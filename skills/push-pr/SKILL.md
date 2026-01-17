---
name: push-pr
description: Create PR with quality checks, fresh branch off main, and proper formatting
---

# Push PR

Create a pull request with mandatory quality checks, proper branch hygiene, and formatted description. Never skip the checklist.

## Usage

- `/push-pr` - Push current changes as a new PR (will use Linear URL from task context if available)
- `/push-pr PAY-123` - Include Linear ticket reference (will fetch full URL from Linear)

## Steps

### 1. Stash Current Changes

```bash
# Save current work
git stash push -m "push-pr-temp"
```

### 2. Create Fresh Branch Off Main

```bash
# Ensure we're on latest main
git checkout main
git pull origin main

# Create new branch with naming convention
git checkout -b <github-username>/<short-description>
```

**Branch naming rules:**
- Format: `<github-username>/<short-kebab-case-description>`
- Example: `john/fix-connected-companies-volume`
- Max 50 chars for description part

### 3. Apply Changes

```bash
# Pop the stashed changes
git stash pop
```

### 4. Review and Stage Files (IMPORTANT)

**Before staging, check what's changed:**
```bash
git status
```

**Exclude these files - NEVER commit them:**
- `.claude/settings.local.json` - local Claude settings
- `*.local.json` - any local config
- `.env*` - environment files
- `.vercel/project.json` - Vercel local config

**If any of these are staged, unstage them:**
```bash
git reset HEAD <path-to-file>
```

**Stage only relevant files:**
```bash
git add <relevant-files>
```

**Verify before proceeding:**
```bash
git diff --cached --name-only
```
Review this list - every file should be intentionally part of the PR.

### 5. Run Rubocop (MANDATORY - if backend files changed)

**Run rubocop on all changed files and fix ALL offenses:**
```bash
bin/rubocop -A <changed-files>
```

- The `-A` flag auto-corrects what it can
- For remaining offenses, fix them manually
- **Do not proceed until rubocop shows 0 offenses**

### 6. Run Frontend Lint (MANDATORY - if frontend files changed)

**Run lint on the frontend codebase:**
```bash
cd frontend/apps/core && pnpm lint
```

This runs both OxLint and ESLint on the frontend codebase.

- **Do not proceed until lint shows 0 errors**
- Warnings are acceptable, errors are not
- Fix any errors before continuing

### 7. Run Checklist Manifesto (MANDATORY)

**This step cannot be skipped.** Run `/checklist-manifesto` to verify:

- Type consistency (GraphQL ↔ DB columns)
- Sortable columns match
- Schema is regenerated
- Specs updated
- Frontend compiles
- CSV exports consistent

**If any check fails:**
1. Fix the issues
2. Re-run checklist
3. Only proceed when all checks pass

### 8. Commit Changes

```bash
git commit -m "$(cat <<'EOF'
<Concise description of change>

<Optional: 1-2 sentence explanation of why>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

**Commit message rules:**
- First line: imperative mood, max 72 chars
- Focus on WHAT and WHY, not HOW
- No period at end of first line

### 9. Push Branch

```bash
git push -u origin <branch-name>
```

### 10. Create PR

```bash
gh pr create --title "<PR title>" --body "$(cat <<'EOF'
### Why did you do this?
<Brief explanation of the problem/motivation>

### What changed?
<Bulleted list of changes>

### Additional notes
<Screenshots, test commands, or other context>

---

## Internal Docs Changelog
<use ai>

---

Fixes https://linear.app/whop/issue/<LINEAR-ID>/<issue-slug>
EOF
)"
```

**Linear ticket rules:**
- Always use full Linear URL with "Fixes" prefix
- Get the full URL from the Linear issue (includes issue slug)
- Example: `Fixes https://linear.app/whop/issue/PAY-510/add-created-at-to-payout-method-api`
- This auto-closes the Linear issue when the PR is merged

**PR title rules:**
- Same as commit first line
- Focus on business impact, not technical details
- Bad: "Update company_type.rb to add field"
- Good: "Fix connected companies volume to include transfers"

### 11. Report Result

```
PR Created Successfully
=======================

Branch: john/fix-connected-companies-volume
PR: https://github.com/whopio/whop-monorepo/pull/XXX

Checklist Results:
[PASS] All 6 checks passed

Next steps:
- Wait for CI to pass
- Request review if needed
```

## Quick Reference

| Step | Command | Can Skip? |
|------|---------|-----------|
| Stash | `git stash` | No |
| Fresh branch | `git checkout main && git pull` | No |
| Review files | `git status && git diff --cached --name-only` | **NEVER** |
| Rubocop | `bin/rubocop -A <files>` | **NEVER** (if backend) |
| Frontend lint | `cd frontend/apps/core && pnpm lint` | **NEVER** (if frontend) |
| Checklist | `/checklist-manifesto` | **NEVER** |
| Commit | `git commit` | No |
| Push | `git push -u origin` | No |
| Create PR | `gh pr create` | No |

## Common Issues

**"I already committed on this branch"**
- That's fine, we'll cherry-pick to a fresh branch off main

**"Checklist found issues"**
- Fix them. No exceptions. This is why the checklist exists.

**"I need to push urgently"**
- The checklist takes 30 seconds. Bugs in prod take hours. Run the checklist.
