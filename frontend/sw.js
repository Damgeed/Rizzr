/* Rizzr Service Worker — PWA offline caching */
const CACHE = 'rizzr-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/settings.html',
  '/pricing.html',
  '/privacy.html',
  '/assets/css/base.css',
  '/assets/css/theme-sunset.css',
  '/assets/css/theme-purple-dream.css',
  '/assets/css/theme-neon-nights.css',
  '/assets/js/i18n.js',
  '/assets/js/theme.js',
  '/assets/js/recorder.js',
  '/assets/js/api.js',
  '/assets/js/app.js',
  '/manifest.json',
];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  // Only cache GET, skip API calls
  if (e.request.method !== 'GET' || e.request.url.includes('/api/')) return;
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request))
  );
});
