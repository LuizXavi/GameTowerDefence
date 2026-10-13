class_name EnemySpawner
extends RefCounted
## Responsável pelo spawn de inimigos, elites, chefes e habilidades especiais inimigas (tiro, teleporte, invocação).

const COLORS := GameData.ENEMY_COLORS
const FAMILY_IDS := GameData.FAMILY_IDS
const ELITE_TYPES := GameData.ELITE_TYPES
const BOSS_TYPES := GameData.BOSS_TYPES

static func variant_for(wave: int, kind: int) -> String:
	var roll := randf()
	if kind == 0 and wave >= 2 and roll < 0.18:
		return "armored"
	if kind == 0 and wave >= 3 and roll < 0.30:
		return "splitter"
	if kind == 1 and wave >= 3 and roll < 0.18:
		return "ghost"
	if kind == 1 and wave >= 4 and roll < 0.30:
		return "thief"
	if kind == 2 and wave >= 4 and roll < 0.24:
		return "regen"
	return ""

static func id_for(kind: int, variant: String) -> String:
	if variant == "armored": return "armored_square"
	if variant == "ghost": return "ghost_triangle"
	if variant == "regen": return "regen_hexagon"
	if variant == "splitter": return "splitter"
	if variant == "thief": return "thief"
	if kind < FAMILY_IDS.size():
		return FAMILY_IDS[kind]
	return "square"

