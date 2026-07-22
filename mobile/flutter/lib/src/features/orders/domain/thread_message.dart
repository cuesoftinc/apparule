import 'package:freezed_annotation/freezed_annotation.dart';

part 'thread_message.freezed.dart';

/// One order-thread message (SOC-005; web `ThreadMessage` parity).
/// Attachments are images only; no payment links in threads
/// (order-lifecycle.md §5).
@freezed
abstract class ThreadMessage with _$ThreadMessage {
  const factory ThreadMessage({
    required String id,
    required String orderId,
    required String authorId,
    required String body,
    required DateTime createdAt,

    /// Whether the signed-in viewer authored it (drives bubble side).
    required bool own,
    String? imageUrl,
  }) = _ThreadMessage;
}
