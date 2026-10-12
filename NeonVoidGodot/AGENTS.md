# Neon Void — instruções para agentes

## Missão

Evoluir o Neon Void sem perder sua identidade: combate incremental por clique, ondas rápidas, geometria neon, feedback forte e interface legível em desktop e telas compactas.

Leia antes de editar:

- `docs/agents/PROJECT_CONTEXT.md`
- `docs/agents/WORKFLOW.md`
- o arquivo da função que você recebeu em `docs/agents/roles/`

## Skills do projeto

Carregue a skill correspondente em `.agents/skills/` quando a tarefa entrar no domínio:

- `neon-void-coordination`: planejamento, delegação e integração entre áreas.
- `neon-void-gameplay`: inimigos, ondas, dano, economia e balanceamento.
- `neon-void-research`: peças, pesquisas, missões e Codex.
- `neon-void-ui-vfx`: HUD, menus, responsividade, acessibilidade e feedback audiovisual.
- `neon-void-persistence`: save, schemas, migrações, backup e recuperação.
- `neon-void-qa`: validação lógica, gráfica e de regressão.

Para trabalho com subagentes, siga `docs/agents/SUBAGENT_PLAN.md` e atribua um único responsável para cada arquivo compartilhado.

## Fonte oficial do estado

`VoidState`, em `scripts/game_state.gd`, é a fonte autoritativa de combate, economia e progressão da partida. A interface mostra esse estado e envia comandos; ela não calcula recompensas nem guarda uma economia paralela.

O ranking e as preferências persistentes pertencem a `scripts/score_store.gd`. Alterar seu schema exige migração, validação, backup e testes com caminhos temporários.

## Responsabilidade dos arquivos

| Área | Responsável primário | Arquivos |
|---|---|---|
| Coordenação | Coordenador | `project.godot`, documentação e integração |
| Gameplay | Gameplay e balanceamento | `scripts/game_state.gd`, definições futuras e testes de regras |
| Interface | UI e experiência | `scripts/main.gd`, cenas e temas de UI |
| Efeitos | Visual e áudio | `scripts/arena.gd`, `shaders/`, `assets/audio/` |
| Persistência | Save e metaprogressão | `scripts/score_store.gd`, migrações e testes de save |
| Qualidade | Testes | `tests/` e relatórios; não altera regras sem devolver o problema ao responsável |

Um agente pode ler qualquer arquivo. Antes de editar um arquivo pertencente a outra área, registre a necessidade no plano da tarefa e coordene a mudança.

## Regras de implementação

- Preserve as fórmulas existentes salvo quando a tarefa pedir balanceamento.
- Consumo de ouro e recompensas acontecem uma única vez.
- Pausa congela gameplay e preserva a resposta da interface.
- Reinício limpa todo o estado temporário.
- Informações importantes usam texto ou forma além de cor.
- Mouse/toque não devem ser a única forma de operar menus.
- Use Containers para layouts; não force posições de filhos gerenciados por Container.
- Novos dados persistentes usam IDs estáveis e schema versionado.
- Não grave testes no save real do usuário.
- Não edite `.godot/`; é cache gerado.
- Preserve as fontes e licenças em `assets/fonts/`.

## Validação mínima

Depois de alterar scripts ou cenas:

```powershell
& "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --editor --import --quit
& "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_game.gd
```

Para UI, input, efeitos, áudio ou cenas, execute também:

```powershell
& "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --script res://tests/test_ui.gd -- --test-mode
```

O teste gráfico cobre 1280×800 e 800×900. Mudanças de layout precisam de inspeção visual das capturas, além da aprovação automática.

## Definição de pronto

Uma tarefa termina apenas quando:

1. O comportamento solicitado funciona.
2. Testes relevantes passam.
3. A aparência foi conferida quando aplicável.
4. Teclado e mouse/toque continuam funcionando.
5. Saves anteriores continuam válidos quando o schema muda.
6. O relatório informa mudanças, validação e limitações reais.

