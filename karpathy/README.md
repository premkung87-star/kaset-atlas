# karpathy/ — Original Karpathy Guidance (Mirrored, Pinned)

## Purpose
This folder contains Andrej Karpathy's Claude Code guidance, mirrored byte-identical from the canonical source repository and pinned to a specific commit SHA for reproducibility.

## Source of Truth
- **Repository:** [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)
- **License:** MIT (`SPDX-License-Identifier: MIT`)
- **Attribution:** Andrej Karpathy (original observations) + forrestchang (CLAUDE.md compilation)
- **Pinned commit:** see `PINNED_VERSION.txt`

## License Note
Upstream declares its MIT license inline in its `README.md` (`## License` section, value `MIT`) and ships **no standalone `LICENSE` file** at the pinned SHA. To preserve byte-identical mirror integrity, this folder also ships no `KARPATHY_LICENSE` file. License inheritance is documented via:

1. The `SPDX-License-Identifier: MIT` field in `PINNED_VERSION.txt` (machine-readable, industry-standard)
2. Upstream's own `README.md` at the pinned SHA (human-readable source of truth)
3. Kit-level `../LICENSE` at repo root (project license, references upstream attribution)

This mirrors how thousands of MIT-licensed GitHub projects declare licensing without a dedicated file. If upstream later adds a `LICENSE` file, `refresh.sh` will detect this and alert the foreman to re-evaluate.

## Files
| File | Purpose | Source |
|---|---|---|
| `CLAUDE.md` | Karpathy guidelines (verbatim) | upstream `/CLAUDE.md` at pinned SHA |
| `PINNED_VERSION.txt` | Provenance metadata + SPDX license | generated locally |
| `refresh.sh` | Re-fetch script | generated locally |

## Rules of Engagement
1. **DO NOT manually edit `CLAUDE.md`** — it must remain byte-identical to upstream at pinned SHA. Drift breaks the kit's integrity claim.
2. **DO NOT renumber, reorder, or paraphrase Karpathy content.** If you disagree with a rule, add a counter-rule in `../pawee/extensions/` instead.
3. **DO refresh periodically** by running `./karpathy/refresh.sh` to pull latest upstream. Review the diff carefully before committing.
4. **DO commit refresh as a single deliberate commit** with message format: `chore(karpathy): refresh to <short-sha>`.
5. **DO act on the LICENSE-file alert** if `refresh.sh` reports upstream has gained one — re-evaluate Option E vs adding a mirrored `KARPATHY_LICENSE`.

## How to Refresh

### Refresh to latest upstream main
```bash
./karpathy/refresh.sh
git diff karpathy/
git add karpathy/
git commit -m "chore(karpathy): refresh to <short-sha>"
```

### Pin to a specific commit SHA
```bash
./karpathy/refresh.sh abc123def456...
```

## Why Mirror Instead of Reference?
- **Offline reproducibility:** Kit works without network access after initial install
- **Deterministic builds:** Two installs of the same kit version produce identical content
- **Audit trail:** PINNED_VERSION.txt records exactly which upstream commit was used
- **Drift detection:** `git diff` after refresh shows what changed upstream

## Why Mirror Instead of Fork?
- **Lower maintenance:** No need to keep a fork in sync
- **Honest attribution:** Single source of truth, no derivative confusion
- **Simpler refresh:** One curl, no git remote dance
