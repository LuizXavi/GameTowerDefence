---
name: neon-void-coordination
description: Planejar, delegar e integrar trabalho de múltiplos agentes no projeto Godot Neon Void, especialmente quando uma mudança atravessa gameplay, UI, efeitos, persistência ou testes.
---

# Coordenação do Neon Void

Leia `AGENTS.md`, `docs/agents/PROJECT_CONTEXT.md`, `docs/agents/WORKFLOW.md` e `docs/agents/SUBAGENT_PLAN.md` antes de dividir o trabalho.

## Planejamento

- Converta o pedido em comportamentos observáveis e critérios de aceite.
- Delegue por propriedade de arquivos. Evite dois agentes editando a mesma função ou cena.
- Declare os contratos entre áreas antes da implementação: sinais, IDs, dados persistentes e apresentação esperada.
- Escolha o modelo e o esforço conforme a matriz registrada em `docs/agents/SUBAGENT_PLAN.md`; aumente a capacidade quando a tarefa exigir arquitetura, migração ou integração entre áreas.
- Execute em paralelo somente tarefas sem dependência de saída ou sobreposição de arquivos.

## Integração

- Trate `VoidState` como fonte autoritativa da partida e `ScoreStore` como fonte dos dados permanentes.
- Integre primeiro contratos e regras, depois apresentação, persistência e testes.
- Encaminhe falhas ao responsável pelo domínio; não altere uma regra apenas para satisfazer um teste.
- Registre no handoff: arquivos alterados, contratos criados, testes feitos, riscos e trabalho restante.

## Conclusão

Execute a importação do Godot, os testes de lógica e, quando houver UI, cenas, input, VFX ou áudio, o teste gráfico com inspeção das capturas. Confirme compatibilidade de save quando houver dados persistentes.
