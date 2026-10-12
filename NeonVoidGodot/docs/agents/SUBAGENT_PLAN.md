# Plano executável de subagentes — Neon Void

## Objetivo

Organizar a evolução do Neon Void em sete especialidades, permitindo trabalho paralelo sem criar duas fontes para combate, economia ou progressão. O coordenador cria tarefas pequenas a partir de `docs/agents/TASK_TEMPLATE.md`, registra os contratos e só libera uma onda quando as entradas necessárias estiverem estáveis.

## Seleção de modelos

| Modelo | Uso no projeto | Motivo |
|---|---|---|
| `gpt-6-astra` | Coordenação e mudanças sistêmicas de gameplay | Trabalho de maior complexidade, com decisões de arquitetura, fórmulas interdependentes e risco de regressões entre áreas. |
| `gpt-6.1-sol` | Pesquisa/Codex, UI/UX, persistência e QA | Implementação e revisão de complexidade média ou alta, com forte necessidade de precisão em contratos, fluxos e validação. |
| `gpt-6-luna` | VFX/áudio e tarefas mecânicas já especificadas | Iteração rápida em mudanças locais e bem delimitadas, com validação visual posterior pelo QA. |

O modelo indicado é o padrão da função. O coordenador pode elevar uma tarefa isolada para `gpt-6-astra` quando ela atravessar três ou mais sistemas, exigir uma migração difícil ou envolver balanceamento com várias soluções possíveis.

## Agentes

### 1. Coordenador e integrador

- **Modelo:** `gpt-6-astra`, raciocínio `high`.
- **Por que:** precisa decompor requisitos ambíguos, estabilizar contratos, arbitrar mudanças concorrentes e avaliar o jogo como um sistema único.
- **Escopo:** planejamento, arquitetura, divisão de tarefas, integração, documentação e aceite final.
- **Propriedade de arquivos:** `AGENTS.md`, `project.godot`, `docs/agents/`, documentação transversal e qualquer arquivo de integração criado especificamente para contratos compartilhados.
- **Entradas:** pedido do jogador, relatórios dos agentes, documentação do projeto, resultados de testes e capturas.
- **Saídas:** tarefas preenchidas, contratos de sinais/dados, ordem de execução, decisões de conflito, changelog da entrega e pacote validado.
- **Dependências:** nenhuma para planejar; depende de todos os agentes para fechar a entrega.
- **Critérios de pronto:** cada tarefa tem dono e aceite observável; nenhuma edição concorrente permanece; testes relevantes passam; capturas foram inspecionadas; compatibilidade do save foi registrada.

### 2. Gameplay e balanceamento

- **Modelo:** `gpt-6-astra`, raciocínio `high`.
- **Por que:** combate, ondas, economia e drops são interdependentes; pequenos ajustes podem produzir exploração de recompensa ou curvas inviáveis.
- **Escopo:** inimigos, elites, bosses, ondas, dano, economia da partida, upgrades temporários, drops e simulações de balanceamento.
- **Propriedade de arquivos:** `scripts/game_state.gd` e futuros Resources de inimigos/upgrades; pode propor casos em `tests/test_game.gd`, mas o QA consolida o arquivo durante a onda de validação.
- **Entradas:** objetivo de design, IDs estáveis, contrato de persistência, limites de balanceamento e métricas da versão anterior.
- **Saídas:** regras determinísticas, sinais de domínio documentados, fórmulas e valores, cenários de teste e relatório de impacto por wave.
- **Dependências:** contrato do coordenador; consulta persistência quando um valor atravessa partidas; entrega sinais para UI e VFX.
- **Critérios de pronto:** não há recompensa duplicada; pausa/reinício mantêm invariantes; regras podem ser testadas sem UI; progressão foi exercitada nas waves afetadas; fórmulas alteradas estão documentadas.

### 3. Pesquisa, missões e Codex

- **Modelo:** `gpt-6.1-sol`, raciocínio `high`.
- **Por que:** combina conteúdo, progressão e exibição, mas deve trabalhar sobre contratos já definidos por gameplay e persistência.
- **Escopo:** árvore de pesquisas, requisitos, missões, estatísticas e conteúdo do Codex; relações entre famílias, variantes, peças e descobertas.
- **Propriedade de arquivos:** `docs/RESEARCH_SYSTEM.md`, `docs/SPECIAL_ENEMIES.md` e futuros Resources de conteúdo de pesquisa/Codex. Alterações necessárias em `main.gd`, `game_state.gd` ou `score_store.gd` são entregues como contrato ao respectivo dono.
- **Entradas:** IDs de inimigos, eventos de abate/drop/wave/combo, inventário persistente, regras de desbloqueio e texto aprovado.
- **Saídas:** catálogo com IDs estáveis, custos e pré-requisitos, especificação das missões, dados de Codex e matriz de eventos necessários.
- **Dependências:** gameplay fornece eventos; persistência fornece formato e migração; UI apresenta os dados.
- **Critérios de pronto:** cada objetivo pode ser medido por um evento autoritativo; compras consomem uma única família de peça uma única vez; conteúdo desconhecido fica oculto corretamente; todas as entradas têm ID estável e pesquisa relacionada.

