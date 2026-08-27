# TUTORIAL COMPLETO — Ambiente SISCOPN no GitHub Codespaces

> **Versão validada em:** agosto de 2026
> **Stack:** Laravel 13 (PHP 8.4) + Expo 54 (TypeScript) + MySQL 8 + Redis 7 + ngrok CLI

---

## Visão geral

O Codespace é um ambiente de desenvolvimento Linux (Ubuntu 22.04) que roda na nuvem do GitHub. Cada aluno pode criar o seu próprio (não precisa de organização, convite, nem permissão).

Quando você abrir este Codespace, o `setup.sh` (rodado automaticamente na criação) vai:

1. Instalar pacotes do sistema + zsh
2. Instalar Oh My Zsh + 3 plugins + tema Powerlevel10k
3. Instalar Composer 2
4. Garantir extensões PHP (pdo_mysql)
5. **Criar projeto Laravel 13** em `/api` com drivers FILE (não precisa Redis)
6. **Criar projeto Expo 54** (blank-typescript) em `/mobile`
7. Instalar ngrok CLI
8. Criar HealthController + rota `/api/health`
9. Criar feature de teste de conexão no Expo
10. Configurar ngrok com seu token

---

## Estrutura de arquivos (8 arquivos)

```
codespace-blank/
├── .devcontainer/
│   ├── devcontainer.json        ← config do Codespace
│   └── setup.sh                 ← bootstrap automático (15 etapas)
├── .zshrc                       ← aliases do shell
├── .env.example                 ← template de variáveis (NGROK_AUTHTOKEN, etc)
├── docker-compose.yml           ← 4 containers auxiliares
├── ngrok.yml                    ← config do tunnel
├── Dockerfile                   ← imagem PHP 8.4 (referência)
├── README.md
└── TUTORIAL-DE-COPIAR.md        ← este arquivo
```

---

## PARTE 1 — Criar o Codespace

### Passo 1.1 — Acessar o template blank

1. Acesse https://github.com/codespaces
2. Clique em **"Blank template"** (ou use o botão "Use this template")
3. Escolha a máquina **4-core, 16 GB RAM**
4. Clique em **"Create codespace"**

### Passo 1.2 — Aguardar o build inicial

A primeira vez demora **5–10 minutos** (download de imagens, instalação de pacotes).

Durante o build, você verá no painel "Codespaces logs":

- "Building container"
- "Installing dependencies"
- "Running setup.sh"
- "[1/15] Pacotes do sistema + zsh..."
- ... (15 etapas)
- "=== Concluido ==="

Quando aparecer **"Container started"**, o Codespace está pronto.

---

## PARTE 2 — Copiar os arquivos de configuração

O Codespace abriu **vazio** (template blank). Você precisa copiar os arquivos do `codespace-blank/`.

### Passo 2.1 — Baixar os arquivos

Você pode receber os arquivos de 3 formas:

- **Email / WhatsApp / Google Drive** — peça ao professor
- **Download direto** — se o professor deixou no repositório
- **Copie do GitHub** — se o professor publicou em um repo público

### Passo 2.2 — Criar a estrutura no Codespace

No terminal do Codespace (que abriu automaticamente), rode:

```bash
# Criar pasta .devcontainer
mkdir -p .devcontainer
```

### Passo 2.3 — Copiar cada arquivo

**Método A — Painel Files do VS Code (recomendado):**

1. No painel **Files** (à esquerda), clique com botão direito → **"New File"**
2. Digite o caminho completo (ex: `.devcontainer/setup.sh`)
3. Cole o conteúdo do arquivo
4. Salve com `Ctrl+S`

**Método B — Terminal com heredoc:**

