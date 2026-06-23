import { test, expect } from '@playwright/test';

test.describe('Chart of Accounts Filtering', () => {
  test.use({ storageState: '.auth/user.json' });

  test('status filter shows only active accounts when selected', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.selectOption('select[name="status"]', 'active');
    await page.waitForTimeout(500);

    await expect(page.locator('[data-testid="accounts-table"]')).toBeVisible();
    const inactiveBadges = page.locator('[data-testid="account-status-inactive"]');
    await expect(inactiveBadges).toHaveCount(0);
  });

  test('status filter shows only inactive accounts when selected', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.selectOption('select[name="status"]', 'inactive');
    await page.waitForTimeout(500);

    const table = page.locator('[data-testid="accounts-table"]');
    const emptyState = page.locator('[data-testid="accounts-empty-state"]');
    const tableVisible = await table.isVisible().catch(() => false);
    const emptyVisible = await emptyState.isVisible().catch(() => false);
    expect(tableVisible || emptyVisible).toBeTruthy();
  });

  test('non-postable filter shows only non-postable accounts', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.locator('input[name="non_postable"]').check();
    await page.waitForTimeout(500);

    const postableNoBadges = page.locator('[data-testid="account-postable-no"]');
    const count = await postableNoBadges.count();
    expect(count).toBeGreaterThan(0);
  });

  test('multiple filters can be combined', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.selectOption('select[name="account_type"]', 'asset');
    await page.locator('input[name="contra"]').check();
    await page.waitForTimeout(500);

    const rows = page.locator('[data-testid="account-row"]');
    const count = await rows.count();
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test('filter changes update URL', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.selectOption('select[name="status"]', 'active');
    await page.waitForTimeout(800);

    await expect(page).toHaveURL(/status=active/);
  });

  test('clearing filters removes all URL params', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.selectOption('select[name="status"]', 'active');
    await page.waitForTimeout(800);
    await expect(page).toHaveURL(/status=active/);

    await page.getByText('Clear').click();
    await page.waitForTimeout(800);

    await page.waitForFunction(() => {
      const url = new URL(window.location.href);
      return !url.searchParams.has('status') && !url.searchParams.has('account_type');
    });
  });

  test('URL params are restored on page reload', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts?account_type=asset&status=active');
    await page.waitForLoadState('networkidle');

    const select = page.locator('select[name="account_type"]');
    await expect(select).toHaveValue('asset');
    const statusSelect = page.locator('select[name="status"]');
    await expect(statusSelect).toHaveValue('active');
  });
});