// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Departments', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('displays department list', async ({ page }) => {
      await page.goto('/management/departments');
      const table = page.getByRole('table');
      await expect(page.getByRole('heading', { name: /departments/i })).toBeVisible();
      await expect(table.getByText(/administration/i).first()).toBeVisible();
      await expect(table.getByText(/lending/i).first()).toBeVisible();
    });

    test('creates a new department', async ({ page }) => {
      await page.goto('/management/departments/new');
      await page.getByLabel(/name/i).fill('E2E Test Dept');
      await page.getByLabel(/code/i).fill('E2E_DEPT');
      await page.getByLabel(/branch/i).selectOption({ index: 1 });
      await page.getByRole('button', { name: /create department/i }).click();
      await expect(page).toHaveURL(/\/management\/departments\/\d+$/);
      await expect(page.getByText(/department was successfully created/i)).toBeVisible();
    });

    test('views department details', async ({ page }) => {
      await page.goto('/management/departments');
      await page.getByRole('link', { name: /edit/i }).first().click();
      await expect(page.getByRole('heading', { name: /edit department/i })).toBeVisible();
    });

    test('edits a department', async ({ page }) => {
      await page.goto('/management/departments');
      await page.getByRole('link', { name: /edit/i }).first().click();
      await page.getByLabel(/name/i).clear();
      await page.getByLabel(/name/i).fill('E2E Updated Dept');
      await page.getByRole('button', { name: /update department/i }).click();
      await expect(page).toHaveURL(/\/management\/departments\/\d+$/);
      await expect(page.getByText(/department was successfully updated/i)).toBeVisible();
    });
  });

  test.describe('Validation', () => {
    test('requires name', async ({ page }) => {
      await page.goto('/management/departments/new');
      await page.getByLabel(/code/i).fill('VAL');
      await page.getByLabel(/branch/i).selectOption({ index: 1 });
      await page.getByRole('button', { name: /create department/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('requires code', async ({ page }) => {
      await page.goto('/management/departments/new');
      await page.getByLabel(/name/i).fill('Validation Test');
      await page.getByLabel(/branch/i).selectOption({ index: 1 });
      await page.getByRole('button', { name: /create department/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });
  });

  test.describe('Filter', () => {
    test('filters departments by branch', async ({ page }) => {
      await page.goto('/management/departments');
      await page.locator('select[name="branch_id"]').selectOption({ index: 1 });
      await page.getByRole('button', { name: /filter/i }).click();
      await expect(page.getByText(/no departments found/i).first()).not.toBeVisible();
    });
  });
});
