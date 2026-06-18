// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Cash Count', () => {
  test.use({ storageState: '.auth/user.json' });

  const SESSION_ID = 1;
  const SHOW_URL = `/treasury/cash_sessions/${SESSION_ID}`;
  const CLOSING_URL = `/treasury/cash_sessions/${SESSION_ID}/closings/new`;

  test.describe('Form loads and displays correctly', () => {
    test('navigates from show page to cash count form', async ({ page }) => {
      await page.goto(SHOW_URL);
      await page.getByRole('link', { name: /Close Session/i }).click();
      await expect(page).toHaveURL(/\/closings\/new/);
    });

    test('renders all 12 PHP denominations with count inputs', async ({ page }) => {
      await page.goto(CLOSING_URL);

      const controller = page.locator('[data-controller="cash-count"]');
      await expect(controller).toBeVisible();

      const countInputs = page.locator('[data-cash-count-target="count"]');
      await expect(countInputs).toHaveCount(12);

      const subtotalTargets = page.locator('[data-cash-count-target="subtotal"]');
      await expect(subtotalTargets).toHaveCount(12);

      await expect(page.getByText(/₱10,350\.00/)).toBeVisible();
    });

    test('expected total value matches seeded balance', async ({ page }) => {
      await page.goto(CLOSING_URL);

      const value = await page
        .locator('[data-cash-count-expected-total-value]')
        .getAttribute('data-cash-count-expected-total-value');
      expect(value).toBe('1035000');
    });
  });

  test.describe('Auto-calculation', () => {
    test('updates subtotal per row on input', async ({ page }) => {
      await page.goto(CLOSING_URL);

      const countInputs = page.locator('[data-cash-count-target="count"]');
      const subtotals = page.locator('[data-cash-count-target="subtotal"]');

      await countInputs.nth(0).fill('5');
      await expect(subtotals.nth(0)).toHaveText(/₱5[,.]000\.00/);

      await countInputs.nth(1).fill('3');
      await expect(subtotals.nth(1)).toHaveText(/₱1[,.]500\.00/);
    });

    test('aggregates total and variance across all denominations', async ({ page }) => {
      await page.goto(CLOSING_URL);

      const countInputs = page.locator('[data-cash-count-target="count"]');
      const total = page.locator('[data-cash-count-target="total"]');
      const variance = page.locator('[data-cash-count-target="variance"]');

      // Enter counts worth ₱1,000 — expected is ₱10,350
      await countInputs.nth(0).fill('1');

      await expect(total).toHaveText(/₱1[,.]000\.00/);
      await expect(variance).toHaveText(/-₱9[,.]350\.00/);
    });

    test('reaches expected total with correct denomination mix', async ({ page }) => {
      await page.goto(CLOSING_URL);

      const countInputs = page.locator('[data-cash-count-target="count"]');
      const total = page.locator('[data-cash-count-target="total"]');

      // ₱10,350 = 10×₱1,000 + 3×₱100 + 1×₱50
      await countInputs.nth(0).fill('10');
      await countInputs.nth(4).fill('3');
      await countInputs.nth(5).fill('1');

      await expect(total).toHaveText(/₱10[,.]350\.00/);
    });
  });

  test.describe('UI elements', () => {
    test('Cancel link returns to session show page', async ({ page }) => {
      await page.goto(CLOSING_URL);
      await page.getByRole('link', { name: /Cancel/i }).click();
      await expect(page).toHaveURL(SHOW_URL);
    });

    test('notes textarea is present and accepts input', async ({ page }) => {
      await page.goto(CLOSING_URL);
      const notes = page.getByLabel(/Notes/i);
      await expect(notes).toBeVisible();
      await notes.fill('Test closing notes');
      await expect(notes).toHaveValue('Test closing notes');
    });
  });

  test.describe('Session closing', () => {
    test('blocks submission when variance exceeds ₱1.00', async ({ page }) => {
      await page.goto(CLOSING_URL);

      const countInputs = page.locator('[data-cash-count-target="count"]');
      await countInputs.nth(0).fill('1');

      let dialogHandled = false;
      page.on('dialog', async (dialog) => {
        expect(dialog.message()).toContain('Variance');
        await dialog.accept();
        dialogHandled = true;
      });

      await page.getByRole('button', { name: /Close Session/i }).click();
      await expect(page).toHaveURL(/\/closings\/new/);
      expect(dialogHandled).toBe(true);
    });

    test('closes session successfully with matching counts', async ({ page }) => {
      await page.goto(CLOSING_URL);

      const countInputs = page.locator('[data-cash-count-target="count"]');

      // Enter ₱10,350 to match expected total:
      // 10 × ₱1,000 + 3 × ₱100 + 1 × ₱50
      await countInputs.nth(0).fill('10');
      await countInputs.nth(4).fill('3');
      await countInputs.nth(5).fill('1');

      await page.getByLabel(/Notes/i).fill('E2E test closing');

      await page.getByRole('button', { name: /Close Session/i }).click();

      await expect(page).toHaveURL(SHOW_URL);
      await expect(page.getByText(/closed successfully/i)).toBeVisible();
    });

    test('already-closed session redirects to show page with alert', async ({ page }) => {
      await page.goto(CLOSING_URL);
      await expect(page).toHaveURL(SHOW_URL);
      await expect(page.getByText(/already closed/i)).toBeVisible();
    });
  });
});
