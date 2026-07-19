// MI-3 first-save toast gate (system QA: the spec'd "Saved to your looks"
// toast was missing from the product).
import { beforeEach, describe, expect, it, vi } from "vitest";
import { maybeFirstSaveToast } from "./first-save";

describe("maybeFirstSaveToast (MI-3)", () => {
  beforeEach(() => {
    window.localStorage.clear();
  });

  it("toasts once with a link to the saver's looks", () => {
    const showToast = vi.fn();
    maybeFirstSaveToast(showToast, "kiki.adeyemi");
    expect(showToast).toHaveBeenCalledWith({
      kind: "success",
      message: "Saved to your looks",
      link: { href: "/dashboard/kiki.adeyemi", label: "View" },
    });
  });

  it("never re-toasts after the first save", () => {
    const showToast = vi.fn();
    maybeFirstSaveToast(showToast, "kiki.adeyemi");
    maybeFirstSaveToast(showToast, "kiki.adeyemi");
    expect(showToast).toHaveBeenCalledTimes(1);
  });

  it("falls back to the profile redirect without a username", () => {
    const showToast = vi.fn();
    maybeFirstSaveToast(showToast, null);
    expect(showToast).toHaveBeenCalledWith(
      expect.objectContaining({
        link: { href: "/dashboard/profile", label: "View" },
      }),
    );
  });
});
