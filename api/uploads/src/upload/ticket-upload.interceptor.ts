import { type CallHandler, type ExecutionContext, Injectable, type NestInterceptor } from '@nestjs/common';
import type { Request, Response } from 'express';
import multer, { MulterError } from 'multer';
import { from, type Observable, switchMap } from 'rxjs';
import { type Pose, type TicketClaims, TicketService } from '../ticket/ticket.service';
import { ApiError } from '../errors/api-error';

/** Multipart framing around the file parts. */
const MULTIPART_OVERHEAD = 64 * 1024;

/** One image part, labelled with the pose it is for (captures) or its position. */
export interface UploadedImage {
  field: string;
  pose?: Pose;
  file: Express.Multer.File;
}

export interface TicketedRequest extends Request {
  ticket: TicketClaims;
  images: UploadedImage[];
}

const poseField = (pose: Pose) => `image_${pose}`;

/**
 * Verifies the ticket and the declared size before reading the body
 * (system-design.md §8 "Abuse"), then reads exactly the parts the ticket
 * allows, with its max_bytes as the hard per-file limit.
 */
@Injectable()
export class TicketUploadInterceptor implements NestInterceptor {
  constructor(private readonly tickets: TicketService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = context.switchToHttp();
    const request = http.getRequest<TicketedRequest>();
    const response = http.getResponse<Response>();

    const ticket = this.tickets.verify(request.header('upload-ticket'));
    const declared = Number(request.header('content-length') ?? 0);
    if (declared > ticket.max_files * ticket.max_bytes + MULTIPART_OVERHEAD) {
      throw tooLarge(ticket.max_bytes);
    }
    request.ticket = ticket;

    const fields =
      ticket.target.kind === 'capture'
        ? (ticket.poses ?? []).map((pose) => ({ name: poseField(pose), maxCount: 1 }))
        : [{ name: 'images', maxCount: ticket.max_files }];

    const read = new Promise<void>((resolve, reject) => {
      multer({
        storage: multer.memoryStorage(),
        limits: { fileSize: ticket.max_bytes, files: ticket.max_files, fields: 0 },
      }).fields(fields)(request, response, (error: unknown) => {
        if (error instanceof MulterError && error.code === 'LIMIT_FILE_SIZE') {
          return reject(tooLarge(ticket.max_bytes, poseOf(error.field)));
        }
        if (error instanceof MulterError) return reject(wrongFields(ticket));
        if (error) return reject(error);
        try {
          request.images = collect(ticket, request.files as Record<string, Express.Multer.File[]> | undefined);
        } catch (failure) {
          return reject(failure);
        }
        resolve();
      });
    });
    return from(read).pipe(switchMap(() => next.handle()));
  }
}

const poseOf = (field: string | undefined): Pose | undefined =>
  field === 'image_front' ? 'front' : field === 'image_side' ? 'side' : undefined;

/** Captures must carry exactly the ticket's poses; media at least one image. */
const collect = (ticket: TicketClaims, files: Record<string, Express.Multer.File[]> | undefined): UploadedImage[] => {
  if (ticket.target.kind === 'capture') {
    const images = (ticket.poses ?? []).map((pose) => ({ field: poseField(pose), pose, file: files?.[poseField(pose)]?.[0] }));
    if (images.some((image) => !image.file || image.file.size === 0)) throw wrongFields(ticket);
    return images as UploadedImage[];
  }
  const images = (files?.images ?? []).filter((file) => file.size > 0);
  if (images.length === 0) throw wrongFields(ticket);
  return images.map((file, i) => ({ field: `images[${i}]`, file }));
};

const wrongFields = (ticket: TicketClaims) =>
  ticket.target.kind === 'capture'
    ? new ApiError(422, 'validation_failed', `Send ${(ticket.poses ?? []).map(poseField).join(' and ')} as multipart files`, {
        fields: (ticket.poses ?? []).map(poseField),
      })
    : new ApiError(422, 'validation_failed', `Send 1 to ${ticket.max_files} files in multipart fields named "images"`);

const tooLarge = (maxBytes: number, pose?: Pose) =>
  new ApiError(413, 'file_too_large', `Images can be at most ${Math.floor(maxBytes / (1024 * 1024))} MB`, {
    max_bytes: maxBytes,
    ...(pose ? { pose } : {}),
  });