### 4. UI/UX e acessibilidade

- **Modelo:** `gpt-6.1-sol`, raciocínio `medium`.
- **Por que:** exige domínio de Godot Containers, foco e responsividade, com regras de negócio já fornecidas por outros agentes.
- **Escopo:** menus, HUD, loja, Laboratório, Codex, missões, pausa, game over, foco, atalhos e adaptação de tela.
- **Propriedade de arquivos:** `scripts/main.gd`, `scenes/main.tscn`, temas e recursos exclusivos de interface.
- **Entradas:** estado e comandos públicos de `VoidState`, catálogo de pesquisa/Codex, estados vazio/bloqueado/completo e identidade visual.
- **Saídas:** fluxos operáveis por teclado e mouse/toque, layouts responsivos, estados de erro claros e capturas para revisão.
- **Dependências:** começa com mocks após o contrato; integração final depende de gameplay, pesquisa/Codex e persistência.
- **Critérios de pronto:** funciona em 1280×800, 800×900 e 640×640; foco não escapa de modais; informação crítica usa texto ou forma além de cor; UI não calcula recompensas; capturas dos estados afetados foram geradas.

### 5. VFX e áudio

- **Modelo:** `gpt-6-luna`, raciocínio `medium`.
- **Por que:** as tarefas devem ser locais, visuais e dirigidas por sinais já especificados; o modelo rápido favorece ciclos curtos de ajuste e captura.
- **Escopo:** desenho procedural, animações, flashes, partículas, tremor, shaders, sons e diferenciação visual de inimigos.
- **Propriedade de arquivos:** `scripts/arena.gd`, `scenes/arena.tscn`, `shaders/`, `assets/audio/` e recursos visuais exclusivos da arena.
- **Entradas:** sinais de gameplay, estados visuais requeridos, orçamento de efeitos e paleta do projeto.
- **Saídas:** feedback visual/sonoro legível, capturas representativas e observação de desempenho em ondas cheias.
- **Dependências:** depende dos sinais de gameplay; fornece estados para o teste gráfico.
- **Critérios de pronto:** nenhuma regra ou recompensa é calculada na apresentação; variantes são distinguíveis por forma/texto/movimento; efeitos não escondem alvos ou HUD; sons simultâneos e efeitos persistentes têm limites.

### 6. Persistência e migrações

- **Modelo:** `gpt-6.1-sol`, raciocínio `high`.
- **Por que:** corrupção, backups e migrações sequenciais exigem precisão e análise de estados inválidos, embora o escopo esteja concentrado em um subsistema.
- **Escopo:** save, ranking, preferências, inventário, pesquisas, Codex, missões permanentes, validação, backup e migrações.
- **Propriedade de arquivos:** `scripts/score_store.gd` e fixtures exclusivas de save; fornece casos ao QA sem editar simultaneamente `tests/test_game.gd`.
- **Entradas:** schema atual, IDs estáveis, limites de valores, dados permanentes pedidos e fixtures de versões anteriores.
- **Saídas:** próximo schema, migração sequencial, validação, round-trip, recuperação por backup e contrato de leitura/escrita.
- **Dependências:** pesquisa/Codex define os dados; gameplay define quais eventos atualizam estatísticas; UI apenas consome o resultado.
- **Critérios de pronto:** schemas 1, 2 e 3 continuam carregando; versão futura não é sobrescrita; números não finitos/tipos inválidos são rejeitados ou normalizados conforme contrato; testes usam caminho temporário; falha de gravação não retorna sucesso.

### 7. QA e validação de entrega

