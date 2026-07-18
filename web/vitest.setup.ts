import "@testing-library/jest-dom/vitest";

// Node ≥22 defines an experimental global `localStorage` (undefined unless
// --localstorage-file is passed) that shadows jsdom's implementation under
// vitest. Install a plain in-memory Web Storage for tests.
class MemoryStorage implements Storage {
  private map = new Map<string, string>();

  get length(): number {
    return this.map.size;
  }
  clear(): void {
    this.map.clear();
  }
  getItem(key: string): string | null {
    return this.map.has(key) ? (this.map.get(key) as string) : null;
  }
  key(index: number): string | null {
    return [...this.map.keys()][index] ?? null;
  }
  removeItem(key: string): void {
    this.map.delete(key);
  }
  setItem(key: string, value: string): void {
    this.map.set(key, String(value));
  }
}

// jsdom lacks a handful of APIs the Radix primitives touch.
if (typeof window !== "undefined") {
  window.HTMLElement.prototype.scrollIntoView ??= () => {};
  window.HTMLElement.prototype.hasPointerCapture ??= () => false;
  window.HTMLElement.prototype.setPointerCapture ??= () => {};
  window.HTMLElement.prototype.releasePointerCapture ??= () => {};
  window.ResizeObserver ??= class {
    observe() {}
    unobserve() {}
    disconnect() {}
  } as unknown as typeof ResizeObserver;
  window.matchMedia ??= ((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  })) as unknown as typeof window.matchMedia;
}

for (const name of ["localStorage", "sessionStorage"] as const) {
  const existing = (globalThis as Record<string, unknown>)[name];
  if (!existing || typeof (existing as Storage).getItem !== "function") {
    Object.defineProperty(globalThis, name, {
      value: new MemoryStorage(),
      writable: true,
      configurable: true,
    });
  }
}
