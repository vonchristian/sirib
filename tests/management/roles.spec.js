// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Roles', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('displays role list', async ({ page }) => {
      await page.goto('/management/roles');
      await expect(page.getByRole('heading', { name: /roles/i })).toBeVisible();
      await expect(page.getByText(/board member/i)).toBeVisible();
      await expect(page.getByText(/general manager/i)).toBeVisible();
      await expect(page.getByText(/branch manager/i)).toBeVisible();
      await expect(page.getByText(/loan officer/i)).toBeVisible();
      await expect(page.getByText(/teller/i)).toBeVisible();
      await expect(page.getByText(/accountant/i)).toBeVisible();
      await expect(page.getByText(/auditor/i)).toBeVisible();
      await expect(page.getByText(/system admin/i)).toBeVisible();
    });

    test('creates a new role', async ({ page }) => {
      await page.goto('/management/roles/new');
      await page.getByLabel(/name/i).fill('E2E Test Role');
      await page.getByLabel(/code/i).fill('e2e_test');
      await page.getByLabel(/rank/i).fill('55');
      await page.getByRole('button', { name: /create role/i }).click();
      await expect(page.getByText(/role was successfully created/i)).toBeVisible();
    });

    test('views role details with permissions', async ({ page }) => {
      await page.goto('/management/roles');
      await page.getByText(/system admin/i).first().click();
      await expect(page.getByText(/system admin/i)).toBeVisible();
      await expect(page.getByText(/rank/i)).toBeVisible();
    });

    test('edits a role', async ({ page }) => {
      await page.goto('/management/roles');
      await page.getByRole('link', { name: /edit/i }).first().click();
      await page.getByLabel(/name/i).clear();
      await page.getByLabel(/name/i).fill('E2E Updated Role');
      await page.getByRole('button', { name: /update role/i }).click();
      await expect(page.getByText(/role was successfully updated/i)).toBeVisible();
    });
  });

  test.describe('Validation', () => {
    test('requires name', async ({ page }) => {
      await page.goto('/management/roles/new');
      await page.getByLabel(/code/i).fill('val_test');
      await page.getByLabel(/rank/i).fill('50');
      await page.getByRole('button', { name: /create role/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('requires code', async ({ page }) => {
      await page.goto('/management/roles/new');
      await page.getByLabel(/name/i).fill('Validation Test');
      await page.getByLabel(/rank/i).fill('50');
      await page.getByRole('button', { name: /create role/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('validates duplicate code', async ({ page }) => {
      await page.goto('/management/roles/new');
      await page.getByLabel(/name/i).fill('Dup Role');
      await page.getByLabel(/code/i).fill('board_member');
      await page.getByLabel(/rank/i).fill('50');
      await page.getByRole('button', { name: /create role/i }).click();
      await expect(page.getByText(/already been taken/i)).toBeVisible();
    });
  });
});