static func spawn(state: RefCounted, kind: int = -1, forced_variant := "", force_elite := false, allow_elite := true, legacy_force_elite := false) -> Dictionary:
	var wave: int = state.wave
	var play_time: float = state.play_time
	var bounds: Vector2 = state.bounds
	if legacy_force_elite:
		force_elite = true
		allow_elite = true
		if kind < 0:
			var elite_pool: Array[int] = [4, 5, 6, 8, 11, 13, 16, 17, 18]
			kind = elite_pool[randi() % elite_pool.size()]
	elif kind < 0:
		var roll := randf()
		if wave >= 14 and roll < 0.14:
			kind = [10, 14, 15, 19, 20][randi() % 5]
		elif wave >= 9 and roll < 0.25:
			kind = [8, 9, 12, 13, 18][randi() % 5]
		elif wave >= 5 and roll < 0.36:
			kind = [5, 6, 7, 11, 16, 17][randi() % 6]
		elif wave >= 3 and roll < 0.42:
			kind = [4, 16, 17][randi() % 3] if wave >= 4 else 4
		else:
			var tank_p := minf(0.22, 0.06 + wave * 0.012)
			kind = 2 if roll < tank_p else (1 if roll < tank_p + minf(0.4, 0.22 + wave * 0.01) else 0)

	var scale_hp := 1 + (wave - 1) * 0.55 + pow(wave - 1, 1.55) * 0.09 + play_time * 0.008
	var base_hps: Array[float] = [
		6.0, 4.0, 22.0, 160.0 * (1.0 + wave * 0.06), 14.0, 35.0,
		48.0, 26.0, 60.0, 55.0, 80.0,
		18.0, 32.0, 70.0, 95.0, 140.0,
		24.0, 20.0, 42.0, 64.0, 78.0
	]
	var health := roundi(base_hps[kind] * scale_hp)
	var speed_mults: Array[float] = [
		1.0, 1.65, 0.62, 1.0, 1.25, 0.55,
		0.75, 1.45, 0.50, 0.85, 0.45,
		1.80, 1.35, 0.60, 0.70, 0.40,
		0.82, 1.30, 0.65, 0.58, 0.95
	]
	var speed: float = (bounds.y * 0.085 + wave * 2.4) * speed_mults[kind]
	if kind == 3:
		speed = bounds.y * 0.045

	var variant := forced_variant if not forced_variant.is_empty() else variant_for(wave, kind)
	var radii: Array[float] = [
		20.0, 15.0, 27.0, 44.0, 22.0, 32.0,
		30.0, 24.0, 34.0, 31.0, 36.0,
		20.0, 25.0, 33.0, 35.0, 42.0,
		24.0, 22.0, 29.0, 33.0, 31.0
	]
	var sides_list: Array[int] = [
		4, 3, 6, 8, 5, 7,
		8, 9, 10, 11, 12,
		4, 5, 6, 12, 4,
		6, 6, 8, 10, 7
	]

	var boss_cfg: Dictionary = BOSS_TYPES[0]
	if kind == 3:
		var b_idx: int = maxi(0, int(wave / 5) - 1) % BOSS_TYPES.size()
		for i in BOSS_TYPES.size():
			if forced_variant == BOSS_TYPES[i].id:
				b_idx = i
				variant = ""
				break
		boss_cfg = BOSS_TYPES[b_idx]
		sides_list[3] = int(boss_cfg.sides)
		health = roundi(float(health) * float(boss_cfg.hp_mult))
		speed *= float(boss_cfg.speed_mult)

	var golds: Array[int] = [
		4 + wave, 3 + wave, 12 + wave * 2, 100 + wave * 12, 8 + wave * 2, 20 + wave * 3,
		24 + wave * 3, 16 + wave * 2, 35 + wave * 4, 32 + wave * 4, 45 + wave * 5,
		15 + wave * 2, 25 + wave * 3, 40 + wave * 4, 55 + wave * 6, 75 + wave * 8,
		18 + wave * 3, 20 + wave * 3, 28 + wave * 4, 38 + wave * 4, 48 + wave * 5
	]
	var leaks: Array[int] = [
		8, 5, 14, 40, 10, 18,
		19, 12, 22, 20, 28,
		11, 15, 24, 30, 38,
		14, 12, 18, 22, 26
	]
	var scores: Array[int] = [
		10, 12, 30, 300, 20, 50,
		60, 40, 90, 85, 130,
		35, 55, 110, 150, 220,
		45, 50, 75, 105, 135
	]

	var resolved_id: String = str(boss_cfg.id) if kind == 3 else id_for(kind, variant)
	var enemy := {
		"type": kind,
		"enemy_id": resolved_id,
		"variant": variant,
		"modifiers": [],
		"elite": false,
		"elite_type": "",
		"elite_name": "",
		"elite_color": Color("ffb02e"),
		"boss_id": str(boss_cfg.id) if kind == 3 else "",
		"boss_name": str(boss_cfg.name) if kind == 3 else "",
		"boss_color": boss_cfg.color if kind == 3 else COLORS[3],
		"boss_ability": str(boss_cfg.ability) if kind == 3 else "",
		"is_miniboss": false,
		"is_minion": false,
		"ghosted": false,
		"since_hit": 99.0,
		"drop_allowed": true,
		"split_depth": 0,
		"p": Vector2(bounds.x / 2 if kind == 3 else randf_range(30, bounds.x - 30), -50 if kind == 3 else -30),
		"hp": float(health),
		"max_hp": health,
		"radius": radii[kind],
		"speed": speed,
		"gold": golds[kind],
		"leak": leaks[kind],
		"score": scores[kind],
		"rot": randf() * TAU,
		"rot_speed": 0.5 if kind == 3 else randf_range(-1.6, 1.6),
		"sides": sides_list[kind],
		"wob": randf() * TAU,
		"wob_speed": 1.2 if kind == 3 else randf_range(1, 3),
		"wob_amp": 60 if kind == 3 else (randf_range(20, 45) if (kind in [1, 11, 17]) else randf_range(4, 14)),
		"hit": 0.0,
		"age": 0.0,
		"slow_timer": 0.0,
		"static_timer": 0.0,
		"can_shoot": kind in [16, 19] or variant == "shooter",
		"can_teleport": kind in [17, 20] or variant == "teleporter",
		"can_summon": kind in [18, 20] or variant == "summoner",
		"shoot_timer": 2.1 if kind == 16 else 2.5,
		"teleport_timer": 2.0,
		"summon_timer": 2.8
	}

	if kind == 3:
		var b_ab: String = str(boss_cfg.ability)
		enemy.can_shoot = b_ab in ["shooter", "teleporter_shooter", "nexus", "siege_regen", "omega"]
		enemy.can_teleport = b_ab in ["teleporter_shooter", "omega"]
		enemy.can_summon = b_ab in ["summoner_regen", "nexus", "omega"]
		if b_ab in ["summoner_regen", "siege_regen", "omega"]:
			enemy.modifiers.append("regen")
		if b_ab == "nexus":
			enemy.modifiers.append("phase")
		enemy.shoot_timer = 2.2
		enemy.teleport_timer = 3.2
		enemy.summon_timer = 3.4

	if variant == "armored":
		enemy.max_hp = roundi(enemy.max_hp * 1.6)
		enemy.hp = float(enemy.max_hp)
	if variant == "thief":
		enemy.speed *= 1.12
		enemy.gold = roundi(enemy.gold * 1.5)
	if variant == "splitter":
		enemy.max_hp = roundi(enemy.max_hp * 1.3)
		enemy.hp = float(enemy.max_hp)

	var forced_elite_archetype := ""
	for e_cfg in ELITE_TYPES:
		if forced_variant == str(e_cfg.id):
			forced_elite_archetype = str(e_cfg.id)
			enemy.variant = ""
			enemy.enemy_id = id_for(kind, "")
			force_elite = true
			break

	var becomes_elite := allow_elite and kind != 3 and (force_elite or (wave >= 4 and randf() < minf(0.18, 0.04 + wave * 0.008)))
	if becomes_elite:
		apply_elite(enemy, forced_elite_archetype)
	state.enemies.append(enemy)
	state.enemy_discovered.emit(enemy.enemy_id)
	if kind == 3 and enemy.boss_id != "boss":
		state.enemy_discovered.emit("boss")
	if enemy.elite:
		state.enemy_discovered.emit("elite")
		if not str(enemy.elite_type).is_empty():
			state.enemy_discovered.emit(str(enemy.elite_type))
	return enemy

