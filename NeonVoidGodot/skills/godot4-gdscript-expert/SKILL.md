---
name: godot4-gdscript-expert
description: Padrões avançados de arquitetura e boas práticas de GDScript para Godot 4.7
---

# Godot 4.7 GDScript Expert Skill

## Regras de Tipagem e Performance
1. **Tipagem Estrita Segura**:
   - Em Godot 4.7, evite inferência estrita (`:=`) com valores de Dictionaries sem cast ou tipo explícito.
   - Use declarações com tipo explícito: `var cur_hp: float = enemy.get("hp", 0.0)`.
2. **Otimização de Renderização Vetorial**:
   - Utilize chamadas nativas de `draw_polyline`, `draw_polygon` e `draw_arc` com espessura controlada.
   - Sempre limite arrays de partículas dinâmicas (`max 400`) para manter 60 FPS contínuos em Web/Desktop.
3. **Gerenciamento de Entidades e Memória**:
   - Para pools de projéteis e partículas, utilize arrays circulares ou reuso de slots.
   - Conecte sinais com referências diretas (`callable`) sem strings para evitar memory leaks.