```bash
# Use Ctrl+Shift+V no terminal para colar blocos inteiros

mkdir -p .devcontainer

# Cole o conteúdo do devcontainer.json em .devcontainer/devcontainer.json
cat > .devcontainer/devcontainer.json << 'JSON_EOF'
{ ... conteúdo ... }
JSON_EOF

# Cole o conteúdo do setup.sh em .devcontainer/setup.sh
cat > .devcontainer/setup.sh << 'SH_EOF'
{ ... conteúdo ... }
SH_EOF

chmod +x .devcontainer/setup.sh

# Cole o .zshrc na raiz
cat > .zshrc << 'ZSH_EOF'
{ ... conteúdo ... }
ZSH_EOF

# Copie o .env.example
cp /caminho/para/codespace-blank/.env.example .env.example
cp .env.example .env

# Cole os outros arquivos da mesma forma
```

### Passo 2.4 — Arquivos a copiar (lista de checagem)

Marque conforme for colando:

- [ ] `.devcontainer/devcontainer.json`
- [ ] `.devcontainer/setup.sh` (depois fazer `chmod +x`)
- [ ] `.zshrc`
- [ ] `.env.example` → renomear para `.env`
- [ ] `docker-compose.yml`
- [ ] `ngrok.yml`
- [ ] `Dockerfile` (opcional, só se quiser customizar a imagem)
- [ ] `README.md` (opcional)
- [ ] `TUTORIAL-DE-COPIAR.md` (este arquivo, para referência)

---

## PARTE 3 — Configurar ngrok (uma vez)

### Passo 3.1 — Criar conta no ngrok

