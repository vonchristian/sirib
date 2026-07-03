 # PRD: Branch Manager AI Agent

## Overview

The Branch Manager AI Agent is an operational intelligence system that continuously monitors branch activity, identifies issues requiring management attention, summarizes performance, and recommends actions.

The objective is not to provide a chatbot.

The objective is to act as an AI-powered branch operations analyst that helps branch managers focus on the highest-impact work each day.

The agent continuously analyzes:

* Loans
* Savings
* Collections
* Membership
* Cash operations
* Approvals
* Compliance
* Employee productivity

and transforms raw transactional data into actionable insights.

---

# Business Problem

Branch managers currently spend significant time:

* Reviewing multiple dashboards
* Preparing reports
* Following up on staff
* Monitoring collections
* Identifying operational risks

Important issues are often discovered too late.

Examples:

* PAR30 increased last week
* Collections are behind target
* KYC documents are expiring
* Loan approvals are stuck
* Cash variance exists

The platform already contains the data.

The AI Agent's role is to surface the right information at the right time.

---

# Goals

Reduce:

* Manual report generation
* Missed operational issues
* Delayed management intervention

Increase:

* Collection performance
* Staff accountability
* Branch visibility
* Faster decision making

---

# Success Metrics

## Operational

Daily manager logins increase.

Managers review AI digest daily.

Average time to identify branch issues decreases.

---

## Portfolio

PAR30 decreases.

Collection efficiency improves.

Loan approval turnaround improves.

---

## Productivity

Reduction in manual report preparation.

Reduction in supervisor follow-up work.

---

# User Roles

## Primary

Branch Manager

## Secondary

Operations Supervisor

Branch Head

Area Manager

CEO

---

# Core Concept

Every morning the manager receives:

* Branch summary
* Risks
* Recommendations
* Staff workload
* Action queue

Instead of opening ten reports.

---

# Daily Digest

Generated automatically at 6:00 AM.

Stored in database.

Visible from dashboard.

Example:

Good Morning.

Branch Angeles Summary

Loans Released Yesterday: 12

Collections Yesterday:
₱985,000

Collection Target:
₱1,200,000

Achievement:
82%

New Members:
18

PAR30:
3.2%

Pending Approvals:
6

Critical Issues:
3

Recommended Actions:
4

---

# Functional Requirements

## FR-001 Daily Branch Summary

Generate daily summary.

Metrics:

Loans Released

Loan Amount Released

Collections Received

Collection Target

Collection Efficiency

Savings Deposits

Savings Withdrawals

New Members

Closed Accounts

Pending Approvals

Pending Applications

Staff Attendance

Cash Position

---

## FR-002 Collections Monitoring

Analyze collection performance.

Identify:

Loans due today

Loans overdue

Broken promises to pay

PAR30 entries

PAR60 entries

Collection target shortfalls

Example Recommendation:

Collections are below target by 18%.

Focus on 14 loans overdue more than 7 days.

---

## FR-003 Loan Pipeline Monitoring

Review loan workflow.

Detect:

Applications pending review

Applications pending approval

Applications pending release

SLA violations

Example:

7 loan applications have been waiting more than 48 hours.

---

## FR-004 Portfolio Risk Monitoring

Monitor loan portfolio.

Metrics:

PAR1

PAR7

PAR30

PAR60

PAR90

Portfolio Growth

Refinanced Loans

Restructured Loans

Detect changes.

Example:

PAR30 increased from 2.4% to 3.1%.

Primary contributor:
Agricultural loans.

---

## FR-005 Savings Monitoring

Track:

Deposit trends

Withdrawal spikes

Dormant accounts

Low balance accounts

Example:

Savings withdrawals increased 42% versus weekly average.

---

## FR-006 Membership Monitoring

Track:

New members

Membership growth

Incomplete applications

Pending KYC

Dormant members

Example:

15 members require KYC update.

---

## FR-007 Cash Monitoring

Analyze teller activity.

Track:

