#!/usr/bin/env sh
# Regenerates test_goldens/**/goldens/ci/*.png ON LINUX/amd64 — the
# platform+arch the golden gate compares on (build-and-test.yml mobile
# job, ubuntu-latest x64).
#
# Alchemist's CI variant already renders platform-independent TEXT
# (blocked boxes) and solid shadows, but curve/gradient anti-aliasing and
# bilinear image filtering are rasterized platform/arch-dependently —
# macOS-arm64 renders differ from the x64 runners by sub-2% pixel residue
# (dashed-arc rings 1.57%, sparklines 0.29%, upscaled media 0.27%,
# observed 2026-07-22). Goldens are therefore authored where they are
# asserted; never commit macOS-rendered goldens/ci images.
#
# Requires Docker. `--platform linux/amd64` is load-bearing on Apple
# Silicon: an arm64 Linux container rasterizes with arm64 float behavior
# and reintroduces the residue. No Docker? Run the `mobile-goldens`
# GitHub workflow (workflow_dispatch) and commit its `ci-goldens`
# artifact instead.
set -eu

cd "$(dirname "$0")/.."

FLUTTER_VERSION="$(sed -n 's/.*"flutter"[^"]*"\([^"]*\)".*/\1/p' .fvmrc)"
IMAGE="ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION}"

echo "Regenerating CI goldens in ${IMAGE} (linux/amd64)…"
docker run --rm --platform linux/amd64 \
  -v "$PWD":/work -w /work \
  "$IMAGE" \
  sh -c 'flutter --version && flutter pub get && flutter test --update-goldens test_goldens'

echo "Done — review with: git diff --stat -- test_goldens"
