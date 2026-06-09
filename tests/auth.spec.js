// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Authentication Flow', () => {
  test('redirects unauthenticated user to sign in page', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveURL(/\/session\/new/);
    await expect(page.getByRole('heading', { name: /welcome back/i })).toBeVisible();
  });

  test('signs in with valid credentials', async ({ page }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('test@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();

    await expect(page).toHaveURL('/');
    await expect(page.getByText(/active loans/i)).toBeVisible();
    await expect(page.getByText(/pending tasks/i)).toBeVisible();
  });

  test('shows error with invalid credentials', async ({ page }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('test@example.com');
    await page.getByLabel(/password/i).fill('wrongpassword');
    await page.getByRole('button', { name: /sign in/i }).click();

    await expect(page.getByText(/try another email/i)).toBeVisible();
  });

  test('signs out successfully', async ({ page }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('test@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();

    await expect(page).toHaveURL('/');

    // Sign out is inside user dropdown — open it first
    await page.locator('[data-action="click->sidebar#toggleUserMenu"]').last().click();
    await page.getByRole('button', { name: /sign out/i }).click();
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test('shows forgot password link', async ({ page }) => {
    await page.goto('/session/new');
    await page.getByRole('link', { name: /forgot your password/i }).click();
    await expect(page.getByRole('heading', { name: /forgot your password/i })).toBeVisible();
  });
});
