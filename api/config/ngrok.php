<?php
return [
    'enabled' => env('NGROK_ENABLED', false),
    'dashboard_url' => env('NGROK_DASHBOARD_URL', 'http://ngrok:4040'),
    'cache_ttl' => env('NGROK_CACHE_TTL', 60),
];
