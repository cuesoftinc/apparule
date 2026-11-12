// B7 sub-screen — Privacy & consent: consent history list, loading skeleton,
// and the error-with-retry state added alongside AccountDataView's loading
// skeleton (issue #455).
import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const reload = vi.fn();
const useSettingsMock = vi.fn();
vi.mock("@/controllers/use-settings", () => ({
  useSettings: (...a: unknown[]) => useSettingsMock(...a),
}));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn(), back: vi.fn() }),
}));

import { PrivacySettingsView } from "./PrivacySettingsView";

beforeEach(() => {
  reload.mockReset();
  useSettingsMock.mockReturnValue({
    consent: [],
    loading: false,
    error: null,
    reload,
  });
});

describe("PrivacySettingsView", () => {
  it("shows a loading skeleton while consent history loads", () => {
    useSettingsMock.mockReturnValue({
      consent: [],
      loading: true,
      error: null,
      reload,
    });
    render(<PrivacySettingsView />);
    expect(screen.getByText("Consent history").parentElement).toHaveAttribute(
      "aria-labelledby",
      "consent-history-h",
    );
    expect(document.querySelector('[aria-busy="true"]')).not.toBeNull();
  });

  it("renders the consent history list once loaded", () => {
    useSettingsMock.mockReturnValue({
      consent: [
        {
          document: "tos",
          version: "1.0",
          accepted_at: "2026-06-09T00:00:00Z",
        },
      ],
      loading: false,
      error: null,
      reload,
    });
    render(<PrivacySettingsView />);
    expect(screen.getByTestId("consent-history")).toBeInTheDocument();
    expect(screen.getByText(/Terms of Service/)).toBeInTheDocument();
  });

  it("shows an empty message when there are no consent records", () => {
    render(<PrivacySettingsView />);
    expect(screen.getByText("No consent records yet.")).toBeInTheDocument();
  });

  it("shows an error with retry when consent history fails to load, and retry calls reload", async () => {
    useSettingsMock.mockReturnValue({
      consent: [],
      loading: false,
      error: "Failed to load settings",
      reload,
    });
    render(<PrivacySettingsView />);
    expect(screen.getByRole("alert")).toHaveTextContent(
      "Consent history couldn't load.",
    );
    await userEvent.click(screen.getByRole("button", { name: "Retry" }));
    expect(reload).toHaveBeenCalledOnce();
  });
});
