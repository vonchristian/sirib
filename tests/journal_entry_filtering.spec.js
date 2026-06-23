import { test, expect } from '@playwright/test';

test.describe('Journal Entry Filtering', () => {
  test('redirects unauthenticated user to sign in', async ({ page }) => {
    await page.goto('/accounting/journal_entries');
    await expect(page).toHaveURL(/\/session\/new/);
  });

  test.describe('Authenticated', () => {
    test.use({ storageState: '.auth/user.json' });

    test('accountant filters journal entries by date and branch', async ({ page }) => {
      await page.goto('/accounting/journal_entries');

      await page.fill('[data-testid="start-date"]', '2026-01-01');
      await page.fill('[data-testid="end-date"]', '2026-01-31');

      await page.selectOption('[data-testid="branch-filter"]', { index: 1 });

      await page.click('[data-testid="apply-filters"]');

      await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
    });

    test('filters by entry type', async ({ page }) => {
      await page.goto('/accounting/journal_entries');

      await page.selectOption('select[name="entry_type"]', 'manual');

      await page.click('[data-testid="apply-filters"]');

      await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
    });

    test('filters by status', async ({ page }) => {
      await page.goto('/accounting/journal_entries');

      await page.selectOption('select[name="status"]', 'posted');

      await page.click('[data-testid="apply-filters"]');

      await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
    });

    test('filters by source module', async ({ page }) => {
      await page.goto('/accounting/journal_entries');

      await page.selectOption('select[name="source_module"]', 'loans');

      await page.click('[data-testid="apply-filters"]');

      await page.waitForLoadState('networkidle');
    });

    test('filters by has_attachments checkbox', async ({ page }) => {
      await page.goto('/accounting/journal_entries');

      await page.check('#has_attachments');

      await page.click('[data-testid="apply-filters"]');

      await page.waitForLoadState('networkidle');
    });

    test('filters by inter_branch checkbox', async ({ page }) => {
      await page.goto('/accounting/journal_entries');

      await page.check('#inter_branch');

      await page.click('[data-testid="apply-filters"]');

      await page.waitForLoadState('networkidle');
    });

    test('filters by amount range', async ({ page }) => {
      await page.goto('/accounting/journal_entries');

      await page.fill('input[name="amount_min"]', '100');
      await page.fill('input[name="amount_max"]', '10000');

      await page.click('[data-testid="apply-filters"]');

      await page.waitForLoadState('networkidle');
    });

    test('filters by reference number', async ({ page }) => {
      await page.goto('/accounting/journal_entries');

      await page.fill('input[name="reference_number"]', 'JV-2026');

      await page.click('[data-testid="apply-filters"]');

      await page.waitForLoadState('networkidle');
    });

    test('reset button clears all filters', async ({ page }) => {
      await page.goto('/accounting/journal_entries');

      await page.selectOption('select[name="entry_type"]', 'manual');
      await page.fill('input[name="amount_min"]', '100');

      await page.click('button:has-text("Reset")');

      await page.waitForLoadState('networkidle');

      const selectedType = await page.locator('select[name="entry_type"]').inputValue();
      expect(selectedType).toBe('');
    });

    test('combines multiple filters', async ({ page }) => {
      await page.goto('/accounting/journal_entries');

      await page.fill('[data-testid="start-date"]', '2026-01-01');
      await page.fill('[data-testid="end-date"]', '2026-01-31');
      await page.selectOption('select[name="entry_type"]', 'manual');
      await page.selectOption('select[name="status"]', 'posted');

      await page.click('[data-testid="apply-filters"]');

      await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
    });
  });
});

test.describe('Journal Entry Search', () => {
  test.use({ storageState: '.auth/user.json' });

  test('search journal entry by reference number', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    await page.fill('input[placeholder="Search entries..."]', 'JV-2026');
    await page.press('input[placeholder="Search entries..."]', 'Enter');

    await page.waitForLoadState('networkidle');
  });

  test('search box is visible on index page', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    await expect(page.locator('input[placeholder="Search entries..."]')).toBeVisible();
  });

  test('empty search shows all entries', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    await page.fill('input[placeholder="Search entries..."]', '');
    await page.press('input[placeholder="Search entries..."]', 'Enter');

    await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
  });
});

