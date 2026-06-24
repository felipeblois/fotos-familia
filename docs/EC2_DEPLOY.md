# Deploy na EC2

Este e o fluxo oficial para publicar o Neviim na EC2 pequena.

Regra principal: a EC2 nao compila Flutter. O build web e gerado no WSL/local, enviado como `.tar.gz` e publicado pelo nginx. A EC2 fica responsavel apenas por:

- backend FastAPI em `127.0.0.1:8000`;
- nginx publico na porta `80` e, opcionalmente, `443`;
- frontend estatico em `/var/www/neviim`;
- `systemd` mantendo o servico `neviim-api`.

## Arquitetura

```text
Navegador -> nginx -> /var/www/neviim
Navegador -> nginx -> 127.0.0.1:8000/api
Google Drive -> index_drive.py -> Firestore -> app Flutter
```

## Pre-requisitos

Na EC2:

- Ubuntu com acesso SSH;
- portas `80` e, se usar HTTPS, `443` liberadas no Security Group;
- repositorio clonado em `/home/ubuntu/apps/app-neviim`;
- service account fora do Git, por exemplo em `/home/ubuntu/service-account.json`;
- DNS `insightflow.ddns.net` apontando para o IP publico atual da EC2.

No WSL/local:

- Flutter instalado em `/opt/flutter`;
- acesso SSH/SCP para a EC2.

## Build e pacote no WSL/local

Para HTTP:

```bash
cd /mnt/c/Users/felip/Documents/projeto_2/app-neviim
chmod +x scripts/*.sh
scripts/wsl_package_web.sh http://insightflow.ddns.net
```

Para HTTPS:

```bash
cd /mnt/c/Users/felip/Documents/projeto_2/app-neviim
chmod +x scripts/*.sh
scripts/wsl_package_web.sh https://insightflow.ddns.net
```

O pacote sera gerado em:

```text
dist/neviim-web.tar.gz
```

Envie para a EC2:

```bash
scp dist/neviim-web.tar.gz ubuntu@insightflow.ddns.net:/home/ubuntu/neviim-web.tar.gz
```

Se o DNS ainda nao estiver apontando para a EC2 atual, use o IP publico no `scp`:

```bash
scp dist/neviim-web.tar.gz ubuntu@IP_PUBLICO_DA_EC2:/home/ubuntu/neviim-web.tar.gz
```

## Instalacao ou atualizacao completa na EC2

Entre na EC2:

```bash
ssh ubuntu@insightflow.ddns.net
```

Rode:

```bash
cd /home/ubuntu/apps/app-neviim
git pull
chmod +x scripts/*.sh
scripts/ec2_start_dns_light.sh insightflow.ddns.net /home/ubuntu/service-account.json SEU_ADMIN_UID /home/ubuntu/apps/app-neviim http /home/ubuntu/neviim-web.tar.gz
```

Se ainda nao tiver o UID real do admin Firebase, use o placeholder e ajuste depois em `backend/.env`:

```bash
scripts/ec2_start_dns_light.sh insightflow.ddns.net /home/ubuntu/service-account.json
```

O script oficial executa:

- interrompe servicos antigos do `agente-feedback-conversacional`, se existirem;
- instala dependencias base da EC2;
- gera `backend/.env` e `app/.env.ec2`;
- copia a service account para `secrets/service-account.json`;
- instala dependencias Python do backend;
- publica o frontend em `/var/www/neviim`;
- configura nginx;
- instala/reinicia `neviim-api` no systemd;
- mostra status final.

## Publicar somente um novo frontend

Use quando mudou tela, texto, asset ou configuracao embutida no Flutter.

No WSL/local:

```bash
cd /mnt/c/Users/felip/Documents/projeto_2/app-neviim
scripts/wsl_package_web.sh http://insightflow.ddns.net
scp dist/neviim-web.tar.gz ubuntu@insightflow.ddns.net:/home/ubuntu/neviim-web.tar.gz
```

Na EC2:

```bash
cd /home/ubuntu/apps/app-neviim
scripts/ec2_publish_frontend.sh /home/ubuntu/neviim-web.tar.gz /var/www/neviim
```

## Deploy via GitHub Actions

O workflow manual fica em:

```text
.github/workflows/deploy-web-ec2.yml
```

Configure estes secrets no GitHub em `Settings > Secrets and variables > Actions`:

- `EC2_HOST`: IP publico atual da EC2, exemplo `107.20.35.155`
- `EC2_USER`: usuario SSH, exemplo `ubuntu`
- `EC2_SSH_KEY`: conteudo completo da chave privada PEM usada no SSH

O workflow faz:

- checkout da branch selecionada no `Run workflow`;
- instala Flutter `3.22.3`;
- roda teste da galeria e `flutter analyze`;
- gera `dist/neviim-web.tar.gz`;
- envia o pacote para `/home/ubuntu/neviim-web.tar.gz`;
- atualiza a EC2 para a mesma branch selecionada;
- executa `scripts/ec2_publish_frontend.sh`;
- atualiza a configuracao do nginx com gzip/cache;
- recarrega o nginx;
- valida `/health`.

