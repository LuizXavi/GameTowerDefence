---
name: neon-void-roguelite
description: Projetar, balancear e implementar o sistema de cartas, drafts, modificadores de run e sinergias roguelite no Neon Void.
---

# Sistema Roguelite de Cartas e Perks — Neon Void

Use esta skill para criar ou iterar sobre mecânicas de escolhas temporárias (in-run) oferecidas após ondas de chefe (waves múltiplas de 5) ou marcos específicos.

## Princípios de Design
1. **Duração da Escolha:** Perks concedidos durante a partida são efêmeros e resetam ao reiniciar (`VoidState.reset()`). Não devem ser salvos em `ScoreStore`.
2. **Impacto e Trade-offs:** Cartas interessantes devem oferecer aumentos significativos ou trocas táticas (ex: +Dano em troca de -Velocidade da Torre, ou sinergias com módulos específicos).
3. **Draft Tríplice:** A cada marco, oferecer 3 opções sorteadas com pesos ponderados (Comum, Raro, Épico).
4. **Acoplamento com VoidState:** O estado ativo das cartas deve ser mantido como dicionário ou array de identificadores estáveis em `VoidState.active_perks`.
5. **Apresentação:** A janela modal de seleção pausa o jogo (`state.paused = true`) e garante foco de navegação acessível via teclado e mouse.

## Critérios de Validação
- Nenhuma carta duplica benefícios indevidamente ao pausar/despausar.
- O reset da partida limpa todos os modificadores acumulados.
- Testes determinísticos em `tests/test_game.gd` devem validar a aplicação e o acúmulo de cada perk.
