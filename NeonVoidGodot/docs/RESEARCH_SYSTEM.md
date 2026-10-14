# Sistema de pesquisas

## Loop

1. O jogador derrota inimigos.
2. Cada família faz uma rolagem independente ao morrer.
3. Um drop adiciona a peça ao inventário permanente e ao contador da partida.
4. No menu, o Laboratório consome peças para comprar níveis permanentes.
5. Os bônus são aplicados no começo de cada partida.

## Famílias e Taxas de Drop Base

| Inimigo | Peça | Chance Base | Quantidade | Pesquisas de Drop Especializadas |
|---|---|---:|---:|---|
| Quadrado | Fragmento quadrado | 6% | 1 | Magnetismo (17), Sintonia de Espólios (28), Sobrecarga (30) |
| Triangular | Fragmento triangular | 5% | 1 | Magnetismo (17), Sintonia de Espólios (28), Sobrecarga (30) |
| Hexagonal | Liga hexagonal | 8% | 1 | Magnetismo (17), Filtro de Matéria Rara (29), Sobrecarga (30) |
| Titã / Especial | Núcleo de boss | 18% | 1 | Magnetismo (17), Sobrecarga (30) |
| Boss | Núcleo de boss | 100% | 2 | Garantido ao derrotar o chefe da wave |

## Pesquisas de Otimização de Drops

1. **Magnetismo de Fragmentos (Índice 17)**: +3% de chance geral por nível em todos os tipos de inimigos.
2. **Sintonia de Espólios (Índice 28)**: +3% de chance por nível para Quadrados e Triângulos.
3. **Filtro de Matéria Rara (Índice 29)**: +5% de chance por nível para Hexágonos e +10% de chance extra em Elites.
4. **Sobrecarga de Extração (Índice 30)**: Abates realizados com Acerto Crítico ou Combo ≥ 10 recebem +4% de chance de drop e 25% de probabilidade de drop duplo (+1 peça).

## Persistência e Esquemas

O jogo utiliza migração sequencial estrita (Schema 1 até 13):
- **Schema 10**: Expandiu pesquisas para 28 entradas.
- **Schema 11**: Adicionou árvore de pesquisas e upgrades do Laboratório (`lab_research`).
- **Schema 12**: Adicionou rastreamento de conquistas (`achievements`).
- **Schema 13**: Expande `research` para 31 slots, acomodando as pesquisas dedicadas de drops de peças com compatibilidade retroativa e validação estrita.

## Extensão futura

Novos tipos devem usar IDs estáveis antes de substituir os arrays por dicionários. Se uma nova peça for adicionada, crie uma migração para o próximo schema e não dependa da posição visual do inimigo para decidir seu drop.
