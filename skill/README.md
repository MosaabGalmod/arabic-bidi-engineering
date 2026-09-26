# Arabic BiDi Engineering Agent Skill

This is an Agent Skill designed for AI coding assistants. It enforces mandatory rules for generating, formatting, or processing Arabic bidirectional (BiDi/RTL) documents across Word (.docx), Excel (.xlsx), PDF, HTML/CSS, and backend scripts.

By loading this skill, AI agents learn to correctly handle Arabic text layout and styling without relying on naive translation or default LTR conventions, avoiding common issues like inverted punctuation or broken tables.

## Installation / Usage

Depending on your AI assistant, configure it to load `SKILL.md` from this directory.

### Claude Code
Add this directory to your Claude skills:
```bash
cp -r . ~/.claude/skills/arabic-bidi-engineering
```

### Cursor
Create a rule in your `.cursor/rules` directory:
```bash
cp SKILL.md .cursor/rules/arabic-bidi-engineering.mdc
```

### Codex / Gemini
Reference the `SKILL.md` in your `AGENTS.md` or `GEMINI.md` system prompt guidelines, or include the contents directly in your project instructions.
