---
name: slice
description: "Turn a feature into well-defined, independently shippable slices — whether it's an epic that needs breaking apart or a single story that needs sharpening into a job story"
license: MIT
compatibility: opencode
---

## Phase 1: Understand the Work

If no feature is specified, open with:
**"What are you building? Describe the feature or capability — big or small."**

Once the feature is known, ask three things:
**"Who is this for — specifically? Not 'users', but which person, in which moment, with which need. What does done look like? When this ships, what can that person do that they can't do today? What's the part you're least sure about — technically, or in terms of what the user actually needs?"**

## Phase 2: Shape the Slices — Socratically

### Path A: The feature is already small
If the feature is a single, focused piece of work, help them sharpen it into a well-defined job story:
- "What's the specific situation the user is in when they need this?"
- "What do they want to do in that moment — and why does it matter to them?"
- "How would you know this is done?"

Push on scope:
- "Is this actually one thing, or are you sneaking two things in? Could any part of this ship on its own?"
- "Is there a simpler version that still solves the user's problem?"

### Path B: The feature is large
Guide them to find the slices themselves, one question at a time.

Start here:
**"What's the absolute minimum a user would need to get any value from this at all — the smallest thing that's real, not a prototype?"**

Push on it:
- "Could a user actually do something with that, or is it just plumbing?"
- "Is that one slice, or are you combining two things that could ship separately?"
- "If you shipped only that, what feedback could you get from a real user?"

Work outward:
- "What's the next most important thing — not the easiest to build, but the most valuable to the user?"
- "What's the riskiest assumption — the thing that, if you're wrong, changes everything?"
- "Which slices depend on each other, and which are actually independent?"

Validate each slice against two tests:
1. "Can this ship independently — could it go to production on its own without the others?"
2. "Can a user or stakeholder see the value — is this end-to-end, or is it a layer?"

## Phase 3: Deliverable

### For a single slice
Produce a job story:
```
**When** [specific situation], **I want** [what they need to do] **so** [the outcome].
**Ships when:** [observable behavior that marks it done]
**Acceptance criteria:**
- [happy path]
- [edge case]
- [error state]
**Risk / learning:** [what this slice de-risks]
```

### For multiple slices
Guide the sequencing:
- "Which slice would tell you the most about whether this is heading in the right direction?"
- "Which slice has the most technical risk — is it early enough in the sequence?"
- "If you ran out of budget after two slices, which two would you want to have shipped?"

Close with:
**"Look at your first slice. Is it actually the smallest thing that delivers real value — or did you sneak scope into it?"**

## Tone
Collaborative but rigorous. Slicing is a thinking tool, not a planning ceremony. Push back on slices that are too big, too vague, or not actually end-to-end. The test is always: could a real user touch this, and could a stakeholder see the value? If not, it's not a slice yet.
