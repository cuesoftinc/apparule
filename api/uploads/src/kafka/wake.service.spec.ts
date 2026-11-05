import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import type { Config } from "../config/config";
import { WakeService } from "./wake.service";

describe("WakeService", () => {
  let server: Server;
  let status = 200;
  let delayMs = 0;
  const hits: { method?: string; url?: string; auth?: string }[] = [];
  let base = "";

  beforeAll(async () => {
    server = createServer((req, res) => {
      hits.push({
        method: req.method,
        url: req.url,
        auth: req.headers.authorization,
      });
      setTimeout(
        () => res.writeHead(status).end(JSON.stringify({ caught_up: true })),
        delayMs,
      );
    });
    await new Promise<void>((resolve) =>
      server.listen(0, "127.0.0.1", resolve),
    );
    base = `http://127.0.0.1:${(server.address() as AddressInfo).port}/`;
  });
  afterAll(() => new Promise<void>((resolve) => server.close(() => resolve())));
  beforeEach(() => {
    hits.length = 0;
    status = 200;
    delayMs = 0;
  });

  const wake = (url: string) =>
    new WakeService({ wakeCommonUrl: url, onCloudRun: false } as Config);

  it("posts to /internal/settle", async () => {
    await wake(base).common("test");
    expect(hits).toEqual([
      { method: "POST", url: "/internal/settle", auth: undefined },
    ]);
  });

  it("settles on every upload and waits for the answer", async () => {
    const service = wake(base);
    delayMs = 50;
    const started = Date.now();
    await service.common("test");
    await service.common("test");
    expect(hits).toHaveLength(2);
    expect(Date.now() - started).toBeGreaterThanOrEqual(100);
  });

  it("does nothing without a URL", async () => {
    await wake("").common("test");
    expect(hits).toEqual([]);
  });

  it("never throws when common refuses or is away", async () => {
    const service = wake(base);
    status = 503;
    await expect(service.common("test")).resolves.toBeUndefined();
    await expect(
      wake("http://127.0.0.1:1/").common("test"),
    ).resolves.toBeUndefined();
  });

  it("signs the call with the service's ID token on Cloud Run", async () => {
    const calls: { url: string; init?: RequestInit }[] = [];
    const spy = jest
      .spyOn(globalThis, "fetch")
      .mockImplementation((input, init) => {
        calls.push({ url: String(input), init });
        const body = String(input).includes("metadata") ? "tok\n" : "{}";
        return Promise.resolve(new Response(body, { status: 200 }));
      });
    try {
      await new WakeService({
        wakeCommonUrl: "https://common.example/",
        onCloudRun: true,
      } as Config).common("test");
    } finally {
      spy.mockRestore();
    }
    expect(calls[0].url).toContain(
      `audience=${encodeURIComponent("https://common.example")}`,
    );
    expect(calls[1].url).toBe("https://common.example/internal/settle");
    expect(
      (calls[1].init?.headers as Record<string, string>).Authorization,
    ).toBe("Bearer tok");
  });
});
