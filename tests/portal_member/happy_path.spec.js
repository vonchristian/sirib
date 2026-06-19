import { test, expect } from '@playwright/test';

test.describe('Member Portal Happy Path', () => {
  test('shows portal login page', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    await expect(page.getByText('Member Portal')).toBeVisible();
    await expect(page.getByText('Sign in to view your account')).toBeVisible();
  });

  test('portal login with valid credentials', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    await page.getByLabel(/member id/i).fill('MBR-PORTAL-001');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/portal\/dashboard/);
    await expect(page.getByText(/welcome.*portal/i)).toBeVisible();
    await expect(page.getByText('MBR-PORTAL-001')).toBeVisible();
  });

  test('portal dashboard shows financial summary', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    await page.getByLabel(/member id/i).fill('MBR-PORTAL-001');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page.getByText(/savings|share capital|loan balance/i)).toBeVisible();
  });

  test('portal can view announcements list', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    await page.getByLabel(/member id/i).fill('MBR-PORTAL-001');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');
    await page.getByRole('link', { name: /announcements/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page.getByText('Announcements')).toBeVisible();
  });

  test('portal can sign out', async ({ page }) => {
    await page.goto('/portal/session/new');
    await page.waitForLoadState('networkidle');
    await page.getByLabel(/member id/i).fill('MBR-PORTAL-001');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');
    await page.getByRole('button', { name: /sign out/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page.getByText('Signed out successfully')).toBeVisible();
  });
});
