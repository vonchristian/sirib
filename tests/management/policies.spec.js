// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Policies', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('displays policy list', async ({ page }) => {
      await page.goto('/management/policies');
      await expect(page.getByRole('heading', { name: /policies/i })).toBeVisible();
      await expect(page.getByText(/max_loan_amount/i)).toBeVisible();
      await expect(page.getByText(/teller_cash_limit/i)).toBeVisible();
      await expect(page.getByText(/min_savings_balance/i)).toBeVisible();
    });

    test('creates a new policy', async ({ page }) => {
      await page.goto('/management/policies/new');
      await page.getByLabel(/name/i).fill('E2E Test Policy');
      await page.getByLabel(/code/i).fill('e2e_test_policy');
      await page.getByLabel(/category/i).fill('test');
      await page.getByRole('button', { name: /create policy/i }).click();
      await expect(page.getByText(/policy was successfully created/i)).toBeVisible();
    });

    test('views policy details with rules', async ({ page }) => {
      await page.goto('/management/policies');
      await page.getByText(/max_loan_amount/i).first().click();
      await expect(page.getByText(/max_loan_amount/i)).toBeVisible();
      await expect(page.getByText(/details/i).first()).toBeVisible();
    });

    test('edits a policy', async ({ page }) => {
      await page.goto('/management/policies');
      await page.getByRole('link', { name: /edit/i }).first().click();
      await page.getByLabel(/name/i).clear();
      await page.getByLabel(/name/i).fill('E2E Updated Policy');
      await page.getByRole('button', { name: /update policy/i }).click();
      await expect(page.getByText(/policy was successfully updated/i)).toBeVisible();
    });

    test('activates a policy', async ({ page }) => {
      // Create a draft policy first
      await page.goto('/management/policies/new');
      await page.getByLabel(/name/i).fill('Activation Test');
      await page.getByLabel(/code/i).fill('activation_test');
      await page.getByLabel(/category/i).fill('test');
      await page.getByRole('button', { name: /create policy/i }).click();
      await expect(page.getByText(/policy was successfully created/i)).toBeVisible();
      // Activate it
      await page.getByRole('button', { name: /activate/i }).click();
      await expect(page.getByText(/policy was activated/i)).toBeVisible();
    });

    test('deactivates a policy', async ({ page }) => {
      await page.goto('/management/policies');
      await page.getByText(/max_loan_amount/i).first().click();
      await page.getByRole('button', { name: /deactivate/i }).click();
      await expect(page.getByText(/policy was deactivated/i)).toBeVisible();
    });
  });

  test.describe('Validation', () => {
    test('requires name', async ({ page }) => {
      await page.goto('/management/policies/new');
      await page.getByLabel(/code/i).fill('val_test');
      await page.getByLabel(/category/i).fill('test');
      await page.getByRole('button', { name: /create policy/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('requires code', async ({ page }) => {
      await page.goto('/management/policies/new');
      await page.getByLabel(/name/i).fill('Validation Test');
      await page.getByLabel(/category/i).fill('test');
      await page.getByRole('button', { name: /create policy/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('validates duplicate code', async ({ page }) => {
      await page.goto('/management/policies/new');
      await page.getByLabel(/name/i).fill('Dup Policy');
      await page.getByLabel(/code/i).fill('max_loan_amount');
      await page.getByLabel(/category/i).fill('test');
      await page.getByRole('button', { name: /create policy/i }).click();
      await expect(page.getByText(/already been taken/i)).toBeVisible();
    });
  });

  test.describe('Filter', () => {
    test('filters policies by category', async ({ page }) => {
      await page.goto('/management/policies');
      // Select first non-blank option in category filter
      const select = page.getByLabel(/all categories/i);
      const options = await select.locator('option').count();
      if (options > 1) {
        await select.selectOption({ index: 1 });
        await page.getByRole('button', { name: /filter/i }).click();
      }
    });
  });
});
