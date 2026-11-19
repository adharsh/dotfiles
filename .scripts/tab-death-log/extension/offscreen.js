// Hold the ports content.js opens. This page stays open, unlike the service worker, which stops when idle
// and would close every port with it. It can only use chrome.runtime, so the worker does the checking.
chrome.runtime.onConnect.addListener((port) => {
  const { tab, frameId, url } = port.sender ?? {};
  if (!port.name.startsWith("page ") || !tab || frameId !== 0) return;
  port.onDisconnect.addListener(() => {
    chrome.runtime
      .sendMessage({
        type: "page-port-closed",
        portClosedMs: Date.now(),
        tabId: tab.id,
        url,
        loadedMs: Number(port.name.slice("page ".length)),
      })
      .catch(() => {});
  });
});
