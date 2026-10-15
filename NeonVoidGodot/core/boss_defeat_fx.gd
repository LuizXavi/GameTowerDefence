class_name BossDefeatFX
extends RefCounted
## Gerenciador cinematográfico ao abater Chefes do Neon Void.
## Executa sequência telegrafada:
## 1. Hit-stop (2-3 frames, ~0.05s)
## 2. Slow-motion dramático (time_scale reduzido)
## 3. Zoom suave na posição do Boss com recuperação contínua
##
## Proteção obrigatória: Engine.time_scale e zoom NUNCA ficam travados.
## Respeita a opção "Reduzir efeitos" do SaveStore.

var active: bool = false
var elapsed: float = 0.0
var phase: int = 0 # 0: inativo, 1: hit-stop, 2: slow-mo, 3: restauração
var current_zoom: float = 1.0
var target_zoom: float = 1.0
var focus_pos: Vector2 = Vector2.ZERO
var hit_stop_duration: float = 0.05
var slowmo_duration: float = 0.45
var slowmo_scale: float = 0.35
var zoom_max: float = 1.08

func _init() -> void:
	var cfg: Dictionary = GameData.BOSS_DEFEAT_VFX if "BOSS_DEFEAT_VFX" in GameData else {}
	if not cfg.is_empty():
		hit_stop_duration = float(cfg.get("hit_stop_duration", 0.05))
		slowmo_duration = float(cfg.get("slowmo_duration", 0.45))
		slowmo_scale = float(cfg.get("slowmo_time_scale", 0.35))
		zoom_max = float(cfg.get("zoom_scale", 1.08))

func trigger(boss_pos: Vector2, reduce_effects: bool = false) -> bool:
	if reduce_effects:
		reset()
		return false
	reset()
	active = true
	phase = 1
	elapsed = 0.0
	focus_pos = boss_pos
	Engine.time_scale = 0.05
	current_zoom = 1.0
	target_zoom = zoom_max
	return true

func update(unscaled_dt: float) -> void:
	if not active:
		return
	elapsed += unscaled_dt
	if phase == 1:
		if elapsed >= hit_stop_duration:
			phase = 2
			elapsed = 0.0
			Engine.time_scale = slowmo_scale
	elif phase == 2:
		var t: float = clampf(elapsed / maxf(0.01, slowmo_duration), 0.0, 1.0)
		current_zoom = lerpf(1.0, zoom_max, t)
		if elapsed >= slowmo_duration:
			phase = 3
			elapsed = 0.0
	elif phase == 3:
		var return_dur: float = 0.25
		var t: float = clampf(elapsed / return_dur, 0.0, 1.0)
		current_zoom = lerpf(zoom_max, 1.0, t)
		Engine.time_scale = lerpf(slowmo_scale, 1.0, t)
		if elapsed >= return_dur:
			reset()

func reset() -> void:
	active = false
	phase = 0
	elapsed = 0.0
	current_zoom = 1.0
	Engine.time_scale = 1.0

func get_zoom_transform(screen_size: Vector2) -> Transform2D:
	if not active or is_equal_approx(current_zoom, 1.0):
		return Transform2D.IDENTITY
	var pivot: Vector2 = focus_pos if focus_pos != Vector2.ZERO else (screen_size * 0.5)
	var xform := Transform2D()
	xform = xform.translated(-pivot)
	xform = xform.scaled(Vector2(current_zoom, current_zoom))
	xform = xform.translated(pivot)
	return xform
