/* Rizzr Service Worker — PWA offline caching */
/* Subpath-safe: derive base from registration scope (works under /Rizzr/ and local) */
const CACHE = 'rizzr-v3-subpath';
const BASE = new URL('./', self.registration.scope).href.replace(/\/$/, '');
const ASSETS = [
  BASE + '/',
  BASE + '/index.html',
  BASE + '/settings.html',
  BASE + '/pricing.html',
  BASE + '/privacy.html',
  BASE + '/assets/css/midnight-aura.css',
  BASE + '/assets/js/api.js',
  BASE + '/manifest.json',
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE).then((c) =>
      Promise.allSettled(ASSETS.map((url) => c.add(url)))
    )
  );
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  // Let API calls go straight to network
  if (req.method !== 'GET' || req.url.includes('/api/')) return;
  const url = new URL(req.url);

  // Navigation (HTML): network-first, fall back to cache if offline
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(url.href, copy));
          return res;
        })
        .catch(() => caches.match(req).then((c) => c || caches.match(BASE + '/index.html')))
    );
    return;
  }

  // Assets: stale-while-revalidate
  e.respondWith(
    caches.match(req).then((cached) => {
      const network = fetch(req)
        .then((res) => {
          if (res && res.status === 200) {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put(url.href, copy));
          }
          return res;
        })
        .catch(() => cached);
      return cached || network;
    })
  );
});
