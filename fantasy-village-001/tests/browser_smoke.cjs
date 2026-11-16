// Optional delivery check: NODE_PATH=<Playwright install> node tests/browser_smoke.cjs
// Uses an already running tools/serve_web.py server. No npm package is needed to play.
const { chromium } = require('playwright');
const fs = require('node:fs/promises');
const path = require('node:path');
const { createHash } = require('node:crypto');

(async () => {
  const output = path.resolve(__dirname, '../test-results');
  await fs.mkdir(output, { recursive: true });
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_BIN || '/usr/bin/chromium',
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--use-gl=angle',
      '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
  });
  const results = [];
  try {
    for (const device of [
      { name: 'desktop', viewport: { width: 1280, height: 900 }, isMobile: false, hasTouch: false },
      { name: 'android-portrait', viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true },
      { name: 'android-landscape', viewport: { width: 844, height: 390 }, isMobile: true, hasTouch: true },
    ]) {
      const context = await browser.newContext({ ...device, deviceScaleFactor: 1 });
      const page = await context.newPage();
      console.log('Starting ' + device.name);
      const errors = [];
      const consoleLines = [];
      page.on('pageerror', error => errors.push(error.message));
      page.on('console', message => {
        consoleLines.push(message.type() + ': ' + message.text());
        if (message.type() === 'error' || /SCRIPT ERROR:|^ERROR:/.test(message.text())) errors.push(message.text());
      });
      page.on('response', response => {
        if (response.status() >= 400 && !response.url().endsWith('favicon.ico'))
          errors.push('HTTP ' + response.status() + ': ' + response.url());
      });
      await page.goto(process.env.PLAY_URL || 'http://127.0.0.1:8060/', { waitUntil: 'load', timeout: 30000 });
      console.log('Loaded HTML for ' + device.name);
      await page.screenshot({ path: path.join(output, device.name + '-loading.png') });
      await page.waitForFunction(() => {
        const status = document.querySelector('#status');
        const canvas = document.querySelector('#canvas');
        return canvas && canvas.width > 0 && (!status || getComputedStyle(status).display === 'none');
      }, null, { timeout: 60000 });
      await page.waitForTimeout(1400);
      await page.screenshot({ path: path.join(output, device.name + '.png') });
      // Match the public UI layout to target real map entities and avatar buttons.
      const width = device.viewport.width;
      const height = device.viewport.height;
      const stretch = Math.min(width / 480, height / 800);
      const logicalWidth = width / stretch;
      const logicalHeight = height / stretch;
      const narrow = logicalWidth < 800;
      const pad = narrow ? 16 : 28;
      const contentWidth = logicalWidth - 2 * pad;
      const mapWidth = narrow ? contentWidth : contentWidth - 284;
      const mapHeight = narrow ? mapWidth * 540 / 960 : logicalHeight - 350;
      const worldScale = Math.min((mapWidth - 12) / 960, (mapHeight - 12) / 540);
      const mapOrigin = [pad + 6 + (mapWidth - 12 - 960 * worldScale) / 2,
        198 + (mapHeight - 12 - 540 * worldScale) / 2];
      const pointOnMap = (x, y) => [(mapOrigin[0] + x * worldScale) * stretch,
        (mapOrigin[1] + y * worldScale) * stretch];
      const click = async point => device.hasTouch
        ? page.touchscreen.tap(...point) : page.mouse.click(...point);
      const infoRect = narrow
        ? { x: pad * stretch, y: (204 + mapHeight) * stretch,
          width: contentWidth * stretch, height: (logicalHeight - 362 - mapHeight) * stretch }
        : { x: (logicalWidth - pad - 268) * stretch, y: 192 * stretch,
          width: 268 * stretch, height: (logicalHeight - 350) * stretch };
      const cardHash = async () => createHash('sha256').update(await page.screenshot({ clip: infoRect })).digest('hex');
      const ownerCard = await cardHash();
      await click(pointOnMap(220, 130));
      await page.waitForTimeout(220);
      const objectCard = await cardHash();
      if (objectCard === ownerCard) errors.push('Clicking the house did not change the information card');
      await page.screenshot({ path: path.join(output, device.name + '-object.png') });
      // Middle bottom card selects AI-01; the next tap orders it across empty ground.
      await click([width / 2, height - 73 * stretch]);
      await page.waitForTimeout(220);
      if (await cardHash() === objectCard) errors.push('The AI avatar did not change the information card');
      await click(pointOnMap(740, 450));
      await page.waitForTimeout(1200);
      await page.screenshot({ path: path.join(output, device.name + '-interaction.png') });
      const metrics = await page.evaluate(() => ({
        viewport: [innerWidth, innerHeight],
        canvas: [document.querySelector('#canvas').width, document.querySelector('#canvas').height],
        horizontalOverflow: document.documentElement.scrollWidth > innerWidth,
        verticalOverflow: document.documentElement.scrollHeight > innerHeight,
      }));
      if (metrics.horizontalOverflow || metrics.verticalOverflow) errors.push('Document overflows viewport');
      const result = { device: device.name, ...metrics, errors, passed: errors.length === 0 };
      results.push(result);
      await fs.writeFile(path.join(output, device.name + '-console.txt'), consoleLines.join('\n'));
      console.log(JSON.stringify(result));
      await context.close();
    }
  } finally {
    await browser.close();
  }
  await fs.writeFile(path.join(output, 'browser-results.json'), JSON.stringify(results, null, 2));
  if (results.some(result => !result.passed)) process.exitCode = 1;
})().catch(error => { console.error(error); process.exitCode = 1; });
