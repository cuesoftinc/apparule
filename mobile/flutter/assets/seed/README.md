# Seed narrative (mobile-implementation.md §6)

`*Fake` repositories read flavor-scoped JSON from `assets/seed/<flavor>/`
(`dev/` today; the two-flavor model per the org environment ruling, user
directive 2026-07-22) — the same story as the web dashboard's seed, so a
person moving between the phone and the web app sees one coherent world.

The files land with the screens wave (§1 phase 3), one per domain:

| File | Domain |
| --- | --- |
| `me.json` | Signed-in test user (non-designer, vault across all three freshness states) |
| `designers.json` | The Nigerian designer-persona cast, incl. `eniola.stitches` |
| `posts.json` | Published posts over the CC-sourced photography pool |
| `vault_sessions.json` | Scan + manual measurement sessions |
| `orders.json` | All ten order-lifecycle states |
| `notifications.json` | Every notification kind, part unread |
| `moderation.json` | Two open reports + one actioned exemplar |

Until then the fakes return empty placeholder data — the repository
interface seam is what the skeleton wave establishes. Fakes must apply the
same invariants the web mock store unit-gates (comment counts match comment
lists, follower counts mirror the follow graph, snapshots are frozen
copies) and, where practical, parse the identical JSON shapes the web mock
server seeds from.
