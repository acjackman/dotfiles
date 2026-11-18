// ==UserScript==
// @name         Gmail Phish Test Banner
// @namespace    https://github.com/acjackman/dotfiles
// @version      1.0
// @description  Detect X-PHISHTEST header in Gmail emails and show a warning banner
// @match        https://mail.google.com/*
// @run-at       document-idle
// @grant        none
// ==/UserScript==

(function () {
  'use strict';

  const BANNER_ID = 'phishtest-banner';
  let cachedIk = null;
  let lastThreadId = null;

  function getIk() {
    if (cachedIk) return cachedIk;
    // Gmail embeds the ik parameter in page source
    const html = document.documentElement.innerHTML;
    // Try GLOBALS pattern: GLOBALS[9]="xxxxxxxx"
    const globalsMatch = html.match(/GLOBALS\[\d+\]\s*=\s*"([a-f0-9]+)"/);
    if (globalsMatch) {
      cachedIk = globalsMatch[1];
      return cachedIk;
    }
    // Try ik:"xxx" pattern
    const ikMatch = html.match(/[,\[]\s*"ik"\s*,\s*"([a-f0-9]+)"/);
    if (ikMatch) {
      cachedIk = ikMatch[1];
      return cachedIk;
    }
    // Try direct assignment pattern
    const directMatch = html.match(/ik=([a-f0-9]{6,})/);
    if (directMatch) {
      cachedIk = directMatch[1];
      return cachedIk;
    }
    return null;
  }

  function getThreadIdFromHash() {
    const hash = location.hash;
    // Match patterns like #inbox/18e1a2b3c4d5e6f7, #sent/18e1a2b3c4d5e6f7, etc.
    const match = hash.match(/#[^/]+\/([a-f0-9]{16,})/);
    return match ? match[1] : null;
  }

  function removeBanner() {
    const existing = document.getElementById(BANNER_ID);
    if (existing) existing.remove();
  }

  function showBanner() {
    removeBanner();
    const banner = document.createElement('div');
    banner.id = BANNER_ID;
    banner.textContent = 'This is a phishing test email.';
    Object.assign(banner.style, {
      position: 'fixed',
      top: '0',
      left: '0',
      right: '0',
      zIndex: '999999',
      background: '#d93025',
      color: '#fff',
      padding: '12px 24px',
      fontSize: '16px',
      fontWeight: 'bold',
      textAlign: 'center',
      boxShadow: '0 2px 8px rgba(0,0,0,0.3)',
    });
    document.body.appendChild(banner);
  }

  async function checkThread(threadId) {
    const ik = getIk();
    if (!ik) {
      console.warn('[PhishTest] Could not extract ik parameter');
      return;
    }

    try {
      const resp = await fetch(`/mail/u/0/?ui=2&ik=${ik}&view=om&th=${threadId}`);
      if (!resp.ok) return;

      const text = await resp.text();
      // Headers end at the first blank line
      const headerEnd = text.search(/\r?\n\r?\n/);
      const headers = headerEnd > 0 ? text.substring(0, headerEnd) : text;

      if (/^X-PHISHTEST\s*:/im.test(headers)) {
        showBanner();
      } else {
        removeBanner();
      }
    } catch (e) {
      console.warn('[PhishTest] Fetch error:', e);
    }
  }

  function onNavigate() {
    const threadId = getThreadIdFromHash();
    if (!threadId) {
      removeBanner();
      lastThreadId = null;
      return;
    }
    if (threadId === lastThreadId) return;
    lastThreadId = threadId;
    checkThread(threadId);
  }

  // Watch for hash changes (Gmail SPA navigation)
  window.addEventListener('hashchange', onNavigate);

  // Initial check
  onNavigate();
})();
