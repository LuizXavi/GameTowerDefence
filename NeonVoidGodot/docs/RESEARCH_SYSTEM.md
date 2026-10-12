# Sistema de pesquisas

## Loop

1. O jogador derrota inimigos.
2. Cada família faz uma rolagem independente ao morrer.
3. Um drop adiciona a peça ao inventário permanente e ao contador da partida.
4. No menu, o Laboratório consome peças para comprar níveis permanentes.
5. Os bônus são aplicados no começo de cada partida.

## Famílias

| Inimigo | Peça | Chance | Quantidade | Pesquisa |
|---|---|---:|---:|---|
| Quadrado | Fragmento quadrado | 30% | 1 | +1 dano base por nível |
| Triangular | Fragmento triangular | 22% | 1 | +8% DPS automático por nível |
| Hexagonal | Liga hexagonal | 40% | 1 | +10 vida máxima por nível |
| Boss | Núcleo de boss | 100% | 2 | +0,3 carga da Nova por segundo e nível |

## Custos e limites

| Pesquisa | Custo inicial | Aumento por nível | Máximo |
|---|---:|---:|---:|
| Análise de Plasma | 5 | +5 | 5 |
| Roteamento Autônomo | 5 | +5 | 5 |
| Liga da Base | 4 | +4 | 5 |
| Reator Nova | 2 | +2 | 3 |

Cada pesquisa aceita apenas a peça da família correspondente. A compra valida saldo, limite e consumo único.

## Persistência

O schema 2 acrescentou:

```json
{
  "pieces": [0, 0, 0, 0],
  "research": [0, 0, 0, 0]
}
```

A ordem estável é quadrado, triangular, hexagonal e boss. Saves do schema 1 são migrados com inventário e pesquisas zerados. O schema 3 acrescenta `enemy_stats` para o Codex e migra sequencialmente os schemas 1 e 2. Saves de versões futuras não são sobrescritos.

O schema 4 acrescenta a maior wave alcançada, módulos de torre pesquisados e o módulo equipado. Torre Criogênica aparece na wave 5 e custa 8 fragmentos triangulares; Torre de Arco aparece na wave 10 e custa 12 fragmentos quadrados. Consulte `docs/TOWER_MODULES.md`.

## Extensão futura

Novos tipos devem usar IDs estáveis antes de substituir os arrays por dicionários. Se uma nova peça for adicionada, crie uma migração para o próximo schema e não dependa da posição visual do inimigo para decidir seu drop.
