// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Loan Aging Permissions', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('allows access for authenticated user', async ({ page }) => {
      await page.goto('/lending/loan_aging');
      await expect(page.getByText('Total Portfolio')).toBeVisible();
    });

    test('shows loans rail item', async ({ page }) => {
      await page.goto('/lending/loan_aging');
      await expect(page.getByRole('button', { name: 'Loans' })).toBeVisible();
    });
  });
});
