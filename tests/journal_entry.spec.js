// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Journal Entry', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/accounting/entries/new');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('shows the entry form with description, date, and lines table', async ({ page }) => {
      await page.goto('/accounting/entries/new');
      await expect(page.locator('input[name="entry[description]"]')).toBeVisible();
      await expect(page.locator('input[name="entry[posted_at]"]')).toBeVisible();
      await expect(page.locator('th')).toContainText(['Account', 'Debit', 'Credit']);
    });

    test('has two initial blank lines', async ({ page }) => {
      await page.goto('/accounting/entries/new');
      const rows = page.locator('[data-entry-form-target="line"]');
      await expect(rows).toHaveCount(2);
    });

    test('adds a new line when clicking Add Line', async ({ page }) => {
      await page.goto('/accounting/entries/new');
      await page.getByText('Add Line').click();
      const rows = page.locator('[data-entry-form-target="line"]');
      await expect(rows).toHaveCount(3);
    });

    test('removes a line when clicking remove button', async ({ page }) => {
      await page.goto('/accounting/entries/new');
      const removeButtons = page.locator('[data-action="entry-form#removeLine"]');
      await removeButtons.first().click();
      const rows = page.locator('[data-entry-form-target="line"]');
      await expect(rows).toHaveCount(1);
    });

    test('shows unbalanced warning when debits do not equal credits', async ({ page }) => {
      await page.goto('/accounting/entries/new');
      await page.locator('[data-entry-form-role="debit"]').first().fill('500');
      await page.locator('[data-entry-form-role="credit"]').nth(1).fill('300');
      await expect(page.getByText(/debits and credits do not balance/i)).toBeVisible();
    });

    test('successfully creates a balanced adjusting entry', async ({ page }) => {
      await page.goto('/accounting/entries/new');
      await page.locator('input[name="entry[description]"]').fill('Test adjusting entry');
      await page.locator('input[name="entry[posted_at]"]').fill('2025-06-30');

      const debitSelect = page.locator('[data-entry-form-target="line"]').nth(0).locator('select');
      await debitSelect.selectOption('11131 — PNB Savings Account');

      const creditSelect = page.locator('[data-entry-form-target="line"]').nth(1).locator('select');
      await creditSelect.selectOption('40110 — Interest Income from Loans');

      await page.locator('[data-entry-form-role="debit"]').first().fill('1000');
      await page.locator('[data-entry-form-role="credit"]').nth(1).fill('1000');

      await page.locator('input[type="submit"]').press('Enter');

      await expect(page.locator('text=Entry created successfully')).toBeVisible();
    });

    test('shows validation errors for unbalanced entry', async ({ page }) => {
      await page.goto('/accounting/entries/new');
      await page.locator('input[name="entry[description]"]').fill('Unbalanced test entry');

      const debitSelect = page.locator('[data-entry-form-target="line"]').nth(0).locator('select');
      await debitSelect.selectOption('11131 — PNB Savings Account');

      const creditSelect = page.locator('[data-entry-form-target="line"]').nth(1).locator('select');
      await creditSelect.selectOption('40110 — Interest Income from Loans');

      await page.locator('[data-entry-form-role="debit"]').first().fill('500');
      await page.locator('[data-entry-form-role="credit"]').nth(1).fill('400');

      await page.locator('input[type="submit"]').press('Enter');

      await expect(page.locator('text=error')).toBeVisible();
    });

    test('sidebar has Accounting section with Journal Entry link', async ({ page }) => {
      await page.goto('/');
      await expect(page.getByText('Accounting')).toBeVisible();
      await expect(page.getByText('Journal Entry')).toBeVisible();
    });

    test('clicking Journal Entry sidebar link navigates to the form', async ({ page }) => {
      await page.goto('/');
      await page.getByText('Journal Entry').click();
      await expect(page).toHaveURL(/\/accounting\/entries\/new/);
      await expect(page.locator('input[name="entry[description]"]')).toBeVisible();
    });
  });
});
