---
name: external-review
description: >
  Send coding work for external review by another LLM (Codex CLI). Use this skill whenever the user
  says "external review", "codex review", "send for review", "get a second opinion", "have codex
  check this", or "/external-review". Also triggers automatically via Stop hook when Claude finishes
  coding and uncommitted changes are detected — Claude should then ask the user if they want an
  external review before ending the session. Do NOT trigger on generic "review my changes" requests
  unless the user explicitly mentions an external reviewer or Codex.
---

# External Review

Send your coding session's work to an external LLM for independent code review. The reviewer gets
full context: a summary of what you were trying to accomplish (from the session transcript), the
git diff, and the full content of modified files.

Currently uses **Codex CLI** (`codex exec`). Designed to be extensible to other CLI agents
(Gemini CLI, etc.) in the future.

## When this skill activates

Two paths:

1. **Slash command** — the user types `/external-review` or asks for an external review.
   Optional arguments are passed as custom review instructions (e.g., `/external-review focus on
   the database queries` or `/external-review security only`).
2. **Auto-ask** — the Stop hook detects uncommitted changes and sends you a system message.
   When you receive that message, ask the user with `AskUserQuestion` whether they want a review
   before you end the session. Respect their answer — if they say no, stop normally.

## Review workflow

### Step 0 — Confirmation (auto-ask path only)

**Skip this step if the user explicitly asked for a review** (slash command or natural language
like "send to codex"). They've already consented by asking.

**Only ask for confirmation when triggered by the Stop hook** (auto-ask path), because the user
didn't explicitly request a review. Use `AskUserQuestion`:
- header: "Review"
- question: "You have uncommitted changes. Want to send them to Codex (OpenAI) for review?"
- options:
  - "Yes, review with Codex" — Continue with the review workflow
  - "No, I'm done" — Stop the session normally

### Step 0.5 — Review scope (unless custom instructions provided)

If the user provided custom instructions (e.g., `/external-review focus on security`), use those
as the review focus and skip this step.

Otherwise, let the user pick the review scope using `AskUserQuestion`:
- header: "Scope"
- question: "What kind of review?"
- options:
  - "Full review (Recommended)" — Bugs, security, performance, style, suggestions
  - "Security focused" — Focus on vulnerabilities, injection risks, auth, secrets
  - "Quick check" — High-level pass, only flag critical/major issues

Store the chosen scope — it determines which review instructions to send to Codex.

### Step 1 — Gather context

First, check if HEAD exists (the repo may have no commits yet):

```bash
git rev-parse HEAD 2>/dev/null
```

Then collect the review payload:

```bash
# Always: list all changed files (tracked and untracked)
git status --porcelain

# Only if HEAD exists: get the diff for tracked changes
git diff HEAD
git diff --name-only HEAD
```

**If HEAD doesn't exist** (fresh repo, no commits): skip `git diff HEAD` entirely. Use
`git status --porcelain` to find all files — they're all new. Read each one.

**If HEAD exists:** `git diff HEAD` shows tracked changes. For **untracked (new) files**,
check `git status --porcelain` for lines starting with `??` — read those files too and include
them in the payload. This ensures new files aren't missed.

Use the `Read` tool to read each modified and untracked file's full content.

**Sensitive file guard:** Before including any file in the review payload, check if it looks
like it contains secrets. Skip (and warn the user about) files matching these patterns:
- `.env`, `.env.*`, `*.env`
- `credentials*`, `*secret*`, `*token*`, `*.key`, `*.pem`, `*.p12`
- `config.local.*`, `settings.local.*`
- Any file containing strings like `API_KEY=`, `SECRET=`, `PASSWORD=`, `Bearer `, `-----BEGIN`

Tell the user which files were excluded and why. If the user explicitly wants to include them,
they can confirm — but never send them silently.

### Step 2 — Summarize the session intent

Before sending to Codex, write a concise summary (3-8 sentences) of what was accomplished in this
session and why. This summary should capture:

- What the user asked for
- What approach you took
- Key decisions made along the way
- Any known limitations or trade-offs

This summary is crucial — it gives the external reviewer the "why" behind the changes so they can
evaluate whether the implementation actually achieves the goal, not just whether the code is clean.

### Step 3 — Run the review

Tell the user before invoking: **"Sending to Codex for review — this may take a few minutes..."**
This is important because Codex can take 1-5 minutes and the user needs to know why nothing is
happening.

Use the Bash tool to invoke Codex CLI. Pass the full review payload via stdin. Adapt the review
instructions based on the scope chosen in Step 0.5 (or custom instructions from the user):

