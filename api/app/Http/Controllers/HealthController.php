<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class HealthController extends Controller
{
    public function check(): JsonResponse
    {
        $start = microtime(true);
        $dbStatus = 'ok';
        $dbError = null;
        try {
            DB::connection()->getPdo();
        } catch (\Throwable $e) {
            $dbStatus = 'error';
            $dbError = $e->getMessage();
        }
        $latencyMs = round((microtime(true) - $start) * 1000, 2);
        return response()->json([
            'status' => 'ok',
            'service' => 'SISCOPN API',
            'version' => '1.0.0',
            'timestamp' => now()->toIso8601String(),
            'latency_ms' => $latencyMs,
            'database' => ['status' => $dbStatus, 'error' => $dbError],
            'server' => [
                'php' => PHP_VERSION,
                'laravel' => app()->version(),
                'environment' => app()->environment(),
            ],
        ]);
    }
}
