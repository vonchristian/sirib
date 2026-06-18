# AGENTS.md — Sirib Cooperative Banking System

## First Reads
- `docs/ai_instructions.md` — highest authority for AI behavior (overrides other docs)
- `docs/architecture.md` — DDD principles, aggregate boundaries, service-object-as-last-resort
- `docs/database_principles.md` — append-only financial events, never modify past entries
- `config/routes.rb` — the real API surface

## Dev Commands
| Action | Command |
|--------|---------|
| Run all tests | `bin/rails db:test:prepare && bin/rspec` |
| Run a single spec file | `bin/rspec spec/path/to/file_spec.rb` |
| Lint | `bin/rubocop` |
| Seed (full reset) | `bin/rails db:seed:replant` (truncates all tables) |
| Seed (append only) | `bin/rails db:seed` (skips existing records via `unless Model.exists?`) |
| Dev server | `bin/dev` (Rails + Tailwind watcher via Procfile.dev) |
| E2E tests | `npm run test:e2e` (Playwright, requires `bin/e2e-setup`) |
| Security scan | `bin/brakeman --no-pager` |
| JS dependency audit | `bin/importmap audit` |

## Architecture
- **Rails 8.0** (Ruby 4.0), PostgreSQL, Hotwire/Turbo/Stimulus, Tailwind CSS
- **Module namespaces**: `Accounting`, `Treasury`, `Lending`, `Equity`, `Management`
  - Each has own `app/models/<module>/`, `app/services/<module>/`, `app/controllers/<module>/`
- **Auth**: Custom `has_secure_password`, no Devise. `Current.user` via `Current.session.user`
- **Background**: Solid Queue, Solid Cache, Solid Cable
- **Deployment**: Kamal (Docker)
- **Trees**: `ancestry` gem on `Account` and `Branch`
- **Pagination**: `pagy ~> 9.0`
- **Service objects**: `active_interaction` gem (`run!` / `run` pattern)
- **Money**: `money-rails` gem. All balance computation is debits and credits. Calculated balances are stored in `RunningBalance` model.

## Database & Enum Quirks
- All enum columns are **`string` type** in the DB. Model `enum` declarations must use **string values**:
  ```ruby
  # CORRECT
  enum :status, { active: "active", inactive: "inactive" }
  # WRONG — column is string, integer mapping returns nil
  enum :status, { active: 0, inactive: 1 }
  ```
- If you change an enum from integer→string mapping, existing DB data (`"0"`, `"1"`) must be migrated via SQL.

## Management Module
- All controllers inherit from `Management::BaseController` (has `require_permission!` helper, `layout "dashboard"`)
- **Form partials for namespaced models**: Use `form_with model: variable`, NOT `[:management, variable]`. Rails infers the correct route from the model class (e.g., `Management::Policy` → `management_policy_path`).
- For non-namespaced models (like `User`), use `form_with model: [:management, @user]`.
- Demo seed only loads in development: `require_relative "seeds/demo_data" if ... !Rails.env.test?`
- All user login passwords in demo: `password123`
- **No management specs exist yet** (`spec/management/` does not exist)

## Pre-existing Test State
- 43+ pre-existing accounting spec failures (`spec/models/accounting/`, `spec/services/accounting/`) related to running balance computation — unrelated to new modules. See `spec/examples.txt` for current state.

## .opencode Skills Available
- `test-driven-development` — strict RSpec red-green-refactor workflow
- `thoughtbot-guides` — Rails conventions
- `clean-rspec-output` — eliminate unexpected test output
- `prior-art` — discover how codebase handles specific concerns
- Others: `explain`, `challenge`, `rubber-duck`, `socratic-review`, `slice`, `standup`, `hard-news`, `offboard`, `rails-audit-thoughtbot`

## Test Setup Quirks
- `config.use_transactional_fixtures = false` — uses DatabaseCleaner instead:
  - `before(:suite)`: truncation
  - `before(:each)`: transaction strategy (unless `js: true` → truncation)
- Factory files in `spec/factories/` — minimal, no business logic in factories
- `spec/support/` is currently empty
- System tests use Capybara + Selenium

