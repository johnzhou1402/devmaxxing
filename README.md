# devmaxxing

For 10x engineers who want to actually learn from their work B)

## Quick Start

```bash
git clone https://github.com/johnzhou1402/devmaxxing.git
cd devmaxxing
./setup.sh
```

## What it does

### /end-day
Run before you leave work:

1. **📋 Standup summary** - Leadership-friendly summaries of your PRs (no jargon)
2. **💬 PR feedback** - Extracts reviewer comments and analyzes lessons learned
3. **🎯 Trivia generation** - Creates quiz questions from systems you touched
4. **📧 Email digest** - Sends you a casual, emoji-rich recap (optional)

### /trivia
Quiz yourself on Whop's business systems:

1. **🎲 Random questions** - From your own PR history
2. **📊 Track progress** - See accuracy by system
3. **🔥 Streaks** - Build consistency

## Usage

```
/end-day          # today's PRs
/end-day ystd     # yesterday's PRs
/end-day 2026-01-05  # specific date

/trivia           # random question
/trivia stats     # your score & streaks
/trivia payments  # questions about payments system
```

## Example Output

**Email you receive:**

```
🌙 End of Day: Tuesday, January 7

📋 What I worked on (3 PRs)

🟢 Cache plaid balances
   Ready for Review
   We can now see real-time bank balances for Plaid accounts.
   Helps with risk assessment and payout decisions.
   ⏳ Waiting on review

💬 Feedback I got (2 comments)

jacksonhuether on PR #455
   "Use decimal(10,2) for money, not float"
   💡 Takeaway: Floats cause precision errors with money.
```

**Files saved:**
- `~/devmaxxing/standup/2026-01-07.md` - daily standup
- `~/devmaxxing/reviews/daily/2026-01-07.md` - daily feedback
- `~/devmaxxing/reviews/history.md` - all feedback ever (appended)
- `~/devmaxxing/trivia/questions.json` - trivia question bank

**Trivia example:**

```
🎯 Trivia Time!

System: accelerator_program
Source: PR #612

Q: What's the GMV threshold for accelerator program graduation?

> ready

📝 Answer:
$500,000 - after this, companies pay 2.5% card fees instead of 0%

Did you get it right? (y/n) y

Nice! 🎉 You've gotten this right 3/4 times.
```

## Prerequisites

- [Claude Code](https://claude.ai/code)
- [GitHub CLI](https://cli.github.com/) - `brew install gh && gh auth login`

## Setup creates

```
~/.claude/skills/
├── end-day/
│   ├── SKILL.md        # Instructions for Claude
│   └── config.json     # Email settings (optional)
└── trivia/
    └── SKILL.md        # Trivia skill instructions

~/devmaxxing/
├── standup/            # Daily standup notes
├── reviews/
│   ├── daily/          # Daily PR feedback
│   └── history.md      # All feedback ever
└── trivia/
    └── questions.json  # Trivia question bank
```

## Email Setup (Optional)

The setup script walks you through this, but if you want email digests:

1. Create free account at [resend.com](https://resend.com)
2. Get API key from API Keys → Create API Key
3. Set usage alerts at Settings → Alerts (recommended)

Free tier: 100 emails/day (plenty for daily digests)
