// @ts-check
import { test, expect } from '@playwright/test';

const memberName = 'Carlos B. Yulo';

test.describe('Member Transaction', () => {
  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('creates a member transaction and appears in cash session', async ({ page }) => {
      // Open a savings account for a member
      await page.goto('/treasury/savings_accounts/new');
      await page.getByLabel(/Savings Product/i).selectOption({ label: 'Regular Savings' });
      await page.getByLabel(/Member/i).selectOption({ label: memberName });
      await page.getByLabel(/Account Type/i).selectOption('Personal');
      await page.getByRole('button', { name: /Open Account/i }).click();
      await expect(page.getByText('Savings account opened.')).toBeVisible();

      // Navigate to member page
      await page.goto('/members');
      const memberRow = page.locator('tr').filter({ hasText: memberName });
      await memberRow.getByRole('link', { name: /View/i }).click();
      await expect(page.getByRole('main').getByRole('heading', { name: memberName })).toBeVisible();

      // Click New Transaction
      await page.getByRole('link', { name: /New Transaction/i }).click();
      await expect(page).toHaveURL(/\/transaction\/new$/);

      // Fill in a savings deposit amount
      const amountInput = page.getByPlaceholder('Amount').first();
      await amountInput.fill('5000');

      // Preview & Confirm
      await page.getByRole('button', { name: /Preview Transaction/i }).click();
      await expect(page.getByText('Transaction Summary')).toBeVisible();
      await page.getByRole('button', { name: /Confirm Transaction/i }).click();
      await expect(page.getByText(/Member transaction completed/)).toBeVisible();

      // Verify the transaction shows up in the cash session report
      await page.goto('/treasury/cash_sessions');
      await page.getByRole('link', { name: /View/ }).first().click();
      await expect(page.getByText(/Member Transaction/).first()).toBeVisible();
      await expect(page.getByText(/5,000\.00/).first()).toBeVisible();
    });
  });
});
