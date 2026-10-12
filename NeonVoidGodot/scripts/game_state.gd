class_name VoidState
extends RefCounted

signal effect(kind: String, position: Vector2, color: Color, text: String)
signal sound(kind: String)
signal ended
signal piece_dropped(kind: int, amount: int, position: Vector2, enemy_id: String, from_elite: bool)
signal enemy_discovered(enemy_id: String)
signal enemy_defeated(enemy_id: String, at_wave: int)

const COLORS = [Color("ff2bd6"), Color("22e6ff"), Color("b6ff2e"), Color("ffb02e")]
const FAMILY_IDS = ["square", "triangle", "hexagon", "boss"]
const ELITE_MODIFIERS = ["armor", "haste", "regen", "phase"]
const TOWER_MODULE_IDS = ["plasma", "cryo", "arc", "pulse", "laser"]
const MAX_TOWER_SLOTS := 7
const AUTO_INTERVAL := 0.28
const ARC_CHAIN_RADIUS := 160.0
const CRYO_SLOW_DURATION := 1.5
const CRYO_SLOW_STRENGTH := 0.35
const PULSE_INTERVAL := 2.5
const PULSE_KNOCKBACK_FORCE := 38.0
var tower_module: String = "plasma"

func interval_for_module(module_id: String) -> float:
	if module_id == "pulse":
		return PULSE_INTERVAL
	return AUTO_INTERVAL
var tower_loadout: Array[String] = ["plasma"]
var tower_slots: Array[Dictionary] = []
var gold: int = 0
var total_gold: int = 0
var score: int = 0
var kills: int = 0
var wave: int = 1
var wave_kills: int = 0
var hp: int = 100
var max_hp: int = 100
var levels: Array = [0, 0, 0, 0]
var combo: int = 0
var max_combo: int = 0
var combo_timer: float = 0
var charge: float = 20
var play_time: float = 0
var spawn_timer: float = 0.2
var auto_timer: float:
	get: return tower_slots[0].auto_timer
	set(value): tower_slots[0].auto_timer = value
var enemies: Array[Dictionary] = []
var bounds := Vector2(980, 728)
var running := false
var paused := false
var banner := "WAVE 1"
var banner_time: float = 1.6
var turret_angle: float:
	get: return tower_slots[0].turret_angle
	set(value): tower_slots[0].turret_angle = value
var turret_target: float:
	get: return tower_slots[0].turret_target
	set(value): tower_slots[0].turret_target = value
var beam_target: Vector2:
	get: return tower_slots[0].beam_target
	set(value): tower_slots[0].beam_target = value
var beam_time: float:
	get: return tower_slots[0].beam_time
	set(value): tower_slots[0].beam_time = value
var beam_chain: Array[Vector2]:
	get: return tower_slots[0].beam_chain
	set(value): tower_slots[0].beam_chain = value
var research: Array[int] = [0, 0, 0, 0]
var run_pieces: Array[int] = [0, 0, 0, 0]

func _init() -> void:
	_reset_tower_slots()

func configure_tower_module(id: String) -> void:
	configure_tower_loadout([id])

func configure_tower_loadout(ids: Array) -> void:
	var configured: Array[String] = []
	for id in ids.slice(0, MAX_TOWER_SLOTS):
		configured.append(str(id) if id in TOWER_MODULE_IDS else "plasma")
	if configured.is_empty():
		configured.append("plasma")
	tower_loadout = configured
	tower_module = tower_loadout[0]
	_reset_tower_slots()

func _reset_tower_slots() -> void:
	tower_slots.clear()
	for i in tower_loadout.size():
		var chain: Array[Vector2] = []
		var mid: String = tower_loadout[i]
		var cadence := interval_for_module(mid)
		tower_slots.append({
			"module_id": mid,
			"auto_timer": cadence * (float(i) / maxf(1.0, float(tower_loadout.size()))),
			"turret_angle": -PI / 2,
			"turret_target": -PI / 2,
			"beam_target": Vector2.ZERO,
			"beam_time": 0.0,
			"beam_chain": chain,
			"pulse_time": 0.0,
			"pulse_ring": 0.0,
			"laser_focus_time": 0.0,
			"laser_target_id": ""
		})

func tower_position(slot_index: int) -> Vector2:
	return Vector2(bounds.x * (slot_index + 1.0) / (tower_slots.size() + 1.0), bounds.y - 40)

func configure_research(levels: Array) -> void:
	for i in 4:
		research[i] = clampi(int(levels[i]) if i < levels.size() else 0, 0, [5, 5, 5, 3][i])

