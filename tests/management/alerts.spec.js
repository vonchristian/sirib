// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Alerts', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('displays alert list', async ({ page }) => {
      await page.goto('/management/alerts');
      await expect(page.getByRole('heading', { name: /alerts/i })).toBeVisible();
      await expect(page.getByText(/qc branch delinquency/i)).toBeVisible();
      await expect(page.getByText(/low cash balance/i)).toBeVisible();
      await expect(page.getByText(/high memory usage/i)).toBeVisible();
    });

    test('views alert details', async ({ page }) => {
      await page.goto('/management/alerts');
      await page.getByRole('link', { name: /view/i }).first().click();
      await expect(page.getByText(/alert/i)).toBeVisible();
    });

    test('resolves an active alert', async ({ page }) => {
      await page.goto('/management/alerts');
      const resolveBtn = page.getByRole('button', { name: /resolve/i }).first();
      if (await resolveBtn.isVisible()) {
        await resolveBtn.click();
        await expect(page.getByText(/alert was resolved/i)).toBeVisible();
      }
    });
  });

  test.describe('Filters', () => {
    test('filters by severity', async ({ page }) => {
      await page.goto('/management/alerts');
      await page.getByLabel(/all severities/i).selectOption('Warning');
      await page.getByRole('button', { name: /filter/i }).click();
    });

    test('filters by status', async ({ page }) => {
      await page.goto('/management/alerts');
      await page.getByLabel(/all statuses/i).selectOption('Active');
      await page.getByRole('button', { name: /filter/i }).click();
    });

    test('shows severity badges', async ({ page }) => {
      await page.goto('/management/alerts');
      await expect(page.getByText(/critical/i).first()).toBeVisible();
      await expect(page.getByText(/warning/i).first()).toBeVisible();
    });
  });
});
