ournal Entry Advanced Filtering, Search & Reporting System (FINAL)
1. Overview

This module transforms Journal Entries from a passive ledger into an audit-grade financial exploration system with:

Deep filtering
Full-text search
Drill-down audit tracing
Report generation
Saved filter views
Automated test coverage (unit + E2E)
2. Core Objective

Enable accountants to:

Instantly locate any journal entry
Investigate financial activity across modules
Generate audit-ready reports
Reproduce results reliably across sessions
3. Functional Scope
3.1 Journal Entry Filtering Engine

Filters supported:

Date range (mandatory)
Account (GL / member / external bank)
Branch
Entry type (manual, system, interest, fees, reversal, adjustment)
Status (posted, pending, reversed)
Amount range
Reference number
Source module (loans, deposits, external banking, manual)
Created by user
Template used
Has attachments
Inter-branch entries
3.2 Search Engine

Supports:

Full-text search (PostgreSQL tsvector)
Reference number lookup
Member/account name search
Partial matching
3.3 Audit Drill-Down View

Each Journal Entry includes:

Header metadata
Entry lines (debit/credit)
Source module link
Event history:
created
updated
reversed
Immutable audit trail
3.4 Reporting Engine
Standard Reports
Trial Balance
General Ledger
Journal Summary
Reversal Report
Adjustment Report
Custom Reports

Any filter combination → exportable as:

PDF
CSV
XLSX (optional)
3.5 Saved Filters (Views)

Users can:

Save filter sets
Reuse filters
Share filters (role-based permissions)
Set default views

Stored as JSON schema.

4. Data Model Enhancements
JournalEntry
entry_date
posted_at
branch_id
status
entry_type
source_module
reference_number
reversed_at
reversal_of_id
Indexing Requirements
composite index: (entry_date, branch_id)
index: account_id via JournalEntryLine
full-text index: description + reference_number
index: status + entry_type
5. Architecture
5.1 Services
JournalEntryQueryService
Builds scoped queries
Handles filter combinations
Ensures query optimization
JournalEntrySearchService
Full-text search
Reference lookup
Fuzzy matching (future)
JournalReportService
Generates:
Trial Balance
Ledger reports
Exports PDF/CSV/XLSX
SavedFilterService
Stores filter JSON
Validates schema
Applies saved views
6. UI Requirements (Hotwire / Rails 8)
Journal Entry Explorer

Layout:

Left: Filters panel (Turbo Frame)
Center: Entries table
Right: Detail drawer (Turbo Stream)

Features:

Live filtering (no page reload)
Pagination (keyset preferred)
Export button (context-aware)
Saved filter dropdown
7. UNIT TESTS (RSpec)
7.1 JournalEntryQueryService Spec
RSpec.describe JournalEntryQueryService do
  let!(:branch) { create(:branch) }
  let!(:account) { create(:account) }

  describe "#call" do
    it "filters by date range" do
      entry1 = create(:journal_entry, entry_date: 5.days.ago)
      entry2 = create(:journal_entry, entry_date: 2.days.ago)

      result = described_class.new(
        start_date: 3.days.ago,
        end_date: Time.current
      ).call

      expect(result).to include(entry2)
      expect(result).not_to include(entry1)
    end

    it "filters by branch" do
      b1 = create(:branch)
      b2 = create(:branch)

      entry1 = create(:journal_entry, branch: b1)
      entry2 = create(:journal_entry, branch: b2)

      result = described_class.new(branch_id: b1.id).call

      expect(result).to include(entry1)
      expect(result).not_to include(entry2)
    end

    it "filters by entry type" do
      system_entry = create(:journal_entry, entry_type: "system")
      manual_entry = create(:journal_entry, entry_type: "manual")

      result = described_class.new(entry_type: "manual").call

      expect(result).to include(manual_entry)
      expect(result).not_to include(system_entry)
    end
  end
end
7.2 JournalEntrySearchService Spec
RSpec.describe JournalEntrySearchService do
  it "finds entry by reference number" do
    entry = create(:journal_entry, reference_number: "JV-2026-001")

    result = described_class.new(query: "JV-2026").call

    expect(result).to include(entry)
  end

  it "finds entry by description text" do
    entry = create(:journal_entry, description: "Loan disbursement")

    result = described_class.new(query: "disbursement").call

    expect(result).to include(entry)
  end
end
7.3 SavedFilterService Spec
RSpec.describe SavedFilterService do
  it "stores filter configuration as JSON" do
    user = create(:user)

    filter = described_class.create!(
      user: user,
      name: "Month End",
      filters: { start_date: "2026-01-01", end_date: "2026-01-31" }
    )

    expect(filter.filters["start_date"]).to eq("2026-01-01")
  end
end
8. E2E TESTS (Playwright)
8.1 Journal Entry Filtering Flow
import { test, expect } from '@playwright/test';

test('accountant filters journal entries by date and branch', async ({ page }) => {
  await page.goto('/journal_entries');

  await page.fill('[data-testid="start-date"]', '2026-01-01');
  await page.fill('[data-testid="end-date"]', '2026-01-31');

  await page.selectOption('[data-testid="branch-filter"]', 'Main Branch');

  await page.click('[data-testid="apply-filters"]');

  await expect(page.locator('[data-testid="journal-row"]')).toBeVisible();

  const rows = await page.locator('[data-testid="journal-row"]').count();
  expect(rows).toBeGreaterThan(0);
});
8.2 Search Flow
test('search journal entry by reference number', async ({ page }) => {
  await page.goto('/journal_entries');

  await page.fill('[data-testid="search-box"]', 'JV-2026');
  await page.press('[data-testid="search-box"]', 'Enter');

  await expect(page.locator('text=JV-2026')).toBeVisible();
});
8.3 Drill-down Audit View
test('open journal entry audit trail', async ({ page }) => {
  await page.goto('/journal_entries');

  await page.click('[data-testid="journal-row"]:first-child');

  await expect(page.locator('[data-testid="audit-trail"]')).toBeVisible();
  await expect(page.locator('text=Created')).toBeVisible();
});
8.4 Export Report Flow
test('export filtered journal entries as CSV', async ({ page }) => {
  await page.goto('/journal_entries');

  await page.click('[data-testid="export-csv"]');

  const download = await page.waitForEvent('download');
  expect(download.suggestedFilename()).toContain('.csv');
});
9. Performance Requirements
1M+ entries supported
Filter response < 500ms
Search < 300ms (indexed)
Pagination via keyset pagination (no offset scans)
10. Security Rules
No deletion of journal entries
Reversal requires audit logging
All exports logged with:
user_id
filter parameters
timestamp
11. Acceptance Criteria

System is complete when:

Accountant can locate any entry in < 10 seconds
All filters are combinable without breaking performance
Reports match filtered dataset exactly
Drill-down shows full audit history
All unit + E2E tests pass in CI
12. Key Design Principle

“Every journal entry must be traceable, searchable, and explainable without needing database access.”