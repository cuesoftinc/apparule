import { makeSigner } from "../testing/tickets";
import { TicketService } from "./ticket.service";

const signer = makeSigner("k1");
const service = new TicketService({
  ticketPublicKeys: new Map([["k1", signer.publicKey]]),
});

const codeOf = (fn: () => unknown): string => {
  try {
    fn();
  } catch (error) {
    return (
      error as { getResponse: () => { error: { code: string } } }
    ).getResponse().error.code;
  }
  return "none";
};

describe("TicketService", () => {
  it("accepts a valid capture ticket and returns its claims", () => {
    const claims = service.verify(
      signer.issue({ poses: ["side"], max_files: 1 }),
    );
    expect(claims.target.kind).toBe("capture");
    expect(claims.poses).toEqual(["side"]);
  });

  it("accepts a media ticket without poses", () => {
    const claims = service.verify(
      signer.issue({
        target: {
          kind: "post_media",
          id: "0d1e2f3a-4b5c-4d6e-8f70-81a2b3c4d5e6",
        },
        poses: undefined,
        max_files: 10,
      }),
    );
    expect(claims.max_files).toBe(10);
  });

  it("rejects a capture ticket without poses, or with an unknown pose", () => {
    expect(codeOf(() => service.verify(signer.issue({ poses: [] })))).toBe(
      "invalid_ticket",
    );
    expect(
      codeOf(() => service.verify(signer.issue({ poses: ["back" as never] }))),
    ).toBe("invalid_ticket");
  });

  it("rejects a missing, malformed or tampered ticket", () => {
    expect(codeOf(() => service.verify(undefined))).toBe("invalid_ticket");
    expect(codeOf(() => service.verify("v1.abc"))).toBe("invalid_ticket");
    const [v, , sig] = signer.issue().split(".");
    const forged = Buffer.from(
      JSON.stringify({ kid: "k1", max_bytes: 1e12 }),
    ).toString("base64url");
    expect(codeOf(() => service.verify(`${v}.${forged}.${sig}`))).toBe(
      "invalid_ticket",
    );
  });

  it("rejects a ticket from an unknown key", () => {
    expect(codeOf(() => service.verify(makeSigner("k1").issue()))).toBe(
      "invalid_ticket",
    );
  });

  it("rejects an expired ticket, allowing 30 s of skew", () => {
    const now = Math.floor(Date.now() / 1000);
    const ticket = signer.issue({ iat: now - 400, exp: now - 100 });
    expect(codeOf(() => service.verify(ticket))).toBe("ticket_expired");
    expect(codeOf(() => service.verify(signer.issue({ exp: now - 20 })))).toBe(
      "none",
    );
  });
});
