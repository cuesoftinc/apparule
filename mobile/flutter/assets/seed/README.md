# Seed narrative (mobile-implementation.md §6)

`*Fake` repositories read flavor-scoped JSON from `assets/seed/<flavor>/`
(`dev/` today; the two-flavor model per the org environment ruling, user
directive 2026-07-22) — the same story as the web dashboard's seed, so a
person moving between the phone and the web app sees one coherent world.

The domain files land screen wave by screen wave (§1 phase 3):

| File | Domain | Status |
| --- | --- | --- |
| `me.json` | Signed-in test user (non-designer, vault across all three freshness states) | pending |
| `designers.json` | The Nigerian designer-persona cast, incl. `eniola.stitches` | pending |
| `posts.json` | Published posts over the CC-sourced photography pool | pending |
| `vault_sessions.json` | Scan + manual measurement sessions — the web mock's sessions verbatim (`created_days_ago` stands in for the web's computed `daysAgo()`) | **shipped (C6 wave)** |
| `orders.json` | All ten order-lifecycle states | pending |
| `notifications.json` | Every notification kind, part unread | pending |
| `moderation.json` | Two open reports + one actioned exemplar | pending |

The C6 capture seam adds two non-domain seeds: `capture_samples.json`
(the fake camera's QC scenario catalog — simulated pipeline metrics the
real capture-qc.md threshold table evaluates, one entry per fail code
plus the happy path and a multi-fault exemplar) and `sample_frontal.png`
(the bundled frame every scenario previews/captures).

Fakes whose domain seed is still pending return empty placeholder data —
the repository interface seam is what the skeleton wave establishes.
Fakes must apply the same invariants the web mock store unit-gates
(comment counts match comment lists, follower counts mirror the follow
graph, snapshots are frozen copies) and, where practical, parse the
identical JSON shapes the web mock server seeds from.
