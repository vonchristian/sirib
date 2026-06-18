🧠 CORE BANKING APPLICATION SHELL — OPENCODE IMPLEMENTATION PRD
1. PROJECT OVERVIEW

Build a Core Banking Application Shell with a 3-pane AI-native layout:

Layout
Left Sidebar (Navigation / Control Plane)
Main Content (Banking Workbench / Execution Plane)
Right Sidebar (AI Banking Copilot / Intelligence Plane)

This is a production banking system shell, not a UI prototype.

2. TECH STACK ASSUMPTION

Generate code assuming:

Backend: Ruby on Rails 8
Frontend: Hotwire (Turbo + Stimulus)
UI styling: Tailwind CSS
Realtime: Turbo Streams
Background jobs: Solid Queue
AI integration: OpenAI-compatible API wrapper service
3. FOLDER STRUCTURE (MANDATORY OUTPUT TARGET)

Generate this structure:

app/
  controllers/
  models/
  services/
    ai/
      context_builder.rb
      prompt_builder.rb
      banking_copilot_service.rb
      action_router.rb
    banking/
      transaction_service.rb
      cash_session_service.rb
      ledger_service.rb
      risk_service.rb
  views/
    layouts/
      application.html.erb
    shell/
      _sidebar.html.erb
      _main.html.erb
      _ai_sidebar.html.erb
  javascript/
    controllers/
      ai_sidebar_controller.js
      sidebar_controller.js
      transaction_form_controller.js
4. APPLICATION SHELL (CORE UI LAYOUT)
Layout File: application.html.erb

Must implement:

3-Pane Structure
<div class="flex h-screen w-screen overflow-hidden">

  <!-- LEFT SIDEBAR -->
  <div class="w-64 bg-gray-900 text-white flex-shrink-0">
    <%= render "shell/sidebar" %>
  </div>

  <!-- MAIN CONTENT -->
  <div class="flex-1 overflow-y-auto bg-gray-50">
    <%= render "shell/main" %>
  </div>

  <!-- RIGHT AI SIDEBAR -->
  <div class="w-96 border-l bg-white flex flex-col">
    <%= render "shell/ai_sidebar" %>
  </div>

</div>
5. LEFT SIDEBAR (NAVIGATION SYSTEM)
Requirements

Implement:

Module navigation
Role-based visibility
Active cash session indicator
Notification badges
Collapsible state (Stimulus controlled)
Modules

Hardcode structure initially:

Dashboard
Cash Sessions
Accounts
Loans
Deposits
Shares
Reports
Audit Logs
Settings
Must include:
Active module highlight
Role-based filtering
Cash session status badge:
OPEN
CLOSED
BALANCING
6. MAIN CONTENT AREA (WORKBENCH ENGINE)

This is a dynamic render zone.

Requirements:
Must support Turbo Frame routing
Must support nested views
Must support multi-step workflows
Example routes:
/cash_sessions/current
/accounts/:id
/loans/:id
/transactions/new
/reports/eod
MUST SUPPORT:
Transaction forms
Account ledgers
Loan workflows
Approval screens
7. RIGHT SIDEBAR (AI BANKING COPILOT)

This is the core differentiator system

AI SIDEBAR UI STRUCTURE
AI HEADER
- Context indicator (screen + role)

CHAT WINDOW
- messages list

SUGGESTED ACTIONS
- buttons

SYSTEM INSIGHTS
- warnings
- anomalies
- risk flags

INPUT BOX
AI CONTEXT INPUT (CRITICAL)

Every request to AI MUST include:

context = {
  user_role: "teller",
  current_route: "/cash_sessions/current",
  selected_entity: {
    type: "account",
    id: 123
  },
  cash_session_id: 45,
  timestamp: Time.current
}
AI FEATURES
1. Explain
explain transaction
explain account balance
explain loan risk
2. Validate
validate transaction correctness
detect missing fields
detect suspicious patterns
3. Suggest
suggest next action
suggest corrections
suggest risk mitigation
AI SERVICE FLOW
User Message
   ↓
Context Builder
   ↓
Prompt Builder
   ↓
LLM API Call
   ↓
Response Parser
   ↓
Action Router
   ↓
UI Render (chat + buttons)
8. BANKING CORE SERVICES
TransactionService

Must implement:

debit/credit validation
idempotency key support
ledger posting
cash session binding
CashSessionService

Rules:

One active session per teller per day
All transactions MUST belong to session
Session must be OPEN before transactions allowed
LedgerService

Must implement:

double-entry accounting
immutable journal entries
audit trail generation
RiskService

Must implement:

simple rule-based scoring initially
AI augmentation later
flags:
large amount deviation
unusual frequency
overdraft risk
9. STATE MANAGEMENT (FRONTEND)

Use Stimulus controllers:

UI State
sidebar_state
ai_sidebar_state
selected_entity_state
Banking State
active_cash_session
current_user_role
transaction_context
10. AI ACTION ROUTER (CRITICAL SAFETY LAYER)

AI responses MUST NOT directly mutate data.

Instead:

AI Response → Suggested Action Object → User Confirmation → Backend Execution

Example:

{
  "type": "suggested_action",
  "action": "validate_transaction",
  "payload": {
    "transaction_id": 123
  }
}
11. SECURITY RULES (NON-NEGOTIABLE)

Implement:

RBAC check on every request
Cash session validation on transactions
Audit log on every mutation
AI responses are NEVER trusted as source of truth
All writes go through service layer only
12. TURBO STREAM EVENTS

Must support real-time updates:

new_transaction
session_updated
ai_alert_generated
ledger_posted
13. MVP IMPLEMENTATION ORDER (FOR OPENCODE)
Application shell layout (3 panes)
Sidebar navigation
Main routing (Turbo Frames)
Cash session service
Transaction service
Ledger service
AI sidebar UI
AI context builder
AI prompt builder
AI action router
Audit logging
14. ACCEPTANCE CRITERIA

System is complete when:

UI renders 3-pane layout correctly
Sidebar navigation works
Main panel loads banking modules
AI sidebar responds with context awareness
Transactions require cash session
Ledger entries are immutable
All actions are audited
AI suggestions do NOT directly mutate state
15. KEY ARCHITECTURE IDEA

This system is:

A Banking Operating System UI with an embedded AI control layer

Not a dashboard.

Not a CRUD app.

A real-time financial operations console.