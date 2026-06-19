import { test, expect } from '@playwright/test';

test.describe('Member Portal Validation', () => {
  test('invalid password shows error', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    await page.getByLabel(/member id/i).fill('MBR-PORTAL-001');
    await page.getByLabel(/password/i).fill('wrongpassword');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page.getByText(/invalid/i)).toBeVisible();
  });

  test('unknown member ID shows error', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    await page.getByLabel(/member id/i).fill('MBR-UNKNOWN-001');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page.getByText(/invalid/i)).toBeVisible();
  });

  test('empty form shows validation', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/portal\/session\/new/);
  });

  test('rate limiting after multiple attempts', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    for (let i = 0; i < 11; i++) {
      await page.getByLabel(/member id/i).fill('MBR-PORTAL-001');
      await page.getByLabel(/password/i).fill('wrongpassword');
      await page.getByRole('button', { name: /sign in/i }).click();
      await page.waitForLoadState('networkidle');
    }
    await expect(page.getByText(/try again later/i)).toBeVisible();
  });
});
