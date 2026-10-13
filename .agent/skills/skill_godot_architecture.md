# SKILL: Arquitetura Godot 4 e GDScript

## Diretrizes de Código
1. **Tipagem Estática Obrigatória:** Toda variável, parâmetro e retorno de função deve ter tipo explícito.
   - *Certo:* `var clock: float = 0.0`, `func update_time(dt: float) -> void:`
   - *Errado:* `var clock = 0.0`, `func update_time(dt):`
2. **Desacoplamento por Signals:** Filhos emitem sinais (`emit_signal`), pais chamam métodos. Não acesse nós pais diretamente via `get_parent()` para lógica de jogo.
3. **Gerenciamento de Nós:** Evite usar `get_node()` ou `$` dentro da função `_process()`. Armazene a referência na inicialização (`_ready()`).
4. **Instanciação Segura:** Use `preload()` para cenas estáticas conhecidas em tempo de compilação.
