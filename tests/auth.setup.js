import { test as setup, expect } from '@playwright/test';

const authFile = '.auth/user.json';

setup('authenticate', async ({ page }) => {
  await page.goto('/session/new');
  await page.getByLabel(/email address/i).fill('test@example.com');
  await page.getByLabel(/password/i).fill('password123');
  await page.getByRole('button', { name: /sign in/i }).click();
  await expect(page).toHaveURL(/\/dashboard/);

  await page.context().storageState({ path: authFile });
});
