// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Holiday Management — Happy Paths', () => {
  test.use({ storageState: '.auth/user.json' });

  test('displays holiday list', async ({ page }) => {
    await page.goto('/management/holidays');
    await expect(page.getByText(/Christmas Day/i)).toBeVisible();
    await expect(page.getByText(/New Year's Day/i)).toBeVisible();
    await expect(page.getByRole('link', { name: /new holiday/i })).toBeVisible();
  });

  test('creates a new holiday', async ({ page }) => {
    await page.goto('/management/holidays/new');
    await page.getByLabel(/date/i).fill('2027-03-15');
    await page.getByLabel(/name/i).fill('Municipal Fiesta');
    await page.getByRole('button', { name: /create holiday/i }).click();
    await expect(page.getByText(/holiday was successfully created/i)).toBeVisible();
  });

  test('views holiday details', async ({ page }) => {
    await page.goto('/management/holidays');
    await page.getByText(/Christmas Day/i).first().click();
    await expect(page.getByText(/Christmas Day/i)).toBeVisible();
  });

  test('edits a holiday', async ({ page }) => {
    await page.goto('/management/holidays');
    await page.getByRole('link', { name: /edit/i }).first().click();
    await page.getByLabel(/name/i).clear();
    await page.getByLabel(/name/i).fill('Updated Holiday Name');
    await page.getByRole('button', { name: /update holiday/i }).click();
    await expect(page.getByText(/holiday was successfully updated/i)).toBeVisible();
  });

  test('deletes a holiday', async ({ page }) => {
    await page.goto('/management/holidays');
    page.on('dialog', dialog => dialog.accept());
    await page.getByRole('button', { name: /delete/i }).first().click();
    await expect(page.getByText(/holiday was successfully deleted/i)).toBeVisible();
  });
});
