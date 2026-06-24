# Operacao de Fotos

Este guia documenta o fluxo de manutencao das fotos do Neviim.

## Como o app carrega fotos

O app nao le o Google Drive diretamente.

Fluxo oficial:

```text
Google Drive -> index_drive.py -> Firestore -> app Flutter
```

Isso significa que:

- alterar fotos no Drive nao atualiza o app sozinho;
- depois de adicionar, remover ou substituir fotos, rode o indexador;
- nao precisa rebuildar o frontend para atualizar fotos;
- rebuild/SCP so e necessario quando mudar codigo, layout ou configuracao do app.

## Estrutura recomendada no Drive

Use uma pasta chamada `Galeria` para as fotos publicas do app.

Modelo recomendado:

```text
Pasta pai compartilhada com a service account/
Galeria/
  foto-01.jpg
  foto-02.jpg
  foto-03.webp
```

Evite no fluxo normal:

```text
Galeria/28-01-2026/
Galeria/04-02-2026/
```

Subpastas so devem ser usadas se a intencao for transformar cada subpasta em album separado no app.

## Formatos aceitos

Formatos que entram no app:

- `image/jpeg` (`.jpg`, `.jpeg`)
- `image/png` (`.png`)
- `image/webp` (`.webp`)

Formatos que nao entram no app:

- `.CR2`
- outros arquivos RAW de camera
- videos
- PDFs
- arquivos maiores que o limite configurado

O limite padrao atual e `50 MB` por foto.

Se o Drive tiver 20 arquivos, mas o app mostrar 6, confira o resumo do indexador. Exemplo real:

```text
Processadas=20
Inseridas=6
Ignoradas=14
Motivo: mime=image/x-canon-cr2
```

Nesse caso, o app esta correto: as 14 fotos ignoradas eram RAW Canon `.CR2`. Converta para `.JPG` ou `.WEBP`, suba as versoes convertidas para `Galeria` e rode a indexacao de novo.

## Comando seguro para sincronizar fotos na EC2

Use este comando no dia a dia:

```bash
cd /home/ubuntu/apps/app-neviim/backend
source .venv/bin/activate
python scripts/index_drive.py --folder-name Galeria --prune-missing-albums
```

Esse comando:

- encontra a subpasta `Galeria`;
- indexa somente essa pasta;
- grava/atualiza as fotos no Firestore;
- marca como removidas as fotos que foram deletadas do Drive;
- marca como removidos albuns antigos que nao fazem parte da indexacao atual.

Resultado esperado quando tudo esta certo:

```text
Processadas=20 Inseridas=20 Ignoradas=0
```

## Sincronizar fotos pelo GitHub Actions

Tambem existe um workflow manual para rodar a indexacao sem acessar a EC2 via SSH local:

```text
.github/workflows/sync-drive-gallery.yml
```

Configure os mesmos secrets usados no deploy web:

- `EC2_HOST`
- `EC2_USER`
- `EC2_SSH_KEY`

Para executar:

1. Abra o repositorio no GitHub.
2. Va em `Actions`.
3. Selecione `Sync Drive Gallery`.
4. Clique em `Run workflow`.
5. Informe `folder_name` como `Galeria`.

O workflow executa na EC2:

```bash
cd /home/ubuntu/apps/app-neviim/backend
source .venv/bin/activate
python scripts/inspect_drive.py --include-subfolders
python scripts/index_drive.py --folder-name Galeria --prune-missing-albums
```

Nao e necessario rebuildar nem publicar frontend quando a mudanca for apenas adicionar, remover ou substituir fotos no Drive.

## Comando de diagnostico

Antes de indexar, ou quando algo parecer estranho, rode:

```bash
cd /home/ubuntu/apps/app-neviim/backend
source .venv/bin/activate
python scripts/inspect_drive.py --include-subfolders
```

Esse comando nao altera Firestore. Ele apenas mostra:

- quais subpastas a service account enxerga;
- quantos arquivos existem em cada pasta;
- quais arquivos entram no app;
- quais arquivos seriam ignorados e por qual motivo.

Se o diagnostico mostrar menos fotos do que voce ve no Google Drive, revise:

- se as fotos estao dentro da pasta correta;
- se a pasta `Galeria` esta compartilhada com a service account;
- se os arquivos foram enviados como `.jpg`, `.png` ou `.webp`;
- se os arquivos nao estao em uma subpasta diferente;
- se os arquivos nao sao RAW `.CR2`.

