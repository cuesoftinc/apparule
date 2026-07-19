"use client";

// CountdownRing — design.md §8.2b: 3 / 2 / 1 (ring progress + numeral) —
// the MI-12 capture countdown. Ring arc fills with the remaining fraction
// (slow/standard tokens); the numeral pops per tick. Reduced motion: static
// arc + numeral swap only.
import clsx from "clsx";

export interface CountdownRingProps {
  value: 1 | 2 | 3;
  /** Diameter in px. */
  size?: number;
  className?: string;
}

export function CountdownRing({
  value,
  size = 96,
  className,
}: CountdownRingProps) {
  const stroke = 4;
  const r = (size - stroke) / 2;
  const c = size / 2;
  const circumference = 2 * Math.PI * r;
  const fraction = value / 3;

  return (
    <div
      role="timer"
      aria-label={`Capturing in ${value}`}
      data-value={value}
      className={clsx("relative grid place-items-center", className)}
      style={{ width: size, height: size }}
    >
      {/* On-media capture UI — raw white by design (web-implementation.md §3
          token-exception note). */}
      <svg
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        aria-hidden="true"
      >
        <circle
          cx={c}
          cy={c}
          r={r}
          fill="none"
          stroke="white"
          strokeOpacity={0.25}
          strokeWidth={stroke}
        />
        <circle
          cx={c}
          cy={c}
          r={r}
          fill="none"
          stroke="white"
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={circumference * (1 - fraction)}
          transform={`rotate(-90 ${c} ${c})`}
          className="transition-[stroke-dashoffset] duration-300 ease-standard motion-reduce:transition-none"
        />
      </svg>
      <span
        key={value}
        className={clsx(
          "absolute text-display font-bold text-white",
          "animate-[pop-in_300ms_var(--ap-ease-standard)] motion-reduce:animate-none",
        )}
      >
        {value}
      </span>
    </div>
  );
}
