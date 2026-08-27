<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'service' => 'SISCOPN API',
        'version' => '1.0.0',
        'timestamp' => now()->toIso8601String(),
        'latency_ms' => 0,
    ]);
});

Route::post('auth/login', [AuthController::class, 'login']);
