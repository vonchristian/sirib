// @ts-check
import { test, expect } from '@playwright/test';

test.describe('AI Branch Manager — Edge Cases', () => {
  test.use({ storageState: '.auth/user.json' });

  test('handles empty state when logged in as system admin on branch with no data', async ({ page }) => {
    await page.goto('/management/ai/dashboard');
    await expect(page.getByText(/today'?s summary/i).or(page.getByText(/no digest/i)).first()).toBeVisible();
  });

  test('shows observation details', async ({ page }) => {
    await page.goto('/management/ai/observations');
    const viewLink = page.getByRole('link', { name: /view/i }).first();
    if (await viewLink.isVisible()) {
      await Promise.all([
        page.waitForURL(/\/management\/ai\/observations\/\d+/),
        viewLink.click()
      ]);
    } else {
      await expect(page.getByText(/no observation/i)).toBeVisible();
    }
  });

  test('shows recommendation details', async ({ page }) => {
    await page.goto('/management/ai/recommendations');
    const viewLink = page.getByRole('link', { name: /view/i }).first();
    if (await viewLink.isVisible()) {
      await Promise.all([
        page.waitForURL(/\/management\/ai\/recommendations\/\d+/),
        viewLink.click()
      ]);
    } else {
      await expect(page.getByText(/no recommendation/i)).toBeVisible();
    }
  });

  test('shows digest details', async ({ page }) => {
    await page.goto('/management/ai/digests');
    const viewLink = page.getByRole('link', { name: /view/i }).first();
    if (await viewLink.isVisible()) {
      await Promise.all([
        page.waitForURL(/\/management\/ai\/digests\/\d+/),
        viewLink.click()
      ]);
    } else {
      await expect(page.getByText(/no digest/i)).toBeVisible();
    }
  });
});
