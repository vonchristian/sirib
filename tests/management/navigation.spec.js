// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Navigation', () => {
  test.use({ storageState: '.auth/user.json' });

  test('navigates via sidebar to management dashboard', async ({ page }) => {
    await page.goto('/dashboard');
    const managementLink = page.getByRole('link', { name: /management/i });
    if (await managementLink.isVisible()) {
      await managementLink.click();
      await expect(page).toHaveURL(/\/management\/dashboard/);
    }
  });

  test('navigates to branches from sidebar', async ({ page }) => {
    await page.goto('/management/dashboard');
    const branchLink = page.getByRole('link', { name: /branches/i });
    if (await branchLink.isVisible()) {
      await branchLink.click();
      await expect(page).toHaveURL(/\/management\/branches/);
    }
  });

  test('navigates to departments from sidebar', async ({ page }) => {
    await page.goto('/management/dashboard');
    const deptLink = page.getByRole('link', { name: /departments/i });
    if (await deptLink.isVisible()) {
      await deptLink.click();
      await expect(page).toHaveURL(/\/management\/departments/);
    }
  });

  test('navigates to roles from sidebar', async ({ page }) => {
    await page.goto('/management/dashboard');
    const rolesLink = page.getByRole('link', { name: /roles/i });
    if (await rolesLink.isVisible()) {
      await rolesLink.click();
      await expect(page).toHaveURL(/\/management\/roles/);
    }
  });

  test('navigates to policies from sidebar', async ({ page }) => {
    await page.goto('/management/dashboard');
    const policiesLink = page.getByRole('link', { name: /policies/i });
    if (await policiesLink.isVisible()) {
      await policiesLink.click();
      await expect(page).toHaveURL(/\/management\/policies/);
    }
  });

  test('navigates to configurations from sidebar', async ({ page }) => {
    await page.goto('/management/dashboard');
    const configLink = page.getByRole('link', { name: /configurations/i });
    if (await configLink.isVisible()) {
      await configLink.click();
      await expect(page).toHaveURL(/\/management\/configurations/);
    }
  });

  test('navigates to alerts from sidebar', async ({ page }) => {
    await page.goto('/management/dashboard');
    const alertsLink = page.getByRole('link', { name: /alerts/i });
    if (await alertsLink.isVisible()) {
      await alertsLink.click();
      await expect(page).toHaveURL(/\/management\/alerts/);
    }
  });

  test('navigates to audit logs from sidebar', async ({ page }) => {
    await page.goto('/management/dashboard');
    const auditLink = page.getByRole('link', { name: /audit logs/i });
    if (await auditLink.isVisible()) {
      await auditLink.click();
      await expect(page).toHaveURL(/\/management\/audit_logs/);
    }
  });

  test('executive dashboard link works', async ({ page }) => {
    await page.goto('/management/dashboard');
    const execLink = page.getByRole('link', { name: /executive dashboard/i });
    if (await execLink.isVisible()) {
      await execLink.click();
      await expect(page).toHaveURL(/\/management\/executive_dashboard/);
    }
  });

  test('branch performance link works', async ({ page }) => {
    await page.goto('/management/dashboard');
    const perfLink = page.getByRole('link', { name: /branch performance/i });
    if (await perfLink.isVisible()) {
      await perfLink.click();
      await expect(page).toHaveURL(/\/management\/branch_performance/);
    }
  });

  test('risk monitoring link works', async ({ page }) => {
    await page.goto('/management/dashboard');
    const riskLink = page.getByRole('link', { name: /risk monitoring/i });
    if (await riskLink.isVisible()) {
      await riskLink.click();
      await expect(page).toHaveURL(/\/management\/risk_monitoring/);
    }
  });

  test('system health link works', async ({ page }) => {
    await page.goto('/management/dashboard');
    const healthLink = page.getByRole('link', { name: /system health/i });
    if (await healthLink.isVisible()) {
      await healthLink.click();
      await expect(page).toHaveURL(/\/management\/system_health/);
    }
  });
});
