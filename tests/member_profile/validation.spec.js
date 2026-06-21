// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Member Profile - Validation & Empty States', () => {
  test.use({ storageState: '.auth/user.json' });

  test('shows empty state for members with no savings accounts', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await page.getByRole('link', { name: /^savings$/i }).click();
    await expect(page.getByText(/no savings accounts/i)).toBeVisible({ timeout: 10000 });
  });

  test('shows empty state for members with no time deposits', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await page.getByRole('link', { name: /time deposits/i }).click();
    await expect(page.getByText(/no time deposits/i)).toBeVisible({ timeout: 10000 });
  });

  test('shows empty state for members with no loans', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await page.getByRole('link', { name: /^loans$/i }).click();
    await expect(page.getByText(/no loans/i)).toBeVisible({ timeout: 10000 });
  });

  test('shows empty state for members with no share capital', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await page.getByRole('link', { name: /share capital/i }).click();
    await expect(page.getByText(/no share capital/i)).toBeVisible({ timeout: 10000 });
  });

  test('shows call-to-action buttons in empty states', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await page.getByRole('link', { name: /^savings$/i }).click();
    await expect(page.getByRole('link', { name: /open savings account/i })).toBeVisible({ timeout: 10000 });

    await page.getByRole('link', { name: /time deposits/i }).click();
    await expect(page.getByRole('link', { name: /open time deposit/i })).toBeVisible({ timeout: 10000 });

    await page.getByRole('link', { name: /^loans$/i }).click();
    await expect(page.getByRole('link', { name: /create loan/i })).toBeVisible({ timeout: 10000 });

    await page.getByRole('link', { name: /share capital/i }).click();
    await expect(page.getByRole('link', { name: /purchase shares/i })).toBeVisible({ timeout: 10000 });
  });
});
