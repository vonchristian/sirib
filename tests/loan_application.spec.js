// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Loan Application', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/loans/applications');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('shows empty state when no applications exist', async ({ page }) => {
      await page.goto('/loans/applications');
      await expect(page.getByText(/No applications yet/)).toBeVisible();
    });

    test('new form requires member and product via autocomplete', async ({ page }) => {
      await page.goto('/loans/applications/new');

      await expect(page.getByText('Select Member & Product')).toBeVisible();
      await expect(page.getByText('Start Application')).toBeVisible();

      // Click Start Application without filling — should trigger validation
      await page.getByRole('button', { name: 'Start Application' }).click();

      // Should stay on new page with validation errors
      await expect(page).toHaveURL(/\/loans\/applications\/new/);
      await expect(page.getByText(/can't be blank|required|error/)).toBeVisible();
    });

    test('creates application and shows wizard with stepper', async ({ page }) => {
      await page.goto('/loans/applications/new');

      // Fill member autocomplete
      const memberInput = page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="input"]');
      await memberInput.fill('Maria');
      await page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="results"] button').first().waitFor({ timeout: 3000 });
      await page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="results"] button').first().click();

      // Fill product autocomplete
      const productInput = page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="input"]');
      await productInput.fill('Salary');
      await page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="results"] button').first().waitFor({ timeout: 3000 });
      await page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="results"] button').first().click();

      await page.getByRole('button', { name: 'Start Application' }).click();

      // Should redirect to edit wizard
      await expect(page).toHaveURL(/\/loans\/applications\/[\w-]+\/edit/);
      await expect(page.getByText('Loan Details')).toBeVisible();
      await expect(page.getByText('Income Sources')).toBeVisible();
      await expect(page.getByText('Collaterals')).toBeVisible();
      await expect(page.getByText('Schedule')).toBeVisible();
    });

    test('navigates through wizard steps with validation', async ({ page }) => {
      await page.goto('/loans/applications/new');

      // Fill and submit to create application
      const memberInput = page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="input"]');
      await memberInput.fill('Maria');
      await page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="results"] button').first().waitFor({ timeout: 3000 });
      await page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="results"] button').first().click();

      const productInput = page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="input"]');
      await productInput.fill('Salary');
      await page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="results"] button').first().waitFor({ timeout: 3000 });
      await page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="results"] button').first().click();

      await page.getByRole('button', { name: 'Start Application' }).click();
      await expect(page).toHaveURL(/\/loans\/applications\/[\w-]+\/edit/);

      // Step 1: Loan Details — fill required fields
      await page.getByLabel(/Loan Amount/i).fill('50000');
      await page.getByLabel(/Term \(months\)/i).fill('12');
      await expect(page.getByLabel(/Interest Rate/i)).not.toBeEmpty();

      // Click Next to go to step 2
      await page.getByRole('button', { name: 'Next' }).click();

      // Step 2: Income Sources
      await expect(page.getByText('Sources of Income')).toBeVisible();
      await page.locator('select[name*="source_type"]').selectOption('Employment');
      await page.locator('input[name*="monthly_income"]').fill('30000');

      // Next to step 3
      await page.getByRole('button', { name: 'Next' }).click();

      // Step 3: Collaterals
      await expect(page.getByText('Collaterals')).toBeVisible();

      // Next to step 4
      await page.getByRole('button', { name: 'Next' }).click();

      // Step 4: Schedule
      await expect(page.getByText('Repayment Schedule')).toBeVisible();
      await expect(page.getByText(/No repayment schedule generated yet/)).toBeVisible();

      // Generate schedule
      await page.getByRole('button', { name: 'Generate Schedule' }).click();

      // Should generate and stay on step 4
      await expect(page.getByText('Repayment Schedule')).toBeVisible();
    });

    test('validates required fields before advancing', async ({ page }) => {
      await page.goto('/loans/applications/new');

      const memberInput = page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="input"]');
      await memberInput.fill('Maria');
      await page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="results"] button').first().waitFor({ timeout: 3000 });
      await page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="results"] button').first().click();

      const productInput = page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="input"]');
      await productInput.fill('Salary');
      await page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="results"] button').first().waitFor({ timeout: 3000 });
      await page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="results"] button').first().click();

      await page.getByRole('button', { name: 'Start Application' }).click();
      await expect(page).toHaveURL(/\/loans\/applications\/[\w-]+\/edit/);

      // Try to proceed with empty Loan Amount
      await page.getByLabel(/Term \(months\)/i).fill('12');

      // Try Next — should show validation error
      await page.getByRole('button', { name: 'Next' }).click();

      // Should still be on step 1
      await expect(page.getByText('Loan Details')).toBeVisible();
      // Should show field error on amount
      await expect(page.getByText('This field is required')).toBeVisible();
    });

    test('back and forward navigation updates stepper', async ({ page }) => {
      await page.goto('/loans/applications/new');

      const memberInput = page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="input"]');
      await memberInput.fill('Maria');
      await page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="results"] button').first().waitFor({ timeout: 3000 });
      await page.locator('[data-autocomplete-url-value*="/loans/searches/members"] [data-autocomplete-target="results"] button').first().click();

      const productInput = page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="input"]');
      await productInput.fill('Salary');
      await page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="results"] button').first().waitFor({ timeout: 3000 });
      await page.locator('[data-autocomplete-url-value*="/loans/searches/loan_products"] [data-autocomplete-target="results"] button').first().click();

      await page.getByRole('button', { name: 'Start Application' }).click();
      await expect(page).toHaveURL(/\/loans\/applications\/[\w-]+\/edit/);

      // Fill step 1
      await page.getByLabel(/Loan Amount/i).fill('50000');
      await page.getByLabel(/Term \(months\)/i).fill('12');

      // Advance to step 2
      await page.getByRole('button', { name: 'Next' }).click();
      await expect(page.getByText('Sources of Income')).toBeVisible();

      // Go back to step 1
      await page.getByRole('button', { name: 'Back' }).click();
      await expect(page.getByText('Loan Details')).toBeVisible();

      // Advance again to step 2
      await page.getByRole('button', { name: 'Next' }).click();
      await expect(page.getByText('Sources of Income')).toBeVisible();

      // Step count visible
      await expect(page.getByText(/Step 2 of 4/)).toBeVisible();
    });
  });
});
