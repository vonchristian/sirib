// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Cash Session Tabs & Row Expansion', () => {
  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('tab click updates URL hash and switches visible panel', async ({ page }) => {
      await page.goto('/treasury/cash_sessions');
      await page.getByRole('link', { name: /View/ }).first().click();
      await expect(page).toHaveURL(/\/treasury\/cash_sessions\/\d+/);

      // Click Disbursements tab
      await page.getByRole('button', { name: /Disbursements/i }).click();
      await expect(page).toHaveURL(/#disbursements/);

      // Click Receipts tab
      await page.getByRole('button', { name: /Receipts/i }).click();
      await expect(page).toHaveURL(/#receipts/);
    });

    test('navigating with URL hash opens correct tab', async ({ page }) => {
      // Open the page with #disbursements hash
      await page.goto('/treasury/cash_sessions');
      await page.getByRole('link', { name: /View/ }).first().click();
      const url = page.url();
      await page.goto(`${url}#disbursements`);
      await expect(page).toHaveURL(/#disbursements/);

      // The Disbursements tab should be visually active
      await expect(page.getByRole('button', { name: /Disbursements/i })).toHaveClass(/border-primary/);
      await expect(page.getByRole('button', { name: /Receipts/i })).toHaveClass(/border-transparent/);
    });

    test('clicking a table row expands debit/credit details', async ({ page }) => {
      // The test needs at least one receipt to be clickable
      // We use an existing session that has posted vouchers
      await page.goto('/treasury/cash_sessions');
      await page.getByRole('link', { name: /View/ }).first().click();

      // If there are receipts, try clicking the first row
      const receiptRow = page.locator('#tab-receipts tbody tr:not(.hidden)').first();
      if (await receiptRow.count() > 0) {
        await receiptRow.click();

        // The detail row should now be visible
        const expandedClass = await receiptRow.getAttribute('class');
        expect(expandedClass).toContain('is-expanded');
      }
    });
  });
});
