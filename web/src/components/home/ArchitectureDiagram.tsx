// A7 architecture mini-diagram (canvas 264:8529) — bespoke token-based
// boxes + hairline connectors: clients → Go API → Python CV → stores.
// Bespoke SVG/DOM per the component-reuse policy (no chart/diagram libs).
import clsx from "clsx";

function Node({
  children,
  className,
}: {
  children: string;
  className?: string;
}) {
  return (
    <div
      className={clsx(
        "flex h-9 items-center justify-center rounded-card border border-border bg-bg-elev px-2 text-caption text-text",
        className,
      )}
    >
      {children}
    </div>
  );
}

function Connector({ className }: { className?: string }) {
  return <span aria-hidden className={clsx("h-6 w-px bg-border", className)} />;
}

export function ArchitectureDiagram({ className }: { className?: string }) {
  return (
    <div
      data-testid="architecture-diagram"
      role="img"
      aria-label="Architecture: the Flutter app and Next.js web talk to the Go API (api/common), which calls the Python CV service (MediaPipe + SMPL) and stores data in Postgres and S3 media storage"
      className={clsx("w-full max-w-[300px]", className)}
    >
      <div className="grid grid-cols-2 gap-5">
        <Node>Flutter app</Node>
        <Node>Next.js web</Node>
      </div>
      <div className="grid grid-cols-2 justify-items-center">
        <Connector />
        <Connector />
      </div>
      <Node>Go API · api/common</Node>
      <div className="flex justify-center">
        <Connector />
      </div>
      <Node>Python CV · MediaPipe + SMPL</Node>
      <div className="flex justify-center">
        <Connector />
      </div>
      <div className="grid grid-cols-2 gap-5">
        <Node>Postgres</Node>
        <Node>S3 media</Node>
      </div>
    </div>
  );
}
