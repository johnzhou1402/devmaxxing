# Claude Skills

Personal productivity skills for Claude Code.

## Quick Start

```bash
git clone https://github.com/johnzhou/claude-skills.git
cd claude-skills
./setup.sh
```

## Skills

### `/end-day`

End-of-day workflow that runs before you leave work:

1. **Standup summary** - Leadership-friendly summaries of your PRs
2. **PR feedback** - Extracts and analyzes reviewer comments with lessons learned
3. **Email digest** - Sends you a nicely formatted recap (optional)

**Usage:**
```
/end-day          # today's PRs
/end-day ystd     # yesterday's PRs
/end-day 2026-01-05  # specific date
```

**Output:**
- `~/devmaxxing/standup/YYYY-MM-DD.md` - standup notes
- `~/devmaxxing/reviews/daily/YYYY-MM-DD.md` - feedback analysis
- Email to your inbox (if configured)

## Prerequisites

- [Claude Code](https://claude.ai/code) installed
- [GitHub CLI](https://cli.github.com/) authenticated (`gh auth login`)

## File Structure

```
~/.claude/skills/
└── end-day/
    ├── SKILL.md      # Skill instructions
    └── config.json   # Email settings (optional)

~/devmaxxing/
├── standup/          # Daily standup notes
└── reviews/
    └── daily/        # PR feedback analysis
```
