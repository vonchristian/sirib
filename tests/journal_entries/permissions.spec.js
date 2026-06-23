import { test, expect } from '@playwright/test';

test.describe('Journal Entries Permissions', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test('redirects unauthenticated user from show page', async ({ page }) => {
    await page.goto('/accounting/journal_entries/1');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test('redirects unauthenticated user from new entry page', async ({ page }) => {
    await page.goto('/accounting/journal_entries/new');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('accountant can access journal entries index', async ({ page }) => {
      await page.goto('/accounting/journal_entries');
      await expect(response).to have_http_status(:ok);
    });

    test('accountant can view entry details', async ({ page }) => {
      await page.goto('/accounting/journal_entries');
      const firstRow = page.locator('[data-testid="journal-row"]').first();
      await firstRow.locator('a:has-text("View")').click();
      await expect(page).toHaveURL(/\/accounting\/journal_entries\/\d+/);
    });

    test('sidebar has Journal Entries link', async ({ page }) => {
      await page.goto('/');
      await expect(page.getByText('Journal Entries')).toBeVisible();
    });

    test('new entry link requires authentication', async ({ page }) => {
      await page.goto('/accounting/journal_entries/new');
      await expect(page).toHaveURL(/\/session\/new/);
    });
  });
});