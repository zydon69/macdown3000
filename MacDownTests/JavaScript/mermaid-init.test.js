'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

// Exercise our DOM adapter with a controlled renderer rejection. Mermaid
// itself is deliberately not mocked as a security guarantee for its SVGs.
(async function () {
  let onLoad;
  let replacement;
  const pre = { tagName: 'PRE', parentNode: {
    replaceChild(element, original) {
      assert.equal(original, pre);
      replacement = element;
    }
  } };
  const code = { textContent: 'invalid graph', parentElement: pre };
  const message = '<img src=x onerror=alert(1)>';
  const context = {
    document: {
      readyState: 'complete', body: { contains: node => node === pre },
      querySelectorAll: () => [code],
      createElement: (tag) => ({ tagName: tag, style: {} })
    },
    window: { addEventListener: (event, callback) => { onLoad = callback; } },
    console: { warn() {}, error() {} },
    mermaid: { initialize() {}, async render() { throw new Error(message); } }
  };
  vm.runInNewContext(fs.readFileSync(path.join(__dirname,
    '../../MacDown/Resources/Extensions/mermaid.init.js'), 'utf8'), context);
  await onLoad();
  assert.equal(replacement.tagName, 'pre');
  assert.equal(replacement.textContent, 'Mermaid Error: ' + message);
  assert.equal(replacement.innerHTML, undefined);
  assert.equal(pre.outerHTML, undefined);
  process.stdout.write('Mermaid error text boundary: passed\n');
})().catch(error => { console.error(error); process.exitCode = 1; });
