import { test, expect } from '@playwright/test';

test.describe('Member Portal Announcements', () => {
  test('redirects to login when not authenticated', async ({ page }) => {
    await page.goto('/announcements');
    await page.waitForLoadState('networkidle');
    expect(page.url()).toContain('/session/new');
  });

  test('shows announcements page after login', async ({ page }) => {
    await page.goto('/session/new');
    await page.waitForLoadState('networkidle');

    // Login as admin since portal routes use same auth
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');

    // Navigate to announcements
    await page.goto('/announcements');
    await page.waitForLoadState('networkidle');
  });
});
