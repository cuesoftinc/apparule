import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:apparule/src/core/utils/app_flavor.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/auth/data/auth_repository_firebase.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/camera_service_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/profile/data/notification_repository.dart';
import 'package:apparule/src/features/profile/data/notification_repository_fake.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

/// The `*Fake` repository set — dev runs entirely on these (§6); prod
/// carries them too until the auth/API waves swap in the real
/// implementations (Firebase auth behind the options files, `*Remote`
/// at §1 phase 4).
///
/// [authRepository] lets an entrypoint (or test) supply a differently
/// seeded auth fake — `main_dev` boots signed in as the §6 test user;
/// everything else starts signed out at C1.
///
/// [cameraService] swaps the C6 camera seam (§10): the set defaults to
/// `CameraServiceFake` (bundled sample frame — simulators/CI/dev need no
/// hardware); prod passes `CameraServiceLive` for the real viewfinder
/// while its measurements still ride this fake set (a provider must not
/// be overridden twice in one scope, hence the parameter rather than a
/// second override). [measurementRepository] likewise lets tests seed the
/// measurement fake differently (empty vault, zero processing delay);
/// [postRepository]/[orderRepository]/[notificationRepository] let tests
/// pin the fake's clock, empty its bundle, or switch the seeded viewer
/// role (the feed/orders wave's seams).
List<Override> fakeRepositoryOverrides({
  AuthRepository? authRepository,
  CameraService? cameraService,
  MeasurementRepository? measurementRepository,
  PostRepository? postRepository,
  OrderRepository? orderRepository,
  NotificationRepository? notificationRepository,
}) => <Override>[
  authRepositoryProvider.overrideWith(
    (ref) => authRepository ?? AuthRepositoryFake(),
  ),
  cameraServiceProvider.overrideWith(
    (ref) => cameraService ?? CameraServiceFake(),
  ),
  postRepositoryProvider.overrideWith(
    (ref) => postRepository ?? PostRepositoryFake(),
  ),
  measurementRepositoryProvider.overrideWith(
    (ref) => measurementRepository ?? MeasurementRepositoryFake(),
  ),
  orderRepositoryProvider.overrideWith(
    (ref) => orderRepository ?? OrderRepositoryFake(),
  ),
  notificationRepositoryProvider.overrideWith(
    (ref) => notificationRepository ?? NotificationRepositoryFake(),
  ),
  profileRepositoryProvider.overrideWith(
    (ref) => ProfileRepositoryFake(),
  ),
  earningsRepositoryProvider.overrideWith(
    (ref) => EarningsRepositoryFake(),
  ),
];

/// The real auth override (§9) — google_sign_in 7 into Firebase Auth on
/// `sandbox-e306a`, tokens at rest via the persistence seam. An
/// entrypoint may adopt this only after `Firebase.initializeApp` ran with
/// its flavor's options file (`firebase_options.dart` for prod,
/// `firebase_options_dev.dart` for dev — bootstrap's `firebaseOptions`
/// parameter); until `flutterfire configure` lands those files (blocked
/// on `firebase login --reauth`), no entrypoint wires it and both
/// flavors stay on the fake set.
Override firebaseAuthRepositoryOverride() {
  const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  return authRepositoryProvider.overrideWith(
    (ref) => AuthRepositoryFirebase(
      firebaseAuth: FirebaseAuth.instance,
      googleSignIn: GoogleSignIn.instance,
      persistenceService: ref.watch(persistenceServiceProvider),
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    ),
  );
}
