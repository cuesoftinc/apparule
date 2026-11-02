/// Build flavors: the two-environment model, so the pair is `dev` and
/// `prod`, not an industry-boilerplate trio.
///
/// - [dev]: fakes/TEST_MODE end to end (mobile-implementation.md §6),
///   Android applicationIdSuffix `.dev`, entrypoint `main_dev.dart`.
/// - [prod]: the bare canonical id `io.cuesoft.apparule`, env from your
///   secrets manager. Entrypoint `main.dart`; `*Remote` repositories
///   arrive with the API wave (§1 phase 4).
enum AppFlavor { dev, prod }