Vault balance

Cash on hand

Cash transfers

Cash variance

Unbalanced cash sessions

Example:

Teller Session #193 has ₱3,200 variance.

---

## FR-008 Staff Productivity Monitoring

Track:

Assigned tasks

Completed tasks

Collection activities

Loan processing activities

Attendance

Example:

Collection Officer Juan completed 2 of 14 assigned collection visits.

---

## FR-009 Exception Detection

Detect operational anomalies.

Examples:

Unusual withdrawals

Sudden delinquency increases

Approval bottlenecks

Missing attendance

Excessive transaction reversals

Cash variances

Each anomaly becomes an Observation.

---

## FR-010 Recommendations Engine

Generate actionable recommendations.

Every recommendation includes:

Title

Description

Reason

Suggested Action

Priority

Confidence Score

Example:

Priority:
High

Issue:
Collection target likely to be missed.

Suggested Action:
Assign additional collector to Barangay Pampang route.

---

# AI Inbox

Managers receive:

Observations

Alerts

Recommendations

Tasks

Sorted by priority.

---

# Priority Levels

Critical

High

Medium

Low

---

# Observation Model

Represents facts detected by AI.

Examples:

PAR30 increased.

Collections below target.

Loan approvals delayed.

No recommendations stored here.

Only facts.

---

# Recommendation Model

Represents suggested action.

Generated from observations.

Example:

Observation:

Collections below target.

Recommendation:

Increase collection visits for high-balance delinquent members.

---

# Data Model

## Ai::Agent

Stores agent definition.

Fields:

name

description

enabled

schedule

---

## Ai::AgentRun

Stores execution history.

Fields:

agent_id

started_at

completed_at

status

tokens_used

execution_time_ms

---

## Ai::Observation

Fields:

branch_id

category

severity

title

summary

metadata

detected_at

resolved_at

---

## Ai::Recommendation

Fields:

observation_id

priority

title

summary

action_text

confidence_score

status

dismissed_at

completed_at

---

## Ai::Digest

Fields:

branch_id

generated_at

summary

risk_summary

recommendations_summary

---

# Agent Tools

Agents never query models directly.

All data access goes through tools.

## Tools

Ai::Tools::BranchMetricsTool

Ai::Tools::CollectionsTool

Ai::Tools::LoanPipelineTool

Ai::Tools::PortfolioRiskTool

Ai::Tools::SavingsTool

Ai::Tools::MembershipTool

Ai::Tools::CashPositionTool

Ai::Tools::StaffProductivityTool

---

# Execution Schedule

## Daily

6:00 AM

Generate Digest

Generate Observations

Generate Recommendations

---

## Hourly

Refresh critical metrics.

Detect anomalies.

Generate alerts.

---

# Dashboard UI

## New Widget

AI Branch Manager

Cards:

Today's Summary

Critical Alerts

Recommendations

Staff Productivity

Collection Risks

Loan Bottlenecks

---

# Hotwire Requirements

Use Turbo Frames.

Each dashboard card updates independently.

No full page reloads.

---

# Notification Rules

Critical:

Immediate notification.

High:

Hourly digest.

Medium:

Daily digest.

Low:

Dashboard only.

---

# Permissions

Branch Manager:

Own branch only.

Area Manager:

Assigned branches.

Executive:

All branches.

---

# Audit Requirements

All AI outputs stored.

All recommendations traceable.

Store:

Input metrics

Prompt version

Model version

Generated output

User actions

No AI-generated recommendation may be deleted.

Only dismissed or resolved.

---

# Phase 1 Scope

Included:

Daily Digest

Collections Monitoring

Loan Pipeline Monitoring

Portfolio Risk Monitoring

Staff Productivity Monitoring

Recommendations Engine

AI Inbox

Dashboard Widgets

Excluded:

Chat interface

Autonomous actions

Loan approval decisions

Automatic transaction posting

Automatic member communications

The AI acts only as an analyst and recommendation engine.
