# Code Smells Reference (Ruby Science)

## Detection Checklist

For each code smell, identify the pattern, assess severity, and recommend a solution.

## 1. Long Method
**Detection**: Methods > 10 lines, > 1 nesting level, > 1 abstraction level, flog >= 10.
**Severity**: Medium
**Solutions**: Extract Method, Replace Temp with Query

## 2. Large Class
**Detection**: Can't describe in one sentence, > 200 lines, > 15 public methods, flog >= 50.
**Severity**: High
**Solutions**: Extract Class, Extract Value Object, Extract Decorator, Move Method

## 3. Feature Envy
**Detection**: Repeated references to same external object, params used more than ivars, Law of Demeter violations.
**Severity**: Medium
**Solutions**: Move Method

## 4. Case Statement / Type Code
**Detection**: `case` checking class/type, multiple `if/elsif` same condition.
**Severity**: High
**Solutions**: Replace Conditional with Polymorphism

## 5. Shotgun Surgery
**Detection**: Same small change needed in multiple files.
**Severity**: High
**Solutions**: Replace Conditional with Polymorphism, Inline Class

## 6. Divergent Change
**Detection**: Class changes for multiple unrelated reasons.
**Severity**: High
**Solutions**: Extract Class, Move Method, Extract Validator, Introduce Form Object

## 7. Long Parameter List
**Detection**: Methods with > 3 arguments.
**Severity**: Medium
**Solutions**: Introduce Parameter Object

## 8. Duplicated Code
**Detection**: Copy-pasted blocks, similar logic with variations.
**Severity**: High
**Solutions**: Extract Method, Extract Class, Replace Conditional with Polymorphism

## 9. Mixin Abuse
**Detection**: Mixins with repeated params, business logic in mixins.
**Severity**: Medium
**Solutions**: Extract Class, Replace Mixin with Composition

## 10. Callback Complexity
**Detection**: `after_create`/`before_save` with business logic (emails, payments).
**Severity**: High
**Solutions**: Replace Callback with Method, Extract to PORO

## 11. Comments as Smell
**Detection**: Comments explaining what code does, commented-out code.
**Severity**: Low
**Solutions**: Extract Method with descriptive name, delete dead code

## 12. STI Issues
**Detection**: Need to change subclass, nil columns everywhere.
**Severity**: Medium
**Solutions**: Replace Subclasses with Strategies, use Polymorphic Associations

## 13. God Class
**Detection**: References most other models, very high methods/lines.
**Severity**: Critical
**Solutions**: Extract Class aggressively, use composition

## Priority Order
1. Critical: God Class, Security issues
2. High: Duplicated Code, Case Statements, Large Class, Callback Complexity
3. Medium: Long Method, Feature Envy, Long Parameter List, Mixin Abuse
4. Low: Comments, Naming issues
