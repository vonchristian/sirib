// @ts-check
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: 'html',

  use: {
    baseURL: 'http://main.lvh.me:3000',
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.js/,
    },
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      dependencies: ['setup'],
    },
  ],

  webServer: {
    command: 'RAILS_ENV=test bin/rails db:drop db:create db:migrate db:seed 2>&1 && bin/e2e-setup && bin/rails server -e test -p 3000',
    url: 'http://localhost:3000/up',
    reuseExistingServer: !process.env.CI,
    timeout: 30000,
  },
});
