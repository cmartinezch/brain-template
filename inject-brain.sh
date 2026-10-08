#!/usr/bin/env bash
set -euo pipefail

inject_repo() {
  local target_dir="$1"

  echo "Injecting Project Brain into: $target_dir"

  # Create directories
  mkdir -p "$target_dir/brain/topics"
  mkdir -p "$target_dir/.cursor/rules"

  # Initialize Git if not present (needed for hooks)
  if [ ! -d "$target_dir/.git" ]; then
    echo "Initializing Git repository in $target_dir..."
    git -C "$target_dir" init
  fi

  # 1. PROJECT.md
  if [ ! -f "$target_dir/brain/PROJECT.md" ]; then
    cat << 'EOF' > "$target_dir/brain/PROJECT.md"
<!-- 
AGENT PERMISSIONS: READ-ONLY
DO NOT MODIFY THIS FILE.
This file defines immutable architecture and constraints. 
Only Human Operators or Orchestrator/Planning models in Plan Mode may alter this file.
-->
# Project Overview
- **Goal**: Core application purpose
- **Tech Stack**: 
- **Non-Negotiable Constraints**: 
EOF
  fi

  # 2. MAP.md
  if [ ! -f "$target_dir/brain/MAP.md" ]; then
    cat << 'EOF' > "$target_dir/brain/MAP.md"
<!-- 
AGENT PERMISSIONS: CONDITIONAL READ-ONLY
Read-only during task execution. 
Modification allowed ONLY when a new module, entry point, or core directory is created.
-->
# System Map & Architecture
- **Entry Points**: 
- **Key Modules**: 
- **Core Data Flows**: 
EOF
  fi

  # 3. STATUS.md
  if [ ! -f "$target_dir/brain/STATUS.md" ]; then
    cat << 'EOF' > "$target_dir/brain/STATUS.md"
# Project Status
- **Current Milestone**: 
- **Active Task**: 
- **Blockers**: None
EOF
  fi

  # 4. DECISIONS.md
  if [ ! -f "$target_dir/brain/DECISIONS.md" ]; then
    cat << 'EOF' > "$target_dir/brain/DECISIONS.md"
<!-- 
AGENT PERMISSIONS: APPEND-ONLY
Never delete, edit, or reorganize existing entries above.
Add new architectural decisions strictly at the bottom using the format:
[YYYY-MM-DD] Decision | Rationale | Alternatives Rejected
-->
# Architecture Decision Log (Append-Only)
Format: [YYYY-MM-DD] - Decision | Rationale | Alternatives Rejected
EOF
  fi

  # 5. HANDOFF.md
  if [ ! -f "$target_dir/brain/HANDOFF.md" ]; then
    cat << 'EOF' > "$target_dir/brain/HANDOFF.md"
<!-- 
AGENT PERMISSIONS: HIGH-CHURN READ/WRITE
Primary task queue. Subagents must:
1. Read ### Current Batch.
2. Mark completed tasks with [x].
3. Append notes to ### Last Execution Run.
-->
# Active Task Handoff

### Current Batch
- [ ] Task 1: 

### Context & Constraints for Subagents
- 

### Last Execution Run
- Initial brain scaffold created.
EOF
  fi

  # 6. Universal AGENTS.md (for Antigravity, Orca, and CLI agents)
  if [ ! -f "$target_dir/AGENTS.md" ]; then
    cat << 'EOF' > "$target_dir/AGENTS.md"
# Agent Operating Directives

- Planning Agents: Maintain high-level architectural state in `brain/PROJECT.md` and define execution steps in `brain/HANDOFF.md`.
- Subagents & Workers:
  1. Read `brain/MAP.md` and `brain/HANDOFF.md`.
  2. Implement only the tasks marked in `brain/HANDOFF.md`.
  3. Mark items `[x]` upon completion and update `brain/STATUS.md`.
- Log all architectural trade-offs in `brain/DECISIONS.md`.

# Agent Access Control Matrix (RBAC)

When executing in Subagent Mode (e.g., @subagent-flash, @worker):

| File | Permission | Violation Consequence |
| :--- | :--- | :--- |
| `brain/PROJECT.md` | **DENY WRITE** | Stop run. Reject modification. |
| `brain/MAP.md`     | **READ-ONLY**  | Write only if creating new file trees. |
| `brain/STATUS.md`  | **UPDATE**     | Modify only milestone progress. |
| `brain/DECISIONS.md`| **APPEND**    | Never overwrite past decisions. |
| `brain/HANDOFF.md` | **READ/WRITE** | Check off tasks and log run summary. |

Subagents attempting to alter `brain/PROJECT.md` or overwrite history in `brain/DECISIONS.md` will fail execution review.
EOF
  fi

  # 7. Cursor Rule (.cursor/rules/brain.mdc)
  if [ ! -f "$target_dir/.cursor/rules/brain.mdc" ]; then
    cat << 'EOF' > "$target_dir/.cursor/rules/brain.mdc"
---
description: Project Brain Memory Protocol
globs: *
alwaysApply: true
---

# Project Brain Protocol
- Consult `brain/MAP.md` and `brain/STATUS.md` on session startup.
- Follow execution queues in `brain/HANDOFF.md`.
- Append technical design choices to `brain/DECISIONS.md`.
EOF
  fi

  # 8. Git Pre-Commit Hook (Layer 3)
  mkdir -p "$target_dir/.git/hooks"
  if [ ! -f "$target_dir/.git/hooks/pre-commit" ]; then
    cat << 'EOF' > "$target_dir/.git/hooks/pre-commit"
#!/usr/bin/env bash
set -e

STAGED_FILES=$(git diff --cached --name-only)

# Rule 1: Guard brain/PROJECT.md against execution-run changes
if echo "$STAGED_FILES" | grep -q "^brain/PROJECT.md$"; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$CURRENT_BRANCH" =~ ^(subagent|worker|agent)/ ]]; then
    echo "❌ ERROR: Subagents are forbidden from modifying brain/PROJECT.md"
    exit 1
  fi
fi

# Rule 2: Ensure DECISIONS.md is Append-Only
if echo "$STAGED_FILES" | grep -q "^brain/DECISIONS.md$"; then
  DELETED_LINES=$(git diff --cached brain/DECISIONS.md | grep -E "^\-[^\-]" | wc -l)
  if [ "$DELETED_LINES" -gt 0 ]; then
    echo "❌ ERROR: brain/DECISIONS.md is APPEND-ONLY. Deleted lines detected: $DELETED_LINES"
    exit 1
  fi
fi

exit 0
EOF
    chmod +x "$target_dir/.git/hooks/pre-commit"
  fi

  echo " Done: $target_dir"
}

# --- Execution ---
if [ "$#" -eq 0 ]; then
  # Default: run on current directory
  inject_repo "$(pwd)"
else
  # Loop through provided directories
  for dir in "$@"; do
    if [ -d "$dir" ]; then
      inject_repo "$dir"
    else
      echo "Directory does not exist: $dir"
    fi
  done
fi