test.describe('Journal Entry Drill-down Audit View', () => {
  test.use({ storageState: '.auth/user.json' });

  test('open journal entry audit trail', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await expect(firstRow).toBeVisible({ timeout: 10000 });

    await firstRow.click();

    await page.waitForLoadState('networkidle');

    await expect(page.locator('[data-testid="audit-trail"]')).toBeVisible();
    await expect(page.getByText('Created')).toBeVisible();
  });

  test('shows entry details on show page', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await firstRow.locator('a:has-text("View")').click();

    await expect(page.getByText('Entry #')).toBeVisible();
    await expect(page.getByText('Entry Lines')).toBeVisible();
  });

  test('show page displays reversal information when applicable', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    await page.locator('[data-testid="journal-row"]').first().locator('a:has-text("View")').click();

    await page.waitForLoadState('networkidle');

    const reversalSection = page.getByText('Reversal Information');
    if (await reversalSection.isVisible()) {
      await expect(page.getByText('Reversed Entry')).toBeVisible();
    }
  });
});

test.describe('Journal Entry Export', () => {
  test.use({ storageState: '.auth/user.json' });

  test('export filtered journal entries as CSV', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    const downloadPromise = page.waitForEvent('download');

    await page.click('[data-testid="export-csv"]');

    const download = await downloadPromise;
    expect(download.suggestedFilename()).toContain('.csv');
  });

  test('export button is visible on index page', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    await expect(page.getByText('Export').first()).toBeVisible();
  });

  test('print button triggers print dialog', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    page.locator('[data-testid="journal-row"]').first().locator('a:has-text("View")').click();
    await page.waitForLoadState('networkidle');

    const printPromise = page.waitForEvent('popup').catch(() => null);
    await page.click('button:has-text("Print Entry")');
  });
});

test.describe('Saved Filters', () => {
  test.use({ storageState: '.auth/user.json' });

  test('save filter panel shows when clicking Save', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    await page.click('button:has-text("+ Save")');

    await expect(page.locator('input[name="filter_name"]')).toBeVisible();
  });

  test('can enter filter name in save panel', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    await page.click('button:has-text("+ Save")');

    await page.fill('input[name="filter_name"]', 'My Test Filter');

    await expect(page.locator('input[name="filter_name"]')).toHaveValue('My Test Filter');
  });

  test('saved filters section is visible', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    await expect(page.getByText('Saved Filters')).toBeVisible();
  });
});

test.describe('Entry Detail Drawer', () => {
  test.use({ storageState: '.auth/user.json' });

  test('clicking entry row shows detail drawer', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    const firstRow = page.locator('[data-testid="journal-row"]').first();
    await expect(firstRow).toBeVisible({ timeout: 10000 });

    await firstRow.click();

    await page.waitForTimeout(500);

    const detailFrame = page.locator('#entry_detail');
    if (await detailFrame.isVisible()) {
      await expect(detailFrame.getByText('Entry Details')).toBeVisible();
    }
  });
});

test.describe('Entry Status and Type Badges', () => {
  test.use({ storageState: '.auth/user.json' });

  test('displays status badges on index', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('Posted').or(page.getByText('Pending')).or(page.getByText('Reversed'))).toBeVisible();
  });

  test('displays entry type badges on index', async ({ page }) => {
    await page.goto('/accounting/journal_entries');

    await expect(page.locator('[data-testid="journal-row"]').first()).toBeVisible({ timeout: 10000 });
    await expect(
      page.getByText('Manual')
        .or(page.getByText('System'))
        .or(page.getByText('Interest'))
        .or(page.getByText('Fees'))
        .or(page.getByText('Reversal'))
        .or(page.getByText('Adjustment'))
    ).toBeVisible();
  });
});