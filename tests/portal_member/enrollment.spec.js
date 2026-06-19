import { test, expect } from '@playwright/test';

test.describe('Member Portal Enrollment', () => {
  test('invalid enrollment token redirects to login with error', async ({ page }) => {
    await page.goto('/portal/enrollment/invalid-token-xyz');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/portal\/session\/new/);
  });

  test('already active member redirected from enrollment', async ({ page }) => {
    await page.goto('/portal/enrollment/some-token');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/portal\/session\/new/);
  });
});
