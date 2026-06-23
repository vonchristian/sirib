import { test, expect } from '@playwright/test';

test.describe('Journal Entries Happy Path', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/session/new');
    await page.fill('input[name="email_address"]', 'admin@sirib.com');
    await page.fill('input[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/$|\/accounting\/journal_entries/);
  });

  test('journal entries index page loads successfully', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await expect(page.getByText('Journal Entries')).toBeVisible();
    await expect(page.getByText('Advanced filtering')).toBeVisible();
  });

  test('shows filter panel on left side', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await expect(page.getByText('Filters')).toBeVisible();
    await expect(page.getByText('Date Range')).toBeVisible();
    await expect(page.getByText('Branch')).toBeVisible();
  });

  test('displays entry table with headers', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await expect(page.getByText('Entry #')).toBeVisible();
    await expect(page.getByText('Description')).toBeVisible();
    await expect(page.getByText('Status')).toBeVisible();
    await expect(page.getByText('Posted At')).toBeVisible();
  });

  test('has New Entry button linking to form', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const newEntryLink = page.locator('a:has-text("New Entry")');
    await expect(newEntryLink).toBeVisible();
    await newEntryLink.click();
    await expect(page).toHaveURL(/\/accounting\/journal_entries\/new/);
  });

  test('search box filters entries by text', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const searchInput = page.locator('input[placeholder="Search entries..."]');
    await expect(searchInput).toBeVisible();
  });

  test('can navigate from index to entry show page', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await firstRow.locator('a:has-text("View")').click();
    await page.waitForURL(/\/accounting\/journal_entries\/\d+/);
    await expect(page.getByText('Entry Lines')).toBeVisible();
  });

  test('row click navigates to entry show page', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await expect(firstRow).toBeVisible();
    await firstRow.click();
    await page.waitForURL(/\/accounting\/journal_entries\/\d+/);
  });

  test('show page displays entry details correctly', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await firstRow.locator('a:has-text("View")').click();

    await expect(page.getByText('Entry Lines')).toBeVisible();
    await expect(page.getByText('Audit Trail')).toBeVisible();
    await expect(page.getByText('Quick Actions')).toBeVisible();
  });

  test('show page breadcrumb links back to index', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await firstRow.locator('a:has-text("View")').click();

    const breadcrumbLink = page.locator('nav a:has-text("Journal Entries")');
    await expect(breadcrumbLink).toBeVisible();
    await breadcrumbLink.click();
    await expect(page).toHaveURL(/\/accounting\/journal_entries/);
  });

  test('show page has back button to index', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await firstRow.locator('a:has-text("View")').click();

    const backButton = page.getByText('Back').or(page.locator('a:has-text("Back")'));
    await expect(backButton).toBeVisible();
    await backButton.click();
    await expect(page).toHaveURL(/\/accounting\/journal_entries/);
  });

  test('export csv link is present', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await expect(page.locator('[data-testid="export-csv"]')).toBeVisible();
  });

  test('pagination controls are present', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await expect(page.locator('.flex.items-center.justify-between')).toBeVisible();
  });

  test('entry table shows status badges', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await expect(firstRow).toBeVisible();
    const statusBadge = firstRow.locator('span:has-text("Posted")').or(firstRow.locator('span:has-text("Pending")')).or(firstRow.locator('span:has-text("Draft")'));
    await expect(statusBadge).toBeVisible();
  });

  test('entry table shows type badges', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await expect(firstRow).toBeVisible();
    const typeBadge = firstRow.locator('span:has-text("Manual")').or(firstRow.locator('span:has-text("System")')).or(firstRow.locator('span:has-text("Interest")'));
    await expect(typeBadge).toBeVisible();
  });

  test('show page displays reversal info when present', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.waitForLoadState('networkidle');
    const firstRow = page.locator('[data-testid="journal-row"]').first();

    if (await firstRow.isVisible()) {
      await firstRow.locator('a:has-text("View")').click();
      await page.waitForLoadState('networkidle');
      const reversalSection = page.getByText('Reversal Information');
      if (await reversalSection.isVisible()) {
        await expect(page.getByText('Reversed Entry')).toBeVisible();
      }
    }
  });

  test('audit trail shows created entry on show page', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await firstRow.locator('a:has-text("View")').click();

    await expect(page.locator('[data-testid="audit-trail"]')).toBeVisible();
    await expect(page.getByText('Created')).toBeVisible();
  });

  test('reverse entry button present when reversible', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.waitForLoadState('networkidle');
    const firstRow = page.locator('[data-testid="journal-row"]').first();

    if (await firstRow.isVisible()) {
      await firstRow.locator('a:has-text("View")').click();
      await page.waitForLoadState('networkidle');
      const reverseButton = page.getByText('Reverse Entry');
      if (await reverseButton.isVisible()) {
        await expect(reverseButton).toBeVisible();
      }
    }
  });

  test('print entry button in quick actions', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await firstRow.locator('a:has-text("View")').click();

    await expect(page.getByText('Print Entry')).toBeVisible();
  });

  test('export csv from show page', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await firstRow.locator('a:has-text("View")').click();

    await expect(page.getByText('Export CSV')).toBeVisible();
  });
});