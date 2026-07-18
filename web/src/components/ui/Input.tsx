"use client";

// Input — design.md §8.2 + §8.2b extension: kind text / numeric+unit-toggle
// (cm-in) / search / textarea (0–500 counter) / currency (₦ prefix, tabular
// numerals) · state default / focus / error / disabled.
// MI-13: the cm/in unit toggle flips with a 200ms x-rotation.
import {
  useId,
  useState,
  type InputHTMLAttributes,
  type TextareaHTMLAttributes,
} from "react";
import clsx from "clsx";
import { Search } from "lucide-react";

export type InputKind = "text" | "numeric" | "search" | "textarea" | "currency";
export type MeasureUnit = "cm" | "in";

interface BaseProps {
  kind?: InputKind;
  error?: string;
  className?: string;
}

export interface InputProps
  extends BaseProps,
    Omit<InputHTMLAttributes<HTMLInputElement>, "className" | "kind"> {
  /** numeric kind: controlled unit + toggle callback (MI-13). */
  unit?: MeasureUnit;
  onUnitChange?: (unit: MeasureUnit) => void;
  /** textarea kind uses TextareaProps instead. */
  kind?: Exclude<InputKind, "textarea">;
}

export interface TextareaProps
  extends BaseProps,
    Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, "className"> {
  kind: "textarea";
  maxLength?: number;
}

// Figma master (40:76): focus = 2px accent border, error = 1.5px error
// border, disabled = 40% opacity on the whole field.
const frame = (error: boolean, disabled: boolean, multiline = false) =>
  clsx(
    "flex rounded-card bg-bg-elev px-3 transition-colors duration-120 ease-standard",
    multiline ? "flex-col items-start gap-2 py-3" : "h-11 items-center gap-2",
    "focus-within:border-2 focus-within:border-accent-start motion-reduce:transition-none",
    error ? "border-[1.5px] border-error" : "border border-border",
    disabled && "opacity-40",
  );

export function Input(props: InputProps | TextareaProps) {
  const errorId = useId();
  const { kind = "text", error, className } = props;

  if (props.kind === "textarea") {
    // omit the wrapper-level props from what reaches the <textarea>
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { kind: _kind, error: _error, className: _cn, maxLength = 500, ...rest } = props;
    const length = String(rest.value ?? "").length;
    return (
      <div className={clsx("flex flex-col gap-1", className)} data-kind="textarea">
        <div className={frame(!!error, !!rest.disabled, true)}>
          <textarea
            rows={3}
            maxLength={maxLength}
            aria-invalid={error ? true : undefined}
            aria-describedby={error ? errorId : undefined}
            className="min-h-16 w-full resize-y bg-transparent text-body text-text outline-none placeholder:text-text-2"
            {...rest}
          />
          {/* Figma master: counter sits inside the field, bottom-right. */}
          <div className="flex w-full justify-end text-micro">
            <span
              className={clsx("tnum", error ? "text-error" : "text-text-2")}
            >
              {length}/{maxLength}
            </span>
          </div>
        </div>
        {error ? (
          <span id={errorId} className="text-caption text-error">
            {error}
          </span>
        ) : null}
      </div>
    );
  }

  // omit the wrapper-level props from what reaches the <input>
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { kind: _kind, error: _error, className: _cn, unit, onUnitChange, disabled, ...rest } = props;

  return (
    <div className={clsx("flex flex-col gap-1", className)} data-kind={kind}>
      <div className={frame(!!error, !!disabled)}>
        {kind === "search" ? (
          <Search size={18} className="shrink-0 text-text-2" aria-hidden />
        ) : null}
        {kind === "currency" ? (
          <span className="shrink-0 text-body font-semibold text-text-2">
            ₦
          </span>
        ) : null}
        <input
          type={kind === "numeric" || kind === "currency" ? "text" : kind === "search" ? "search" : "text"}
          inputMode={kind === "numeric" || kind === "currency" ? "decimal" : undefined}
          disabled={disabled}
          aria-invalid={error ? true : undefined}
          aria-describedby={error ? errorId : undefined}
          className={clsx(
            "w-full bg-transparent text-body text-text outline-none placeholder:text-text-2",
            (kind === "numeric" || kind === "currency") && "tnum",
          )}
          {...rest}
        />
        {kind === "currency" ? (
          <span className="shrink-0 text-micro font-semibold text-text-2">
            NGN
          </span>
        ) : null}
        {kind === "numeric" && unit && onUnitChange ? (
          <UnitToggle unit={unit} onUnitChange={onUnitChange} disabled={disabled} />
        ) : null}
      </div>
      {error ? (
        <span id={errorId} className="text-caption text-error">
          {error}
        </span>
      ) : null}
    </div>
  );
}

/** MI-13 cm/in toggle — flips with a 3D x-rotation, 200ms.
 * Figma master (40:19): segmented pill on a border-token track; the active
 * unit fills with the text token, the inactive one reads as text-2. */
function UnitToggle({
  unit,
  onUnitChange,
  disabled,
}: {
  unit: MeasureUnit;
  onUnitChange: (unit: MeasureUnit) => void;
  disabled?: boolean;
}) {
  const [flipping, setFlipping] = useState(false);
  return (
    <button
      type="button"
      disabled={disabled}
      aria-label={`Switch units (currently ${unit})`}
      onClick={() => {
        setFlipping(true);
        onUnitChange(unit === "cm" ? "in" : "cm");
        setTimeout(() => setFlipping(false), 200);
      }}
      className={clsx(
        "flex shrink-0 items-center gap-[2px] rounded-pill bg-border p-[2px]",
        "transition-transform duration-200 ease-standard [transform-style:preserve-3d]",
        flipping && "[transform:rotateX(360deg)]",
        "motion-reduce:transition-none motion-reduce:[transform:none]",
      )}
    >
      {(["cm", "in"] as const).map((u) => (
        <span
          key={u}
          className={clsx(
            "rounded-pill px-2 py-[2px] text-micro font-semibold",
            u === unit ? "bg-text text-bg" : "text-text-2",
          )}
        >
          {u}
        </span>
      ))}
    </button>
  );
}
