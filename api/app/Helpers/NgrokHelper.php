<?php

namespace App\Helpers;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class NgrokHelper
{
    public static function publicUrl(): ?string
    {
        return Cache::remember('ngrok_public_url', (int) config('ngrok.cache_ttl', 60), function () {
            try {
                $dashboard = config('ngrok.dashboard_url', 'http://ngrok:4040');
                $response = Http::timeout(3)->get("{$dashboard}/api/tunnels");
                if (!$response->successful()) return null;
                foreach ($response->json('tunnels', []) as $tunnel) {
                    if (($tunnel['config']['addr'] ?? '') === '8000' && isset($tunnel['public_url'])) {
                        return $tunnel['public_url'];
                    }
                }
            } catch (\Throwable $e) {}
            return null;
        });
    }

    public static function apiUrl(): string
    {
        $public = self::publicUrl();
        return $public ? "{$public}/api" : config('app.url') . '/api';
    }
}
