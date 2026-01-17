---
name: end-day
description: Auto-generate standup summaries and save PR feedback (today + catch up past 3 days)
---

# End Day

Generate standup summary, save PR feedback, and email yourself a digest. Fully automatic - just run `/end-day` with no arguments.

## Usage

- `/end-day` - Process today + catch up on any missing days from the past 3 days

## Steps

### 1. Determine time windows (timezone-aware)

Get the user's local timezone and calculate UTC cutoffs for today and past 3 days:

```bash
# Get timezone
date +%Z  # e.g., EST, PST

# Get local date
LOCAL_DATE=$(date +%Y-%m-%d)

# Calculate UTC offset (EST = -5, PST = -8, etc.)
# Midnight local time converted to UTC = start of that day for PR filtering
```

**Calculate UTC cutoffs for each day:**

| Day | Local Midnight | UTC Equivalent (EST example) |
|-----|----------------|------------------------------|
| Today | Jan 7 00:00 EST | Jan 7 05:00 UTC |
| Yesterday | Jan 6 00:00 EST | Jan 6 05:00 UTC |
| 2 days ago | Jan 5 00:00 EST | Jan 5 05:00 UTC |
| 3 days ago | Jan 4 00:00 EST | Jan 4 05:00 UTC |

### 2. Check which days need processing

For each of the past 3 days + today, check if output files exist and are complete:

```bash
# Check if standup file exists and has content
ls ~/devmaxxing/standup/YYYY-MM-DD.md

# Check if daily review file exists
ls ~/devmaxxing/reviews/daily/YYYY-MM-DD.md
```

**A day needs processing if:**
- Standup file is missing
- Standup file exists but has 0 PRs (empty day that might now have PRs)
- Review file is missing when there were PRs with human feedback

### 3. Get PRs from GitHub for all days that need processing

```bash
# Get all recent PRs (covers past 3 days + today)
gh pr list --author @me --state all --limit 100 --json number,title,headRefName,updatedAt,state,isDraft,reviewDecision,url
```

**Filter PRs by day using UTC timestamps:**

For each day that needs processing, filter PRs where:
- `updatedAt >= [day's midnight in UTC]` AND
- `updatedAt < [next day's midnight in UTC]`

**Today is special:** Filter `updatedAt >= [today's midnight UTC]` with no upper bound (up to current time).

### 4. Generate Standup Summary (for each day that needs processing)

For each PR, gather context and write a leadership-friendly summary:

```bash
# PR details
gh pr view <number> --json title,body,state,isDraft,reviewDecision,statusCheckRollup

# Commits on this branch
git log main..<branch> --no-merges --oneline
```

**Status mapping:**

- `state=MERGED` → 🟢 **Merged**
- `state=CLOSED` → 🔴 **Closed**
- `isDraft=true` → ⚪ **Draft**
- `reviewDecision=CHANGES_REQUESTED` → 🟠 **Changes Requested**
- `reviewDecision=APPROVED` + CI passing → 🟢 **Ready to Merge**
- `reviewDecision=REVIEW_REQUIRED` → 🟡 **Ready for Review**

**For each PR, write:**

- **What**: 1-2 sentence business impact (not technical details)
- **Status**: From mapping above
- **Next**: What happens next?

**Writing style:**

- Lead with impact, not implementation
- No jargon - your manager should understand it
- Bad: "Added a migration to store plaid balances"
- Good: "Creators can now see their real bank balance when setting up payouts"

Write to `~/devmaxxing/standup/YYYY-MM-DD.md`

### 5. Save PR Feedback

For each PR with human review comments:

```bash
# General reviews
gh pr view <number> --json reviews,comments

# Inline code comments
gh api repos/{owner}/{repo}/pulls/<number>/comments
```

**Filter to human reviewers only** (ignore bots: vercel, linear, github-actions, sentry, cursor, seer)

For each human comment, extract and analyze:

- Reviewer name
- File path and line numbers (if inline)
- Comment text
- **Intention**: What is the reviewer really asking for?
- **Category**: Style | Logic | Performance | Security | Testing | Naming | Architecture
- **Lesson**: What general principle can you learn?

Write to `~/devmaxxing/reviews/daily/YYYY-MM-DD.md`

### 6. Append to Feedback History

Also append each comment to the persistent history file `~/devmaxxing/reviews/history.md`.