func reset() -> void:
	gold = 0
	total_gold = 0
	score = 0
	kills = 0
	wave = 1
	wave_kills = 0
	hp = 100
	max_hp = 100
	max_hp += research[2] * 10
	hp = max_hp
	levels = [0, 0, 0, 0]
	combo = 0
	max_combo = 0
	combo_timer = 0
	charge = 20
	play_time = 0
	spawn_timer = 0.2
	_reset_tower_slots()
	enemies.clear()
	running = true
	paused = false
	banner = "WAVE 1"
	banner_time = 1.6
	run_pieces = [0, 0, 0, 0]
	sound.emit("start")

func multiplier() -> float:
	return 1 + mini(combo, 60) * 0.04

func click_damage() -> int:
	return roundi((3 + research[0] + levels[0] * 3 + wave * 0.6) * multiplier())

func auto_dps() -> int:
	var level: int = levels[1]
	return roundi(level * (5 + wave * 1.4 + level * 1.6) * (1 + research[1] * 0.08))

func auto_attack(target: Dictionary, base_damage: float, module_id: String = "", slot_index: int = 0) -> void:
	if not running or paused:
		return
	if slot_index < 0 or slot_index >= tower_slots.size():
		return
	var slot := tower_slots[slot_index]
	var active_module: String = slot.module_id if module_id.is_empty() else module_id
	if active_module not in TOWER_MODULE_IDS:
		active_module = "plasma"

	if active_module == "pulse":
		# Onda Sísmica: dano radial, empurra inimigos e eletriza para tempestade estática
		slot.pulse_time = 0.4
		slot.pulse_ring = bounds.x * 0.75
		effect.emit("burst", tower_position(slot_index), Color("b6ff2e"), "ONDA SÍSMICA")
		sound.emit("bomb")
		var pulse_damage := base_damage * 1.8
		for enemy in enemies.duplicate():
			if enemy.hp <= 0 or enemy.ghosted:
				continue
			var hit_dist := tower_position(slot_index).distance_to(enemy.p)
			if hit_dist < slot.pulse_ring:
				enemy.p.y = maxf(enemy.radius + 10, enemy.p.y - PULSE_KNOCKBACK_FORCE)
				enemy.static_timer = 2.5
				damage_enemy(enemy, pulse_damage, false, "auto")
		return

	if target.is_empty() or target.hp <= 0 or target.ghosted or not enemies.has(target):
		slot.laser_target_id = ""
		slot.laser_focus_time = 0.0
		return

	slot.beam_target = target.p
	slot.beam_time = 0.16
	slot.beam_chain.clear()
	slot.turret_target = (Vector2(slot.beam_target) - tower_position(slot_index)).angle()

	var damage := base_damage

	if active_module == "cryo":
		damage *= 0.75
		target.slow_timer = CRYO_SLOW_DURATION
	elif active_module == "arc":
		damage *= 0.65
	elif active_module == "laser":
		# Laser de Antimatéria: rampa de dano mantendo o foco
		var target_key: String = str(target.get("enemy_id", "")) + "_" + str(target.get("age", 0.0))
		if slot.laser_target_id == target_key:
			slot.laser_focus_time = minf(2.0, slot.laser_focus_time + AUTO_INTERVAL)
		else:
			slot.laser_target_id = target_key
			slot.laser_focus_time = 0.0
		# Multiplicador rampa de 0.5x até 3.5x
		var ramp: float = 0.5 + (float(slot.laser_focus_time) / 2.0) * 3.0
		damage *= ramp
		# Ponto de Ruptura: acelera em inimigos congelados
		if target.get("slow_timer", 0.0) > 0:
			damage *= 1.35
			effect.emit("text", target.p - Vector2(0, target.radius + 18), Color("ff7799"), "RUPTURA!")
	elif active_module == "plasma":
		# Sinergia Choque Térmico: dano extra se alvo estiver desacelerado/congelado
		if target.get("slow_timer", 0.0) > 0:
			damage *= 1.45
			effect.emit("text", target.p - Vector2(0, target.radius + 18), Color("ff55ff"), "CHOQUE TÉRMICO!")

	var targets: Array[Dictionary] = [target]
	if active_module == "arc":
		# Sinergia Tempestade Estática: se alvo foi eletrizado por sísmica, raio salta até 4 vezes e com maior alcance
		var max_hops := 4 if target.get("static_timer", 0.0) > 0 else 2
		var chain_radius := ARC_CHAIN_RADIUS * 1.5 if target.get("static_timer", 0.0) > 0 else ARC_CHAIN_RADIUS
		var origin: Vector2 = target.p
		for hop in max_hops:
			var next: Dictionary = {}
			var closest := chain_radius * chain_radius
			for enemy in enemies:
				if enemy.hp <= 0 or enemy.ghosted or targets.has(enemy):
					continue
				var distance := origin.distance_squared_to(enemy.p)
				if distance <= closest and (next.is_empty() or distance < closest):
					next = enemy
					closest = distance
			if next.is_empty():
				break
			targets.append(next)
			origin = next.p
			slot.beam_chain.append(origin)
	for i in targets.size():
		damage_enemy(targets[i], damage * (1.0 if i == 0 else 0.45), false, "auto")

