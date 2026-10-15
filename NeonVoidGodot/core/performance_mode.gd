extends Node
## Autoload e gerenciador do Modo Performance do Neon Void.
## Quando ativo:
## - Desliga halos decorativos externos dos _draw() (usar só traço principal)
## - Reduz partículas a 0 ou flash curto
## - Limita taxa de quadros (FPS cap) em 60
## - Desliga animações de pulso
## - Reduz pool de projéteis e hit stops

signal mode_changed(enabled: bool)

static var instance: Node = null

var enabled: bool = false:
	set(val):
		enabled = val
		_apply_performance_mode()
		mode_changed.emit(enabled)

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	_apply_performance_mode()

func toggle() -> bool:
	enabled = not enabled
	return enabled

func _apply_performance_mode() -> void:
	if enabled:
		Engine.max_fps = 60
	else:
		Engine.max_fps = 0

static func is_enabled() -> bool:
	return instance != null and instance.enabled
