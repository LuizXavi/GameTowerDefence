# SKILL: Renderização Vetorial e Procedural (2D)

## Alta Performance em _draw()
1. **Uso de _draw():** Centralize renderização de geometria procedural no método `_draw()` e atualize com `queue_redraw()` no `_process()`.
2. **Evite Lixo de Memória:** Não crie novos arrays complexos ou dicionários a cada frame dentro do `_draw()`. Reaproveite variáveis de estado.
3. **Batching Visual:** Agrupe chamadas visuais (como `draw_circle`, `draw_line`, `draw_colored_polygon`) em arrays estáticos quando a geometria base dos inimigos ou torres for constante.
4. **Efeitos Temporários (VFX):** Gerencie partículas e textos flutuantes iterando sobre arrays leves de dicionários com chaves de posição (`p`), velocidade (`v`), tempo de vida (`life`) e cor (`color`).
