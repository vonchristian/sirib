// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Holiday Management — Validation', () => {
  test.use({ storageState: '.auth/user.json' });

  test('requires date', async ({ page }) => {
    await page.goto('/management/holidays/new');
    await page.getByLabel(/name/i).fill('Test Holiday');
    await page.getByRole('button', { name: /create holiday/i }).click();
    await expect(page.getByText(/can't be blank/i)).toBeVisible();
  });

  test('requires name', async ({ page }) => {
    await page.goto('/management/holidays/new');
    await page.getByLabel(/date/i).fill('2026-12-08');
    await page.getByRole('button', { name: /create holiday/i }).click();
    await expect(page.getByText(/can't be blank/i)).toBeVisible();
  });

  test('rejects duplicate date', async ({ page }) => {
    await page.goto('/management/holidays/new');
    await page.getByLabel(/date/i).fill('2026-12-25');
    await page.getByLabel(/name/i).fill('Duplicate Christmas');
    await page.getByRole('button', { name: /create holiday/i }).click();
    await expect(page.getByText(/already a holiday/i)).toBeVisible();
  });
});
