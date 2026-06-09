---
name: test-driven-development
description: "Strict red-green-refactor TDD workflow for implementing features, fixing bugs, or changing behavior in Rails applications — enforces betterspecs.org style guide"
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

## When Stuck
| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |

## Debugging Integration
Bug found? Write failing test reproducing it. Follow TDD cycle. Test proves fix and prevents regression.

## betterspecs.org RSpec Style Guide

These rules apply to every test written. They are not optional.

### 1. Describe Methods Clearly
Use `.` for class methods, `#` for instance methods.
```ruby
describe '.authenticate' do   # class method
describe '#admin?' do         # instance method
```

### 2. Use Contexts
Group conditions with `context`. Start descriptions with `when`, `with`, or `without`.
```ruby
context 'when logged in' do
  it { is_expected.to respond_with 200 }
end
context 'when logged out' do
  it { is_expected.to respond_with 401 }
end
```

### 3. Keep Descriptions Short
Never exceed 40 characters. If you need more, split into a context.

### 4. Single Expectation Per Test (Isolated)
One assertion per example. Multiple expectations signal multiple behaviours.
```ruby
it { is_expected.to respond_with_content_type(:json) }
it { is_expected.to assign_to(:resource) }
```
**Exception:** slow integration/feature specs may group expectations to avoid repeated setup.

### 5. Test All Possible Cases
Cover valid, edge, and invalid cases. Think of every input and test it.
```ruby
context 'when resource is found' do
  it { is_expected.to respond_with 200 }
end
context 'when resource is not found' do
  it { is_expected.to respond_with 404 }
end
```

### 6. Use `expect` Syntax Always
Never use `should`. Configure RSpec to enforce only `expect` syntax.
```ruby
# bad
response.should respond_with_content_type(:json)
# good
expect(response).to respond_with_content_type(:json)
# one-liner with implicit subject
it { is_expected.to respond_with 200 }
```

### 7. Use `subject`
DRY up repeated subjects with `subject` and named subject.
```ruby
subject { assigns('message') }
it { is_expected.to match /it was born in Billville/ }

subject(:hero) { Hero.first }
it 'carries a sword' do
  expect(hero.equipment).to include 'sword'
end
```

### 8. Use `let` and `let!`
Replace `before` + instance variables with `let`. `let` lazy-loads, `let!` eager-loads.
```ruby
# bad
before { @resource = FactoryBot.create :device }
# good
let(:resource) { FactoryBot.create :device }
let!(:populated) { FactoryBot.create_list :user, 3 }  # eager for scopes/queries
```

### 9. Don't Overuse Mocks
Test real behaviour when possible. Mocks make specs faster but harder to maintain.
```ruby
context 'when not found' do
  before { allow(Resource).to receive(:where).and_return(false) }
  it { is_expected.to respond_with 404 }
end
```

### 10. Create Only the Data You Need
Do not load more records than necessary. If you think you need dozens, you're probably wrong.
```ruby
before { FactoryBot.create_list(:user, 3) }
it { expect(User.top(2)).to have(2).item }
```

### 11. Use Factories, Not Fixtures
Fixtures are difficult to control. Use FactoryBot.
```ruby
user = FactoryBot.create :user
```

### 12. Use Readable Matchers
Prefer expressive matchers. Use `expect { }.to raise_error` over `lambda`.
```ruby
expect { model.save! }.to raise_error Mongoid::Errors::DocumentNotFound
```

### 13. Use Shared Examples to DRY
Extract repeated patterns into shared examples.
```ruby
it_behaves_like 'a listable resource'
it_behaves_like 'a paginable resource'
```

### 14. Test What You See
Favour integration tests with Capybara over controller tests. Test the behaviour users experience. Deeply test models. Skip controller tests unless they add unique coverage.

### 15. Don't Use `should` in Descriptions
Use third-person present tense.
```ruby
# bad
it 'should not change timings'
# good
it 'does not change timings'
```

### 16. Stub HTTP Requests
Use webmock or VCR for external services. Never hit real APIs in tests.
```ruby
before { stub_request(:get, uri).to_return(status: 401, body: fixture('401.json')) }
```

## Verification Checklist (Extended)
- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered
- [ ] Descriptions use `.`/`#` notation for methods
- [ ] Contexts start with `when`/`with`/`without`
- [ ] Descriptions under 40 characters
- [ ] Single expectation per isolated test
- [ ] Uses `expect` syntax, never `should`
- [ ] Uses `let`/`subject` over instance variables
- [ ] No unnecessary data creation
- [ ] Stubs external HTTP requests
- [ ] No `should` in description strings

## Final Rule
```
Production code → test exists and failed first
Otherwise → not TDD
```
