---
name: neon-void-qa
description: Validar mudanças do Godot Neon Void com importação, testes de gameplay e save, fluxo gráfico, controles, resoluções e inspeção de capturas.
---

# QA do Neon Void

Leia `AGENTS.md`, `docs/agents/WORKFLOW.md`, `docs/agents/roles/QA.md` e os critérios de aceite da tarefa. Registre uma baseline antes de mudanças extensas.

## Cobertura

- Regras: valores limites, pausa, reinício, game over, recompensa única e interações entre clique, torreta, Nova, variantes e elites.
- Persistência: round-trip, migrações suportadas, corrupção, backup, versão futura e caminhos temporários.
- Interface: mouse/toque, teclado, foco e Escape; estados bloqueados, vazios e concluídos.
- Visual: 1280×800, 800×900 e 640×640 quando relevante; arena cheia, textos legíveis e efeitos sem ocultar alvos.

## Execução

1. Importe o projeto com o executável Godot definido em `AGENTS.md`.
2. Rode `tests/test_game.gd` para toda mudança de código ou dados.
3. Rode `tests/test_ui.gd -- --test-mode` para UI, input, cenas, renderização, VFX ou áudio.
4. Inspecione as capturas visualmente; uma mensagem PASS não valida composição ou legibilidade.

Relate comportamento esperado, observado, passos, provável domínio responsável, gravidade e evidência. Não altere regras de produção para fazer um teste passar; devolva a falha ao proprietário do domínio.
