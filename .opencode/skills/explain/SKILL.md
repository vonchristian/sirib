---
name: explain
description: "Explain what a piece of code does — a specific file, class, or method in close detail, or a user-facing flow as a concise system overview"
license: MIT
compatibility: opencode
---

Determine the mode from the argument:
- **If the argument is a file path, class name, or method** — this is a **code explanation**. Follow the Code Explanation section.
- **If the argument is a user action, feature, or flow description** — this is a **flow explanation**. Follow the Flow Explanation section.

## Code Explanation

Start by checking the git history for the file: `git log --oneline -15 <file>` and `git log -1 -p <file>` for the most recent change. Commit messages often reveal the "why" that the code itself doesn't — a bug that was fixed, a refactor that simplified something, a workaround for an external constraint. Note anything that reframes the code before diving into it.

Then read the code carefully and explain in this order:

### 1. What it does — in one paragraph
Plain English. No jargon, no code. Describe what this code accomplishes from the outside — what goes in, what comes out, what changes as a result.

### 2. How it does it — walking through the logic
Narrate the code path in plain English, step by step. For each meaningful chunk:
- What is this step doing?
- Why is it doing it here, in this order?
- What would break if it wasn't here?

Don't narrate every line — skip the obvious. Focus on the parts that require interpretation.

### 3. Patterns and conventions in use
Name the Rails, Ruby, or design patterns this code is using — and why they appear here. Examples:
- "This is a service object following the thoughtbot pattern — one public `call` method, one responsibility"
- "This is using `delegate` to avoid Law of Demeter violations"
- "This callback is doing what's normally done in a service object — worth noting"

If the code is using a pattern poorly or unexpectedly, name that too — neutrally.

### 4. What to watch out for
Any non-obvious behaviour, implicit dependencies, or things that would surprise someone maintaining this code. Not a critique — just "here's what you'd need to know to work safely in this area."

## Flow Explanation

Start with the Rails router. Locate the route(s) that correspond to the described flow. From each entry point, trace the execution path through the codebase — controllers, service objects, models, callbacks, jobs, mailers. Follow both success and failure paths.

Then deliver: a **diagram** and a **summary**.

### 1. Diagram
Render a concise visual flowchart using box-drawing characters (`┌─┐`, `│`, `├──`, `└──`, `▼`). Show:
- **States and transitions** — the lifecycle, not method calls
- **Decision points** — where the flow branches
- **Key actions** — described in plain English
- **Terminal states** — where the flow ends

### 2. Summary
**Entry points** — every way this flow can be triggered.
**Branching logic** — conditions that shape the flow (feature flags, state checks, validations).
**Side effects** — everything with consequences outside the immediate flow (jobs, mailers, API calls, broadcasts, cache writes).

## Tone
Clear and direct. You're translating, not teaching and not judging. The goal is that they finish with a working mental model of what this code does and how to navigate it.