static func apply_elite(enemy: Dictionary, forced_elite_type := "") -> void:
	enemy.elite = true
	var chosen_cfg: Dictionary = ELITE_TYPES[randi() % ELITE_TYPES.size()]
	if not forced_elite_type.is_empty():
		for e_cfg in ELITE_TYPES:
			if str(e_cfg.id) == forced_elite_type:
				chosen_cfg = e_cfg
				break
	enemy.elite_type = str(chosen_cfg.id)
	enemy.elite_name = str(chosen_cfg.name)
	enemy.elite_color = chosen_cfg.color
	enemy.max_hp = roundi(enemy.max_hp * float(chosen_cfg.hp_mult))
	enemy.hp = float(enemy.max_hp)
	enemy.gold = roundi(enemy.gold * 2.2)
	enemy.score = roundi(enemy.score * 2.2)
	enemy.radius *= 1.22
	enemy.speed *= float(chosen_cfg.speed_mult)
	enemy.modifiers = chosen_cfg.mods.duplicate()
	if enemy.modifiers.has("shooter"):
		enemy.can_shoot = true
	if enemy.modifiers.has("teleporter"):
		enemy.can_teleport = true
	if enemy.modifiers.has("summoner"):
		enemy.can_summon = true

static func shoot_from_enemy(state: RefCounted, enemy: Dictionary) -> void:
	if not state.running or state.paused:
		return
	var salvo := 1
	if enemy.type == 3:
		salvo = 3
	elif enemy.type == 19:
		salvo = 2
	var p_color: Color = enemy.get("boss_color", COLORS[enemy.type]) if enemy.type == 3 else (enemy.get("elite_color", COLORS[enemy.type]) if enemy.elite else COLORS[enemy.type])
	for i in salvo:
		var spread_offset: float = 0.0
		if salvo == 2:
			spread_offset = -55.0 if i == 0 else 55.0
		elif salvo == 3:
			spread_offset = float(i - 1) * 85.0
		var target_x: float = clampf(enemy.p.x + spread_offset, 36.0, state.bounds.x - 36.0)
		var target_pos := Vector2(target_x, state.bounds.y - 30.0)
		var dir: Vector2 = (target_pos - enemy.p).normalized()
		if dir.length_squared() < 0.01:
			dir = Vector2.DOWN
		state.enemy_projectiles.append({
			"p": enemy.p + dir * (enemy.radius + 6.0),
			"v": dir * (225.0 + minf(110.0, state.wave * 3.0)),
			"radius": 6.5 if enemy.type == 3 else 5.0,
			"damage": 4 if enemy.type == 3 else (3 if enemy.type == 19 else 2),
			"color": p_color,
			"age": 0.0
		})
	state.effect.emit("text", enemy.p - Vector2(0, enemy.radius + 14), p_color, "DISPARO!")

