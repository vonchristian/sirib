// @ts-check
import { test, expect } from '@playwright/test';

// Member names match the seed data (db/seeds/members.rb) — Member#name returns [first, middle, last].join(" ")
const memberNames = [
  'Maria Santos Cruz',
  'Juan Dela Reyes',
  'Elena Garcia Villanueva',
  'Jose Rizal Mercado',
  'Ana Luna Dimagiba',
  'Pedro M. Santos',
  'Sofia C. Gonzales',
  'Carlos B. Yulo',
  'Luz V. Macapagal',
  'Ramon D. Alcantara',
  'Isabel T. Samson',
  'Antonio L. Lopez',
  'Carmen P. Natividad',
  'Victor S. Mendoza',
  'Lorna R. Fernandez',
  'Danilo E. Rivera',
  'Gloria M. Romero',
  'Fernando A. Ramos',
  'Rosario B. Castillo',
  'Miguel N. Angeles'
];

const openAccount = async (page, memberName) => {
  await page.goto('/equity/accounts/new');
  await page.getByLabel(/Share Capital Product/i).selectOption({ index: 1 });
  await page.getByLabel(/Member/i).selectOption({ label: memberName });
  await page.getByRole('button', { name: /Open Account/i }).click();
  await expect(page.getByText('Share capital account opened.')).toBeVisible();
};

