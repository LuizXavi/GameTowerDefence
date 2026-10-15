class_name DamageNumbers
extends RefCounted
## Gerenciador de números de dano flutuantes (Floating Combat Text) com pool pré-alocado.
## Agrupa acertos simultâneos/rápidos no mesmo alvo (anti-spam), colore por elemento
## e formata valores com NumberFormat. Suporta texto contextual ("FRACO!", "RESISTE").

class DamageEntry:
	var active: bool = false
	var target_id: int = -1
	var position: Vector2 = Vector2.ZERO
	var value: float = 0.0
	var text: String = ""
	var extra_text: String = ""
	var color: Color = Color.WHITE
	var is_crit: bool = false
	var life: float = 0.0
	var max_life: float = 0.70
	var scale: float = 1.0
	var velocity_y: float = -42.0

var pool: Array[DamageEntry] = []
var max_active: int = 45
var aggregation_window: float = 0.08
var enabled: bool = true

func _init(max_count: int = 45) -> void:
	max_active = max_count
	var cfg: Dictionary = GameData.DAMAGE_NUMBER_CONFIG if "DAMAGE_NUMBER_CONFIG" in GameData else {}
	if not cfg.is_empty():
		max_active = int(cfg.get("max_active", max_active))
		aggregation_window = float(cfg.get("aggregation_window", 0.08))
	for i in max_active:
		pool.append(DamageEntry.new())

func spawn_number(target_id: int, pos: Vector2, amount: float, damage_type: String = "plasma", is_crit: bool = false, extra: String = "") -> void:
	if not enabled or amount <= 0.0:
		return

	# Agregação rápida no mesmo alvo se já houver um número ativo recente
	for entry in pool:
		if entry.active and entry.target_id == target_id and (entry.max_life - entry.life) <= aggregation_window:
			entry.value += amount
			entry.text = NumberFormat.format_int(roundi(entry.value))
			if is_crit:
				entry.is_crit = true
				entry.scale = 1.40
				entry.color = get_color_for_type(damage_type, true)
			if not extra.is_empty():
				entry.extra_text = extra
			return

	# Busca slot inativo
	var chosen: DamageEntry = null
	for entry in pool:
		if not entry.active:
			chosen = entry
			break

	# Se todas estiverem ativas, reutiliza a mais antiga
	if chosen == null:
		var oldest_life: float = INF
		for entry in pool:
			if entry.life < oldest_life:
				oldest_life = entry.life
				chosen = entry

	if chosen == null:
		return

	chosen.active = true
	chosen.target_id = target_id
	chosen.position = pos + Vector2(randf_range(-8.0, 8.0), randf_range(-4.0, 4.0))
	chosen.value = amount
	chosen.text = NumberFormat.format_int(roundi(amount))
	chosen.extra_text = extra
	chosen.is_crit = is_crit
	chosen.color = get_color_for_type(damage_type, is_crit)
	chosen.max_life = 0.70
	chosen.life = chosen.max_life
	chosen.scale = 1.35 if is_crit else 1.0
	chosen.velocity_y = -50.0 if is_crit else -38.0

func get_color_for_type(type_name: String, is_crit: bool) -> Color:
	if is_crit:
		return Color("ff2bd6")
	var cfg: Dictionary = GameData.DAMAGE_NUMBER_CONFIG if "DAMAGE_NUMBER_CONFIG" in GameData else {}
	var colors: Dictionary = cfg.get("colors", {})
	if colors.has(type_name):
		return colors[type_name]
	return Color.WHITE

func update(delta: float) -> void:
	for entry in pool:
		if not entry.active:
			continue
		entry.life -= delta
		if entry.life <= 0.0:
			entry.active = false
			continue
		entry.position.y += entry.velocity_y * delta
		if entry.scale > 1.0:
			entry.scale = maxf(1.0, entry.scale - delta * 2.0)

func clear() -> void:
	for entry in pool:
		entry.active = false

func get_active_count() -> int:
	var count := 0
	for entry in pool:
		if entry.active:
			count += 1
	return count
