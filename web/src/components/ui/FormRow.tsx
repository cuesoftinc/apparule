// FormRow — design.md §8.2: label + control + helper/error · state
// default / focus / error / disabled (profile & settings editors).
// State lives on the wrapped control; the row provides layout + copy.
import { type ReactNode } from "react";
import clsx from "clsx";

export interface FormRowProps {
  label: string;
  /** Ties the label to the control. */
  htmlFor?: string;
  helper?: string;
  error?: string;
  required?: boolean;
  children: ReactNode;
  className?: string;
}

export function FormRow({
  label,
  htmlFor,
  helper,
  error,
  required = false,
  children,
  className,
}: FormRowProps) {
  return (
    <div className={clsx("flex flex-col gap-1.5", className)} data-error={!!error || undefined}>
      <label htmlFor={htmlFor} className="text-body font-semibold text-text">
        {label}
        {required ? <span className="text-error"> *</span> : null}
      </label>
      {children}
      {error ? (
        <p className="text-micro text-error">{error}</p>
      ) : helper ? (
        <p className="text-micro text-text-2">{helper}</p>
      ) : null}
    </div>
  );
}
