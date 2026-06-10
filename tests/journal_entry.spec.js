// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Journal Entry', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/accounting/entries/new');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('shows the entry form with description, date, and lines', async ({ page }) => {
      await page.goto('/accounting/entries/new');
      await expect(page.locator('textarea[name="entry[description]"]')).toBeVisible();
      await expect(page.locator('input[name="entry[posted_at]"]')).toBeVisible();
      await expect(page.locator('[data-entry-form-target="line"]')).toHaveCount(2);
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
      await page.locator('[data-entry-form-role="amount"]').first().fill('500');
      const lines = page.locator('[data-entry-form-target="line"]');
      const creditDropdown = lines.nth(1).locator('[data-entry-form-role="direction"]');
      await creditDropdown.selectOption('credit');
      await page.locator('[data-entry-form-role="amount"]').nth(1).fill('300');
      await expect(page.getByText(/difference/i)).toBeVisible();
    });

    test('successfully creates a balanced adjusting entry', async ({ page }) => {
      await page.goto('/accounting/entries/new');
      await page.locator('textarea[name="entry[description]"]').fill('Test adjusting entry');
      await page.locator('input[name="entry[posted_at]"]').fill('2025-06-30');

      const debitRow = page.locator('[data-entry-form-target="line"]').nth(0);
      const debitInput = debitRow.locator('[data-typeahead-target="input"]');
      await debitInput.fill('PNB');
      await expect(debitRow.locator('[role="option"]').first()).toBeVisible({ timeout: 5000 });
      await debitRow.locator('[role="option"]').first().click();

      const creditRow = page.locator('[data-entry-form-target="line"]').nth(1);
      const creditInput = creditRow.locator('[data-typeahead-target="input"]');
      await creditInput.fill('Interest Income');
      await expect(creditRow.locator('[role="option"]').first()).toBeVisible({ timeout: 5000 });
      await creditRow.locator('[role="option"]').first().click();

      await creditRow.locator('[data-entry-form-role="direction"]').selectOption('credit');
      await page.locator('[data-entry-form-role="amount"]').first().fill('1000');
      await page.locator('[data-entry-form-role="amount"]').nth(1).fill('1000');

      await page.locator('input[type="submit"]').press('Enter');

      await expect(page).toHaveURL(/\/accounting\/entries\/\d+/);
      await expect(page.locator('text=Entry created successfully')).toBeVisible();
    });

    test('shows validation errors for unbalanced entry', async ({ page }) => {
      await page.goto('/accounting/entries/new');
      await page.locator('textarea[name="entry[description]"]').fill('Unbalanced test entry');

      const debitRow = page.locator('[data-entry-form-target="line"]').nth(0);
      const debitInput = debitRow.locator('[data-typeahead-target="input"]');
      await debitInput.fill('PNB');
      await expect(debitRow.locator('[role="option"]').first()).toBeVisible({ timeout: 5000 });
      await debitRow.locator('[role="option"]').first().click();

      const creditRow = page.locator('[data-entry-form-target="line"]').nth(1);
      const creditInput = creditRow.locator('[data-typeahead-target="input"]');
      await creditInput.fill('Interest Income');
      await expect(creditRow.locator('[role="option"]').first()).toBeVisible({ timeout: 5000 });
      await creditRow.locator('[role="option"]').first().click();

      await creditRow.locator('[data-entry-form-role="direction"]').selectOption('credit');
      await page.locator('[data-entry-form-role="amount"]').first().fill('500');
      await page.locator('[data-entry-form-role="amount"]').nth(1).fill('400');

      await page.locator('input[type="submit"]').press('Enter');

      await expect(page.locator('text=error')).toBeVisible();
    });

    test('sidebar has Accounting section with Journal Entries link', async ({ page }) => {
      await page.goto('/');
      await expect(page.getByText('Accounting')).toBeVisible();
      await expect(page.getByText('Journal Entries')).toBeVisible();
    });

    test('New Entry button on index page navigates to the form', async ({ page }) => {
      await page.goto('/accounting/entries');
      await page.getByText('New Entry').click();
      await expect(page).toHaveURL(/\/accounting\/entries\/new/);
      await expect(page.locator('textarea[name="entry[description]"]')).toBeVisible();
    });
  });
});
