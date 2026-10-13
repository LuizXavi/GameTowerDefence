---
name: neon-void-ui-vfx
description: Criar e revisar HUD, menus, Codex, laboratório, desenho procedural, efeitos e áudio do Godot Neon Void mantendo estilo neon, acessibilidade e responsividade.
---

# UI e VFX do Neon Void

Leia `AGENTS.md`, `docs/agents/PROJECT_CONTEXT.md` e as funções `UI_UX.md` ou `VFX_AUDIO.md` conforme a tarefa. `scripts/main.gd` apresenta a interface; `scripts/arena.gd` apresenta a arena e recebe input. Nenhum deles deve calcular economia ou recompensas.

## Interface

- Use Containers para layouts e teste 1280×800, 800×900 e 640×640 quando a tela afetada puder ficar compacta.
- Preserve navegação por teclado e mouse/toque, foco dentro de modais e Escape para fechamento previsível.
- Mostre estados bloqueado, disponível, máximo, vazio e erro por texto ou forma além da cor.
- Leia valores do estado autoritativo e envie comandos; não replique fórmulas de gameplay na UI.

## Arena, efeitos e áudio

- Preserve fundo espacial escuro, geometria neon e a paleta documentada.
- Diferencie variantes por silhueta, rótulo, movimento ou padrão; cor isolada não basta.
- Use sinais do gameplay para feedback de dano, morte, drop e habilidade.
- Limite flashes, partículas, tremor, sons simultâneos e efeitos persistentes para manter alvos e HUD legíveis.

## Validação

Execute importação, testes de lógica quando o contrato mudou e sempre o teste gráfico para UI, input, cenas, VFX ou áudio. Inspecione as capturas, incluindo os estados novos e uma arena cheia.
