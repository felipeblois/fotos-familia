# API Neviim

Documentacao operacional das rotas usadas pelo app e pelo painel administrativo.

## Base local

- Backend local: `http://localhost:8000`
- Prefixo principal: `/api/v1`

## Health check

### `GET /health`

Uso:

- validar se o backend subiu
- verificar rapidamente o ambiente local

Resposta esperada:

```json
{
  "status": "ok"
}
```

## Midia

### `GET /api/v1/media/albums/{album_id}/photos/{photo_id}`

Uso:

- o app Flutter usa essa rota para abrir uma imagem no visualizador
- o download do fiel tambem passa por essa rota

Comportamento:

- busca os metadados da foto no Firestore
- resolve o arquivo do Google Drive
- devolve a imagem ao navegador sem expor o Drive diretamente no app web

Observacoes:

- `HEAD` retorna `405 Method Not Allowed`; o endpoint aceita `GET`
- se o arquivo nao existir ou estiver oculto, a API responde erro apropriado

Exemplo:

```bash
curl "http://localhost:8000/api/v1/media/albums/28-01-2026/photos/1DlDBY5ItLgbEvKAKtc7ByVW2pNStjnGR" -o /tmp/test-photo.jpg
```

## Admin

Todas as rotas abaixo exigem usuario autenticado no Firebase Auth e autorizado pelo backend.

Cabecalho esperado:

```text
Authorization: Bearer <firebase-id-token>
```

### `GET /api/v1/admin/albums`

Uso:

- carregar a lista de albuns no painel administrativo

Resposta:

```json
{
  "success": true,
  "message": "Albuns carregados com sucesso.",
  "data": {
    "albums": [
      {
        "id": "28-01-2026",
        "title": "28-01-2026",
        "photo_count": 228,
        "cover_url": "",
        "created_at": "2026-01-28T00:00:00+00:00",
        "last_indexed_at": "2026-04-16T20:00:00+00:00",
        "is_deleted": false
      }
    ]
  }
}
```

### `GET /api/v1/admin/albums/{album_id}/photos`

Uso:

- listar fotos moderaveis de um album

Campos relevantes:

- `id`
- `name`
- `created_at`
- `download_url`
- `view_url`
- `thumbnail_url`
- `mime_type`
- `indexed_at`

### `DELETE /api/v1/admin/albums/{album_id}/photos/{photo_id}`

Uso:

- soft delete de uma foto

Comportamento:

- marca `is_deleted = true` no documento da foto
- decrementa `photo_count` do album
- grava evento em `audit_log`

Resposta de sucesso:

```json
{
  "success": true,
  "message": "Foto ocultada com sucesso.",
  "data": {
    "photo_id": "foto-1",
    "album_id": "28-01-2026",
    "deleted": true
  }
}
```

### `GET /api/v1/admin/audit-logs`

Uso:

- alimentar a secao de auditoria recente do painel admin
- conferir quem ocultou qual foto

Retorno:

- lista dos ultimos eventos gravados em `audit_log`

## Firestore usado pelo app

Colecoes em uso:

- `albums/{albumId}`
- `albums/{albumId}/photos/{photoId}`
- `audit_log/{logId}` para trilha administrativa
- `consents/{consentId}` somente se `NEVIIM_ENABLE_REMOTE_CONSENT=true`

## Regras de seguranca relacionadas

- o app publico so le documentos nao removidos
- o cliente nao grava albuns nem fotos
- toda acao administrativa sensivel passa pelo backend

Antes de publicar, sincronizar tambem:

- `firestore.rules`
- whitelist de admins no backend
- variaveis Firebase do app
