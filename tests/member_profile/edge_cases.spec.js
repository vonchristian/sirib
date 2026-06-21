// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Member Profile - Edge Cases', () => {
  test.use({ storageState: '.auth/user.json' });

  test('returns 404 for non-existent member', async ({ page }) => {
    const response = await page.goto('/members/99999');
    expect(response?.status()).toBe(404);
  });

  test('breadcrumb navigation works', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    const membersLink = page.getByRole('link', { name: /^members$/i });
    await expect(membersLink).toBeVisible();

    await membersLink.click();
    await expect(page).toHaveURL('/members');
  });

  test('new transaction button is visible', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    const transactionBtn = page.getByRole('link', { name: /new transaction/i });
    await expect(transactionBtn).toBeVisible();
    await expect(transactionBtn).toHaveAttribute('href', /\/members\/\d+\/transaction\/new/);
  });

  test('rapid tab switching still shows correct content', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await page.getByRole('link', { name: /^savings$/i }).click();
    await page.getByRole('link', { name: /time deposits/i }).click();
    await page.getByRole('link', { name: /^loans$/i }).click();

    await expect(page.getByRole('link', { name: /^loans$/i })).toHaveClass(/border-primary/);
  });
});
