---
name: linear-workflow
description: Structured workflow for Linear tasks - gather context, interview, specs, then implement
---

# Linear Workflow

Structured process for working on Linear tasks. **Never jump to implementation.**

## Usage

- `/linear-workflow <LINEAR-URL>` - Start workflow for a Linear task
- `/linear-workflow PAY-123` - Start workflow with ticket ID

## Phase 1: Gather Context (Current Phase)

**Goal:** Understand the task completely before any implementation.

### 1.1 Fetch Linear Issue

```bash
# If given a URL, fetch it
# If given an ID like PAY-123, construct: https://linear.app/whop/issue/PAY-123
```

Extract from the issue:
- Title and description
- Acceptance criteria
- Labels and priority
- Related issues/PRs
- Comments and discussion

### 1.2 Explore Codebase

Search for relevant code:
- Related files and modules
- Existing patterns to follow
- Dependencies and integrations
- Similar past implementations

### 1.3 Summarize Findings

Present a summary:

```
## Task Summary

**Issue:** PAY-123 - <title>
**Priority:** <priority>

### Description
<summarized description>

### Relevant Code Found
- `path/to/file.rb` - <why relevant>
- `path/to/component.tsx` - <why relevant>

### Open Questions
- <questions that need clarification>

### Initial Scope Estimate
- Backend: <small/medium/large>
- Frontend: <small/medium/large>
```

### 1.4 STOP AND WAIT

**Do NOT proceed to implementation.** Say:

```
Context gathered. Ready for next phase.

When ready:
- Run `/interview` to begin spec generation
- Or ask me questions about the codebase
```

---

## Phase 2: Interview (User Triggered)

**Trigger:** User runs `/interview`

This phase uses the interview command to ask probing questions about:
- Technical implementation details
- UI/UX requirements
- Edge cases and failure modes
- Scope boundaries
- Integration points

---

## Phase 3: Generate Specs

After interview, generate three specs:

### 3.1 Product Spec (→ Bowen)

```markdown
## Product Spec: <Feature Name>

### Problem
<What problem are we solving?>

### Solution
<High-level solution description>

### User Stories
- As a <user type>, I want <action> so that <benefit>

### Acceptance Criteria
- [ ] <criterion 1>
- [ ] <criterion 2>

### Out of Scope
- <what we're NOT doing>

### Success Metrics
- <how we measure success>
```

### 3.2 Tech Spec - Backend (→ Jackson or Tristan)

```markdown
## Tech Spec (Backend): <Feature Name>

### Overview
<Technical summary>

### Database Changes
- Migrations needed
- New models/columns

### API Changes
- New GraphQL queries/mutations
- Modified endpoints

### Business Logic
- Service objects
- Workers/jobs

### Testing Plan
- Unit tests
- Integration tests

### Rollout Plan
- Feature flags
- Migration strategy
```

### 3.3 Tech Spec - Frontend (→ Jackson or Tristan)

```markdown
## Tech Spec (Frontend): <Feature Name>

### Overview
<Technical summary>

### Components
- New components needed
- Modified components

### State Management
- New queries/mutations
- Local state changes

### Routes
- New pages
- Modified routes

### Testing Plan
- Component tests
- E2E scenarios
```

### 3.4 Request Approval

```
Specs generated. Please review:

1. **Product Spec** → Bowen for approval
2. **Tech Spec (Backend)** → Jackson or Tristan for approval
3. **Tech Spec (Frontend)** → Jackson or Tristan for approval

Waiting for spec approval before implementation.
```

---

## Phase 4: Implementation

**Only after specs are approved.**

1. Create branch following naming convention
2. Implement according to approved specs
3. Run `/checklist-manifesto` before PR
4. Create PR with `/push-pr`

---

## Quick Reference

| Phase | Trigger | Output | Next Step |
|-------|---------|--------|-----------|
| 1. Context | `/linear-workflow` | Summary | Wait for user |
| 2. Interview | `/interview` | Detailed requirements | Generate specs |
| 3. Specs | Auto after interview | 3 spec documents | Get approval |
| 4. Implement | After approval | Working code + PR | Done |

## Rules

1. **Never skip phases** - Each phase gates the next
2. **Never implement without specs** - Specs must be approved first
3. **Always wait for user** - Don't auto-proceed between phases
4. **Ask questions freely** - Better to clarify than assume
