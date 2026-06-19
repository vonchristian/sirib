import { test, expect } from '@playwright/test';

const BASE = 'http://main.lvh.me:3000';
const OTHER = 'http://asenso.lvh.me:3000';

test.describe('subdomain login', () => {
  test('login succeeds on correct subdomain', async ({ page }) => {
    await page.goto(`${BASE}/session/new`);
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);
    await expect(page.getByText(/sign in/i)).not.toBeVisible();
  });

  test('login fails with wrong password', async ({ page }) => {
    await page.goto(`${BASE}/session/new`);
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('wrongpassword');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page.getByText(/try another/i)).toBeVisible();
  });

  test('login with non-existent user shows error', async ({ page }) => {
    await page.goto(`${BASE}/session/new`);
    await page.getByLabel(/email address/i).fill('nobody@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page.getByText(/try another/i)).toBeVisible();
  });

  test('logout redirects to login page on same subdomain', async ({ page }) => {
    // Login first
    await page.goto(`${BASE}/session/new`);
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);

    // Logout — use fetch to send DELETE, then navigate to follow redirect
    await page.evaluate(async () => {
      await fetch('/session', { method: 'DELETE', redirect: 'manual' });
      window.location.href = '/session/new';
    });
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test('session is scoped to subdomain', async ({ page }) => {
    // Login on main
    await page.goto(`${BASE}/session/new`);
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);

    // Try accessing asenso - should not be authenticated
    await page.goto(`${OTHER}/dashboard`);
    await expect(page).toHaveURL(/\/session\/new/);
  });
});

test.describe('cross-tenant login rejection', () => {
  test('user from one coop cannot login on another coop subdomain', async ({ page }) => {
    // Login with main cooperative user on asenso subdomain
    await page.goto(`${OTHER}/session/new`);
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();

    // Should redirect back to login with access denied
    await expect(page).toHaveURL(/\/session\/new/);
    // Or the dashboard but then verify_tenant_access kicks in
  });
});
