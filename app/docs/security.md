Technical Implementation Blueprint
Rails 8 Cooperative Banking Platform

Version: 1.0

Audience

Senior Rails Engineers

Security Engineers

OpenCode AI

Architecture
Rails 8
│
├── Authentication
├── Authorization
├── Audit
├── Security
├── Monitoring
├── Fraud Detection
├── Encryption
├── Compliance
└── Infrastructure

Every module should be isolated.

app/
    domains/
        security/
        audit/
        authentication/
        authorization/
        compliance/
        fraud/
Security Layers
Browser

↓

NGINX

↓

Rack Middleware

↓

Rails Security Middleware

↓

Authentication

↓

Authorization

↓

Controllers

↓

Policies

↓

Services

↓

Models

↓

Database

↓

Encrypted Storage

Every request passes every layer.

1 Authentication
Database
users

password_digest

failed_attempts

locked_at

password_changed_at

last_login_at

last_login_ip

last_seen_at

last_device

mfa_enabled

mfa_secret

remember_created_at

force_password_change

session_version
Password Policy Engine

Create

Security::PasswordPolicy

Responsible for

Minimum length

Uppercase

Lowercase

Numbers

Symbols

Dictionary words

Password history

Expiration

Login Flow
Email

↓

Password

↓

Account Locked?

↓

Password Expired?

↓

MFA Required?

↓

Create Session

↓

Audit Log

↓

Dashboard
Session Security

Store

IP

Browser

Platform

Location

Session ID

Created

Last Activity

Idle timeout

Absolute timeout

Concurrent session detection

Force logout

Device management

2 MFA

Support

TOTP

Recovery Codes

Email OTP

SMS OTP (future)

WebAuthn (future)

Models

UserMfaDevice

RecoveryCode
3 Authorization

Never use

if current_user.admin?

Instead

Pundit

Role

Permission

Policy

Scope

Permission model

Role

↓

Permissions

↓

Feature

↓

Action

↓

Policy

↓

Record

Example

Loan

Approve

Branch

Maximum Amount

Required Role
Dynamic Permissions

Tables

roles

permissions

role_permissions

user_roles

Permission examples

loan.approve

loan.view

loan.release

savings.withdraw

cash.deposit

member.edit
Branch Isolation

Every query

current_branch

Automatically scoped

Never manually filter

Record Security

Every model

ApplicationRecord

↓

SecurityScope

↓

Branch Scope

↓

Soft Delete Scope
4 Encryption

Rails Active Record Encryption

Encrypt

National ID

TIN

Birthdate

Phone

Email

Passport

Collateral Serial Numbers

Never encrypt

Foreign keys

Indexes

Frequently searched columns

Use deterministic encryption when searchable.

Secrets

Rails Credentials

Environment Variables

No secrets in source code

Secret rotation

Master key rotation

5 Audit Trail

Most banking systems fail here.

Need immutable logs.

Create

AuditLog

Columns

who

when

where

what

old_value

new_value

request_id

ip

browser

device

reason

approval_chain

Audit every

Create

Update

Delete

Approval

Reject

Export

Print

Login

Logout

Permission changes

Interest posting

Loan release

Cash withdrawal

Deposit

Never allow

update audit_logs
delete audit_logs

Only insert.

Event Bus

Everything emits events.

LoanApproved

↓

Event

↓

Audit

↓

Notification

↓

Fraud Detection

↓

Analytics

Use

ActiveSupport::Notifications
6 Logging

Use

Structured JSON Logs

Every request includes

request_id

user_id

branch_id

device

ip

latency

controller

action

Sensitive data filtered.

7 CSRF

Every controller

protect_from_forgery

API

JWT

No session cookies.

8 Security Headers

Middleware

Automatically inject

HSTS

CSP

Frame Options

Referrer Policy

Permissions Policy

X Content Type
9 Input Validation

Layer 1

Browser

Layer 2

Controller

Layer 3

Model

Layer 4

Database Constraint

Never trust client validation.

File Upload

Pipeline

Upload

↓

Content Type

↓

Extension

↓

Virus Scan

↓

Magic Bytes

↓

Rename

↓

Encrypt

↓

Store

Never trust extension.

SQL Injection

Never

where("name = #{params[:name]}")

Always

where(name: ...)
XSS

Sanitize

Rich text

Notes

Comments

Descriptions

Escape by default.

Background Jobs

Every job

Idempotent

Retry

Dead Queue

Audit

Authorization
Rate Limiting

Rack::Attack

Protect

Login

OTP

Password Reset

Public APIs

Fraud Detection Engine

Create

Fraud::Rule

Fraud::Incident

Fraud::Alert

Rules

10 failed logins

Large withdrawal

Night transactions

Impossible travel

Rapid transfers

Multiple IPs

Dormant account activity
Monitoring

Health endpoint

database

redis

solid queue

storage

mail

cache

Metrics

CPU

Memory

Latency

Errors

Queue

DB

Slow Queries
Database Security

Foreign Keys

Check Constraints

Unique Constraints

Indexes

NOT NULL

Transactions

Optimistic Locking

Backup

Nightly

Encrypted

Immutable

Retention

Restore testing

Compliance Engine

Track

Security Control

↓

Evidence

↓

Verification

↓

Reviewer

↓

Expiration

↓

Revalidation
Dashboard

Overall Score

Critical Findings

Security Trends

Failed Controls

Pending Reviews

Compliance Mapping

Scheduled Security Tasks

Solid Queue

Daily

Expired passwords

Expired MFA

Inactive accounts

Security reports

Backup verification

Log integrity

Certificate expiration
Gem Recommendations

Authentication

bcrypt
devise (optional)
rotp
webauthn

Authorization

pundit

Security

rack-attack
brakeman
bundler-audit
strong_migrations

Monitoring

mission_control-jobs

Audit

paper_trail

Uploads

marcel
mini_mime
Testing Requirements

Every feature must include:

Unit tests for security services and policies.
Request specs covering authentication, authorization, CSRF, rate limiting, and validation.
System tests for end-to-end flows (login, MFA, approvals, maker-checker).
Regression tests for every reported security bug.
Authorization tests ensuring users cannot access records outside their branch or permissions.
Security-focused test cases for SQL injection, XSS, mass assignment, IDOR (Insecure Direct Object Reference), file upload validation, and session management.
Performance tests for authentication and authorization under expected production load.
Definition of Done (Security)

A feature cannot be marked complete unless it satisfies all of the following:

Authentication and authorization implemented and tested.
Every sensitive action generates an immutable audit log.
Branch isolation and permission checks enforced.
Input validation exists at controller, model, and database layers.
Sensitive data is encrypted where required.
Security events are logged with structured metadata.
Background jobs are idempotent and authorized.
New endpoints have request specs, authorization tests, and security regression tests.
Static analysis (brakeman, bundler-audit) passes with no unresolved high-severity findings.
Documentation is updated with any new security controls or configuration requirements.

This blueprint gives OpenCode enough architectural guidance to implement a security framework that becomes part of the platform's foundation rather than a collection of isolated security features.