import { createPublicKey, verify, type KeyObject } from "node:crypto";
import { Inject, Injectable } from "@nestjs/common";
import { CONFIG, type Config } from "../config/config";
import { ApiError } from "../errors/api-error";

export type Pose = "front" | "side";
export type TargetKind = "capture" | "post_media" | "attachment";

export interface TicketClaims {
  kid: string;
  jti: string;
  account_id: string;
  target: { kind: TargetKind; id: string };
  /** Captures only: the poses this ticket accepts. */
  poses?: Pose[];
  max_files: number;
  /** Per image. */
  max_bytes: number;
  iat: number;
  exp: number;
}

const SKEW_SECONDS = 30;
const KINDS: readonly string[] = ["capture", "post_media", "attachment"];
const POSES: readonly string[] = ["front", "side"];

/**
 * Verifies upload tickets signed by api/common (format:
 * api/common/contract/upload-ticket.md). Stateless: single use is enforced
 * by common when it consumes the upload event.
 */
@Injectable()
export class TicketService {
  private readonly keys = new Map<string, KeyObject>();

  constructor(@Inject(CONFIG) config: Pick<Config, "ticketPublicKeys">) {
    for (const [kid, raw] of config.ticketPublicKeys) {
      this.keys.set(
        kid,
        createPublicKey({
          key: { kty: "OKP", crv: "Ed25519", x: raw.toString("base64url") },
          format: "jwk",
        }),
      );
    }
  }

  verify(
    ticket: string | undefined,
    now: number = Date.now() / 1000,
  ): TicketClaims {
    const invalid = () =>
      new ApiError(
        401,
        "invalid_ticket",
        "The upload ticket is missing or invalid",
      );
    const parts = ticket?.split(".") ?? [];
    if (parts.length !== 3 || parts[0] !== "v1") throw invalid();
    const [version, payload, signature] = parts;

    let claims: TicketClaims;
    try {
      claims = JSON.parse(
        Buffer.from(payload, "base64url").toString("utf8"),
      ) as TicketClaims;
    } catch {
      throw invalid();
    }
    const key = this.keys.get(claims.kid);
    if (
      !key ||
      !verify(
        null,
        Buffer.from(`${version}.${payload}`, "ascii"),
        key,
        Buffer.from(signature, "base64url"),
      )
    ) {
      throw invalid();
    }
    const capture = claims.target?.kind === "capture";
    if (
      typeof claims.jti !== "string" ||
      typeof claims.account_id !== "string" ||
      !claims.target?.id ||
      !KINDS.includes(claims.target.kind) ||
      (capture &&
        !(
          Array.isArray(claims.poses) &&
          claims.poses.length > 0 &&
          claims.poses.every((p) => POSES.includes(p))
        )) ||
      !(claims.max_files > 0) ||
      !(claims.max_bytes > 0) ||
      typeof claims.exp !== "number"
    ) {
      throw invalid();
    }
    if (claims.exp + SKEW_SECONDS < now) {
      throw new ApiError(
        401,
        "ticket_expired",
        "The upload ticket has expired; start the upload again",
      );
    }
    return claims;
  }
}
