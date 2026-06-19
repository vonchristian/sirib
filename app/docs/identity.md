Core Banking Platform — Identity Layer (Rails 8 + E2E Tested)

You are a Principal Product Manager + Staff Rails Architect designing the Identity Layer for a core banking platform used by internal employees (tellers, managers, auditors, admins).

Your output must be directly implementable in Rails 8 by an AI coding agent (OpenCode).

1. Context

This system is internal-only for bank employees:

Tellers → cash handling, deposits, withdrawals
Branch Managers → approvals, overrides, reporting
Auditors → read-only investigation access
Admins → system configuration and user management

The Identity Layer is the root security boundary of the entire banking system.

2. Core Principle

Do NOT treat identity as:

email + password login

Instead model identity as a multi-dimensional security object:

WHO the employee is (identity)
WHAT authority they have (role)
WHERE they operate (branch context)
WHAT they are allowed to do (permissions scope)
3. Functional Requirements
3.1 Authentication (Rails 8 Secure Login)

Implement secure authentication:

Employee ID + password login (primary credential)
Secure password hashing (bcrypt or argon2)
Session-based authentication (Rails session store)
Session expiration + idle timeout
Session revocation on:
role change
password change
suspension

Optional but required design support:

TOTP-based MFA (Google Authenticator compatible)
3.2 Employee Identity Model (Core Domain Object)

Define Employee as a first-class domain entity.

Each employee must have:

employee_id (unique, immutable)
full_name
status:
active
suspended
terminated
roles (many-to-many)
branch assignments (many-to-many)
permission overrides (optional direct grants/denies)
3.3 Role System (RBAC Foundation)

Predefined roles:

Teller
Branch Manager
Auditor
System Admin

Each role defines:

default permissions
module access scope
allowed actions (create, approve, view, override)

Rules:

Employees can have multiple roles
Roles are composable
Roles are extendable per bank configuration
3.4 Branch Context Layer

All employee actions are executed within a branch context.

Rules:

Each employee has a primary branch
May have secondary branch access
Data access must be strictly scoped by branch

Constraints:

Teller → only assigned branch
Manager → multiple users within branch scope
Auditor → multi-branch read-only access
3.5 Permission System (Fine-Grained Authorization)

Define permissions using structured format:

resource:action:scope

Examples:

transactions:create:branch
transactions:approve:branch
accounts:view:branch
users:manage:system

Rules:

Permissions inherited from roles
Explicit DENY overrides ALLOW
Must support future ABAC-style rules (attribute-based control)
Must be enforceable at service layer (not just UI)
3.6 Identity Context Resolver (Core Engine)

Build a deterministic service:

“What can this employee do right now?”

It must compute:

effective roles
effective permissions
branch scope
overrides (allow/deny)
current session validity

Requirements:

Must be cacheable (Redis optional)
Must remain consistent with audit log integrity
Must be fast (used on every request)
3.7 Security Requirements (Bank-Grade)
bcrypt or argon2 password hashing
MFA via TOTP (Google Authenticator compatible)
login attempt throttling (brute-force protection)
session expiration + idle timeout
forced logout on identity change
full audit logging for identity events:
login success/failure
logout
password changes
role/branch changes
permission overrides
suspension/activation
3.8 Audit Logging System

Every identity action must be immutably logged.

Audit log must capture:

actor (employee performing action)
target (employee affected)
action type
timestamp
IP address
device/session identifier
before state
after state

Audit logs must be:

append-only
tamper-resistant (no updates/deletes)
4. Rails 8 Data Model (Expected Output)

Design ActiveRecord models and migrations for:

Core Tables
employees
roles
permissions
employee_roles
role_permissions
branches
employee_branches
sessions
audit_logs
permission_overrides (optional but recommended)

Include:

proper indexes
foreign key constraints
uniqueness constraints
soft delete strategy (only where appropriate)
5. Authorization Logic

Define a single source of truth service:

Identity::AuthorizationService

Responsibilities:

resolve effective permissions
evaluate allow/deny rules
validate branch scope
expose can?(employee, action, resource)

Must be:

deterministic
testable
framework-agnostic inside Rails services
6. E2E Testing Requirements (CRITICAL)

You MUST design Playwright-based E2E tests (or equivalent system tests in Rails 8) for the Identity Layer.

6.1 Required E2E Scenarios
Authentication
valid login succeeds
invalid password fails
locked/suspended account cannot login
MFA (if enabled)
correct TOTP passes
incorrect TOTP fails
Session Management
session expires after timeout
logout invalidates session
role change forces logout
Role-Based Access
teller cannot access manager-only screens
auditor has read-only access across branches
admin can manage roles
Branch Isolation
user cannot access other branch data
manager can access assigned branch users only
Permission Enforcement
unauthorized action blocked at backend
UI does NOT hide-only security (backend enforced)
Audit Logging
login generates audit entry
role change generates audit entry
failed login generates audit entry
6.2 Test Design Requirements
Tests must be reusable and modular
Fixtures or factories required (FactoryBot recommended)
Must simulate multiple employee roles
Must run in CI
Must be deterministic (no flaky timing issues)
7. Edge Cases (Must Handle)
employee with multiple roles conflicting permissions
branch reassignment while session active
simultaneous login sessions
revoked employee still holding cached session
deny overriding allow permissions
auditor accessing restricted transaction data
orphaned role or branch relationships
8. Constraints
Must be Rails 8 idiomatic
Must use ActiveRecord + Service Objects (no fat controllers)
Must be production-ready for banking systems
Must assume zero-trust environment
Must support horizontal scaling
Must be understandable by AI coding agents (OpenCode-ready)
9. Output Format

You must output:

Rails architecture overview (services + models)
Full ActiveRecord schema design
Authorization algorithm (step-by-step logic)
Identity Context Resolver design
Audit logging system design
Full E2E test plan (Playwright or Rails system tests)
Edge case handling strategy
10. Success Criteria

This design is successful if:

A Rails 8 code generator can implement it without clarification
It enforces strict branch isolation
It prevents privilege escalation
It is fully test-covered via E2E flows
It is production-grade for real banking operations