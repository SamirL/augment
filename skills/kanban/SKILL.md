---
name: kanban
description: >
  Manage a project Kanban board. Use this skill whenever the user says "kanban", "add a task",
  "show the board", "what's on the board", "move X to doing/review/done", "remove task",
  "board status", "add a subtask", "clear done tasks", or uses /kanban. Also use this skill
  AUTONOMOUSLY: when you start working on something that matches a board task, move it to Doing.
  When you finish, move it to Done. When you discover bugs or new work items, add them to Todo.
  Keep the board current as you work — don't wait to be asked.
---

# Kanban Board

A project-scoped Kanban board stored as `.kanban.json` (source of truth) with an auto-generated
`.kanban.md` (human-readable view). Any AI agent (Claude Code, Codex, Gemini, etc.) can use this
to track tasks across four columns: **Todo**, **Doing**, **Review**, **Done**.

## Board schema

### `.kanban.json` format

```json
{
  "meta": {
    "nextId": 1
  },
  "todo": [],
  "doing": [],
  "review": [],
  "done": []
}
```

Each **task** object:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | int | yes | Auto-incrementing, from `meta.nextId` |
| `title` | string | yes | Short task name |
| `description` | string | no | Longer context, rationale, notes |
| `created` | string | yes | ISO date (YYYY-MM-DD) |
| `updated` | string | yes | ISO date, updated on any change |
| `subtasks` | array | no | List of subtask objects |

Each **subtask** object:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | int | yes | Scoped to parent task (1, 2, 3...) |
| `title` | string | yes | Subtask description |
| `done` | boolean | yes | Completion status |

### `.kanban.md` format (auto-generated, read-only)

Generated from the JSON after every mutation. **Never edit this file directly** — changes will
be overwritten on the next board update.

Template:

```markdown
# Kanban Board

## Todo
- [ ] **Task title** — description (1/3 done)
  - [x] Completed subtask
  - [ ] Pending subtask
  - [ ] Another pending subtask

## Doing
- [ ] **Another task**

## Review

## Done
- [x] **Finished task** — description
```

Rules:
- Use `- [ ]` for tasks in Todo/Doing/Review, `- [x]` for tasks in Done
- Show `**Title**` in bold, followed by ` — description` if description exists
- If a task has subtasks, show progress after the title: `(2/3 done)`
- Indent subtasks with two spaces: `  - [ ] subtask` or `  - [x] subtask`
- Always show all four column headers, even if empty
- Sort tasks by ID within each column

## Slash command: `/kanban`

| Command | Action |
|---------|--------|
| `/kanban` | Show the current board |
| `/kanban add <title>` | Add a task to Todo. Prompt for optional description. |
| `/kanban move <task\|id> <column>` | Move a task to another column (todo/doing/review/done) |
| `/kanban remove <task\|id>` | Remove a task entirely |
| `/kanban edit <task\|id>` | Update a task's title or description |
| `/kanban sub <task\|id> <subtask title>` | Add a subtask to a task |
| `/kanban clear done` | Remove all tasks in the Done column |

**Task matching:** When the user provides a task reference, try to match by:
1. **ID** — if the reference is a number, match by task ID
2. **Title substring** — case-insensitive substring match against task titles
3. **Ambiguous** — if multiple tasks match, show the matches and ask which one

**Column names:** Accept common variations:
- `todo` / `to-do` / `backlog`
- `doing` / `in-progress` / `wip`
- `review` / `in-review` / `pr`
- `done` / `completed` / `finished`

## Natural language

Also respond to conversational requests about the board. Examples:
- "Add 'fix login bug' to the board"
- "What's on the board?"
- "Move the auth task to review"
- "Remove task 3"
- "Add a subtask to the refactoring task: extract helper functions"
- "What am I working on?" (show Doing column)
- "Clear the done tasks"
- "Break down task 2 into subtasks"

## Autonomous tracking

**This is critical.** Don't just wait for explicit board commands. Proactively manage the board
as you work:

### When starting work
- Check if there's a matching task on the board for what you're about to do
- If yes: move it to **Doing** and briefly note it ("Board: moved 'fix login' to Doing")
- If no matching task exists: you can optionally add one, especially for non-trivial work

### When finishing work
- Move the task to **Done**
- Check off any completed subtasks
- Briefly note it ("Board: moved 'fix login' to Done")

### When discovering issues
- If you find a bug, missing feature, or TODO while working on something else, add it to
  **Todo** with a description of what you found
- Example: "Board: added 'Input validation missing on /api/users' to Todo"

### When subtasks complete
- Check off individual subtasks as you complete them
- When all subtasks of a task are done, suggest moving the parent to the next column

### Keep it low-friction
- Board updates should be **one-line status notes**, not verbose explanations
- Don't ask for confirmation — just update and briefly mention what changed
- Don't let board management interrupt the flow of actual work

## Operations — detailed steps

### For every operation:

1. **Read** `.kanban.json` using the Read tool. Never assume the board's current state.
2. **Parse** the JSON content.
3. **Perform** the requested operation (add/move/remove/edit/etc.).
4. **Update** `meta.nextId` if a new task or subtask was added.
5. **Set** `updated` to today's date on any modified task.
6. **Write** the updated JSON back to `.kanban.json` using the Write tool.
7. **Regenerate** `.kanban.md` from the updated JSON using the Write tool.

