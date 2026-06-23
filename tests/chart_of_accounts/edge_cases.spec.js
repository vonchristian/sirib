import { test, expect } from '@playwright/test';

test.describe('Chart of Accounts Edge Cases', () => {
  test.use({ storageState: '.auth/user.json' });

  test('searching with no results shows empty state', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const searchInput = page.getByPlaceholder('Search account name, code, or ledger');
    await searchInput.fill('zzzzz_nonexistent');

    await page.waitForTimeout(500);

    await expect(page.getByText('No results found')).toBeVisible();
  });

  test('searching with short query shows no results dropdown', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const searchInput = page.getByPlaceholder('Search account name, code, or ledger');
    await searchInput.fill('a');

    await page.waitForTimeout(500);

    await expect(page.locator('[data-chart-of-accounts-target="searchResults"].hidden')).toBeAttached();
  });

  test('pressing escape closes search results', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const searchInput = page.getByPlaceholder('Search account name, code, or ledger');
    await searchInput.fill('Cash');
    await page.waitForTimeout(500);

    await expect(page.getByText('Cash on Hand')).toBeVisible();

    await searchInput.press('Escape');
    await page.waitForTimeout(100);

    await expect(page.locator('[data-chart-of-accounts-target="searchResults"]')).toHaveClass(/hidden/);
  });

  test('filtering by contra shows empty when no contra accounts exist', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.locator('input[name="contra"]').check();
    await page.waitForTimeout(300);

    await expect(page.getByText('No accounts found')).toBeVisible();
  });

  test('clicking account code link navigates to show page', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const accountLink = page.locator('table tbody tr a').filter({ hasText: '11110' });
    await accountLink.click();
    await page.waitForLoadState('networkidle');

    await expect(page).toHaveURL(/\/accounting\/accounts\/\d+/);
  });
});
