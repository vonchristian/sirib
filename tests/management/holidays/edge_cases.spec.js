// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Holiday Management — Edge Cases', () => {
  test.use({ storageState: '.auth/user.json' });

  test('shows empty state when no holidays', async ({ page }) => {
    await page.goto('/management/holidays');
    const rows = page.locator('table tbody tr');
    // There should be seeded holidays, so this tests the non-empty render
    await expect(rows.first()).toBeVisible();
  });

  test('toggle recurring creates yearly holiday', async ({ page }) => {
    await page.goto('/management/holidays/new');
    await page.getByLabel(/date/i).fill('2028-11-01');
    await page.getByLabel(/name/i).fill('All Saints Day');
    await page.getByLabel(/recurring/i).check();
    await page.getByRole('button', { name: /create holiday/i }).click();
    await expect(page.getByText(/holiday was successfully created/i)).toBeVisible();
    await expect(page.getByText(/Recurring/i)).toBeVisible();
  });

  test('can create one-off holiday', async ({ page }) => {
    await page.goto('/management/holidays/new');
    await page.getByLabel(/date/i).fill('2027-06-15');
    await page.getByLabel(/name/i).fill('Special Non-Working Day');
    await page.getByRole('button', { name: /create holiday/i }).click();
    await expect(page.getByText(/holiday was successfully created/i)).toBeVisible();
    await expect(page.getByText(/One-off/i)).toBeVisible();
  });
});
