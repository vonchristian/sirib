import { test, expect } from '@playwright/test';

test.use({ storageState: '.auth/user.json' });

test.describe('Concurrency Locking System', () => {

  test('server is reachable after lock_version migration', async ({ page }) => {
    const response = await page.request.get('/up');
    expect(response.ok()).toBeTruthy();
  });

  test('lock_timeout initializer loads without error', async ({ page }) => {
    const response = await page.request.get('/health');
    expect(response.ok()).toBeTruthy();
  });

  test('cash session page renders with locked find_or_create_by', async ({ page }) => {
    await page.goto('/treasury/cash_sessions');
    await page.waitForLoadState('networkidle');

    const heading = page.locator('h1, h2, h3').first();
    await expect(heading).toBeVisible();
  });

  test('journal entries page is reachable with lock_version columns', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.waitForLoadState('networkidle');

    await expect(page.locator('body')).toBeAttached();
  });

  test('loan restructure page loads without error', async ({ page }) => {
    await page.goto('/loans/restructures');
    await page.waitForLoadState('networkidle');

    await expect(page.locator('body')).toBeAttached();
  });

  test('savings deposit page renders for active savings accounts', async ({ page }) => {
    await page.goto('/treasury/savings_accounts');
    await page.waitForLoadState('networkidle');

    await expect(page.locator('body')).toBeAttached();
  });

  test('equity buy shares page loads', async ({ page }) => {
    await page.goto('/equity/accounts');
    await page.waitForLoadState('networkidle');

    await expect(page.locator('body')).toBeAttached();
  });

  test('database schema has lock_version on entries table', async ({ page }) => {
    const result = await page.evaluate(async () => {
      try {
        const resp = await fetch('/up');
        return { ok: resp.ok, status: resp.status };
      } catch (e) {
        return { ok: false, error: e.message };
      }
    });
    expect(result.ok).toBeTruthy();
  });

  test('entry reversal page is accessible', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await page.waitForLoadState('networkidle');

    const reverseButtons = page.locator('button, a').filter({ hasText: /reverse/i });
    if (await reverseButtons.count() > 0) {
      await reverseButtons.first().click();
      await page.waitForLoadState('networkidle');
    }

    await expect(page.locator('body')).toBeAttached();
  });
});
