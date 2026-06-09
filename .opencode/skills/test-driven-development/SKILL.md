---
name: test-driven-development
description: "Strict red-green-refactor TDD workflow for implementing features, fixing bugs, or changing behavior in Rails applications"
license: MIT
compatibility: opencode
---

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## The Iron Law
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```
Write code before the test? Delete it. Start over. No exceptions.

## Outside-In Development

Start every feature with a high-level test that describes behavior from the user's perspective. Let each failure guide what to build next. Drop to unit tests when you encounter non-trivial logic.

### The Outer Loop: Feature Specs
1. Take the user story
2. Write a feature spec describing the behavior end-to-end
3. Run it — watch it fail
4. The error tells you what to build next: a route, a controller action, a view, a model method
5. Build the minimum to get past that error
6. Run again — next error drives next piece
7. When you hit non-trivial logic, drop to the inner loop

Feature specs use real database records. No mocks — except for external services.

### The Inner Loop: Unit Tests
When the feature spec error points to logic that needs its own proof — a search method, a calculation, a validation rule:
1. Write a unit test for that specific behavior
2. Follow Red-Green-Refactor (below)
3. Pass the unit test
4. Return to the feature spec

Unit tests isolate the object under test. Mock collaborators aggressively.

## Red-Green-Refactor

### RED — Write Failing Test
Write one minimal test showing what should happen.
- One behavior
- Clear name
- Feature specs: real records, no mocks (except external services)
- Unit tests: mock collaborators, test the object in isolation

### Verify RED — Watch It Fail
**MANDATORY. Never skip.**
Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

### GREEN — Minimal Code
Write simplest code to pass the test.
Don't add features, refactor other code, or "improve" beyond the test.

### Verify GREEN — Watch It Pass
**MANDATORY.**
Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

### REFACTOR — Clean Up
After green only:
- Remove duplication
- Improve names
- Extract helpers

Keep tests green. Don't add behavior.

### Repeat
Return to the feature spec. Next error drives the next piece.

## Good Tests
| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `it "validates email and domain and whitespace"` |
| **Clear** | Name describes behavior | `it "test1"` |
| **Shows intent** | Demonstrates desired API | Obscures what code should do |

## Verification Checklist
- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

## When Stuck
| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |

## Debugging Integration
Bug found? Write failing test reproducing it. Follow TDD cycle. Test proves fix and prevents regression.

## Final Rule
```
Production code → test exists and failed first
Otherwise → not TDD
```