Para executar:

1. Abra o repositorio no GitHub.
2. Va em `Actions`.
3. Selecione `Deploy Web EC2`.
4. Clique em `Run workflow`.
5. Escolha a branch que deseja publicar.
6. Informe `backend_base_url`, por exemplo:

```text
http://107.20.35.155
```

Regra atual: qualquer branch pode fazer build e deploy. A branch escolhida no GitHub Actions sera a mesma branch usada para gerar o pacote e atualizar o repositorio na EC2.

Observacao: o Security Group da EC2 precisa permitir SSH a partir do runner do GitHub Actions. Como os IPs do GitHub podem mudar, a opcao mais simples e deixar a porta `22` acessivel temporariamente durante o deploy, ou futuramente configurar um runner auto-hospedado na propria EC2.

## Atualizar somente backend

Use quando mudou codigo Python, indexador, rotas ou configuracao de API.

```bash
cd /home/ubuntu/apps/app-neviim
git pull
cd backend
source .venv/bin/activate
pip install -r requirements.txt
cd ..
scripts/ec2_restart.sh
```

## Operacao

Status:

```bash
cd /home/ubuntu/apps/app-neviim
scripts/ec2_status.sh
```

Logs:

```bash
cd /home/ubuntu/apps/app-neviim
scripts/ec2_logs.sh
scripts/ec2_logs.sh api
scripts/ec2_logs.sh nginx
```

Restart:

```bash
cd /home/ubuntu/apps/app-neviim
scripts/ec2_restart.sh
```

Stop:

```bash
cd /home/ubuntu/apps/app-neviim
scripts/ec2_stop.sh
```

Validacao local na EC2:

```bash
curl -I http://localhost/
curl http://localhost/health
```

## HTTPS

O primeiro deploy pode ser HTTP. Para ativar HTTPS:

```bash
cd /home/ubuntu/apps/app-neviim
scripts/ec2_install_https.sh insightflow.ddns.net seu-email@dominio.com
```

Depois gere outro pacote local com URL HTTPS embutida e publique novamente:

```bash
scripts/wsl_package_web.sh https://insightflow.ddns.net
scp dist/neviim-web.tar.gz ubuntu@insightflow.ddns.net:/home/ubuntu/neviim-web.tar.gz
```

Na EC2:

```bash
cd /home/ubuntu/apps/app-neviim
scripts/ec2_publish_frontend.sh /home/ubuntu/neviim-web.tar.gz /var/www/neviim
```

Valide:

```bash
curl https://insightflow.ddns.net/health
```

## Fotos do Drive

Alterar fotos no Drive nao exige rebuild nem SCP.

Comando seguro na EC2:

```bash
cd /home/ubuntu/apps/app-neviim/backend
source .venv/bin/activate
python scripts/index_drive.py --folder-name Galeria --prune-missing-albums
```

Diagnostico:

```bash
python scripts/inspect_drive.py --include-subfolders
```

Guia completo: `docs/PHOTO_OPERATIONS.md`.

Tambem e possivel sincronizar pelo GitHub Actions:

```text
Actions > Sync Drive Gallery > Run workflow
folder_name = Galeria
```

## Performance e cache

O frontend carrega a galeria em lotes de 20 fotos. O botao "Carregar mais" busca apenas o proximo lote e mantem as fotos ja carregadas na tela.

As miniaturas passam pelo backend e ficam em cache local na EC2. O caminho recomendado fica em:

```text
/home/ubuntu/apps/app-neviim/data/media-cache
```

Esse caminho e configurado por `NEVIIM_MEDIA_CACHE_DIR` em `backend/.env`. Se precisar limpar miniaturas antigas, remova apenas essa pasta e reinicie a API:

```bash
rm -rf /home/ubuntu/apps/app-neviim/data/media-cache/thumbnails
scripts/ec2_restart.sh
```

O nginx tambem aplica gzip e cache control para assets estaticos. O deploy via GitHub Actions atualiza essa configuracao automaticamente.

## Validacao final

1. Abrir `http://insightflow.ddns.net/` ou `https://insightflow.ddns.net/`.
2. Confirmar splash, consentimento, home e galeria.
3. Abrir uma foto e testar download.
4. Validar `curl /health`.
5. Validar painel admin, se o UID do admin ja estiver configurado.

## Scripts oficiais de uso direto

Estes sao os scripts que o time deve chamar manualmente no dia a dia. Os demais scripts da pasta `scripts/` sao helpers internos usados por esses comandos.

- `scripts/wsl_run_local.sh`
- `scripts/wsl_start.sh`
- `scripts/wsl_status.sh`
- `scripts/wsl_stop.sh`
- `scripts/wsl_build_web.sh`
- `scripts/wsl_package_web.sh`
- `scripts/ec2_start_dns_light.sh`
- `scripts/ec2_publish_frontend.sh`
- `scripts/ec2_status.sh`
- `scripts/ec2_logs.sh`
- `scripts/ec2_restart.sh`
- `scripts/ec2_stop.sh`
- `scripts/ec2_install_https.sh`
