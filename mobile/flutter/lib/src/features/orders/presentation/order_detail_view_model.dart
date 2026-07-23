import 'dart:async';

import 'package:apparule/src/core/ui/app_haptics.dart';
import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/domain/thread_message.dart';
import 'package:apparule/src/features/orders/presentation/orders_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_detail_view_model.g.dart';

/// The MI-18 send ladder a thread row climbs (design.md §8.2b ThreadBubble
/// state axis; web `use-thread.ts` OutgoingMessage parity).
enum ThreadSendState { sending, sent, failed }

/// One rendered thread row: the message plus its send state — `failed`
/// rows keep the user's text on screen and carry the retry affordance
/// (D40: a failed send must never silently discard the message).
class ThreadEntry {
  const ThreadEntry({
    required this.message,
    this.sendState = ThreadSendState.sent,
  });

  final ThreadMessage message;
  final ThreadSendState sendState;
}

/// What C8's detail renders: the order, its thread (send states
/// included), the MI-17 typing pulse, and the MI-15 payment flags.
typedef OrderDetailState = ({
  Order order,
  List<ThreadEntry> messages,

  /// MI-17 (D13): the counterparty "responding…" pulse is on stage while
  /// a scripted reply is held back.
  bool typing,

  /// MI-15 (D07): a pay call is in flight — the box shows `paying` and
  /// the CTA cannot double-fire.
  bool paying,

  /// MI-15 (D64): payment completed THIS session — gates the escrow
  /// explainer to the just-paid moment (web `justPaid` parity).
  bool justPaid,
});

/// C8's detail ViewModel — every action is a REAL lifecycle transition on
/// the repository (validated against order-lifecycle.md §1); the updated
/// order echoes into this state and invalidates the list so its pill
/// pulses to the new state (MI-14). Lifecycle actions rethrow — the
/// screen wraps them in `runAction` (CLASS 4), so races/double-taps
/// surface as a toast instead of a silent unhandled StateError (D39).
@riverpod
class OrderDetailViewModel extends _$OrderDetailViewModel {
  /// MI-17 (D13): how long the scripted counterparty reply hides behind
  /// the typing pulse (web `use-thread.ts` TYPING_MS parity).
  static const Duration typingHoldBack = Duration(milliseconds: 1600);

  Timer? _typingTimer;
  final Set<String> _knownIds = <String>{};
  int _localSequence = 0;
  bool _justPaid = false;

  @override
  Future<OrderDetailState> build(String orderId) async {
    ref.onDispose(() => _typingTimer?.cancel());
    final repository = ref.watch(orderRepositoryProvider);
    final messages = await repository.messages(orderId);
    _knownIds
      ..clear()
      ..addAll(messages.map((message) => message.id));
    return (
      order: await repository.order(orderId),
      messages: <ThreadEntry>[
        for (final message in messages) ThreadEntry(message: message),
      ],
      typing: false,
      paying: false,
      justPaid: _justPaid,
    );
  }

  OrderRepository get _repository => ref.read(orderRepositoryProvider);

  /// MI-15 (D07): drives `paying` around the escrow hold; a second tap
  /// while in flight is a no-op (never an unhandled paid→paid
  /// StateError). Rethrows real failures for the screen's `runAction`.
  Future<void> pay() async {
    final current = state.value;
    if (current == null || current.paying) return;
    state = AsyncData(_copy(current, paying: true));
    try {
      final updated = await _repository.pay(orderId);
      _justPaid = true;
      // MI-20 medium: payment success.
      AppHaptics.medium();
      _emitOrder(updated);
      ref.invalidate(ordersViewModelProvider);
    } finally {
      if (state.value case final latest? when latest.paying) {
        state = AsyncData(_copy(latest, paying: false));
      }
    }
  }

  Future<void> confirmDelivery() =>
      _apply(() => _repository.confirmDelivery(orderId));

  Future<void> withdraw() => _apply(() => _repository.cancel(orderId));

  Future<void> openDispute(DisputeReason reason, {String? detail}) => _apply(
    () => _repository.openDispute(orderId, reason, detail: detail),
  );

  Future<void> decline(DeclineReason reason, {String? note}) =>
      _apply(() => _repository.decline(orderId, reason, note: note));

  Future<void> sendQuote(int quoteCents, {required DateTime dueAt}) =>
      _apply(() => _repository.quote(orderId, quoteCents, dueAt: dueAt));

