#!/usr/bin/env bash
set -euo pipefail

echo "=== SISCOPN — bootstrap do Codespace ==="
echo "Stack: Laravel 13 + React Native + Expo 54 + MySQL 8 + Redis 7"
echo "Disciplina: Desenvolvimento de Software Integrado — IFPA 2026.2"
echo "Professor: Edinelson Junior (edinelson.sousa@ifpa.edu.br)"
echo

# Desabilitar Xdebug (interfere com artisan)
export XDEBUG_MODE=off
export XDEBUG_SESSION=
export PHP_IDE_CONFIG=

# ============ Detectar PROJECT_ROOT ============
find_project_root() {
  local dir="$(pwd)"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.devcontainer" ]; then echo "$dir"; return 0; fi
    if [ -f "$dir/composer.json" ] && grep -q "laravel/framework" "$dir/composer.json" 2>/dev/null; then
      echo "$(dirname "$dir")"; return 0
    fi
    dir="$(dirname "$dir")"
  done
  pwd
}

PROJECT_ROOT="$(find_project_root)"
if [ "$(basename "$PROJECT_ROOT")" = "api" ]; then
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
fi
echo "  PROJECT_ROOT: $PROJECT_ROOT"

# ─── 1. Pacotes + zsh ────────────────────────────────────────────
echo "[1/13] Pacotes do sistema + zsh..."
sudo apt-get update -y >/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  git unzip curl wget jq build-essential ca-certificates xclip \
  zsh fonts-powerline redis-tools \
  >/dev/null
echo "    zsh: $(which zsh)"

# ─── 2. Oh My Zsh ─────────────────────────────────────────────────
echo "[2/13] Oh My Zsh..."
[ -d "$HOME/.oh-my-zsh" ] || RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# ─── 3. Plugins zsh ───────────────────────────────────────────────
echo "[3/13] Plugins zsh..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for entry in \
  "https://github.com/zsh-users/zsh-autosuggestions.git|zsh-autosuggestions" \
  "https://github.com/zsh-users/zsh-syntax-highlighting.git|zsh-syntax-highlighting" \
  "https://github.com/zsh-users/zsh-completions.git|zsh-completions"; do
  url="${entry%%|*}"; name="${entry##*|}"
  [ -d "$ZSH_CUSTOM/plugins/$name" ] || git clone --depth=1 "$url" "$ZSH_CUSTOM/plugins/$name"
done

