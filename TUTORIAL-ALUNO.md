# Tutorial Rapido - Ambiente SISCOPN no GitHub Codespaces

> Tempo: 15-20 min na primeira vez. 30 s nas proximas.

## PASSO 1 - Baixar os arquivos

Receba do professor o arquivo `codespace-blank.zip` (por e-mail, WhatsApp ou Google Drive).

Salve em qualquer pasta do seu computador.

## PASSO 2 - Criar o Codespace (vazio)

1. Abra no navegador: https://github.com/codespaces
2. Clique em **"Blank template"**
3. Escolha a maquina **"4-core, 16 GB RAM"**
4. Clique em **"Create codespace"**
5. Aguarde **5-10 minutos** (so na primeira vez)

## PASSO 3 - Colar os arquivos no Codespace

### Jeito A - Painel Files (recomendado)

1. No painel **Files** (icone de pasta a esquerda), clique com botao direito
2. Selecione **"Upload..."** e escolha os arquivos

**IMPORTANTE:** mantenha a estrutura de pastas! O arquivo `.devcontainer/devcontainer.json` precisa estar em `.devcontainer/`, nao na raiz.

### Jeito B - Terminal com unzip

Faca upload do zip pelo painel Files, depois:

```bash
unzip ~/codespace-blank.zip -d /tmp/
cp -r /tmp/codespace-blank/* /workspaces/codespaces-blank/
ls /workspaces/codespaces-blank/
```

## PASSO 4 - Configurar o ngrok (uma vez)

1. Abra: https://dashboard.ngrok.com/signup
2. Crie conta gratis
3. Copie seu authtoken em: https://dashboard.ngrok.com/get-started/your-authtoken

No Codespace:

```bash
cp /workspaces/codespaces-blank/.env.example /workspaces/codespaces-blank/.env
code /workspaces/codespaces-blank/.env
```

Cole na ultima linha:

```
NGROK_AUTHTOKEN=2xY_seu_token_aqui
```

Salve com `Ctrl+S`.

## PASSO 5 - Subir os servicos (4 abas)

Para abrir **nova aba de terminal**: `Ctrl+Shift+` (Ctrl+Shift+acento grave).

### Aba 1 - Containers

```bash
cd /workspaces/codespaces-blank
dcu
dcps
```

**Esperado:** 4 containers "Up" (db, redis, mailhog, phpmyadmin).

### Aba 2 - Laravel

```bash
cd /workspaces/codespaces-blank/api
pas
```

**Esperado:** `INFO Server running on [http://0.0.0.0:8000]`. **Deixe essa aba aberta.**

### Aba 3 - ngrok

```bash
ngrok:start
ngrok:api
ngrok:set-expo
```

**Esperado:** mostra URL publica (ex.: `https://xxxx.ngrok-free.app`).

### Aba 4 - Expo (mobile)

```bash
cd /workspaces/codespaces-blank/mobile
ntunnel
```

Vai aparecer um **QR code**. Pressione `w` para abrir no navegador.

## PASSO 6 - Testar

Na aba 4 (Expo), pressione `w` para abrir no navegador. Voce deve ver:

**Conexao ativa** com latencia (ex.: `250ms`)

Se aparecer **Conexao falhou**: verifique se os 4 containers estao rodando (`dcps`).

## Comandos rapidos

| Comando | O que faz |
|---------|-----------|
| `dcu` | Sobe os 4 containers |
| `dcd` | Para os containers |
| `dcps` | Lista status dos containers |
| `pas` | Sobe o Laravel (porta 8000) |
| `pam` | Roda migrations |
| `ngrok:start` | Inicia ngrok em background |
| `ngrok:api` | Mostra URL publica do ngrok |
| `ngrok:set-expo` | Atualiza `mobile/.env` com URL |
| `ntunnel` | Sobe o Expo com tunnel (celular) |
| `exec zsh` | Recarregar aliases |

## Problemas comuns

**"zsh: command not found: docker"** -> Aguarde o Codespace terminar o build. Se persistir: `Ctrl+Shift+P` -> "Rebuild Container".

**"zsh: command not found: dcu"** -> Os aliases nao carregaram. Rode: `exec zsh` e tente de novo.

**"ngrok nao esta rodando"** -> Rode `ngrok:start` antes. Se der erro de token, confira o `.env`.

**App mostra "Conexao falhou"** -> Verifique se `dcu`, `pas` e `ngrok:start` estao rodando.

## Para parar tudo

```bash
# Aba 2 (Laravel): Ctrl+C
# Aba 4 (Expo): Ctrl+C
# Aba 1: dcd
# Aba 3: ngrok:stop
```

## Proximo passo

Quando o ambiente estiver funcionando (Conexao ativa), voce esta pronto para a **Aula 02**.

---

**Duvidas?** Edinelson Junior - edinelson.sousa@ifpa.edu.br - @_edi_jr
