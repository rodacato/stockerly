#!/usr/bin/env bash
#
# audit-entropy.sh — baseline entropy metrics for Stockerly.
#
# Runs a small set of greps that approximate how much "drift" lives in the
# codebase. Output is a one-screen report. Compare across sprint retros to
# detect regressions. Add metrics here only when they catch real entropy.
#
# Usage:
#   script/audit-entropy.sh                 # human-readable
#   script/audit-entropy.sh --json          # machine-readable (CI/diff)
#
# Established 2026-05-14 (Sprint 2 opening per Sprint 1 retro).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FORMAT="text"
[[ "${1:-}" == "--json" ]] && FORMAT="json"

# ---- metrics ----

# 1. Cross-context leaks: a context calling another context's namespace directly.
# Heuristic: a file in app/contexts/<A>/ that mentions <B>:: where B != A (and B != one of the shared roots).
# Self-references are excluded with explicit context-folder → PascalCase-namespace pairs
# because the snake_case folder name (market_data) doesn't match the Ruby namespace (MarketData).
# False positives possible (test fixtures, comments) — keep the regex narrow.
leaks=$(
  grep -rEn 'Trading::|MarketData::|Alerts::|Identity::|Administration::|Notifications::' \
    app/contexts/ 2>/dev/null \
    | grep -v -E 'app/contexts/trading/[^:]+:.*Trading::' \
    | grep -v -E 'app/contexts/market_data/[^:]+:.*MarketData::' \
    | grep -v -E 'app/contexts/alerts/[^:]+:.*Alerts::' \
    | grep -v -E 'app/contexts/identity/[^:]+:.*Identity::' \
    | grep -v -E 'app/contexts/administration/[^:]+:.*Administration::' \
    | grep -v -E 'app/contexts/notifications/[^:]+:.*Notifications::' \
    | grep -v -E '^\s*#' \
    | wc -l | tr -d ' '
)

# 2. Hardcoded "USD" outside the Asset/Position/Trade schema definition.
# We expect this to drop to ~0 after Sprint 2 closes.
hardcoded_usd=$(
  grep -rEn '"USD"|'\''USD'\''' app/ \
    --include='*.rb' \
    | grep -v -E '(spec|db/schema|fx_rate|currency:\s*"USD",\s*default)' \
    | wc -l | tr -d ' '
)

# 3. ADR-001 violations in views: prescriptive verbs that should not appear.
# See docs/architecture/adr/0001-descriptive-not-prescriptive-language.md
adr001_violations=$(
  grep -rEin \
    'recommend|suggest|you should|consider buying|consider selling|high.probability|smart|optimal|best move|gain a competitive edge|make smarter' \
    app/views/ 2>/dev/null \
    | wc -l | tr -d ' '
)

# 4. Doc bloat: any markdown file in docs/ with > 200 lines.
# Threshold from anti-pattern #4 ("useful docs fit on one screen", informal ~200 lines).
bloated_docs=$(
  find docs/ -name '*.md' -type f -print0 2>/dev/null \
    | xargs -0 wc -l 2>/dev/null \
    | awk '$1 > 200 && $2 != "total" { print $2 }' \
    | wc -l | tr -d ' '
)
bloated_docs_list=$(
  find docs/ -name '*.md' -type f -print0 2>/dev/null \
    | xargs -0 wc -l 2>/dev/null \
    | awk '$1 > 200 && $2 != "total" { printf "  %5d  %s\n", $1, $2 }' \
    | sort -rn
)

# 5. TODO / FIXME / XXX in app/.
todos=$(
  grep -rEn 'TODO|FIXME|XXX' app/ --include='*.rb' --include='*.erb' 2>/dev/null \
    | wc -l | tr -d ' '
)

# ---- output ----

if [[ "$FORMAT" == "json" ]]; then
  cat <<EOF
{
  "sampled_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cross_context_leaks": $leaks,
  "hardcoded_usd_literals": $hardcoded_usd,
  "adr001_violations_in_views": $adr001_violations,
  "bloated_docs_count": $bloated_docs,
  "todo_fixme_markers": $todos
}
EOF
  exit 0
fi

cat <<EOF
═══════════════════════════════════════════════════════════════
  Stockerly — Entropy Audit
  $(date -u +%Y-%m-%d\ %H:%M\ UTC)
═══════════════════════════════════════════════════════════════

  Cross-context leaks (greps):        $leaks
  Hardcoded "USD" literals in app/:   $hardcoded_usd
  ADR-001 violations in views:        $adr001_violations
  Bloated docs (>200 lines):          $bloated_docs
  TODO/FIXME/XXX markers:             $todos

EOF

if [[ -n "$bloated_docs_list" ]]; then
  echo "  Bloated docs:"
  echo "$bloated_docs_list"
  echo
fi

cat <<EOF
  ↓ Sprint 2 target deltas:
    - hardcoded_usd_literals → near 0 (Asset.currency lands)
    - cross_context_leaks    → 1 less (#45 / S2-E)
    - adr001_violations      → near 0 (#31 closes)

  Compare across sprints by checking this file's output into the retro.
═══════════════════════════════════════════════════════════════
EOF
