// MI-3: the first-ever save shows a "Saved to your looks" toast with a link
// (design.md §4). Once per browser — saved state itself lives server-side;
// this only gates the one-time toast.
import type { ToastInput } from "./toast-context";

const KEY = "apparule.first-save-toast";

export function maybeFirstSaveToast(
  showToast: (input: ToastInput) => void,
  username: string | null,
): void {
  try {
    if (window.localStorage.getItem(KEY)) return;
    window.localStorage.setItem(KEY, "1");
  } catch {
    return; // storage unavailable — skip rather than re-toast forever
  }
  showToast({
    kind: "success",
    message: "Saved to your looks",
    link: {
      href: username ? `/dashboard/${username}` : "/dashboard/profile",
      label: "View",
    },
  });
}
