import { test, expect } from '@playwright/test';

test.describe('Chart of Accounts Permissions', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/accounting/chart_of_accounts');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('authenticated user can access the page', async ({ page }) => {
      await page.goto('/accounting/chart_of_accounts');
      await page.waitForLoadState('networkidle');

      await expect(page.getByText('Chart of Accounts')).toBeVisible();
      await expect(page).toHaveURL(/\/accounting\/chart_of_accounts/);
    });

    test('clicking account row navigates to account show page', async ({ page }) => {
      await page.goto('/accounting/chart_of_accounts');
      await page.waitForLoadState('networkidle');

      await page.getByText('11110').first().click();
      await page.waitForLoadState('networkidle');

      await expect(page).toHaveURL(/\/accounting\/accounts\/\d+/);
    });
  });
});
