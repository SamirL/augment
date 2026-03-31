# Kanban Board

A project-scoped Kanban board for AI coding agents. Track tasks across four columns — Todo, Doing, Review, Done — with subtask support and task dependencies. The board lives in your project directory as `.kanban.json` (source of truth) and `.kanban.md` (human-readable view).

## How it works

1. The AI agent reads and writes `.kanban.json` to manage tasks
2. After every change, `.kanban.md` is regenerated for human readability
3. The agent autonomously tracks its work — moving tasks to Doing when it starts, Done when it finishes
4. A Stop hook reminds the agent to update tasks left in Doing before ending a session

## Slash commands

| Command | Description |
|---------|-------------|
| `/kanban` | Show the current board |
| `/kanban add <title>` | Add a task to Todo |
| `/kanban move <task> <column>` | Move a task (by ID or name) |
| `/kanban remove <task>` | Remove a task |
| `/kanban edit <task>` | Edit a task's title or description |
| `/kanban sub <task> <subtask>` | Add a subtask |
| `/kanban block <task> <blocker>` | Add a dependency (task can't start until blocker is done) |
| `/kanban unblock <task> <blocker>` | Remove a dependency |
| `/kanban clear done` | Remove all completed tasks |

## Natural language

Also works with plain requests:
- "Add 'fix login bug' to the board"
- "What's on the board?"
- "Show me the kanban"
- "Move the auth task to review"
- "What am I working on?" (shows Doing column)
- "Break down task 2 into subtasks"
- "Clear the done tasks"

## Display

The board is displayed as a horizontal kanban using Unicode box-drawing characters:

```
┌──────────────────┬──────────────────┬──────────────────┬──────────────────┐
│    Todo (2)      │   Doing (1)      │  Review (0)      │    Done (1)      │
├──────────────────┼──────────────────┼──────────────────┼──────────────────┤
│                  │                  │                  │                  │
│ #1 Fix login bug │ #3 Refactor auth │                  │ #4 Setup CI      │
│                  │            [2/3] │                  │                  │
│ #2 Add input     │  ✓ Extract token │                  │                  │
│    validation    │  ✓ Refresh flow  │                  │                  │
│                  │  · Update tests  │                  │                  │
│                  │                  │                  │                  │
└──────────────────┴──────────────────┴──────────────────┴──────────────────┘
```

## Storage format

**`.kanban.json`** — structured data, version-controlled:
```json
{
  "meta": { "nextId": 3 },
  "todo": [
    {
      "id": 1,
      "title": "Add input validation",
      "description": "Validate API endpoint inputs against schema",
      "created": "2026-03-30",
      "updated": "2026-03-30",
      "subtasks": [
        { "id": 1, "title": "Validate /users endpoint", "done": true },
        { "id": 2, "title": "Validate /posts endpoint", "done": false }
      ]
    }
  ],
  "doing": [{ "id": 2, "title": "Refactor auth module", "created": "2026-03-30", "updated": "2026-03-30" }],
  "review": [],
  "done": []
}
```

**`.kanban.md`** — auto-generated, human-readable:
```markdown
# Kanban Board

## Todo
- [ ] **Add input validation** — Validate API endpoint inputs against schema (1/2 done)
  - [x] Validate /users endpoint
  - [ ] Validate /posts endpoint

## Doing
- [ ] **Refactor auth module**

## Review

## Done
```

## Dependencies

Tasks can depend on other tasks via the `blocked_by` field. A blocked task cannot move to Doing until all its blockers are in Done.

```
/kanban add "Deploy to prod"
/kanban block Deploy 1        # Deploy is blocked by task #1
/kanban move Deploy doing     # Error: blocked by #1
/kanban move 1 done           # "Task #1 done — this unblocks #3 Deploy to prod"
/kanban move Deploy doing     # Now succeeds
```

Blocked tasks show `[blocked: #1]` in the board display.

## Autonomous tracking

The agent proactively manages the board:
- Moves tasks to Doing when starting work
- Moves tasks to Done when finishing
- Adds new tasks when discovering bugs or TODOs
- Checks off subtasks as they're completed
- Suggests moving parent tasks when all subtasks are done

## Requirements

None — the skill uses only built-in file read/write tools.
