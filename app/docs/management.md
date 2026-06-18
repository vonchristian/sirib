# Product Manager Prompt: Management Operations Module (Core Banking System for Cooperatives)

## Role

You are an expert Product Manager specializing in **Core Banking Systems**, **Organizational Governance Platforms**, and **Financial Institution Management Systems** for cooperatives.

Your task is to design a **Management Operations Module** that serves as the **control plane of the entire core banking system**.

This is not an HR system.

This is the **governance, configuration, oversight, and operational control layer** of a regulated financial institution.

---

# Business Context

A cooperative core banking system consists of multiple financial domains:

* Loans (credit operations)
* Savings (liabilities)
* Time Deposits (term liabilities)
* Share Capital (equity)
* Treasury (cash movement)
* Accounting (financial truth layer)

All of these systems must be governed, configured, monitored, and controlled by a central management layer.

---

# Core Design Principle

> “If operations are the engine, management is the control tower.”

The Management Operations module is responsible for:

* Governance
* Policy enforcement
* Operational limits
* Branch oversight
* System configuration
* Performance monitoring
* Risk visibility
* Organizational structure

---

# Feature 1 — Organizational Structure Management

## Entities

* Cooperative Entity
* Branches
* Departments
* Teams

---

## Rules

* Every transaction must belong to a branch
* Branch-level isolation of financial data
* Central consolidation view required
* Hierarchical reporting structure enforced

---

# Feature 2 — User & Role Management

## Roles

* Board Member
* General Manager
* Branch Manager
* Loan Officer
* Teller
* Accountant
* Auditor
* System Admin

---

## Permissions System

Supports:

* Role-based access control (RBAC)
* Attribute-based access control (ABAC)
* Branch-based access restriction
* Product-level permissions (Loans, Savings, etc.)

---

## Rules

* No user can approve their own transactions
* Sensitive operations require dual control
* All access is logged

---

# Feature 3 — Policy & Limit Engine

Defines institutional rules.

---

## Examples

### Loan Limits

* Max loan per member
* Max loan per branch
* Approval thresholds

### Cash Limits

* Teller cash limit
* Vault cash limit
* Disbursement limits

### Savings Rules

* Minimum balance
* Withdrawal limits

---

## Rule Behavior

* Policies are enforced at runtime
* Violations must block or require override approval
* Overrides are fully audited

---

# Feature 4 — Branch Performance Management

## Metrics

* Loan portfolio per branch
* Savings growth
* Delinquency rate
* Collection efficiency
* Cash flow position
* Profitability (estimated)

---

## Outputs

* Branch ranking dashboard
* KPI scorecards
* Trend analysis

---

# Feature 5 — System Configuration Engine

Central configuration for all modules:

* Loan product rules
* Savings product rules
* Share capital rules
* Time deposit rules
* Treasury thresholds
* Accounting mappings

---

## Rule

* Config changes require approval workflow
* Changes are versioned
* Historical configurations must remain accessible

---

# Feature 6 — Approval Workflow Engine

Used across all operations.

---

## Configurable Approval Chains

Example:

* Loan under ₱50,000 → Branch Manager
* ₱50,000–₱500,000 → Credit Committee
* Above ₱500,000 → Board

---

## Rules

* Approval is immutable
* Multi-level approval supported
* Delegation must be logged
* No bypassing approval chains

---

# Feature 7 — Risk & Compliance Monitoring

## Risk Categories

* Credit risk
* Liquidity risk
* Operational risk
* Fraud risk indicators

---

## Monitoring Metrics

* Delinquency rate
* Portfolio at risk (PAR)
* Cash shortages
* Suspicious transaction patterns
* Policy violations

---

# Feature 8 — Audit & Oversight Console

Central visibility layer for governance.

---

## Features

* View all system transactions
* Drill-down into any financial event
* View approval history
* View system logs
* Export audit reports

---

## Rule

* Read-only access for auditors
* Tamper-proof logs
* Immutable history

---

