// Stockerly Service Worker — cache-first for static assets, network-first for pages
const CACHE_VERSION = "v3";
const STATIC_CACHE = `stockerly-static-${CACHE_VERSION}`;
const FONT_CACHE = `stockerly-fonts-${CACHE_VERSION}`;
const OFFLINE_URL = "/offline.html";

// Assets to pre-cache on install
const PRECACHE_URLS = [
  OFFLINE_URL,
  "/icon.svg",
  "/icon-192.svg",
  "/icon-512.svg"
];

// Install: pre-cache offline page and icons
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(PRECACHE_URLS))
  );
  self.skipWaiting();
});

// Activate: clean up old caches
self.addEventListener("activate", (event) => {
  const currentCaches = [STATIC_CACHE, FONT_CACHE];
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key.startsWith("stockerly-") && !currentCaches.includes(key))
          .map((key) => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

// Fetch: network-first for navigation, cache-first for static assets
self.addEventListener("fetch", (event) => {
  const { request } = event;

  // Only handle GET requests
  if (request.method !== "GET") return;

  // Skip non-http(s) requests (chrome-extension, etc.)
  if (!request.url.startsWith("http")) return;

  // Navigation requests: network-first with offline fallback
  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request).catch(() => caches.match(OFFLINE_URL))
    );
    return;
  }

  // Google Fonts: cache-first (fonts rarely change)
  if (isGoogleFont(request.url)) {
    event.respondWith(
      caches.match(request).then((cached) => {
        if (cached) return cached;
        return fetch(request).then((response) => {
          if (response.ok) {
            const clone = response.clone();
            caches.open(FONT_CACHE).then((cache) => cache.put(request, clone));
          }
          return response;
        });
      })
    );
    return;
  }

  // Static assets (CSS, JS, images, fonts): stale-while-revalidate
  if (isStaticAsset(request.url)) {
    event.respondWith(
      caches.match(request).then((cached) => {
        const fetchPromise = fetch(request).then((response) => {
          if (response.ok) {
            const clone = response.clone();
            caches.open(STATIC_CACHE).then((cache) => cache.put(request, clone));
          }
          return response;
        });
        return cached || fetchPromise;
      })
    );
    return;
  }
});

function isStaticAsset(url) {
  return /\.(css|js|png|jpg|jpeg|svg|ico|woff2?|ttf|eot)(\?.*)?$/.test(url);
}

function isGoogleFont(url) {
  return url.startsWith("https://fonts.googleapis.com") || url.startsWith("https://fonts.gstatic.com");
}