**Format for history file:**

```markdown
## YYYY-MM-DD

### PR #123 - PR Title
**From**: reviewer
**Category**: Architecture
**File**: path/to/file.rb:42

> "The actual comment text"

**Lesson**: What you learned from this feedback.

---
```

**Rules:**
- Only append NEW comments (check if PR # + reviewer + comment already exists)
- Add a date header if this is the first entry for that date
- Keep chronological order (newest at bottom)

### 7. Generate Trivia Questions

For each PR, analyze the code changes to generate trivia questions about Whop's business systems.

**Read the actual code files touched:**

```bash
# Get files changed in PR
gh pr view <number> --json files --jq '.files[].path'

# Read key files (services, workers, models)
```

**Generate questions about:**

1. **Constants & Thresholds**: Magic numbers, limits, rates
   - "What's the GMV threshold for X?" → "$500,000"
   - "What fee percentage does Y charge?" → "2.5%"

2. **Business Logic**: What systems do and why
   - "What happens when a company graduates from the accelerator program?"
   - "Which worker handles X?"

3. **System Relationships**: How things connect
   - "What service does X call to do Y?"
   - "What feature flag controls Z?"

4. **Domain Knowledge**: Business concepts
   - "What's the difference between X and Y?"
   - "When does Z get triggered?"

**Question quality rules:**
- Questions should test understanding, not memorization of syntax
- Answers should be concise (1-2 sentences max)
- Focus on "why" and "what" over "how"
- Tie to business impact when possible

**Save to `~/devmaxxing/trivia/questions.json`:**

```json
{
  "questions": [
    {
      "id": "uuid",
      "question": "What's the GMV threshold for accelerator program graduation?",
      "answer": "$500,000 - after this, companies pay 2.5% card fees instead of 0%",
      "system": "accelerator_program",
      "source_pr": "PR #612",
      "source_file": "backend/app/services/accelerator_program/graduate.rb",
      "added_date": "2026-01-07",
      "times_asked": 0,
      "times_correct": 0
    }
  ]
}
```

**Rules:**
- Generate 2-5 questions per PR (quality over quantity)
- Don't duplicate existing questions (check by similarity)
- Skip trivial changes (typos, formatting, deps)
- Focus on business logic, not boilerplate

### 8. Send Email Digest (if configured)

Read config from `~/.claude/skills/end-day/config.json`. If `resend_api_key` is empty, skip email.

```json
{
  "resend_api_key": "re_xxx",
  "email_to": "you@email.com",
  "email_from": "onboarding@resend.dev"
}
```

Send email via Resend API:

```bash
curl -X POST 'https://api.resend.com/emails' \
  -H 'Authorization: Bearer <resend_api_key>' \
  -H 'Content-Type: application/json' \
  -d '{
    "from": "<email_from>",
    "to": "<email_to>",
    "subject": "🌙 End of Day: YYYY-MM-DD",
    "html": "<email_content>"
  }'
```

**Email style:**

- Use emojis liberally (🌙 🟢 🟡 🟠 🔴 💬 💡 ⏳ 📝)
- Casual, easy-to-read tone
- Status colors: 🟢 Merged, 🟡 Ready for Review, 🟠 Changes Requested, 🔴 Closed
- Card-style layout with rounded backgrounds for each PR
- Quote blocks for reviewer comments
- "💡 Takeaway:" for lessons learned

**Email structure:**

```text
🌙 End of Day: [Day of week], [Date]

📋 What I worked on (N PRs)
  - [emoji] PR Title
    Status: ...
    [casual 1-2 sentence summary]
    [next step indicator]

💬 Feedback I got (N comments)
  - [reviewer] on PR #X
    "[quoted comment]"
    💡 Takeaway: [lesson]
```

### 9. Report Summary

Print to terminal:

```text
End of day complete for YYYY-MM-DD

Standup:
  - N PRs summarized
  - Saved to ~/devmaxxing/standup/YYYY-MM-DD.md

Feedback:
  - N human comments saved
  - Saved to ~/devmaxxing/reviews/daily/YYYY-MM-DD.md
  - Appended N new comments to ~/devmaxxing/reviews/history.md

Trivia:
  - N new questions generated
  - Total questions in bank: M
  - Saved to ~/devmaxxing/trivia/questions.json

Email sent to you@email.com ✓
```