static func teleport_enemy(state: RefCounted, enemy: Dictionary) -> void:
	if not state.running or state.paused:
		return
	var old_p: Vector2 = enemy.p
	var margin: float = maxf(36.0, enemy.radius + 16.0)
	var new_x: float = randf_range(margin, maxf(margin + 10.0, state.bounds.x - margin))
	if absf(new_x - old_p.x) < 70.0:
		new_x = clampf(old_p.x + (120.0 if old_p.x < state.bounds.x * 0.5 else -120.0), margin, maxf(margin + 10.0, state.bounds.x - margin))
	var advance_y: float = 24.0 if enemy.type == 3 else 34.0
	enemy.p = Vector2(new_x, minf(state.bounds.y - 80.0, old_p.y + advance_y))
	var t_color: Color = enemy.get("boss_color", COLORS[enemy.type]) if enemy.type == 3 else COLORS[enemy.type]
	state.effect.emit("ring", old_p, t_color, "")
	state.effect.emit("burst", enemy.p, t_color, "TELEPORTE!")
	if enemy.type == 20:
		var rift_minion := spawn_minions(state, enemy, 1)
		if not rift_minion.is_empty():
			rift_minion[0].p = old_p

static func spawn_minions(state: RefCounted, parent: Dictionary, count: int = 2) -> Array[Dictionary]:
	var spawned: Array[Dictionary] = []
	if not state.running or state.paused:
		return spawned
	for i in count:
		var side_dir: float = -1.0 if (i % 2 == 0) else 1.0
		var m := spawn(state, 1, "minion", false, false)
		m.enemy_id = "triangle"
		m.variant = "minion"
		m.is_minion = true
		m.elite = false
		m.modifiers = []
		m.can_shoot = false
		m.can_teleport = false
		m.can_summon = false
		m.split_depth = 1
		m.drop_allowed = false
		m.radius = 10.5
		m.max_hp = maxi(2, roundi(parent.max_hp * (0.06 if parent.type == 3 else 0.16)))
		m.hp = float(m.max_hp)
		m.gold = maxi(1, roundi(parent.gold * 0.10))
		m.score = maxi(1, roundi(parent.score * 0.12))
		m.leak = 2
		m.speed = maxf(state.bounds.y * 0.12, parent.speed * 1.45)
		m.p = Vector2(clampf(parent.p.x + side_dir * (parent.radius + 14.0 + i * 6.0), 24.0, state.bounds.x - 24.0), parent.p.y + 10.0)
		spawned.append(m)
	var s_color: Color = parent.get("boss_color", COLORS[parent.type]) if parent.type == 3 else COLORS[parent.type]
	state.effect.emit("burst", parent.p, s_color, "LACAIOS!")
	return spawned

static func spawn_split_children(state: RefCounted, parent: Dictionary) -> void:
	for direction in [-1, 1]:
		var child := spawn(state, 0, "child", false, false)
		child.enemy_id = "square"
		child.variant = ""
		child.elite = false
		child.modifiers = []
		child.split_depth = 1
		child.drop_allowed = false
		child.radius = 11.0
		child.max_hp = maxi(1, roundi(parent.max_hp * 0.28))
		child.hp = float(child.max_hp)
		child.gold = maxi(1, roundi(parent.gold * 0.2))
		child.score = maxi(1, roundi(parent.score * 0.25))
		child.leak = 3
		child.speed = parent.speed * 1.25
		child.p = parent.p + Vector2(direction * 14, 0)
