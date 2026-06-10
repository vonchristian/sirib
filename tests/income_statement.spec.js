// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Income Statement', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/accounting/income_statement');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('shows filter bar with date picker and comparison dropdown', async ({ page }) => {
      await page.goto('/accounting/income_statement');
      await expect(page.locator('input[name="as_of_date"]')).toBeVisible();
      await expect(page.locator('select[name="comparison"]')).toBeVisible();
    });

    test('displays REVENUES and EXPENSES sections', async ({ page }) => {
      await page.goto('/accounting/income_statement');
      await expect(page.locator('text=REVENUES').first()).toBeVisible();
      await expect(page.locator('text=EXPENSES').first()).toBeVisible();
    });

    test('shows revenue ledgers', async ({ page }) => {
      await page.goto('/accounting/income_statement');
      await expect(page.locator('text=Income from Credit Operations').first()).toBeVisible();
      await expect(page.locator('text=Income from Service Operations').first()).toBeVisible();
      await expect(page.locator('text=Other Income').first()).toBeVisible();
    });

    test('shows expense ledgers', async ({ page }) => {
      await page.goto('/accounting/income_statement');
      await expect(page.locator('text=Cost of Goods Sold').first()).toBeVisible();
      await expect(page.locator('text=Operating Expenses').first()).toBeVisible();
      await expect(page.locator('text=Other Income and Expenses').first()).toBeVisible();
    });

    test('shows Net Income (Loss) row', async ({ page }) => {
      await page.goto('/accounting/income_statement');
      await expect(page.locator('text=NET INCOME (LOSS)').first()).toBeVisible();
    });

    test('shows revenue and expense accounts', async ({ page }) => {
      await page.goto('/accounting/income_statement');
      await expect(page.locator('text=Interest Income from Loans').first()).toBeVisible();
      await expect(page.locator('text=Service Income').first()).toBeVisible();
      await expect(page.locator('text=Salaries and Wages').first()).toBeVisible();
      await expect(page.locator('text=Rent Expense').first()).toBeVisible();
    });

    test('shows Chart of Accounts Legend', async ({ page }) => {
      await page.goto('/accounting/income_statement');
      await expect(page.getByText('Chart of Accounts Legend')).toBeVisible();
      await expect(page.locator('text=Revenue').last()).toBeVisible();
      await expect(page.locator('text=Expense').last()).toBeVisible();
      await expect(page.getByText(/contra account/i).last()).toBeVisible();
    });

    test('shows comparative period indicator when comparison is selected', async ({ page }) => {
      await page.goto('/accounting/income_statement?comparison=prior_year');
      await expect(page.getByText(/comparative period/i).first()).toBeVisible();
      await expect(page.locator('th').nth(2)).toBeVisible();
    });

    test('shows revenue ledger code prefixes', async ({ page }) => {
      await page.goto('/accounting/income_statement');
      await expect(page.locator('text=40100').first()).toBeVisible();
      await expect(page.locator('text=40200').first()).toBeVisible();
    });

    test('shows expense ledger code prefixes', async ({ page }) => {
      await page.goto('/accounting/income_statement');
      await expect(page.locator('text=51000').first()).toBeVisible();
      await expect(page.locator('text=60000').first()).toBeVisible();
    });

    test('auto-submits on comparison switch', async ({ page }) => {
      await page.goto('/accounting/income_statement');
      await page.locator('select[name="comparison"]').selectOption('prior_year');
      await expect(page).toHaveURL(/comparison=prior_year/);
    });

    test('sidebar has Accounting section with Income Statement link', async ({ page }) => {
      await page.goto('/');
      await expect(page.getByText('Accounting')).toBeVisible();
      await expect(page.getByText('Income Statement')).toBeVisible();
    });

    test('clicking Income Statement sidebar link navigates to the page', async ({ page }) => {
      await page.goto('/');
      await page.getByText('Income Statement').click();
      await expect(page).toHaveURL(/\/accounting\/income_statement/);
      await expect(page.locator('input[name="as_of_date"]')).toBeVisible();
    });
  });
});
