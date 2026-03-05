// ==UserScript==
// @name         Block donotreply.biz
// @namespace    https://gist.github.com/acjackman/532415a2a83efb169395dd4fa5edaaca
// @version      1.0
// @description  Block phishing test links from donotreply.biz with a notification
// @match        *://*/*
// @run-at       document-start
// @grant        GM_notification
// @updateURL    https://gist.githubusercontent.com/acjackman/532415a2a83efb169395dd4fa5edaaca/raw/block-donotreply-biz.user.js
// @downloadURL  https://gist.githubusercontent.com/acjackman/532415a2a83efb169395dd4fa5edaaca/raw/block-donotreply-biz.user.js
// ==/UserScript==

document.addEventListener('click', (e) => {
  const link = e.target.closest('a');
  if (link && link.hostname.endsWith('donotreply.biz')) {
    e.preventDefault();
    e.stopImmediatePropagation();
    GM_notification({ text: 'This link is a phishing test and has been blocked.', title: 'Phishing Test' });
  }
}, true);
