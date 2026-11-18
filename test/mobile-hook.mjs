// Run the fetch hook injected into the mobile UI template against a fake /nodes reply.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const tpl = readFileSync(process.argv[2], 'utf8');
const hook = tpl.match(/<script>\s*\/\/ SHUSHMOX-PATCHED([\s\S]*?)<\/script>/)[1];

const nodes = { data: [{ node: 'a', level: '' }, { node: 'b' }, { node: 'c', level: 'c' }] };
globalThis.window = globalThis;
globalThis.location = { href: 'https://pve:8006/pve2/mobile/' };
globalThis.fetch = async () => new Response(JSON.stringify(nodes), { status: 200 });
new Function(hook)();

const levels = async (url) => (await (await fetch(new Request(url))).json()).data.map((n) => n.level);
assert.deepEqual(await levels('https://pve:8006/api2/extjs/nodes'), ['shushmox', 'shushmox', 'c']);
assert.deepEqual(await levels('https://pve:8006/api2/json/nodes'), ['shushmox', 'shushmox', 'c']);
assert.deepEqual(await levels('https://pve:8006/api2/extjs/nodes/a/status'), ['', undefined, 'c']);
