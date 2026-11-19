// Keep a port open to the extension's offscreen page for as long as this page lives. If this page's
// process dies, the port closes without the page unloading, and background.js checks whether the tab died.
(() => {
  const loadedMs = Math.round(performance.timeOrigin);
  let retryMs = 1000;

  function connect() {
    if (!chrome.runtime?.id) return; // The extension was reloaded, which orphans this copy of the script.
    const openedMs = Date.now();
    const port = chrome.runtime.connect({ name: `page ${loadedMs}` });
    port.onDisconnect.addListener(() => {
      void chrome.runtime.lastError;
      if (!chrome.runtime?.id) return;
      // This page still runs, so the offscreen page is gone or this page came back from the back/forward
      // cache. Wake the service worker to reopen the offscreen page, then reconnect, slower if it keeps failing.
      retryMs = Date.now() - openedMs > 10000 ? 1000 : Math.min(retryMs * 2, 60000);
      chrome.runtime
        .sendMessage({ type: "ensure-offscreen" })
        .catch(() => {})
        .finally(() => setTimeout(connect, retryMs));
    });
  }

  connect();
})();
