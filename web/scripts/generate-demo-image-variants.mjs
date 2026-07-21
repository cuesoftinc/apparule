// Pre-generate responsive WebP variants of the CC demo pool.
//
// The deploy target (Firebase App Hosting Next.js adapter) disables Next's
// runtime image optimizer, so variants are committed artifacts, not build
// outputs: for every public/demo/*.jpg this emits `<base>.w<width>.webp` at
// the srcset width buckets src/lib/demo-image-loader.ts serves (keep the two
// lists in sync). Originals stay byte-identical on disk — they are the
// CC-attributed derivatives manifested in public/demo/ATTRIBUTIONS.md, and
// every variant inherits its original's attribution.
//
// Rerun after adding or replacing pool images:
//   node scripts/generate-demo-image-variants.mjs
import { readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import sharp from "sharp"; // next's bundled optional dependency

/** Keep in sync with VARIANT_WIDTHS in src/lib/demo-image-loader.ts. */
const WIDTHS = [128, 384, 640, 960];
const QUALITY = 72;

const demoDir = fileURLToPath(new URL("../public/demo/", import.meta.url));
const jpgs = (await readdir(demoDir)).filter(
  (f) => f.endsWith(".jpg") && !f.includes(".w"),
);

let files = 0;
for (const jpg of jpgs) {
  const base = path.basename(jpg, ".jpg");
  for (const width of WIDTHS) {
    const out = path.join(demoDir, `${base}.w${width}.webp`);
    // withoutEnlargement: sources top out at 900px wide — the w960 file
    // simply keeps the intrinsic width rather than upscaling.
    const info = await sharp(path.join(demoDir, jpg))
      .resize({ width, withoutEnlargement: true })
      .webp({ quality: QUALITY })
      .toFile(out);
    files += 1;
    console.log(
      `${base}.w${width}.webp ${info.width}x${info.height} ${(info.size / 1024).toFixed(1)}KB`,
    );
  }
}
console.log(`${files} variants for ${jpgs.length} originals`);
