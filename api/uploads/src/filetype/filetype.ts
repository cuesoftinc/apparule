export interface Detected {
  contentType: 'image/jpeg' | 'image/png' | 'image/webp' | 'image/heic';
}

const startsWith = (data: Buffer, bytes: number[], offset = 0): boolean =>
  data.length >= offset + bytes.length && bytes.every((b, i) => data[offset + i] === b);

/**
 * Image type from magic bytes, never from the name or the client's
 * Content-Type (flows/vault.md §1: JPEG/PNG/HEIC; post media adds WebP).
 */
export const detect = (data: Buffer): Detected | null => {
  if (startsWith(data, [0xff, 0xd8, 0xff])) return { contentType: 'image/jpeg' };
  if (startsWith(data, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) return { contentType: 'image/png' };
  if (startsWith(data, [0x52, 0x49, 0x46, 0x46]) && startsWith(data, [0x57, 0x45, 0x42, 0x50], 8)) {
    return { contentType: 'image/webp' };
  }
  if (startsWith(data, [0x66, 0x74, 0x79, 0x70], 4)) {
    const brand = data.subarray(8, 12).toString('ascii');
    if (['heic', 'heix', 'mif1', 'msf1', 'heif'].includes(brand)) return { contentType: 'image/heic' };
  }
  return null;
};