---

# Implementation Standards

You are a senior Ruby on Rails 8 engineer responsible for delivering production-ready software.

Every feature request must be implemented completely. Do not stop after implementing the happy path.

## Technology Stack

- Ruby on Rails 8
- PostgreSQL
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- Playwright for End-to-End testing

---

# Deliverables

Unless explicitly stated otherwise, every feature must include:

- Database migrations
- Models
- Controllers
- Routes
- Services
- Policies/Authorization
- Views
- Turbo Streams
- Stimulus controllers (when appropriate)
- Background jobs (when needed)
- Mailers/Notifications (when needed)
- Audit logging (when applicable)
- Seed data (if useful)
- Documentation
- Refactoring where necessary

---

# Engineering Standards

The implementation should:

- Follow Rails conventions
- Follow Domain-Driven Design where appropriate
- Keep business logic out of controllers
- Keep models thin
- Prefer Service Objects for workflows
- Be modular and extensible
- Avoid duplicated code
- Be idempotent where applicable
- Handle concurrent requests safely
- Prevent race conditions
- Fail gracefully with meaningful error messages
- Be production-ready
- Be maintainable for future developers

---

# Playwright End-to-End Tests (Required)

Every feature MUST include comprehensive Playwright E2E tests.

Do not only test the happy path.

Cover all user journeys.

## Happy Paths

Test complete user workflows from beginning to end.

Examples include:

- Create
- Edit
- Delete
- View
- Search
- Filter
- Navigation
- Successful completion
- UI feedback
- Data persistence

---

## Validation Tests

Cover every validation including:

- Required fields
- Invalid input
- Duplicate values
- Maximum lengths
- Minimum values
- Invalid formats
- Business validation failures

---

## Business Rules

Test every business rule.

Verify:

- State transitions
- Calculations
- Permissions
- Visibility
- Posting logic
- Workflow restrictions
- Approval rules
- Feature-specific domain logic

---

## Authorization

Verify each user role can:

- Access allowed pages
- Cannot access restricted pages
- Cannot perform unauthorized actions

---

## Edge Cases

Include tests for:

- Empty states
- Duplicate submissions
- Double-clicking buttons
- Browser refresh
- Back button
- Forward button
- Multiple browser tabs
- Concurrent users
- Race conditions
- Large datasets
- Maximum values
- Expired sessions

---

## Error Handling

Verify:

- Record not found
- Validation failures
- Server errors
- Authorization failures
- Network interruptions where applicable
- Friendly error messages

---

## Hotwire Behavior

Verify:

- Turbo Frames
- Turbo Streams
- Inline updates
- Partial page refreshes
- Flash messages
- Modal behavior
- Loading indicators

---

## Accessibility

Verify:

- Keyboard navigation
- Focus management
- Accessible labels
- Screen-reader friendly forms
- Error announcements

---

## Regression Tests

Ensure existing workflows continue functioning.

Add tests where necessary to prevent regressions.

---

# Test Organization

Organize Playwright tests by feature.

Example:

tests/e2e/
    feature_name/
        happy_path.spec.ts
        validation.spec.ts
        permissions.spec.ts
        edge_cases.spec.ts
        regression.spec.ts

Reuse:

- Page Objects
- Fixtures
- Test helpers
- Authentication helpers
- Factory methods

Avoid duplicated test code.

---

# Code Quality

Before considering the implementation complete, verify:

- No TODO comments
- No placeholder code
- No dead code
- No duplicated logic
- No N+1 queries
- Proper database indexes
- Strong parameter validation
- Consistent naming
- Clear separation of concerns

---

# Definition of Done

A feature is complete only when:

- All requested functionality is implemented.
- Code is production-ready.
- Existing tests pass.
- New Playwright E2E tests pass.
- The implementation is maintainable.
- The feature follows Rails and Hotwire best practices.
- Edge cases are handled.
- Business rules are enforced.
- The implementation is safe for concurrent usage.
- The feature can be confidently deployed to production without additional engineering work.

Do not stop until every item above has been satisfied.
