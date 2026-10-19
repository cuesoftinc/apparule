import { detect } from './filetype';

describe('detect', () => {
  it.each([
    ['\x89PNG\r\n\x1a\n....', 'image/png'],
    ['\xff\xd8\xff\xe0....', 'image/jpeg'],
    ['RIFF\x00\x00\x00\x00WEBPVP8 ', 'image/webp'],
    ['\x00\x00\x00\x18ftypheic....', 'image/heic'],
  ])('%j -> %s', (content, type) => {
    expect(detect(Buffer.from(content, 'latin1'))?.contentType).toBe(type);
  });

  it('rejects anything that is not an image', () => {
    expect(detect(Buffer.from('%PDF-1.7\n'))).toBeNull();
    expect(detect(Buffer.from('Date,Description\n'))).toBeNull();
    expect(detect(Buffer.from([0x4d, 0x5a, 0x90, 0x00]))).toBeNull();
    expect(detect(Buffer.alloc(0))).toBeNull();
  });
});
