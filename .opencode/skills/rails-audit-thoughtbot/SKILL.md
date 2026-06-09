---
name: rails-audit-thoughtbot
description: "Perform comprehensive code audits of Ruby on Rails applications based on thoughtbot best practices — covering testing, security, code design, database, and performance"
license: MIT
compatibility: opencode
---

# Rails Audit Skill (thoughtbot Best Practices)

Perform comprehensive Ruby on Rails application audits based on thoughtbot's Ruby Science and Testing Rails best practices, with emphasis on Plain Old Ruby Objects (POROs) over Service Objects.

## Audit Scope

The audit can be run in two modes:
1. **Full Application Audit**: Analyze entire Rails application
2. **Targeted Audit**: Analyze specific files or directories

## Execution Flow

### Step 1: Determine Audit Scope
Ask user or infer from request:
- Full audit: Analyze all of `app/`, `spec/` or `test/`, `config/`, `db/`, `lib/`
- Targeted audit: Analyze specified paths only

### Step 2: Collect Optional Metrics (SimpleCov + RubyCritic)
Ask the user both questions upfront: whether to run SimpleCov (test coverage) and RubyCritic (code quality). Both are recommended.

If accepted, spawn subagents in parallel using the Task tool with the instructions in `agents/simplecov_agent.md` and `agents/rubycritic_agent.md`.

After both finish, clean up: `rm -rf coverage/` and `rm -rf tmp/rubycritic/`.

### Step 3: Load Reference Materials
Before analyzing, read the relevant files from `references/`:
- `code_smells.md` - Code smell patterns to identify
- `testing_guidelines.md` - Testing best practices
- `poro_patterns.md` - PORO and ActiveModel patterns
- `security_checklist.md` - Security vulnerability patterns
- `rails_antipatterns.md` - Rails-specific antipatterns

### Step 4: Analyze Code by Category
Analyze in this order:
1. **Testing Coverage & Quality** — missing test files, untested methods, test structure
2. **Security Vulnerabilities** — SQL injection, mass assignment, XSS, auth issues
3. **Models & Database** — fat models, N+1 queries, callback complexity, Law of Demeter
4. **Controllers** — fat controllers, business logic in controllers, REST violations
5. **Code Design & Architecture** — service objects → PORO refactoring, large classes, long methods, feature envy
6. **Views & Presenters** — logic in views, missing partials, helper complexity
7. **External Services & Error Handling** — fire and forget, missing timeouts, bare rescue
8. **Database & Migrations** — missing indexes, messy migrations, Ruby vs SQL iteration

### Step 5: Generate Audit Report
Save to `RAILS_AUDIT_REPORT.md` in project root using the template at `references/report_template.md`.

## Severity Definitions
- **Critical**: Security vulnerabilities, data loss risks, production-breaking issues
- **High**: Performance issues, missing tests for critical paths, major code smells
- **Medium**: Code smells, convention violations, maintainability concerns
- **Low**: Style issues, minor improvements, suggestions

## Key Detection Patterns

### Service Object → PORO Refactoring
When you find classes in `app/services/`:
- Classes named `*Service`, `*Manager`, `*Handler`
- Classes with only `.call` or `.perform` methods
- Recommend: Rename to domain nouns, include `ActiveModel::Model`

### Fat Model Detection
Models with: more than 200 lines, more than 15 public methods, multiple unrelated responsibilities.
Recommend: Extract to POROs using composition.

### Fat Controller Detection
Controllers with: actions over 15 lines, business logic, multiple instance variable assignments.
Recommend: Extract to form objects or domain models.

### Missing Test Detection
For each Ruby file in `app/`, check for corresponding `_spec.rb` or `_test.rb`, check for tested public methods.

## Analysis Commands
Use Glob, Grep, and Read tools. Do not use Bash for file searching.

## Report Output
Always save the audit report to `RAILS_AUDIT_REPORT.md` in the project root and present it to the user.
