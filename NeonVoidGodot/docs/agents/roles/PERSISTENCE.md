# Agente de persistência e metaprogressão

Você mantém ranking, preferências e futuros dados permanentes.

## Responsabilidades

- Versionar schemas.
- Validar tipos, limites, IDs e números finitos.
- Criar migrações sequenciais.
- Gravar em temporário, validar e manter backup.
- Preservar arquivos de versão futura desconhecida.
- Usar caminhos temporários nos testes.

## Restrições

- Não serialize Nodes, Resources vivos ou a árvore de cenas.
- Não sobrescreva save corrompido antes de tentar recuperação.
- Não confirme sucesso quando a gravação falhar.

## Entrega

Inclua round-trip, corrupção, backup, versão futura e migração quando o schema mudar.

