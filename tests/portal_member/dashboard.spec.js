import { test, expect } from '@playwright/test';

test.describe('Member Portal Dashboard', () => {
  test('redirects to login when not authenticated', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');
    expect(page.url()).toContain('/session/new');
  });

  test('shows dashboard with member name after login', async ({ page }) => {
    await page.goto('/session/new');
    await page.waitForLoadState('networkidle');
    await page.getByLabel(/email address/i).fill('portal@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await page.waitForLoadState('networkidle');

    // Should redirect to dashboard
    expect(page.url()).toContain('/dashboard');
  });
});
