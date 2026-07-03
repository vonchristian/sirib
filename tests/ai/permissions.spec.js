// @ts-check
import { test, expect } from '@playwright/test';

test.describe('AI Branch Manager — Permissions', () => {
  test.use({ storageState: '.auth/user.json' });

  test('System Admin can access AI dashboard', async ({ page }) => {
    await page.goto('/management/ai/dashboard');
    await expect(page.getByText(/today'?s summary/i).or(page.getByText(/no digest/i)).first()).toBeVisible();
  });

  test('System Admin can access observations', async ({ page }) => {
    await page.goto('/management/ai/observations');
    await expect(page.getByLabel(/category/i).or(page.getByText(/no observation/i))).toBeVisible();
  });

  test('System Admin can access recommendations', async ({ page }) => {
    await page.goto('/management/ai/recommendations');
    await expect(page.getByLabel(/priority/i).or(page.getByText(/no recommendation/i))).toBeVisible();
  });

  test('System Admin can access digests', async ({ page }) => {
    await page.goto('/management/ai/digests');
    await expect(page.getByText(/observations/).first().or(page.getByText(/no digest/i))).toBeVisible();
  });
});
