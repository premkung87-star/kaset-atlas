---
number: 20
title: "Fixture Parity with Real Payloads"
tags: [UNIVERSAL, TESTING_DISCIPLINE, FIXTURE, INTEGRATION]
applies_to: [generic]
universal: true
source: AUDIT_LOG.md (PR #50 four-bug audit + Bug 5 + Bug 6 cluster)
incident_refs:
  - AUDIT_LOG.md "Phase A smoke test — 4 Phase 1 plumbing bugs found in v2.1.0-beta.1 (2026-04-24)"
  - AUDIT_LOG.md "Bug 5 — agent_type vs subagent_type field-name mismatch in hook payload parsing (2026-04-25)"
  - AUDIT_LOG.md "Bug 6 — last_assistant_message vs final_message field-name mismatch in SubagentStop payload (2026-04-25)"
added_in_kit: 2.2.0-beta.6
---

# 20. Fixture Parity with Real Payloads

## Problem Statement

Test fixtures for any hook, MCP server, subagent integration, or
other contract-boundary integration MUST be byte-identical
captures of real upstream payloads, not hand-authored JSON
modeling the implementer's mental model of the payload shape.
Hand-rolled fixtures pass green while the real integration
silently fails at runtime — a class of bug that can ship across
multiple version bumps and downstream propagations before being
caught by a real production task.

The pattern is structural, not stochastic. Every observed instance
in this kit's history (6 instances across PR #50 four-bug audit
plus Bug 5 + Bug 6) shared the same shape: hook author read the
upstream documentation, formed a mental model of the JSON schema,
hand-rolled a fixture matching that mental model, wrote tests that
passed against the fixture, and shipped — only to discover at
runtime that the upstream's actual field names diverged from the
mental model. The fixture made the divergence invisible. Hand-
rolled fixtures encode the same misconceptions the production code
encodes; they cannot serve as an independent regression guard.

The capture-and-fixture discipline is therefore a hard requirement
for any contract-boundary integration whose JSON schema is not
documented in a stable, machine-checkable form: a new PR ships
with a `tests/fixtures/captured-real-*-payload.json` fixture
captured via temporary instrumentation during a real dispatch,
PLUS a companion integration test that consumes that fixture
byte-for-byte and asserts the real field shape — OR the PR does
not ship.

## Source Incidents

The pattern accumulated across two distinct sub-classes:

1. **PR #50 four-bug audit cluster (2026-04-24)** — initial Phase 1
   architect-in-terminal smoke test surfaced four plumbing bugs
   simultaneously (Bugs 1+2+3+4). All four were hook-input
   parsing bugs masked by hand-rolled fixtures in the test
   suite. PR #52 fixed Bugs 1+2+3 and added the first integration
   test. Bug 4 fixed in PR #53.
