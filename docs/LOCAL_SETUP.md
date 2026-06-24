# Setup Local

Este guia e o caminho simples para rodar o Neviim no WSL/local.

Arquitetura oficial:

- Flutter Web/PWA le os albuns no Firestore;
- backend FastAPI serve health check, admin, proxy de midia e indexador;
- Google Drive e apenas a origem das fotos;
- `index_drive.py` sincroniza Drive -> Firestore.

## Inicio rapido

Na raiz do projeto:

```bash
cd /mnt/c/Users/felip/Documents/projeto_2/app-neviim
chmod +x scripts/*.sh
./scripts/wsl_run_local.sh
```

O esperado:

- backend em `http://localhost:8000`;
- app em `http://localhost:3000`;
- logs em `/tmp/neviim_backend.log` e `/tmp/neviim_flutter.log`.

## Comandos locais oficiais

Subir:

```bash
./scripts/wsl_start.sh
```

Ver status:

```bash
./scripts/wsl_status.sh
```

Parar:

```bash
./scripts/wsl_stop.sh
```

Reiniciar tudo:

```bash
./scripts/wsl_run_local.sh
```

## Backend local

Configure `backend/.env` a partir de `backend/.env.example`.

Variaveis mais importantes:

- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `FIREBASE_PROJECT_ID`
- `DRIVE_FOLDER_ID`
- `ADMIN_UID_WHITELIST`
- `ALLOWED_ORIGINS`

O `wsl_start.sh` cria ou repara `backend/.venv-wsl` quando necessario e sobe:

```bash
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Validacao:

```bash
curl http://localhost:8000/health
```

## App Flutter Web local

O `wsl_start.sh` usa por padrao o Firebase do projeto `hidden-solstice-305914` e aponta o frontend para:

```text
http://localhost:8000
```

Abra:

```text
http://localhost:3000
```

Se precisar sobrescrever alguma configuracao:

```bash
export NEVIIM_FIREBASE_API_KEY="..."
export NEVIIM_FIREBASE_APP_ID="..."
export NEVIIM_FIREBASE_MESSAGING_SENDER_ID="..."
export NEVIIM_FIREBASE_PROJECT_ID="..."
export NEVIIM_FIREBASE_AUTH_DOMAIN="..."
export NEVIIM_FIREBASE_STORAGE_BUCKET="..."
export NEVIIM_BACKEND_BASE_URL="http://localhost:8000"
./scripts/wsl_start.sh
```

## Gerar build web local

Para testar build apontando para backend local:

```bash
./scripts/wsl_build_web.sh http://localhost:8000
```

Para gerar pacote para a EC2:

```bash
./scripts/wsl_package_web.sh http://insightflow.ddns.net
```

Com HTTPS:

```bash
./scripts/wsl_package_web.sh https://insightflow.ddns.net
```

O pacote sai em:

```text
dist/neviim-web.tar.gz
```

Deploy EC2: `docs/EC2_DEPLOY.md`.

## Fotos do Drive

Alterar fotos no Drive nao exige rebuild do Flutter.

Fluxo seguro local:

```bash
cd backend
./.venv-wsl/bin/python scripts/index_drive.py --folder-name Galeria --prune-missing-albums
```

Diagnostico:

```bash
cd backend
./.venv-wsl/bin/python scripts/inspect_drive.py --include-subfolders
```

Guia completo de adicionar, remover e substituir fotos: `docs/PHOTO_OPERATIONS.md`.

## Testes

Backend:

```bash
cd backend
./.venv-wsl/bin/pytest tests
```

Flutter:

```bash
cd app
flutter test
```

## Validacao manual recomendada

1. Rodar `./scripts/wsl_run_local.sh`.
2. Validar `curl http://localhost:8000/health`.
3. Abrir `http://localhost:3000`.
4. Confirmar splash, consentimento, home e galeria.
5. Abrir uma foto e testar download.
6. Se usar admin, validar login, listagem e soft delete.
7. Rodar `./scripts/wsl_status.sh`.

## Documentos de apoio

- API administrativa e de midia: `docs/API.md`
- Deploy EC2: `docs/EC2_DEPLOY.md`
- Operacao de fotos: `docs/PHOTO_OPERATIONS.md`
- Seguranca e governanca: `docs/GOVERNANCE.md`
- Capacidade e limite gratuito: `docs/CAPACITY_PLAN.md`
