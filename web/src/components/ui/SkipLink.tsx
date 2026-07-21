// SkipLink — fleet a11y canon (P15): the first focusable element on every
// route. Sits fixed above the viewport until focus lands on it, then slides
// into the top-left as a token-styled pill; activating it moves focus to
// the route's single <main id="main" tabIndex={-1}>.
export function SkipLink() {
  return (
    <a
      href="#main"
      className="fixed left-3 top-3 z-50 -translate-y-[150%] rounded-card border border-border bg-bg-elev px-4 py-2 text-sm font-semibold text-text focus:translate-y-0"
    >
      Skip to content
    </a>
  );
}
