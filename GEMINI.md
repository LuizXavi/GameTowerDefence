# Neon Void — Guia de Operação Autônoma & Framework de Agentes

Bem-vindo ao **Neon Void**, um jogo incremental de Tower Defence com estética Cyberpunk Neon construído em **Godot 4.7**.

Você está conectado ao repositório do jogo incremental **Neon Void**.
Consulte sempre os arquivos de instruções contidos em `.agent/rules/godot_project_rules.md` e `.agent/skills/`.

---

## 🚀 Ferramenta de Automação Rápida: `neon.bat`
O repositório possui uma CLI de automação completa na raiz do projeto:
- `.\neon.bat validate` — Roda a validação completa (compilação headless + 127 testes lógicos + testes gráficos de UI).
- `.\neon.bat play` — Inicia o jogo diretamente no Godot.
- `.\neon.bat test-logic` — Executa apenas os testes determinísticos de gameplay (`test_game.gd`).
- `.\neon.bat test-ui` — Executa a suíte de UI e captura de telas (`test_ui.gd`).
- `.\neon.bat balance` — Simula e imprime as curvas matemáticas de combate e economia (`simulate_balance.py` e `balance_simulator.py`).
- `.\neon.bat clean` — Limpa caches temporários, backups órfãos e arquivos residuais.
- `.\neon.bat status` — Mostra o painel de status do projeto, git e saúde dos testes.
- `.\neon.bat sync` — Executa o ciclo de checagem, limpeza e commit/push com validação.
- `.\neon.bat monitor` — Abre o Escritório Virtual dos Agentes em tempo real (`agent_monitor.html`).

---

## 👥 Especialistas e Subagentes (`.agent/` e `.agents/`)

1. **`neon_director` / `gdscript_architect` (Direção Técnica & Arquitetura)**
   - Planejamento, tipagem estática rigorosa, signals para desacoplamento e conformidade técnica.
2. **`neon_gameplay_expert` / `progression_balancer` (Engenheiro de Combate & Economia)**
   - Arquitetura de `VoidState` (`scripts/game_state.gd`), `EnemySpawner`, `TowerCombat`, escala exponencial e balanceamento de waves.
3. **`neon_meta_persistence` (Engenheiro de Meta-Progressão & Saves)**
   - Gerenciamento de `SaveStore`, banco de pesquisas, migrações de esquema (Schema 11+), fragmentos e persistência.
4. **`neon_ui_vfx_specialist` / `vfx_sound_designer` (Designer de Interface, Shaders & VFX)**
   - Componentes `UIFactory`, desenho vetorial procedural em `NeonIcons`, shaders de pulso, modais responsivos e áudio.
5. **`neon_qa_validator` (Engenheiro de Qualidade & CI/CD)**
   - Manutenção da suíte de 127+ testes em `test_game.gd` e `test_ui.gd`, verificação de regressões e integridade de build.

---

## 🛠 Diretrizes de Desenvolvimento Autônomo
Ao receber demandas de desenvolvimento, opere de forma autônoma aplicando as seguintes regras:
- **Para novas telas de UI**: siga estritamente o padrão `UIFactory` (`UIFactory.label()`, `UIFactory.button()`, `UIFactory.panel()`) e gerencie o foco/scroll com `modal_return_focus`.
- **Para novos tipos de torres ou módulos**: atualize as constantes em `GameData`, o mapeamento em `VoidState`, os slots em `SaveStore` e a rotina visual em `AttackVFX`.
- **Para novos inimigos**: utilize desenho vetorial limpo mapeado em `Arena._draw()`, evitando alocações excessivas no loop principal.
- **Para persistência**: nunca quebre saves legados; sempre mantenha a cadeia sequencial `migrate()` em `SaveStore` e a validação estrita com `valid()`.
- **Notação Numérica**: todas as exibições de pontuação, ouro e DPS devem ser roteadas por `NumberFormat.format()` ou `NumberFormat.format_int()`.
- **Identidade Visual e Ícones**: consistência gráfica cyberpunk neon inegociável em todos os elementos. Zero emojis de sistema e zero bitmaps avulsos na interface; todo ícone, aba ou indicador deve ser desenhado proceduralmente via `NeonIcons` (`draw_ui`, `draw_piece_icon`, `draw_tower`, `draw_enemy`).

---

## 📚 Sistema de Skills Ativas (Godot 4)
O agente deve aplicar rigorosamente as regras definidas em:
- `.agent/skills/skill_godot_architecture.md` (Tipagem estática e estrutura por signals)
- `.agent/skills/skill_godot_ui_system.md` (Responsividade, containers e UIFactory)
- `.agent/skills/skill_godot_rendering_vfx.md` (Vetor procedural via _draw e partículas leves)
- `.agent/skills/skill_godot_persistence.md` (Migração de esquemas e integridade JSON)
- `.agents/skills/` (gameplay, módulos, persistência, pesquisas, roguelite, UI, balanceamento e QA)

