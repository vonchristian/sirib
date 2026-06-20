// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Entry Templates', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('lists entry templates', async ({ page }) => {
      await page.goto('/management/entry_templates');
      await expect(page.getByRole('heading', { name: /entry templates/i })).toBeVisible();
    });

    test('creates a new template', async ({ page }) => {
      await page.goto('/management/entry_templates/new');
      await page.getByLabel(/name/i).fill('E2E Test Template');
      await page.getByLabel(/description/i).fill('Created during E2E test');

      // First line: debit variable
      await page.getByLabel(/account/i).first().selectOption({ index: 1 });
      await page.locator('select').filter({ hasText: /debit|credit/i }).first().selectOption('debit');
      await page.locator('select').filter({ hasText: /variable|fixed/i }).first().selectOption('variable');
      await page.getByLabel(/seq/i).first().fill('1');

      // Add second line: credit variable
      await page.getByText(/add line/i).click();
      const selects = page.locator('select');
      await selects.nth(2).selectOption({ index: 2 });
      await page.locator('select').filter({ hasText: /debit|credit/i }).nth(1).selectOption('credit');
      await page.locator('select').filter({ hasText: /variable|fixed/i }).nth(1).selectOption('variable');
      await page.getByLabel(/seq/i).nth(1).fill('2');

      await page.getByRole('button', { name: /create/i }).click();
      await expect(page.getByText(/template created successfully/i)).toBeVisible();
    });

    test('views a template', async ({ page }) => {
      await page.goto('/management/entry_templates');
      const links = page.getByRole('link', { name: /edit/i });
      await links.first().click();
      await expect(page.getByRole('heading', { name: /edit/i })).toBeVisible();
    });

    test('edits a template', async ({ page }) => {
      await page.goto('/management/entry_templates');
      await page.getByRole('link', { name: /edit/i }).first().click();
      await page.getByLabel(/name/i).clear();
      await page.getByLabel(/name/i).fill('E2E Updated Template');
      await page.getByRole('button', { name: /update/i }).click();
      await expect(page.getByText(/template updated successfully/i)).toBeVisible();
    });

    test('previews an entry from a template', async ({ page }) => {
      await page.goto('/management/entry_templates');
      await page.getByRole('link', { name: /edit/i }).first().click();
      await page.goto('/management/entry_templates');
      await page.locator('a[href*="/management/entry_templates/"]').first().click();
      await expect(page.getByText(/execute template/i)).toBeVisible();

      await page.getByLabel(/amount/i).fill('10000');
      await page.getByRole('button', { name: /preview/i }).click();
      await expect(page.getByText(/debit/i)).toBeVisible();
    });

    test('posts an entry from a template', async ({ page }) => {
      await page.goto('/management/entry_templates');
      const links = page.locator('a[href*="/management/entry_templates/"]');
      const count = await links.count();
      const link = links.nth(count > 2 ? 1 : 0);
      await link.click();
      await expect(page.getByText(/execute template/i)).toBeVisible();

      await page.getByLabel(/amount/i).fill('5000');
      await page.getByRole('button', { name: /preview/i }).click();
      await expect(page.getByText(/debit/i)).toBeVisible();

      await page.getByRole('button', { name: /post entry/i }).click();
      await expect(page.getByText(/posted successfully/i)).toBeVisible();
    });
  });

  test.describe('Validation', () => {
    test('requires name', async ({ page }) => {
      await page.goto('/management/entry_templates/new');
      await page.getByRole('button', { name: /create/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });
  });
});
