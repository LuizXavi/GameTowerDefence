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
Nunca use imagens bitmap rasas (.png) para ícones do sistema que destoem do estilo vetorial neon.
Todos os novos ícones devem ser implementados com métodos em `NeonIcons`:
- `draw_ui(canvas, icon_id, size, center, color)`
- `draw_tower(canvas, module_id, size, center)`
- Linhas com espessura de 1.8 a 2.4 com `antialiased = true`.