# Feature 9 — Dashboard & Executive Reporting

## Executive KPIs

* Total assets under management
* Loan portfolio size
* Savings deposits
* Share capital growth
* Net income
* Cash position
* Branch performance ranking

---

## UX Requirement

* Executive-level simplicity
* High-level summaries
* Drill-down capability
* Real-time or near real-time updates

---

# Feature 10 — Operational Alerts Engine

Triggers alerts for:

* Loan delinquency spikes
* Cash shortages
* Branch anomalies
* Approval threshold breaches
* Suspicious transactions
* System failures

---

## Channels

* Email
* SMS
* In-app alerts
* Dashboard notifications

---

# Feature 11 — Governance Controls

## Board-Level Controls

* Policy approval
* Strategic limit adjustments
* System-wide configuration approval

---

## Management Controls

* Operational oversight
* Branch management
* Performance interventions

---

## Rule

* Governance actions are fully audited
* Dual approval required for critical changes

---

# Feature 12 — Multi-Branch Consolidation Engine

## Outputs

* Consolidated financial reports
* Inter-branch eliminations
* System-wide liquidity position
* Group-level performance metrics

---

# Feature 13 — System Health Monitoring

## Metrics

* Transaction throughput
* Queue processing status (Solid Queue)
* Posting latency
* Error rates
* Failed transactions
* Reconciliation mismatches

---

# Feature 14 — Audit Trail (System-Wide)

Every management action must log:

* Actor
* Role
* Branch
* Timestamp
* Device/IP
* Before state
* After state
* Approval chain
* Configuration version

---

# Feature 15 — Permissions Model

## Board

* Approve policies
* View all reports

## General Manager

* Full operational oversight
* Approve major changes

## Branch Manager

* Branch-level control
* Performance monitoring

## Admin

* System configuration

## Auditor

* Read-only access across all modules

---

# UX Requirements

Management UI must be:

* Executive-grade
* Clean dashboards
* Minimal noise
* High-density data tables where needed
* Fast navigation
* Drill-down oriented
* Role-aware views
* No decorative UI

---

# Event-Driven Architecture

Management operations emit events:

* PolicyUpdated
* UserRoleChanged
* BranchCreated
* LimitChanged
* ApprovalWorkflowUpdated
* AlertTriggered

These events affect:

* All operational modules
* Accounting constraints
* Treasury limits
* Loan rules
* System behavior

---

# Integration Layer

This module governs:

* Loan Operations
* Savings Operations
* Time Deposit Operations
* Share Capital Operations
* Treasury Operations
* Accounting Operations

It does NOT execute financial transactions directly.

It defines the rules under which they operate.

---

# Future Enhancements

Design for:

* AI governance assistant
* Automated risk scoring
* Predictive branch performance
* Fraud detection insights
* Regulatory compliance automation
* Dynamic policy recommendations
* Natural language policy configuration
* Real-time anomaly detection
* Board simulation dashboards

---

# Expected Deliverables

Generate:

1. User Stories
2. Business Rules
3. Acceptance Criteria
4. Validation Rules
5. Domain Model
6. Database Schema
7. ERD
8. Rails Models
9. Service Objects
10. State Machines
11. Policy Engine Design
12. Approval Workflow System
13. Role & Permission Architecture
14. Dashboard Design
15. API Endpoints
16. Hotwire UI Wireframes
17. Screen Layouts
18. Alerting System Design
19. Audit Logging Strategy
20. Event-Driven Architecture
21. Multi-Branch Consolidation Strategy
22. System Governance Framework
23. Future Extension Strategy

---

# Technical Constraints

Must be designed for:

* Ruby on Rails 8
* Hotwire / Turbo / Stimulus
* PostgreSQL
* Solid Queue
* Domain-Driven Design (DDD)
* Event-driven architecture
* Strict auditability
* Role-based + attribute-based security
* High reliability distributed system design

---

# Core Principle

> Management does not touch money. It governs how money moves.

If governance is wrong, everything downstream is wrong.
