// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Loan Aging Edge Cases', () => {
  test.use({ storageState: '.auth/user.json' });

  test('handles large min_dpd gracefully', async ({ page }) => {
    await page.goto('/lending/loan_aging?min_dpd=999');
    await expect(page.locator('input[name="min_dpd"]')).toHaveValue('999');
  });

  test('handles negative dpd gracefully', async ({ page }) => {
    await page.goto('/lending/loan_aging?min_dpd=-1');
    await expect(page.locator('input[name="min_dpd"]')).toHaveValue('-1');
  });

  test('handles future as_of_date gracefully', async ({ page }) => {
    await page.goto('/lending/loan_aging?as_of_date=2099-01-01');
    await expect(page.locator('input[name="as_of_date"]')).toHaveValue('2099-01-01');
  });

  test('combines multiple filters', async ({ page }) => {
    await page.goto('/lending/loan_aging?min_dpd=30&max_dpd=90');
    await expect(page.locator('input[name="min_dpd"]')).toHaveValue('30');
    await expect(page.locator('input[name="max_dpd"]')).toHaveValue('90');
  });

  test('page is responsive on mobile viewport', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto('/lending/loan_aging');
    await expect(page.getByText('Total Portfolio')).toBeVisible();
  });

  test('page is responsive on tablet viewport', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('/lending/loan_aging');
    await expect(page.getByText('Total Portfolio')).toBeVisible();
  });

  test('browser back button works after filter', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    await page.locator('input[name="min_dpd"]').fill('30');
    await page.getByRole('button', { name: 'Apply' }).click();
    await expect(page.locator('input[name="min_dpd"]')).toHaveValue('30');
    await page.goBack();
  });

  test('browser forward button works after back', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    await page.locator('input[name="min_dpd"]').fill('30');
    await page.getByRole('button', { name: 'Apply' }).click();
    await page.goBack();
    await page.goForward();
  });
});
