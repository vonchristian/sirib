# UI Improvement Plan — UXDA-inspired

Based on [UXDA Banking Back-Office Transformation Case Study](https://theuxda.com/blog/banking-back-office-transformation-ux-case-study)

## Principles Applied

1. **Information at a glance** — dashboards show what matters, not everything
2. **Reduce cognitive load** — less clutter, clearer hierarchy, progressive disclosure
3. **Data visualization over raw tables** — charts reveal patterns; tables are for detail
4. **Employee-centric flows** — organized by what users do, not by system modules
5. **Modern, emotionally engaging design** — color, spacing, micro-interactions

---

## Improvement Items

### 1. Dashboard — Wire Real KPI Data (High)

**Problem:** All 4 KPI cards show em-dashes (`—`). The dashboard is the first thing employees see — it must reflect real cooperative health.

**UXDA principle:** Information at a glance; emotional engagement (employees feel informed).

**Action:** Query real counts in `DashboardController` and render them:
- Active Loans → `Lending::Loan.active.count`
- Pending Disbursement → `Lending::LoanApplication.submitted.count`
- Today's Collections → sum of payments posted today
- Total Members → `Member.count`

---

### 2. Dashboard — Replace Hardcoded Panels with Real Data (High)

**Problem:** Pending Tasks, Recent Activity, Today's Schedule, and Productivity panels are all static HTML.

**UXDA principle:** Employee-centric; reduce friction by showing what's actionable.

**Action:**
- Tasks: Query actual pending tasks from a tasks model or derived from application state
- Activity: Query recent transactions/events across the system
- Schedule: Query from a calendar/events model or remove if not populated

---

### 3. Table Pagination — Members & Loan Applications (High)

**Problem:** Both list views grow unbounded. No pagination means slow loads and impossible scanning.

**UXDA principle:** Reduce cognitive load — show bite-sized chunks.

**Action:** Add `pagy` or `kaminari` pagination to:
- `app/views/members/index.html.erb`
- `app/views/loans/applications/index.html.erb`

---

### 4. Data Visualization — Balance Sheet Composition Chart (Medium)

**Problem:** Balance sheet is a single tall table with hundreds of rows. No visual sense of proportion.

**UXDA principle:** Data visualization over raw tables.

**Action:** Add a CSS-only donut/pie chart (conic-gradient) showing Asset / Liability / Equity split at a glance, above the table.

---

### 5. Summary Stats Bar — Loan Applications Index (Medium)

**Problem:** Users must scan the full table to understand the application pipeline.

**UXDA principle:** Information at a glance.

**Action:** Add a row of stat cards above the table: Total Applications, Pending Review, Approved Today, Total Amount.

---

### 6. Summary Strip — Members Index (Medium)

**Problem:** No sense of cooperative membership at the top.

**UXDA principle:** Emotional engagement; context before detail.

**Action:** Add member count + gender breakdown strip above the table.

---

### 7. Savings Account — Balance Trend Sparkline (Medium)

**Problem:** Account show page shows current balance but no trend context.

**UXDA principle:** Information at a glance.

**Action:** Add a CSS-only mini bar chart (bar-in-a-cell pattern) showing last 7 days of balance movement next to the balance.

---

### 8. Loading & Skeleton States (Low)

**Problem:** No visual feedback while data loads (especially Turbo Stream screens like balance sheet).

**UXDA principle:** Emotional engagement; reduce uncertainty.

**Action:** Add `animate-pulse` skeleton placeholders for data-heavy regions.
