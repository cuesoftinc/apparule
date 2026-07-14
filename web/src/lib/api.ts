// Minimal API client for the api/common (Go) service.
import { env } from "@/config/env";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${env.apiBaseUrl}${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", ...(init?.headers ?? {}) },
  });
  if (!res.ok) {
    throw new Error(`API ${path} failed with status ${res.status}`);
  }
  return (await res.json()) as T;
}

export interface AuthResponse {
  message: string;
  token?: string;
  project?: string;
  email?: string;
  scope?: string;
}

export const api = {
  health: () => request<{ status: string; message: string }>("/health"),
  googleLogin: (idToken: string) =>
    request<AuthResponse>("/api/auth/google", {
      method: "POST",
      body: JSON.stringify({ id_token: idToken }),
    }),
  emailLogin: (email: string) =>
    request<AuthResponse>("/api/auth/email", {
      method: "POST",
      body: JSON.stringify({ email }),
    }),
};
