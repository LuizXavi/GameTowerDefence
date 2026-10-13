class_name VoidState
extends RefCounted

signal effect(kind: String, position: Vector2, color: Color, text: String)
signal sound(kind: String)
signal ended
signal piece_dropped(kind: int, amount: int, position: Vector2, enemy_id: String, from_elite: bool)
signal enemy_discovered(enemy_id: String)
signal enemy_defeated(enemy_id: String, at_wave: int)

const COLORS := GameData.ENEMY_COLORS
const FAMILY_IDS := GameData.FAMILY_IDS
const ELITE_MODIFIERS := GameData.ELITE_MODIFIERS
const ELITE_TYPES := GameData.ELITE_TYPES
const BOSS_TYPES := GameData.BOSS_TYPES
const TOWER_MODULE_IDS := GameData.MODULE_IDS
const MAX_TOWER_SLOTS := GameData.MAX_TOWER_SLOTS
const AUTO_INTERVAL := 0.28
const ARC_CHAIN_RADIUS := 160.0
const CRYO_SLOW_DURATION := 1.5
const CRYO_SLOW_STRENGTH := 0.35
const PULSE_INTERVAL := 2.5
const PULSE_KNOCKBACK_FORCE := 38.0
var tower_module: String = "plasma"

const UPGRADE_DEFS := GameData.UPGRADE_DEFS

func interval_for_module(module_id: String) -> float:
	var base := AUTO_INTERVAL
	if module_id == "pulse":
		base = PULSE_INTERVAL
	elif module_id == "vortex":
		base = 1.4
	elif module_id == "railgun":
		base = 1.6 * (1.0 - float(research[24]) * 0.04)
	var haste_bonus: float = float(research[9]) * 0.05 + float(upg_level("tower_haste")) * 0.10
	return base / (1.0 + haste_bonus)
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
var shield: float = 0.0
var max_shield: float = 0.0
var shield_regen_timer: float = 0.0
var hp_regen_acc: float = 0.0
var levels: Array = [0, 0, 0, 0]
var upg_levels: Dictionary = {}
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
var enemy_projectiles: Array[Dictionary] = []
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
var research: Array[int] = GameData.empty_research()
var run_pieces: Array[int] = [0, 0, 0, 0]

func _init() -> void:
	_reset_upgrades()
	_reset_tower_slots()

func _reset_upgrades() -> void:
	upg_levels.clear()
	for k in UPGRADE_DEFS:
		upg_levels[k] = 0

func shield_unlocked() -> bool:
	return research.size() > 25 and research[25] > 0

func shield_regen_rate() -> float:
	if max_shield <= 0.0:
		return 0.0
	return 1.5 + float(research[26]) * 1.5 + float(upg_level("shield_regen")) * 2.5

func upg_level(id: String) -> int:
	if id == "click_dmg":
		return int(levels[0])
	if id == "crit_chance":
		return int(levels[2])
	if id == "base_hull":
		return int(levels[3])
	return int(upg_levels.get(id, 0))

func upg_cost(id: String) -> int:
	if id == "click_dmg":
		return cost(0)
	if id == "crit_chance":
		return cost(2)
	if id == "base_hull":
		return cost(3)
	if not UPGRADE_DEFS.has(id):
		return 999999
	var def: Dictionary = UPGRADE_DEFS[id]
	var lvl: int = upg_level(id)
	return floori(float(def.base) * pow(float(def.scale), lvl))

func can_buy_upgrade(id: String) -> bool:
	if not running or paused:
		return false
	if UPGRADE_DEFS.has(id) and UPGRADE_DEFS[id].get("requires_shield", false) and not shield_unlocked():
		return false
	return gold >= upg_cost(id)

func buy_upgrade(id: String) -> bool:
	if not running or paused:
		return false
	if id == "click_dmg":
		return buy(0)
	if id == "crit_chance":
		return buy(2)
	if id == "base_hull":
		return buy(3)
	if not UPGRADE_DEFS.has(id):
		return false
	if UPGRADE_DEFS[id].get("requires_shield", false) and not shield_unlocked():
		sound.emit("deny")
		return false
	var price := upg_cost(id)
	if gold < price:
		sound.emit("deny")
		return false
	gold -= price
	upg_levels[id] = upg_level(id) + 1
	if id == "hull_vitality":
		max_hp += 25
		hp = mini(max_hp, hp + 20)
		effect.emit("burst", Vector2(bounds.x / 2, bounds.y - 60), COLORS[2], "+25 VIDA MÁX")
		sound.emit("shield")
	elif id == "shield_cap":
		max_shield += 35.0
		shield = minf(max_shield, shield + 35.0)
		effect.emit("burst", Vector2(bounds.x / 2, bounds.y - 60), Color("00f5d4"), "+35 ESCUDO")
		sound.emit("shield")
	elif id in ["shield_regen", "shield_pulse"]:
		shield = minf(max_shield, shield + 15.0)
		sound.emit("shield")
	else:
		sound.emit("buy")
	return true

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
			"level": 0,
			"auto_timer": cadence * (float(i) / maxf(1.0, float(tower_loadout.size()))),
			"turret_angle": -PI / 2,
			"turret_target": -PI / 2,
			"beam_target": Vector2.ZERO,
			"beam_time": 0.0,
			"beam_chain": chain,
			"pulse_time": 0.0,
			"pulse_ring": 0.0,
			"laser_focus_time": 0.0,
			"laser_target_id": "",
			"vortex_time": 0.0,
			"vortex_center": Vector2.ZERO
		})

