# Benchmark Baseline — Kaset Atlas Crop Audit

> Baseline snapshot of the crop reliability gates as of 2026-04-30
> (post-tomato auto-publish, 5-crop corpus). Future runs of
> `scripts/audit-crops.sh` are compared against this snapshot to
> detect regression or drift.

## How to reproduce

```bash
./scripts/audit-crops.sh           # human-readable summary
./scripts/audit-crops.sh --json    # machine-readable JSON
```

Optional gates (off by default to keep the audit deterministic and
network-free):

```bash
./scripts/audit-crops.sh --with-urls    # adds verify-urls.sh per crop (HTTP)
./scripts/audit-crops.sh --with-build   # adds verify-build.sh once (npm build)
```

## Baseline (2026-04-30, 5-crop corpus)

| Crop | check-mdx-safety | verify-source-table | verify-claim-grounding | Status |
|------|---|---|---|---|
| cassava | ✓ pass | ✓ pass | ✓ pass | pass |
| holy-basil | ✓ pass | ✓ pass | ✓ pass | pass |
| mango | ✓ pass | ✓ pass | ⚠ known exception | pass-with-known-exception |
| sweet-basil | ✓ pass | ✓ pass | ✓ pass (legacy schema) | pass |
| tomato | ✓ pass | ✓ pass | ✓ pass | pass |

**Aggregate:** 5 crops audited, 14 pass / 0 new-fail / 1 known-exception / 0 skipped. Audit status: **PASS**.

Tomato shipped on 2026-04-30 via the auto-pipeline (commit `64fc52d`,
`content(food-crops): add tomato [auto]`) and is the first crop drafted
end-to-end after the `general-purpose` dispatch Pattern Win
(WORKFLOW_KIT §4 2026-04-30) and the drafter source-table-confidence
patch (commit `d94cfaf`). Auto-pipeline run summary: researcher 38
tool calls / drafter 29 / content-verifier 26, all reliability gates
green, 0 blockers.

## Per-gate pass rates (default audit)

| Gate | Pass | Fail | Known | Total | Pass rate |
|---|---|---|---|---|---|
| check-mdx-safety | 5 | 0 | 0 | 5 | 100% |
| verify-source-table | 5 | 0 | 0 | 5 | 100% |
| verify-claim-grounding | 4 | 0 | 1 | 5 | 80% (100% excl. exception) |

## Schema-coverage observation

`verify-claim-grounding.sh` v1 reports the schema mode of each
sidecar. As of this baseline:

- 4 of 5 sidecars use the current schema (`supporting_source_ids`):
  cassava, holy-basil, mango, tomato.
- 1 of 5 uses the legacy schema (`supporting_source_types`):
  sweet-basil — this is the retroactive sidecar created in commit
  `2870ef6` and is preserved as-is. It validates as `pass` with
  one warning entry: `legacy_schema_supporting_source_types(sections=11)`.
- 0 of 5 carry the future v2 fields (`claims` array per section,
  per-claim `evidence_quote`). v2 schema would unlock deterministic
  quote-in-source-body verification; that migration is out of scope
  for the current pipeline gates.

## Known historical exception — mango

**What:** the mango reasoning sidecar references **12 unique source IDs**
in its `section_confidence[*].supporting_source_ids` lists, but the
mango MDX source table contains **11 unique URLs**.

**Where:** the 12th source ID is `doaenews-mango-seed-weevil`. It is
documented in `mango.reasoning.json` under the `production_note`
field as: *"DOAE seed weevil source identified during research but
not added as separate row to keep source table at 11 entries"* (in
the `7_pests_diseases` section's rationale).

**Why it remains:** mango shipped on 2026-04-30 (commits `a5cde99`
and `1ec594a`) before `verify-claim-grounding.sh --with-mdx` existed.
Resolving the discrepancy requires either:
1. dropping `doaenews-mango-seed-weevil` from the sidecar (the source
   was used during research but not cited in the body), or
2. adding the DOAE seed-weevil URL as a 12th row to the MDX source
   table.

Neither option is in scope for the Day-3 benchmark task. The
discrepancy is preserved visibly: it appears in every audit run
under the "Known exceptions" block, and is a row in the script's
`KNOWN_EXCEPTIONS` array. It is **not silently normalized**.

**How to remove the exception (when ready):** delete the line from
the `KNOWN_EXCEPTIONS` array in `scripts/audit-crops.sh` and ensure
the underlying issue is fixed in the mango files. The audit will
then either pass cleanly (issue resolved) or fail with exit 1 (issue
still present, but no longer waived).

## What this baseline does NOT cover

- **URL liveness** (off by default). Run `--with-urls` for the network
  pass — it invokes `verify-urls.sh` per crop, which checks HTTP
  status + soft-200 body content.
- **Build verification** (off by default). Run `--with-build` to
  invoke `verify-build.sh` once globally — heavy (`npm run build`).
- **Content fidelity** (not yet implementable). Would require the
  v2 sidecar schema (`evidence_quote` per claim) plus a fetched-body
  cache. Out of scope for v1 of the audit harness.
- **Subagent dispatch reliability**. That signal lives in
  `.claude/logs/subagent-dispatch.json` and is the Day-1
  instrumentation. The audit harness does not analyze the dispatch
  log (different concern: per-run pipeline reliability vs. per-crop
  state).

## Drift detection workflow

1. Run `./scripts/audit-crops.sh --json > /tmp/audit-now.json`
2. Compare against this baseline doc.
3. New rows in `summary.fail` (i.e. exit 1 from the script) indicate
   regression.
4. Changes in `coverage_assessment` (e.g. a sidecar moving from
   `v1-structural` to `v2-full`) indicate forward progress.

The script is designed to be cheap enough to run on every pipeline
invocation as a final smoke check, or on a CI cron schedule to
catch silent drift.
