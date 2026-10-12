# Contexto do Neon Void

## Produto

Neon Void é um jogo incremental de defesa em uma única arena. Inimigos geométricos descem em direção à base. O jogador os ataca por clique/toque, compra melhorias durante a partida e usa o Pulso Nova quando sua carga chega a 100%.

## Identidade

- Fundo espacial roxo muito escuro.
- Grade animada e estrelas.
- Rosa: inimigo comum e dano de clique.
- Ciano: inimigo rápido, escudo e informações.
- Verde-limão: tanque e torreta automática.
- Âmbar: crítico e boss.
- Fonte de títulos: Orbitron.
- Fonte de corpo: Rajdhani.

O visual deve continuar limpo mesmo com muitos inimigos. Efeitos devem reforçar impacto sem esconder alvos ou informações.

## Fluxo atual

```text
Menu → Partida → Pausa/Continuação → Game over → Ranking/Reinício
```

Durante a partida:

```text
spawn → movimento → clique ou torreta → dano → morte/recompensa
                                   ↘ vazamento → dano à base
```

Ao atingir a cota de abates, a próxima onda começa. A cada cinco ondas surge um boss.

## Arquitetura atual

- `scenes/main.tscn`: entrada do jogo.
- `scripts/main.gd`: constrói menus, HUD, loja, modais e conecta os sistemas.
- `scripts/game_state.gd`: combate, economia, ondas, inimigos e upgrades.
- `scenes/arena.tscn` + `scripts/arena.gd`: apresentação da arena e input de clique.
- `scripts/score_store.gd`: ranking, recorde, preferência de som e recuperação por backup.
- `tests/test_game.gd`: regras e persistência.
- `tests/test_ui.gd`: fluxo gráfico e controles.

## Regras econômicas atuais

- Clique Plasma: custo base 15, crescimento 1,58.
- Torreta Auto: custo base 50, crescimento 1,68.
- Núcleo Crítico: custo base 90, crescimento 1,80.
- Escudo Base: custo base 70, crescimento 1,72.
- Combo aumenta dano e ouro em 4% por acerto, limitado a 60 acertos.
- Errar reduz o combo em três.
- Um inimigo que atravessa a base reduz o combo em seis.
- Pulso Nova começa com 20% e carrega com tempo, abates e marcos de combo.

## Inimigos especiais

- Quadrado blindado resiste a cliques e é vulnerável à torreta.
- Triângulo fantasma alterna períodos intangíveis.
- Hexágono regenerador recupera vida após ficar sem receber dano.
- Duplicador cria dois inimigos menores ao morrer.
- Ladrão rouba ouro quando alcança a base.
- Elite recebe dois modificadores distintos e melhora a recompensa de peças.

## Pesquisas permanentes

- Fragmento quadrado: 30% de drop; melhora dano base de clique.
- Fragmento triangular: 22% de drop; melhora DPS da torreta.
- Liga hexagonal: 40% de drop; melhora vida máxima.
- Núcleo de boss: drop garantido de duas unidades; melhora recarga passiva da Nova.
- Inventário e níveis de pesquisa foram introduzidos no schema 2; o Codex entrou no schema 3; o schema atual é 4 e inclui descoberta, pesquisa e equipamento dos módulos da torre.
- Drops são persistidos imediatamente e cada linha consome apenas sua própria família.

## Módulos da torre

- O jogador equipa um módulo antes da partida; a escolha altera a Torreta Auto.
- Plasma é inicial. Criogênica aparece na wave 5 e Arco na wave 10.
- Descoberta, pesquisa e equipamento pertencem ao schema 4 do save.
- Regras e custos estão em `docs/TOWER_MODULES.md`.

## Limites conhecidos

- Definições de inimigos e upgrades ainda estão embutidas no script.
- A arena usa desenho procedural; não há sprites animados externos.
- O áudio é uma adaptação local dos sintetizadores da versão web.
- Não existe suporte específico a gamepad nos testes atuais.

## Direção recomendada

1. Extrair definições de inimigos e upgrades para Resources.
2. Adicionar escolhas de melhoria entre ondas.
3. Criar novos bosses com fases.
4. Implementar missões de pesquisa usando os IDs e contadores persistentes existentes.
5. Validar gamepad e mobile real.

