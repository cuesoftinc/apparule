import { Inject, Injectable, Logger } from "@nestjs/common";
import { CONFIG, type Config } from "../config/config";

/** The upload waits at most this long; common's captures job finishes the rest. */
const SETTLE_TIMEOUT_MS = 30_000;

const METADATA_IDENTITY =
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity";

/**
 * Settles api/common after an upload event is sent (scale to zero,
 * shared-messaging.md). Cloud Run gives common CPU only while it serves a
 * request (S-14), so POST /internal/settle is the call that makes its
 * consumer read the message and publish what that causes. Awaited inside the
 * upload request, because this service's CPU is only allocated while a
 * request runs. Best-effort: a missed settle leaves the message in Kafka, and
 * common's captures job settles it within a minute.
 */
@Injectable()
export class WakeService {
  private readonly logger = new Logger(WakeService.name);
  private readonly base: string;
  private readonly onCloudRun: boolean;

  constructor(@Inject(CONFIG) config: Config) {
    this.base = config.wakeCommonUrl.replace(/\/+$/, "");
    this.onCloudRun = config.onCloudRun;
  }

  async common(reason: string): Promise<void> {
    // No URL: compose and Helm run common all the time.
    if (!this.base) return;
    const target = new URL(this.base).host;
    try {
      const headers: Record<string, string> = {};
      if (this.onCloudRun) {
        headers.Authorization = `Bearer ${await this.idToken()}`;
      }
      const res = await fetch(`${this.base}/internal/settle`, {
        method: "POST",
        headers,
        signal: AbortSignal.timeout(SETTLE_TIMEOUT_MS),
      });
      if (!res.ok) throw new Error(`status ${res.status}`);
      const answer = (await res.json().catch(() => ({}))) as {
        caught_up?: boolean;
      };
      this.logger.log({
        message: "settled service",
        step: "settle",
        target,
        reason,
        caught_up: answer.caught_up ?? false,
      });
    } catch (error) {
      this.logger.warn({
        message: "settle failed",
        step: "settle",
        target,
        reason,
        error: (error as Error).message,
      });
    }
  }

  /** The service account's ID token for common's URL, which Cloud Run checks. */
  private async idToken(): Promise<string> {
    const res = await fetch(
      `${METADATA_IDENTITY}?audience=${encodeURIComponent(this.base)}`,
      {
        headers: { "Metadata-Flavor": "Google" },
        signal: AbortSignal.timeout(5_000),
      },
    );
    if (!res.ok) throw new Error(`id token: status ${res.status}`);
    return (await res.text()).trim();
  }
}