# ─── 4. Tema Powerlevel10k ───────────────────────────────────────
echo "[4/13] Tema Powerlevel10k..."
[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

# ─── 5. zsh como shell padrão ─────────────────────────────────────
echo "[5/13] zsh como shell padrão..."
sudo chsh -s "$(which zsh)" vscode 2>/dev/null || true
sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || true

# ─── 5b. Configurar aliases zsh (sem precisar rodar manualmente) ────
# ─── 5c. Criar .env na raiz (para ngrok) ──────────────────────────────────
echo "[5c/15] Criando .env na raiz do projeto..."
if [ ! -f "$PROJECT_ROOT/.env" ]; then
  if [ -f "$PROJECT_ROOT/.env.example" ]; then
    cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
    echo "    [OK] .env criado na raiz"
  fi
fi

echo "[6/13] Configurando aliases zsh..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT_S="$(find_project_root)"

# Copiar .zshrc para ~/.zshrc.ifpa (idempotente)
if [ -f "$PROJECT_ROOT_S/.zshrc" ]; then
  cp "$PROJECT_ROOT_S/.zshrc" "$HOME/.zshrc.ifpa"
  echo "    ✓ ~/.zshrc.ifpa criado"

  # Adicionar source no ~/.zshrc se ainda não tiver
  if ! grep -q "zshrc.ifpa" "$HOME/.zshrc" 2>/dev/null; then
    echo "" >> "$HOME/.zshrc"
    echo "# IFPA — carregar aliases do projeto" >> "$HOME/.zshrc"
    echo "source ~/.zshrc.ifpa 2>/dev/null || true" >> "$HOME/.zshrc"
    echo "    ✓ source adicionado ao ~/.zshrc"
  fi
fi

# ─── 6. Composer ──────────────────────────────────────────────────
echo "[7/13] Composer..."
command -v composer >/dev/null || curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
echo "    $(composer --version | head -1)"

# ─── 7. Laravel 13 em /api ────────────────────────────────────────
echo "[8/13] Laravel 13 em /api..."
if [ ! -d "$PROJECT_ROOT/api" ]; then
  cd "$PROJECT_ROOT"
  composer create-project laravel/laravel:^13.0 api --no-interaction --prefer-dist 2>&1 | tail -3
  cd api
  php artisan key:generate --force >/dev/null 2>&1

  # Configurar .env do Laravel (drivers file — não precisa Redis instalado)
  sed -i 's|^APP_NAME=.*|APP_NAME=SISCOPN|' .env
  sed -i 's|^APP_URL=.*|APP_URL=http://localhost:8000|' .env
  sed -i 's|^DB_CONNECTION=.*|DB_CONNECTION=mysql|' .env
  sed -i 's|^DB_HOST=.*|DB_HOST=db|' .env
  sed -i 's|^DB_DATABASE=.*|DB_DATABASE=siscopn|' .env
  sed -i 's|^DB_USERNAME=.*|DB_USERNAME=root|' .env
  sed -i 's|^DB_PASSWORD=.*|DB_PASSWORD=root|' .env
  sed -i 's|^CACHE_STORE=.*|CACHE_STORE=file|' .env
  # Redis desabilitado (não tem php-redis instalado) — drivers FILE
  sed -i 's|^SESSION_DRIVER=.*|SESSION_DRIVER=file|' .env
  # session.connection não necessário com driver file
  sed -i 's|^QUEUE_CONNECTION=.*|QUEUE_CONNECTION=sync|' .env

  # Criar config/ngrok.php
  mkdir -p config app/Helpers app/Console/Commands
  cat > config/ngrok.php <<'CFG'
<?php
return [
    'enabled' => env('NGROK_ENABLED', false),
    'dashboard_url' => env('NGROK_DASHBOARD_URL', 'http://ngrok:4040'),
    'cache_ttl' => env('NGROK_CACHE_TTL', 60),
];
CFG

  # Criar App\Helpers\NgrokHelper (NOME DIFERENTE — sem conflito)
  cat > app/Helpers/NgrokHelper.php <<'HELPER'
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
HELPER

  # Criar comando artisan ngrok:url (importa NgrokHelper)
  cat > app/Console/Commands/NgrokUrl.php <<'CMD'
<?php

namespace App\Console\Commands;

use App\Helpers\NgrokHelper;
use Illuminate\Console\Command;

class NgrokUrl extends Command
{
    protected $signature = 'ngrok:url {--copy}';
    protected $description = 'Mostra a URL pública do ngrok';

    public function handle(): int
    {
        $url = NgrokHelper::publicUrl();
        if (!$url) {
            $this->error('ngrok não está rodando. Verifique: docker compose ps ngrok');
            return self::FAILURE;
        }
        $this->info("URL pública: {$url}");
        $this->info("API:        " . NgrokHelper::apiUrl());
        return self::SUCCESS;
    }
}
CMD

  # Adicionar autoload App\Helpers via PHP nativo (sem sed)
  php -r '
    $f = "composer.json";
    $c = json_decode(file_get_contents($f), true);
    if (isset($c["autoload"]["psr-4"]["App\\\\"])) {
      $c["autoload"]["psr-4"]["App\\\\Helpers\\\\"] = "app/Helpers/";
      file_put_contents($f, json_encode($c, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    }
  '
  composer dump-autoload --quiet 2>&1 | tail -1 || true

  cd "$PROJECT_ROOT"
  echo "    ✓ Laravel 13 criado"
else
  echo "    já existe"
fi

# ─── 8. Expo 54 em /mobile ────────────────────────────────────────
echo "[9/13] Expo 54 em /mobile..."
if [ ! -d "$PROJECT_ROOT/mobile" ]; then
  cd "$PROJECT_ROOT"
  rm -rf mobile
  yes "" | timeout 120 npx --yes create-expo-app@latest mobile --template blank-typescript@54 --no-install > /tmp/expo.log 2>&1 || true
  if [ ! -d "$PROJECT_ROOT/mobile" ]; then
    yes "" | timeout 120 npx --yes create-expo-app@latest mobile --template blank-typescript@53 --no-install > /tmp/expo2.log 2>&1 || true
  fi
  if [ -d "$PROJECT_ROOT/mobile" ]; then
    cd "$PROJECT_ROOT/mobile"
    cat > .env <<'MENV'
EXPO_PUBLIC_API_URL=http://localhost:8000/api
EXPO_PUBLIC_APP_NAME=SISCOPN
MENV
    npm install --no-audit --no-fund 2>&1 | tail -2 || true

  # Garantir react-native-safe-area-context para SafeAreaView modernizado
  if [ -f package.json ] && ! grep -q '"react-native-safe-area-context"' package.json; then
    npm install --no-audit --no-fund react-native-safe-area-context >/dev/null 2>&1 || true
  fi

    cd "$PROJECT_ROOT"
    echo "    ✓ Expo 54 criado"
  fi
else
  echo "    já existe"
fi

# ─── 9. Instalar ngrok CLI (download direto do binário) ────────────────
echo "[10/14] Instalando ngrok CLI..."
if ! command -v ngrok >/dev/null 2>&1; then
  # Tentar múltiplas URLs de download (algumas podem estar bloqueadas no proxy do Codespace)
  cd /tmp
  NGROK_INSTALLED=false

  # URL 1: bin.equinox.io (oficial do ngrok, pode estar bloqueado)
  curl -sSL --max-time 30 https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -o ngrok.tgz 2>/dev/null
  if [ -s ngrok.tgz ] && file ngrok.tgz | grep -q "gzip"; then
    tar -xzf ngrok.tgz
    sudo mv ngrok /usr/local/bin/ngrok
    rm -f ngrok.tgz
    NGROK_INSTALLED=true
    echo "    ✓ baixado de bin.equinox.io"
  fi

  # URL 2: GitHub releases (alternativa)
  if [ "$NGROK_INSTALLED" = false ]; then
    rm -f ngrok.tgz
    curl -sSL --max-time 30 https://github.com/ngrok/ngrok/releases/download/v3-stable/ngrok-v3-stable-linux-amd64.tgz -o ngrok.tgz 2>/dev/null
    if [ -s ngrok.tgz ] && file ngrok.tgz | grep -q "gzip"; then
      tar -xzf ngrok.tgz
      sudo mv ngrok /usr/local/bin/ngrok
      rm -f ngrok.tgz
      NGROK_INSTALLED=true
      echo "    ✓ baixado de github.com"
    fi
  fi

  # URL 3: API oficial do ngrok via s3 (formato zip)
  if [ "$NGROK_INSTALLED" = false ]; then
    rm -f ngrok.zip
    curl -sSL --max-time 30 https://ngrok-agent.s3.amazonaws.com/ngrok_v3-stable_linux_amd64.zip -o ngrok.zip 2>/dev/null
    if [ -s ngrok.zip ] && file ngrok.zip | grep -q "Zip"; then
      unzip -o ngrok.zip >/dev/null 2>&1
      sudo mv ngrok /usr/local/bin/ngrok
      rm -f ngrok.zip
      NGROK_INSTALLED=true
      echo "    ✓ baixado de ngrok-agent.s3.amazonaws.com (zip)"
    fi
  fi

  # Fallback: tentar via apt
  if [ "$NGROK_INSTALLED" = false ]; then
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc 2>/dev/null | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null || true
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null || true
    sudo apt-get update -y >/dev/null 2>&1 || true
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ngrok >/dev/null 2>&1 || true
    if command -v ngrok >/dev/null 2>&1; then
      NGROK_INSTALLED=true
      echo "    ✓ instalado via apt"
    fi
  fi
fi
if command -v ngrok >/dev/null 2>&1; then
  echo "    ✓ ngrok: $(ngrok version 2>&1 | head -1)"
else
  echo "    ⚠ ngrok não instalado"
fi

# ─── 10b. Garantir Sanctum e routes/api.php no Laravel ─────────────────
echo "[11/14] Verificando Sanctum e routes/api.php..."
if [ -d "$PROJECT_ROOT/api" ]; then
  cd "$PROJECT_ROOT/api"

  # Instalar Sanctum se não estiver
  if [ -f composer.json ] && ! grep -q '"laravel/sanctum"' composer.json; then
    echo "    Instalando laravel/sanctum..."
    composer require laravel/sanctum --quiet 2>&1 | tail -2 || true
  fi

  # Instalar API routes (caso não tenha)
  if [ ! -f routes/api.php ]; then
    echo "    Criando routes/api.php..."
    php artisan install:api --no-interaction --without-migration-prompt --passport=false 2>&1 | tail -3 || true
  fi

  # Se ainda não existir routes/api.php após tentativas, criar manualmente
  if [ ! -f routes/api.php ]; then
    cat > routes/api.php <<'APIROUTES'
<?php

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
APIROUTES
    echo "    ✓ routes/api.php criado manualmente"
  fi

  cd "$PROJECT_ROOT"
fi

# ─── 11. Criar HealthController + rota /api/health no Laravel ─────────
echo "[12/14] Criando HealthController no Laravel..."
if [ -d "$PROJECT_ROOT/api" ]; then
  cd "$PROJECT_ROOT/api"

  # HealthController
  # Garantir prefixo /api no bootstrap/app.php
  if [ ! -f bootstrap/app.php ] || ! grep -q 'api.*__DIR__.*api.php' bootstrap/app.php; then
    echo '    Configurando prefixo /api...'
    php artisan install:api --no-interaction --without-migration-prompt --passport=false >/dev/null 2>&1 || true
  fi

  mkdir -p app/Http/Controllers

  # Sobrescrever bootstrap/app.php para garantir api routing correto
  cat > bootstrap/app.php <<'BOOTSTRAP'
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );
    })->create();
