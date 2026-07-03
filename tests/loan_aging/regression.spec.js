// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Loan Aging Regression', () => {
  test.use({ storageState: '.auth/user.json' });

  test('dashboard page does not crash', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    const hasError = await page.getByText(/internal server error|500|something went wrong/i).count();
    expect(hasError).toBe(0);
  });

  test('all sections have no server errors', async ({ page }) => {
    const responses = [];
    page.on('response', response => {
      if (response.status() >= 400) {
        responses.push({ url: response.url(), status: response.status() });
      }
    });
    await page.goto('/lending/loan_aging');
    expect(responses.filter(r => r.status >= 500).length).toBe(0);
  });

  test('filters do not cause errors', async ({ page }) => {
    const responses = [];
    page.on('response', response => {
      if (response.status() >= 500) {
        responses.push({ url: response.url(), status: response.status() });
      }
    });
    await page.goto('/lending/loan_aging?min_dpd=30&max_dpd=90&loan_aging_group_id=1');
    expect(responses.length).toBe(0);
  });

  test('turbo frame updates work without full reload', async ({ page }) => {
    let fullPageLoads = 0;
    page.on('load', () => fullPageLoads++);
    await page.goto('/lending/loan_aging');
    const initialLoads = fullPageLoads;
    await page.locator('input[name="min_dpd"]').fill('60');
    await page.getByRole('button', { name: 'Apply' }).click();
    await page.waitForTimeout(500);
    expect(fullPageLoads).toBe(initialLoads);
  });
});
