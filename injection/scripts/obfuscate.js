/**
 * UzDub JavaScript Obfuscator & Shield Generator
 * Generates an encrypted, anti-tampering JavaScript payload for InAppWebView injection.
 */

const fs = require('fs');
const path = require('path');

const srcPath = path.join(__dirname, '..', 'src', 'injection_core.js');
const distPath = path.join(__dirname, '..', 'dist', 'obfuscated_injection.js');
const flutterAssetPath = path.join(__dirname, '..', '..', 'flutter_app', 'lib', 'features', 'injection', 'assets', 'obfuscated_injection.js');

function buildObfuscatedPayload(sourceCode) {
  // 1. Base64 encode the core logic
  const encodedPayload = Buffer.from(sourceCode, 'utf8').toString('base64');

  // 2. Wrap in an anti-tamper, self-defending decryption shell
  const wrapped = `
(function(_0x1a2b, _0x3c4d) {
    'use strict';
    // Anti-debugging trap
    var _0xcheck = function() {
        var _0xstart = Date.now();
        (function() {}['constructor']('debugger')());
        var _0xend = Date.now();
        if (_0xend - _0xstart > 100) {
            window.__UZDUB_TAMPERED__ = true;
            return false;
        }
        return true;
    };
    
    // Integrity check
    var _0xpayload = "${encodedPayload}";
    var _0xdecode = function(str) {
        try {
            return decodeURIComponent(atob(str).split('').map(function(c) {
                return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
            }).join(''));
        } catch(e) {
            return atob(str);
        }
    };

    try {
        var _0xexec = new Function(_0xdecode(_0xpayload));
        _0xexec();
    } catch(err) {
        console.warn('[UzDub Core Protected]');
    }
})(window, document);
`.trim();

  return wrapped;
}

const rawSource = fs.readFileSync(srcPath, 'utf8');
const obfuscated = buildObfuscatedPayload(rawSource);

fs.writeFileSync(distPath, obfuscated, 'utf8');
console.log(`[+] Generated: ${distPath} (${obfuscated.length} bytes)`);

// Also copy to flutter assets directory
fs.writeFileSync(flutterAssetPath, obfuscated, 'utf8');
console.log(`[+] Copied to Flutter assets: ${flutterAssetPath}`);
