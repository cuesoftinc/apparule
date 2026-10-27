import { generateKeyPairSync, randomUUID, sign } from 'node:crypto';
import type { TicketClaims } from '../ticket/ticket.service';

export const SESSION_ID = '5c2a9d1e-3b4f-4a6c-8d7e-9f0a1b2c3d4e';
export const ACCOUNT_ID = '1e2d3c4b-5a69-4788-9a0b-c1d2e3f4a5b6';

/** Test-only signer mirroring api/common's ticket issuer. */
export const makeSigner = (kid = 'test') => {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  const raw = Buffer.from(publicKey.export({ format: 'jwk' }).x as string, 'base64url');

  const issue = (overrides: Partial<TicketClaims> = {}): string => {
    const now = Math.floor(Date.now() / 1000);
    const claims: TicketClaims = {
      kid,
      jti: randomUUID(),
      account_id: ACCOUNT_ID,
      target: { kind: 'capture', id: SESSION_ID },
      poses: ['front', 'side'],
      max_files: 2,
      max_bytes: 10 * 1024 * 1024,
      iat: now,
      exp: now + 300,
      ...overrides,
    };
    const head = `v1.${Buffer.from(JSON.stringify(claims)).toString('base64url')}`;
    return `${head}.${sign(null, Buffer.from(head, 'ascii'), privateKey).toString('base64url')}`;
  };

  return { kid, publicKey: raw, issue };
};