BOOTSTRAP
  echo '    [OK] bootstrap/app.php com api routing'

  cat > app/Http/Controllers/HealthController.php <<'HEALTH'
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
HEALTH
  echo "    ✓ HealthController criado"

  # Rota /api/health — adicionada via PHP nativo (sem sed com escapes)
  if [ -f routes/api.php ]; then
    if ! grep -q "/health" routes/api.php; then
      # Adicionar rota no final
      echo "" >> routes/api.php
      echo "Route::get('/health', [HealthController::class, 'check']);" >> routes/api.php
      echo "    ✓ Rota /api/health adicionada"
    else
      echo "    ✓ Rota /api/health já existe"
    fi
  fi

  cd "$PROJECT_ROOT"
fi

# ─── 12. Criar feature de teste de conexão no Expo ────────────────────
echo "[13/14] Criando feature de teste de conexão no Expo..."
if [ -d "$PROJECT_ROOT/mobile" ]; then
  cd "$PROJECT_ROOT/mobile"

  # lib/api.ts — wrapper HTTP
  mkdir -p lib components
  cat > lib/api.ts <<'APITS'
import axios from 'axios';

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8000/api';
console.log('[SISCOPN API] Base URL:', API_URL);

const api = axios.create({
  baseURL: API_URL,
  timeout: 10000,
  headers: { Accept: 'application/json' },
});