### Board initialization

**IMPORTANT:** If `.kanban.json` does not exist, you MUST create it immediately — even if the user
only asked to "show" the board. Never just report that the board doesn't exist. Always initialize
it and then show the (empty) result. The board should feel like it always exists.

Create both files:

**`.kanban.json`:**
```json
{
  "meta": {
    "nextId": 1
  },
  "todo": [],
  "doing": [],
  "review": [],
  "done": []
}
```

**`.kanban.md`:**
```markdown
# Kanban Board

## Todo

## Doing

## Review

## Done
```

No special "init" command needed — just create on first use, for any operation.

### Adding a task

1. Read the board
2. Create a new task object with `id = meta.nextId`, increment `meta.nextId`
3. Set `created` and `updated` to today's date
4. Add to the specified column (default: `todo`)
5. Write both files
6. Display: "Added task #N: **Title** to Todo"

### Moving a task

1. Read the board
2. Find the task (by ID or title substring)
3. Remove it from its current column
4. Add it to the target column
5. Update `updated` date
6. Write both files
7. Display: "Moved #N: **Title** from Doing to Done"

### Removing a task

1. Read the board
2. Find the task
3. Remove it from its column
4. Write both files
5. Display: "Removed #N: **Title**"

### Editing a task

1. Read the board
2. Find the task
3. If called from slash command, ask what to change (title, description, or both) using `AskUserQuestion`
4. Update the fields
5. Update `updated` date
6. Write both files

### Adding a subtask

1. Read the board
2. Find the parent task
3. Initialize `subtasks` array if it doesn't exist
4. Add subtask with `id` = next available within the parent (max existing + 1, or 1)
5. Set subtask `done` to `false`
6. Update parent's `updated` date
7. Write both files
8. Display: "Added subtask to #N: **subtask title**"

### Toggling a subtask

1. Read the board
2. Find the parent task, then the subtask by ID or title
3. Toggle `done` boolean
4. Update parent's `updated` date
5. Write both files
6. If all subtasks are now done, suggest moving the parent task forward

### Clearing done tasks

1. Read the board
2. Remove all tasks from the `done` array
3. Write both files
4. Display: "Cleared N completed tasks"

### Showing the board

1. Read `.kanban.json`
2. Display the board as a **visual kanban** using Unicode box-drawing inside a code block.
   This renders beautifully in Claude Code's monospace terminal.

**Format:** A horizontal kanban with four side-by-side columns using Unicode box-drawing.
Wrap the entire output in a fenced code block (```) so alignment is preserved.

**How to build it:**

1. Set column inner width to 18 characters (adjust wider if task titles need it, but keep all 4 equal).
2. For each column, build an array of content lines:
   - For each task: `#ID Title` (truncate with `..` if too long). If subtasks, append ` [done/total]`.
   - If the task has a description: add a line `   description` (truncated).
   - If the task has subtasks: add lines `  ✓ done-subtask` or `  · pending-subtask`.
   - Add a blank line between tasks.
3. Pad all 4 columns to the same height (the tallest column determines height).
4. Render row by row, joining cells with `│`, padding each cell to the fixed width.

**Example with tasks:**

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

**Example empty board:**

```
┌──────────────────┬──────────────────┬──────────────────┬──────────────────┐
│    Todo (0)      │   Doing (0)      │  Review (0)      │    Done (0)      │
├──────────────────┼──────────────────┼──────────────────┼──────────────────┤
│                  │                  │                  │                  │
└──────────────────┴──────────────────┴──────────────────┴──────────────────┘
```

**Rendering rules:**
- Top border: `┌──┬──┐`, header row, separator: `├──┼──┤`, content rows, bottom: `└──┴──┘`
- Every row: `│` + cell padded to column width + `│` + next cell... for all 4 columns
- Column headers: centered, bold-style with spaces (e.g., `    Todo (2)      `)
- Tasks: `#ID Title` left-aligned within the cell
- Subtasks: `✓` for done, `·` for pending, indented 2 spaces
- Subtask progress: `[2/3]` right-aligned on the task title line or the line below
- Blank line between tasks in the same column
- Empty columns: just blank rows (no special marker needed)
- All 4 columns MUST have the same width and same number of rows

If the board is empty, also add below the code block:
"Use `/kanban add <title>` or ask me to add a task to get started."

## Edge cases

- **Task not found:** "No task matching 'X' found. Current tasks: [list titles with IDs]"
- **Ambiguous match:** "Multiple tasks match 'auth': #2 'Auth refactor' (Doing), #5 'Auth tests' (Todo). Which one?"
- **Move to same column:** "Task #3 is already in Doing."
- **Empty board on show:** "The board is empty."
- **Clear done with nothing done:** "No completed tasks to clear."
- **Subtask on a Done task:** Allow it, but note that the parent is already marked done.

## Git integration

Both `.kanban.json` and `.kanban.md` are project artifacts meant to be committed alongside the
code. They track what was done, what's in progress, and what's planned — useful context for any
contributor (human or AI) picking up the project.

Don't add them to `.gitignore`. They should be version-controlled.
