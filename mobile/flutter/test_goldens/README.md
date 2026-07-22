# Golden suites (alchemist)

One suite per `core/ui` module (mobile-implementation.md §7): every
variant×state cell of the Figma set's axes, light + dark. A component is
not done until its goldens exist. CI compares `goldens/ci/*.png`
byte-exactly (no diff tolerances) in the mobile lane's "Golden tests"
step.

## The goldens are authored on Linux — not on your Mac

Alchemist's CI variant removes the dominant cross-platform
nondeterminism: text renders as blocked boxes and shadows render solid.
What it cannot fix is curve/gradient **anti-aliasing** and bilinear
image filtering — those rasterize platform/arch-dependently, leaving
sub-2% pixel residue between macOS-arm64 renders and the x64 Linux
runners (observed 2026-07-22: dashed-arc rings 1.57%, sparklines 0.29%,
upscaled media 0.27%, pill/glow edges 0.02%). Goldens are therefore
generated where they are asserted:

```sh
# from the repo root (requires Docker):
make mobile-goldens
# equivalently: mobile/flutter/tool/update_goldens.sh
```

The script runs `flutter test --update-goldens test_goldens` inside the
pinned-version Flutter container on **linux/amd64** (the `--platform`
flag matters on Apple Silicon — arm64 Linux reintroduces the residue).
No Docker? Dispatch the `mobile-goldens` GitHub workflow and commit its
`ci-goldens` artifact.

Consequences:

- `flutter test test_goldens` **fails on macOS** for the AA-heavy suites
  by those same sub-2% diffs — expected, not a regression. The behavior
  suite (`flutter test`) is the local gate.
- A local `--update-goldens` run is fine for eyeballing a change, but
  never commit macOS-rendered `goldens/ci` images.

## Conventions

- `flutter_test_config.dart` disables platform goldens and keeps
  alchemist's CI defaults (`obscureText: true`, `renderShadows: false`).
- `helpers/golden_themes.dart` registers every test twice (light/dark)
  and provides bounded pumps for suites hosting repeating animations
  (spinners, shimmer, pulses) — `onlyPumpAndSettle` never settles there.
- `helpers/test_images.dart` is the deterministic 1×1 media stand-in.
