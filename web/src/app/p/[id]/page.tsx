// /p/{post_id} — public post permalink (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { PostPermalink } from "./PostPermalink";

export const metadata: Metadata = {
  title: "Post — Apparule",
};

export default async function PostPermalinkPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <PostPermalink postId={id} />;
}
