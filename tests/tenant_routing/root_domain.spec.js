import { test, expect } from '@playwright/test';

const ROOT = 'http://lvh.me:3000';
const MAIN = 'http://main.lvh.me:3000';
const BASE = 'http://main.lvh.me:3000';
const OTHER = 'http://asenso.lvh.me:3000';
const MISSING = 'http://unknown.lvh.me:3000';

test('root domain redirects to main subdomain', async ({ page }) => {
  await page.goto(ROOT);
  expect(page.url()).toMatch(/main\.lvh\.me/);
});

test('root domain redirects to main subdomain login', async ({ page }) => {
  await page.goto(ROOT);
  expect(page.url()).toMatch(/main\.lvh\.me/);
  expect(page.url()).toMatch(/\/session\/new/);
});

test('subdomain shows login page for unauthenticated user', async ({ page }) => {
  await page.goto(`${BASE}/session/new`);
  await expect(page.getByRole('heading', { name: /sign in/i })).toBeVisible();
});

test('dashboard on subdomain redirects unauthenticated to login', async ({ page }) => {
  await page.goto(`${BASE}/dashboard`);
  await expect(page).toHaveURL(/\/session\/new/);
});

test('unknown subdomain returns 404', async ({ page }) => {
  const response = await page.request.get(MISSING);
  expect(response.status()).toBe(404);
});

test('session routes on root domain return 404', async ({ page }) => {
  const response1 = await page.request.get(`${ROOT}/session/new`);
  expect(response1.status()).toBe(404);
  const response2 = await page.request.get(`${ROOT}/session`);
  expect(response2.status()).toBe(404);
});

test('health check works on both root and subdomain', async ({ page }) => {
  const r1 = await page.request.get(`${ROOT}/up`);
  expect(r1.status()).toBe(200);
  const r2 = await page.request.get(`${MAIN}/up`);
  expect(r2.status()).toBe(200);
});

