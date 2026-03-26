# Prompt Optimizer — Claude Code Skill

A Claude Code skill that analyzes and improves your prompts before executing them. Write a rough prompt, get an optimized version, approve it, and Claude runs it — all in one flow.

## How it works

1. **You enter a prompt** — paste it or describe what you want
2. **Claude analyzes failure modes** — identifies the specific ways a model would misinterpret or underdeliver on the original
3. **Claude rewrites it** — applying only the techniques that fix actual problems (specificity, constraints, structure, format)
4. **You review and approve** — Claude shows you the optimized version with a brief explanation of what changed
5. **Claude executes it** — responds to the approved prompt as if you'd typed it yourself

## Installation

### Option A: Marketplace (recommended)

Register this repo as a skill marketplace in Claude Code:

```bash
/plugin marketplace add sam-prompt-optimizer
```

Then browse and install the skill from the marketplace UI.

### Option B: Manual install

```bash
git clone https://github.com/YOUR_USERNAME/prompt-optimizer-skill.git
cp -r prompt-optimizer-skill/skills/prompt-optimizer ~/.claude/skills/
```

### Option C: Direct copy

Copy `skills/prompt-optimizer/SKILL.md` into `~/.claude/skills/prompt-optimizer/SKILL.md`.

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

**You approve, Claude executes the optimized prompt.**

## What it optimizes

The skill focuses on fixing failure modes — the specific ways a model would get the output wrong:

- **Ambiguity** — replaces vague instructions with concrete constraints
- **Missing context** — adds audience, length, tone, and output format
- **Failure modes** — adds guardrails for the most likely misinterpretations
- **Structure** — adds sections, steps, or formatting when it materially helps
- **Type-specific** — different strategies for code, creative writing, system prompts, and analysis

It calibrates effort to need. A clear three-line prompt gets a light polish, not a twenty-line overhaul.

## License

MIT — see [LICENSE](LICENSE).
