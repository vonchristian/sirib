# Testing Guidelines Reference (Testing Rails)

## Test Suite Quality Characteristics
Fast, Complete, Reliable, Isolated, Maintainable, Expressive.

## Testing Pyramid
- **Base**: Many fast unit/model tests
- **Middle**: Some integration tests
- **Top**: Few slow feature/system tests

## Test Types Coverage Requirements
### Feature/System Specs — All critical user flows, happy paths, key error handling
### Model Specs — All validations, public methods, associations
### Controller/Request Specs — Authorization, error handling, response formats
### View Specs — Conditional rendering, complex view logic
### Helper Specs — All public helper methods
### Mailer Specs — Correct recipients, subject, body content

## Four Phase Test Pattern
```ruby
it "does something" do
  # Setup
  user = create(:user)
  # Exercise
  result = user.full_name
  # Verify
  expect(result).to eq "John Doe"
  # Teardown (handled by framework)
end
```

## Testing Antipatterns
1. **Slow Tests** — > 5min suite, avg spec > 100ms
2. **Intermittent Failures** — shared state, time dependency, ordering
3. **Brittle Tests** — testing implementation, hardcoded selectors
4. **Duplication** — repeated setup, missing shared examples
5. **Mystery Guest** — test data invisible in test body
6. **Stubbing System Under Test** — `allow(subject).to receive(...)`
7. **False Positives** — `expect(page).to have_content("")`
8. **Factories Like Fixtures** — `create(:admin_user_with_premium)`
9. **Bloated Factories** — > 5 attrs, unnecessary associations
10. **Over-use of let/subject/before** — > 5 let statements

## Coverage Requirements
| Type | Min Coverage |
|------|--------------|
| Model | 90% |
| Controller | 80% |
| Service/PORO | 95% |
| Helper | 100% |
| Mailer | 100% |
| Job | 90% |

## FactoryBot Best Practices
Keep factories lean — only required fields with sensible defaults. Avoid unnecessary associations.
