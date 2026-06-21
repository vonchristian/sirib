// @ts-check
import { test, expect } from '@playwright/test';

const openAccount = async (page, memberName = 'Maria Santos Cruz') => {
  await page.goto('/treasury/savings_accounts/new');

  // Search and select member via autocomplete
  await page.getByPlaceholder(/Search member/i).fill(memberName.split(' ')[0]);
  await page.getByText(memberName).first().waitFor({ timeout: 5000 });
  await page.getByText(memberName).first().click();

  // Select savings product (first radio)
  await page.locator('label').filter({ hasText: /Regular Savings/ }).first().click();

  // Select account type (Personal Savings)
  await page.locator('label').filter({ hasText: /Personal Savings/ }).click();

  await page.getByRole('button', { name: /Open Account/i }).click();
  await expect(page.getByText('Savings account opened.')).toBeVisible();
};

test.describe('Treasury Savings', () => {
  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('creates a savings product', async ({ page }) => {
      await page.goto('/treasury/savings_products/new');

      await page.getByLabel(/Name/i).fill('E2E Test Savings');
      await page.getByLabel(/Description/i).fill('Created by e2e test');
      await page.getByPlaceholder('e.g. 0.025').fill('0.035');

      await page.getByRole('button', { name: /Create Product/i }).click();

      await expect(page.getByText('Savings product created.')).toBeVisible();
      await expect(page.getByRole('heading', { name: 'E2E Test Savings' }).first()).toBeVisible();
    });

    test('opens a savings account for a member', async ({ page }) => {
      await openAccount(page);
      await expect(page.getByRole('link', { name: /Deposit/ })).toBeVisible();
      await expect(page.getByRole('link', { name: /Withdraw/ })).toBeVisible();
    });

    test('deposit transaction', async ({ page }) => {
      await openAccount(page, 'Juan Dela Reyes');

      await page.getByRole('link', { name: /Deposit/ }).click();
      await expect(page).toHaveURL(/\/deposit$/);

      await page.getByPlaceholder('0.00').fill('10000');
      await page.getByRole('button', { name: /Preview/i }).click();

      await expect(page.getByRole('button', { name: /Confirm Deposit/i })).toBeVisible();
      await expect(page.getByText(/Balance After Deposit/)).toBeVisible();

      await page.getByRole('button', { name: /Confirm Deposit/i }).click();
      await expect(page.getByText(/Deposit of.*completed/i)).toBeVisible();
    });

    test('withdraw transaction', async ({ page }) => {
      await openAccount(page, 'Elena Garcia Villanueva');

      await page.getByRole('link', { name: /Deposit/ }).click();
      await page.getByPlaceholder('0.00').fill('50000');
      await page.getByRole('button', { name: /Preview/i }).click();
      await page.getByRole('button', { name: /Confirm Deposit/i }).click();
      await expect(page.getByText(/Deposit of.*completed/i)).toBeVisible();

      await page.getByRole('link', { name: /Withdraw/ }).click();
      await expect(page).toHaveURL(/\/withdraw$/);

      await page.getByPlaceholder('0.00').fill('3000');
      await page.getByRole('button', { name: /Preview/i }).click();

      await expect(page.getByRole('button', { name: /Confirm Withdrawal/i })).toBeVisible();
      await expect(page.getByRole('cell', { name: /₱3,000\.00/ }).first()).toBeVisible();

      await page.getByRole('button', { name: /Confirm Withdrawal/i }).click();
      await expect(page.getByText(/Withdrawal of.*completed/i)).toBeVisible();
    });

    test('validates insufficient balance on withdraw', async ({ page }) => {
      await openAccount(page, 'Ana Luna Dimagiba');

      await page.getByRole('link', { name: /Withdraw/ }).click();
      await page.getByPlaceholder('0.00').fill('5000');
      await page.getByRole('button', { name: /Preview/i }).click();

      await expect(page.getByText(/Insufficient/i).first()).toBeVisible();
    });

    test('cancels deposit at preview stage', async ({ page }) => {
      await openAccount(page, 'Pedro M. Santos');

      await page.getByRole('link', { name: /Deposit/ }).click();
      await page.getByPlaceholder('0.00').fill('5000');

      await page.getByText('Cancel').first().click();
      await expect(page).toHaveURL(/\/treasury\/savings_accounts\/\d+$/);
    });

    test('edits deposit amount from preview', async ({ page }) => {
      await openAccount(page, 'Sofia C. Gonzales');

      await page.getByRole('link', { name: /Deposit/ }).click();
      await page.getByPlaceholder('0.00').fill('5000');
      await page.getByRole('button', { name: /Preview/i }).click();
      await expect(page.getByRole('button', { name: /Confirm Deposit/i })).toBeVisible();

      await page.getByRole('link', { name: /Edit/i }).click();
      await expect(page).toHaveURL(/\/deposit(\?|$)/);
    });
  });
});