- **Modelo:** `gpt-6.1-sol`, raciocínio `high`.
- **Por que:** precisa relacionar sintomas entre regras, UI, renderização e save, criar cenários determinísticos e rejeitar correções que apenas escondem regressões.
- **Escopo:** importação, testes de regras, persistência, UI, input, resolução, inspeção de capturas, recursos ausentes e regressão completa.
- **Propriedade de arquivos:** `tests/test_game.gd`, `tests/test_ui.gd`, fixtures de teste e relatórios de QA. Não muda regras de produção para satisfazer testes.
- **Entradas:** critérios de aceite, fórmulas, contratos de sinais, schemas, builds integradas e capturas.
- **Saídas:** testes automatizados, relatório por gravidade, passos de reprodução, evidências e decisão de aprovação/reprovação.
- **Dependências:** prepara casos a partir dos contratos na primeira onda; executa a validação completa após integração.
- **Critérios de pronto:** importação limpa; suíte lógica passa; suíte gráfica passa; resoluções e controles foram exercitados; saves antigos, corrupção, backup e versão futura foram testados quando aplicável; capturas foram inspecionadas manualmente.

## Ondas de execução

### Onda 0 — contrato e baseline

1. **Coordenador** registra comportamento observável, arquivos compartilhados e versão de schema.
2. **QA** executa a baseline e salva resultados e capturas atuais.
3. **Gameplay**, **Pesquisa/Codex** e **Persistência** definem, sem editar produção, os IDs, eventos e formatos que atravessam áreas.

**Gate:** sinais, comandos, IDs e formato persistente estão escritos na tarefa. Nenhuma implementação começa com contrato indefinido.

### Onda 1 — fundações paralelas

- **Gameplay:** implementa regras e sinais em `game_state.gd`.
- **Pesquisa/Codex:** prepara Resources/documentação de conteúdo sem tocar nos arquivos dos outros agentes.
- **Persistência:** implementa schema e migrações em `score_store.gd`.
- **QA:** prepara casos e fixtures em uma branch/worktree própria, sem integrar ainda.

**Gate:** gameplay funciona sem UI; save faz round-trip e migração; IDs coincidem entre as três trilhas.

### Onda 2 — apresentação paralela

- **UI/UX:** integra comandos e dados estáveis em `main.gd` e cenas.
- **VFX/áudio:** integra sinais estáveis em `arena.gd` e assets.
- **QA:** atualiza testes contra a build integrada da Onda 1.

**Gate:** fluxo completo é operável, o estado exibido vem da fonte autoritativa e não há erro de importação.

### Onda 3 — integração e correções

1. **Coordenador** integra na ordem: persistência → gameplay → conteúdo → UI → VFX → testes.
2. **QA** executa importação, suíte lógica e suíte gráfica e inspeciona capturas.
3. Falhas retornam ao dono do arquivo; o QA apenas confirma a correção.

**Gate:** todos os critérios de pronto aplicáveis passam e não há conflito pendente.

### Onda 4 — entrega

O **coordenador** atualiza a documentação, registra compatibilidade do save, limitações reais, evidências de teste e gera o pacote final.

## Protocolo de handoff

Cada agente entrega um bloco com:

1. **Resultado percebido pelo jogador.**
2. **Arquivos alterados e propriedade.**
3. **Contrato:** dados recebidos, comandos usados, sinais emitidos e dados persistidos.
4. **Fórmulas/IDs/schema** criados ou alterados.
5. **Validação executada** e resultado exato.
6. **Capturas**, quando houver mudança visual.
7. **Riscos, pendências e destinatário** do próximo handoff.

Um handoff só é aceito quando outro agente consegue integrar a saída sem inferir nomes, tipos ou comportamento ausente.

## Protocolo de conflitos

- Um arquivo tem um único escritor em cada onda. Outros agentes enviam uma proposta de contrato ou patch ao proprietário.
- `scripts/game_state.gd` prevalece para combate, economia e progresso da partida.
- `scripts/score_store.gd` prevalece para dados permanentes e compatibilidade.
- `scripts/main.gd` apenas apresenta estado e envia comandos; divergências de valores voltam ao gameplay ou à persistência.
- `scripts/arena.gd` apenas apresenta eventos; divergências de dano, recompensa ou alvo voltam ao gameplay.
- `tests/` pertence ao QA durante integração. O autor da regra fornece o cenário esperado, e o QA decide a forma do teste.
- Em conflito semântico, os agentes interrompem a edição do trecho, registram opções e impacto e o coordenador decide antes da continuação.
- Em conflito de merge, o coordenador refaz a integração sobre a versão mais recente; não escolhe automaticamente um lado inteiro.
- Alterações de schema, IDs estáveis, fórmulas ou identidade visual exigem registro explícito no handoff.

## Comandos de validação do gate final

```powershell
& "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --editor --import --quit
& "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_game.gd
& "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --script res://tests/test_ui.gd -- --test-mode
```
