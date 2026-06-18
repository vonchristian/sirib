// @ts-check
import { test, expect } from '@playwright/test';

test.describe('Management Approval Workflows', () => {
  test.use({ storageState: '.auth/user.json' });

  test.describe('Happy Paths', () => {
    test('displays workflow list', async ({ page }) => {
      await page.goto('/management/approval_workflows');
      await expect(page.getByRole('heading', { name: /approval workflows/i })).toBeVisible();
      await expect(page.getByText(/loan_approval/i)).toBeVisible();
      await expect(page.getByText(/config_change/i)).toBeVisible();
      await expect(page.getByText(/policy_approval/i)).toBeVisible();
    });

    test('creates a new approval workflow', async ({ page }) => {
      await page.goto('/management/approval_workflows/new');
      await page.getByLabel(/name/i).fill('E2E Test Workflow');
      await page.getByLabel(/code/i).fill('e2e_test_workflow');
      await page.getByLabel(/category/i).fill('test');
      await page.getByRole('button', { name: /create approval workflow/i }).click();
      await expect(page.getByText(/approval workflow was successfully created/i)).toBeVisible();
    });

    test('views workflow details with steps', async ({ page }) => {
      await page.goto('/management/approval_workflows');
      await page.getByText(/loan_approval/i).first().click();
      await expect(page.getByText(/loan_approval/i)).toBeVisible();
      await expect(page.getByText(/steps/i).first()).toBeVisible();
    });

    test('edits a workflow', async ({ page }) => {
      await page.goto('/management/approval_workflows');
      await page.getByRole('link', { name: /edit/i }).first().click();
      await page.getByLabel(/name/i).clear();
      await page.getByLabel(/name/i).fill('E2E Updated Workflow');
      await page.getByRole('button', { name: /update approval workflow/i }).click();
      await expect(page.getByText(/approval workflow was successfully updated/i)).toBeVisible();
    });
  });

  test.describe('Approval Requests', () => {
    test('displays approval requests for a workflow', async ({ page }) => {
      await page.goto('/management/approval_workflows');
      await page.getByText(/loan_approval/i).first().click();
      await page.getByRole('link', { name: /view all/i }).click();
      await expect(page.getByText(/approval requests/i)).toBeVisible();
    });
  });

  test.describe('Validation', () => {
    test('requires name', async ({ page }) => {
      await page.goto('/management/approval_workflows/new');
      await page.getByLabel(/code/i).fill('val_test');
      await page.getByLabel(/category/i).fill('test');
      await page.getByRole('button', { name: /create approval workflow/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('requires code', async ({ page }) => {
      await page.goto('/management/approval_workflows/new');
      await page.getByLabel(/name/i).fill('Validation Test');
      await page.getByLabel(/category/i).fill('test');
      await page.getByRole('button', { name: /create approval workflow/i }).click();
      await expect(page.getByText(/can't be blank/i)).toBeVisible();
    });

    test('validates duplicate code', async ({ page }) => {
      await page.goto('/management/approval_workflows/new');
      await page.getByLabel(/name/i).fill('Dup Workflow');
      await page.getByLabel(/code/i).fill('loan_approval');
      await page.getByLabel(/category/i).fill('test');
      await page.getByRole('button', { name: /create approval workflow/i }).click();
      await expect(page.getByText(/already been taken/i)).toBeVisible();
    });
  });
});
