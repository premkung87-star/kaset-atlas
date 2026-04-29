---
description: Audit the last N auto-published crops to spot-check pipeline quality
argument-hint: <number of recent crops to audit, default 5>
---

# Audit Recent Auto-Published Crops

Audit count: ${1:-5}

## Process

1. Run `git log --oneline --grep="\[auto\]" -n $1` to find recent auto commits
2. For each commit, extract the crop file path
3. For each crop file:
   - Run `./scripts/verify-urls.sh` again
   - Use **content-verifier** subagent to re-verify
4. Compile audit report

## Report Format

```
# Audit Report — YYYY-MM-DD

## Summary
- Crops audited: N
- All URLs still valid: X/N
- Content verifier still pass: Y/N

## Per-crop findings

### [crop name] (commit [sha])
- URL check: pass/fail (X/Y URLs)
- Content verifier: pass/fail
- New issues found: [list]

## Recommendations
- [If failure rate > 10%: suggest pipeline review]
- [If specific patterns found: suggest agent prompt update]
```

## Action

Save report to `docs/audits/YYYY-MM-DD-audit.md` and commit with:
```
chore(audit): periodic quality audit of recent auto-published crops
```