func crit_chance() -> float:
	return minf(0.05 + levels[2] * 0.045, 0.65)

func cost(key: int) -> int:
	return floori([15, 50, 90, 70][key] * pow([1.58, 1.68, 1.8, 1.72][key], levels[key]))

func quota() -> int:
	return 6 + wave * 4

func buy(key: int) -> bool:
	if not running or paused or key < 0 or key > 3:
		return false
	var price := cost(key)
	if gold < price:
		sound.emit("deny")
		return false
	gold -= price
	levels[key] += 1
	if key == 3:
		max_hp += 15
		hp = mini(max_hp, hp + 30)
		effect.emit("burst", Vector2(bounds.x / 2, bounds.y - 60), COLORS[1], "+30 ESCUDO")
	sound.emit("shield" if key == 3 else "buy")
	return true

func tap(point: Vector2) -> void:
	if not running or paused:
		return
	var target: Dictionary = {}
	var distance := INF
	var phased_target: Dictionary = {}
	for enemy in enemies:
		var d := point.distance_squared_to(enemy.p)
		if d <= pow(enemy.radius + 14, 2) and enemy.ghosted:
			phased_target = enemy
		elif d <= pow(enemy.radius + 14, 2) and d < distance:
			target = enemy
			distance = d
	if target.is_empty():
		if not phased_target.is_empty():
			effect.emit("text", phased_target.p - Vector2(0, phased_target.radius + 8), COLORS[1], "INTANGÍVEL")
			return
		combo = maxi(0, combo - 3)
		effect.emit("ring", point, Color(1, 1, 1, 0.35), "")
		return
	var critical := randf() < crit_chance()
	var damage := click_damage() * randf_range(0.9, 1.1)
	if critical:
		damage *= 3 + levels[2] * 0.25
	combo += 1
	combo_timer = 2.2
	max_combo = maxi(max_combo, combo)
	target.p.y -= 10 if critical else 5
	effect.emit("hit", point, COLORS[3] if critical else COLORS[1], "")
	damage_enemy(target, damage, critical, "click")
	sound.emit("crit" if critical else "click")
	if combo % 15 == 0:
		charge = minf(100, charge + 12)
		effect.emit("text", point - Vector2(0, 50), COLORS[2], "COMBO x%d!" % combo)

func nova() -> bool:
	if not running or paused or charge < 100:
		return false
	charge = 0
	var damage := 60 + click_damage() * 12 + wave * 12
	effect.emit("nova", bounds / 2, Color.WHITE, "PULSO NOVA!")
	sound.emit("bomb")
	for enemy in enemies.duplicate():
		damage_enemy(enemy, damage * randf_range(0.8, 1.2), false, "nova")
	return true

func damage_enemy(enemy: Dictionary, damage: float, critical := false, source := "click") -> void:
	if enemy.hp <= 0 or enemy.ghosted:
		return
	if enemy.variant == "armored" or enemy.modifiers.has("armor"):
		damage *= 1.75 if source == "auto" else (0.35 if source == "click" else 0.8)
	enemy.hp -= damage
	enemy.hit = 0.09
	enemy.since_hit = 0.0
	if source != "nova":
		effect.emit("text", enemy.p - Vector2(0, enemy.radius + 8), COLORS[3] if critical else Color.WHITE, str(roundi(damage)) + ("!" if critical else ""))
	if enemy.hp > 0:
		return
	enemies.erase(enemy)
	kills += 1
	wave_kills += 1
	var gain := roundi(enemy.gold * multiplier())
	gold += gain
	total_gold += gain
	score += roundi(enemy.score * (1 + wave * 0.15) * (1.5 if critical else 1.0))
	charge = minf(100, charge + [3.5, 3.5, 6, 30][enemy.type])
	effect.emit("burst", enemy.p, COLORS[enemy.type], "+%d" % gain)
	sound.emit("kill")
	roll_piece_drop(enemy)
	enemy_defeated.emit(enemy.enemy_id, wave)
	if enemy.elite:
		enemy_defeated.emit("elite", wave)
	if enemy.variant == "splitter" and enemy.split_depth == 0:
		spawn_split_children(enemy)
	if enemy.type == 3:
		effect.emit("nova", bounds * Vector2(0.5, 0.35), COLORS[3], "BOSS DESTRUÍDO!")
	if wave_kills >= quota():
		next_wave()

