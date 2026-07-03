// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Loan Aging Happy Path', () => {
  test.use({ storageState: '.auth/user.json' });

  test('page loads with all sections', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    await expect(page.getByText('Total Portfolio')).toBeVisible();
    await expect(page.locator('#summary_cards').getByText('Delinquent', { exact: true })).toBeVisible();
    await expect(page.locator('#summary_cards').getByText('PAR30', { exact: true })).toBeVisible();
    await expect(page.locator('#summary_cards').getByText('PAR60', { exact: true })).toBeVisible();
    await expect(page.locator('#summary_cards').getByText('PAR90', { exact: true })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Delinquent Loans' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Aging Distribution' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Branch Performance' })).toBeVisible();
  });

  test('shows aging distribution chart', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    await expect(page.getByRole('heading', { name: 'Aging Distribution' })).toBeVisible();
    const distributionSection = page.locator('#aging_distribution').first();
    await expect(distributionSection).toBeVisible();
  });

  test('shows branch performance table', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    await expect(page.getByRole('heading', { name: 'Branch Performance' })).toBeVisible();
    const table = page.locator('#branch_performance table');
    await expect(table.getByRole('columnheader', { name: 'Branch' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'Portfolio' })).toBeVisible();
  });

  test('delinquent loans table has correct columns', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    const table = page.locator('#delinquent_loans table');
    await expect(table.getByRole('columnheader', { name: 'Loan #' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'Borrower' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'Branch' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'Product' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'Principal' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'Interest' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'Penalty' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'Exposure' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'DPD' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'Group' })).toBeVisible();
    await expect(table.getByRole('columnheader', { name: 'Actions' })).toBeVisible();
  });

  test('can use filters to refine results', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    await expect(page.locator('select[name="branch_id"]')).toBeVisible();
    await expect(page.locator('select[name="loan_product_id"]')).toBeVisible();
    await expect(page.locator('select[name="loan_aging_group_id"]')).toBeVisible();
    await expect(page.locator('input[name="min_dpd"]')).toBeVisible();
    await expect(page.locator('input[name="max_dpd"]')).toBeVisible();
    await expect(page.locator('input[name="as_of_date"]')).toBeVisible();
  });

  test('apply filter and see min_dpd retained', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    const minDpdInput = page.locator('input[name="min_dpd"]');
    await minDpdInput.fill('30');
    await page.getByRole('button', { name: 'Apply' }).click();
    await expect(minDpdInput).toHaveValue('30');
  });

  test('clear filters resets min_dpd', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    const minDpdInput = page.locator('input[name="min_dpd"]');
    await minDpdInput.fill('30');
    await page.getByRole('button', { name: 'Apply' }).click();
    await expect(minDpdInput).toHaveValue('30');
    await page.getByRole('link', { name: 'Clear' }).click();
    await expect(page).toHaveURL(/\/lending\/loan_aging$/);
  });

  test('shows empty state when no delinquent loans', async ({ page }) => {
    await page.goto('/lending/loan_aging');
    const delinquentSection = page.locator('#delinquent_loans');
    await expect(delinquentSection.getByText('No delinquent loans found.')).toBeVisible();
  });
});
