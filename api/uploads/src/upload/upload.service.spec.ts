import sharp from 'sharp';
import type { UploadedImage } from './ticket-upload.interceptor';
import { cleanImage, MAX_IMAGE_EDGE, MAX_INPUT_PIXELS } from './upload.service';

const png = (width: number, height: number): Promise<Buffer> =>
  sharp({ create: { width, height, channels: 3, background: '#ffffff' } }).png().toBuffer();

const upload = (buffer: Buffer): UploadedImage =>
  ({ field: 'front', file: { buffer, mimetype: 'image/png', size: buffer.length } }) as unknown as UploadedImage;

describe('cleanImage', () => {
  it('re-encodes a normal photo within the edge limit', async () => {
    const result = await cleanImage(upload(await png(3000, 2000)));
    expect(Math.max(result.width, result.height)).toBe(MAX_IMAGE_EDGE);
  });

  it('rejects an image that decodes past the pixel limit', async () => {
    const side = Math.ceil(Math.sqrt(MAX_INPUT_PIXELS)) + 1;
    const buffer = await png(side, side);
    expect(buffer.length).toBeLessThan(5 * 1024 * 1024);
    await expect(cleanImage(upload(buffer))).rejects.toMatchObject({ status: 422 });
  });
});
