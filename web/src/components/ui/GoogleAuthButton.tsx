"use client";

// GoogleAuthButton — the single auth CTA (X-1), design.md §8.2b contract:
// Google 'G' mark + "Continue with Google" · state: default / pressed /
// loading / disabled · theme via tokens.
//
// Behavior (web-standard TEST_MODE rule): with NEXT_PUBLIC_TEST_MODE=1 the
// sign-in resolves against the mock server and routes straight to
// /dashboard; without it, the stub provider reports
// "Connect Firebase at integration" (no Firebase dependency yet).
import { useState } from "react";
import { useRouter } from "next/navigation";
import clsx from "clsx";
import { useAuth } from "@/auth/AuthContext";
import { GoogleG } from "@/components/icons/GoogleG";
import { Spinner } from "@/components/ui/Spinner";

export interface GoogleAuthButtonProps {
  disabled?: boolean;
  /** Route pushed after a successful sign-in. */
  redirectTo?: string;
  className?: string;
}

export function GoogleAuthButton({
  disabled = false,
  redirectTo = "/dashboard",
  className,
}: GoogleAuthButtonProps) {
  const router = useRouter();
  const { signInWithGoogle } = useAuth();
  const [loading, setLoading] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  async function handleClick() {
    if (loading || disabled) return;
    setLoading(true);
    setNotice(null);
    const result = await signInWithGoogle();
    if (result.ok) {
      router.push(redirectTo);
      return; // keep the loading state through the navigation
    }
    setLoading(false);
    if (result.code === "popup_dismissed") {
      // silent return, screen unchanged (flows/auth.md §4)
      return;
    }
    setNotice(result.message);
  }

  return (
    <div className={clsx("flex flex-col items-stretch gap-2", className)}>
      <button
        type="button"
        onClick={handleClick}
        disabled={disabled || loading}
        aria-busy={loading}
        className={clsx(
          // Figma master (83:887): 48px, radius/card, hairline border,
          // 14px semibold; loading keeps the G and swaps the label for a
          // spinner; pressed tints the surface.
          "flex h-12 items-center justify-center gap-3 rounded-card border border-border bg-bg-elev px-6",
          "text-body font-semibold text-text",
          "transition-transform duration-120 ease-standard",
          "enabled:active:scale-[0.98] enabled:active:bg-[rgba(128,128,128,0.18)]",
          "disabled:opacity-40 disabled:cursor-not-allowed",
          "motion-reduce:transition-none motion-reduce:active:scale-100",
        )}
      >
        <GoogleG size={18} />
        {loading ? (
          <Spinner size={20} kind="neutral" />
        ) : (
          <span>Continue with Google</span>
        )}
      </button>
      {notice ? (
        <p role="status" className="text-center text-caption text-text-2">
          {notice}
        </p>
      ) : null}
    </div>
  );
}
