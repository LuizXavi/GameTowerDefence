---
name: neon-visuals
description: Guia de padrões para design gráfico cyberpunk neon, desenho de ícones com chamadas vetoriais 2D (NeonIcons), paletas e responsividade.
---

# Skill: Neon Visuals Runbook

Padrões de design visual e identidade para Neon Void.

## 1. Paleta de Cores Obrigatória
| Nome | Hex | Aplicação Primária |
| :--- | :--- | :--- |
| **Ciano** | `#00ffff` | Escudos, slots de hangar, botões de ação primária |
| **Rosa Choque** | `#ff007f` | Ataque, módulos ofensivos, perigo, elites |
| **Limão Elétrico** | `#39ff14` | Economia, status positivo, conclusão de pesquisa |
| **Âmbar** | `#ffb703` | Fragmentos, alertas, aviso de custo |
| **Roxo Profundo** | `#140b29` | Fundo de painéis e caixas |
| **Borda Neon** | `#8b5cf6` | Bordas e divisores com brilho |

## 2. Desenho Vetorial de Ícones em `NeonIcons`
- **Zero Emojis de Sistema**: NUNCA usar caracteres unicode/emojis como substitutos de ícones na UI (ex: 🔬, ⚔, 🛡).
- **Zero Imagens Bitmap Rasas**: Ícones do sistema devem ser puramente procedurais.
- Todos os ícones devem ser implementados com métodos em `NeonIcons`:
  - `draw_ui(canvas, icon_id, size, center, color)`: Ícones de status, abas e atributos (mira, escudo, laboratório, economia, radar, cadência, etc.).
  - `draw_piece_icon(canvas, kind, size, center)`: Ícones geométricos dos fragmentos (quadrado ciano, triângulo rosa, hexágono limão, núcleo de plasma âmbar).
  - `draw_tower(canvas, module_id, size, center)`: Ícones técnicos das torretas do hangar.
  - `draw_enemy(canvas, enemy_id)`: Silhuetas e variantes no Codex de inimigos.
- Linhas com espessura de 1.2 a 2.4 com `antialiased = true`, halo neon escuro e núcleos luminosos com a paleta oficial.
