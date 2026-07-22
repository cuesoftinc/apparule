import 'package:flutter/painting.dart';

/// Resolves a seed media URL to an image provider. The §6 seed carries the
/// web mock's URL form verbatim (`/demo/outfit-w01.jpg`) so the two seed
/// sets stay regenerable from one source (mobile-implementation.md §6);
/// the dev bundle ships that pool under `assets/seed/dev/demo/`. Absolute
/// http(s) URLs (the phase-4 `*Remote` shape) load over the network
/// unchanged — screens never branch on the source.
ImageProvider<Object> seedMediaImage(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return NetworkImage(url);
  }
  if (url.startsWith('/demo/')) {
    return AssetImage('assets/seed/dev$url');
  }
  return AssetImage(url);
}

/// Nullable convenience for avatar slots (`null` stays initials).
ImageProvider<Object>? seedMediaImageOrNull(String? url) =>
    url == null ? null : seedMediaImage(url);
