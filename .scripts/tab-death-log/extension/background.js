// When a page's port closes (see content.js), decide whether its tab died, and log it through the
// native-messaging host (../host.py), which appends to ~/.local/share/browser-tab-watchdog/tab-deaths.jsonl.
const HOST = "dotfiles.tab_death_log";
const CHECK_AFTER_MS = 3000;
const logged = new Set();

async function ensureOffscreen() {
  if (await chrome.offscreen.hasDocument()) return;
  try {
    await chrome.offscreen.createDocument({
      url: "offscreen.html",
      reasons: ["WORKERS"],
      justification: "Hold each page's port open, to notice when a tab's page process dies.",
    });
  } catch (error) {
    // Two wake-ups can race to create it; only one offscreen page is allowed.
    if (!String(error).includes("single offscreen")) throw error;
  }
}

const origin = (url) => {
  try {
    return new URL(url).origin;
  } catch {
    return undefined;
  }
};

async function checkTab({ tabId, url, loadedMs, portClosedMs }) {
  await new Promise((resolve) => setTimeout(resolve, CHECK_AFTER_MS));
  let tab;
  try {
    tab = await chrome.tabs.get(tabId);
  } catch {
    return console.log("closed", tabId, url);
  }
  // Memory Saver unloaded it, it is loading a page, or it went to another site (or a brave:// page).
  if (tab.discarded) return console.log("discarded", tabId, url);
  if (tab.status === "loading") return console.log("loading", tabId, url);
  if (origin(tab.url) === undefined || origin(tab.url) !== origin(url)) return console.log("navigated", tabId, url, tab.url);
  // A tab whose page process died keeps its address and title, but no script can run in it.
  let probeError;
  try {
    await chrome.scripting.executeScript({ target: { tabId }, func: () => true });
    return console.log("alive", tabId, url);
  } catch (error) {
    probeError = String(error?.message ?? error);
  }
  // A page has two ports if content.js went into it twice (from the manifest, and from onInstalled below).
  const page = `${tabId} ${loadedMs}`;
  if (logged.has(page)) return;
  logged.add(page);
  setTimeout(() => logged.delete(page), 60000);
  const death = {
    port_closed_ms: portClosedMs,
    url: tab.url,
    title: tab.title,
    tab_id: tabId,
    window_id: tab.windowId,
    active: tab.active,
    audible: Boolean(tab.audible),
    pinned: tab.pinned,
    open_seconds: Math.round((portClosedMs - loadedMs) / 1000),
    probe_error: probeError,
  };
  console.log("died", death);
  await chrome.runtime.sendNativeMessage(HOST, death).catch((error) => console.error("log failed", error));
}

chrome.runtime.onStartup.addListener(ensureOffscreen);
chrome.runtime.onInstalled.addListener(async () => {
  await ensureOffscreen();
  // The manifest only adds content.js to pages loaded from now on, so add it to the pages already open.
  for (const tab of await chrome.tabs.query({ url: ["http://*/*", "https://*/*", "file:///*"] })) {
    chrome.scripting.executeScript({ target: { tabId: tab.id }, files: ["content.js"] }).catch(() => {});
  }
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message?.type === "ensure-offscreen") {
    ensureOffscreen().finally(() => sendResponse());
    return true;
  }
  // Only the offscreen page reports closed ports; pages have a sender.tab.
  if (message?.type === "page-port-closed" && !sender.tab && sender.url === chrome.runtime.getURL("offscreen.html")) {
    checkTab(message);
  }
});
