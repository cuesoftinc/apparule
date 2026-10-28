import { describe, expect, it } from "vitest";
import { ApiError } from "@/lib/api";
import {
  getOAuthRedirectErrorMessage,
  getSsoCompletionErrorMessage,
} from "./oauth-errors";
import { readCallbackContract } from "./callback-contract";

const params = (q: string) => new URLSearchParams(q);

describe("oauth redirect messages", () => {
  it("maps known codes and falls back for unknown ones", () => {
    expect(getOAuthRedirectErrorMessage(params("error=access_denied"))).toMatch(
      /cancelled/,
    );
    expect(getOAuthRedirectErrorMessage(params("error=weird"))).toMatch(
      /could not be completed/,
    );
    expect(getOAuthRedirectErrorMessage(params("message=x"))).toMatch(
      /could not be completed/,
    );
  });

  it("returns null when there is no error", () => {
    expect(getOAuthRedirectErrorMessage(params(""))).toBeNull();
  });
});

describe("exchange failure messages", () => {
  it("distinguishes a spent handoff, an outage and a network failure", () => {
    expect(
      getSsoCompletionErrorMessage(new ApiError("handoff_invalid", "x", 401)),
    ).toMatch(/already used/);
    expect(
      getSsoCompletionErrorMessage(new ApiError("internal", "x", 500)),
    ).toMatch(/temporarily unavailable/);
    expect(getSsoCompletionErrorMessage(new TypeError("fetch"))).toMatch(
      /could not reach/,
    );
    expect(getSsoCompletionErrorMessage(new Error("x"))).toMatch(
      /could not be completed/,
    );
  });
});

describe("callback URL contract", () => {
  const handoff = "a".repeat(43);
  it("accepts a bare handoff or an empty query", () => {
    expect(readCallbackContract(`?handoff=${handoff}`, "")).toEqual({
      kind: "exchange",
      handoff,
    });
    expect(readCallbackContract("", "")).toEqual({
      kind: "exchange",
      handoff: null,
    });
  });

  it("rejects hashes, extra keys, repeats and malformed handoffs", () => {
    expect(readCallbackContract("", "#x").kind).toBe("invalid");
    expect(readCallbackContract(`?handoff=${handoff}&a=1`, "").kind).toBe(
      "invalid",
    );
    expect(
      readCallbackContract(`?handoff=${handoff}&handoff=${handoff}`, "").kind,
    ).toBe("invalid");
    expect(readCallbackContract("?handoff=short", "").kind).toBe("invalid");
  });

  it("surfaces oauth errors and rejects unknown keys", () => {
    expect(readCallbackContract("?error=access_denied", "").kind).toBe(
      "oauth-error",
    );
    expect(readCallbackContract("?foo=1", "").kind).toBe("invalid");
  });
});
