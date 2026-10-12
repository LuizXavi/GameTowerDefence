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
| `plasma` | Torre Plasma | Inicial | Gratuita | 100% do dano automático em um alvo. Ativa Choque Térmico (+45% dano) em alvos desacelerados. |
| `cryo` | Torre Criogênica | Wave 5 | 8 fragmentos triangulares | 75% do dano e reduz o movimento do alvo em 35% por 1,5 segundo. |
| `arc` | Torre de Arco | Wave 10 | 12 fragmentos quadrados | 65% do dano no alvo e até dois saltos (até 4 saltos e 1.5x alcance se alvo estiver eletrizado). |
| `pulse` | Torre Sísmica | Wave 15 | 14 ligas hexagonais | Onda radial expansiva com knockback vertical (empurra inimigos) e aplica carga estática. |
| `laser` | Laser Antimatéria | Wave 20 | 4 núcleos de boss | Feixe contínuo que rampa de 50% até 350% de dano enquanto focado no alvo. |

O Arco procura o próximo alvo em até 160 pixels (240 pixels em tempestade estática). Fantasmas intangíveis não podem ser alvejados nem receber saltos. Resistências continuam sendo calculadas pelo gameplay.

## Sinergias elementais (Reações em Cadeia)

- **Choque Térmico (Criogênica + Plasma):** Inimigos desacelerados por gelo recebem +45% de dano adicional de tiros de Plasma.
- **Tempestade Estática (Sísmica + Arco):** Inimigos atingidos pela onda sísmica ficam eletrizados; arcos elétricos saltam para até 4 alvos com 50% mais alcance.
- **Ponto de Ruptura (Criogênica + Laser):** O Laser Antimatéria ganha +35% de dano extra em alvos congelados.

## Persistência

O schema 6 acrescenta suporte aos novos módulos mantendo compatibilidade com schemas 1 a 5:

```json
{
  "highest_wave": 1,
  "tower_modules": {
    "plasma": true,
    "cryo": false,
    "arc": false,
    "pulse": false,
    "laser": false
  },
  "unlocked_tower_slots": 1,
  "tower_loadout": ["plasma", "plasma", "plasma", "plasma", "plasma", "plasma", "plasma"]
}
```

## Extensão

Novos módulos precisam definir ID estável, wave de descoberta, família e quantidade de peças, comportamento de combate, apresentação visual e testes de migração, compra única e equipamento.
