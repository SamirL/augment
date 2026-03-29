# External Review

Sends your coding work to an external LLM for independent code review. Currently uses Codex CLI, designed to be extensible to other CLI agents (Gemini CLI, etc.).

## How it works

1. Claude gathers your changes (git diff + full file contents)
2. Claude summarizes the session intent (what you were trying to accomplish)
3. The payload is sent to Codex CLI for independent review
4. Claude validates Codex's findings (filtering false positives)
5. Validated results are presented inline with categorized findings

## Trigger modes

**Slash command:**
```
/external-review
/external-review focus on security
```

**Natural language:**
- `"Send this to codex for review"`
- `"Get a second opinion on these changes"`
- `"Have codex check this"`

**Auto-ask:** A Stop hook detects uncommitted changes when Claude finishes coding and offers to send for review.

## Review scopes

- **Full review** — bugs, security, performance, style, suggestions
- **Security focused** — vulnerabilities, injection risks, auth, secrets
- **Quick check** — only critical/major issues
- **Custom** — pass your own instructions via `/external-review <instructions>`

## Requirements

- [Codex CLI](https://github.com/openai/codex) installed and authenticated (`npm install -g @openai/codex && codex login`)

## Safety

- Confirms before sending code to an external service (auto-ask path)
- Filters sensitive files (.env, credentials, keys) from the review payload
- Reviewer runs in read-only sandbox mode
