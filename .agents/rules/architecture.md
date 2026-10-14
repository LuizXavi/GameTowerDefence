---
trigger: always_on
description: Regras arquiteturais críticas e invariantes do projeto Neon Void (Godot 4.7)
---

# Diretrizes Arquiteturais do Neon Void

## 1. Princípio da Fonte Única da Verdade
- `VoidState` (`scripts/game_state.gd`): Estado autoritativo da partida (HP, ouro, combo, carga, inimigos, projéteis).
- `SaveStore` (`scripts/score_store.gd`): Estado autoritativo persistente (peças, pesquisas, módulos, hangar, ranking).
- `GameData` (`data/game_data.gd`): Constantes, paleta de cores neon, tabelas estáticas de custo e balanceamento.
- Interfaces (`ui/screens/*`) são visões puras: nunca calcule regras econômicas ou aplique dano diretamente em telas.

## 2. Tipagem Estática Rigorosa (GDScript 4.7)
- Todas as variáveis, argumentos de funções e retornos devem ter tipos estáticos explícitos.
- Evite inferência ambígua (`:=`) quando o lado direito for Variant ou chamada de dicionário/array untyped:
  - CORRETO: `var cost: int = int(data.get("amount", 0))`
  - INCORRETO: `var cost := data.get("amount")`
- Arrays numéricos devem usar tipo concreto: `Array[int]` ou `Array[float]`.

## 3. Compatibilidade e Migração de Saves
- Nunca quebre saves antigos. Sempre incremente `SCHEMA_VERSION` e implemente a cadeia em `SaveStore.migrate()`.
- O método `SaveStore.valid()` deve verificar rigorosamente a integridade dos tipos e valores antes de gravar em disco (`.tmp` -> rename atômico).

## 4. UI e Estilo Visual Neon (Padronização Gráfica Inegociável)
- Todos os elementos devem respeitar a paleta cyberpunk:
  - Ciano `#00ffff` (Escudos, seleção primária, laboratório)
  - Rosa/Magenta `#ff007f` (Ataque, perigo, elites, módulos ofensivos)
  - Limão `#39ff14` (Economia, confirmação, sucesso)
  - Âmbar `#ffb703` (Fragmentos, alertas, aviso de custo)
- **Zero Emojis de Sistema / Zero Bitmaps Estranhos**: NUNCA utilize emojis do sistema (como 🔬, ⚔, 🛡) ou imagens PNG que destoem da estética vetorial neon.
- **Desenhos Procedurais Centralizados em `NeonIcons`**:
  - Todo novo ícone, botão de aba, cabeçalho ou marcador de recurso DEVE ser implementado como desenho vetorial procedural 2D em `NeonIcons.draw_ui()`, `NeonIcons.draw_tower()`, `NeonIcons.draw_enemy()` ou `NeonIcons.draw_piece_icon()`.
  - Linhas com espessura de 1.2 a 2.4 com `antialiased = true`, anéis de halo escuro e núcleos luminosos.
- Layouts devem ser responsivos de 640x640 até 1920x1080.
- Telas modais devem sempre preservar a posição de rolagem através de `get_modal_scroll_v()` e `restore_modal_scroll_v()`.

## 5. Validação Contínua (CI/CD Local)
- Antes de qualquer commit, execute a validação automatizada:
  `.\neon.bat validate`
- Todos os testes lógicos (`tests/test_game.gd`) e testes visuais (`tests/test_ui.gd`) devem passar com 100% de sucesso.
