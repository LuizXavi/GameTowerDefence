class_name ScreenShake
extends RefCounted
## Componente reutilizável de Screen Shake do Neon Void.
## Suporta intensidades parametrizadas por evento (crítico, nova, abate de chefe, dano na base),
## soma cumulativa limitada a um teto máximo e decaimento exponencial suave.
## Respeita a opção "Reduzir tremores" do jogador.

var current_intensity: float = 0.0
var max_intensity: float = 18.0
var decay_rate: float = 20.0
var enabled: bool = true
var offset: Vector2 = Vector2.ZERO

func _init(max_int: float = 18.0, decay: float = 20.0) -> void:
	max_intensity = max_int
	decay_rate = decay
	var cfg: Dictionary = GameData.SCREEN_SHAKE_CONFIG if "SCREEN_SHAKE_CONFIG" in GameData else {}
	if not cfg.is_empty():
		max_intensity = float(cfg.get("max_intensity", max_intensity))
		decay_rate = float(cfg.get("decay_rate", decay_rate))

func add_trauma(intensity: float) -> void:
	if not enabled or intensity <= 0.0:
		return
	current_intensity = minf(max_intensity, current_intensity + intensity)

func add_event_shake(event_type: String, custom_intensity: float = -1.0) -> void:
	if not enabled:
		return
	var intensity: float = custom_intensity
	if intensity < 0.0:
		var cfg: Dictionary = GameData.SCREEN_SHAKE_CONFIG if "SCREEN_SHAKE_CONFIG" in GameData else {}
		var evt_cfg: Variant = cfg.get(event_type)
		if evt_cfg is Dictionary:
			intensity = float(evt_cfg.get("intensity", 3.0))
		else:
			intensity = 3.0
	add_trauma(intensity)

func shake_critical() -> void:
	add_event_shake("critical")

func shake_nova() -> void:
	add_event_shake("nova")

func shake_boss_defeat() -> void:
	add_event_shake("boss_defeat")

func shake_base_hit() -> void:
	add_event_shake("base_hit")

func update(delta: float) -> Vector2:
	if not enabled or current_intensity <= 0.001:
		current_intensity = 0.0
		offset = Vector2.ZERO
		return Vector2.ZERO
	current_intensity = maxf(0.0, current_intensity - decay_rate * delta)
	var angle: float = randf() * TAU
	offset = Vector2(cos(angle), sin(angle)) * current_intensity
	return offset

func stop() -> void:
	current_intensity = 0.0
	offset = Vector2.ZERO

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		stop()
