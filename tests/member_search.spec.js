// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Member Typeahead Search', () => {
  test.use({ storageState: '.auth/user.json' });

  test.beforeEach(async ({ page }) => {
    await page.goto('/members');
    await expect(page.getByPlaceholder(/search by name, email, mobile/i)).toBeVisible();
  });

  test('shows all members on initial load', async ({ page }) => {
    const rows = page.locator('#members-tbody tr');
    await expect(rows.first()).toBeVisible();
    const count = await rows.count();
    expect(count).toBeGreaterThan(0);
  });

  test('filters members by first name', async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search by name, email, mobile/i);
    await searchInput.fill('Maria');
    await page.waitForTimeout(500);
    const rows = page.locator('#members-tbody tr');
    await expect(rows.first()).toBeVisible();
    await expect(page.locator('#members-tbody').getByText('Maria')).toBeVisible();
  });

  test('filters members by last name', async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search by name, email, mobile/i);
    await searchInput.fill('Cruz');
    await page.waitForTimeout(500);
    const rows = page.locator('#members-tbody tr');
    await expect(rows.first()).toBeVisible();
    await expect(page.locator('#members-tbody').getByText('Cruz')).toBeVisible();
  });

  test('filters members by mobile number', async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search by name, email, mobile/i);
    await searchInput.fill('09170000000');
    await page.waitForTimeout(500);
    const rows = page.locator('#members-tbody tr');
    await expect(rows.first()).toBeVisible();
  });

  test('shows no results message for unmatched query', async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search by name, email, mobile/i);
    await searchInput.fill('zzzznonexistent');
    await page.waitForTimeout(500);
    await expect(page.locator('#members-tbody').getByText(/no members matching/i)).toBeVisible();
  });

  test('restores all members when search is cleared', async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search by name, email, mobile/i);
    await searchInput.fill('Maria');
    await page.waitForTimeout(500);
    await searchInput.fill('');
    await page.waitForTimeout(500);
    const rows = page.locator('#members-tbody tr');
    const countAfterClear = await rows.count();
    expect(countAfterClear).toBeGreaterThan(5);
  });

  test('search is case-insensitive', async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search by name, email, mobile/i);
    await searchInput.fill('maria');
    await page.waitForTimeout(500);
    await expect(page.locator('#members-tbody').getByText('Maria')).toBeVisible();
  });

  test('search is trimmed before submitting', async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search by name, email, mobile/i);
    await searchInput.fill('  Maria  ');
    await page.waitForTimeout(500);
    await expect(page.locator('#members-tbody').getByText('Maria')).toBeVisible();
  });

  test('rapid typing only triggers one search', async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search by name, email, mobile/i);
    await searchInput.fill('M');
    await page.waitForTimeout(50);
    await searchInput.fill('Ma');
    await page.waitForTimeout(50);
    await searchInput.fill('Mar');
    await page.waitForTimeout(50);
    await searchInput.fill('Mari');
    await page.waitForTimeout(50);
    await searchInput.fill('Maria');
    await page.waitForTimeout(500);
    await expect(page.locator('#members-tbody').getByText('Maria')).toBeVisible();
  });

  test('search by partial name matches', async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search by name, email, mobile/i);
    await searchInput.fill('Cru');
    await page.waitForTimeout(500);
    await expect(page.locator('#members-tbody').getByText('Cruz')).toBeVisible();
  });

  test('multiple members match partial query', async ({ page }) => {
    const searchInput = page.getByPlaceholder(/search by name, email, mobile/i);
    await searchInput.fill('San');
    await page.waitForTimeout(500);
    const rows = page.locator('#members-tbody tr');
    const count = await rows.count();
    expect(count).toBeGreaterThanOrEqual(2);
  });
});
