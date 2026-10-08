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