1. Acesse https://dashboard.ngrok.com/signup
2. Crie conta grátis (pode usar login do GitHub)
3. Após login, vá em https://dashboard.ngrok.com/get-started/your-authtoken
4. Copie o **Authtoken** (formato: `2xY_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)

### Passo 3.2 — Colar token no .env

No Codespace:

```bash
code .env
```

Cole na última linha:

```
NGROK_AUTHTOKEN=2xY_seu_token_aqui
```

Salve com `Ctrl+S`.

---

## PARTE 4 — Subir os serviços (todo dia)

Você vai precisar de **4 abas de terminal** abertas simultaneamente. Para abrir nova aba: `Ctrl+Shift+\`` (Ctrl+Shift+acento grave).

### Aba 1 — Containers auxiliares (MySQL, Redis, MailHog, phpMyAdmin)

```bash
# Subir os 4 containers
dcu

# Ver status
dcps
```

**Esperado (4 containers "Up"):**

```
NAME                 IMAGE                          STATUS
siscopn-db           mysql:8                        Up (healthy)
siscopn-redis        redis:7-alpine                 Up
siscopn-mailhog      mailhog/mailhog:latest         Up
siscopn-phpmyadmin   phpmyadmin/phpmyadmin:latest   Up
```

### Aba 2 — Laravel (deixar rodando)

```bash
cd /workspaces/codespaces-blank/api
pas
```

**Saída esperada:**

```
INFO  Server running on [http://0.0.0.0:8000].
Press Ctrl+C to stop the server
```

**Acessar Laravel:** aba **Ports** → 8000 → ícone 🌐

**Testar rota da API:**

Em outra aba ou no mesmo terminal:

```bash
curl http://localhost:8000/api/health
```

**Esperado:**

```json
{"status":"ok","service":"SISCOPN API","version":"1.0.0",...}
```

### Aba 3 — ngrok (deixar rodando em background)

```bash
# Iniciar ngrok
ngrok:start

# Ver URL pública
ngrok:api
```

**Saída esperada:**

```
URL pública do ngrok:
  https://xxxx.ngrok-free.app
URL da API:
  https://xxxx.ngrok-free.app/api
```

**Apontar mobile para a API:**

```bash
ngrok:set-expo
```

**Saída esperada:**

```
✓ mobile/.env → https://xxxx.ngrok-free.app/api
```

**Dashboard ngrok:** aba **Ports** → 4040 → ícone 🌐

### Aba 4 — Expo (deixar rodando)

```bash
cd /workspaces/codespaces-blank/mobile
ntunnel
```

Vai aparecer QR code. Para abrir no navegador: pressione `w`.

---

## PARTE 5 — Testar a conexão (feature Health Check)

### Opção A — No navegador (mais fácil)

1. Na aba 4 (Expo), pressione `w`
2. Vai abrir `http://localhost:8081` no navegador
3. Vai aparecer a tela **"🔌 Teste de Conexão"**
4. Automaticamente testa a conexão (também tem botão **"Testar Conexão"**)
5. Se aparecer **"Conexão ativa"** com latência: **funcionou!** ✅

### Opção B — No celular (Expo Go)

1. Instale **Expo Go** no celular:
   - Android: https://play.google.com/store/apps/details?id=host.exp.exponent
   - iOS: https://apps.apple.com/app/expo-go/id982107779
2. Abra o Expo Go
3. Toque em **"Scan QR code"** e aponte para o QR code que aparece no terminal
4. O app SISCOPN vai abrir no celular
5. Toque em **"Testar Conexão"**
6. Se aparecer **"Conexão ativa"** com latência: **funcionou!** ✅

### Opção C — Direto na API (sem app)

```bash
curl https://SEU-DOMINIO.ngrok-free.app/api/health
```

**Esperado:**

```json
{
  "status": "ok",
  "service": "SISCOPN API",
  "version": "1.0.0",
  "timestamp": "2026-08-02T...",
  "latency_ms": 12.34,
  "database": { "status": "ok" },
  "server": { "php": "8.4.23", "laravel": "13.x.x", "environment": "local" }
}
```

---

## PARTE 6 — Comandos úteis (resumo)

### Containers (Aba 1)

| Comando     | Ação                     |
| ----------- | ------------------------ |
| `dcu`       | Sobe os 4 containers     |
| `dcd`       | Para todos os containers |
| `dcps`      | Status dos containers    |
| `dcl`       | Logs em tempo real       |
| `dcl ngrok` | Logs só do ngrok         |

### Laravel (Aba 2)

| Comando               | Ação                         |
| --------------------- | ---------------------------- |
| `pas`                 | Inicia servidor (porta 8000) |
| `pam`                 | Roda migrations              |
| `pat`                 | REPL interativo              |
| `par`                 | Lista rotas                  |
| `pa migrate:rollback` | Reverte última migration     |
| `pa route:clear`      | Limpa cache de rotas         |

### ngrok (Aba 3)

| Comando          | Ação                       |
| ---------------- | -------------------------- |
| `ngrok:start`    | Inicia ngrok em background |
| `ngrok:api`      | Mostra URL pública         |
| `ngrok:set-expo` | Atualiza mobile/.env       |
| `ngrok:stop`     | Para o ngrok               |

### Expo (Aba 4)

| Comando   | Ação                        |
| --------- | --------------------------- |
| `ntunnel` | Expo com tunnel (celular)   |
| `nwlan`   | Expo via Wi-Fi (mesma rede) |
| `nweb`    | Expo no navegador           |

### Git / Zsh

| Comando    | Ação               |
| ---------- | ------------------ |
| `gs`       | git status         |
| `ga`       | git add            |
| `gc`       | git commit -m      |
| `gp`       | git push           |
| `ll`       | ls -lah            |
| `cl`       | clear              |
| `c`        | code .             |
| `exec zsh` | Recarregar aliases |

---

## PARTE 7 — Solução de problemas

### Problema 1 — `zsh: command not found: docker`

**Causa:** O build do Codespace ainda não terminou OU a feature docker-in-docker não foi instalada.

**Solução:**

```bash
# Verificar se Docker está instalado
docker --version
# Se retornar "command not found", rebuild:
# Ctrl+Shift+P → "Codespaces: Rebuild Container"
```

### Problema 2 — `dcu: command not found`

**Causa:** Os aliases do `.zshrc` não foram carregados.

**Solução:**

```bash
# Recarregar aliases
source ~/.zshrc.ifpa 2>/dev/null
exec zsh

# Testar
type dcu
# Deve mostrar: dcu is an alias for docker compose up -d
```

### Problema 3 — `ngrok:start` falha (exit 1)

**Causa:** Token do ngrok não configurado OU URL já em uso.

**Solução:**

```bash
# Verificar token
ngrok config check

# Se não tiver, adicionar
ngrok config add-authtoken SEU_TOKEN

# Matar processos antigos
pkill -9 -f ngrok

# Tentar de novo
ngrok:start
```

### Problema 4 — Laravel retorna "Class Redis not found"

**Causa:** A imagem PHP do Codespace não tem a extensão `php-redis`.

**Solução:** o `setup.sh` configura o Laravel com drivers FILE (não Redis). Se isso acontecer:

```bash
# Verificar .env do Laravel
grep -E "CACHE_STORE|SESSION_DRIVER|QUEUE_CONNECTION" /workspaces/codespaces-blank/api/.env

# Se algum driver for "redis", mudar para "file":
cd /workspaces/codespaces-blank/api
sed -i 's|^CACHE_STORE=.*|CACHE_STORE=file|' .env
sed -i 's|^SESSION_DRIVER=.*|SESSION_DRIVER=file|' .env
sed -i 's|^QUEUE_CONNECTION=.*|QUEUE_CONNECTION=sync|' .env

php artisan config:clear
php artisan cache:clear
```

### Problema 5 — Expo não consegue se conectar à API

**Causa:** A URL no `mobile/.env` está errada OU o ngrok não está rodando.

**Solução:**

```bash
# Verificar URL no mobile
cat /workspaces/codespaces-blank/mobile/.env

# Verificar se ngrok está rodando
curl -s http://localhost:4040/api/tunnels | python3 -m json.tool 2>/dev/null | head -10

# Se ngrok não estiver rodando:
ngrok:start
ngrok:set-expo
```

### Problema 6 — `cd api && pas` retorna erro "Address already in use"

**Causa:** Outra instância do Laravel está rodando.

**Solução:**

```bash
# Matar processos do php artisan
pkill -f "artisan serve"

# Tentar de novo
cd /workspaces/codespaces-blank/api
pas
```

### Problema 7 — Container ngrok em loop de restart

**Causa:** O ngrok do docker-compose foi removido nesta versão — agora usamos o ngrok CLI local.

**Solução:** Não há container ngrok. Use `ngrok:start` na aba 3.

---

## PARTE 8 — Rebuild do Codespace

Se algo der muito errado e quiser recomeçar do zero:

1. **Ctrl+Shift+P** → **"Codespaces: Rebuild Container"**
2. Aguarde 5–10 minutos
3. Quando o terminal abrir, rode `cd /workspaces/codespaces-blank && ls`
4. Os arquivos devem estar lá
5. Rode `dcu` e siga a Parte 4

---

## PARTE 9 — Estrutura final esperada

Depois de subir tudo, você deve ter:

```
/workspaces/codespaces-blank/
├── .devcontainer/           (devcontainer.json, setup.sh)
├── api/                     (Laravel 13)
│   ├── app/Http/Controllers/HealthController.php
│   ├── bootstrap/app.php     (com api: ...routes/api.php)
│   ├── routes/api.php       (com /health)
│   ├── .env                 (com DB_*, NGROK_*, etc)
│   └── vendor/
├── mobile/                  (Expo 54)
│   ├── App.tsx              (com SafeAreaProvider)
│   ├── lib/api.ts           (com checkHealth)
│   ├── components/HealthCheck.tsx
│   ├── .env                 (com EXPO_PUBLIC_API_URL)
│   └── node_modules/
└── .env                     (com NGROK_AUTHTOKEN)
```

---

## PARTE 10 — Contato

Se algo não funcionar após seguir este tutorial:

- **Email:** edinelson.sousa@ifpa.edu.br
- **Instagram:** @\_edi_jr

---

> **Última atualização:** agosto de 2026
> **Versão do setup.sh:** validada com build completo
