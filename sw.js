const C = 'gtp-v7';
self.addEventListener('install', e => { self.skipWaiting(); });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(k => Promise.all(k.filter(x => x !== C).map(x => caches.delete(x))))); });
self.addEventListener('fetch', e => {
  if (/tradingview|twelvedata|metals\.live|swissquote|yahoo|vercel\.app/.test(e.request.url)) return;
  e.respondWith(fetch(e.request).catch(() => caches.match(e.request)));
});

// Handle push notifications
self.addEventListener('push', e => {
  const data = e.data ? e.data.json() : { title: 'Gold Trader Pro', body: 'Signal alert' };
  e.waitUntil(self.registration.showNotification(data.title, {
    body: data.body, icon: '/icon-192.png', badge: '/icon-192.png',
    tag: 'gtp-signal', renotify: true,
    data: { url: data.url || '/' }
  }));
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(clients.openWindow(e.notification.data.url || '/'));
});
