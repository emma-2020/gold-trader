const C='gtp-v5';
self.addEventListener('install',e=>{self.skipWaiting();});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==C).map(x=>caches.delete(x)))));});
self.addEventListener('fetch',e=>{if(/tradingview|twelvedata|metals\.live|swissquote|yahoo/.test(e.request.url))return;e.respondWith(fetch(e.request).catch(()=>caches.match(e.request)));});
