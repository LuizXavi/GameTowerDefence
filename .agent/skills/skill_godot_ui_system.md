# SKILL: Interface de Usuário (Control Nodes) Godot 4

## Criação e Responsividade
1. **Layouts Dinâmicos:** Use `VBoxContainer`, `HBoxContainer`, e `GridContainer` com `add_theme_constant_override` para separação. Não use posições absolutas.
2. **Ancoragem Automática:** Para preencher a tela, utilize `set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)`.
3. **Instanciação Dinâmica (UIFactory):** Ao criar UI por código, siga o padrão de fábrica do projeto (ex: `UIFactory.label()`, `UIFactory.button()`) para garantir consistência de fonte e tema.
4. **Tratamento de Foco:** Ao lidar com modais e menus operados por teclado/gamepad, garanta que o foco seja devolvido ao controle anterior ao fechar (`modal_return_focus`).