func roll_piece_drop(enemy: Dictionary, forced_roll := -1.0) -> int:
	if not enemy.drop_allowed:
		return 0
	var kind: int = int(enemy.type)
	var chance: float = [0.30, 0.22, 0.40, 1.0][kind]
	if enemy.elite:
		chance = minf(1.0, chance * 2.0)
	var roll := randf() if forced_roll < 0 else forced_roll
	if roll >= chance:
		return 0
	var amount := 2 if kind == 3 else 1
	if enemy.elite:
		amount += 1
	run_pieces[kind] += amount
	piece_dropped.emit(kind, amount, enemy.p, enemy.enemy_id, enemy.elite)
	return amount

func next_wave() -> void:
	wave += 1
	wave_kills = 0
	var bonus := 10 + wave * 6
	gold += bonus
	total_gold += bonus
	score += wave * 250
	hp = mini(max_hp, hp + 6)
	banner = ("BOSS — WAVE %d" if wave % 5 == 0 else "WAVE %d") % wave
	banner_time = 1.8
	sound.emit("wave")
	if wave % 5 == 0:
		spawn(3)

func variant_for(kind: int) -> String:
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

func id_for(kind: int, variant: String) -> String:
	if variant == "armored": return "armored_square"
	if variant == "ghost": return "ghost_triangle"
	if variant == "regen": return "regen_hexagon"
	if variant == "splitter": return "splitter"
	if variant == "thief": return "thief"
	return FAMILY_IDS[kind]

func spawn(kind: int = -1, forced_variant := "", force_elite := false, allow_elite := true) -> Dictionary:
	if kind < 0:
		var roll := randf()
		var tank_p := minf(0.22, 0.06 + wave * 0.012)
		kind = 2 if roll < tank_p else (1 if roll < tank_p + minf(0.4, 0.22 + wave * 0.01) else 0)
	var scale_hp := 1 + (wave - 1) * 0.55 + pow(wave - 1, 1.55) * 0.09 + play_time * 0.008
	var health := roundi([6, 4, 22, 160 * (1 + wave * 0.06)][kind] * scale_hp)
	var speed: float = (bounds.y * 0.085 + wave * 2.4) * [1, 1.65, 0.62, 1][kind]
	if kind == 3:
		speed = bounds.y * 0.045
	var variant := forced_variant if not forced_variant.is_empty() else variant_for(kind)
	var enemy := {"type": kind, "enemy_id": id_for(kind, variant), "variant": variant, "modifiers": [], "elite": false, "ghosted": false, "since_hit": 99.0, "drop_allowed": true, "split_depth": 0, "p": Vector2(bounds.x / 2 if kind == 3 else randf_range(30, bounds.x - 30), -50 if kind == 3 else -30), "hp": float(health), "max_hp": health, "radius": [20, 15, 27, 44][kind], "speed": speed, "gold": [4 + wave, 3 + wave, 12 + wave * 2, 100 + wave * 12][kind], "leak": [8, 5, 14, 40][kind], "score": [10, 12, 30, 300][kind], "rot": randf() * TAU, "rot_speed": 0.5 if kind == 3 else randf_range(-1.6, 1.6), "sides": [4, 3, 6, 8][kind], "wob": randf() * TAU, "wob_speed": 1.2 if kind == 3 else randf_range(1, 3), "wob_amp": 60 if kind == 3 else (randf_range(20, 45) if kind == 1 else randf_range(4, 14)), "hit": 0.0, "age": 0.0}
	enemy.slow_timer = 0.0
	enemy.static_timer = 0.0
	if variant == "armored":
		enemy.max_hp = roundi(enemy.max_hp * 1.6)
		enemy.hp = float(enemy.max_hp)
	if variant == "thief":
		enemy.speed *= 1.12
		enemy.gold = roundi(enemy.gold * 1.5)
	if variant == "splitter":
		enemy.max_hp = roundi(enemy.max_hp * 1.3)
		enemy.hp = float(enemy.max_hp)
	var becomes_elite := allow_elite and kind != 3 and (force_elite or (wave >= 4 and randf() < minf(0.16, 0.04 + wave * 0.008)))
	if becomes_elite:
		apply_elite(enemy)
	enemies.append(enemy)
	enemy_discovered.emit(enemy.enemy_id)
	if enemy.elite:
		enemy_discovered.emit("elite")
	return enemy

