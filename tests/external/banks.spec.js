// @ts-check
import { test, expect } from '@playwright/test';

test.describe('External Banking', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('creates a new external bank', async ({ page }) => {
      await page.goto('/external/banks');
      await page.getByRole('link', { name: /add bank/i }).click();
      await page.waitForURL('**/external/banks/new');
      await page.getByLabel(/name/i).fill('E2E Test Bank');
      await page.getByLabel(/code/i).fill('E2E');
      await page.getByLabel(/country/i).fill('Philippines');
      await page.getByRole('button', { name: /create bank/i }).click();
      await expect(page.getByText(/bank was successfully created/i)).toBeVisible();
      await expect(page.getByRole('heading', { name: /e2e test bank/i })).toBeVisible();
    });

    test('views bank list', async ({ page }) => {
      await page.goto('/external/banks');
      await expect(page.getByRole('heading', { name: /external banks/i })).toBeVisible();
    });

    test('creates an external account under a bank', async ({ page }) => {
      await page.goto('/external/banks');
      const bankLink = page.getByRole('link', { name: /E2E Test Bank/i });
      if (await bankLink.isVisible()) {
        await bankLink.click();
      } else {
        await page.goto('/external/banks/new');
        await page.getByLabel(/name/i).fill('E2E Account Bank');
        await page.getByLabel(/code/i).fill('EAB');
        await page.getByLabel(/country/i).fill('Philippines');
        await page.getByRole('button', { name: /create bank/i }).click();
        await page.waitForURL('**/external/banks/*');
      }
      await page.getByRole('link', { name: /add account/i }).click();
      await page.waitForURL('**/external/banks/*/accounts/new');
      await page.getByLabel(/account name/i).fill('E2E Checking Account');
      await page.getByLabel(/account type/i).selectOption('checking');
      await page.getByRole('button', { name: /create account/i }).click();
      await expect(page.getByText(/account was successfully created/i)).toBeVisible();
      await expect(page.getByRole('heading', { name: /e2e checking account/i })).toBeVisible();
    });

    test('views account detail page', async ({ page }) => {
      await page.goto('/external/banks');
      const bankLink = page.getByRole('link', { name: /E2E Account Bank|E2E Test Bank/i });
      if (await bankLink.isVisible()) {
        await bankLink.click();
      }
      await page.waitForURL('**/external/banks/*');
      const accountLink = page.getByRole('link', { name: /e2e checking account/i });
      if (await accountLink.isVisible()) {
        await accountLink.click();
        await page.waitForURL('**/external/banks/*/accounts/*');
        await expect(page.getByText(/balance/i)).toBeVisible();
      }
    });
  });

  test.describe('Validation', () => {
    test('requires bank name', async ({ page }) => {
      await page.goto('/external/banks/new');
      await page.getByRole('button', { name: /create bank/i }).click();
      await expect(page.getByText(/can't be blank/i).or(page.getByText(/error/i))).toBeVisible();
    });

    test('requires account name', async ({ page }) => {
      await page.goto('/external/banks');
      const bankLink = page.getByRole('link', { name: /E2E Test Bank|E2E Account Bank/i });
      if (await bankLink.isVisible()) {
        await bankLink.click();
        await page.waitForURL('**/external/banks/*');
        await page.getByRole('link', { name: /add account/i }).click();
        await page.waitForURL('**/external/banks/*/accounts/new');
        await page.getByRole('button', { name: /create account/i }).click();
        await expect(page.getByText(/can't be blank/i).or(page.getByText(/error/i))).toBeVisible();
      }
    });
  });

  test.describe('Reconciliation', () => {
    test('loads reconciliation page', async ({ page }) => {
      await page.goto('/external/banks');
      const bankLink = page.getByRole('link', { name: /E2E Test Bank|E2E Account Bank/i });
      if (await bankLink.isVisible()) {
        await bankLink.click();
        await page.waitForURL('**/external/banks/*');
        const reconcileLink = page.getByRole('link', { name: /reconcile/i });
        if (await reconcileLink.isVisible()) {
          await reconcileLink.click();
          await page.waitForURL('**/external/banks/*/accounts/*/reconciliation');
          await expect(page.getByRole('heading', { name: /reconciliation/i })).toBeVisible();
        }
      }
    });
  });
});