## Adicionar novas fotos

1. Converta RAWs para `.JPG` ou `.WEBP`, se necessario.
2. Suba as fotos finais para a pasta `Galeria`.
3. Rode:

```bash
cd /home/ubuntu/apps/app-neviim/backend
source .venv/bin/activate
python scripts/index_drive.py --folder-name Galeria --prune-missing-albums
```

4. Abra o app e atualize a galeria.

Se as fotos nao aparecerem, rode o diagnostico:

```bash
python scripts/inspect_drive.py --include-subfolders
```

## Remover fotos

1. Delete as fotos da pasta `Galeria` no Google Drive ou mova para uma pasta fora da Galeria.
2. Rode:

```bash
cd /home/ubuntu/apps/app-neviim/backend
source .venv/bin/activate
python scripts/index_drive.py --folder-name Galeria --prune-missing-albums
```

3. O Firestore sera atualizado com `is_deleted=true` para as fotos removidas.

Nao precisa rebuildar frontend.

## Substituir fotos

Fluxo recomendado:

1. Delete ou mova a foto antiga para fora de `Galeria`.
2. Suba a foto nova em `.JPG` ou `.WEBP`.
3. Rode:

```bash
cd /home/ubuntu/apps/app-neviim/backend
source .venv/bin/activate
python scripts/index_drive.py --folder-name Galeria --prune-missing-albums
```

Observacao:

- Se voce trocar o conteudo mantendo o mesmo arquivo no Drive, pode haver cache do navegador ou do Google Drive.
- O caminho mais previsivel e remover o arquivo antigo e subir um novo arquivo convertido.

## O que nao usar no fluxo normal

Evite este comando:

```bash
python scripts/index_drive.py --include-subfolders --prune-missing-albums
```

Ele indexa subpastas como albuns separados. Se as pastas antigas `28-01-2026` e `04-02-2026` ainda existirem no Drive, elas voltam para o Firestore.

Use `--include-subfolders` apenas quando voce realmente quiser publicar cada subpasta como album separado.

## Quando precisa rebuildar o frontend

Precisa rebuildar e fazer SCP quando mudar:

- telas do Flutter;
- imagens/assets do app;
- textos fixos;
- URL do backend embutida no build;
- configuracoes Firebase do build;
- `app/web/index.html`;
- qualquer codigo dentro de `app/lib`.

Nao precisa rebuildar quando mudar:

- fotos no Drive;
- documentos no Firestore;
- permissao ou conteudo da pasta `Galeria`;
- fotos deletadas ou adicionadas no Drive.

## Troubleshooting rapido

### O Drive tem 20 fotos, mas o app mostra 6

Rode:

```bash
python scripts/index_drive.py --folder-name Galeria --prune-missing-albums
```

Se aparecer:

```text
Processadas=20 Inseridas=6 Ignoradas=14
```

Leia os warnings. Se forem `.CR2`, converta os arquivos para `.JPG` ou `.WEBP`.

### Pastas antigas voltaram para o Firestore

Provavel causa:

```bash
python scripts/index_drive.py --include-subfolders --prune-missing-albums
```

Solucao:

```bash
python scripts/index_drive.py --folder-name Galeria --prune-missing-albums
```

Tambem remova ou mova subpastas antigas do Drive se nao forem mais usadas.

### O indexador mostra Processadas=0

Provaveis causas:

- `DRIVE_FOLDER_ID` aponta para a pasta errada;
- as fotos estao dentro de uma subpasta e o comando nao esta usando `--folder-name Galeria`;
- a service account nao tem permissao na pasta;
- a pasta esta vazia para a service account.

Diagnostico:

```bash
python scripts/inspect_drive.py --include-subfolders
```

### O app ainda mostra foto deletada

Rode a indexacao com prune:

```bash
python scripts/index_drive.py --folder-name Galeria --prune-missing-albums
```

Depois atualize o navegador com `Ctrl + F5` ou abra em aba anonima.

## Checklist de manutencao

Sempre que mexer nas fotos:

1. Garanta que as fotos finais estao em `.JPG`, `.PNG` ou `.WEBP`.
2. Coloque as fotos finais na pasta `Galeria`.
3. Rode `inspect_drive.py --include-subfolders` se quiser conferir.
4. Rode `index_drive.py --folder-name Galeria --prune-missing-albums`.
5. Confira se `Inseridas` bate com a quantidade esperada.
6. Abra a galeria no app.
