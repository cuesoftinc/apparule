import 'package:apparule/src/core/utils/app_flavor.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'di.g.dart';

/// DI = provider overrides per environment (mobile-implementation.md §4):
/// Riverpod's provider graph is the only injection mechanism — no second
/// container. Each entrypoint builds a ProviderScope from these sets.
///
/// The current flavor, overridden by [appFlavorProvider]'s entrypoint
/// override in bootstrap.
@Riverpod(keepAlive: true)
AppFlavor appFlavor(Ref ref) => throw UnimplementedError(
  'appFlavor is overridden by bootstrap() — run a main_<flavor>.dart '
  'entrypoint',
);

/// The `*Fake` repository set — dev/stg run entirely on these (§6).
/// prd carries them too until the API wave swaps in `*Remote` (§1 phase 4).
List<Override> fakeRepositoryOverrides() => <Override>[
  authRepositoryProvider.overrideWith((ref) => AuthRepositoryFake()),
  postRepositoryProvider.overrideWith((ref) => PostRepositoryFake()),
  measurementRepositoryProvider.overrideWith(
    (ref) => MeasurementRepositoryFake(),
  ),
  orderRepositoryProvider.overrideWith((ref) => OrderRepositoryFake()),
  profileRepositoryProvider.overrideWith((ref) => ProfileRepositoryFake()),
  earningsRepositoryProvider.overrideWith((ref) => EarningsRepositoryFake()),
];
