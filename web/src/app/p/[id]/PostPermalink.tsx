"use client";

// /p/{post_id} — public post permalink (pages.md B2 note): the MI-9 share
// target; renders post detail with the request CTA for signed-in users.
import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import type { Post } from "@/models";
import { useAuth } from "@/auth/AuthContext";
import { AppBar } from "@/components/ui/AppBar";
import { PostDetailView } from "@/components/dashboard/post/PostDetailView";
import { PostOptionsSheet } from "@/components/dashboard/feed/PostOptionsSheet";
import { RequestStepperSheet } from "@/components/dashboard/feed/RequestStepperSheet";
import { ToastProvider } from "@/components/dashboard/toast-context";

export function PostPermalink({ postId }: { postId: string }) {
  const { status } = useAuth();
  const router = useRouter();
  const [requestPost, setRequestPost] = useState<Post | null>(null);
  const [optionsPost, setOptionsPost] = useState<Post | null>(null);
  const signedIn = status === "signed_in";

  return (
    <ToastProvider>
      <AppBar
        kind="sub"
        title="Post"
        onBack={() => router.back()}
        trailing={
          signedIn ? (
            <Link href="/dashboard" className="text-body text-link">
              Open app
            </Link>
          ) : (
            <Link href="/signin" className="text-body text-link">
              Sign in
            </Link>
          )
        }
      />
      <main className="mx-auto w-full max-w-4xl px-4 py-6">
        <h1 className="sr-only">Post</h1>
        <PostDetailView
          postId={postId}
          onRequest={signedIn ? (post) => setRequestPost(post) : undefined}
          onOverflow={signedIn ? (post) => setOptionsPost(post) : undefined}
        />
      </main>
      <RequestStepperSheet
        post={requestPost}
        onOpenChange={(open) => {
          if (!open) setRequestPost(null);
        }}
      />
      <PostOptionsSheet
        post={optionsPost}
        onOpenChange={(open) => {
          if (!open) setOptionsPost(null);
        }}
      />
    </ToastProvider>
  );
}
