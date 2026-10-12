# Inimigos especiais e elites

## Aparição

As variantes entram gradualmente:

- Wave 2: Quadrado Blindado.
- Wave 3: Duplicador e Triângulo Fantasma.
- Wave 4: Ladrão, Hexágono Regenerador e Elites.
- Boss: continua a cada cinco waves.

As probabilidades de variante são aplicadas depois da escolha da família base. Elites têm chance crescente, limitada a 16%.

## Comportamentos

| ID estável | Nome | Regra |
|---|---|---|
| `armored_square` | Quadrado Blindado | Recebe 35% do dano de clique e 175% do dano da torreta. |
| `ghost_triangle` | Triângulo Fantasma | Fica intangível por um segundo a cada três segundos. |
| `regen_hexagon` | Hexágono Regenerador | Recupera 3,5% da vida máxima por segundo depois de 1,5 segundo sem receber dano. |
| `splitter` | Duplicador | Ao morrer, gera dois quadrados menores, sem novos drops. |
| `thief` | Ladrão | Ao alcançar a base, rouba 15% do ouro, com mínimo de 10 limitado ao saldo. |
| `elite` | Elite | Vida, ouro e pontuação dobrados; recebe dois modificadores diferentes e melhora os drops. |

## Modificadores de elite

- `armor`: resistência a clique e fraqueza à torreta.
- `haste`: velocidade multiplicada por 1,4.
- `regen`: regeneração após intervalo sem dano.
- `phase`: alternância de intangibilidade.

Elites duplicam a chance de peça até o limite de 100% e acrescentam uma unidade ao drop.

## Codex e missões

O save registra descoberta, abates, peças e maior wave por ID. O Codex apresenta essas informações, chance de drop, fraqueza, variantes e pesquisa ligada. Os mesmos IDs formam o contrato para futuras missões como “derrote 100 quadrados” ou “mate um boss com combo acima de 30”.
