// Takes the store screenshots from a web build of lib/shots.dart.
//
//   flutter build web --release -t lib/shots.dart -o build/shots
//   npx http-server build/shots -p 8793 -c-1 --silent
//   node tool/store_shots/store_shots.js 8793 [device ...]
// Set ONLY=03 (a shot-name prefix) to retake just one shot.
//
// Needs `playwright` resolvable from where it is run (it is not a project
// dependency; install it in a scratch folder and run from there).
// Viewports are logical points with the device's pixel density, so the UI
// is the size it is on the real device.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..');
const WEB = path.join(ROOT, 'build', 'shots');

const DEVICES = {
  phone: { w: 360, h: 720, scale: 3 }, // 1080 x 2160, Google Play phone
  'tablet-7in': { w: 600, h: 960, scale: 2 }, // 1200 x 1920
  'tablet-10in': { w: 800, h: 1280, scale: 2 }, // 1600 x 2560
  'iphone-6.3in': { w: 402, h: 874, scale: 3 }, // 1206 x 2622
  'ipad-13in': { w: 1032, h: 1376, scale: 2 }, // 2064 x 2752
};

// name, query, milliseconds to let the scene run before the shutter.
const SHOTS = [
  ['01-pho-sai-gon', 's=ride&theme=0&bike=0&skip=31&seed=2', 900],
  ['02-van-het-ga', 's=ride&theme=2&two=1&bike=5&skip=12&seed=9&boost=1', 900],
  // No pre-roll: the grid lined up under the countdown.
  ['03-dua-chang', 's=ride&stage=3&bike=2', 0],
  ['04-gara', 's=garage&bike=6', 600],
  ['05-ha-noi', 's=ride&mission=4&bike=1&skip=22', 900],
  ['06-deo-chieu-ta', 's=ride&theme=3&two=1&dusk=1&bike=4&skip=27&seed=5', 900],
  ['07-mien-tay', 's=ride&mission=6&bike=3&skip=16', 900],
  ['08-chang-dua', 's=stages', 600],
];

(async () => {
  const [port, ...only] = process.argv.slice(2);
  const browser = await chromium.launch({ args: ['--no-sandbox', '--enable-unsafe-swiftshader'] });
  for (const [device, d] of Object.entries(DEVICES)) {
    if (only.length && !only.includes(device)) continue;
    const out = path.join(ROOT, 'store', device);
    fs.mkdirSync(out, { recursive: true });
    const ctx = await browser.newContext({
      viewport: { width: d.w, height: d.h },
      deviceScaleFactor: d.scale,
    });
    const page = await ctx.newPage();
    page.on('pageerror', (e) => console.log('pageerror:', e.message));
    // The default bootstrap fetches CanvasKit from a CDN; serve the local copy.
    await page.route('https://www.gstatic.com/flutter-canvaskit/**', (route) => {
      const file = route.request().url().split('/').slice(5).join('/');
      const local = path.join(WEB, 'canvaskit', file);
      if (fs.existsSync(local)) route.fulfill({ path: local });
      else route.continue();
    });
    for (const [name, query, settle] of SHOTS) {
      if (process.env.ONLY && !name.startsWith(process.env.ONLY)) continue;
      await page.goto(`http://localhost:${port}/?nocache=${Date.now()}&${query}`);
      // First frame marks the app as up; then let the scene play a moment.
      await page.waitForFunction(() => !!document.querySelector('flt-glass-pane, flutter-view'), null, { timeout: 30000 });
      await page.waitForTimeout(2600 + settle);
      await page.screenshot({ path: path.join(out, name + '.png') });
      console.log(device, name);
    }
    await ctx.close();
  }
  await browser.close();
})();
