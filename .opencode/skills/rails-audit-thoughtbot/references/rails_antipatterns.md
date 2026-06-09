# Rails Antipatterns Reference

## 1. Voyeuristic Models (Law of Demeter)
**Detection**: Chained association access in views (`@invoice.customer.address.street`)
**Fix**: Use `delegate` with `prefix`, access finders through association proxy

## 2. Monolithic Controllers (REST Violations)
**Detection**: > 7 actions per controller, excessive `member`/`collection` routes
**Fix**: Extract to separate REST controllers

## 3. Bloated Sessions
**Detection**: Storing full objects (`session[:user] = @user`)
**Fix**: Store only IDs (`session[:user_id]`)

## 4. Fire and Forget (External Service Errors)
**Detection**: `rescue nil`, bare `rescue`, HTTP calls without exception handling
**Fix**: Rescue specific HTTP errors, report failures, don't silently swallow

## 5. Sluggish Services (Missing Timeouts)
**Detection**: HTTP calls without explicit timeouts
**Fix**: Set `open_timeout` (2-5s) and `read_timeout` (5-10s), background when possible

## 6. Messy Migrations
**Detection**: Model references in migrations (`User.all.each`)
**Fix**: Use raw SQL or define inline model class

## 7. Missing Database Indexes
**Detection**: `*_id` columns without index, uniqueness validations without unique index
**Fix**: Add indexes on foreign keys, polymorphic type/id pairs, slugs

## 8. Painful Performance (Ruby vs SQL)
**Detection**: `Model.all.select`, `all.map`, `all.reject`, `.length` on associations
**Fix**: Use SQL `where`, `count`, `sum` — database does the work

## 9. Inaudible Failures (Silent Errors)
**Detection**: `save` without checking return, `update` without bang, no transactions
**Fix**: Use `save!`/`update!`, wrap bulk ops in transactions

## 10. Spaghetti SQL (Query Logic in Controllers)
**Detection**: `where`/`order`/`joins` chains in controllers
**Fix**: Extract to model scopes

## 11. PHPitis (Logic in Views)
**Detection**: Model queries in views, > 2 levels of conditional nesting
**Fix**: Extract to presenters/helpers

## 12. Gem Hygiene
**Detection**: Unused gems, gems inactive > 12 months, multiple gems solving same problem
**Fix**: Audit with TAM (Tests, Activity, Maturity)

## Priority Order
1. Missing Indexes, Inaudible Failures, Fire and Forget
2. Monolithic Controllers, Bloated Sessions, Painful Performance
3. Voyeuristic Models, Spaghetti SQL, Messy Migrations, PHPitis
4. Gem Hygiene
