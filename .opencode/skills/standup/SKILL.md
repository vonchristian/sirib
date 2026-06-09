---
name: standup
description: "Write a client update — identify what was done, what's next, and surface risks before they become surprises"
license: MIT
compatibility: opencode
---

## Behavior

This is a guided conversation that ends with a polished, ready-to-send update. Start by getting the raw material from the user — then help them sharpen it.

### Step 1: Gather
Check git for context:
- `git log --since="yesterday" --author=$(git config user.email)`
- Check for open branches, uncommitted work, open PRs

Then open with:
**"Here's what I can see from git. Before I help you write this — what did you actually spend your time on? Git doesn't always tell the full story."**

Then ask:
**"What's the most important thing the client should know from today — if they read one sentence and nothing else?"**

Then:
**"Is there anything the client needs to decide, unblock, or be aware of before your next working session?"**

### Step 2: Sharpen — Socratically
Before writing, push on what they've said:

**On completeness:**
- "You mentioned [X] — is that done-done, or is there a loose end?"
- "Is there anything you learned today that changes the plan or the estimate?"

**On risks — push hard:**
- "Is there a risk here you're not mentioning because you think you can handle it?"
- "If the client asked 'are we on track?' right now — what's your honest answer?"
- "Are you going to hit the next deadline? If there's any doubt, say it now."
- "Is there anything that took longer than expected? Does that change the timeline?"
- "Are there areas you shipped without full test coverage?"
- "What would fall through the cracks if you got hit by a bus tomorrow?"

**On team communication:**
- "Is there something here you need to raise with your team before this goes to the client?"
- "Did anything come up today that a teammate needs to know about?"

### Step 3: Write the Update
Produce a clean, ready-to-send update. Keep it short:

```
**Update: [Date]**

**Done:**
- [Completed items — outcomes, not tasks]

**In progress:**
- [What's actively being worked on]

**Up next:**
- [Planned for next session]

**Heads up:**
- [Risks, blockers, decisions needed — omit if nothing]
```

### Writing Principles
- **Outcomes over tasks** — "Users can now do X" beats "Implemented Y controller"
- **Honest over optimistic** — a small concern flagged early builds trust
- **Short over thorough** — respect the client's time
- **No jargon** — write for a smart person who doesn't know Rails
- **No filler** — "Continued working on..." is not an update

Close with:
**"Read it back — does it honestly reflect where things stand? Is there anything you softened that should be said more directly?"**

## Tone
Efficient and honest. This isn't a ceremony — it's a communication tool. Help them say what matters in as few words as possible, without hiding the uncomfortable parts.
