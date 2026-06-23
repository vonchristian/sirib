import { test, expect } from '@playwright/test';

test.describe('Journal Entries Filtering', () => {
  test.use({ storageState: '.auth/user.json' });

  test('filters by date range', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.fill('[data-testid="start-date"]', '2026-01-01');
    await page.fill('[data-testid="end-date"]', '2026-01-31');
    await page.click('[data-testid="apply-filters"]');
    await page.waitForLoadState('networkidle');
    await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
  });

  test('filters by branch', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.selectOption('[data-testid="branch-filter"]', { index: 1 });
    await page.waitForLoadState('networkidle');
    await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
  });

  test('filters by entry type', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.selectOption('select[name="entry_type"]', 'manual_entry');
    await page.waitForLoadState('networkidle');
  });

  test('filters by status', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.selectOption('select[name="status"]', 'posted');
    await page.waitForLoadState('networkidle');
    await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
  });

  test('filters by source module', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.selectOption('select[name="source_module"]', 'loans');
    await page.waitForLoadState('networkidle');
  });

  test('filters by amount range', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.fill('input[name="amount_min"]', '100');
    await page.fill('input[name="amount_max"]', '10000');
    await page.click('[data-testid="apply-filters"]');
    await page.waitForLoadState('networkidle');
  });

  test('filters by reference number', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.fill('input[name="reference_number"]', 'JV-2026');
    await page.click('[data-testid="apply-filters"]');
    await page.waitForLoadState('networkidle');
  });

  test('reset button clears all filters', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.selectOption('select[name="entry_type"]', 'manual_entry');
    await page.fill('input[name="amount_min"]', '100');
    await page.click('button:has-text("Reset")');
    await page.waitForLoadState('networkidle');
    const selectedType = await page.locator('select[name="entry_type"]').inputValue();
    expect(selectedType).toBe('');
  });

  test('combines multiple filters', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.fill('[data-testid="start-date"]', '2026-01-01');
    await page.fill('[data-testid="end-date"]', '2026-01-31');
    await page.selectOption('select[name="entry_type"]', 'manual_entry');
    await page.selectOption('select[name="status"]', 'posted');
    await page.click('[data-testid="apply-filters"]');
    await page.waitForLoadState('networkidle');
    await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
  });

  test('search box filters entries via text query', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const searchInput = page.locator('input[placeholder="Search entries..."]');
    await searchInput.fill('test');
    await page.press(searchInput, 'Enter');
    await page.waitForLoadState('networkidle');
  });

  test('filter changes submit form automatically via onchange', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.fill('[data-testid="start-date"]', '2026-06-01');
    await page.waitForLoadState('networkidle');
    await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
  });

  test('has attachments checkbox filters entries', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.check('#has_attachments');
    await page.waitForLoadState('networkidle');
  });

  test('inter branch checkbox filters entries', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.check('#inter_branch');
    await page.waitForLoadState('networkidle');
  });

  test('empty search shows all entries', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const searchInput = page.locator('input[placeholder="Search entries..."]');
    await searchInput.fill('');
    await searchInput.press('Enter');
    await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
  });

  test('saved filters panel shows when clicking Save', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.click('button:has-text("+ Save")');
    await expect(page.locator('input[name="filter_name"]')).toBeVisible();
  });

  test('can enter filter name in save panel', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.click('button:has-text("+ Save")');
    await page.fill('input[name="filter_name"]', 'My Test Filter');
    await expect(page.locator('input[name="filter_name"]')).toHaveValue('My Test Filter');
  });

  test('saved filters section is visible', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await expect(page.getByText('Saved Filters')).toBeVisible();
  });
});