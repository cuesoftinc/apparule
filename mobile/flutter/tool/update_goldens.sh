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
# cirruslabs publishes images per Flutter RELEASE TAG it mirrors, and the
# newest stable tag lags (3.44.0 is the last 3.44.x image; there is no
# :3.44.7). The image's SDK is a git checkout, so the pin is TWO-STAGE:
# a fixed base image + an in-container `git checkout <tag>` to the exact
# .fvmrc version — deterministic (release tags are immutable) and always
# in lockstep with the version CI asserts against (mobile-goldens.yml
# reads .fvmrc the same way).
BASE_IMAGE="ghcr.io/cirruslabs/flutter:3.44.0"

echo "Regenerating CI goldens at Flutter ${FLUTTER_VERSION}" \
  "(${BASE_IMAGE}, linux/amd64)…"
docker run --rm --platform linux/amd64 \
  -v "$PWD":/work -w /work \
  -e FLUTTER_VERSION="$FLUTTER_VERSION" \
  "$BASE_IMAGE" \
  sh -c 'set -eu
    FLUTTER_ROOT="$(dirname "$(dirname "$(command -v flutter)")")"
    git -C "$FLUTTER_ROOT" fetch --depth 1 origin "tag" "$FLUTTER_VERSION"
    git -C "$FLUTTER_ROOT" checkout "$FLUTTER_VERSION"
    flutter --version
    flutter pub get
    flutter test --update-goldens test_goldens'

echo "Done — review with: git diff --stat -- test_goldens"