2. **Bug 5 (PR #57, 2026-04-25)** — `phase-state-guard.sh` and
   `spec-lock-precondition.sh` parsed `subagent_type` from hook
   input. Real Claude Code SubagentStop payloads use `agent_type`.
   Hand-rolled fixtures had `subagent_type`; tests were green;
   production silently failed. Foreman ran two manual `pawee-
   phase-reset idle` recoveries before the bug was diagnosed.
3. **Bug 6 (PR #58, 2026-04-25)** — same hook script
   (`spec-lock-precondition.sh`) parsed `final_message` from hook
   input. Real Claude Code SubagentStop payloads use
   `last_assistant_message`. Bug 5 fix was validated end-to-end
   on the very first post-merge dispatch; that dispatch
   IMMEDIATELY surfaced Bug 6, which had been latent under the
   same hand-rolled-fixture mask.

Total: 6 incident-instances in 8 days, all in the same context
(hook input parsing) but across three distinct field types and
two distinct hook scripts. KARPATHY §13 threshold of 3+ incidents
is clearly cleared. Single-context concentration is treated as
strength-of-pattern (every observed hook integration that lacked
captured fixtures had this class of bug) rather than weakness-of-
spread.

## Examples

WRONG — hand-rolled fixture from documentation reading:

```bash
# tests/hooks/spec-lock-precondition-test.sh (pre-Bug-6)
input='{"subagent_type": "pawee-architect", "final_message": "SPEC LOCKED: ..."}'
echo "$input" | bash library/hooks/spec-lock-precondition.sh
# Test passes. Production silently fails because real Claude
# Code uses {"agent_type": "...", "last_assistant_message": "..."}.
```

RIGHT — captured real payload as fixture:

```bash
# Step 1: Add temporary capture to hook
# library/hooks/spec-lock-precondition.sh (top of script):
#   echo "$input" > /tmp/captured-payload.json

# Step 2: Trigger one real dispatch
# (Run an actual Claude Code architect dispatch in this repo)

# Step 3: Promote captured file to permanent fixture
cp /tmp/captured-payload.json \
   tests/fixtures/captured-real-subagent-stop-payload.json

# Step 4: Author production hook against the actual field names
# Step 5: Author integration test as fixture-consumer
# tests/integration/real-payload-spec-lock-test.sh:
input=$(cat tests/fixtures/captured-real-subagent-stop-payload.json)
echo "$input" | bash library/hooks/spec-lock-precondition.sh
# Asserts on real field names: agent_type, last_assistant_message
# Code-only regression guards: grep -L 'subagent_type\|final_message'

# Step 6: Remove temporary capture line; commit fixture + test +
# hook together. Future hook edits re-capture if the upstream
# payload shape changes.
```

## Generic Pattern (Strategy B Abstraction)

For any test fixture that models a contract-boundary payload,
the fixture MUST be a captured byte-identical sample of the real
boundary shape. Contract-boundary payloads include:

- Claude Code hook inputs (PreToolUse, PostToolUse, SubagentStop,
  Stop, etc.)
- MCP server request and response payloads
- Subagent invocation inputs and outputs
- Third-party API webhook payloads
- LLM provider streaming chunks (where applicable)
- Any JSON-over-stdin or JSON-over-HTTP integration whose schema
  is owned by an upstream provider you do not control

For contract-boundary integrations whose JSON schema is not
documented or is not stable across the upstream provider's
versions, this rule is mandatory. For contracts with stable,
documented, machine-checkable schemas (e.g., OpenAPI specs or
JSONSchema published by the provider), capturing is recommended
but a hand-rolled fixture matching the published schema is
permissible IF a regression guard tests against the live API in
CI.

The capture-and-fixture pattern itself has three required artifacts
in every PR that introduces or modifies a contract-boundary
integration:

1. `tests/fixtures/captured-real-<event>-payload.json` — the
   captured byte-for-byte fixture. Filename includes the event
   name (e.g., `captured-real-subagent-stop-payload.json`,
   `captured-real-tool-use-payload.json`). Permanent regression
   guard.
2. `tests/integration/real-payload-<hook>-test.sh` — the
   integration test that consumes the fixture. Asserts on the
   real field shape. Includes code-only regression guards
   (grep-based blocks against re-introducing the wrong field
   names) so the rule is enforced at test-suite level even if a
   future author bypasses the fixture.
3. The production hook or integration code authored against the
   ACTUAL field names from the captured payload, not the
   documentation's stated schema (when they differ, the captured
   payload wins).

## Enforcement

**Architect-side:** Architect MUST require captured-real-payload
fixtures in any spec that introduces or modifies a hook, MCP
server, or subagent integration test. Architect specs that ship
hand-rolled fixtures for contract-boundary payloads are §17
self-violations (Architect dispatch contains content the rule
forbids). Architect explicitly states in the dispatch's
"Verification commands" section the path to the captured fixture
and the integration test that consumes it.

**Builder-side:** Builder HALTs at the test-authoring step if
asked to write a hand-rolled fixture for a contract-boundary
integration; reports the §20 violation in the CHECKPOINT report
and surfaces the choice to Foreman: capture a real payload, or
explicitly mark the fixture as documented-schema-permissible per
§20's "Generic Pattern" carve-out. If the carve-out is invoked,
the PR description must cite the upstream's stable schema doc.

**Audit-side:** every §20 violation caught at HALT, at pre-merge
review, or post-merge is logged as a new audit entry under the
incident_refs of this rule. A 4th post-promotion violation
triggers KARPATHY §13 review of §20 wording — the rule itself may
need refinement if it fails to prevent recurrence at three
instances post-promotion.

**Self-application:** the PR that introduces a new hook ships its
own captured-real-payload fixture. The PR that promotes this
rule (v2.2.0-beta.6) does not introduce a new hook but DOES
ensure that all existing hook tests in the kit comply — at
promotion time, `tests/hooks/spec-lock-precondition-test.sh`,
`tests/hooks/phase-state-guard-test.sh`, and
`tests/hooks/head-build-bash-allowlist-test.sh` all use
`tests/fixtures/captured-real-subagent-stop-payload.json` as
their canonical fixture source where applicable. Pre-promotion
hand-rolled fixtures from before Bug 5/6 era are grandfathered
but flagged for replacement at next material edit of the
corresponding hook.
