# Neon Void — versão Godot

Conversão nativa para Godot 4.7 do jogo incremental fornecido em React/Canvas.

## Abrir e jogar

1. Abra o Godot 4.7 ou mais recente.
2. Importe o arquivo `project.godot` desta pasta.
3. Pressione F6/F5 para executar.

## Controles

- Mouse ou toque: atacar inimigos e usar a interface
- 1–4: comprar upgrades
- Espaço: Pulso Nova
- P ou Esc: pausar/continuar
- R: reiniciar
- M: ativar/desativar som

O ranking e a preferência de som são salvos localmente em `user://records_v1.json`, com validação e cópia de segurança.

## Pesquisas

Inimigos derrotados podem soltar peças da sua família:

- Quadrado: 30% de chance.
- Triangular: 22% de chance.
- Hexagonal: 40% de chance.
- Boss: sempre solta dois núcleos.

As peças ficam guardadas entre partidas e podem ser gastas no Laboratório de Pesquisas do menu. As linhas atuais melhoram dano de clique, DPS automático, vida máxima e recarga passiva do Pulso Nova.

As chances, custos, limites e formato persistente estão documentados em `docs/RESEARCH_SYSTEM.md`.

## Módulos da torre

O menu permite equipar uma torre por vez. Plasma está disponível desde o início; a Torre Criogênica é descoberta na wave 5 e a Torre de Arco na wave 10. Depois da descoberta, cada módulo precisa ser pesquisado com peças antes de ser equipado. Os efeitos e custos ficam em `docs/TOWER_MODULES.md`.

## Inimigos especiais

Waves avançadas incluem Blindados, Fantasmas, Regeneradores, Duplicadores, Ladrões e Elites com dois modificadores. O menu possui um Codex persistente com descobertas, abates, peças, fraquezas e maior wave. As regras completas ficam em `docs/SPECIAL_ENEMIES.md`.

## Estrutura

- `scenes/`: cenas principais e arena
- `scripts/`: gameplay, interface e persistência
- `shaders/`: fundos e título animado
- `assets/`: fontes e efeitos sonoros
- `tests/`: testes de lógica e de interação gráfica

As fontes Orbitron e Rajdhani são distribuídas sob a SIL Open Font License; os textos das licenças estão junto aos arquivos.

## Desenvolvimento com agentes

As regras para trabalho coordenado estão em `AGENTS.md`. O contexto, os papéis, o fluxo, o modelo de tarefa e o primeiro ciclo recomendado ficam em `docs/agents/`.

O projeto também inclui seis skills em `.agents/skills/` para coordenação, gameplay, pesquisas/Codex, UI/VFX, persistência e QA. O plano de subagentes, modelos recomendados, ondas paralelas e protocolo de handoff está em `docs/agents/SUBAGENT_PLAN.md`.
