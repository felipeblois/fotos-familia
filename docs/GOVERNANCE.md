# Governanca e Seguranca

Guia pratico para operar o Neviim sem aumentar risco desnecessario.

## Responsabilidades

- Operacao do app: subir backend, app web e indexador local.
- Curadoria de conteudo: escolher quais albuns entram no app.
- Moderacao: ocultar fotos inadequadas pelo painel admin.
- Governanca: revisar acessos, regras e uso mensal dos recursos.

## Controles atuais

- Fotos publicas sao lidas pelo app direto no Firestore.
- Imagem completa e download passam pelo backend em vez de URL direta do Drive.
- Moderacao exige login Google e validacao de admin no backend.
- Exclusao operacional e soft delete, preservando auditoria.
- Consentimento remoto e push estao atras de flags.

## Segredos e credenciais

Nunca versionar:

- `backend/.env`
- `backend/credentials/service-account.json`
- chaves locais exportadas no shell

Boas praticas:

- usar uma service account dedicada ao projeto
- compartilhar no Drive apenas a pasta raiz necessaria
- limitar admins no `ADMIN_UID_WHITELIST`
- trocar credenciais se um notebook ou servidor for comprometido

## Checklist de seguranca antes de publicar

1. Publicar `firestore.rules` no projeto Firebase correto.
2. Publicar `firestore.indexes.json` alinhado ao modelo atual.
3. Confirmar que somente admins reais estao na whitelist.
4. Revisar `backend/.env` e remover valores de teste.
5. Ativar consentimento remoto apenas depois de validar o fluxo completo.
6. Confirmar que o proxy de midia responde somente para fotos indexadas e nao removidas.
7. Revisar CORS e origem do app implantado.

## Regras operacionais

- Novo album so entra no app depois de indexado e revisado.
- Foto removida no admin nao deve ser apagada manualmente do Firestore sem necessidade.
- Toda manutencao deve registrar data, responsavel e alteracao principal.

## Limites do plano gratuito

Resumo atual documentado em `docs/CAPACITY_PLAN.md`.

Pontos de atencao:

- leituras do Firestore aumentam com numero de usuarios e volume de galerias abertas
- gravacoes aumentam na indexacao e nas acoes administrativas
- o armazenamento cresce com metadados e logs

## Rotina semanal recomendada

1. Conferir novos albuns no Google Drive.
2. Rodar a indexacao local.
3. Validar os albuns no app.
4. Revisar auditoria recente.
5. Atualizar a contagem de fotos e o consumo estimado.

## Rotina mensal recomendada

1. Revisar admins autorizados.
2. Revisar service account e compartilhamentos do Drive.
3. Conferir se o volume de fotos continua dentro da faixa gratuita.
4. Revisar backlog de melhoria, bugs e riscos.
