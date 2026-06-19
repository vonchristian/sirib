1. 🎯 PRODUCT OBJECTIVE

Build a multi-tenant core banking system for cooperatives where:

Each cooperative is:

a fully isolated banking institution
operating independently
sharing only application code, NOT data
2. 🧠 ARCHITECTURE DECISION (FINAL)
✔ Selected model for Phase 1:

Single PostgreSQL cluster + schema-per-tenant + strict tenant boundary layer

❌ Explicitly rejected for Phase 1:
DB-per-domain (accounting DB, lending DB) → WRONG MODEL
Row-based tenancy → unsafe for banking requirement
Sharding → premature
Microservices → unnecessary
🏗 System architecture
                    Rails 8 App
                          │
        ┌──────────────── Tenant Boundary Layer ────────────────┐
        │                                                       │
   CurrentTenant Resolver                             Auth / RBAC
        │
        ▼
 PostgreSQL (Single Cluster)
        │
 ┌──────────── Schema-per-tenant (STRICT ISOLATION) ───────────┐
 │ coop_001 | coop_002 | coop_003 | coop_004                   │
 │ accounting | lending | members | cash_management           │
 └──────────────────────────────────────────────────────────────┘
3. 🧱 TENANCY MODEL (CRITICAL)
3.1 Rules
Every request MUST resolve a tenant
No database query without tenant context
No shared banking tables
No cross-schema queries
3.2 Tenant resolution sources

Priority order:

Subdomain (coop1.app.com)
Authenticated user context
Admin override (backoffice only)
3.3 Enforcement (VERY IMPORTANT)

System must prevent:

Account.all # ❌ forbidden without tenant context

Must enforce:

CurrentTenant.scope(Account) # ✔ allowed
4. 🏦 DOMAIN DESIGN (CLEAN + FUTURE-PROOF)

We separate code domains, NOT databases.

4.1 Accounting Domain (CORE OF BANKING)
Responsibilities:
General Ledger (GL)
Journal Entries
Trial Balance
Financial Statements
Entities:
Account (GL Account)
JournalEntry
JournalLine
4.2 Lending Domain
Responsibilities:
Loan lifecycle
Amortization
Repayments
Interest calculation (simple phase 1)
Entities:
LoanAccount
LoanSchedule
LoanPayment
4.3 Member Domain
Responsibilities:
Member onboarding
Identity management
Account linking
Entities:
Member
MemberProfile
4.4 Cash Operations (Teller-lite)
Responsibilities:
Cash in / cash out
Teller sessions (basic)
Vault tracking (simple)
5. 🔐 BANK-GRADE ISOLATION RULES
HARD RULES
1. No cross-tenant query possible
enforced via middleware
2. No shared banking tables
no global accounts table
3. No tenant ID filtering in models
tenant is handled by infrastructure only
4. Audit requirement

Every transaction logs:

coop_id
user_id
action
timestamp
entity affected
6. 🧭 TENANT PROVISIONING SYSTEM
6.1 Onboarding flow
Admin creates cooperative
→ System creates schema
→ Runs migrations
→ Seeds default GL accounts
→ Seeds roles & permissions
→ Activates tenant
6.2 Provisioning service
CoopProvisioningService.call(coop)
6.3 Seeded defaults per coop
Chart of Accounts template
Loan product templates
Member roles
Cash account structure
7. 🔄 MIGRATION SYSTEM (CRITICAL INFRA)
Requirement

Migrations must apply to ALL tenant schemas safely.

Execution model:
for each coop schema:
  switch schema
  run migration
  log result
Must support:
retry failed schemas
migration audit table
partial failure detection
safe re-run
8. ⚙️ READ/WRITE MODEL
Phase 1 simplicity:
Writes → primary DB
Reads → same DB (replica optional)
Allowed read scaling:
reports
dashboards
audit views
9. 🧾 REPORTING (PHASE 1 SCOPE)

ONLY per-coop reporting:

Balance sheet
Trial balance
Loan portfolio summary
Member balances

❌ No cross-coop analytics yet

10. 🔁 BACKGROUND JOB RULES

Every job MUST include tenant context:

LoanRepaymentJob.perform_later(coop_id, loan_id)

Job execution:

resolve tenant
switch schema
execute logic
11. 🧪 TESTING STRATEGY (BANKING-GRADE)
Required:
Unit tests
accounting correctness
loan computations
Integration tests
tenant isolation
schema switching correctness
E2E tests (Playwright)
full banking flow per coop
verify no cross-tenant access
12. 🚀 PERFORMANCE TARGETS
API response: < 300ms typical
loan posting: < 1s
report generation: < 5s acceptable
onboarding: < 5 minutes per coop
13. 📦 DEPLOYMENT MODEL
Single Rails 8 application
Single PostgreSQL cluster
Optional read replica
ENV-based tenant resolution enabled
14. 📈 SUCCESS CRITERIA (PHASE 1)

System is successful if:

Business
0 → 50 cooperatives onboarded successfully
full banking lifecycle works per coop
Technical
zero cross-tenant data leaks (tested)
migrations run across all schemas reliably
system stable under moderate load
15. 🧠 FUTURE COMPATIBILITY (NON-NEGOTIABLE)

Phase 1 MUST NOT block:

DB-per-tenant migration
Rails sharding introduction
hybrid architecture (small/large coops split)
data warehouse extraction
🔑 FINAL CTO DECISION SUMMARY
We are building:

A single Rails monolith that behaves like 50 isolated banks running independently

We are NOT building:
microservices
domain-separated databases
sharding system
distributed architecture