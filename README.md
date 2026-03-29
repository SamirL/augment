# Augment

A collection of skills that augment AI coding agents. Works with Claude Code and other AI coding assistants.

## Skills

| Skill | Description |
|---|---|
| [prompt-optimizer](skills/prompt-optimizer/) | Analyzes and improves your prompts before executing them |
| [external-review](skills/external-review/) | Sends your coding work to an external LLM (Codex CLI) for independent review |

## Installation

### Marketplace (recommended)

Register this repo as a skill marketplace in Claude Code:

```bash
/plugin marketplace add SamirL/augment
```

Then browse and install skills from the marketplace UI.

### Manual install

```bash
git clone https://github.com/SamirL/augment.git
cp -r augment/skills/<skill-name> ~/.claude/skills/
```

## Adding new skills

Each skill lives in its own directory under `skills/` with a `SKILL.md` file and optional supporting files (hooks, scripts, evals). See existing skills for the structure.

## License

MIT — see [LICENSE](LICENSE).
