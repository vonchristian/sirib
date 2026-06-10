// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Balance Sheet', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/accounting/balance_sheet');
    await expect(page).toHaveURL(/\/session\/new/);
  });


  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('shows filter bar with date picker and comparison dropdown', async ({ page }) => {
      await page.goto('/accounting/balance_sheet');
      await expect(page.locator('input[name="as_of_date"]')).toBeVisible();
      await expect(page.locator('select[name="comparison"]')).toBeVisible();
    });

    test('displays all three sections', async ({ page }) => {
      await page.goto('/accounting/balance_sheet');
      await expect(page.locator('text=ASSETS').first()).toBeVisible();
      await expect(page.locator('text=LIABILITIES').first()).toBeVisible();
      await expect(page.locator('text=EQUITY').first()).toBeVisible();
    });

    test('shows all accounts including zero-balance accounts', async ({ page }) => {
      await page.goto('/accounting/balance_sheet');
      await expect(page.locator('text=Cash on Hand').first()).toBeVisible();
      await expect(page.locator('text=PNB Savings Account').first()).toBeVisible();
      await expect(page.locator('text=Loans Receivable — Current').first()).toBeVisible();
    });

    test('shows chart of accounts hierarchy with nested child ledgers', async ({ page }) => {
      await page.goto('/accounting/balance_sheet');
      await expect(page.locator('text=Cash and Cash Equivalents').first()).toBeVisible();
      await expect(page.locator('text=Cash in Bank').first()).toBeVisible();
      await expect(page.locator('text=PNB Savings Account').first()).toBeVisible();
      await expect(page.locator('text=LandBank Account 001').first()).toBeVisible();
      await expect(page.locator('text=Loans and Receivables').first()).toBeVisible();
      await expect(page.locator('text=Loans Receivable — Current').first()).toBeVisible();
    });

    test('displays ledger code prefix next to ledger name', async ({ page }) => {
      await page.goto('/accounting/balance_sheet');
      await expect(page.locator('text=11100').first()).toBeVisible();
      await expect(page.locator('text=11130').first()).toBeVisible();
      await expect(page.locator('text=21100').first()).toBeVisible();
      await expect(page.locator('text=30100').first()).toBeVisible();
    });

    test('marks contra accounts with badge and parentheses', async ({ page }) => {
      await page.goto('/accounting/balance_sheet');
      const contraBadges = page.locator('text=contra');
      const count = await contraBadges.count();
      expect(count).toBeGreaterThanOrEqual(5);
      await expect(page.locator('text=Allowance for Probable Losses').first()).toBeVisible();
      await expect(page.locator('text=Accumulated Depreciation').first()).toBeVisible();
    });

    test('shows Chart of Accounts Legend', async ({ page }) => {
      await page.goto('/accounting/balance_sheet');
      await expect(page.getByText('Chart of Accounts Legend')).toBeVisible();
      await expect(page.locator('text=Asset').last()).toBeVisible();
      await expect(page.locator('text=Liability').last()).toBeVisible();
      await expect(page.locator('text=Equity').last()).toBeVisible();
      await expect(page.getByText(/contra account/i).last()).toBeVisible();
    });

    test('shows comparative period indicator when comparison is selected', async ({ page }) => {
      await page.goto('/accounting/balance_sheet?comparison=prior_year');
      await expect(page.getByText(/comparative period/i).first()).toBeVisible();
      await expect(page.locator('th').nth(2)).toBeVisible();
    });

    test('shows three column headers when comparison is selected', async ({ page }) => {
      await page.goto('/accounting/balance_sheet?comparison=prior_year');
      const headers = page.locator('table thead th');
      expect(await headers.count()).toBe(3);
    });

    test('filtering with date changes the subtitle', async ({ page }) => {
      await page.goto('/accounting/balance_sheet?as_of_date=2025-01-15');
      await expect(page.locator('text=January 15, 2025').first()).toBeVisible();
    });

    test('shows membership equity section', async ({ page }) => {
      await page.goto('/accounting/balance_sheet');
      await expect(page.locator("text=Members' Equity").first()).toBeVisible();
      await expect(page.locator('text=Statutory Funds').first()).toBeVisible();
    });

    test('shows current and non-current asset ledgers', async ({ page }) => {
      await page.goto('/accounting/balance_sheet');
      await expect(page.locator('text=Property, Plant and Equipment').first()).toBeVisible();
      await expect(page.locator('text=Other Current Assets').first()).toBeVisible();
      await expect(page.locator('text=Intangible Assets').first()).toBeVisible();
    });

    test('auto-submits on comparison switch', async ({ page }) => {
      await page.goto('/accounting/balance_sheet');
      await page.locator('select[name="comparison"]').selectOption('prior_year');
      await expect(page).toHaveURL(/comparison=prior_year/);
    });

    test('sidebar has Accounting section with Balance Sheet link', async ({ page }) => {
      await page.goto('/');
      await expect(page.getByText('Accounting')).toBeVisible();
      await expect(page.getByText('Balance Sheet')).toBeVisible();
    });

    test('clicking Balance Sheet sidebar link navigates to the page', async ({ page }) => {
      await page.goto('/');
      await page.getByText('Balance Sheet').click();
      await expect(page).toHaveURL(/\/accounting\/balance_sheet/);
      await expect(page.locator('input[name="as_of_date"]')).toBeVisible();
    });
  });
});
