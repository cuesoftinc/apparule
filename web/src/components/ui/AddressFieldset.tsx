"use client";

// AddressFieldset — design.md §8.2: context delivery (request stepper —
// frozen per order) / profile location (city + state + country · "near me"
// explainer, X-10 tier 1) · NG-state select · prefill-from-last-order.
import clsx from "clsx";
import type { DeliveryAddress } from "@/models";
import { FormRow } from "./FormRow";
import { Input } from "./Input";
import { Select } from "./Select";

export const NG_STATES = [
  "Abia", "Adamawa", "Akwa Ibom", "Anambra", "Bauchi", "Bayelsa", "Benue",
  "Borno", "Cross River", "Delta", "Ebonyi", "Edo", "Ekiti", "Enugu",
  "FCT Abuja", "Gombe", "Imo", "Jigawa", "Kaduna", "Kano", "Katsina",
  "Kebbi", "Kogi", "Kwara", "Lagos", "Nasarawa", "Niger", "Ogun", "Ondo",
  "Osun", "Oyo", "Plateau", "Rivers", "Sokoto", "Taraba", "Yobe", "Zamfara",
] as const;

const STATE_OPTIONS = NG_STATES.map((s) => ({ value: s, label: s }));

export type AddressFieldsetContext = "delivery" | "profile-location";

export interface AddressFieldsetProps {
  context: AddressFieldsetContext;
  value: Partial<DeliveryAddress>;
  onChange: (value: Partial<DeliveryAddress>) => void;
  errors?: Partial<Record<keyof DeliveryAddress, string>>;
  disabled?: boolean;
  className?: string;
}

export function AddressFieldset({
  context,
  value,
  onChange,
  errors = {},
  disabled,
  className,
}: AddressFieldsetProps) {
  const set = (patch: Partial<DeliveryAddress>) =>
    onChange({ ...value, ...patch });

  return (
    <fieldset
      data-context={context}
      disabled={disabled}
      className={clsx("flex flex-col gap-4", className)}
    >
      {context === "delivery" ? (
        <>
          <FormRow label="Recipient name" required error={errors.recipient_name}>
            <Input
              value={value.recipient_name ?? ""}
              onChange={(e) => set({ recipient_name: e.target.value })}
              placeholder="Full name"
              error={errors.recipient_name}
            />
          </FormRow>
          <FormRow label="Phone" required error={errors.phone}>
            <Input
              value={value.phone ?? ""}
              onChange={(e) => set({ phone: e.target.value })}
              placeholder="+234…"
              error={errors.phone}
            />
          </FormRow>
          <FormRow label="Address line 1" required error={errors.line1}>
            <Input
              value={value.line1 ?? ""}
              onChange={(e) => set({ line1: e.target.value })}
              placeholder="Street address"
              error={errors.line1}
            />
          </FormRow>
          <FormRow label="Address line 2">
            <Input
              value={value.line2 ?? ""}
              onChange={(e) => set({ line2: e.target.value })}
              placeholder="Apartment, landmark (optional)"
            />
          </FormRow>
        </>
      ) : (
        <p className="text-caption text-text-2">
          Used to recommend nearby designers — optional, and never shown
          publicly.
        </p>
      )}
      <div className="grid grid-cols-2 gap-4">
        <FormRow label="City" required={context === "delivery"} error={errors.city}>
          <Input
            value={value.city ?? ""}
            onChange={(e) => set({ city: e.target.value })}
            placeholder="City"
            error={errors.city}
          />
        </FormRow>
        <FormRow label="State" required={context === "delivery"} error={errors.state}>
          <Select
            aria-label="State"
            options={STATE_OPTIONS}
            value={value.state || undefined}
            onValueChange={(state) => set({ state })}
            placeholder="Select state"
            error={errors.state}
            disabled={disabled}
          />
        </FormRow>
      </div>
      <FormRow label="Country" required={context === "delivery"} error={errors.country}>
        <Input
          value={value.country ?? "NG"}
          onChange={(e) => set({ country: e.target.value })}
          error={errors.country}
        />
      </FormRow>
    </fieldset>
  );
}
