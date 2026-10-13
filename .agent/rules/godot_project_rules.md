# Neon Void - Diretrizes do Projeto Godot 4 & GDScript

## Princípios Arquiteturais Obrigatórios
1. **Tipagem Estática Total:** Toda variável, argumento de função e tipo de retorno deve ser explicitamente tipado (ex: `func tick(dt: float) -> void:`).
2. **Separação de Camadas:**
   - Telas de UI não gerenciam dados diretamente; consultam `VoidState` ou `SaveStore`.
   - Modificações na persistência precisam incrementar o `SCHEMA_VERSION` e fornecer blocos seguros na função `migrate()` em `SaveStore`.
3. **Renderização de Alto Desempenho:**
   - Todo efeito néon e geométrico procedural no nó Arena usa `_draw()`.
   - Evitar alocações desnecessárias de coleções pesadas dentro do `_process()` ou `_draw()`.
4. **Áudio Procedural:**
   - Novos efeitos sonoros devem ser preferencialmente implementados como sintetizadores de onda PCM em `SoundManager`, mantendo zero dependência de arquivos externos.
5. **Notação Incremental:**
   - Todas as exibições de pontuação, ouro e DPS devem ser roteadas por `NumberFormat.format()` ou `NumberFormat.format_int()`.