export interface HealthCheckResult {
  success: boolean;
  error?: string;
  latencyMs?: number;
}

export async function checkHealth(): Promise<HealthCheckResult> {
  const start = Date.now();
  try {
    await api.get('/health');
    return { success: true, latencyMs: Date.now() - start };
  } catch (err: any) {
    const error = err?.message || 'Erro desconhecido';
    return { success: false, error, latencyMs: Date.now() - start };
  }
}

export function getApiUrl(): string {
  return API_URL;
}
APITS
  echo "    ✓ lib/api.ts criado"

  # components/HealthCheck.tsx — UI
  cat > components/HealthCheck.tsx <<'HEALTHCHECK'
import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native';
import { checkHealth, getApiUrl } from '../lib/api';

export default function HealthCheck() {
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState<boolean | null>(null);
  const [error, setError] = useState<string>('');
  const [latency, setLatency] = useState<number>(0);

  useEffect(() => { handleCheck(); }, []);

  async function handleCheck() {
    setLoading(true);
    const res = await checkHealth();
    setSuccess(res.success);
    setError(res.error || '');
    setLatency(res.latencyMs || 0);
    setLoading(false);
  }

  return (
    <View style={styles.container}>
      <View style={styles.card}>
        <Text style={styles.title}>Teste de Conexao</Text>
        <Text style={styles.url}>{getApiUrl()}</Text>
      </View>

      <TouchableOpacity
        style={[styles.button, loading && styles.buttonDisabled]}
        onPress={handleCheck}
        disabled={loading}
      >
        {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.buttonText}>Testar Conexao</Text>}
      </TouchableOpacity>

      {success !== null && !loading && (
        <View style={[styles.result, success ? styles.resultOk : styles.resultErr]}>
          <Text style={styles.resultText}>{success ? 'Conexao ativa' : 'Conexao falhou'}</Text>
          <Text style={styles.latency}>{latency}ms</Text>
          {!success && error ? <Text style={styles.errorText}>{error}</Text> : null}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, paddingTop: 60, backgroundColor: '#fafaf7' },
  card: { backgroundColor: '#fff', padding: 20, borderRadius: 8, marginBottom: 20, borderLeftWidth: 4, borderLeftColor: '#1e88e5' },
  title: { fontSize: 28, fontWeight: 'bold', color: '#046b3f', marginBottom: 8 },
  url: { fontSize: 13, color: '#1a1a1a', fontFamily: 'Courier New' },
  button: { backgroundColor: '#046b3f', padding: 16, borderRadius: 8, alignItems: 'center', marginBottom: 20 },
  buttonDisabled: { opacity: 0.6 },
  buttonText: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
  result: { padding: 24, borderRadius: 8, alignItems: 'center' },
  resultOk: { backgroundColor: '#e8f5e9', borderColor: '#2e7d32', borderWidth: 2 },
  resultErr: { backgroundColor: '#ffebee', borderColor: '#c62828', borderWidth: 2 },
  resultText: { fontSize: 24, fontWeight: 'bold', marginBottom: 8 },
  latency: { fontSize: 16, color: '#4a4a4a' },
  errorText: { fontSize: 12, color: '#c62828', marginTop: 8, fontFamily: 'Courier New', textAlign: 'center' },
});
HEALTHCHECK
  echo "    ✓ components/HealthCheck.tsx criado"

  # App.tsx — usar HealthCheck (com SafeAreaProvider moderno)
  cat > App.tsx <<'APPTSX'
