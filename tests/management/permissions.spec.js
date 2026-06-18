// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Permissions', () => {
  test.use({ storageState: '.auth/user.json' });

  test('displays permission list', async ({ page }) => {
    await page.goto('/management/permissions');
    await expect(page.getByRole('heading', { name: /permissions/i })).toBeVisible();
  });

  test('shows permission details', async ({ page }) => {
    await page.goto('/management/permissions');
    const viewLink = page.getByRole('link', { name: /view/i }).first();
    if (await viewLink.isVisible()) {
      await viewLink.click();
      await expect(page.getByText(/action/i)).toBeVisible();
    }
  });
});
