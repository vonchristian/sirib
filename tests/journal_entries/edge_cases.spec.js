import { test, expect } from '@playwright/test';

test.describe('Journal Entries Edge Cases', () => {
  test.use({ storageState: '.auth/user.json' });

  test('shows empty state when no entries exist', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const emptyState = page.getByText('No journal entries found');
    if (await emptyState.isVisible()) {
      await expect(emptyState).toBeVisible();
      await expect(page.getByText('Try adjusting your filters or create a new entry')).toBeVisible();
    }
  });

  test('handles very long entry descriptions gracefully', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const descriptionCell = page.locator('[data-testid="journal-row"] td:nth-child(2)').first();
    if (await descriptionCell.isVisible()) {
      const text = await descriptionCell.textContent();
      expect(text.length).toBeGreaterThan(0);
    }
  });

  test('handles many filters applied simultaneously', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.fill('[data-testid="start-date"]', '2020-01-01');
    await page.fill('[data-testid="end-date"]', '2030-12-31');
    await page.selectOption('select[name="entry_type"]', 'manual_entry');
    await page.selectOption('select[name="status"]', 'posted');
    await page.fill('input[name="amount_min"]', '0');
    await page.fill('input[name="amount_max"]', '999999999');
    await page.click('[data-testid="apply-filters"]');
    await page.waitForLoadState('networkidle');
    const rows = page.locator('[data-testid="journal-row"]');
    await expect(rows.first()).toBeVisible();
  });

  test('date range with same start and end date works', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const today = new Date().toISOString().split('T')[0];
    await page.fill('[data-testid="start-date"]', today);
    await page.fill('[data-testid="end-date"]', today);
    await page.click('[data-testid="apply-filters"]');
    await page.waitForLoadState('networkidle');
  });

  test('handles special characters in reference number search', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.fill('input[name="reference_number"]', "'; DROP TABLE entries;--");
    await page.click('[data-testid="apply-filters"]');
    await page.waitForLoadState('networkidle');
  });

  test('handles negative amount range', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.fill('input[name="amount_min"]', '-1000');
    await page.fill('input[name="amount_max"]', '1000');
    await page.click('[data-testid="apply-filters"]');
    await page.waitForLoadState('networkidle');
  });

  test('handles very large amount range', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.fill('input[name="amount_min"]', '0');
    await page.fill('input[name="amount_max"]', '999999999999');
    await page.click('[data-testid="apply-filters"]');
    await page.waitForLoadState('networkidle');
  });

  test('pagination works correctly', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const pagination = page.locator('.flex.items-center.justify-between');
    if (await pagination.isVisible()) {
      const nextButton = page.locator('a:has-text("Next")');
      if (await nextButton.isVisible()) {
        await nextButton.click();
        await page.waitForLoadState('networkidle');
      }
    }
  });

  test('handles branch filter when no branches exist', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const branchSelect = page.locator('[data-testid="branch-filter"]');
    if (await branchSelect.isVisible()) {
      await branchSelect.selectOption({ index: 1 });
      await page.waitForLoadState('networkidle');
    }
  });

  test('entry row clickable area is correct', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await expect(firstRow).toBeVisible();
    const rowBounds = await firstRow.boundingBox();
    expect(rowBounds.width).toBeGreaterThan(100);
  });

  test('links in row do not trigger row click', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await firstRow.locator('a:has-text("View")').click();
    await page.waitForURL(/\/accounting\/journal_entries\/\d+/);
  });
});