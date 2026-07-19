// B1 feed — screen-state parity (three-frame rule): loading skeletons,
// empty with explore CTA, default with posts + caught-up divider (MI-6).
import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import type { Post } from "@/models";

const useFeedMock = vi.fn();
vi.mock("@/controllers/use-feed", () => ({
  useFeed: (...a: unknown[]) => useFeedMock(...a),
}));
vi.mock("@/controllers/use-vault", () => ({
  useVault: () => ({
    sessions: [],
    latest: [],
    freshness: null,
    loading: false,
    error: null,
    reload: vi.fn(),
    addManualSession: vi.fn(),
    deleteSession: vi.fn(),
  }),
}));
vi.mock("@/controllers/use-suggestions", () => ({
  useSuggestions: () => ({ rows: [], loading: false, toggleFollow: vi.fn() }),
}));
vi.mock("@/controllers/auth/AuthContext", () => ({
  useAuth: () => ({
    status: "signed_in",
    account: { username: "kiki.adeyemi", display_name: "Kiki Adeyemi" },
  }),
}));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: vi.fn(), back: vi.fn(), replace: vi.fn() }),
}));

import { FeedView } from "./FeedView";
import { ToastProvider } from "../toast-context";

const feedBase = {
  posts: [] as Post[],
  loading: false,
  loadingMore: false,
  error: null,
  caughtUp: false,
  reload: vi.fn(),
  loadMore: vi.fn(),
  toggleLike: vi.fn(),
  toggleSave: vi.fn(),
};

const post: Post = {
  id: "post-1",
  designer: {
    id: "des-amara",
    username: "amara.designs",
    display_name: "Amara Designs",
    avatar_url: null,
    verified: true,
  },
  caption: "Ankara midi gown",
  style_tags: ["ankara"],
  base_price_cents: 4_500_000,
  currency: "NGN",
  turnaround_days: 14,
  media: [
    {
      id: "m0",
      post_id: "post-1",
      url: "/demo/outfit-w00.jpg",
      position: 0,
      alt_text: "Ankara gown",
      width: 1024,
      height: 1280,
    },
  ],
  like_count: 214,
  comment_count: 3,
  liked: false,
  saved: false,
  created_at: new Date().toISOString(),
};

function renderFeed() {
  return render(
    <ToastProvider>
      <FeedView />
    </ToastProvider>,
  );
}

beforeEach(() => {
  useFeedMock.mockReset();
});

describe("FeedView — three-frame rule", () => {
  it("loading: renders skeleton cards", () => {
    useFeedMock.mockReturnValue({ ...feedBase, loading: true });
    renderFeed();
    expect(document.querySelector('[aria-busy="true"]')).toBeTruthy();
  });

  it("empty: follow-designers copy + explore CTA", () => {
    useFeedMock.mockReturnValue(feedBase);
    renderFeed();
    expect(
      screen.getByText("Follow designers to fill your feed"),
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Explore designers" }),
    ).toBeInTheDocument();
  });

  it("default: posts render with story rail + caught-up divider", () => {
    useFeedMock.mockReturnValue({
      ...feedBase,
      posts: [post],
      caughtUp: true,
    });
    renderFeed();
    expect(screen.getByTestId("feed-list")).toBeInTheDocument();
    expect(screen.getAllByText("amara.designs").length).toBeGreaterThan(0);
    expect(screen.getByText(/all caught up/i)).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Request this outfit" }),
    ).toBeInTheDocument();
  });
});
