# IFPA — .zshrc do SISCOPN (Codespace blank template)

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git docker docker-compose composer npm node laravel artisan
  web-search copypath copyfile copybuffer dirhistory history jsontools sudo extract
  zsh-autosuggestions zsh-syntax-highlighting zsh-completions
)

source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8
export EDITOR='code --wait'
export VISUAL='code --wait'

# ===== Navegação =====
alias ls="ls --color=auto -lah"
alias ll="ls -lah"
alias ..="cd .."
alias ...="cd ../.."

# ===== Docker =====
alias d="docker"
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcb="docker compose up -d --build"
alias dcps="docker compose ps"
alias dcl="docker compose logs -f"
alias dcr="docker compose restart"

# ===== Git =====
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --oneline -20"
alias gd="git diff"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gb="git branch -a"

# ===== Laravel (em /api) =====
alias pa="php artisan"
alias pam="php artisan migrate"
alias pamf="php artisan migrate:fresh --seed"
alias pas="php artisan serve"
alias pat="php artisan tinker"
alias par="php artisan route:list"
alias ptest="php artisan test"
alias ngrok:url="php artisan ngrok:url"

# ===== Expo / React Native (em /mobile) =====
alias ntunnel="npx expo start --tunnel"
alias nwlan="npx expo start --lan"
alias nlocal="npx expo start --localhost"
alias nclear="npx expo start --clear"
alias nweb="npx expo start --web"
alias nrd="npm run dev"
alias nrb="npm run build"

# ===== Utilitários =====
alias cl="clear"
alias c="code ."
alias reload="source ~/.zshrc"
alias reload-zsh="exec zsh"
alias ports="netstat -tulanp 2>/dev/null || ss -tulanp"
alias df="df -h"

# ===== ngrok:set-expo =====
__find_project_root() {
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

# ===== ngrok functions (CLI local, não container) =====

# Configurar authtoken do ngrok (uma vez só)
# Uso: ngrok:set-token 1acf828c4266...
ngrok:set-token() {
  if [ -z "$1" ]; then
    echo "Uso: ngrok:set-token SEU_AUTHTOKEN"
    echo "Pega em: https://dashboard.ngrok.com/get-started/your-authtoken"
    return 1
  fi
  ngrok config add-authtoken "$1"
  echo "✓ authtoken configurado"
  cat ~/.config/ngrok/ngrok.yml 2>/dev/null | head -3
}

# Iniciar ngrok na porta 8000 (Laravel) em background
# Uso: ngrok:start
ngrok:start() {
  if ! command -v ngrok >/dev/null 2>&1; then
    echo "✗ ngrok não instalado. Reconstrua o Codespace."
    return 1
  fi
  # Mata ngrok anterior se estiver rodando
  pkill -9 -f "ngrok" 2>/dev/null || true
  sleep 2
  # Inicia em background com pooling-enabled (evita conflito de domínio)
  nohup ngrok http 8000 --pooling-enabled > /tmp/ngrok.log 2>&1 &
  sleep 4
  # Verifica se subiu
  if curl -s http://localhost:4040/api/tunnels >/dev/null 2>&1; then
    echo "✓ ngrok iniciado em background (PID: $!)"
  else
    echo "✗ ngrok falhou ao iniciar. Ver: cat /tmp/ngrok.log"
  fi
}

# Ver URL pública do ngrok
# Uso: ngrok:api
ngrok:api() {
  if ! command -v ngrok >/dev/null 2>&1; then
    echo "✗ ngrok não instalado."
    return 1
  fi
  # API do ngrok local: http://localhost:4040/api/tunnels
  local url=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for t in data.get('tunnels', []):
        if t.get('config', {}).get('addr') == '8000' or '8000' in t.get('config', {}).get('addr', ''):
            print(t.get('public_url', ''))
            break
except: pass
" 2>/dev/null)
  if [ -z "$url" ]; then
    echo "✗ ngrok não está rodando. Inicie com: ngrok:start"
    return 1
  fi
  echo "URL pública do ngrok:"
  echo "  $url"
  echo "URL da API:"
  echo "  $url/api"
}

# Apontar mobile para API do ngrok
# Uso: ngrok:set-expo
ngrok:set-expo() {
  local project_root="$(__find_project_root)"
  local url=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for t in data.get('tunnels', []):
        if t.get('config', {}).get('addr') == '8000' or '8000' in t.get('config', {}).get('addr', ''):
            print(t.get('public_url', ''))
            break
except: pass
" 2>/dev/null)
  if [ -z "$url" ]; then
    echo "✗ ngrok não está rodando. Inicie com: ngrok:start"
    return 1
  fi
  local api_url="${url}/api"
  if [ -f "$project_root/mobile/.env" ]; then
    sed -i "s|EXPO_PUBLIC_API_URL=.*|EXPO_PUBLIC_API_URL=${api_url}|" "$project_root/mobile/.env"
    echo "✓ mobile/.env → $api_url"
  else
    echo "EXPO_PUBLIC_API_URL=${api_url}" > "$project_root/mobile/.env"
    echo "✓ mobile/.env criado"
  fi
  echo "  Reinicie Expo: cd $project_root/mobile && ntunnel"
}

# Parar ngrok
ngrok:stop() {
  pkill -f "ngrok http" 2>/dev/null && echo "✓ ngrok parado" || echo "ngrok não estava rodando"
}

# ===== Shell options =====
setopt AUTO_CD CORRECT EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY 2>/dev/null

HISTSIZE=100000
SAVEHIST=100000

# ===== Completion =====
autoload -Uz compinit 2>/dev/null && compinit 2>/dev/null

# ===== Powerlevel10k =====
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh 2>/dev/null

# ===== Banner =====
cat <<'MSG'

╔══════════════════════════════════════════════════════════╗
║  SISCOPN — IFPA 2026.2                                  ║
╚══════════════════════════════════════════════════════════╝

  /api     — Laravel 13
  /mobile  — Expo 54

Aliases:
  dcu            # sobe 5 containers
  pas            # php artisan serve
  ngrok:api      # URL pública
  ngrok:set-expo # atualiza mobile/.env
  ntunnel        # npx expo start --tunnel

Professor: Edinelson Junior (edinelson.sousa@ifpa.edu.br)
MSG
