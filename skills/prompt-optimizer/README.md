# Prompt Optimizer

Analyzes and improves your prompts before executing them. Write a rough prompt, get an optimized version, approve it, and Claude runs it.

## How it works

1. You enter a prompt
2. Claude analyzes failure modes — the specific ways a model would misinterpret or underdeliver
3. Claude rewrites it — applying only the techniques that fix actual problems
4. You review and approve via interactive options
5. Claude executes the optimized prompt

## Trigger phrases

- `"Optimize this prompt: ..."`
- `"Improve my prompt"`
- `"Make this prompt better"`
- `"Prompt engineer this"`
- `/prompt-optimizer`

## What it optimizes

- **Ambiguity** — replaces vague instructions with concrete constraints
- **Missing context** — adds audience, length, tone, output format
- **Failure modes** — adds guardrails for likely misinterpretations
- **Structure** — sections, steps, or formatting when it helps
- **Research** — looks up specific topics (products, APIs, games) to bake in real facts

Calibrates effort to need. A clear prompt gets a light polish, not a full rewrite.

## Example

**You type:**
```
optimize this prompt: write me something about machine learning for my blog
```

**Claude responds with an optimized version, asks if you want to run it, and executes on approval.**
