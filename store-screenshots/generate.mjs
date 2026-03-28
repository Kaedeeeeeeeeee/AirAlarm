import puppeteer from 'puppeteer-core';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const WIDTH = 1284;
const HEIGHT = 2778;

const slideNames = [
  '01-perfect-moment',
  '02-sleep-smarter',
  '03-airpods-detect',
  '04-wake-window',
  '05-sleep-sounds',
];

async function generate() {
  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--force-device-scale-factor=1',
      '--allow-file-access-from-files',
    ],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: WIDTH, height: HEIGHT, deviceScaleFactor: 1 });

  const templateUrl = `file://${path.join(__dirname, 'template.html')}`;

  for (const lang of ['en', 'zh']) {
    const outDir = path.join(__dirname, lang);
    fs.mkdirSync(outDir, { recursive: true });

    for (let i = 0; i < 5; i++) {
      const url = `${templateUrl}?lang=${lang}&slide=${i + 1}`;
      await page.goto(url, { waitUntil: 'networkidle0', timeout: 10000 });
      // Extra wait for images to render
      await new Promise(r => setTimeout(r, 500));

      const outPath = path.join(outDir, `${slideNames[i]}.png`);
      await page.screenshot({ path: outPath, type: 'png' });
      console.log(`✓ ${lang}/${slideNames[i]}.png`);
    }
  }

  await browser.close();
  console.log('\nDone! Generated 10 App Store screenshots.');
}

generate().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
