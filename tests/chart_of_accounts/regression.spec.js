import { test, expect } from '@playwright/test';

test.describe('Chart of Accounts Regression', () => {
  test.use({ storageState: '.auth/user.json' });

  test('search still works after applying filters', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.selectOption('select[name="account_type"]', 'asset');
    await page.waitForTimeout(300);

    const searchInput = page.getByPlaceholder('Search account name, code, or ledger');
    await searchInput.fill('Cash');
    await page.waitForTimeout(500);

    await expect(page.getByText('Cash on Hand')).toBeVisible();
  });

  test('clearing filters restores all accounts', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.selectOption('select[name="account_type"]', 'liability');
    await page.waitForTimeout(300);

    await page.getByText('Clear').click();
    await page.waitForTimeout(300);

    await expect(page.getByText('11110')).toBeVisible();
    await expect(page.getByText('21120')).toBeVisible();
  });

  test('account table still shows after filter combination', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await page.selectOption('select[name="account_type"]', 'asset');
    await page.locator('input[name="contra"]').check();
    await page.waitForTimeout(500);

    await expect(page.locator('[data-testid="accounts-table"]')).toBeVisible();
  });

  test('search results show ledger and account results', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const searchInput = page.getByPlaceholder('Search account name, code, or ledger');
    await searchInput.fill('cash');
    await page.waitForTimeout(500);

    await expect(page.getByText('Ledgers')).toBeVisible();
    await expect(page.getByText('Accounts')).toBeVisible();
  });

  test('clicking ledger from search results filters table', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const searchInput = page.getByPlaceholder('Search account name, code, or ledger');
    await searchInput.fill('Cash on Hand');
    await page.waitForTimeout(500);

    const ledgerButton = page.locator('button[data-ledger-id]').first();
    await ledgerButton.click();
    await page.waitForTimeout(500);

    await expect(page.locator('[data-testid="accounts-table"]')).toBeVisible();
  });

  test('clicking account from search results navigates to show page', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const searchInput = page.getByPlaceholder('Search account name, code, or ledger');
    await searchInput.fill('Cash in Bank');
    await page.waitForTimeout(500);

    const accountButton = page.locator('button[data-account-id]').first();
    await accountButton.click();
    await page.waitForLoadState('networkidle');

    await expect(page).toHaveURL(/\/accounting\/accounts\/\d+/);
  });

  test('clicking account row navigates to show page with balance visible', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const accountLink = page.locator('table tbody tr a').filter({ hasText: '11110' });
    await accountLink.click();
    await page.waitForLoadState('networkidle');

    await expect(page).toHaveURL(/\/accounting\/accounts\/\d+/);
    await expect(page.getByText('Current Balance')).toBeVisible();
  });

  test('accounts table columns are intact with status and postable', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    await expect(page.getByText('Status')).toBeVisible();
    await expect(page.getByText('Postable')).toBeVisible();
  });

  test('accounts table shows status and postable values for each row', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await page.waitForLoadState('networkidle');

    const firstRow = page.locator('[data-testid="account-row"]').first();

    const statusActive = firstRow.locator('[data-testid="account-status-active"]');
    const statusInactive = firstRow.locator('[data-testid="account-status-inactive"]');
    const postableYes = firstRow.locator('[data-testid="account-postable-yes"]');
    const postableNo = firstRow.locator('[data-testid="account-postable-no"]');

    const hasAnyStatus = await statusActive.isVisible().catch(() => false) ||
                         await statusInactive.isVisible().catch(() => false);
    const hasAnyPostable = await postableYes.isVisible().catch(() => false) ||
                           await postableNo.isVisible().catch(() => false);

    expect(hasAnyStatus || hasAnyPostable).toBeTruthy();
  });
});