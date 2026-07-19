"use client";

// DateInput — design.md §8.2b: state default / focus / error / disabled ·
// calendar popover (standalone DatePickerPopover, as built 2026-07-17) ·
// min-date rules (due_at ≥ today+1; target date ≥ today+turnaround
// soft-warn). date-fns for the math (allowed utility reuse).
import { useState } from "react";
import * as RadixPopover from "@radix-ui/react-popover";
import clsx from "clsx";
import {
  addDays,
  addMonths,
  eachDayOfInterval,
  endOfMonth,
  endOfWeek,
  format,
  isBefore,
  isSameDay,
  isSameMonth,
  startOfDay,
  startOfMonth,
  startOfWeek,
} from "date-fns";
import { Calendar, ChevronLeft, ChevronRight } from "lucide-react";

export interface DateInputProps {
  value: Date | null;
  onChange: (date: Date) => void;
  /** Earliest selectable day (e.g. tomorrow for due_at). */
  minDate?: Date;
  /** Soft-warn threshold (target date < today+turnaround warns, not blocks). */
  softMinDate?: Date;
  softWarning?: string;
  error?: string;
  disabled?: boolean;
  placeholder?: string;
  "aria-label": string;
  className?: string;
}

export function DateInput({
  value,
  onChange,
  minDate,
  softMinDate,
  softWarning = "That's earlier than the designer's stated turnaround",
  error,
  disabled,
  placeholder = "Pick a date",
  className,
  ...rest
}: DateInputProps) {
  const [open, setOpen] = useState(false);
  const showSoftWarning =
    value !== null &&
    softMinDate !== undefined &&
    isBefore(startOfDay(value), startOfDay(softMinDate));

  return (
    <div className={clsx("flex flex-col gap-1", className)}>
      <RadixPopover.Root open={open} onOpenChange={setOpen}>
        <RadixPopover.Trigger
          disabled={disabled}
          aria-invalid={error ? true : undefined}
          className={clsx(
            // Figma form-kit frame (74:801): 14px value, 1.5px error border,
            // 2px accent focus, 40% disabled.
            "flex h-11 items-center justify-between gap-2 rounded-card bg-bg-elev px-3 text-body",
            "transition-colors duration-120 ease-standard motion-reduce:transition-none",
            "disabled:opacity-40",
            error
              ? "border-[1.5px] border-error"
              : "border border-border focus:border-2 focus:border-accent-start",
            value ? "text-text" : "text-text-2",
          )}
          {...rest}
        >
          <span className={value ? "tnum" : undefined}>
            {value ? format(value, "d MMM yyyy") : placeholder}
          </span>
          <Calendar size={18} className="text-text-2" />
        </RadixPopover.Trigger>
        <RadixPopover.Portal>
          <RadixPopover.Content
            sideOffset={4}
            // Collision-clamp canon (org SKILL.md, 2026-07-19): the calendar
            // must never clip off a screen edge (found live as a
            // period-picker clipping right on expendit) — 8px viewport pad.
            collisionPadding={8}
            // z-40 (sheet layer): the calendar opens from inside the quote
            // Sheet (z-40 dialog) — at the z-20 dropdown layer the dialog
            // paints over it and swallows every click, so the due date could
            // never be picked. Same layer as the sheet, later in portal
            // order wins (the same class of fix as Select, W3).
            className="z-40 rounded-card border border-border bg-bg-elev p-3 shadow-lg"
          >
            <DatePickerPopover
              value={value}
              minDate={minDate}
              onSelect={(date) => {
                onChange(date);
                setOpen(false);
              }}
            />
          </RadixPopover.Content>
        </RadixPopover.Portal>
      </RadixPopover.Root>
      {error ? (
        <span className="text-micro text-error">{error}</span>
      ) : showSoftWarning ? (
        <span className="text-micro text-warn">{softWarning}</span>
      ) : null}
    </div>
  );
}

/** DatePickerPopover — the standalone month-grid calendar (bespoke, no kit). */
export function DatePickerPopover({
  value,
  minDate,
  onSelect,
}: {
  value: Date | null;
  minDate?: Date;
  onSelect: (date: Date) => void;
}) {
  const [month, setMonth] = useState(() => startOfMonth(value ?? new Date()));
  const days = eachDayOfInterval({
    start: startOfWeek(startOfMonth(month), { weekStartsOn: 1 }),
    end: endOfWeek(endOfMonth(month), { weekStartsOn: 1 }),
  });
  const min = minDate ? startOfDay(minDate) : undefined;

  return (
    <div data-testid="date-picker" className="w-64 select-none">
      <div className="mb-2 flex items-center justify-between">
        <button
          type="button"
          aria-label="Previous month"
          onClick={() => setMonth((m) => addMonths(m, -1))}
          className="grid size-8 place-items-center rounded-pill text-text-2 hover:bg-border/40"
        >
          <ChevronLeft size={16} />
        </button>
        <span className="text-body font-semibold">{format(month, "MMMM yyyy")}</span>
        <button
          type="button"
          aria-label="Next month"
          onClick={() => setMonth((m) => addMonths(m, 1))}
          className="grid size-8 place-items-center rounded-pill text-text-2 hover:bg-border/40"
        >
          <ChevronRight size={16} />
        </button>
      </div>
      <div className="grid grid-cols-7 gap-y-0.5 text-center">
        {["M", "T", "W", "T2", "F", "S", "S2"].map((d) => (
          <span key={d} className="py-1 text-micro text-text-2">
            {d.replace(/\d/, "")}
          </span>
        ))}
        {days.map((day) => {
          const outside = !isSameMonth(day, month);
          const disabled = min !== undefined && isBefore(day, min);
          const selected = value !== null && isSameDay(day, value);
          return (
            <button
              key={day.toISOString()}
              type="button"
              disabled={disabled}
              onClick={() => onSelect(day)}
              aria-pressed={selected || undefined}
              className={clsx(
                "tnum mx-auto grid size-8 place-items-center rounded-pill text-body",
                selected
                  ? "bg-accent-gradient font-semibold text-on-accent"
                  : "text-text hover:bg-border/40",
                outside && !selected && "text-text-2/60",
                disabled && "cursor-not-allowed text-text-2/30 hover:bg-transparent",
              )}
            >
              {format(day, "d")}
            </button>
          );
        })}
      </div>
    </div>
  );
}

/** due_at rule from the contract: earliest tomorrow. */
export function minDueDate(now: Date = new Date()): Date {
  return startOfDay(addDays(now, 1));
}
