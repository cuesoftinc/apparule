import { join } from 'node:path';
import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import sharp from 'sharp';
import request from 'supertest';
import { AppModule } from '../app.module';
import { CONFIG, type Config } from '../config/config';
import { ContractService } from '../contract/contract.service';
import { ErrorFilter } from '../errors/error.filter';
import { KafkaProducerService } from '../kafka/kafka-producer.service';
import { StorageService, type StoredObject } from '../storage/storage.service';
import { ACCOUNT_ID, makeSigner, SESSION_ID } from '../testing/tickets';

const signer = makeSigner('k1');
const CONTRACT_DIR = process.env.CONTRACT_DIR ?? join(__dirname, '..', '..', '..', 'common', 'contract');
const POST_ID = '0d1e2f3a-4b5c-4d6e-8f70-81a2b3c4d5e6';

interface Sent {
  account_id: string;
  poses: Record<string, { width: number; height: number }>;
  images: unknown[];
}

const config: Config = {
  port: 0,
  corsOrigins: ['http://localhost:3000'],
  kafka: { brokers: ['unused:9092'], username: '', password: '', sslCa: '' },
  storage: { driver: 's3', bucket: 'b', prefix: 'apparule/test', endpoint: 'unused', accessKey: '', secretKey: '', useSsl: false },
  ticketPublicKeys: new Map([['k1', signer.publicKey]]),
  contractDir: CONTRACT_DIR,
  wakeCommonUrl: '',
};

/** A small JPEG carrying EXIF (camera make and a GPS-bearing IFD). */
const photo = (width = 600, height = 900) =>
  sharp({ create: { width, height, channels: 3, background: '#8a7' } })
    .withExif({ IFD0: { Make: 'TestCam', Model: 'X1' }, IFD3: { GPSLatitudeRef: 'N', GPSLatitude: '6/1 27/1 0/1' } })
    .jpeg()
    .toBuffer();

