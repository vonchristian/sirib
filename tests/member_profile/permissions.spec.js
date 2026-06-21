// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Member Profile - Permissions', () => {
  test('authenticated user can view member profile', async ({ page }) => {
    test.use({ storageState: '.auth/user.json' });

    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await expect(page.getByText(/active member/i)).toBeVisible();
  });

  test('unauthenticated user is redirected to login', async ({ page }) => {
    await page.goto('/members/1');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test('settings tab displays portal toggle', async ({ page }) => {
    test.use({ storageState: '.auth/user.json' });

    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await page.getByRole('link', { name: /^settings$/i }).click();
    await expect(page.getByText(/member portal access/i)).toBeVisible({ timeout: 10000 });
  });
});
