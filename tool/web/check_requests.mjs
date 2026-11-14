// Loads the built web app in headless Chrome and fails if a page requests
// anything outside its own origin, or the browser reports a Content Security
// Policy violation (r-06, ADR-043). Uses only Node (>= 22) and Chrome's
// DevTools protocol, no packages.
//
//   node tool/web/check_requests.mjs http://127.0.0.1:8765/CatholicPrayer/ [chrome]
//
// Visits each screen in SCREENS, in each language of LANGUAGES (the browser's
// language picks the app's), and waits for it to settle.
import { spawn } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const base = process.argv[2];
const chrome = process.argv[3] ?? 'google-chrome';
const SCREENS = ['', '#/library', '#/library/hail_mary', '#/learn', '#/learn/joyful',
  '#/pray', '#/settings', '#/today', '#/chaplet/divine-mercy', '#/rosary/sorrowful',
  '#/rosary/joyful/passage/1'];
const LANGUAGES = ['en', 'es', 'fr'];
const origin = new URL(base).origin;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const outside = new Set();
const violations = [];
const missing = new Set();

async function run(lang) {
  const profile = mkdtempSync(join(tmpdir(), 'check-requests-'));
  const browser = spawn(chrome, ['--headless=new', '--no-first-run', '--no-default-browser-check',
    '--disable-background-networking', '--disable-component-update', '--disable-sync',
    `--user-data-dir=${profile}`, `--lang=${lang}`, `--accept-lang=${lang}`, '--remote-debugging-port=0', '--window-size=900,1200',
    'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const wsUrl = await new Promise((resolve, reject) => {
    let log = '';
    browser.stderr.on('data', (d) => {
      log += d;
      const m = log.match(/DevTools listening on (ws:\S+)/);
      if (m) resolve(m[1]);
    });
    browser.on('exit', () => reject(new Error(`Chrome exited:\n${log}`)));
  });

  const ws = new WebSocket(wsUrl);
  await new Promise((r) => ws.addEventListener('open', r));
  let nextId = 0;
  const pending = new Map();
  const send = (method, params = {}, sessionId) => new Promise((resolve) => {
    const id = ++nextId;
    pending.set(id, resolve);
    ws.send(JSON.stringify({ id, method, params, sessionId }));
  });
  ws.addEventListener('message', (event) => {
    const msg = JSON.parse(event.data);
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg.result ?? msg.error);
      pending.delete(msg.id);
    } else if (msg.method === 'Network.requestWillBeSent') {
      const url = msg.params.request.url;
      if (/^https?:/.test(url) && new URL(url).origin !== origin) outside.add(url);
      // The engine asks for a fallback font when a character isn't in Roboto.
      if (url.includes('/assets/fonts/fallback/')) missing.add(url);
    } else if (msg.method === 'Log.entryAdded') {
      const { source, level, text } = msg.params.entry;
      if (source === 'security' || /Content Security Policy/i.test(text)) violations.push(text);
      else if (level === 'error') console.log(`console error: ${text}`);
    } else if (msg.method === 'Runtime.consoleAPICalled' && msg.params.type === 'error') {
      console.log(`console error: ${msg.params.args.map((a) => a.value ?? a.description).join(' ')}`);
    }
  });

  const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
  for (const domain of ['Network', 'Log', 'Runtime', 'Page']) await send(`${domain}.enable`, {}, sessionId);
  for (const screen of SCREENS) {
    await send('Page.navigate', { url: base + screen }, sessionId);
    await sleep(screen === '' ? 8000 : 3000);
    console.log(`visited ${base}${screen} (${lang})`);
  }
  ws.close();
  browser.kill();
  await sleep(500);
  rmSync(profile, { recursive: true, force: true });

}

for (const lang of LANGUAGES) await run(lang);

for (const url of outside) console.log(`::error::Request outside ${origin}: ${url}`);
for (const text of violations) console.log(`::error::CSP: ${text}`);
for (const url of missing) console.log(`::error::A character is missing from the bundled Roboto: ${url}`);
if (outside.size || violations.length || missing.size) process.exit(1);
console.log(`No request outside ${origin}, no CSP violation, no missing character.`);
