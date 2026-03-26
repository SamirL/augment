# Prompt Optimizer — Claude Code Skill

A Claude Code skill that analyzes and improves your prompts before executing them. Write a rough prompt, get an optimized version, approve it, and Claude runs it — all in one flow.

## How it works

1. **You enter a prompt** — paste it or describe what you want
2. **Claude rewrites it** — applying prompt engineering techniques (role assignment, output formatting, step-by-step decomposition, ambiguity removal)
3. **You review and approve** — Claude shows you the optimized version with a brief explanation of what changed
4. **Claude executes it** — responds to the approved prompt as if you'd typed it yourself

## Installation

### Option A: Plugin marketplace (recommended)

Register this repo as a marketplace in Claude Code, then install:

```bash
# One-time: register the marketplace
/plugin marketplace add YOUR_USERNAME/prompt-optimizer-skill

# Install the skill
/plugin install prompt-optimizer@YOUR_MARKETPLACE_NAME
```

> Replace `YOUR_USERNAME` and `YOUR_MARKETPLACE_NAME` with your actual GitHub username and chosen marketplace name.

### Option B: Manual install

```bash
git clone https://github.com/YOUR_USERNAME/prompt-optimizer-skill.git
cp -r prompt-optimizer-skill/skills/prompt-optimizer ~/.claude/skills/
```

### Option C: Direct copy

If you just want the skill file, copy `skills/prompt-optimizer/SKILL.md` into `~/.claude/skills/prompt-optimizer/SKILL.md`.

## Usage

Once installed, the skill triggers automatically when you say things like:

- `"Optimize this prompt: ..."`
- `"Improve my prompt"`
- `"Make this prompt better"`
- `"Prompt engineer this for me"`
- `"Help me write a better prompt for..."`

### Example

**You type:**
```
optimize this prompt: write me something about machine learning for my blog
```

**Claude responds with an optimized version:**
```
Write a ~800-word blog post introducing machine learning to a non-technical audience.
Cover what ML is (with a real-world analogy), three practical applications people
encounter daily (e.g., recommendation systems, spam filters, voice assistants), and
a brief look at where the field is heading. Use a conversational, accessible tone.
Structure it with a hook intro, subheadings for each section, and a forward-looking
conclusion. No jargon without explanation.
```

**You approve → Claude executes the optimized prompt.**

## What it optimizes

The skill applies prompt engineering techniques only where they help:

- **Clarity** — removes ambiguity and vague instructions
- **Structure** — adds formatting, sections, or step-by-step flow when beneficial
- **Specificity** — locks in audience, length, tone, and output format
- **Guardrails** — adds constraints to prevent common misinterpretations
- **Techniques** — role assignment, few-shot examples, negative constraints, etc.

It won't over-engineer simple prompts. A clear three-line prompt stays three lines if that's all it needs.

## License

MIT — see [LICENSE](LICENSE).
