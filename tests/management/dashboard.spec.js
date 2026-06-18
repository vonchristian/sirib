// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Dashboard', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Operations Dashboard', () => {
    test('loads management dashboard with KPIs', async ({ page }) => {
      await page.goto('/management/dashboard');
      const main = page.getByRole('main');
      await expect(page.getByRole('heading', { name: /management dashboard/i })).toBeVisible();
      await expect(main.getByText(/total assets/i)).toBeVisible();
      await expect(main.getByText(/loan portfolio/i)).toBeVisible();
      await expect(main.getByText(/savings deposits/i)).toBeVisible();
      await expect(main.getByText(/share capital/i)).toBeVisible();
      await expect(main.getByText(/net income/i)).toBeVisible();
      await expect(main.getByText(/cash position/i)).toBeVisible();
    });

    test('displays active branches count and member count', async ({ page }) => {
      await page.goto('/management/dashboard');
      const main = page.getByRole('main');
      await expect(main.getByText(/3/i).first()).toBeVisible();
      await expect(main.getByText(/members/i).first()).toBeVisible();
    });

    test('shows recent alerts section', async ({ page }) => {
      await page.goto('/management/dashboard');
      await expect(page.getByText(/recent alerts/i)).toBeVisible();
    });

    test('shows pending approvals section', async ({ page }) => {
      await page.goto('/management/dashboard');
      await expect(page.getByText(/pending approvals/i).first()).toBeVisible();
    });
  });

  test.describe('Executive Dashboard', () => {
    test('loads executive dashboard with KPIs', async ({ page }) => {
      await page.goto('/management/executive_dashboard');
      const main = page.getByRole('main');
      await expect(page.getByRole('heading', { name: /executive dashboard/i })).toBeVisible();
      await expect(main.getByText(/branches/i).first()).toBeVisible();
      await expect(main.getByText(/total members/i)).toBeVisible();
      await expect(main.getByText(/total assets/i).first()).toBeVisible();
    });

    test('shows branch ranking table', async ({ page }) => {
      await page.goto('/management/executive_dashboard');
      await expect(page.getByText(/branch ranking/i)).toBeVisible();
    });

    test('displays risk overview section', async ({ page }) => {
      await page.goto('/management/executive_dashboard');
      await expect(page.getByText(/risk overview/i)).toBeVisible();
    });

    test('shows system health status', async ({ page }) => {
      await page.goto('/management/executive_dashboard');
      await expect(page.getByText(/system health/i)).toBeVisible();
    });
  });

  test.describe('Branch Performance', () => {
    test('loads branch performance page', async ({ page }) => {
      await page.goto('/management/branch_performance');
      await expect(page.getByRole('heading', { name: /branch performance/i })).toBeVisible();
    });

    test('displays branch ranking with metrics', async ({ page }) => {
      await page.goto('/management/branch_performance');
      await expect(page.getByText(/head office/i)).toBeVisible();
      await expect(page.getByText(/makati/i)).toBeVisible();
      await expect(page.getByText(/quezon city/i)).toBeVisible();
    });
  });

  test.describe('Risk Monitoring', () => {
    test('loads risk monitoring page', async ({ page }) => {
      await page.goto('/management/risk_monitoring');
      await expect(page.getByRole('heading', { name: /risk monitoring/i })).toBeVisible();
    });

    test('displays risk summary counts', async ({ page }) => {
      await page.goto('/management/risk_monitoring');
      await expect(page.getByText(/normal/i).first()).toBeVisible();
      await expect(page.getByText(/elevated/i).first()).toBeVisible();
    });

    test('shows risk indicators table', async ({ page }) => {
      await page.goto('/management/risk_monitoring');
      await expect(page.getByText(/Credit risk delinquency/i).first()).toBeVisible();
    });
  });

  test.describe('System Health', () => {
    test('loads system health page', async ({ page }) => {
      await page.goto('/management/system_health');
      await expect(page.getByRole('heading', { name: /system health/i })).toBeVisible();
    });

    test('displays health metrics', async ({ page }) => {
      await page.goto('/management/system_health');
      await expect(page.getByText(/current status/i)).toBeVisible();
      await expect(page.getByText(/recent snapshots/i)).toBeVisible();
    });

    test('shows healthy status indicators', async ({ page }) => {
      await page.goto('/management/system_health');
      await expect(page.getByText(/transaction_throughput/i).first()).toBeVisible();
      await expect(page.getByText(/queue_depth/i).first()).toBeVisible();
    });
  });

  test.describe('Settings', () => {
    test('loads settings page', async ({ page }) => {
      await page.goto('/management/settings');
      await expect(page.getByRole('heading', { name: /management settings/i })).toBeVisible();
    });
  });
});
