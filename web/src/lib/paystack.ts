// Paystack checkout (Inline JS v2) for an order's pay step. The popup only
// collects the payment: the order turns paid when api/commerce settles the
// charge from Paystack's webhook (system-design.md §6.3), so callers poll
// the order afterwards rather than trusting this callback.

const SCRIPT = "https://js.paystack.co/v2/inline.js";

export interface Checkout {
  provider: "paystack";
  reference: string;
  amount_cents: number;
  currency: string;
  email: string;
  public_key: string;
}

interface PaystackPopup {
  newTransaction(options: {
    key: string;
    email: string;
    amount: number;
    currency: string;
    reference: string;
    onSuccess: () => void;
    onCancel: () => void;
    onError?: (error: { message?: string }) => void;
  }): void;
}

declare global {
  interface Window {
    PaystackPop?: new () => PaystackPopup;
  }
}

let loading: Promise<void> | null = null;

function loadScript(): Promise<void> {
  if (typeof window === "undefined")
    return Promise.reject(new Error("no window"));
  if (window.PaystackPop) return Promise.resolve();
  loading ??= new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = SCRIPT;
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => {
      loading = null;
      reject(new Error("Paystack checkout could not load"));
    };
    document.head.appendChild(script);
  });
  return loading;
}

export type CheckoutResult = "paid" | "cancelled";

/** Opens Paystack's checkout; resolves when the customer finishes or closes it. */
export async function openCheckout(
  checkout: Checkout,
): Promise<CheckoutResult> {
  await loadScript();
  const Popup = window.PaystackPop!;
  return new Promise((resolve, reject) => {
    new Popup().newTransaction({
      key: checkout.public_key,
      email: checkout.email,
      // Minor units, as Paystack expects (kobo for NGN).
      amount: checkout.amount_cents,
      currency: checkout.currency,
      reference: checkout.reference,
      onSuccess: () => resolve("paid"),
      onCancel: () => resolve("cancelled"),
      onError: (error) => reject(new Error(error.message ?? "Checkout failed")),
    });
  });
}
