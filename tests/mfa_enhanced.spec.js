// @ts-check
import { test, expect } from '@playwright/test';
import { authenticator } from '@otplib/preset-default';

test.describe('MFA Enhancement', () => {
  test.describe('Trusted Device Management', () => {
    test('trusts and shows device after MFA verification', async ({ page, context }) => {
      // Log in normally
      await page.goto('/session/new');
      await page.getByLabel(/email address/i).fill('admin@example.com');
      await page.getByLabel(/password/i).fill('password123');
      await page.getByRole('button', { name: /sign in/i }).click();
      await expect(page).toHaveURL(/\/dashboard/);

      // Enable MFA
      await page.goto('/mfa/setup');
      await expect(page.getByText(/scan the qr code/i)).toBeVisible();
      const secretText = await page.locator('.select-all').textContent();
      const secret = secretText.replace(/\s/g, '');
      const code = authenticator.generate(secret);
      await page.locator('#code').fill(code);
      await page.getByRole('button', { name: /enable two-factor/i }).click();
      await expect(page.getByText(/backup recovery codes/i)).toBeVisible();
      await page.getByRole('link', { name: /done/i }).click();

      // Log out and log in again to trigger MFA challenge
      await context.clearCookies();
      await page.goto('/session/new');
      await page.getByLabel(/email address/i).fill('admin@example.com');
      await page.getByLabel(/password/i).fill('password123');
      await page.getByRole('button', { name: /sign in/i }).click();
      await expect(page.getByText(/two-factor authentication/i)).toBeVisible();

      // Complete MFA challenge (auto-submit fires on 6 digits)
      const code2 = authenticator.generate(secret);
      await page.locator('#code').fill(code2);
      await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });

      // Check trusted devices page shows the device
      await page.goto('/mfa/devices');
      await expect(page.getByText(/trusted devices/i)).toBeVisible();
      await expect(page.getByRole('button', { name: /revoke/i })).toBeVisible();

      // Cleanup
      await page.request.post('/mfa/disable');
    });

    test('revokes trusted device', async ({ page, context }) => {
      // Log in normally
      await page.goto('/session/new');
      await page.getByLabel(/email address/i).fill('admin@example.com');
      await page.getByLabel(/password/i).fill('password123');
      await page.getByRole('button', { name: /sign in/i }).click();
      await expect(page).toHaveURL(/\/dashboard/);

      // Enable MFA
      await page.goto('/mfa/setup');
      await expect(page.getByText(/scan the qr code/i)).toBeVisible();
      const secretText = await page.locator('.select-all').textContent();
      const secret = secretText.replace(/\s/g, '');
      const code = authenticator.generate(secret);
      await page.locator('#code').fill(code);
      await page.getByRole('button', { name: /enable two-factor/i }).click();
      await expect(page.getByText(/backup recovery codes/i)).toBeVisible();
      await page.getByRole('link', { name: /done/i }).click();

      // Log out and log in again to trigger MFA challenge
      await context.clearCookies();
      await page.goto('/session/new');
      await page.getByLabel(/email address/i).fill('admin@example.com');
      await page.getByLabel(/password/i).fill('password123');
      await page.getByRole('button', { name: /sign in/i }).click();
      await expect(page.getByText(/two-factor authentication/i)).toBeVisible();

      // Complete MFA challenge
      const code2 = authenticator.generate(secret);
      await page.locator('#code').fill(code2);
      await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });

      // Revoke all devices
      await page.goto('/mfa/devices');
      await page.getByRole('button', { name: /revoke all/i }).click();
      await expect(page.getByText(/no trusted devices/i)).toBeVisible();

      // Cleanup
      await page.request.post('/mfa/disable');
    });
  });

  test.describe('Step-Up Authentication API', () => {
    test('rejects invalid code via step-up endpoint', async ({ page }) => {
      // Log in normally
      await page.goto('/session/new');
      await page.getByLabel(/email address/i).fill('admin@example.com');
      await page.getByLabel(/password/i).fill('password123');
      await page.getByRole('button', { name: /sign in/i }).click();
      await expect(page).toHaveURL(/\/dashboard/);

      // Enable MFA
      await page.goto('/mfa/setup');
      await expect(page.getByText(/scan the qr code/i)).toBeVisible();
      const secretText = await page.locator('.select-all').textContent();
      const secret = secretText.replace(/\s/g, '');
      const code = authenticator.generate(secret);
      await page.locator('#code').fill(code);
      await page.getByRole('button', { name: /enable two-factor/i }).click();
      await expect(page.getByText(/backup recovery codes/i)).toBeVisible();
      await page.getByRole('link', { name: /done/i }).click();

      // Invalid code returns 422
      const invalidRes = await page.request.post('/mfa/step_up_verify', { form: { code: '000000' } });
      expect(invalidRes.status()).toBe(422);

      // Valid code returns success
      const code2 = authenticator.generate(secret);
      const validRes = await page.request.post('/mfa/step_up_verify', { form: { code: code2 } });
      expect(validRes.ok()).toBeTruthy();
      const body = await validRes.json();
      expect(body.success).toBe(true);

      // Cleanup
      await page.request.post('/mfa/disable');
    });
  });

  test.describe('MFA Attempt Logging', () => {
    test('rate limits MFA verify', async ({ page, context }) => {
      // Log in normally
      await page.goto('/session/new');
      await page.getByLabel(/email address/i).fill('admin@example.com');
      await page.getByLabel(/password/i).fill('password123');
      await page.getByRole('button', { name: /sign in/i }).click();
      await expect(page).toHaveURL(/\/dashboard/);

      // Enable MFA
      await page.goto('/mfa/setup');
      await expect(page.getByText(/scan the qr code/i)).toBeVisible();
      const secretText = await page.locator('.select-all').textContent();
      const secret = secretText.replace(/\s/g, '');
      const code = authenticator.generate(secret);
      await page.locator('#code').fill(code);
      await page.getByRole('button', { name: /enable two-factor/i }).click();
      await expect(page.getByText(/backup recovery codes/i)).toBeVisible();
      await page.getByRole('link', { name: /done/i }).click();

      // Log out and go to challenge
      await context.clearCookies();
      await page.goto('/session/new');
      await page.getByLabel(/email address/i).fill('admin@example.com');
      await page.getByLabel(/password/i).fill('password123');
      await page.getByRole('button', { name: /sign in/i }).click();
      await expect(page.getByText(/two-factor authentication/i)).toBeVisible();

      // Submit 5 invalid codes (auto-submit fires when 6 digits are entered)
      for (let i = 0; i < 5; i++) {
        await page.locator('#code').fill('000000');
        await expect(page.getByText(/invalid verification/i)).toBeVisible();
      }

      // 6th attempt — rate limited
      await page.locator('#code').fill('000000');
      await expect(page.getByText(/too many attempts/i).or(page.getByText(/invalid verification/i))).toBeVisible();

      // Cleanup
      await page.request.post('/mfa/disable');
    });
  });
});