describe('POST /api/v1/uploads', () => {
  let app: INestApplication;
  const stored: Array<{ key: string; data: Buffer; contentType: string }> = [];
  const sent: Array<{ topic: string; key: string; data: Sent }> = [];
  let failKafka = false;

  beforeAll(async () => {
    const contract = new ContractService(config);
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(CONFIG)
      .useValue(config)
      .overrideProvider(StorageService)
      .useValue({
        tmpKey: (kind: string, target: string, ticket: string, name: string) => `apparule/test/tmp/${kind}/${target}/${ticket}/${name}.jpg`,
        store: async (key: string, data: Buffer, contentType: string, sha256: string): Promise<StoredObject> => {
          stored.push({ key, data, contentType });
          return { bucket: 'b', key, size: data.length, content_type: contentType, sha256 };
        },
        ready: async () => undefined,
      })
      .overrideProvider(KafkaProducerService)
      .useValue({
        isConnected: true,
        // Validate exactly as the real producer does.
        send: async (topic: string, key: string, data: Record<string, unknown>) => {
          if (failKafka) throw new Error('broker down');
          contract.validateData(topic, data);
          sent.push({ topic, key, data: data as unknown as Sent });
        },
      })
      .compile();
    app = moduleRef.createNestApplication({ bodyParser: false, logger: false });
    app.useGlobalFilters(new ErrorFilter());
    await app.init();
  });

  afterAll(() => app.close());
  beforeEach(() => {
    stored.length = 0;
    sent.length = 0;
    failKafka = false;
  });

  it('stores both poses in tmp/ and publishes a valid capture.uploaded', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue())
      .attach('image_front', await photo(), 'IMG_0001.jpg')
      .attach('image_side', await photo(), 'IMG_0002.jpg')
      .expect(202);

    expect(res.body).toEqual({ target: { kind: 'capture', id: SESSION_ID }, status: 'processing' });
    expect(stored.map((s) => s.key)).toEqual([
      expect.stringMatching(new RegExp(`^apparule/test/tmp/capture/${SESSION_ID}/[0-9a-f-]{36}/front\\.jpg$`)),
      expect.stringMatching(new RegExp(`^apparule/test/tmp/capture/${SESSION_ID}/[0-9a-f-]{36}/side\\.jpg$`)),
    ]);
    expect(sent).toHaveLength(1);
    expect(sent[0].topic).toBe('apparule.capture.uploaded');
    expect(sent[0].key).toBe(SESSION_ID);
    expect(sent[0].data.account_id).toBe(ACCOUNT_ID);
    expect(sent[0].data.poses.front).toMatchObject({ width: 600, height: 900 });
  });

  it('strips EXIF and GPS before storing', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue())
      .attach('image_front', await photo(), 'a.jpg')
      .attach('image_side', await photo(), 'b.jpg')
      .expect(202);
    for (const { data } of stored) {
      const meta = await sharp(data).metadata();
      expect(meta.exif).toBeUndefined();
      expect(data.includes(Buffer.from('TestCam'))).toBe(false);
    }
  });

  it('accepts a single-pose retake ticket', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue({ poses: ['side'], max_files: 1 }))
      .attach('image_side', await photo(), 'retake.jpg')
      .expect(202);
    expect(Object.keys(sent[0].data.poses)).toEqual(['side']);
  });

  it('422s a capture missing a pose its ticket requires', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue())
      .attach('image_front', await photo(), 'a.jpg')
      .expect(422);
    expect(res.body.error.code).toBe('validation_failed');
    expect(stored).toHaveLength(0);
  });

  it('rejects a pose the retake ticket does not allow', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue({ poses: ['side'], max_files: 1 }))
      .attach('image_front', await photo(), 'a.jpg')
      .expect(422);
    expect(res.body.error.code).toBe('validation_failed');
  });

  it('publishes post media as media.uploaded', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue({ target: { kind: 'post_media', id: POST_ID }, poses: undefined, max_files: 10 }))
      .attach('images', await photo(), 'look-1.jpg')
      .attach('images', await photo(800, 800), 'look-2.jpg')
      .expect(202);
    expect(res.body).toEqual({ target: { kind: 'post_media', id: POST_ID }, status: 'received', count: 2 });
    expect(sent[0].topic).toBe('apparule.media.uploaded');
    expect(sent[0].data.images).toHaveLength(2);
  });

  it('401s without a ticket, before touching storage', async () => {
    const res = await request(app.getHttpServer()).post('/api/v1/uploads').attach('image_front', await photo(), 'a.jpg').expect(401);
    expect(res.body.error.code).toBe('invalid_ticket');
    expect(stored).toHaveLength(0);
  });

  it('413s an image over the ticket limit, naming the pose', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue({ max_bytes: 100 }))
      .attach('image_front', await photo(), 'a.jpg')
      .attach('image_side', await photo(), 'b.jpg')
      .expect(413);
    expect(res.body.error.code).toBe('file_too_large');
  });

  it('415s a file that is not an image, naming the pose', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue())
      .attach('image_front', await photo(), 'a.jpg')
      .attach('image_side', Buffer.from('%PDF-1.7\n'), 'b.pdf')
      .expect(415);
    expect(res.body.error).toMatchObject({ code: 'unsupported_type', details: { pose: 'side' } });
    expect(stored).toHaveLength(0);
  });

  it('422s an image that will not decode, naming the pose', async () => {
    const broken = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(64, 7)]);
    const res = await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue())
      .attach('image_front', broken, 'a.jpg')
      .attach('image_side', await photo(), 'b.jpg')
      .expect(422);
    expect(res.body.error).toMatchObject({ code: 'undecodable_image', details: { pose: 'front' } });
  });

  it('downscales an oversized image to 2048 px', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue())
      .attach('image_front', await photo(1500, 3000), 'a.jpg')
      .attach('image_side', await photo(), 'b.jpg')
      .expect(202);
    const meta = await sharp(stored[0].data).metadata();
    expect([meta.width, meta.height]).toEqual([1024, 2048]);
  });

  it('503s while Kafka is away', async () => {
    failKafka = true;
    const res = await request(app.getHttpServer())
      .post('/api/v1/uploads')
      .set('Upload-Ticket', signer.issue())
      .attach('image_front', await photo(), 'a.jpg')
      .attach('image_side', await photo(), 'b.jpg')
      .expect(503);
    expect(res.body.error.code).toBe('service_unavailable');
  });

  it('answers health and readiness', async () => {
    await request(app.getHttpServer()).get('/health').expect(200, { status: 'healthy' });
    await request(app.getHttpServer()).get('/ready').expect(200, { status: 'ready' });
  });
});
