extends Node
## Autoload e serviço central de acessibilidade do Neon Void.
## Gerencia escala de UI, modos para daltonismo (protanopia, deuteranopia, tritanopia),
## redução de flashes/explosões, remoção de tremores de tela e redução de movimento/senóides decorativas.

signal settings_changed()

enum ColorBlindMode {
	NONE = 0,
	PROTANOPIA = 1,
	DEUTERANOPIA = 2,
	TRITANOPIA = 3
}

static var instance: Node = null

var ui_scale: float = 1.0:
	set(val):
		ui_scale = clampf(val, 0.75, 1.5)
		_apply_ui_scale()

var color_blind_mode: int = ColorBlindMode.NONE:
	set(val):
		color_blind_mode = val
		settings_changed.emit()

var reduce_flash: bool = false:
	set(val):
		reduce_flash = val
		settings_changed.emit()

var reduce_shake: bool = false:
	set(val):
		reduce_shake = val
		settings_changed.emit()

var reduce_motion: bool = false:
	set(val):
		reduce_motion = val
		settings_changed.emit()

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	_apply_ui_scale()

func _apply_ui_scale() -> void:
	var tree := get_tree()
	if is_instance_valid(tree) and is_instance_valid(tree.root):
		tree.root.content_scale_factor = ui_scale

static func remap_color(col: Color) -> Color:
	if instance == null or instance.color_blind_mode == ColorBlindMode.NONE:
		return col

	var r: float = col.r
	var g: float = col.g
	var b: float = col.b
	var a: float = col.a

	match instance.color_blind_mode:
		ColorBlindMode.PROTANOPIA:
			# Redução / deficiência no canal vermelho: remapeia espectro vermelho/verde para amarelo/azul
			var new_r: float = 0.56667 * r + 0.43333 * g
			var new_g: float = 0.55833 * r + 0.44167 * g
			var new_b: float = 0.24167 * g + 0.75833 * b
			return Color(new_r, new_g, new_b, a)
		ColorBlindMode.DEUTERANOPIA:
			# Redução / deficiência no canal verde
			var new_r: float = 0.625 * r + 0.375 * g
			var new_g: float = 0.70 * r + 0.30 * g
			var new_b: float = 0.30 * g + 0.70 * b
			return Color(new_r, new_g, new_b, a)
		ColorBlindMode.TRITANOPIA:
			# Redução no canal azul
			var new_r: float = 0.95 * r + 0.05 * g
			var new_g: float = 0.43333 * g + 0.56667 * b
			var new_b: float = 0.475 * g + 0.525 * b
			return Color(new_r, new_g, new_b, a)
		_:
			return col

static func is_reduce_flash() -> bool:
	return instance != null and instance.reduce_flash

static func is_reduce_shake() -> bool:
	return instance != null and instance.reduce_shake

static func is_reduce_motion() -> bool:
	return instance != null and instance.reduce_motion
