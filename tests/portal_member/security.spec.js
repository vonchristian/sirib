import { test, expect } from '@playwright/test';

test.describe('Member Portal Security', () => {
  test('dashboard redirects to login when not authenticated', async ({ page }) => {
    await page.goto('/portal/dashboard');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/portal\/session\/new/);
  });

  test('announcements redirect to login when not authenticated', async ({ page }) => {
    await page.goto('/portal/announcements');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/portal\/session\/new/);
  });

  test('cannot access admin dashboard while in portal', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    await page.getByLabel(/member id/i).fill('MBR-PORTAL-001');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/portal\/dashboard/);

    // Try accessing admin dashboard
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test('session expires after inactivity', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    await page.getByLabel(/member id/i).fill('MBR-PORTAL-001');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/portal\/dashboard/);
  });
});
