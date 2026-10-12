---
name: neon-void-persistence
description: Criar ou alterar saves, migrações, ranking, peças, pesquisas, missões e estatísticas permanentes do Neon Void com compatibilidade e recuperação de corrupção.
---

# Persistência do Neon Void

Leia `AGENTS.md`, `docs/agents/roles/PERSISTENCE.md`, `docs/RESEARCH_SYSTEM.md` e `scripts/score_store.gd`.

## Contrato de dados

- Use IDs estáveis para inimigos, variantes, pesquisas e missões. Nunca derive um ID de texto visível ou posição na interface.
- Incremente o schema somente quando a forma persistida mudar.
- Migre versões sequencialmente e preserve saves de versão futura sem sobrescrevê-los.
- Valide tipos, limites, números finitos, coleções e referências antes de aplicar dados carregados.
- Garanta que drops, compras e recompensas sejam contabilizados uma única vez.

## Gravação e recuperação

- Grave em arquivo temporário, valide e só então substitua o save principal.
- Mantenha backup válido e tente recuperá-lo quando o principal estiver corrompido.
- Não serialize Nodes nem Resources vivos.
- Use caminhos temporários em todos os testes; nunca toque no save real do jogador.

## Validação

Cubra round-trip, migração de cada versão suportada, arquivo corrompido, backup, limites inválidos e versão futura. Rode `tests/test_game.gd`; execute o teste gráfico quando os dados também aparecem na interface.
