// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Identity Layer — Authentication', () => {
  test.beforeEach(async ({ page }) => {
    await page.context().clearCookies();
  });

  test('signs in with email and password', async ({ page }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);
  });

  test('signs in with employee_id and password', async ({ page }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);

    await page.goto('/management/users');
    const employeeIdText = await page.locator('table tbody tr').first().locator('td').first().textContent();

    await page.getByRole('button', { name: /sign out/i }).click();
    await expect(page).toHaveURL(/\/session\/new/);

    await page.getByLabel(/email address/i).fill(employeeIdText.trim());
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);
  });

  test('rejects invalid password', async ({ page }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('wrongpassword');

    // Use evaluate to submit form directly, bypassing Turbo
    await page.evaluate(() => {
      const form = document.querySelector('form');
      if (form) {
        form.removeAttribute('data-turbo');
        form.submit();
      }
    });

    await expect(page.getByText(/try another/i)).toBeVisible({ timeout: 10000 });
  });

  test('rejects unknown employee_id', async ({ page }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('XXXXXXXX');
    await page.getByLabel(/password/i).fill('password123');

    await page.evaluate(() => {
      const form = document.querySelector('form');
      if (form) {
        form.removeAttribute('data-turbo');
        form.submit();
      }
    });

    await expect(page.getByText(/try another/i)).toBeVisible({ timeout: 10000 });
  });

  test('rejects empty credentials', async ({ page }) => {
    await page.goto('/session/new');

    await page.evaluate(() => {
      const form = document.querySelector('form');
      if (form) {
        form.removeAttribute('data-turbo');
        form.submit();
      }
    });

    await expect(page.getByText(/try another/i)).toBeVisible({ timeout: 10000 });
  });

  test('sign out clears session and redirects to login', async ({ page }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);

    await page.getByRole('button', { name: /sign out/i }).click();
    await expect(page).toHaveURL(/\/session\/new/);

    await page.goto('/');
    await expect(page).toHaveURL(/\/session\/new/);
  });
});

test.describe('Identity Layer — Management Pages', () => {
  test.beforeEach(async ({ page }) => {
    await page.context().clearCookies();
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);
  });

  test('dashboard shows key metrics', async ({ page }) => {
    await page.goto('/management/dashboard');
    await expect(page.locator('text=Total Assets').first()).toBeVisible({ timeout: 10000 });
  });

  test('users list shows employee_id column', async ({ page }) => {
    await page.goto('/management/users');
    await expect(page.locator('text=Employee ID').first()).toBeVisible({ timeout: 10000 });
    const employeeIdCell = page.locator('table tbody tr').first().locator('td').first();
    await expect(employeeIdCell).toBeVisible();
    const text = await employeeIdCell.textContent();
    expect(text.trim()).toMatch(/^[A-F0-9]+$/);
  });

  test('users list shows full name', async ({ page }) => {
    await page.goto('/management/users');
    await expect(page.locator('text=System Administrator').first()).toBeVisible({ timeout: 10000 });
  });

  test('users list shows status badge', async ({ page }) => {
    await page.goto('/management/users');
    await expect(page.locator('text=Active').first()).toBeVisible({ timeout: 10000 });
  });

  test('user detail page shows new identity fields', async ({ page }) => {
    await page.goto('/management/users');
    const firstUserLink = page.locator('table tbody tr a').first();
    await firstUserLink.click();
    await expect(page.locator('text=Employee ID').first()).toBeVisible({ timeout: 10000 });
    await expect(page.locator('text=Full Name').first()).toBeVisible();
    await expect(page.locator('text=Status').first()).toBeVisible();
  });
});
