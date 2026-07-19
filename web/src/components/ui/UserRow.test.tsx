import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { UserRow } from "./UserRow";

describe("UserRow (§8.2b, MI-7)", () => {
  it.each(["follow", "following", "none"] as const)(
    "renders trailing=%s",
    (trailing) => {
      const { container } = render(
        <UserRow username="tunde.o" trailing={trailing} />,
      );
      expect(
        container.querySelector(`[data-trailing="${trailing}"]`),
      ).not.toBeNull();
      if (trailing === "none") {
        expect(
          screen.queryByRole("button", { name: /follow/i }),
        ).not.toBeInTheDocument();
      }
    },
  );

  it("Follow fires onFollow (gradient CTA)", async () => {
    const onFollow = vi.fn();
    render(
      <UserRow username="tunde.o" trailing="follow" onFollow={onFollow} />,
    );
    await userEvent.click(screen.getByRole("button", { name: "Follow" }));
    expect(onFollow).toHaveBeenCalledOnce();
  });

  it("Following routes to the confirm path, never direct unfollow (MI-7)", async () => {
    const onFollowingTap = vi.fn();
    render(
      <UserRow
        username="amara.designs"
        trailing="following"
        onFollowingTap={onFollowingTap}
      />,
    );
    await userEvent.click(screen.getByRole("button", { name: "Following" }));
    expect(onFollowingTap).toHaveBeenCalledOnce();
  });

  it("renders meta line + avatar sizes 32/44", () => {
    const { container } = render(
      <UserRow username="tunde.o" meta="Agbada · Lagos" avatarSize={32} />,
    );
    expect(screen.getByText("Agbada · Lagos")).toBeInTheDocument();
    expect(container.querySelector('[data-size="32"]')).not.toBeNull();
  });
});
