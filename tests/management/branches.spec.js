// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Branches', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('displays branch list', async ({ page }) => {
      await page.goto('/management/branches');
      const table = page.getByRole('table');
      await expect(page.getByRole('heading', { name: /branches/i })).toBeVisible();
      await expect(table.getByText(/head office/i)).toBeVisible();
      await expect(table.getByText(/makati/i)).toBeVisible();
      await expect(table.getByText(/quezon city/i)).toBeVisible();
    });

    test('creates a new branch', async ({ page }) => {
      await page.goto('/management/branches/new');
      await page.getByLabel(/name/i).fill('E2E Test Branch');
      await page.getByLabel(/^code$/i).fill('E2E');
      await page.getByLabel(/address/i).fill('123 Test Street');
      await page.getByLabel(/phone/i).fill('+63-2-555-9999');
      await page.getByLabel(/email/i).fill('e2e@test.com');
      await page.getByLabel(/status/i).selectOption('active');
      await page.getByRole('button', { name: /create branch/i }).click();
      await expect(page.getByText(/branch was successfully created/i)).toBeVisible();
      await expect(page.getByRole('heading', { name: /e2e test branch/i })).toBeVisible();
    });

    test('views branch details', async ({ page }) => {
      await page.goto('/management/branches');
      await page.getByRole('link', { name: /head office/i }).first().click();
      await page.waitForURL('**/management/branches/*');
      await expect(page.locator('h1')).toHaveText(/head office/i);
      await expect(page.getByRole('heading', { name: /head office/i })).toBeVisible();
    });

    test('edits an existing branch', async ({ page }) => {
      await page.goto('/management/branches');
      await page.getByRole('link', { name: /edit/i }).first().click();
      await page.getByLabel(/name/i).clear();
      await page.getByLabel(/name/i).fill('E2E Updated Branch');
      await page.getByRole('button', { name: /update branch/i }).click();
      await expect(page.getByText(/branch was successfully updated/i)).toBeVisible();
      // Revert name so other tests are not affected
      await page.getByRole('link', { name: /back/i }).click();
      await page.getByRole('link', { name: /edit/i }).first().click();
      await page.getByLabel(/name/i).clear();
      await page.getByLabel(/name/i).fill('Head Office');
      await page.getByRole('button', { name: /update branch/i }).click();
      await expect(page.getByText(/branch was successfully updated/i)).toBeVisible();
    });

    test('displays departments on branch show page', async ({ page }) => {
      await page.goto('/management/branches');
      await page.getByRole('link', { name: /head office/i }).first().click();
      await page.getByRole('heading', { name: /head office/i }).waitFor();
      await expect(page.getByText(/administration/i).first()).toBeVisible();
    });
  });

  test.describe('Validation', () => {
    test('requires name', async ({ page }) => {
      await page.goto('/management/branches/new');
      await page.getByLabel(/^code$/i).fill('VAL');
      await page.getByRole('button', { name: /create branch/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('requires code', async ({ page }) => {
      await page.goto('/management/branches/new');
      await page.getByLabel(/name/i).fill('Validation Test');
      await page.getByRole('button', { name: /create branch/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('validates duplicate code', async ({ page }) => {
      await page.goto('/management/branches/new');
      await page.getByLabel(/name/i).fill('Dup Branch');
      await page.getByLabel(/^code$/i).fill('HQ');
      await page.getByRole('button', { name: /create branch/i }).click();
      await expect(page.getByText(/already been taken/i)).toBeVisible();
    });
  });

  test.describe('Search', () => {
    test('searches branches by name', async ({ page }) => {
      await page.goto('/management/branches');
      await page.getByPlaceholder(/search by name/i).fill('Makati');
      await page.getByRole('button', { name: /search/i }).click();
      await expect(page.getByText(/makati branch/i)).toBeVisible();
    });

    test('shows empty state for no results', async ({ page }) => {
      await page.goto('/management/branches');
      await page.getByPlaceholder(/search by name/i).fill('zzzzz');
      await page.getByRole('button', { name: /search/i }).click();
      await expect(page.getByText(/no branches found/i)).toBeVisible();
    });
  });
});
