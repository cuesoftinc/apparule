// Mock: POST /api/v1/requests/{id}/verify-payment. The mock does not call a
// payment provider; a valid customer request remains pending for UI flows.
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const { reference } = await readJson<{ reference?: string }>(request);
    if (
      typeof reference !== "string" ||
      reference.length < 5 ||
      reference.length > 100 ||
      !reference.startsWith("apr_")
    ) {
      throw new MockApiError(
        "validation_failed",
        "Invalid payment reference",
        422,
      );
    }
    const result = getStore().verifyPendingPayment(
      id,
      actorUsername(request),
      reference,
    );
    return jsonResponse(result);
  });
}
