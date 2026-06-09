# PORO Patterns Reference (Plain Old Ruby Objects)

## Philosophy: Service Objects Are Poorly-Named Models
Create domain models with meaningful names, not generic `*Service` classes.

## Naming Convention
| Instead of | Use |
|------------|-----|
| `UserSignupService` | `Registration` |
| `PaymentProcessor` | `Payment` |
| `NotificationService` | `Notification` |
| `OrderCreator` | `OrderPlacement` |

## ActiveModel::Model Pattern
```ruby
class Registration
  include ActiveModel::Model
  attr_accessor :email, :password, :company_name
  validates :email, presence: true

  def save
    return false unless valid?
    create_user
    create_company
    send_welcome_email
    true
  end
end
```

## Form Objects
Use when forms don't map 1:1 to a DB model. Include `ActiveModel::Model`, define `attr_accessor` for form fields, use meaningful verbs like `submit` instead of `call`.

## Search/Query Objects
Use for complex search forms with filtering and sorting:
```ruby
class PostSearch
  include ActiveModel::Model
  include ActiveModel::Attributes
  attribute :query, :string

  def results
    scope = Post.all
    scope = scope.where("title ILIKE ?", "%#{query}%") if query.present?
    scope
  end
end
```

## Refactoring Service Objects to POROs
1. Identify the domain concept (noun)
2. Add `ActiveModel::Model`
3. Replace `.call` with a domain verb (`complete`, `submit`, `save`)
4. Update controller to instantiate the PORO

## Directory Structure
Prefer `app/models/` with namespaces over `app/services/`:
```
app/models/
├── registration.rb
├── post_search.rb
├── user_presenter.rb
└── orders/
    ├── placement.rb
    └── calculator.rb
```