import { StatusBar } from 'expo-status-bar';
import { StyleSheet } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import HealthCheck from './components/HealthCheck';

export default function App() {
  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
        <StatusBar style="auto" />
        <HealthCheck />
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fafaf7' },
});
APPTSX
  echo "    ✓ App.tsx atualizado"

  # Garantir que axios está instalado
  if [ -f package.json ] && ! grep -q '"axios"' package.json; then
    npm install --no-audit --no-fund axios 2>&1 | tail -2 || true
    echo "    ✓ axios instalado"
  fi

  cd "$PROJECT_ROOT"
fi

# ─── 13. Configurar ngrok com token do .env ──────────────────────────
echo "[14/14] Configurando ngrok..."
if command -v ngrok >/dev/null 2>&1; then
  # Ler token do .env (raiz do projeto ou do codespace)
  TOKEN=""
  for envfile in "$PROJECT_ROOT/.env" "$HOME/.env" "/workspaces/codespaces-blank/.env"; do
    if [ -f "$envfile" ]; then
      TOKEN=$(grep "^NGROK_AUTHTOKEN=" "$envfile" | head -1 | cut -d= -f2- | tr -d "[:space:]\"'")
      if [ -n "$TOKEN" ] && [ "$TOKEN" != "" ]; then
        echo "    Token encontrado em: $envfile"
        break
      fi
    fi
  done

  if [ -n "$TOKEN" ]; then
    ngrok config add-authtoken "$TOKEN" 2>&1 | tail -3
    echo "    ✓ ngrok configurado com token"
  else
    echo "    ⚠ NGROK_AUTHTOKEN não encontrado no .env"
    echo "    Para configurar: ngrok config add-authtoken SEU_TOKEN"
  fi
else
  echo "    ⚠ ngrok não instalado"
fi

echo
echo "=== Concluído ==="
echo "Proximos passos (em 4 abas de terminal):"
echo "  Aba 1: cd $PROJECT_ROOT && dcu"
echo "  Aba 2: cd $PROJECT_ROOT/api && pas"
echo "  Aba 3: cd $PROJECT_ROOT/api && ngrok:api"
echo "  Aba 4: cd $PROJECT_ROOT/mobile && ntunnel"
