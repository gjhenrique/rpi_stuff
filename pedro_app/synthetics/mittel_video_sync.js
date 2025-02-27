import { browser } from 'k6/browser';
import { check } from 'https://jslib.k6.io/k6-utils/1.5.0/index.js';

export const options = {
  scenarios: {
    ui: {
      executor: 'shared-iterations',
      options: {
        browser: {
          type: 'chromium',
        },
      },
    },
  },
  thresholds: {
    checks: ['rate==1.0'],
  },
};

export default async function () {
  const context = await browser.newContext();
  const page = await context.newPage();

  // Set up the dialog handler before navigating to the page
  page.on('dialog', async (dialog) => {
    console.log(`Dialog message: ${dialog.message()}`);
    await dialog.accept();
  });

  try {
    await page.goto("https://mittel.site/login");

    await page.locator('#username').type("pedro");
    await page.locator('#password').type("ENV_PEDRO_PASSWORD");

    await Promise.all([
      page.waitForNavigation(),
      page.locator('button[type="submit"]').click(),
    ]);

    await check(page.locator("section.home h2:first-child"), {
      "header": async (locator) => {
        const text = await locator.textContent();
        return text.includes("Pedro");
      },
    });

    // Check if the sync button is present
    await check(page.locator(".bx.bx-sync.video-sync-submit"), {
	"present": async (locator) => {
	  const isVisible = await locator.isVisible();
	  return isVisible;
	}
    })

    await page.locator(".bx.bx-sync.video-sync-submit").click();

    // wait 5 seconds
    await page.waitForTimeout(5000);


    await page.waitForSelector(".badge.badge-success", { timeout: 5000 });
  } finally {
    await page.close();
  }
}
