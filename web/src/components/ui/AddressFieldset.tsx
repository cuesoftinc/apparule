"use client";

// AddressFieldset — design.md §8.2: context delivery (request stepper —
// frozen per order) / profile location (city + state + country · "near me"
// explainer, X-10 tier 1) · NG-state select · prefill-from-last-order.
import { useId } from "react";
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
  // Programmatic label→control association (semantic-forms rule).
  const idBase = useId();
  const fieldId = (name: string) => `${idBase}-${name}`;

  return (
    <fieldset
      data-context={context}
      disabled={disabled}
      className={clsx("flex flex-col gap-4", className)}
    >
      {/* Figma master (74:801): address → city → state → country → phone,
          stacked full-width; recipient/line-2 are web data-model additions */}
      {context === "delivery" ? (
        <>
          <FormRow label="Recipient name" htmlFor={fieldId("recipient")} required error={errors.recipient_name}>
            <Input
              id={fieldId("recipient")}
              value={value.recipient_name ?? ""}
              onChange={(e) => set({ recipient_name: e.target.value })}
              placeholder="Full name"
              error={errors.recipient_name}
            />
          </FormRow>
          <FormRow label="Address line 1" htmlFor={fieldId("line1")} required error={errors.line1}>
            <Input
              id={fieldId("line1")}
              value={value.line1 ?? ""}
              onChange={(e) => set({ line1: e.target.value })}
              placeholder="14 Adeola Odeku St"
              error={errors.line1}
            />
          </FormRow>
          <FormRow label="Address line 2" htmlFor={fieldId("line2")}>
            <Input
              id={fieldId("line2")}
              value={value.line2 ?? ""}
              onChange={(e) => set({ line2: e.target.value })}
              placeholder="Apartment, landmark (optional)"
            />
          </FormRow>
        </>
      ) : null}
      <FormRow label="City" htmlFor={fieldId("city")} required={context === "delivery"} error={errors.city}>
        <Input
          id={fieldId("city")}
          value={value.city ?? ""}
          onChange={(e) => set({ city: e.target.value })}
          placeholder="Ikeja"
          error={errors.city}
        />
      </FormRow>
      <FormRow label="State" required={context === "delivery"} error={errors.state}>
        <Select
          aria-label="State"
          options={STATE_OPTIONS}
          value={value.state || undefined}
          onValueChange={(state) => set({ state })}
          placeholder="Lagos"
          error={errors.state}
          disabled={disabled}
        />
      </FormRow>
      <FormRow label="Country" required={context === "delivery"} error={errors.country}>
        <Select
          aria-label="Country"
          options={[{ value: "NG", label: "Nigeria" }]}
          value={value.country ?? "NG"}
          onValueChange={(country) => set({ country })}
          error={errors.country}
          disabled={disabled}
        />
      </FormRow>
      {context === "delivery" ? (
        <>
          <FormRow label="Phone" htmlFor={fieldId("phone")} required error={errors.phone}>
            <Input
              id={fieldId("phone")}
              value={value.phone ?? ""}
              onChange={(e) => set({ phone: e.target.value })}
              placeholder="+234 801 234 5678"
              error={errors.phone}
            />
          </FormRow>
          <p className="text-caption text-text-2">
            Saved with this order — address changes never affect placed orders
          </p>
        </>
      ) : (
        <div className="flex flex-col gap-1">
          <p className="text-caption text-text-2">
            Used to recommend designers near you
          </p>
          <p className="text-caption text-text-2">
            Pre-fills from your last order
          </p>
        </div>
      )}
    </fieldset>
  );
}
