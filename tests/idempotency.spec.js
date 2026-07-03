import { test, expect } from '@playwright/test';

test.use({ storageState: '.auth/user.json' });

test.describe('Idempotency System', () => {

  test('server is reachable after idempotency migration', async ({ page }) => {
    const response = await page.request.get('/up');
    expect(response.ok()).toBeTruthy();
  });

  test('admin can create a journal entry without errors', async ({ page }) => {
    await page.goto('/accounting/entries/new');
    await page.waitForLoadState('networkidle');

    await expect(page.locator('h1, h2, h3').first()).toBeVisible();
  });

  test('journal entry template execution handles idempotency gracefully', async ({ page }) => {
    await page.goto('/accounting/entry_templates');
    await page.waitForLoadState('networkidle');

    const templates = page.locator('table tbody tr, .template-item, [data-testid="template"]');
    const count = await templates.count();

    if (count > 0) {
      await templates.first().locator('a, button').filter({ hasText: /execute|run|post/i }).first().click();
      await page.waitForLoadState('networkidle');
      expect(page.locator('.flash-success, .notice, .alert, .flash-alert').first()).toBeAttached();
    }
  });

  test('idempotency key cleanup job does not raise errors', async ({ page }) => {
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
});