test.describe('Share Capital', () => {
  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test.describe('Product Management', () => {
      test('creates a share capital product', async ({ page }) => {
        await page.goto('/equity/products/new');

        await page.getByLabel(/Product Code/i).fill('TEST01');
        await page.getByLabel(/Share Type/i).selectOption('Common');
        await page.getByLabel(/Product Name/i).fill('E2E Test Shares');
        await page.getByLabel(/Description/i).fill('Created by e2e test');
        await page.getByLabel(/Status/i).selectOption('Active');
        await page.getByLabel(/Price Per Share \(cents\)/i).fill('5000');
        await page.getByLabel(/Minimum Required Shares/i).fill('20');
        await page.getByLabel(/Maximum Allowed Shares/i).fill('200');
        await page.getByLabel(/Minimum Initial Purchase/i).fill('5');

        await page.getByRole('button', { name: /Create Product/i }).click();

        await expect(page.getByText('Share capital product created.')).toBeVisible();
        await expect(page.getByRole('heading', { name: 'E2E Test Shares' }).first()).toBeVisible();
      });

      test('displays product list', async ({ page }) => {
        await page.goto('/equity/products');
        await expect(page.getByText('Common Shares').first()).toBeVisible();
        await expect(page.getByText('Preferred Shares').first()).toBeVisible();
      });

      test('shows product details', async ({ page }) => {
        await page.goto('/equity/products');
        await page.getByText('Common Shares').first().click();

        await expect(page.getByRole('heading', { name: 'Common Shares' })).toBeVisible();
        await expect(page.getByText(/₱100\.00/).first()).toBeVisible();
        await expect(page.locator('dd').filter({ hasText: '50' }).first()).toBeVisible();
        await expect(page.locator('dd').filter({ hasText: '500' }).first()).toBeVisible();
      });

      test('validates duplicate product code', async ({ page }) => {
        await page.goto('/equity/products/new');
        await page.getByLabel(/Product Code/i).fill('COMMON');
        await page.getByLabel(/Share Type/i).selectOption('Common');
        await page.getByLabel(/Product Name/i).fill('Duplicate Test');
        await page.getByLabel(/Price Per Share \(cents\)/i).fill('5000');
        await page.getByLabel(/Minimum Required Shares/i).fill('10');
        await page.getByLabel(/Minimum Initial Purchase/i).fill('5');
        await page.getByRole('button', { name: /Create Product/i }).click();
        await expect(page.getByText(/already been taken/i)).toBeVisible();
      });

      test('validates minimum shares not greater than maximum', async ({ page }) => {
        await page.goto('/equity/products/new');
        await page.getByLabel(/Product Code/i).fill('VALIDATE01');
        await page.getByLabel(/Share Type/i).selectOption('Common');
        await page.getByLabel(/Product Name/i).fill('Validation Test');
        await page.getByLabel(/Price Per Share \(cents\)/i).fill('5000');
        await page.getByLabel(/Minimum Required Shares/i).fill('100');
        await page.getByLabel(/Maximum Allowed Shares/i).fill('50');
        await page.getByLabel(/Minimum Initial Purchase/i).fill('5');
        await page.getByRole('button', { name: /Create Product/i }).click();
        await expect(page.getByText(/must be greater than minimum/i)).toBeVisible();
      });
    });

    test.describe('Account Management', () => {
      test('opens a share capital account for a member', async ({ page }) => {
        await openAccount(page, memberNames[0]);
        await expect(page.getByText(/Share Progress/)).toBeVisible();
        await expect(page.getByRole('link', { name: /Buy Shares/i })).toBeVisible();
      });

      test('displays share progress correctly', async ({ page }) => {
        await openAccount(page, memberNames[1]);
        await expect(page.locator('dd').filter({ hasText: '0' }).first()).toBeVisible();
        await expect(page.getByText(/0%/).first()).toBeVisible();
        await expect(page.getByText('50').first()).toBeVisible();
        await expect(page.getByText(/₱0\.00/).first()).toBeVisible();
      });

      test('shows accounts list', async ({ page }) => {
        await openAccount(page, memberNames[2]);
        await page.goto('/equity/accounts');
        await expect(page.getByText(/SC-/).first()).toBeVisible();
        await expect(page.getByText('Common Shares').first()).toBeVisible();
      });
    });

    test.describe('Buy Shares', () => {
      test('shows buy shares form', async ({ page }) => {
        await openAccount(page, memberNames[3]);
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await expect(page).toHaveURL(/\/buy$/);
        await expect(page.getByText(/₱100\.00 per share/)).toBeVisible();
        await expect(page.getByLabel(/Amount \(₱\)/i)).toBeVisible();
      });

      test('previews purchase before confirming', async ({ page }) => {
        await openAccount(page, memberNames[4]);
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await page.getByLabel(/Amount \(₱\)/i).fill('2500');
        await page.getByRole('button', { name: /Preview Purchase/i }).click();
        await expect(page.getByRole('button', { name: /Confirm Purchase/i })).toBeVisible();
        await expect(page.getByText(/Confirmation/)).toBeVisible();
        await expect(page.getByText(/₱2,500\.00/).first()).toBeVisible();
        await expect(page.getByText('Shares to Purchase')).toBeVisible();
      });

      test('completes a share purchase', async ({ page }) => {
        await openAccount(page, memberNames[5]);
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await page.getByLabel(/Amount \(₱\)/i).fill('2500');
        await page.getByRole('button', { name: /Preview Purchase/i }).click();
        await expect(page.getByRole('button', { name: /Confirm Purchase/i })).toBeVisible();
        await page.getByRole('button', { name: /Confirm Purchase/i }).click();
        await expect(page.getByText(/Successfully purchased 25 shares/)).toBeVisible();
        await expect(page.getByText('25').first()).toBeVisible();
        await expect(page.getByText(/₱2,500\.00/).first()).toBeVisible();
      });

      test('validates zero amount', async ({ page }) => {
        await openAccount(page, memberNames[6]);
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await page.getByLabel(/Amount \(₱\)/i).fill('0');
        await page.getByRole('button', { name: /Preview Purchase/i }).click();
        await expect(page.getByText(/must be greater than zero/i)).toBeVisible();
      });

      test('validates insufficient amount for one share', async ({ page }) => {
        await openAccount(page, memberNames[7]);
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await page.getByLabel(/Amount \(₱\)/i).fill('50');
        await page.getByRole('button', { name: /Preview Purchase/i }).click();
        await expect(page.getByText(/at least ₱100\.00/)).toBeVisible();
      });

      test('edits amount from preview', async ({ page }) => {
        await openAccount(page, memberNames[8]);
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await page.getByLabel(/Amount \(₱\)/i).fill('2500');
        await page.getByRole('button', { name: /Preview Purchase/i }).click();
        await expect(page.getByRole('button', { name: /Confirm Purchase/i })).toBeVisible();
        await page.getByRole('link', { name: /Edit/i }).click();
        await expect(page).toHaveURL(/\/buy(\?|$)/);
      });

      test('cancels at preview stage', async ({ page }) => {
        await openAccount(page, memberNames[9]);
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await page.getByLabel(/Amount \(₱\)/i).fill('2500');
        await page.getByRole('button', { name: /Preview Purchase/i }).click();
        await page.getByRole('link', { name: 'Cancel' }).first().click();
        await expect(page).toHaveURL(/\/equity\/accounts\/\d+$/);
      });

      test('increases share count on second purchase', async ({ page }) => {
        await openAccount(page, memberNames[10]);
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await page.getByLabel(/Amount \(₱\)/i).fill('2500');
        await page.getByRole('button', { name: /Preview Purchase/i }).click();
        await page.getByRole('button', { name: /Confirm Purchase/i }).click();
        await expect(page.getByText(/Successfully purchased 25 shares/)).toBeVisible();
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await page.getByLabel(/Amount \(₱\)/i).fill('3000');
        await page.getByRole('button', { name: /Preview Purchase/i }).click();
        await page.getByRole('button', { name: /Confirm Purchase/i }).click();
        await expect(page.getByText(/Successfully purchased 30 shares/)).toBeVisible();
        await expect(page.getByText('55').first()).toBeVisible();
      });

      test('validates minimum initial purchase', async ({ page }) => {
        await openAccount(page, memberNames[11]);
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await page.getByLabel(/Amount \(₱\)/i).fill('999');
        await page.getByRole('button', { name: /Preview Purchase/i }).click();
        await expect(page.getByText(/minimum initial purchase/i)).toBeVisible();
      });
    });

    test.describe('Accounting Integration', () => {
      test('creates equity ledger for product', async ({ page }) => {
        await page.goto('/equity/products/new');
        await page.getByLabel(/Product Code/i).fill('ACCTEST');
        await page.getByLabel(/Share Type/i).selectOption('Common');
        await page.getByLabel(/Product Name/i).fill('Accounting Test');
        await page.getByLabel(/Price Per Share \(cents\)/i).fill('5000');
        await page.getByLabel(/Minimum Required Shares/i).fill('10');
        await page.getByLabel(/Minimum Initial Purchase/i).fill('5');
        await page.getByRole('button', { name: /Create Product/i }).click();
        await expect(page.getByText('Share capital product created.')).toBeVisible();
        await expect(page.getByRole('heading', { name: 'Accounting' }).first()).toBeVisible();
        await expect(page.getByText(/Equity Ledger/)).toBeVisible();
      });
    });

    test.describe('Cash Session Integration', () => {
      test('appears as a receipt in the cash session report', async ({ page }) => {
        await openAccount(page, memberNames[12]);
        await page.getByRole('link', { name: /Buy Shares/i }).click();
        await page.getByLabel(/Amount \(₱\)/i).fill('2500');
        await page.getByRole('button', { name: /Preview Purchase/i }).click();
        await page.getByRole('button', { name: /Confirm Purchase/i }).click();
        await expect(page.getByText(/Successfully purchased/)).toBeVisible();

        await page.goto('/treasury/cash_sessions');
        await page.getByRole('link', { name: /View/ }).first().click();
        await expect(page.getByText(/Share Capital Purchase/).first()).toBeVisible();
        await expect(page.getByText(/₱2,500\.00/).first()).toBeVisible();
      });
    });

    test.describe('Navigation', () => {
      test('navigates to share capital via sidebar', async ({ page }) => {
        await page.goto('/dashboard');
        await page.getByRole('link', { name: /Share Capital/i }).click();
        await expect(page).toHaveURL(/\/equity\/accounts/);
      });

      test('navigates to products page', async ({ page }) => {
        await page.goto('/equity/products');
        await expect(page.getByRole('heading', { name: 'Share Capital Products' }).first()).toBeVisible();
      });
    });
  });
});