```bash
codex exec -s read-only - <<'REVIEW_PROMPT'
You are reviewing code changes made by another AI coding assistant (Claude). Your job is to provide
an independent, critical review. The developer's intent and the full context are provided below.

## Session Context
[paste your session summary here]

## Git Diff
[paste git diff HEAD output here]

## Modified Files (full content)
[paste each file's full content here, with filename headers]

## Review Instructions

[ADAPT BASED ON SCOPE:]

**Full review** — use all categories below.
**Security focused** — only use the Security category. Be thorough: check for injection, auth
bypass, secret exposure, unsafe deserialization, path traversal, SSRF, etc.
**Quick check** — only flag critical and major issues across all categories. Skip minor/style.
**Custom instructions** — follow the user's specific instructions instead.

Provide a thorough code review organized into these categories. Only include categories where you
have findings — skip empty ones.

### Bugs
Actual bugs, logic errors, off-by-one errors, race conditions, null/undefined risks.
Reference specific file:line. Severity: critical / major / minor.

### Security
Injection risks, auth issues, secret exposure, unsafe operations.
Reference specific file:line. Severity: critical / major / minor.

### Performance
Unnecessary allocations, O(n^2) where O(n) is possible, missing caching, blocking calls.
Reference specific file:line.

### Style & Maintainability
Naming, dead code, missing error handling, unclear logic, inconsistencies.
Reference specific file:line.

### Suggestions
Improvements that go beyond the current scope but are worth noting for the future.

If the code looks solid, say so directly — don't manufacture issues.
End with a one-line overall verdict: LGTM / Minor issues / Needs revision / Major concerns.
REVIEW_PROMPT
```

**Important notes on the Codex invocation:**
- Use `-s read-only` sandbox mode — the reviewer should not modify any files
- Use `-` to read the prompt from stdin so we can include the full context
- The heredoc uses `<<'REVIEW_PROMPT'` (quoted) to prevent variable expansion
- If `codex` is not installed or fails, inform the user and suggest installing it

### Step 4 — Review the reviewer's findings

Before presenting anything to the user, **critically evaluate each finding from Codex.** The
external reviewer can be wrong — it may flag false positives, misunderstand the codebase context,
or make incorrect assumptions about how frameworks or tools work. For each finding, ask yourself:

- Is this actually a bug, or is the reviewer misunderstanding how this code/tool works?
- Does the referenced file:line actually contain the issue described?
- Is this finding based on outdated knowledge or incorrect assumptions?
- Did the reviewer verify its claim, or is it speculating?

**Mark findings you disagree with.** When presenting to the user, note which findings you've
validated vs which you think are false positives, and briefly explain why. This gives the user
a more useful review — not just a raw dump of another LLM's output.

### Step 5 — Present findings

Show the validated review results inline in the conversation. Add a brief header:

```
## External Review (Codex)

[Codex's review output, with your annotations on any disputed findings]
```

If the review found issues, **tailor the follow-up options to what was actually found.** Count
the validated findings by category and offer specific options. For example, if Codex found 2 bugs
and 3 style issues but you determined 1 style issue is a false positive:

Use `AskUserQuestion`:
- header: "Next step"
- question: "Codex found 2 bugs and 2 valid style issues (1 style finding was a false positive). What would you like to do?"
- options:
  - "Fix bugs only (Recommended)" — Address the 2 bug findings
  - "Fix all 4 valid issues" — Address bugs and style issues
  - "Discuss" — Talk through specific findings before deciding
  - "Ignore" — Dismiss the review and move on

Adapt the options to what was actually found — don't offer "Fix bugs" if there were no bugs.
If the verdict was LGTM with no actionable findings, just say so and skip the follow-up question.
If there are only non-blocking suggestions, mention them inline without prompting.

## Handling edge cases

### No changes detected
If `git status --porcelain` is empty (no tracked changes AND no untracked files), tell the user
there's nothing to review.

### No HEAD (fresh repo)
If `git rev-parse HEAD` fails (repo has no commits yet), use `git status --porcelain` to find
all files and treat everything as new. Skip `git diff HEAD`.

### Codex not installed
If the `codex` command is not found, tell the user:
> "Codex CLI is not installed. Install it with `npm install -g @openai/codex` and make sure
> you've authenticated with `codex login`."

### Very large diffs
If the diff exceeds ~500 lines, consider focusing on the most important files. Tell the user
you're truncating and which files you're prioritizing.

### Review fails or times out
If Codex returns an error or takes too long, report the error to the user and offer to retry
or skip.

## Extensibility

The skill currently uses Codex CLI. To add another reviewer in the future:
1. Add new options to the `AskUserQuestion` call (e.g., "Review with Gemini")
2. Swap `codex exec` for the appropriate CLI command (e.g., `gemini ...`)
3. The review prompt template stays the same — it's model-agnostic

## Auto-ask behavior (Stop hook)

A Stop hook (`hooks/stop-hook.sh`) runs whenever Claude considers stopping. It checks for
uncommitted git changes. If changes exist, it sends a reason telling Claude to ask the user
if they want an external review.

The hook uses a session-scoped state file (in `/tmp/claude-external-review/<session_id>`) to
ensure it only asks once per session. If the user says no, the hook won't block again. The state
is stored outside the repo to avoid contaminating git status.
