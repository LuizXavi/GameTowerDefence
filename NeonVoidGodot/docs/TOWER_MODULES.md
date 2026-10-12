# Módulos da torre

## Fluxo

1. O jogador alcança a wave exigida e descobre uma nova torre.
2. O módulo passa a aparecer no Laboratório e na tela de Módulos.
3. O jogador gasta as peças exigidas para pesquisá-lo uma única vez.
4. Depois da pesquisa, o módulo pode ser equipado antes da partida.
5. Apenas um módulo fica equipado. A escolha é aplicada no início da próxima partida.

## Módulos atuais

| ID | Torre | Descoberta | Pesquisa | Efeito |
|---|---|---:|---:|---|
| `plasma` | Torre Plasma | Inicial | Gratuita | 100% do dano automático em um alvo. |
| `cryo` | Torre Criogênica | Wave 5 | 8 fragmentos triangulares | 75% do dano e reduz o movimento do alvo em 35% por 1,5 segundo. |
| `arc` | Torre de Arco | Wave 10 | 12 fragmentos quadrados | 65% do dano no alvo e até dois saltos; cada salto causa 45% do tiro de Arco. |

O Arco procura o próximo alvo em até 160 pixels. Fantasmas intangíveis não podem ser alvejados nem receber saltos. Resistências continuam sendo calculadas pelo gameplay.

## Persistência

O schema 4 acrescenta:

```json
{
  "highest_wave": 1,
  "tower_modules": {
    "plasma": true,
    "cryo": false,
    "arc": false
  },
  "equipped_module": "plasma"
}
```

A migração do schema 3 calcula `highest_wave` usando o maior resultado salvo, mantém Plasma desbloqueada e começa com ela equipada. Módulos usam IDs estáveis; nomes visíveis não fazem parte do contrato do save.

## Extensão

Novos módulos precisam definir ID estável, wave de descoberta, família e quantidade de peças, comportamento de combate, apresentação visual e testes de migração, compra única e equipamento.
