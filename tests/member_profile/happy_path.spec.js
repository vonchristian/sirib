// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Member Profile - Happy Path', () => {
  test.use({ storageState: '.auth/user.json' });

  test('opens member profile from list and displays header', async ({ page }) => {
    await page.goto('/members');
    await expect(page.getByRole('heading', { name: /members/i })).toBeVisible();

    const firstMemberLink = page.locator('#members-tbody tr a').first();
    await firstMemberLink.click();

    await page.waitForURL(/\/members\/\d+$/);
    await expect(page.getByText(/active member/i)).toBeVisible();
    await expect(page.getByText(/no\./i)).toBeVisible();
  });

  test('overview tab is selected by default with summary cards', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await expect(page.getByRole('link', { name: /overview/i })).toHaveClass(/border-primary/);
    await expect(page.getByText(/savings/i)).toBeVisible();
    await expect(page.getByText(/time deposits/i)).toBeVisible();
    await expect(page.getByText(/loans/i)).toBeVisible();
    await expect(page.getByText(/share capital/i)).toBeVisible();
  });

  test('displays member information and financial snapshot', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await expect(page.getByText(/member number/i)).toBeVisible();
    await expect(page.getByText(/full name/i)).toBeVisible();
    await expect(page.getByText(/financial snapshot/i)).toBeVisible();
    await expect(page.getByText(/savings balance/i)).toBeVisible();
  });

  test('shows recent activity section', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    await expect(page.getByText(/recent activity/i)).toBeVisible();
  });

  test('navigates between tabs without full page reload', async ({ page }) => {
    await page.goto('/members');
    await page.locator('#members-tbody tr a').first().click();
    await page.waitForURL(/\/members\/\d+$/);

    const savingsLink = page.getByRole('link', { name: /^savings$/i });
    await savingsLink.click();
    await expect(page.getByRole('link', { name: /^savings$/i })).toHaveClass(/border-primary/);

    const loansLink = page.getByRole('link', { name: /^loans$/i });
    await loansLink.click();
    await expect(page.getByRole('link', { name: /^loans$/i })).toHaveClass(/border-primary/);
  });
});