func apply_elite(enemy: Dictionary) -> void:
	enemy.elite = true
	enemy.max_hp = roundi(enemy.max_hp * 2.0)
	enemy.hp = float(enemy.max_hp)
	enemy.gold = roundi(enemy.gold * 2.0)
	enemy.score = roundi(enemy.score * 2.0)
	enemy.radius *= 1.18
	var pool := ELITE_MODIFIERS.duplicate()
	pool.shuffle()
	enemy.modifiers = [pool[0], pool[1]]
	if enemy.modifiers.has("haste"):
		enemy.speed *= 1.4

func spawn_split_children(parent: Dictionary) -> void:
	for direction in [-1, 1]:
		var child := spawn(0, "child", false, false)
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

func tick(delta: float) -> void:
	if not running or paused:
		return
	var dt := minf(delta, 0.05)
	play_time += dt
	banner_time = maxf(0, banner_time - dt)
	for slot in tower_slots:
		slot.beam_time = maxf(0, slot.beam_time - dt)
		slot.pulse_time = maxf(0, slot.pulse_time - dt)
	combo_timer -= dt
	if combo_timer <= 0:
		combo = 0
	charge = minf(100, charge + dt * (1.6 + research[3] * 0.3))
	spawn_timer -= dt
	var max_alive := mini(26, 8 + wave)
	if spawn_timer <= 0 and enemies.size() < max_alive:
		spawn_timer = maxf(0.2, 0.9 - wave * 0.055 - play_time * 0.0015) * randf_range(0.7, 1.25)
		spawn()
		if wave >= 4 and randf() < 0.35 and enemies.size() < max_alive:
			spawn()
		if wave >= 8 and randf() < 0.3 and enemies.size() < max_alive:
			spawn()
	if auto_dps() > 0 and not enemies.is_empty():
		for slot_index in tower_slots.size():
			var slot := tower_slots[slot_index]
			slot.auto_timer -= dt
			if slot.auto_timer > 0:
				continue
			var cadence := interval_for_module(slot.module_id)
			slot.auto_timer += cadence
			var target: Dictionary = {}
			for enemy in enemies:
				if enemy.hp > 0 and not enemy.ghosted and (target.is_empty() or enemy.hp < target.hp):
					target = enemy
			if not target.is_empty() or slot.module_id == "pulse":
				auto_attack(target, auto_dps() * cadence * randf_range(0.85, 1.15), slot.module_id, slot_index)
	for slot in tower_slots:
		slot.turret_angle = lerp_angle(slot.turret_angle, slot.turret_target, minf(1, dt * 10))
	for enemy in enemies.duplicate():
		enemy.age += dt
		enemy.since_hit += dt
		enemy.hit = maxf(0, enemy.hit - dt)
		enemy.ghosted = (enemy.variant == "ghost" or enemy.modifiers.has("phase")) and fmod(enemy.age, 3.0) > 2.0
		if (enemy.variant == "regen" or enemy.modifiers.has("regen")) and enemy.since_hit > 1.5 and enemy.hp < enemy.max_hp:
			enemy.hp = minf(enemy.max_hp, enemy.hp + enemy.max_hp * 0.035 * dt)
		enemy.rot += enemy.rot_speed * dt
		enemy.wob += enemy.wob_speed * dt
		var movement_dt := dt - CRYO_SLOW_STRENGTH * minf(dt, enemy.slow_timer)
		enemy.slow_timer = maxf(0, enemy.slow_timer - dt)
		enemy.static_timer = maxf(0, enemy.get("static_timer", 0.0) - dt)
		enemy.p.y += enemy.speed * (1 + play_time * 0.0012) * movement_dt * (0.4 if enemy.age < 0.5 else 1.0)
		enemy.p.x = clampf(enemy.p.x + cos(enemy.wob) * enemy.wob_amp * movement_dt, enemy.radius * 0.6, bounds.x - enemy.radius * 0.6)
		if enemy.p.y >= bounds.y - 36:
			enemies.erase(enemy)
			var stolen := 0
			if enemy.variant == "thief":
				stolen = mini(gold, maxi(10, roundi(gold * 0.15)))
				gold -= stolen
			hp = maxi(0, hp - enemy.leak)
			combo = maxi(0, combo - 6)
			effect.emit("leak", enemy.p, Color("ff3355"), ("-%d HP  -%d OURO" % [enemy.leak, stolen]) if stolen > 0 else "-%d" % enemy.leak)
			sound.emit("leak")
			if hp == 0:
				running = false
				sound.emit("gameover")
				ended.emit()
				break
