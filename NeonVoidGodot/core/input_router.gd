extends Node
## Autoload de roteamento central de atalhos de teclado do Neon Void.
## Suporta mapeamento padrão com detecção e debounce, ignorando teclas em LineEdit/TextEdit.
##
## Padrões:
## Espaço    -> pause / retomar
## 1 / 2 / 3 -> velocidade 1x / 2x / 4x
## L         -> abrir/fechar Laboratório
## H         -> abrir/fechar Hangar (Módulos)
## C         -> abrir/fechar Codex
## A         -> abrir/fechar Conquistas
## Esc       -> fechar modal atual
## F1        -> toggle modo performance
## F2        -> toggle reduzir screen shake / flash

signal shortcut_triggered(action: StringName)

static var instance: Node = null

func _enter_tree() -> void:
	instance = self

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return

	# Ignora atalhos globais se um controle de texto estiver com foco ativo
	var viewport := get_viewport()
	if is_instance_valid(viewport):
		var focus_owner := viewport.gui_get_focus_owner()
		if focus_owner is LineEdit or focus_owner is TextEdit:
			return

	var key_event := event as InputEventKey
	var code := key_event.keycode

	match code:
		KEY_SPACE:
			shortcut_triggered.emit(&"toggle_pause")
		KEY_1:
			shortcut_triggered.emit(&"speed_1x")
		KEY_2:
			shortcut_triggered.emit(&"speed_2x")
		KEY_3:
			shortcut_triggered.emit(&"speed_4x")
		KEY_L:
			shortcut_triggered.emit(&"toggle_research")
		KEY_H:
			shortcut_triggered.emit(&"toggle_modules")
		KEY_C:
			shortcut_triggered.emit(&"toggle_codex")
		KEY_A:
			shortcut_triggered.emit(&"toggle_achievements")
		KEY_ESCAPE:
			shortcut_triggered.emit(&"close_modal")
		KEY_F1:
			shortcut_triggered.emit(&"toggle_performance")
		KEY_F2:
			shortcut_triggered.emit(&"toggle_accessibility_effects")
