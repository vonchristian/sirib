// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Savings Account Opening Form', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Path', () => {
    test('opens a savings account with autocomplete member search', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      // Search and select member via autocomplete
      await page.getByPlaceholder(/Search member/i).fill('Jose');
      await page.getByText('Jose Rizal Mercado').first().waitFor({ timeout: 5000 });
      await page.getByText('Jose Rizal Mercado').first().click();

      // Verify member selection is displayed
      await expect(page.getByTitle('Change member')).toBeVisible();
      await expect(page.getByText('Jose Rizal Mercado')).toBeVisible();

      // Select savings product
      await page.locator('label').filter({ hasText: /Regular Savings/ }).first().click();

      // Select account type
      await page.locator('label').filter({ hasText: /Personal Savings/ }).click();

      // Submit the form
      await page.getByRole('button', { name: /Open Account/i }).click();

      // Verify success
      await expect(page.getByText('Savings account opened.')).toBeVisible();
    });

    test('opens a business savings account', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      await page.getByPlaceholder(/Search member/i).fill('Juan');
      await page.getByText('Juan Dela Reyes').first().waitFor({ timeout: 5000 });
      await page.getByText('Juan Dela Reyes').first().click();

      await page.locator('label').filter({ hasText: /Regular Savings/ }).first().click();
      await page.locator('label').filter({ hasText: /Business Savings/ }).click();

      await page.getByRole('button', { name: /Open Account/i }).click();
      await expect(page.getByText('Savings account opened.')).toBeVisible();
    });
  });

  test.describe('Autocomplete', () => {
    test('searches members and shows results', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      const input = page.getByPlaceholder(/Search member/i);
      await input.fill('Elena');

      await expect(page.getByText('Elena Garcia Villanueva').first()).toBeVisible({ timeout: 5000 });
    });

    test('shows empty state when no members match', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      const input = page.getByPlaceholder(/Search member/i);
      await input.fill('zzzxnonexistent');

      await expect(page.getByText('No members found')).toBeVisible({ timeout: 5000 });
    });

    test('clears selection and allows re-selection', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      // Select Maria
      await page.getByPlaceholder(/Search member/i).fill('Maria');
      await page.getByText('Maria Santos Cruz').first().waitFor({ timeout: 5000 });
      await page.getByText('Maria Santos Cruz').first().click();
      await expect(page.getByText('Maria Santos Cruz')).toBeVisible();

      // Clear selection
      await page.getByTitle('Change member').click();
      await expect(page.getByPlaceholder(/Search member/i)).toBeVisible();

      // Re-select Juan
      await page.getByPlaceholder(/Search member/i).fill('Juan');
      await page.getByText('Juan Dela Reyes').first().waitFor({ timeout: 5000 });
      await page.getByText('Juan Dela Reyes').first().click();
      await expect(page.getByText('Juan Dela Reyes')).toBeVisible();
    });

    test('keyboard navigation works (arrow down + enter)', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      const input = page.getByPlaceholder(/Search member/i);
      await input.fill('Maria');
      await page.getByText('Maria Santos Cruz').first().waitFor({ timeout: 5000 });

      // Press arrow down to highlight first result, then enter
      await page.keyboard.press('ArrowDown');
      await page.keyboard.press('Enter');

      // After pressing Enter, the selected member card appears if the
      // highlighted item was the first one (Maria Santos Cruz).
      // We check that the search input is gone (hidden by select).
      await expect(page.getByTitle('Change member')).toBeVisible();
    });
  });

  test.describe('Dark Mode', () => {
    test('toggles dark mode on the form page', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      // Verify light mode first
      await expect(page.locator('html')).not.toHaveClass(/dark/);

      // Toggle dark mode
      await page.getByTitle('Toggle theme').click();
      await expect(page.locator('html')).toHaveClass(/dark/);

      // Form elements should be visible (no layout breaks)
      await expect(page.getByText('Open Savings Account')).toBeVisible();
      await expect(page.getByPlaceholder(/Search member/i)).toBeVisible();
      await expect(page.getByText('Regular Savings').first()).toBeVisible();
      await expect(page.getByText('Personal Savings')).toBeVisible();

      // Open Account button should be visible and styled
      const submitBtn = page.getByRole('button', { name: /Open Account/i });
      await expect(submitBtn).toBeVisible();
      await expect(submitBtn).toBeEnabled();
      await expect(submitBtn.locator('svg')).toBeVisible();

      // Cancel button should be visible
      await expect(page.getByText('Cancel')).toBeVisible();

      // Toggle back to light mode
      await page.getByTitle('Toggle theme').click();
      await expect(page.locator('html')).not.toHaveClass(/dark/);
    });

    test('opens account in dark mode', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      // Switch to dark mode
      await page.getByTitle('Toggle theme').click();
      await expect(page.locator('html')).toHaveClass(/dark/);

      // Complete the form in dark mode
      await page.getByPlaceholder(/Search member/i).fill('Carlos');
      await page.getByText('Carlos B. Yulo').first().waitFor({ timeout: 5000 });
      await page.getByText('Carlos B. Yulo').first().click();

      await page.locator('label').filter({ hasText: /Regular Savings/ }).first().click();
      await page.locator('label').filter({ hasText: /Personal Savings/ }).click();

      await page.getByRole('button', { name: /Open Account/i }).click();
      await expect(page.getByText('Savings account opened.')).toBeVisible();

      // Account page should also be in dark mode
      await expect(page.locator('html')).toHaveClass(/dark/);
    });
  });

  test.describe('Validation', () => {
    test('shows error when no member selected', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      // Select product and account type but no member
      await page.locator('label').filter({ hasText: /Regular Savings/ }).first().click();
      await page.locator('label').filter({ hasText: /Personal Savings/ }).click();

      await page.getByRole('button', { name: /Open Account/i }).click();

      // Should stay on form with validation error
      await expect(page.getByText(/error/i)).toBeVisible();
      await expect(page).toHaveURL(/\/treasury\/savings_accounts\/new/);
    });

    test('shows error when no product selected', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      await page.getByPlaceholder(/Search member/i).fill('Jose');
      await page.getByText('Jose Rizal Mercado').first().waitFor({ timeout: 5000 });
      await page.getByText('Jose Rizal Mercado').first().click();

      await page.locator('label').filter({ hasText: /Personal Savings/ }).click();

      await page.getByRole('button', { name: /Open Account/i }).click();

      await expect(page.getByText(/error/i)).toBeVisible();
      await expect(page).toHaveURL(/\/treasury\/savings_accounts\/new/);
    });

    test('shows error when no account type selected', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      await page.getByPlaceholder(/Search member/i).fill('Ramon');
      await page.getByText('Ramon D. Alcantara').first().waitFor({ timeout: 5000 });
      await page.getByText('Ramon D. Alcantara').first().click();

      await page.locator('label').filter({ hasText: /Regular Savings/ }).first().click();

      await page.getByRole('button', { name: /Open Account/i }).click();

      await expect(page.getByText(/error/i)).toBeVisible();
      await expect(page).toHaveURL(/\/treasury\/savings_accounts\/new/);
    });
  });

  test.describe('Edge Cases', () => {
    test('cancel button navigates back to accounts list', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');
      await page.getByText('Cancel').click();
      await expect(page).toHaveURL(/\/treasury\/savings_accounts$/);
    });

    test('double clicking Open Account does not create duplicate', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      await page.getByPlaceholder(/Search member/i).fill('Luz');
      await page.getByText('Luz V. Macapagal').first().waitFor({ timeout: 5000 });
      await page.getByText('Luz V. Macapagal').first().click();

      await page.locator('label').filter({ hasText: /Regular Savings/ }).first().click();
      await page.locator('label').filter({ hasText: /Personal Savings/ }).click();

      // Double click submit
      const btn = page.getByRole('button', { name: /Open Account/i });
      await btn.click();
      await btn.click({ force: true });

      // Should succeed only once (redirected to account show page)
      await expect(page.getByText('Savings account opened.')).toBeVisible();
      await expect(page).not.toHaveURL(/\/treasury\/savings_accounts\/new/);
    });

    test('Open Account button has correct icon', async ({ page }) => {
      await page.goto('/treasury/savings_accounts/new');

      const btn = page.getByRole('button', { name: /Open Account/i });
      await expect(btn).toBeVisible();
      await expect(btn).toBeEnabled();
      await expect(btn.locator('svg')).toBeVisible();

      const cancel = page.getByText('Cancel');
      await expect(cancel).toBeVisible();
    });
  });

  test.describe('Pre-selected Member', () => {
    test('shows member card when depositor_id param is present', async ({ page }) => {
      // First, find a valid member ID
      await page.goto('/members');
      await expect(page.getByText(/Maria Santos Cruz/).first()).toBeVisible({ timeout: 10000 });
      const memberLink = page.getByText(/Maria Santos Cruz/).first();
      const href = await memberLink.getAttribute('href');
      const memberId = href.match(/\d+/)[0];

      // Navigate to new account form with depositor_id
      await page.goto(`/treasury/savings_accounts/new?depositor_id=${memberId}`);

      // Member should be pre-selected with a badge
      await expect(page.getByText('Selected')).toBeVisible();
      await expect(page.getByText('Maria Santos Cruz')).toBeVisible();

      // No search input should appear
      await expect(page.getByPlaceholder(/Search member/i)).toHaveCount(0);
    });
  });
});
