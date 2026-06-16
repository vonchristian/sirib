// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Time Deposit', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/treasury/time_deposits');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test('redirects unauthenticated user to sign in for new', async ({ page }) => {
    await page.goto('/treasury/time_deposits/new');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('shows empty state when no deposits exist', async ({ page }) => {
      await page.goto('/treasury/time_deposits');
      await expect(page.getByText('No time deposits yet')).toBeVisible();
      await expect(page.getByText('Open a Time Deposit')).toBeVisible();
    });

    test('new form shows product selector and amount field', async ({ page }) => {
      await page.goto('/treasury/time_deposits/new');
      await expect(page.getByLabel('Product')).toBeVisible();
      await expect(page.getByLabel('Amount')).toBeVisible();
      await expect(page.getByRole('button', { name: 'Preview' })).toBeVisible();
    });

    test('preview calculates interest and maturity date', async ({ page }) => {
      await page.goto('/treasury/time_deposits/new');
      await page.getByLabel('Product').selectOption({ index: 1 });
      await page.getByLabel('Amount').fill('10000');
      await page.getByRole('button', { name: 'Preview' }).click();

      await expect(page.getByText('Interest Earnings')).toBeVisible();
      await expect(page.getByText(/day/)).toBeVisible();
      await expect(page.getByText('Maturity Date')).toBeVisible();
      await expect(page.getByRole('button', { name: 'Confirm & Open' })).toBeVisible();
    });

    test('shows error for amount below minimum deposit', async ({ page }) => {
      await page.goto('/treasury/time_deposits/new');
      await page.getByLabel('Product').selectOption({ index: 1 });
      await page.getByLabel('Amount').fill('100');
      await page.getByRole('button', { name: 'Preview' }).click();

      await expect(page.getByText(/minimum deposit/i)).toBeVisible();
    });

    test('full end-to-end: open a time deposit and verify journal entry', async ({ page }) => {
      await page.goto('/treasury/time_deposits/new');

      await page.getByLabel('Product').selectOption({ index: 1 });
      await page.getByLabel('Amount').fill('5000');
      await page.getByRole('button', { name: 'Preview' }).click();

      await expect(page.getByText('Preview Time Deposit')).toBeVisible();
      await expect(page.getByText('₱5,000.00')).toBeVisible();
      await expect(page.getByText('Interest Earnings')).toBeVisible();

      await page.getByRole('button', { name: 'Confirm & Open' }).click();

      await expect(page).toHaveURL(/\/treasury\/time_deposits\/\d+/);
      await expect(page.getByRole('heading', { name: 'Time Deposit Opened' })).toBeVisible();
      await expect(page.getByText('₱5,000.00')).toBeVisible();
      await expect(page.getByText('Active')).toBeVisible();

      await page.goto('/accounting/entries');
      await expect(page.getByText(/time deposit/i)).toBeVisible();
    });

    test('index page lists opened deposits', async ({ page }) => {
      await page.goto('/treasury/time_deposits/new');

      await page.getByLabel('Product').selectOption({ index: 1 });
      await page.getByLabel('Amount').fill('5000');
      await page.getByRole('button', { name: 'Preview' }).click();
      await page.getByRole('button', { name: 'Confirm & Open' }).click();

      await page.goto('/treasury/time_deposits');
      await expect(page.getByText('30-Day Time Deposit')).toBeVisible();
      await expect(page.getByText('₱5,000.00')).toBeVisible();
    });
  });
});
