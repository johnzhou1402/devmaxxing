---
name: push
description: Run quality checks then push to current branch
---

# Push

Run mandatory quality checks before pushing to the current branch. This skill ensures specs pass and code is linted before any push.

## Usage

- `/push` - Run checks and push current branch to origin
- `/push --force` - Run checks and force push (for after rebase)

## Steps

### 1. Verify Branch

```bash
# Get current branch
git rev-parse --abbrev-ref HEAD
```

**Block if on main/master** - must be on a feature branch.

### 2. Check for Uncommitted Changes

```bash
git status --short
```

If there are staged or unstaged changes, warn the user:
> "You have uncommitted changes. Commit them first or they won't be pushed."

### 3. Get Changed Files (vs main)

```bash
# Files changed in this branch compared to main
git diff --name-only main...HEAD
```

### 4. Run Rubocop on Changed Backend Files (MANDATORY)

```bash
# Filter for ruby files
git diff --name-only main...HEAD | grep -E '\.rb$' | xargs bin/rubocop -A
```

- **Cannot skip this step**
- Must show 0 offenses before proceeding
- If offenses remain after auto-fix, stop and report them

### 5. Run Frontend Lint on Changed Frontend Files (MANDATORY)

If any files in `frontend/` are changed:

```bash
cd frontend/apps/core && pnpm lint
```

This runs both OxLint and ESLint on the frontend codebase.

- **Cannot skip this step** when frontend files are changed
- Must show 0 errors before proceeding
- Warnings are acceptable, errors are not

### 6. Run Specs for Changed Files (MANDATORY)

```bash
bin/test-changes
```

This runs specs related to changed files.

- **Cannot skip this step**
- If any specs fail, stop and report failures
- Do NOT proceed to push if specs fail

### 7. Run Type Convention Check (if applicable)

If changes include GraphQL types, enums, or migrations:

```bash
# Run the check-type-conventions skill
```

### 8. Push to Origin

Only after all checks pass:

```bash
# Normal push
git push origin <current-branch>

# Or with --force flag
git push --force-with-lease origin <current-branch>
```

### 9. Report Results

```
## Push Results

Branch: john/wpn-onboarding
Remote: origin

### Quality Checks
✅ Rubocop: 0 offenses
✅ Frontend lint: 0 errors
✅ Specs: 34 passed, 0 failed
✅ Type conventions: All valid

### Push
✅ Pushed successfully to origin/john/wpn-onboarding

Commit: abc123f "Your commit message"
```

Or if checks fail:

```
## Push Blocked

### Quality Checks
✅ Rubocop: 0 offenses
❌ Frontend lint: 1 error

### Failures
app/.../sign-in/page.tsx:50
  - eslint(no-empty): Unexpected empty block statements

### Next Steps
1. Fix the failing lint errors
2. Run `/push` again
```

## Quick Reference

| Step | Command | Can Skip? |
|------|---------|-----------|
| Check branch | `git rev-parse --abbrev-ref HEAD` | No |
| Rubocop | `bin/rubocop -A` | **NEVER** |
| Frontend lint | `cd frontend/apps/core && pnpm lint` | **NEVER** (if frontend changed) |
| Specs | `bin/test-changes` | **NEVER** |
| Type check | `/check-type-conventions` | Auto (if applicable) |
| Push | `git push origin <branch>` | No |

## Important Rules

1. **NEVER push without running specs** - This is the whole point of this skill
2. **NEVER skip rubocop** - Backend code must be linted
3. **NEVER skip frontend lint** - Frontend code must pass OxLint and ESLint
4. **Report failures clearly** - Show exactly what failed and why
5. **Block on any failure** - Do not push if any check fails
