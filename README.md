# SISCOPN — IFPA 2026.2

Meu Codespace da disciplina **Desenvolvimento de Software Integrado — IFPA 2026.2**.

## Estrutura

- `.devcontainer/` — config do Codespace (devcontainer.json + setup.sh)
- `Dockerfile` — imagem PHP 8.4 com php-redis
- `docker-compose.yml` — 5 serviços auxiliares
- `ngrok.yml` — config do tunnel
- `.zshrc` — aliases zsh
- `.env.example` — template de variáveis

## Como abrir

1. Crie Codespace pelo botão "Blank template" no GitHub.
2. Copie os 6 arquivos (veja `TUTORIAL-DE-COPIAR.md`).
3. Rode `bash .devcontainer/setup.sh`.
4. Rebuild do Codespace (`Ctrl+Shift+P`).
5. Rode `dcu` para subir containers.
6. Rode `cd api && pas` para subir Laravel.

## Ajuda

Edinelson Junior · edinelson.sousa@ifpa.edu.br · @_edi_jr
