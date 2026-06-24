# Capacity Plan

Base atual validada:

- Album `04-02-2026`: 349 fotos
- Album `28-01-2026`: 228 fotos
- Total atual publicado: 577 fotos

## Limites gratuitos mais sensiveis

Firestore:

- 50.000 leituras de documento por dia
- 20.000 gravacoes por dia
- 20.000 exclusoes por dia
- 1 GiB armazenado

## Estimativa operacional atual

- Documentos principais: 2 albuns + 577 fotos
- Reindexacao completa desses 2 albuns: ~579 writes
- Abertura completa dos 2 albuns sem paginacao: ~579 leituras
- Carga inicial atual com paginacao de 48 por album: ~98 leituras para abrir ambos

## Regra simples para nao estourar leitura

Conta pratica:

- 1 abertura de album ~= quantidade de fotos carregadas naquela pagina
- com pagina inicial de 48 itens, 100 aberturas de album no dia ~= 4.800 leituras
- com 500 aberturas de album no dia ~= 24.000 leituras

Interpretacao:

- com o acervo atual, o plano gratuito ainda suporta uso inicial controlado
- se o numero de fieis ativos crescer, o primeiro gargalo tende a ser leitura diaria do Firestore

## Decisao aplicada na Sprint 6

- A galeria passa a carregar fotos em paginas de 48 itens por album.
- Isso reduz leitura inicial e melhora previsibilidade para ampliar catalogo.

## Regra pratica para ampliar acervo

1. Publicar novos albuns em lotes pequenos.
2. Acompanhar leituras no console do Firestore.
3. Manter albuns antigos arquivados ou menos destacados se o volume crescer.
4. Evitar reindexacoes totais desnecessarias.

## Checklist antes de liberar mais fotos

- Validar se o album foi indexado com `photo_count` correto.
- Confirmar se thumbnails e proxy de midia estao abrindo.
- Confirmar se o album nao excede leitura inicial aceitavel.
- Confirmar se fotos removidas continuam ocultas.
