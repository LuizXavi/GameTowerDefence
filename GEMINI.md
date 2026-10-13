# Neon Void — Guia do Desenvolvedor & Framework de Agentes

Bem-vindo ao **Neon Void**, um jogo incremental de Tower Defence com estética Cyberpunk Neon construído em **Godot 4.7**.

## 🚀 Ferramenta de Automação Rápida: `neon.bat`
O repositório possui uma CLI de automação completa na raiz do projeto:
- `.\neon.bat validate` — Roda a validação completa (compilação headless + 127 testes lógicos + testes gráficos de UI).
- `.\neon.bat play` — Inicia o jogo diretamente no Godot.
- `.\neon.bat test-logic` — Executa apenas os testes determinísticos de gameplay (`test_game.gd`).
- `.\neon.bat test-ui` — Executa a suíte de UI e captura de telas (`test_ui.gd`).
- `.\neon.bat balance` — Simula e imprime as curvas matemáticas de combate e economia (`simulate_balance.py`).
- `.\neon.bat clean` — Limpa caches temporários, backups órfãos e arquivos residuais.
- `.\neon.bat status` — Mostra o painel de status do projeto, git e saúde dos testes.
- `.\neon.bat sync` — Executa o ciclo de checagem, limpeza e commit/push com validação.
- `.\neon.bat monitor` — Abre o Escritório Virtual dos Agentes em tempo real (`agent_monitor.html`).

---

## 👥 Especialistas e Subagentes (`.agents/agents/`)

1. **`neon_director` (Coordenador de Produção)**
   - Planejamento de sprints, triagem de requisitos, delegação para especialistas e revisão final.
2. **`neon_gameplay_expert` (Engenheiro de Combate & Balanceamento)**
   - Arquitetura de `VoidState`, `EnemySpawner`, `TowerCombat`, física dos projéteis, ondas e bosses.
3. **`neon_meta_persistence` (Engenheiro de Meta-Progressão & Saves)**
   - Gerenciamento de `SaveStore`, banco de pesquisas, migrações de esquema (Schema 11+), fragmentos e persistência.
4. **`neon_ui_vfx_specialist` (Designer de Interface, Shaders & VFX)**
   - Componentes `UIFactory`, desenho vetorial procedural em `NeonIcons`, shaders de pulso, modais responsivos e áudio.
5. **`neon_qa_validator` (Engenheiro de Qualidade & CI/CD)**
   - Manutenção da suíte de 127+ testes em `test_game.gd` e `test_ui.gd`, verificação de regressões e integridade de build.

---

## 🛠 Padrões Técnicos e Invariantes
- **GDScript 4.7 Tipado**: Sempre declare tipos explícitos (`var nome: Tipo = valor`), evitando inferências ambíguas em variantes.
- **SaveStore Determinístico**: Todo save grava primeiro em `.tmp`, valida o json gravado com `valid()`, e executa renomeação atômica.
- **Scroll Preservation**: Modais devem ler o scroll antes de rebuildar cards e restaurar a posição e foco após o ciclo de renderização.
