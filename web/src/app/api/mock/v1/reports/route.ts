// Mock: POST /api/v1/reports — report content/account (SOC-009, A-6).
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";
import type { ReportReason, ReportSubjectKind } from "@/models";

const KINDS: ReportSubjectKind[] = ["post", "comment", "account"];
const REASONS: ReportReason[] = [
  "spam",
  "inappropriate",
  "counterfeit",
  "harassment",
  "other",
];

export async function POST(request: Request) {
  return handle(async () => {
    const body = await readJson<{
      subject_kind?: ReportSubjectKind;
      subject_id?: string;
      reason?: ReportReason;
      detail?: string;
    }>(request);
    if (
      !body.subject_kind ||
      !KINDS.includes(body.subject_kind) ||
      !body.subject_id ||
      !body.reason ||
      !REASONS.includes(body.reason)
    ) {
      throw new MockApiError(
        "validation_failed",
        "subject_kind, subject_id and reason are required",
        422,
      );
    }
    return jsonResponse(
      getStore().fileReport(
        actorUsername(request),
        body.subject_kind,
        body.subject_id,
        body.reason,
        body.detail,
      ),
      201,
    );
  });
}
