import { createHash } from 'node:crypto';
import { Injectable, Logger } from '@nestjs/common';
import sharp from 'sharp';
import { ApiError } from '../errors/api-error';
import { detect } from '../filetype/filetype';
import { KafkaProducerService } from '../kafka/kafka-producer.service';
import { CAPTURE_UPLOADED, MEDIA_UPLOADED } from '../kafka/topics';
import { WakeService } from '../kafka/wake.service';
import { StorageService, type StoredObject } from '../storage/storage.service';
import type { Pose, TargetKind, TicketClaims } from '../ticket/ticket.service';
import type { UploadedImage } from './ticket-upload.interceptor';

/** Clients compress to 2048 px on the long edge (flows/vault.md §1); the server re-checks. */
export const MAX_IMAGE_EDGE = 2048;
const JPEG_QUALITY = 90;

export interface UploadAccepted {
  target: { kind: TargetKind; id: string };
  status: 'processing' | 'received';
  count?: number;
}

interface CleanImage {
  data: Buffer;
  width: number;
  height: number;
}

interface ImageRef {
  object: StoredObject;
  width: number;
  height: number;
}

@Injectable()
export class UploadService {
  private readonly logger = new Logger(UploadService.name);

  constructor(
    private readonly storage: StorageService,
    private readonly kafka: KafkaProducerService,
    private readonly wake: WakeService,
  ) {}

  async accept(ticket: TicketClaims, images: UploadedImage[]): Promise<UploadAccepted> {
    // Check and clean every image before storing any: a bad side photo must
    // not leave a front photo behind in tmp/.
    const clean: Array<{ image: UploadedImage; result: CleanImage }> = [];
    for (const image of images) {
      if (!detect(image.file.buffer)) {
        throw new ApiError(415, 'unsupported_type', 'Upload a JPEG, PNG, WebP or HEIC photo', detailsFor(image));
      }
      clean.push({ image, result: await cleanImage(image) });
    }

    const refs: Array<{ image: UploadedImage; ref: ImageRef }> = [];
    try {
      for (const { image, result } of clean) {
        const key = this.storage.tmpKey(ticket.target.kind, ticket.target.id, ticket.jti, image.pose ?? String(refs.length));
        const sha256 = createHash('sha256').update(result.data).digest('hex');
        const object = await this.storage.store(key, result.data, 'image/jpeg', sha256);
        refs.push({ image, ref: { object, width: result.width, height: result.height } });
      }
    } catch (error) {
      this.logger.error({ message: 'storage write failed', ticket: ticket.jti, error: (error as Error).message });
      throw unavailable('storage_unavailable');
    }

    const capture = ticket.target.kind === 'capture';
    try {
      if (capture) {
        await this.kafka.send(CAPTURE_UPLOADED, ticket.target.id, {
          ticket_id: ticket.jti,
          account_id: ticket.account_id,
          session_id: ticket.target.id,
          poses: Object.fromEntries(refs.map(({ image, ref }) => [image.pose as Pose, ref])),
        });
      } else {
        await this.kafka.send(MEDIA_UPLOADED, ticket.target.id, {
          ticket_id: ticket.jti,
          account_id: ticket.account_id,
          target: ticket.target,
          images: refs.map(({ ref }) => ref),
        });
      }
    } catch (error) {
      // The images stay in tmp/; the bucket's 24 h lifecycle rule removes them.
      this.logger.error({ message: 'kafka publish failed', ticket: ticket.jti, error: (error as Error).message });
      throw unavailable('queue_unavailable');
    }
    await this.wake.common(capture ? CAPTURE_UPLOADED : MEDIA_UPLOADED);

    this.logger.log({
      message: 'upload accepted; stored in tmp/ and handed to common',
      step: capture ? 'capture.uploaded' : 'media.uploaded',
      ticket: ticket.jti,
      target: ticket.target.kind,
      target_id: ticket.target.id,
      images: refs.length,
      bytes: refs.reduce((sum, { ref }) => sum + ref.object.size, 0),
    });
    return capture
      ? { target: ticket.target, status: 'processing' }
      : { target: ticket.target, status: 'received', count: refs.length };
  }
}

/**
 * Decode, apply the EXIF orientation, drop every metadata block (EXIF, GPS,
 * XMP, ICC) and re-encode as JPEG at <= 2048 px. sharp writes no metadata
 * unless asked to, so the stored image carries none (system-design.md §8).
 */
export const cleanImage = async (image: UploadedImage): Promise<CleanImage> => {
  try {
    const { data, info } = await sharp(image.file.buffer, { failOn: 'error' })
      .rotate()
      .resize({ width: MAX_IMAGE_EDGE, height: MAX_IMAGE_EDGE, fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: JPEG_QUALITY, mozjpeg: true })
      .toBuffer({ resolveWithObject: true });
    return { data, width: info.width, height: info.height };
  } catch {
    throw new ApiError(422, 'undecodable_image', "That image couldn't be read — try another photo", detailsFor(image));
  }
};

const detailsFor = (image: UploadedImage): Record<string, unknown> =>
  image.pose ? { pose: image.pose } : { field: image.field };

const unavailable = (code: string) =>
  new ApiError(503, 'service_unavailable', 'Uploads are temporarily unavailable; try again shortly', { reason: code, retry_after: 30 });
