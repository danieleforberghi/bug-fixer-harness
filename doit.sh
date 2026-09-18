#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Autonomous Multi-Agent TDD Engine (macOS & Linux)
# Usage:
#   Immediate: ./doit.sh ./src/billing "Fix discount calculation rounding error"
#   Scheduled: ./doit.sh ./src/billing "Fix discount calculation rounding error" --schedule 1
# ==============================================================================

TARGET_DIR="${1:-"."}"
BUG_DESCRIPTION="${2:-"Fix unhandled logic edge case"}"
SCHEDULE_FLAG="${3:-""}"
SCHEDULE_TIME="${4:-""}"

# Resolve absolute path to agy binary before changing working directories
AGY_BIN=$(which agy 2>/dev/null || echo "")
if [ -z "${AGY_BIN}" ]; then
    echo "❌ Error: 'agy' CLI binary not found in PATH."
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || { echo "❌ Error: Not inside a Git repository."; exit 1; })
TIMESTAMP=$(date +%s)
BRANCH_NAME="fix/auto-tdd-${TIMESTAMP}"
WORKTREE_DIR="${REPO_ROOT}/.worktrees/${BRANCH_NAME}"
GOAL_FILE_REL=".agent/goals/goal-${TIMESTAMP}.md"
GOAL_FILE_ABS="${REPO_ROOT}/${GOAL_FILE_REL}"

# Handle Autonomous Scheduling / Delay
if [ "${SCHEDULE_FLAG}" == "--schedule" ]; then
    DELAY_MINUTES="${SCHEDULE_TIME:-"1"}"
    CLEAN_MINUTES=$(echo "${DELAY_MINUTES}" | tr -dc '0-9')
    CLEAN_MINUTES="${CLEAN_MINUTES:-1}"

    mkdir -p "${REPO_ROOT}/.agent/goals"
    LOG_FILE="${REPO_ROOT}/.agent/goals/execution-${TIMESTAMP}.log"
    touch "${LOG_FILE}"

    echo "📅 Scheduling Goal Execution in background for: in ${CLEAN_MINUTES} minute(s)..."
    echo "📄 Log file created at: ${LOG_FILE}"

    (
        echo "⏰ Waiting ${CLEAN_MINUTES} minute(s) before starting TDD engine..."
        sleep $((CLEAN_MINUTES * 60))
        "${0}" "${TARGET_DIR}" "${BUG_DESCRIPTION}"
    ) > "${LOG_FILE}" 2>&1 &

    echo "🎉 Goal scheduled autonomously in background! PID: $!"
    exit 0
fi

echo "🛠️  [1/7] Bootstrapping Infrastructure & Subagents..."

# Auto-create target directory in repo root if missing
mkdir -p "${TARGET_DIR}"

# 1. Persistent Root Rules
cat << 'EOF' > "${REPO_ROOT}/AGENTS.md"
# AGENTS.md
## Core TDD Guidelines
- **RED**: Write failing tests before modifying implementation code.
- **GREEN**: Make minimal edits to pass the test.
- **REFACTOR**: Consolidate stacked tests into parameterized tables (@pytest.mark.parametrize) per DRY principles.
- **IMPORTS**: Always import modules assuming repository root is on PYTHONPATH (e.g., `from src.billing.discount import ...`).
EOF

# 2. Subagents Setup
mkdir -p "${REPO_ROOT}/.agent/agents/red-agent"
cat << 'EOF' > "${REPO_ROOT}/.agent/agents/red-agent/AGENT.md"
# RED Agent (Reproducer)
Role: Write a failing unit test reproducing the issue strictly inside the targeted path.
Rules: Do NOT touch production code or files outside the target directory. Verify execution ends with a test failure (RED).
EOF

mkdir -p "${REPO_ROOT}/.agent/agents/green-agent"
cat << 'EOF' > "${REPO_ROOT}/.agent/agents/green-agent/AGENT.md"
# GREEN Agent (Fixer)
Role: Edit production code inside target path to pass tests. Do NOT alter files outside assigned scope.
EOF

mkdir -p "${REPO_ROOT}/.agent/agents/refactor-agent"
cat << 'EOF' > "${REPO_ROOT}/.agent/agents/refactor-agent/AGENT.md"
# REFACTOR Agent (Clean-up)
Role: Consolidate duplicate tests into parameterized tables per AGENTS.md strictly inside target path.
EOF

# Relative path calculation
ABS_TARGET_PATH=$(cd "${TARGET_DIR}" && pwd)
REL_TARGET_PATH="${ABS_TARGET_PATH#"${REPO_ROOT}/"}"
if [ "${REL_TARGET_PATH}" == "${ABS_TARGET_PATH}" ]; then
    REL_TARGET_PATH="."
fi

echo "📝 [2/7] Generating Physical Goal File with Strict Scope..."
mkdir -p "${REPO_ROOT}/.agent/goals"
cat << EOF > "${GOAL_FILE_ABS}"
# Goal: Autonomous TDD Patch for ${BUG_DESCRIPTION}

