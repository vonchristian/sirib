// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Audit Logs', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('displays audit log list', async ({ page }) => {
      await page.goto('/management/audit_logs');
      await expect(page.getByRole('heading', { name: /audit logs/i })).toBeVisible();
      await expect(page.getByText(/user_login/i)).toBeVisible();
      await expect(page.getByText(/policy_created/i)).toBeVisible();
      await expect(page.getByText(/configuration_updated/i)).toBeVisible();
    });

    test('views audit log details', async ({ page }) => {
      await page.goto('/management/audit_logs');
      await page.getByRole('link', { name: /view/i }).first().click();
      await expect(page.getByText(/audit log/i)).toBeVisible();
    });
  });

  test.describe('Filters', () => {
    test('filters by action type', async ({ page }) => {
      await page.goto('/management/audit_logs');
      await page.getByLabel(/all actions/i).selectOption({ index: 1 });
      await page.getByRole('button', { name: /filter/i }).click();
    });

    test('filters by date range', async ({ page }) => {
      await page.goto('/management/audit_logs');
      const fromInput = page.getByLabel(/from/i);
      const toInput = page.getByLabel(/to/i);
      if (await fromInput.isVisible()) {
        await fromInput.fill('2026-01-01');
        await toInput.fill('2026-12-31');
        await page.getByRole('button', { name: /filter/i }).click();
      }
    });
  });

  test.describe('Empty State', () => {
    test('handles no results gracefully', async ({ page }) => {
      await page.goto('/management/audit_logs');
      // Filter with a non-existent action
      await page.getByLabel(/all actions/i).selectOption({ index: 1 });
      await page.getByRole('button', { name: /filter/i }).click();
    });
  });
});