  Future<void> startProgress() =>
      _apply(() => _repository.startProgress(orderId));

  Future<void> ship({String? tracking}) =>
      _apply(() => _repository.ship(orderId, tracking: tracking));

  /// Optimistic send (D40, MI-18): the bubble appears `sending` in the
  /// same frame, settles to `sent` on the server echo, or flips to
  /// `failed` with the text preserved and a retry affordance — a failure
  /// never discards the message (web `use-thread.ts` parity). The
  /// scripted counterparty reply is held back behind the MI-17 typing
  /// pulse (D13) instead of popping in the send's own frame.
  Future<void> sendMessage(String body) async {
    final trimmed = body.trim();
    final current = state.value;
    if (trimmed.isEmpty || current == null) return;
    final order = current.order;
    final ownParty = order.viewerRole == OrderRole.designer
        ? order.designer
        : order.customer;
    final optimistic = ThreadMessage(
      id: 'optimistic-${++_localSequence}',
      orderId: orderId,
      authorId: ownParty.id,
      body: trimmed,
      own: true,
      createdAt: DateTime.now(),
    );
    _emitMessages(<ThreadEntry>[
      ...current.messages,
      ThreadEntry(message: optimistic, sendState: ThreadSendState.sending),
    ]);
    try {
      final saved = await _repository.sendMessage(orderId, trimmed);
      _knownIds.add(saved.id);
      _swapEntry(optimistic.id, ThreadEntry(message: saved));
      final all = await _repository.messages(orderId);
      final incoming = <ThreadMessage>[
        for (final message in all)
          if (!message.own && !_knownIds.contains(message.id)) message,
      ];
      if (incoming.isNotEmpty) {
        _knownIds.addAll(incoming.map((message) => message.id));
        _setTyping(on: true);
        _typingTimer?.cancel();
        _typingTimer = Timer(typingHoldBack, () => _reveal(incoming));
      }
    } on Object {
      // The failed bubble + retry IS the feedback (web parity — no
      // toast); the text survives on stage.
      _swapEntry(
        optimistic.id,
        ThreadEntry(message: optimistic, sendState: ThreadSendState.failed),
      );
    }
  }

  /// D40: retry a failed bubble — drop it and re-run the optimistic send
  /// with the same body.
  Future<void> retryMessage(String failedMessageId) async {
    final current = state.value;
    if (current == null) return;
    ThreadEntry? failed;
    for (final entry in current.messages) {
      if (entry.message.id == failedMessageId &&
          entry.sendState == ThreadSendState.failed) {
        failed = entry;
      }
    }
    if (failed == null) return;
    _emitMessages(<ThreadEntry>[
      for (final entry in current.messages)
        if (entry.message.id != failedMessageId) entry,
    ]);
    await sendMessage(failed.message.body);
  }

  void _reveal(List<ThreadMessage> incoming) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      _copy(
        current,
        typing: false,
        messages: <ThreadEntry>[
          ...current.messages,
          for (final message in incoming) ThreadEntry(message: message),
        ],
      ),
    );
  }

  void _setTyping({required bool on}) {
    if (state.value case final current?) {
      state = AsyncData(_copy(current, typing: on));
    }
  }

  void _emitMessages(List<ThreadEntry> messages) {
    if (state.value case final current?) {
      state = AsyncData(_copy(current, messages: messages));
    }
  }

  void _swapEntry(String messageId, ThreadEntry replacement) {
    if (state.value case final current?) {
      _emitMessages(<ThreadEntry>[
        for (final entry in current.messages)
          if (entry.message.id == messageId) replacement else entry,
      ]);
    }
  }

  void _emitOrder(Order order) {
    if (state.value case final current?) {
      state = AsyncData(_copy(current, order: order));
    }
  }

  Future<void> _apply(Future<Order> Function() action) async {
    final updated = await action();
    _emitOrder(updated);
    ref.invalidate(ordersViewModelProvider);
  }

  OrderDetailState _copy(
    OrderDetailState current, {
    Order? order,
    List<ThreadEntry>? messages,
    bool? typing,
    bool? paying,
  }) => (
    order: order ?? current.order,
    messages: messages ?? current.messages,
    typing: typing ?? current.typing,
    paying: paying ?? current.paying,
    justPaid: _justPaid,
  );
}
