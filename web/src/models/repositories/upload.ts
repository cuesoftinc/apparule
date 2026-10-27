// Create-then-upload plumbing for the real backend (system-design.md §6.1):
// api/common answers with an upload ticket; the files go to api/uploads
// (POST /api/v1/uploads, through the web's /api proxy) with the ticket as
// their only credential, and the client polls common for the result.
import { apiFetch } from "@/lib/api";

/** The ticket api/common returns with a session or a media batch. */
export interface UploadTicket {
  ticket: string;
  url: string;
  fields: string[];
  max_files: number;
  max_bytes: number;
  expires_at: string;
}

/** POST the files to the gateway: `field -> file` (one or more per field). */
export function uploadWithTicket(
  upload: UploadTicket,
  files: [field: string, file: File][],
): Promise<unknown> {
  const form = new FormData();
  for (const [field, file] of files) form.append(field, file);
  return apiFetch<unknown>(upload.url, {
    method: "POST",
    body: form,
    headers: { "Upload-Ticket": upload.ticket },
  });
}

/**
 * Poll `read` until `done` holds (D7: users see progress, not a hanging
 * request). Gives up after `timeoutMs` with the last value.
 */
export async function pollUntil<T>(
  read: () => Promise<T>,
  done: (value: T) => boolean,
  { intervalMs = 1500, timeoutMs = 120_000 } = {},
): Promise<T> {
  const deadline = Date.now() + timeoutMs;
  let value = await read();
  while (!done(value) && Date.now() < deadline) {
    await new Promise((resolve) => setTimeout(resolve, intervalMs));
    value = await read();
  }
  return value;
}