func tower_slot_level(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= tower_slots.size():
		return 0
	var lvl: int = int(tower_slots[slot_index].get("level", 0))
	if slot_index == 0 and lvl == 0 and int(levels[1]) > 0:
		return int(levels[1])
	return lvl

func tower_slot_cost(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= tower_slots.size():
		return 999999
	var lvl: int = tower_slot_level(slot_index)
	var base_c: int = 50 + slot_index * 25
	return floori(base_c * pow(1.68, lvl))

func buy_tower_slot(slot_index: int) -> bool:
	if not running or paused or slot_index < 0 or slot_index >= tower_slots.size():
		return false
	var price := tower_slot_cost(slot_index)
	if gold < price:
		sound.emit("deny")
		return false
	gold -= price
	var next_lvl: int = tower_slot_level(slot_index) + 1
	tower_slots[slot_index].level = next_lvl
	if slot_index == 0:
		levels[1] = next_lvl
	var pos := tower_position(slot_index)
	var msg := "TORRE #%d ATIVA!" % (slot_index + 1) if next_lvl == 1 else "TORRE #%d Nv.%d" % [slot_index + 1, next_lvl]
	effect.emit("burst", pos - Vector2(0, 20), COLORS[2], msg)
	sound.emit("buy")
	return true

func slot_dps(slot_index: int) -> int:
	var lvl: int = tower_slot_level(slot_index)
	if lvl <= 0:
		return 0
	var syn_mult: float = 1.0 + float(upg_level("tower_synergy")) * 0.12
	return roundi(lvl * (5.0 + wave * 1.4 + lvl * 1.6) * (1.0 + research[1] * 0.08) * syn_mult)

func active_tower_count() -> int:
	var count := 0
	for i in tower_slots.size():
		if tower_slot_level(i) > 0:
			count += 1
	return count

func tower_position(slot_index: int) -> Vector2:
	return Vector2(bounds.x * (slot_index + 1.0) / (tower_slots.size() + 1.0), bounds.y - 40)

func configure_research(res_levels: Array) -> void:
	for i in GameData.RESEARCH_COUNT:
		research[i] = clampi(int(res_levels[i]) if i < res_levels.size() else 0, 0, GameData.RESEARCH_MAX[i])

func reset() -> void:
	gold = research[15] * 20
	total_gold = gold
	score = 0
	kills = 0
	wave = 1
	wave_kills = 0
	hp = 100
	max_hp = 100
	max_hp += research[2] * 10
	hp = max_hp
	max_shield = float(research[25] * 25) if shield_unlocked() else 0.0
	shield = max_shield
	shield_regen_timer = 0.0
	hp_regen_acc = 0.0
	levels = [0, 0, 0, 0]
	_reset_upgrades()
	combo = 0
	max_combo = 0
	combo_timer = 0
	charge = minf(100.0, 20.0 + float(research[16]) * 10.0)
	play_time = 0
	spawn_timer = 0.2
	_reset_tower_slots()
	enemies.clear()
	enemy_projectiles.clear()
	running = true
	paused = false
	banner = "WAVE 1"
	banner_time = 1.6
	run_pieces = [0, 0, 0, 0]
	sound.emit("start")

func multiplier() -> float:
	var combo_bonus: float = 0.04 + float(research[5]) * 0.008 + float(upg_level("combo_drive")) * 0.012
	return 1 + mini(combo, 60) * combo_bonus

func click_damage() -> int:
	return roundi((3 + research[0] + levels[0] * 3 + wave * 0.6) * multiplier())

func auto_dps() -> int:
	var total := 0
	for i in tower_slots.size():
		total += slot_dps(i)
	return total

func auto_attack(target: Dictionary, base_damage: float, module_id: String = "", slot_index: int = 0) -> void:
	if not running or paused:
		return
	if slot_index < 0 or slot_index >= tower_slots.size():
		return
	var slot := tower_slots[slot_index]
	var active_module: String = slot.module_id if module_id.is_empty() else module_id
	if active_module not in TOWER_MODULE_IDS:
		active_module = "plasma"
	var range_mult: float = 1.0 + float(upg_level("tower_range")) * 0.15

	if active_module == "pulse":
		# Onda Sísmica: dano radial, empurra inimigos e eletriza para tempestade estática
		slot.pulse_time = 0.4
		slot.pulse_ring = bounds.x * 0.75 * range_mult
		effect.emit("burst", tower_position(slot_index), Color("b6ff2e"), "ONDA SÍSMICA")
		sound.emit("pulse")
		var pulse_damage := base_damage * 1.8 * (1.0 + float(research[21]) * 0.12)
		var knockback := (PULSE_KNOCKBACK_FORCE + float(research[21]) * 6.0) * range_mult
		for proj in enemy_projectiles.duplicate():
			if tower_position(slot_index).distance_to(proj.p) < slot.pulse_ring:
				enemy_projectiles.erase(proj)
		for enemy in enemies.duplicate():
			if enemy.hp <= 0 or enemy.ghosted:
				continue
			var hit_dist := tower_position(slot_index).distance_to(enemy.p)
			if hit_dist < slot.pulse_ring:
				enemy.p.y = maxf(enemy.radius + 10, enemy.p.y - knockback)
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
		damage *= 0.75 * (1.0 + float(research[19]) * 0.10)
		target.slow_timer = CRYO_SLOW_DURATION + float(research[19]) * 0.25
	elif active_module == "arc":
		damage *= 0.65 * (1.0 + float(research[20]) * 0.10)
	elif active_module == "laser":
		# Laser de Antimatéria: rampa de dano mantendo o foco
		var target_key: String = str(target.get("enemy_id", "")) + "_" + str(target.get("age", 0.0))
		var ramp_step: float = AUTO_INTERVAL * (1.0 + float(research[22]) * 0.15)
		if slot.laser_target_id == target_key:
			slot.laser_focus_time = minf(2.0, slot.laser_focus_time + ramp_step)
		else:
			slot.laser_target_id = target_key
			slot.laser_focus_time = 0.0
		# Multiplicador rampa de 0.5x até (3.5x + bônus de lente)
		var max_ramp_add: float = 3.0 + float(research[22]) * 0.3
		var ramp: float = 0.5 + (float(slot.laser_focus_time) / 2.0) * max_ramp_add
		damage *= ramp * (1.0 + float(research[22]) * 0.08)
		sound.emit("laser")
		# Ponto de Ruptura: acelera em inimigos congelados
		if target.get("slow_timer", 0.0) > 0:
			damage *= 1.35
			effect.emit("text", target.p - Vector2(0, target.radius + 18), Color("ff7799"), "RUPTURA!")
	elif active_module == "plasma":
		damage *= (1.0 + float(research[18]) * 0.12)
		# Sinergia Choque Térmico: dano extra se alvo estiver desacelerado/congelado
		if target.get("slow_timer", 0.0) > 0:
			damage *= (1.45 + float(research[18]) * 0.15)
			effect.emit("text", target.p - Vector2(0, target.radius + 18), Color("ff55ff"), "CHOQUE TÉRMICO!")
	elif active_module == "vortex":
		# Vórtice Gravitacional: cria micro singularidade, puxa inimigos e causa implosão
		slot.vortex_center = target.p
		slot.vortex_time = 0.7
		slot.beam_target = target.p
		slot.beam_time = 0.22
		sound.emit("vortex")
		effect.emit("burst", target.p, Color("9933ff"), "VÓRTICE!")
		var vortex_radius := (160.0 + float(research[23]) * 12.0) * range_mult
		for enemy in enemies.duplicate():
			if enemy.hp <= 0 or enemy.ghosted:
				continue
			var diff: Vector2 = target.p - enemy.p
			var dist: float = diff.length()
			if dist <= vortex_radius:
				if dist > 6.0:
					enemy.p += diff.normalized() * minf(dist - 5.0, 48.0 * range_mult)
				enemy.vortex_timer = 2.0
				var v_dmg := base_damage * 1.25 * (1.0 + float(research[23]) * 0.12)
				if enemy.get("slow_timer", 0.0) > 0 or enemy.get("static_timer", 0.0) > 0:
					v_dmg *= 1.5
					effect.emit("text", enemy.p - Vector2(0, enemy.radius + 18), Color("9933ff"), "IMPLOSÃO!")
				damage_enemy(enemy, v_dmg, false, "auto")
		return
	elif active_module == "railgun":
		# Canhão Railgun Fotônico: feixe perfurante ultra-sônico com ricochete na parede
		var origin: Vector2 = tower_position(slot_index)
		var fire_dir: Vector2 = (target.p - origin).normalized()
		var t_wall: float = bounds.y * 2.0
		var hit_side: String = "top"
		if fire_dir.y < -0.001:
			var t_top: float = -origin.y / fire_dir.y
			if t_top > 0.0 and t_top < t_wall:
				t_wall = t_top
				hit_side = "top"
		if fire_dir.x < -0.001:
			var t_left: float = -origin.x / fire_dir.x
			if t_left > 0.0 and t_left < t_wall:
				t_wall = t_left
				hit_side = "left"
		elif fire_dir.x > 0.001:
			var t_right: float = (bounds.x - origin.x) / fire_dir.x
			if t_right > 0.0 and t_right < t_wall:
				t_wall = t_right
				hit_side = "right"

		var p_wall: Vector2 = origin + fire_dir * t_wall
		p_wall.x = clampf(p_wall.x, 0.0, bounds.x)
		p_wall.y = clampf(p_wall.y, 0.0, bounds.y)

		var reflect_dir: Vector2 = fire_dir
		if hit_side == "top":
			reflect_dir.y = -reflect_dir.y
		else:
			reflect_dir.x = -reflect_dir.x

		var p_bounce: Vector2 = p_wall + reflect_dir * (bounds.y * 0.7)
		slot.beam_target = p_wall
		slot.beam_chain = [p_bounce]
		slot.beam_time = 0.20
		sound.emit("railgun")

		for enemy in enemies.duplicate():
			if enemy.hp <= 0 or enemy.ghosted:
				continue
			var d1: float = Geometry2D.get_closest_point_to_segment(enemy.p, origin, p_wall).distance_to(enemy.p)
			var d2: float = Geometry2D.get_closest_point_to_segment(enemy.p, p_wall, p_bounce).distance_to(enemy.p)
			if d1 < enemy.radius + 14.0 or d2 < enemy.radius + 14.0:
				var tag := "PERFURADO!" if d1 < enemy.radius + 14.0 else "RICOCHETE!"
				effect.emit("text", enemy.p - Vector2(0, enemy.radius + 16), Color("33ffcc"), tag)
				damage_enemy(enemy, base_damage * 1.6 * (1.0 + float(research[24]) * 0.14), false, "auto")
		return

	var targets: Array[Dictionary] = [target]
	if active_module == "arc":
		# Sinergia Tempestade Estática: se alvo foi eletrizado por sísmica, raio salta até 4 vezes e com maior alcance
		var max_hops := (4 if target.get("static_timer", 0.0) > 0 else 2) + (1 if upg_level("tower_range") >= 2 else 0)
		if target.get("static_timer", 0.0) > 0:
			sound.emit("spark")
		var base_arc_radius: float = (ARC_CHAIN_RADIUS + float(research[20]) * 18.0) * range_mult
		var chain_radius := base_arc_radius * 1.5 if target.get("static_timer", 0.0) > 0 else base_arc_radius
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
	var res_crit: float = float(research[4]) * 0.02 # Foco Crítico
	return minf(0.05 + levels[2] * 0.045 + res_crit, 0.75)

func cost(key: int) -> int:
	if key == 1:
		return tower_slot_cost(0)
	return floori([15, 50, 90, 70][key] * pow([1.58, 1.68, 1.8, 1.72][key], levels[key]))

func quota() -> int:
	return 6 + wave * 4

func buy(key: int) -> bool:
	if not running or paused or key < 0 or key > 3:
		return false
	if key == 1:
		return buy_tower_slot(0)
	var price := cost(key)
	if gold < price:
		sound.emit("deny")
		return false
	gold -= price
	levels[key] += 1
	if key == 3:
		max_hp += 15
		hp = mini(max_hp, hp + 30 + research[16] * 4)
		if max_shield > 0.0:
			shield = minf(max_shield, shield + 15.0)
		effect.emit("burst", Vector2(bounds.x / 2, bounds.y - 60), COLORS[1], "+%d VIDA" % (30 + research[16] * 4))
	sound.emit("shield" if key == 3 else "buy")
	return true

func tap(point: Vector2) -> void:
	if not running or paused:
		return
	for proj in enemy_projectiles.duplicate():
		if point.distance_squared_to(proj.p) <= pow(float(proj.radius) + 18.0, 2):
			enemy_projectiles.erase(proj)
			combo += 1
			combo_timer = 2.2 + float(research[12]) * 0.4 + float(upg_level("combo_drive")) * 0.3
			max_combo = maxi(max_combo, combo)
			effect.emit("burst", proj.p, COLORS[1], "INTERCEPTADO!")
			sound.emit("click")
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
		combo = maxi(0, combo - maxi(1, 3 - research[12] / 2))
		effect.emit("ring", point, Color(1, 1, 1, 0.35), "")
		return
	var critical := randf() < crit_chance()
	var damage := click_damage() * randf_range(0.9, 1.1)
	if critical:
		var crit_mult: float = 3.0 + levels[2] * 0.25 + float(research[4]) * 0.20 + float(upg_level("crit_mult")) * 0.35
		damage *= crit_mult
	combo += 1
	combo_timer = 2.2 + float(research[12]) * 0.4 + float(upg_level("combo_drive")) * 0.3
	max_combo = maxi(max_combo, combo)
	var target_pos: Vector2 = target.p
	target.p.y -= 10 if critical else 5
	effect.emit("hit", point, COLORS[3] if critical else COLORS[1], "")
	damage_enemy(target, damage, critical, "click")
	var splash_lvl: int = upg_level("click_splash")
	if splash_lvl > 0:
		var splash_dmg: float = damage * (0.15 + float(splash_lvl) * 0.10)
		for other in enemies.duplicate():
			if other != target and other.hp > 0 and not other.ghosted and other.p.distance_to(target_pos) <= 95.0 + splash_lvl * 15.0:
				damage_enemy(other, splash_dmg, false, "click")
	sound.emit("crit" if critical else "click")
	if combo % 15 == 0:
		charge = minf(100, charge + 12)
		effect.emit("text", point - Vector2(0, 50), COLORS[2], "COMBO x%d!" % combo)

func nova() -> bool:
	if not running or paused or charge < 100:
		return false
	charge = 0
	enemy_projectiles.clear()
	var nova_bonus: float = 1.0 + float(research[7]) * 0.25 + float(upg_level("nova_overdrive")) * 0.25
	var damage := (60 + click_damage() * 12 + wave * 12) * nova_bonus
	effect.emit("nova", bounds / 2, Color.WHITE, "PULSO NOVA!")
	sound.emit("bomb")
	for enemy in enemies.duplicate():
		damage_enemy(enemy, damage * randf_range(0.8, 1.2), false, "nova")
	return true

func damage_enemy(enemy: Dictionary, damage: float, critical := false, source := "click") -> void:
	if enemy.hp <= 0 or enemy.ghosted:
		return
	var pierce_bonus: float = float(upg_level("tower_pierce")) * 0.18 if source == "auto" else 0.0
	if enemy.variant == "armored" or enemy.modifiers.has("armor"):
		damage *= (1.75 if source == "auto" else (0.35 if source == "click" else 0.8)) * (1.0 + float(research[8]) * 0.12 + pierce_bonus)
	if research[10] > 0 and enemy.hp < float(enemy.max_hp) * 0.40:
		damage *= (1.0 + float(research[10]) * 0.10)
	if (research[11] > 0 or pierce_bonus > 0.0) and (enemy.elite or enemy.type == 3):
		damage *= (1.0 + float(research[11]) * 0.12 + pierce_bonus)
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
	var gold_mult: float = 1.0 + float(research[6]) * 0.08 # Extração Quântica
	var gain := roundi(enemy.gold * multiplier() * gold_mult)
	gold += gain
	total_gold += gain
	score += roundi(enemy.score * (1 + wave * 0.15) * (1.5 if critical else 1.0))
	var charge_gains: Array[float] = [
		3.5, 3.5, 6.0, 30.0, 4.0, 5.0,
		6.5, 4.5, 8.0, 7.5, 12.0,
		4.0, 5.5, 9.0, 14.0, 20.0,
		6.0, 6.5, 8.5, 11.0, 14.0
	]
	charge = minf(100, charge + (charge_gains[enemy.type] if enemy.type < charge_gains.size() else 10.0))
	var burst_color: Color = COLORS[enemy.type] if enemy.type < COLORS.size() else Color.WHITE
	effect.emit("burst", enemy.p, burst_color, "+%d" % gain)
	sound.emit("kill")
	roll_piece_drop(enemy)
	enemy_defeated.emit(enemy.enemy_id, wave)
	if enemy.elite:
		enemy_defeated.emit("elite", wave)
		var e_type: String = str(enemy.get("elite_type", ""))
		if not e_type.is_empty() and e_type != "elite":
			enemy_defeated.emit(e_type, wave)
	if enemy.variant == "splitter" and enemy.split_depth == 0:
		spawn_split_children(enemy)
	if enemy.type == 3:
		var b_id: String = str(enemy.get("boss_id", "boss"))
		if b_id != "boss":
			enemy_defeated.emit("boss", wave)
		effect.emit("nova", bounds * Vector2(0.5, 0.35), enemy.get("boss_color", COLORS[3]), str(enemy.get("boss_name", "BOSS")) + " DESTRUÍDO!")
	if wave_kills >= quota():
		next_wave()

func roll_piece_drop(enemy: Dictionary, forced_roll := -1.0) -> int:
	if not enemy.drop_allowed:
		return 0
	# Mapeia tipos expandidos para os 4 tipos de fragmentos fundamentais
	# 0: Square, 1: Triangle, 2: Hexagon, 3: Boss
	var enemy_type: int = int(enemy.type)
	var piece_kind: int = 0
	var chance: float = 0.30
	if enemy_type in [3, 14, 15, 20]:
		piece_kind = 3 # Boss core / Singularidade / Titã / Tecelão de Fendas
		chance = 1.0 if enemy_type == 3 else 0.65
	elif enemy_type in [1, 4, 7, 11, 12, 16, 17]:
		piece_kind = 1 # Família Triângulo / Ágil / Atirador / Teleportador
		chance = 0.30
	elif enemy_type in [2, 5, 6, 8, 9, 10, 13, 18, 19]:
		piece_kind = 2 # Família Hexágono / Pesada / Invocador / Artilheiro
		chance = 0.42
	else:
		piece_kind = 0 # Quadrado / Equilibrado
		chance = 0.32

	chance = minf(1.0, chance + float(research[17]) * 0.06)
	if enemy.elite:
		chance = minf(1.0, chance * 2.0)
	var roll := randf() if forced_roll < 0 else forced_roll
	if roll >= chance:
		return 0
	var amount := 2 if enemy_type == 3 else 1
	if enemy.elite:
		amount += 1
	run_pieces[piece_kind] += amount
	piece_dropped.emit(piece_kind, amount, enemy.p, enemy.enemy_id, enemy.elite)
	return amount

func next_wave() -> void:
	wave += 1
	wave_kills = 0
	var bonus := 10 + wave * 6
	gold += bonus
	total_gold += bonus
	score += wave * 250
	hp = mini(max_hp, hp + 6 + research[14] * 4)
	if wave % 5 == 0:
		var boss_idx: int = maxi(0, int(wave / 5) - 1) % BOSS_TYPES.size()
		var boss_cfg: Dictionary = BOSS_TYPES[boss_idx]
		banner = "BOSS — " + str(boss_cfg.name)
		banner_time = 2.2
		sound.emit("boss")
		spawn(3)
	elif wave % 5 == 3 and wave >= 3:
		sound.emit("boss")
		var elite_cmd := spawn(-1, "", true, true)
		banner = "COMANDANTE — " + str(elite_cmd.get("elite_name", "ELITE"))
		banner_time = 1.9
	else:
		banner = "WAVE %d" % wave
		banner_time = 1.6
		sound.emit("wave")

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
	if kind < FAMILY_IDS.size():
		return FAMILY_IDS[kind]
	return "square"

func spawn(kind: int = -1, forced_variant := "", force_elite := false, allow_elite := true, legacy_force_elite := false) -> Dictionary:
	if legacy_force_elite:
		force_elite = true
		allow_elite = true
		if kind < 0:
			var elite_pool: Array[int] = [4, 5, 6, 8, 11, 13, 16, 17, 18]
			kind = elite_pool[randi() % elite_pool.size()]
	elif kind < 0:
		var roll := randf()
		if wave >= 14 and roll < 0.14:
			kind = [10, 14, 15, 19, 20][randi() % 5] # Dodecágono, Singularidade, Titã, Artilheiro, Tecelão
		elif wave >= 9 and roll < 0.25:
			kind = [8, 9, 12, 13, 18][randi() % 5] # Decágono, Hendecágono, Estrela, Prisma, Invocador
		elif wave >= 5 and roll < 0.36:
			kind = [5, 6, 7, 11, 16, 17][randi() % 6] # Heptágono, Octógono, Nonágono, Diamante, Atirador, Teleportador
		elif wave >= 3 and roll < 0.42:
			kind = [4, 16, 17][randi() % 3] if wave >= 4 else 4
		else:
			var tank_p := minf(0.22, 0.06 + wave * 0.012)
			kind = 2 if roll < tank_p else (1 if roll < tank_p + minf(0.4, 0.22 + wave * 0.01) else 0)

	var scale_hp := 1 + (wave - 1) * 0.55 + pow(wave - 1, 1.55) * 0.09 + play_time * 0.008
	# Base health por tipo (0..20)
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

	var variant := forced_variant if not forced_variant.is_empty() else variant_for(kind)
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
	enemies.append(enemy)
	enemy_discovered.emit(enemy.enemy_id)
	if kind == 3 and enemy.boss_id != "boss":
		enemy_discovered.emit("boss")
	if enemy.elite:
		enemy_discovered.emit("elite")
		if not str(enemy.elite_type).is_empty():
			enemy_discovered.emit(str(enemy.elite_type))
	return enemy

func apply_elite(enemy: Dictionary, forced_elite_type := "") -> void:
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

func shoot_from_enemy(enemy: Dictionary) -> void:
	if not running or paused:
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
		var target_x: float = clampf(enemy.p.x + spread_offset, 36.0, bounds.x - 36.0)
		var target_pos := Vector2(target_x, bounds.y - 30.0)
		var dir: Vector2 = (target_pos - enemy.p).normalized()
		if dir.length_squared() < 0.01:
			dir = Vector2.DOWN
		enemy_projectiles.append({
			"p": enemy.p + dir * (enemy.radius + 6.0),
			"v": dir * (225.0 + minf(110.0, wave * 3.0)),
			"radius": 6.5 if enemy.type == 3 else 5.0,
			"damage": 4 if enemy.type == 3 else (3 if enemy.type == 19 else 2),
			"color": p_color,
			"age": 0.0
		})
	effect.emit("text", enemy.p - Vector2(0, enemy.radius + 14), p_color, "DISPARO!")

func teleport_enemy(enemy: Dictionary) -> void:
	if not running or paused:
		return
	var old_p: Vector2 = enemy.p
	var margin: float = maxf(36.0, enemy.radius + 16.0)
	var new_x: float = randf_range(margin, maxf(margin + 10.0, bounds.x - margin))
	if absf(new_x - old_p.x) < 70.0:
		new_x = clampf(old_p.x + (120.0 if old_p.x < bounds.x * 0.5 else -120.0), margin, maxf(margin + 10.0, bounds.x - margin))
	var advance_y: float = 24.0 if enemy.type == 3 else 34.0
	enemy.p = Vector2(new_x, minf(bounds.y - 80.0, old_p.y + advance_y))
	var t_color: Color = enemy.get("boss_color", COLORS[enemy.type]) if enemy.type == 3 else COLORS[enemy.type]
	effect.emit("ring", old_p, t_color, "")
	effect.emit("burst", enemy.p, t_color, "TELEPORTE!")
	if enemy.type == 20:
		var rift_minion := spawn_minions(enemy, 1)
		if not rift_minion.is_empty():
			rift_minion[0].p = old_p

func spawn_minions(parent: Dictionary, count: int = 2) -> Array[Dictionary]:
	var spawned: Array[Dictionary] = []
	if not running or paused:
		return spawned
	for i in count:
		var side_dir: float = -1.0 if (i % 2 == 0) else 1.0
		var m := spawn(1, "minion", false, false)
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
		m.speed = maxf(bounds.y * 0.12, parent.speed * 1.45)
		m.p = Vector2(clampf(parent.p.x + side_dir * (parent.radius + 14.0 + i * 6.0), 24.0, bounds.x - 24.0), parent.p.y + 10.0)
		spawned.append(m)
	var s_color: Color = parent.get("boss_color", COLORS[parent.type]) if parent.type == 3 else COLORS[parent.type]
	effect.emit("burst", parent.p, s_color, "LACAIOS!")
	return spawned

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

func apply_base_damage(raw_dmg: int, hit_pos: Vector2, stolen := 0, is_proj := false) -> void:
	var armor_red: int = research[13] + upg_level("reactive_plating")
	var dmg: int = maxi(1, raw_dmg - (armor_red / 2 if is_proj else armor_red))
	var absorbed := 0
	if shield >= 1.0:
		if research[27] > 0:
			dmg = maxi(1, roundi(float(dmg) * maxf(0.4, 1.0 - float(research[27]) * 0.08)))
		absorbed = mini(int(floor(shield)), dmg)
		shield = maxf(0.0, shield - float(absorbed))
		dmg -= absorbed
		shield_regen_timer = maxf(1.0, 3.2 - float(research[26]) * 0.3 - float(upg_level("shield_regen")) * 0.25)
		if research[27] > 0 or upg_level("shield_pulse") > 0:
			var pulse_lvl: int = upg_level("shield_pulse")
			var ref_dmg: float = float(absorbed * (2 + research[27] * 2 + pulse_lvl * 3))
			for other in enemies.duplicate():
				if other.hp > 0 and not other.ghosted and other.p.y >= bounds.y - 240.0:
					if pulse_lvl > 0:
						other.p.y = maxf(other.radius + 10.0, other.p.y - (28.0 + pulse_lvl * 10.0))
					damage_enemy(other, ref_dmg, false, "auto")
	if dmg > 0:
		hp = maxi(0, hp - dmg)
	if absorbed > 0 and dmg == 0:
		effect.emit("ring", hit_pos, Color("00f5d4"), "-%d ESCUDO" % absorbed)
		sound.emit("shield")
	else:
		var msg := ("-%d HP  -%d OURO" % [dmg, stolen]) if stolen > 0 else ("-%d TIRO" % dmg if is_proj else "-%d" % dmg)
		effect.emit("hit" if is_proj else "leak", hit_pos, Color("ff3355"), msg)
		sound.emit("leak")
	if hp == 0:
		running = false
		sound.emit("gameover")
		ended.emit()

func tick(delta: float) -> void:
	if not running or paused:
		return
	var dt := minf(delta, 0.05)
	play_time += dt
	banner_time = maxf(0, banner_time - dt)
	for slot in tower_slots:
		slot.beam_time = maxf(0, slot.beam_time - dt)
		slot.pulse_time = maxf(0, slot.pulse_time - dt)
		slot.vortex_time = maxf(0, float(slot.get("vortex_time", 0.0)) - dt)
	combo_timer -= dt
	if combo_timer <= 0:
		combo = 0
	var nova_regen_bonus: float = float(research[3]) * 0.3 + float(upg_level("nova_overdrive")) * 0.8
	charge = minf(100, charge + dt * (1.6 + nova_regen_bonus))
	if upg_level("nano_regen") > 0 and hp < max_hp:
		hp_regen_acc += dt * float(upg_level("nano_regen")) * 1.5
		if hp_regen_acc >= 1.0:
			var heal_pts: int = int(floor(hp_regen_acc))
			hp_regen_acc -= float(heal_pts)
			hp = mini(max_hp, hp + heal_pts)
	if max_shield > 0.0:
		shield_regen_timer = maxf(0.0, shield_regen_timer - dt)
		if shield_regen_timer <= 0.0 and shield < max_shield:
			shield = minf(max_shield, shield + shield_regen_rate() * dt)
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
			var s_dps := slot_dps(slot_index)
			if s_dps <= 0:
				continue
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
				auto_attack(target, s_dps * cadence * randf_range(0.85, 1.15), slot.module_id, slot_index)
	for slot in tower_slots:
		slot.turret_angle = lerp_angle(slot.turret_angle, slot.turret_target, minf(1, dt * 10))
	for proj in enemy_projectiles.duplicate():
		proj.age = float(proj.get("age", 0.0)) + dt
		proj.p += Vector2(proj.v) * dt
		if proj.p.y >= bounds.y - 34.0:
			enemy_projectiles.erase(proj)
			apply_base_damage(int(proj.damage), proj.p, 0, true)
			if not running:
				return
	for enemy in enemies.duplicate():
		enemy.age += dt
		enemy.since_hit += dt
		enemy.hit = maxf(0, enemy.hit - dt)
		enemy.ghosted = (enemy.variant == "ghost" or enemy.modifiers.has("phase")) and fmod(enemy.age, 3.0) > 2.0
		if (enemy.variant == "regen" or enemy.modifiers.has("regen")) and enemy.since_hit > 1.5 and enemy.hp < enemy.max_hp:
			enemy.hp = minf(enemy.max_hp, enemy.hp + enemy.max_hp * 0.035 * dt)
		if enemy.get("can_shoot", false) and enemy.p.y > 10.0 and enemy.p.y < bounds.y - 110.0:
			enemy.shoot_timer = float(enemy.get("shoot_timer", 2.2)) - dt
			if enemy.shoot_timer <= 0.0:
				enemy.shoot_timer = 2.0 if enemy.type == 3 else (2.4 if enemy.type == 19 else 2.2)
				shoot_from_enemy(enemy)
		if enemy.get("can_teleport", false) and enemy.p.y > 10.0 and enemy.p.y < bounds.y - 120.0:
			enemy.teleport_timer = float(enemy.get("teleport_timer", 2.0)) - dt
			if enemy.teleport_timer <= 0.0:
				enemy.teleport_timer = 2.8 if enemy.type == 3 else 2.1
				teleport_enemy(enemy)
		if enemy.get("can_summon", false) and enemy.p.y > 0.0 and enemy.p.y < bounds.y - 110.0 and enemies.size() < max_alive + 6:
			enemy.summon_timer = float(enemy.get("summon_timer", 2.8)) - dt
			if enemy.summon_timer <= 0.0:
				enemy.summon_timer = 3.2 if enemy.type == 3 else 2.9
				spawn_minions(enemy, 2)
		enemy.rot += enemy.rot_speed * dt
		enemy.wob += enemy.wob_speed * dt
		var movement_dt := dt - CRYO_SLOW_STRENGTH * minf(dt, enemy.slow_timer)
		enemy.slow_timer = maxf(0, enemy.slow_timer - dt)
		enemy.static_timer = maxf(0, enemy.get("static_timer", 0.0) - dt)
		var berserk_mult: float = 1.35 if (enemy.modifiers.has("berserk") and enemy.hp < enemy.max_hp * 0.6) else 1.0
		enemy.p.y += enemy.speed * berserk_mult * (1 + play_time * 0.0012) * movement_dt * (0.4 if enemy.age < 0.5 else 1.0)
		enemy.p.x = clampf(enemy.p.x + cos(enemy.wob) * enemy.wob_amp * movement_dt, enemy.radius * 0.6, bounds.x - enemy.radius * 0.6)
		if enemy.p.y >= bounds.y - 36:
			enemies.erase(enemy)
			var stolen := 0
			if enemy.variant == "thief":
				var steal_factor: float = maxf(0.2, 1.0 - float(research[15]) * 0.12)
				stolen = mini(gold, maxi(1, roundi(maxi(10, roundi(gold * 0.15)) * steal_factor)))
				gold -= stolen
			combo = maxi(0, combo - 6)
			apply_base_damage(int(enemy.leak), enemy.p, stolen, false)
			if not running:
				break
