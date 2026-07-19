// Mock: POST /api/v1/designer/payout-account/resolve — scripted Paystack
// account resolution (pages.md B8: resolving → resolved name / mismatch).
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function POST(request: Request) {
  return handle(async () => {
    const body = await readJson<{
      bank_code?: string;
      account_number?: string;
    }>(request);
    if (!body.bank_code || !body.account_number) {
      throw new MockApiError(
        "validation_failed",
        "bank_code and account_number are required",
        422,
      );
    }
    return jsonResponse(
      getStore().resolveBank(
        actorUsername(request),
        body.bank_code,
        body.account_number,
      ),
    );
  });
}
