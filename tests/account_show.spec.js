import { test, expect } from '@playwright/test';

test.describe('Account Show Page', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/accounting/accounts/1');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    async function findAccountId(page) {
      const response = await page.request.get('/accounting/accounts/search?q=11110');
      const html = await response.text();
      const match = html.match(/data-account-id="(\d+)"/);
      return match ? match[1] : null;
    }

    test('displays account header with metadata', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await expect(page.locator('[data-testid="account-header"]')).toBeVisible();
      await expect(page.getByText('11110')).toBeVisible();
      await expect(page.getByText('asset')).toBeVisible();
    });

    test('displays tab navigation', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await expect(page.getByText('Overview')).toBeVisible();
      await expect(page.getByText('Transactions')).toBeVisible();
      await expect(page.getByText('Audit Trail')).toBeVisible();
    });

    test('displays balance snapshot on overview tab', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await expect(page.locator('[data-testid="balance-snapshot"]')).toBeVisible();
      await expect(page.getByText('Opening Balance')).toBeVisible();
      await expect(page.getByText('Current Balance')).toBeVisible();
    });

    test('shows account details on overview tab', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await expect(page.getByText('Account Details')).toBeVisible();
      await expect(page.getByText('Normal Balance')).toBeVisible();
    });

    test('displays filter panel', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await expect(page.locator('[data-testid="filter-panel"]')).toBeVisible();
      await expect(page.getByText('Quick Date')).toBeVisible();
      await expect(page.getByText('From Date')).toBeVisible();
      await expect(page.getByText('Entry Type')).toBeVisible();
    });

    test('displays empty state when account has no transactions', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await expect(page.getByText('No ledger activity')).toBeVisible();
    });

    test('displays audit trail section', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await expect(page.locator('[data-testid="audit-trail"]')).toBeVisible();
      await expect(page.getByText('Account ID')).toBeVisible();
      await expect(page.getByText('Ledger')).toBeVisible();
    });

    test('filtering by date range still shows empty state', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await page.fill('input[name="from_date"]', '2026-01-01');
      await page.fill('input[name="to_date"]', '2026-12-31');
      await page.click('input[type="submit"][value="Apply Filters"]');

      await page.waitForLoadState('networkidle');
      await expect(page.getByText('No ledger activity')).toBeVisible();
    });

    test('can switch sort order', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}?sort=asc`);
      await page.waitForLoadState('networkidle');

      await expect(page.locator('[data-testid="account-header"]')).toBeVisible();
    });

    test('filter by source module works', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await page.selectOption('select[name="source_module"]', 'source_manual');
      await page.click('input[type="submit"][value="Apply Filters"]');
      await page.waitForLoadState('networkidle');

      await expect(page.getByText('No ledger activity')).toBeVisible();
    });

    test('shows current balance in header', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await expect(page.getByText('Current Balance')).toBeVisible();
    });

    test('shows status and postable in account details', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      await expect(page.locator('[data-testid="account-status"]')).toBeVisible();
      await expect(page.locator('[data-testid="account-postable"]')).toBeVisible();
    });

    test('displays posting restriction alert when account is inactive', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      const statusEl = page.locator('[data-testid="account-status"]');
      const status = await statusEl.textContent();

      if (status && status.trim().toLowerCase() === 'inactive') {
        await expect(page.locator('[data-testid="posting-restriction-alert"]')).toBeVisible();
        await expect(page.getByText(/inactive/i)).toBeVisible();
      }
    });

    test('displays posting restriction alert when account is non-postable', async ({ page }) => {
      const accountId = await findAccountId(page);
      test.skip(!accountId, 'Cash account not seeded');

      await page.goto(`/accounting/accounts/${accountId}`);
      await page.waitForLoadState('networkidle');

      const postableEl = page.locator('[data-testid="account-postable"]');
      const postable = await postableEl.textContent();

      if (postable && postable.trim().toLowerCase() === 'no') {
        await expect(page.locator('[data-testid="posting-restriction-alert"]')).toBeVisible();
        await expect(page.getByText(/non-postable/i)).toBeVisible();
      }
    });

    test('returns 404 for non-existent account', async ({ page }) => {
      const response = await page.request.get('/accounting/accounts/999999');
      expect(response.status()).toBe(404);
    });
  });
});
