---
name: neon-void-gameplay
description: Implementar e balancear combate, inimigos, elites, waves, economia e upgrades de partida no projeto Godot Neon Void. Use para mudanças nas regras executadas durante uma partida; não use para pesquisas permanentes, missões ou save do Codex.
---

# Gameplay do Neon Void

Trabalhe no projeto Godot 4 mantendo `scripts/game_state.gd` como fonte das regras e a UI apenas como apresentação. Antes de editar, leia `docs/agents/PROJECT_CONTEXT.md` e, para variantes ou elites, `docs/SPECIAL_ENEMIES.md`.

## Fluxo

1. Identifique a regra afetada e os valores atuais em `scripts/game_state.gd` e `tests/test_game.gd`.
2. Preserve pausa, reinício, game over, boss a cada cinco waves e consumo único de compras e recompensas.
3. Ao criar inimigos ou modificadores, defina vida, velocidade, resistência, recompensa, vazamento, entrada por wave e interação com clique, torreta e Nova.
4. Faça mudanças de balanceamento isoladas e explique a fórmula ou progressão alterada. Não ajuste valores alheios à tarefa.
5. Adicione testes determinísticos usando `spawn` forçado, rolagens forçadas ou estado controlado. Teste a interação, não apenas a existência do campo.
6. Execute a importação headless e `tests/test_game.gd`; execute `tests/test_ui.gd` quando a mudança afetar apresentação, input ou fluxo de telas.

## Invariantes

- Não use Nodes ou texto da interface como fonte do estado.
- Uma morte concede abate, ouro, pontuação e drop no máximo uma vez.
- Filhos do Duplicador não geram nova divisão nem peças.
- Alvos intangíveis não recebem dano nem são escolhidos pela torreta.
- Mudanças em dados permanentes exigem também o fluxo da skill `neon-void-research`.
- Preserve o estilo geométrico neon, a legibilidade com muitos alvos e os controles existentes.

Entregue os arquivos alterados, os valores finais, as waves em que a regra aparece e o resultado dos testes.
