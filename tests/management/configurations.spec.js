// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Configurations', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('displays configuration list', async ({ page }) => {
      await page.goto('/management/configurations');
      await expect(page.getByRole('heading', { name: /configurations/i })).toBeVisible();
      await expect(page.getByText(/loan_default_interest_rate/i)).toBeVisible();
      await expect(page.getByText(/savings_base_interest_rate/i)).toBeVisible();
      await expect(page.getByText(/late_payment_penalty_rate/i)).toBeVisible();
    });

    test('creates a new configuration', async ({ page }) => {
      await page.goto('/management/configurations/new');
      await page.getByLabel(/key/i).fill('e2e_test_config');
      await page.getByLabel(/value/i).fill('test_value');
      await page.getByRole('button', { name: /create configuration/i }).click();
      await expect(page.getByText(/configuration was successfully created/i)).toBeVisible();
    });

    test('views configuration details', async ({ page }) => {
      await page.goto('/management/configurations');
      await page.getByText(/loan_default_interest_rate/i).first().click();
      await expect(page.getByText(/loan_default_interest_rate/i)).toBeVisible();
    });

    test('edits a configuration', async ({ page }) => {
      await page.goto('/management/configurations');
      await page.getByRole('link', { name: /edit/i }).first().click();
      await page.getByLabel(/value/i).clear();
      await page.getByLabel(/value/i).fill('updated_value');
      await page.getByRole('button', { name: /update configuration/i }).click();
      await expect(page.getByText(/configuration was successfully updated/i)).toBeVisible();
    });
  });

  test.describe('Approval Actions', () => {
    test('activates a configuration', async ({ page }) => {
      await page.goto('/management/configurations');
      await page.getByText(/loan_default_interest_rate/i).first().click();
      const activateBtn = page.getByRole('button', { name: /activate/i });
      if (await activateBtn.isVisible()) {
        await activateBtn.click();
        await expect(page.getByText(/configuration was activated/i)).toBeVisible();
      }
    });
  });

  test.describe('Validation', () => {
    test('requires key', async ({ page }) => {
      await page.goto('/management/configurations/new');
      await page.getByLabel(/value/i).fill('test_val');
      await page.getByRole('button', { name: /create configuration/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('requires value', async ({ page }) => {
      await page.goto('/management/configurations/new');
      await page.getByLabel(/key/i).fill('test_key');
      await page.getByRole('button', { name: /create configuration/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });
  });
});
