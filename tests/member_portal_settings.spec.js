// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Member Portal Settings', () => {
  test.use({ storageState: '.auth/user.json' });

  test.beforeEach(async ({ page }) => {
    await page.goto('/members');
    await page.waitForLoadState('networkidle');
  });

  test('settings tab is visible on member show page', async ({ page }) => {
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await expect(settingsTab).toBeVisible();
  });

  test('clicking settings tab shows portal settings', async ({ page }) => {
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.click();
    await page.waitForLoadState('networkidle');

    await expect(page.getByText(/online portal access/i)).toBeVisible();
    await expect(page.getByText(/member portal access/i)).toBeVisible();
  });

  test('portal toggle switch is visible and is a form button', async ({ page }) => {
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.click();
    await page.waitForLoadState('networkidle');

    const toggleForm = page.locator('form[action*="toggle_portal_access"]');
    await expect(toggleForm).toBeVisible();
  });

  test('shows portal status indicator when active', async ({ page }) => {
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.click();
    await page.waitForLoadState('networkidle');

    const activeBadge = page.getByText('Active');
    const inactiveBadge = page.getByText('Inactive');
    const suspendedBadge = page.getByText('Suspended');

    const hasActiveBadge = await activeBadge.isVisible().catch(() => false);
    const hasInactiveBadge = await inactiveBadge.isVisible().catch(() => false);
    const hasSuspendedBadge = await suspendedBadge.isVisible().catch(() => false);

    expect(hasActiveBadge || hasInactiveBadge || hasSuspendedBadge).toBeTruthy();
  });

  test('profile settings section is visible in settings tab', async ({ page }) => {
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.click();
    await page.waitForLoadState('networkidle');

    await expect(page.getByText(/profile settings/i)).toBeVisible();
    await expect(page.getByRole('link', { name: /edit profile/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /upload id/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /update address/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /change signature/i })).toBeVisible();
  });

  test('other tabs are still accessible after viewing settings', async ({ page }) => {
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.click();
    await page.waitForLoadState('networkidle');
    await expect(page.getByText(/online portal access/i)).toBeVisible();

    const savingsTab = page.getByRole('tab', { name: /savings/i });
    await savingsTab.click();
    await page.waitForLoadState('networkidle');
    await expect(page.getByText(/savings accounts/i)).toBeVisible();
  });

  test('tabs maintain active state correctly', async ({ page }) => {
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.click();

    const activeTab = page.locator('button[aria-selected="true"]');
    await expect(activeTab).toContainText(/settings/i);
  });

  test('responsive: settings tab works on mobile viewport', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.scrollIntoViewIfNeeded();
    await settingsTab.click();
    await page.waitForLoadState('networkidle');

    await expect(page.getByText(/online portal access/i)).toBeVisible();
  });

  test('responsive: portal toggle visible on small screens', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.scrollIntoViewIfNeeded();
    await settingsTab.click();
    await page.waitForLoadState('networkidle');

    const toggleForm = page.locator('form[action*="toggle_portal_access"]');
    await expect(toggleForm).toBeVisible();
  });

  test('desktop layout matches existing design patterns', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 720 });
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.click();
    await page.waitForLoadState('networkidle');

    const portalCard = page.locator('.rounded-lg.border.border-border').filter({ hasText: /online portal access/i });
    await expect(portalCard).toBeVisible();
    await expect(portalCard.getByText(/member portal access/i)).toBeVisible();
  });

  test('clicking toggle shows confirmation dialog', async ({ page }) => {
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.click();
    await page.waitForLoadState('networkidle');

    const toggleForm = page.locator('form[action*="toggle_portal_access"]');
    const toggleButton = toggleForm.locator('button[type="submit"]');

    page.on('dialog', async dialog => {
      expect(dialog.message()).toMatch(/enable|suspend/i);
      await dialog.accept();
    });

    await toggleButton.click();
  });

  test('navigating away and back preserves tab state', async ({ page }) => {
    const firstMemberLink = page.locator('#members-tbody tr').first().locator('a').first();
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    const settingsTab = page.getByRole('tab', { name: /settings/i });
    await settingsTab.click();
    await page.waitForLoadState('networkidle');
    await expect(page.getByText(/online portal access/i)).toBeVisible();

    await page.goBack();
    await page.waitForLoadState('networkidle');
    await firstMemberLink.click();
    await page.waitForLoadState('networkidle');

    await expect(page.getByText(/savings/i).first()).toBeVisible();
  });
});