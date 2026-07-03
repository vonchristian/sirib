// @ts-check
import { test, expect } from '@playwright/test';

test.describe('AI Branch Manager — Happy Path', () => {
  test.use({ storageState: '.auth/user.json' });

  test('loads AI dashboard with digest and sections', async ({ page }) => {
    await page.goto('/management/ai/dashboard');
    await expect(page.getByText(/today'?s summary/i)).toBeVisible();
    await expect(page.getByText(/risk summary/i)).toBeVisible();
    await expect(page.getByText(/critical alerts/i)).toBeVisible();
    await expect(page.getByText(/recommendations/i).first()).toBeVisible();
    await expect(page.getByText(/observations/i).first()).toBeVisible();
  });

  test('displays digest content on dashboard', async ({ page }) => {
    await page.goto('/management/ai/dashboard');
    const digestSummary = page.locator('pre').first();
    await expect(digestSummary).toBeVisible();
    expect(await digestSummary.textContent()).not.toBe('');
  });

  test('displays observations list with filters', async ({ page }) => {
    await page.goto('/management/ai/observations');
    await expect(page.getByLabel(/category/i)).toBeVisible();
    await expect(page.getByLabel(/severity/i)).toBeVisible();
    await expect(page.getByLabel(/status/i)).toBeVisible();
    await expect(page.getByText(/delinquency/i).first()).toBeVisible();
  });

  test('displays recommendations list with filters and actions', async ({ page }) => {
    await page.goto('/management/ai/recommendations');
    await expect(page.getByLabel(/priority/i)).toBeVisible();
    await expect(page.getByLabel(/status/i)).toBeVisible();
    await expect(page.getByText(/collection drive/i).first()).toBeVisible();
    await expect(page.getByText(/cash reserve/i).first()).toBeVisible();
    await expect(page.getByRole('button', { name: /acknowledge/i }).first()).toBeVisible();
    await expect(page.getByRole('button', { name: /dismiss/i }).first()).toBeVisible();
  });

  test('displays digests list', async ({ page }) => {
    await page.goto('/management/ai/digests');
    await expect(page.getByText(/observations/).first()).toBeVisible();
    await expect(page.getByText(/recommendations/).first()).toBeVisible();
    await expect(page.getByText(/digest/i).first()).toBeVisible();
  });

  test('navigates to observation detail page', async ({ page }) => {
    await page.goto('/management/ai/observations');
    const viewLink = page.getByRole('link', { name: /view/i }).first();
    if (await viewLink.isVisible()) {
      await Promise.all([
        page.waitForURL(/\/management\/ai\/observations\/\d+/),
        viewLink.click()
      ]);
    }
  });

  test('navigates to digest detail page', async ({ page }) => {
    await page.goto('/management/ai/digests');
    const viewLink = page.getByRole('link', { name: /view/i }).first();
    if (await viewLink.isVisible()) {
      await Promise.all([
        page.waitForURL(/\/management\/ai\/digests\/\d+/),
        viewLink.click()
      ]);
    }
  });

  test('shows digest detail with risk summary', async ({ page }) => {
    await page.goto('/management/ai/digests');
    const viewLink = page.getByRole('link', { name: /view/i }).first();
    if (await viewLink.isVisible()) {
      await Promise.all([
        page.waitForURL(/\/management\/ai\/digests\/\d+/),
        viewLink.click()
      ]);
      await expect(page.getByText(/risk summary/i).first()).toBeVisible();
    }
  });

  test('navigates to recommendation detail page', async ({ page }) => {
    await page.goto('/management/ai/recommendations');
    const viewLink = page.getByRole('link', { name: /view/i }).first();
    if (await viewLink.isVisible()) {
      await Promise.all([
        page.waitForURL(/\/management\/ai\/recommendations\/\d+/),
        viewLink.click()
      ]);
    }
  });
});
