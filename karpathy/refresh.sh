#!/usr/bin/env bash
# refresh.sh — Re-fetch Karpathy upstream content into karpathy/ folder
#
# Usage:
#   ./karpathy/refresh.sh                   # fetch latest from main
#   ./karpathy/refresh.sh <commit-sha>      # fetch specific commit SHA
#
# After running, review the diff and commit deliberately:
#   git diff karpathy/
#   git add karpathy/ && git commit -m "chore(karpathy): refresh to <new-sha>"
#
# Note: This script does NOT fetch a LICENSE file because upstream
# (forrestchang/andrej-karpathy-skills) declares MIT via README only and
# ships no standalone LICENSE file. License inheritance is documented via
# SPDX-License-Identifier in PINNED_VERSION.txt and karpathy/README.md.

set -euo pipefail

UPSTREAM_REPO="forrestchang/andrej-karpathy-skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine target SHA
if [ -n "${1:-}" ]; then
  TARGET_SHA="$1"
  echo "Fetching pinned SHA from argument: $TARGET_SHA"
else
  TARGET_SHA=$(curl -s "https://api.github.com/repos/${UPSTREAM_REPO}/commits/main" \
    | grep '"sha"' | head -1 | cut -d '"' -f 4)
  echo "Fetching latest main: $TARGET_SHA"
fi

# Validate SHA
if [[ ! "$TARGET_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "ERROR: Invalid SHA format: $TARGET_SHA" >&2
  exit 1
fi

# Fetch CLAUDE.md
RAW_BASE="https://raw.githubusercontent.com/${UPSTREAM_REPO}/${TARGET_SHA}"
echo "Fetching CLAUDE.md..."
curl -sf -o "${SCRIPT_DIR}/CLAUDE.md" "${RAW_BASE}/CLAUDE.md"

# Sanity check: did upstream gain a LICENSE file? If so, alert the foreman.
echo "Checking if upstream has gained a LICENSE file at this SHA..."
if curl -sfI "${RAW_BASE}/LICENSE" >/dev/null 2>&1 || curl -sfI "${RAW_BASE}/LICENSE.md" >/dev/null 2>&1; then
  echo ""
  echo "===== ATTENTION ====="
  echo "Upstream now ships a LICENSE file at SHA ${TARGET_SHA}."
  echo "Consider re-evaluating Option E vs mirroring the new LICENSE file."
  echo "See pawee-workflow-kit/docs/DECISIONS.md (when written) for context."
  echo "====================="
  echo ""
fi

# Update PINNED_VERSION.txt
TODAY=$(date -u +%Y-%m-%d)
cat > "${SCRIPT_DIR}/PINNED_VERSION.txt" <<EOF
source_repo: ${UPSTREAM_REPO}
source_url: https://github.com/${UPSTREAM_REPO}
source_branch: main
pinned_commit_sha: ${TARGET_SHA}
pinned_files:
  - CLAUDE.md
fetched_at: ${TODAY}
fetched_by: refresh.sh
SPDX-License-Identifier: MIT
license_declaration: Upstream declares MIT license in README.md (## License section). No standalone LICENSE file exists in upstream repo at pinned SHA. This mirror inherits MIT via SPDX identifier above and upstream README declaration.
attribution: Andrej Karpathy (original observations) + forrestchang (CLAUDE.md compilation)
EOF

echo ""
echo "=== Refresh complete ==="
echo "SHA: $TARGET_SHA"
echo "Files updated:"
echo "  - karpathy/CLAUDE.md"
echo "  - karpathy/PINNED_VERSION.txt"
echo ""
echo "Next steps:"
echo "  git diff karpathy/"
echo "  git add karpathy/"
echo "  git commit -m 'chore(karpathy): refresh to ${TARGET_SHA:0:7}'"
