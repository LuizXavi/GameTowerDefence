---
name: neon-void-research
description: Implementar pesquisas, peças, objetivos, missões, Codex e persistência de metaprogressão no Godot Neon Void. Use quando o progresso atravessa partidas ou depende de estatísticas permanentes de inimigos.
---

# Pesquisas e Codex do Neon Void

Antes de editar, leia `docs/RESEARCH_SYSTEM.md`, `docs/SPECIAL_ENEMIES.md`, `scripts/score_store.gd`, os sinais relevantes de `scripts/game_state.gd` e os consumidores em `scripts/main.gd`.

## Modelo de dados

- Use IDs estáveis independentes do nome exibido e da posição visual. Preserve os IDs existentes: `square`, `triangle`, `hexagon`, `boss`, `armored_square`, `ghost_triangle`, `regen_hexagon`, `splitter`, `thief` e `elite`.
- Defina cada progresso com evento, critério, escopo e momento de concessão. Exemplos de eventos: inimigo descoberto, morte confirmada, peça concedida, wave concluída, dano à base e uso da Nova.
- Diferencie progresso da partida, inventário permanente, estatística do Codex e recompensa já resgatada. Persista uma chave de conclusão ou resgate quando repetir o evento puder duplicar prêmio.
- Atualize o Codex a partir de eventos confirmados do gameplay. Filhos sem drop, dano repetido e carregamento de save não podem gerar peças ou abates extras.

## Implementação

1. Especifique custos, limites, família de peça e efeito por nível antes de alterar código.
2. Para missões, escreva um critério verificável, por exemplo `kills_by_id >= 100`, e registre apenas os contadores mínimos necessários. Condições como "sem Nova" ou "sem sofrer dano" precisam de estado explícito da tentativa.
3. Se o formato persistido mudar, incremente o schema, migre versões em sequência, valide tipos, limites, IDs e números finitos, e preserve saves de versão futura sem sobrescrevê-los.
4. Continue gravando em temporário, validando antes da troca e mantendo backup recuperável.
5. Garanta operação idempotente: comprar consome uma vez; concluir não resgata automaticamente de novo; sinais duplicados não duplicam recompensa.
6. Teste saldo insuficiente, limite máximo, round-trip, migrações, corrupção/backup, versão futura e o caso de duplicação relevante. Use caminhos temporários nos testes.

Mantenha compatibilidade com os arrays atuais de quatro famílias. Ao adicionar nova família ou moeda, prefira um schema baseado em IDs ou crie migração explícita; nunca derive persistência da ordem da UI.

Entregue o contrato dos IDs e eventos, a alteração de schema quando houver, a regra de concessão/resgate e o resultado dos testes.
