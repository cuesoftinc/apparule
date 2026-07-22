/// Build flavors — the two-environment model (org environment ruling,
/// user directive 2026-07-22): CueLABS production runs on the sandbox
/// account, so the pair is `dev` and `prod`, not an industry-boilerplate
/// trio.
///
/// - [dev]: fakes/TEST_MODE end to end (mobile-implementation.md §6),
///   Android applicationIdSuffix `.dev`, entrypoint `main_dev.dart`.
/// - [prod]: the bare canonical id `io.cuesoft.apparule`, Firebase on
///   `sandbox-e306a`, env from the Doppler `apparule/stg` config (the
///   Doppler config name stays `stg`; the environment it feeds is
///   production). Entrypoint `main.dart`; `*Remote` repositories arrive
///   with the API wave (§1 phase 4).
enum AppFlavor { dev, prod }
