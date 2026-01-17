---
name: trivia
description: Quiz yourself on Whop's business systems from your own PR history
---

# Trivia

Test your knowledge of Whop's codebase with questions generated from your PR history.

## Usage

- `/trivia` - Random question from the bank
- `/trivia stats` - Show your score and streaks
- `/trivia [system]` - Question from specific system (e.g., `/trivia payments`)

## Steps

### 1. Load Question Bank

Read questions from `~/devmaxxing/trivia/questions.json`.

If the file doesn't exist or is empty, tell the user:
```
No trivia questions yet! Run /end-day after working on some PRs to generate questions.
```

### 2. Select a Question

**Default mode (`/trivia`):**
- Pick a random question, weighted towards:
  - Questions asked fewer times (prioritize fresh questions)
  - Questions answered incorrectly (reinforce learning)

**System filter (`/trivia [system]`):**
- Filter to questions matching that system
- If no matches, suggest available systems

**Stats mode (`/trivia stats`):**
- Skip to step 5

### 3. Ask the Question

Present the question clearly:

```
🎯 Trivia Time!

System: accelerator_program
Source: PR #612

Q: What's the GMV threshold for accelerator program graduation?

Take a moment to think, then say "ready" or type your answer.
```

### 4. Reveal Answer & Score

After user responds:

```
📝 Answer:
$500,000 - after this, companies pay 2.5% card fees instead of 0%

Source: backend/app/services/accelerator_program/graduate.rb
```

Then ask: "Did you get it right? (y/n)"

**Update stats in questions.json:**
- Increment `times_asked`
- If correct, increment `times_correct`

**Give encouraging feedback:**
- Correct: "Nice! 🎉 You've gotten this right X/Y times."
- Incorrect: "No worries! This one's tricky. You'll get it next time."

### 5. Show Stats (for `/trivia stats`)

```
📊 Your Trivia Stats

Total questions in bank: 47
Questions answered: 32
Accuracy: 78%

By system:
  payments:           12 questions, 83% accuracy
  accelerator_program: 5 questions, 60% accuracy
  checkout:            8 questions, 75% accuracy
  ledger:              7 questions, 86% accuracy

🔥 Current streak: 5 correct in a row
🏆 Best streak: 12

Tip: Run /trivia payments to focus on a specific area.
```

### 6. Offer Next Action

```
What next?
- "again" or "a" - Another question
- "stats" or "s" - See your stats
- "quit" or "q" - Done for now
```

## Question Bank Format

Located at `~/devmaxxing/trivia/questions.json`:

```json
{
  "questions": [
    {
      "id": "unique-id",
      "question": "The question text",
      "answer": "The answer with context",
      "system": "system_name",
      "source_pr": "PR #123",
      "source_file": "path/to/file.rb",
      "added_date": "2026-01-07",
      "times_asked": 5,
      "times_correct": 4
    }
  ],
  "stats": {
    "current_streak": 5,
    "best_streak": 12,
    "last_played": "2026-01-07"
  }
}
```

## Available Systems

Common systems you might see:
- `payments` - Payment processing, Stripe, fees
- `checkout` - Checkout flow, sessions
- `ledger` - Ledger accounts, balances, transactions
- `accelerator_program` - Fee waivers, graduation
- `memberships` - User memberships, access
- `webhooks` - Webhook handlers
- `graphql` - API layer
- `workers` - Background jobs
