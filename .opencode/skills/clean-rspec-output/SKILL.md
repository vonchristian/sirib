---
name: clean-rspec-output
description: "Systematically eliminate unexpected output (warnings, stray puts/logs, deprecation notices) from a Ruby on Rails RSpec test suite, one issue at a time, with per-fix verification and commits"
license: MIT
compatibility: opencode
---

# Clean Up Unexpected RSpec Output

A procedural workflow for identifying and eliminating unexpected output from a Rails RSpec suite, one issue at a time, verifying each fix in isolation and committing as you go.

## When to use this

The user has an RSpec suite that produces unexpected output during test runs. This is typically a mix of:
- Ruby warnings (e.g. `warning: already initialized constant`, `warning: method redefined`)
- Gem deprecation notices
- Stray `puts`, `p`, `pp`, or `Rails.logger` calls left in application or test code
- ActiveRecord or ActionView deprecation warnings
- Output from third-party libraries that should be silenced in the test environment

## Before you start

Ask the user which git branch this work should happen on. Explain why: the skill iterates through each unexpected output one at a time and creates a separate commit per fix, so that individual fixes can be reviewed or cherry-picked independently. If the user has told you to ignore specific output patterns, note them.

## Fix scope: what counts as a fix

Fixes may change **how** a test runs. Fixes must not change **what** it covers.

A fix preserves every one of these:
- The assertions (`expect(...)` calls, their matchers, and the values passed to them)
- The branches the test exercises
- The setup data that drives those branches

### Changes to tests that ARE legitimate
- Updating a deprecated RSpec API while preserving assertion semantics
- Updating setup that uses a deprecated framework API, assertions untouched
- Replacing an inline `puts`/`pp` that was never load-bearing with nothing

### Anti-pattern: simplifying a test until the noise stops
If a branch produces noise because the test data is incomplete, do not delete the branches. The branches are the coverage. Trace the noise to its source (application code, a view helper, a gem), fix it there, and leave the assertions intact.

## The workflow

### 1. Capture the full output
Run the full suite in default format to capture unexpected output:
```bash
bundle exec rspec 2>&1 | tee tmp/rspec-output.log
```
Then run a second time with documentation format to locate source tests:
```bash
bundle exec rspec --format documentation 2>&1 | tee tmp/rspec-output-doc.log
```
Do not run these in parallel — they share the test database.

### 2. Scan for unexpected output
Read the plain log and identify each distinct unexpected output. Group by likely root cause where possible. Skip any user-flagged ignore patterns.

### 3. For each issue, follow the verification loop
1. **Locate the source test** — use the documentation log. Grep for the exact line of stray output, then read surrounding lines to find the preceding test description.
2. **Reproduce in isolation (hard gate)** — run just that one test. You must see the unexpected output before you can propose any fix. If you cannot reproduce with a scoped command, stop and tell the user.
3. **Categorize and fix**:
   - **Warnings**: resolve the underlying cause. Suppressing is a last resort.
   - **Stray puts/p/pp**: delete it (it was debugging left-over). If intentional, flag to the user.
   - **Third-party output**: silence at the test configuration level, scoped narrowly.
4. **Verify the fix** — re-run the isolated test. Confirm output is gone.
5. **Check the diff** — does this change only *how* the test runs, or *what* it covers?
6. **Commit** — one fix per commit. Use this format:
   ```
   Title line explaining what changed

   Before, [current state context and the problem].
   Now, [what changed and the impact].
   ```

### 4. Final verification
Re-run the full suite and confirm output is clean. Stop when done.

## What this skill does not do
- It does not address test failures, only unexpected output from passing tests.
- It does not rewrite the suite for speed or structure.
- It does not add new tests, only fixes noise in existing ones.