- **Target Path Scope**: \`${REL_TARGET_PATH}\`
- **Created At**: $(date)

## STRICT OPERATIONAL RULES
1. You MUST directly create, edit, and write physical files to disk inside \`${REL_TARGET_PATH}\` within this turn.
2. DO NOT pretend to delegate to subagents or claim processes are running in the background. Write the code directly to disk.
3. You MUST create at least one test file matching \`${REL_TARGET_PATH}/test_*.py\` and ensure it contains executable \`pytest\` tests.
4. **IMPORT PATH RULE**: Always import modules using the full path from repo root (e.g., \`from ${REL_TARGET_PATH/\//.}.discount import ...\` or \`from src.billing...\`). NEVER import assuming subfolders are root (e.g., DO NOT write \`from billing...\`).

## Pipeline Steps
1. **RED**: Create a failing unit test in \`${REL_TARGET_PATH}/test_*.py\` reproducing: ${BUG_DESCRIPTION}.
2. **GREEN**: Write production code in \`${REL_TARGET_PATH}\` to fix the issue and make the test pass.
3. **REFACTOR**: Parametrize duplicate test cases using \`@pytest.mark.parametrize\` per \`AGENTS.md\`.

## End Condition
- At least one valid \`test_*.py\` file exists in \`${REL_TARGET_PATH}\` and passes with 0 errors.
EOF

echo "🚀 [3/7] Creating Isolated Git Worktree Sandbox: ${WORKTREE_DIR}..."
mkdir -p "${REPO_ROOT}/.worktrees"
git worktree add -b "${BRANCH_NAME}" "${WORKTREE_DIR}"
cd "${WORKTREE_DIR}"

# Guarantee target directory exists inside the worktree sandbox
mkdir -p "${REL_TARGET_PATH}"

echo "🤖 [4/7] Executing Scope-Bounded Goal via Antigravity Harness..."
GOAL_TEXT="$(cat "${GOAL_FILE_ABS}")"

if "${AGY_BIN}" \
    -p "${GOAL_TEXT}" \
    --add-dir "${WORKTREE_DIR}" \
    --add-dir "${REL_TARGET_PATH}" \
    --dangerously-skip-permissions < /dev/null; then
    echo "✅ Agent orchestration completed successfully."
else
    echo "❌ Execution failed. Removing worktree sandbox..."
    cd "${REPO_ROOT}" && git worktree remove --force "${WORKTREE_DIR}"
    exit 1
fi

echo "🧪 [5/7] Verifying Quality Gates in '${REL_TARGET_PATH}'..."
cd "${WORKTREE_DIR}"

if [ ! -d "${REL_TARGET_PATH}" ]; then
    echo "❌ Quality gate error: Directory '${REL_TARGET_PATH}' does not exist inside worktree."
    cd "${REPO_ROOT}" && git worktree remove --force "${WORKTREE_DIR}"
    exit 1
fi

if PYTHONPATH="${WORKTREE_DIR}" pytest "${REL_TARGET_PATH}"; then
    echo "✅ Verification passed: 100% GREEN."
else
    echo "❌ Quality gate failed: Tests failing. Aborting PR creation."
    cd "${REPO_ROOT}" && git worktree remove --force "${WORKTREE_DIR}"
    exit 1
fi

echo "🔀 [6/7] Pushing Branch & Creating Pull Request..."
cd "${WORKTREE_DIR}"

git add "${REL_TARGET_PATH}"
git commit -m "fix(${REL_TARGET_PATH}): autonomous TDD patch for${BUG_DESCRIPTION}" || true
git push origin "${BRANCH_NAME}"

# Hämta exakt repository-namn (t.ex. danieleforberghi/bugg-fixer-harness) från git remote
REPO_NICK=$(git config --get remote.origin.url | sed -E 's/.*github\.com[:\/](.+)\.git/\1/' | sed 's/\.git$//')

if ! gh pr create \
    --repo "${REPO_NICK}" \
    --head "${BRANCH_NAME}" \
    --title "fix(${REL_TARGET_PATH}): autonomous patch for${BUG_DESCRIPTION}" \
    --body "### Autonomous Multi-Agent TDD Patch
    - **Target Scope:** \`${REL_TARGET_PATH}\`
    - **Issue:** ${BUG_DESCRIPTION}
    - **Pipeline Executed:** \`red-agent\` ➔ \`green-agent\` ➔ \`refactor-agent\`" \
    --base main; then
    echo "⚠️  'gh pr create' failed (verify GitHub CLI account permissions via 'gh auth status')."
    echo "🔗 You can manually open the PR here:"
    echo "   https://github.com/${REPO_NICK}/pull/new/${BRANCH_NAME}"
fi

echo "🧹 [7/7] Cleaning Up Worktree Sandbox..."
cd "${REPO_ROOT}"
git worktree remove --force "${WORKTREE_DIR}"

echo "🎉 Done! Execution completed successfully."