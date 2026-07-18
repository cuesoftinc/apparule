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

const frame = (error: boolean, disabled: boolean) =>
  clsx(
    "flex items-center gap-2 rounded-card border bg-bg-elev px-3 transition-colors duration-120 ease-standard",
    "focus-within:border-accent-start motion-reduce:transition-none",
    error ? "border-error" : "border-border",
    disabled && "opacity-50",
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
        <div className={clsx(frame(!!error, !!rest.disabled), "py-2")}>
          <textarea
            rows={3}
            maxLength={maxLength}
            aria-invalid={error ? true : undefined}
            aria-describedby={error ? errorId : undefined}
            className="min-h-20 w-full resize-y bg-transparent text-body text-text outline-none placeholder:text-text-2"
            {...rest}
          />
        </div>
        <div className="flex justify-between text-micro text-text-2">
          {error ? (
            <span id={errorId} className="text-error">
              {error}
            </span>
          ) : (
            <span />
          )}
          <span className="tnum">
            {length}/{maxLength}
          </span>
        </div>
      </div>
    );
  }

  // omit the wrapper-level props from what reaches the <input>
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { kind: _kind, error: _error, className: _cn, unit, onUnitChange, disabled, ...rest } = props;

  return (
    <div className={clsx("flex flex-col gap-1", className)} data-kind={kind}>
      <div className={clsx(frame(!!error, !!disabled), "h-11")}>
        {kind === "search" ? (
          <Search size={18} className="shrink-0 text-text-2" aria-hidden />
        ) : null}
        {kind === "currency" ? (
          <span className="shrink-0 text-body-lg text-text-2">₦</span>
        ) : null}
        <input
          type={kind === "numeric" || kind === "currency" ? "text" : kind === "search" ? "search" : "text"}
          inputMode={kind === "numeric" || kind === "currency" ? "decimal" : undefined}
          disabled={disabled}
          aria-invalid={error ? true : undefined}
          aria-describedby={error ? errorId : undefined}
          className={clsx(
            "w-full bg-transparent text-body-lg text-text outline-none placeholder:text-text-2",
            (kind === "numeric" || kind === "currency") && "tnum",
          )}
          {...rest}
        />
        {kind === "numeric" && unit && onUnitChange ? (
          <UnitToggle unit={unit} onUnitChange={onUnitChange} disabled={disabled} />
        ) : null}
      </div>
      {error ? (
        <span id={errorId} className="text-micro text-error">
          {error}
        </span>
      ) : null}
    </div>
  );
}

/** MI-13 cm/in toggle — flips with a 3D x-rotation, 200ms. */
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
        "shrink-0 rounded-pill border border-border px-2 py-0.5 text-micro font-semibold text-text-2",
        "transition-transform duration-200 ease-standard [transform-style:preserve-3d]",
        flipping && "[transform:rotateX(360deg)]",
        "motion-reduce:transition-none motion-reduce:[transform:none]",
      )}
    >
      {unit}
    </button>
  );
}
