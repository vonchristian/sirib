// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Teams', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('displays team list', async ({ page }) => {
      await page.goto('/management/teams');
      await expect(page.getByRole('heading', { name: /teams/i })).toBeVisible();
    });

    test('creates a new team', async ({ page }) => {
      await page.goto('/management/teams/new');
      await page.getByLabel(/name/i).fill('E2E Test Team');
      await page.getByLabel(/department/i).selectOption({ index: 1 });
      await page.getByRole('button', { name: /create team/i }).click();
      await expect(page.getByText(/team was successfully created/i)).toBeVisible();
    });

    test('edits a team', async ({ page }) => {
      await page.goto('/management/teams');
      if (await page.getByRole('link', { name: /edit/i }).first().isVisible()) {
        await page.getByRole('link', { name: /edit/i }).first().click();
        await page.getByLabel(/name/i).clear();
        await page.getByLabel(/name/i).fill('E2E Updated Team');
        await page.getByRole('button', { name: /update team/i }).click();
        await expect(page.getByText(/team was successfully updated/i)).toBeVisible();
      }
    });
  });

  test.describe('Validation', () => {
    test('requires name', async ({ page }) => {
      await page.goto('/management/teams/new');
      await page.getByLabel(/department/i).selectOption({ index: 1 });
      await page.getByRole('button', { name: /create team/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('requires department', async ({ page }) => {
      await page.goto('/management/teams/new');
      await page.getByLabel(/name/i).fill('No Dept Team');
      // Leave department unselected
      await page.getByRole('button', { name: /create team/i }).click();
      await expect(page.getByText(/must exist/i)).toBeVisible();
    });
  });

  test.describe('Filter', () => {
    test('filters teams by department', async ({ page }) => {
      await page.goto('/management/teams');
      await page.locator('select[name="department_id"]').selectOption({ index: 1 });
      await page.getByRole('button', { name: /filter/i }).click();
    });
  });
});
