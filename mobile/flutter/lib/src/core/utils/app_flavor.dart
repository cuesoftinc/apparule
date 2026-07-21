/// Build flavors (mobile-implementation.md §2): `dev`/`stg` run entirely on
/// `*Fake` repositories; `prd` swaps to `*Remote` when API wiring lands
/// (§1 phase 4). Matched by Android `productFlavors` (applicationIdSuffix)
/// and the three `main_<flavor>.dart` entrypoints.
enum AppFlavor { dev, stg, prd }
