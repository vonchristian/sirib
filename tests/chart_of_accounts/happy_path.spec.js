import { test, expect } from '@playwright/test';

test.describe('Chart of Accounts Happy Path', () => {
  test.use({ storageState: '.auth/user.json' });

  test('renders the workbench page', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await expect(page.getByText('Chart of Accounts')).toBeVisible();
    await expect(page.getByPlaceholder('Search account name, code, or ledger')).toBeVisible();
    await expect(page.getByText('Filters')).toBeVisible();
  });

  test('does not show tree panel', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await expect(page.getByText('Ledger Tree')).not.toBeVisible();
  });

  test('displays accounts sorted by code', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const codes = await page.$$eval('table tbody tr td:first-child', els =>
      els.map(el => el.textContent.trim())
    );
    const sorted = [...codes].sort();
    expect(codes).toEqual(sorted);
  });

  test('displays accounts in the table', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await expect(page.getByText('11110')).toBeVisible();
    await expect(page.getByText('21120')).toBeVisible();
  });

  test('searching for an account by partial name shows results', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const searchInput = page.getByPlaceholder('Search account name, code, or ledger');
    await searchInput.fill('Cash');

    await page.waitForTimeout(500);

    await expect(page.getByText('Cash on Hand')).toBeVisible();
  });

  test('clicking an account row navigates to show page', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.getByText('11110').first().click();
    await page.waitForLoadState('networkidle');

    await expect(page).toHaveURL(/\/accounting\/accounts\/\d+/);
    await expect(page.getByText('Current Balance')).toBeVisible();
  });

  test('filtering by account type updates the table', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.selectOption('select[name="account_type"]', 'liability');
    await page.waitForTimeout(300);

    await expect(page.getByText('21120')).toBeVisible();
    await expect(page.getByText('Time Deposits')).toBeVisible();
  });

  test('clearing filters resets the table', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.selectOption('select[name="account_type"]', 'liability');
    await page.waitForTimeout(300);

    await page.getByText('Clear').click();
    await page.waitForTimeout(300);

    await expect(page.getByText('11110')).toBeVisible();
    await expect(page.getByText('21120')).toBeVisible();
  });
});
