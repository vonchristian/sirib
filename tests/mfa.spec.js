// @ts-check
import { test, expect } from '@playwright/test';
import { authenticator } from '@otplib/preset-default';

test.describe('Multi-Factor Authentication', () => {
  async function enableMfa(page) {
    await page.goto('/mfa/setup');
    await expect(page.getByText(/scan the qr code/i)).toBeVisible();

    const secretText = await page.locator('.select-all').textContent();
    const secret = secretText.replace(/\s/g, '');
    const code = authenticator.generate(secret);
    await page.locator('#code').fill(code);
    await page.getByRole('button', { name: /enable two-factor/i }).click();
    await expect(page.getByText(/backup recovery codes/i)).toBeVisible();
    return secret;
  }

  async function disableMfa(page) {
    await page.request.post('/mfa/disable');
  }

  test('enables MFA and shows backup codes', async ({ page }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);

    await enableMfa(page);

    const codes = await page.locator('.font-mono.tracking-wider').allTextContents();
    expect(codes.length).toBe(10);

    await disableMfa(page);
    await page.goto('/dashboard');
  });

  test('requires MFA challenge on login when enabled', async ({ page, context }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);

    const secret = await enableMfa(page);
    await page.getByRole('link', { name: /done/i }).click();

    await context.clearCookies();

    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page.getByText(/two-factor authentication/i)).toBeVisible();

    // Auto-submit fires when 6 digits are entered (otp-input Stimulus controller)
    const code = authenticator.generate(secret);
    await page.locator('#code').fill(code);
    // Wait for the auto-submit to process and redirect to dashboard
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });

    await disableMfa(page);
  });

  test('rejects invalid code during MFA challenge', async ({ page, context }) => {
    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);

    const secret = await enableMfa(page);
    await page.getByRole('link', { name: /done/i }).click();

    await context.clearCookies();

    await page.goto('/session/new');
    await page.getByLabel(/email address/i).fill('admin@example.com');
    await page.getByLabel(/password/i).fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page.getByText(/two-factor authentication/i)).toBeVisible();

    // Enter invalid code — auto-submit fires, server returns invalid
    await page.locator('#code').fill('000000');
    await expect(page.getByText(/invalid verification code/i)).toBeVisible();

    // Now enter valid code — auto-submit fires again
    const code = authenticator.generate(secret);
    await page.locator('#code').fill(code);
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });

    await disableMfa(page);
  });
});
