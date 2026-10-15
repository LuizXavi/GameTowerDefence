class_name TowerCombat
extends RefCounted
## Responsável pelo cálculo e execução dos disparos automáticos das torretas e drops de peças.

const TOWER_MODULE_IDS := GameData.MODULE_IDS
const ARC_CHAIN_RADIUS := 160.0
const CRYO_SLOW_DURATION := 1.5
const PULSE_KNOCKBACK_FORCE := 38.0
const AUTO_INTERVAL := 0.28

static func calculate_slot_dps(level: int, wave: int, research_routing: int = 0, synergy_level: int = 0) -> int:
	if level <= 0:
		return 0
	var syn_mult: float = 1.0 + float(synergy_level) * 0.12
	return roundi(level * (5.0 + wave * 1.4 + level * 1.6) * (1.0 + research_routing * 0.08) * syn_mult)

static func auto_attack(state: Object, target: Dictionary, base_damage: float, module_id: String = "", slot_index: int = 0) -> void:
	if not state.running or state.paused:
		return
	if slot_index < 0 or slot_index >= state.tower_slots.size():
		return
	var slot: Dictionary = state.tower_slots[slot_index]
	var active_module: String = slot.module_id if module_id.is_empty() else module_id
	if active_module not in TOWER_MODULE_IDS:
		active_module = "plasma"
	var range_mult: float = 1.0 + float(state.upg_level("tower_range")) * 0.15

	if active_module == "pulse":
		slot.pulse_time = 0.4
		slot.pulse_ring = state.bounds.x * 0.75 * range_mult
		state.effect.emit("burst", state.tower_position(slot_index), Color("b6ff2e"), "ONDA SÍSMICA")
		state.sound.emit("pulse")
		var pulse_damage: float = base_damage * 1.8 * (1.0 + float(state.research[24]) * 0.12)
		var knockback: float = (PULSE_KNOCKBACK_FORCE + float(state.research[25]) * 6.0) * range_mult
		for proj in state.enemy_projectiles.duplicate():
			if (state.tower_position(slot_index) as Vector2).distance_to(proj.p) < slot.pulse_ring:
				state.enemy_projectiles.erase(proj)
		for enemy in state.enemies.duplicate():
			if enemy.hp <= 0 or enemy.ghosted:
				continue
			var hit_dist: float = (state.tower_position(slot_index) as Vector2).distance_to(enemy.p)
			if hit_dist < slot.pulse_ring:
				enemy.p.y = maxf(enemy.radius + 10, enemy.p.y - knockback)
				enemy.static_timer = 2.5
				state.damage_enemy(enemy, pulse_damage, false, "auto")
		if state.has_method("has_perk") and state.has_perk("seismic_echo"):
			state.queue_seismic_echo(slot_index, base_damage * 0.60 * float(state.get_perk_level("seismic_echo")), 0.4)
		return

	if target.is_empty() or target.hp <= 0 or target.ghosted or not state.enemies.has(target):
		slot.laser_target_id = ""
		slot.laser_focus_time = 0.0
		return

	slot.beam_target = target.p
	slot.beam_time = 0.16
	slot.beam_chain.clear()
	slot.turret_target = (Vector2(slot.beam_target) - (state.tower_position(slot_index) as Vector2)).angle()

	var damage: float = base_damage
	if state.has_method("has_perk"):
		if state.has_perk("glass_cannon"):
			damage *= (1.0 + 0.65 * float(state.get_perk_level("glass_cannon")))
		if state.has_perk("midas_touch"):
			var midas_mult: float = minf(0.60, float(state.gold) / 100.0 * 0.025 * float(state.get_perk_level("midas_touch")))
			damage *= (1.0 + midas_mult)

	if active_module == "cryo":
		damage *= 0.75 * (1.0 + float(state.research[20]) * 0.10)
		target.slow_timer = CRYO_SLOW_DURATION + float(state.research[21]) * 0.25
		if state.has_method("has_perk") and state.has_perk("cryo_permafrost"):
			target.slow_timer = 2.5
			damage += float(target.get("max_hp", 10.0)) * 0.12 * float(state.get_perk_level("cryo_permafrost"))
	elif active_module == "arc":
		damage *= 0.65 * (1.0 + float(state.research[22]) * 0.10)
	elif active_module == "laser":
		var target_key: String = str(target.get("enemy_id", "")) + "_" + str(target.get("age", 0.0))
		var ramp_mult: float = 1.0 + (0.60 * float(state.get_perk_level("laser_rampage")) if (state.has_method("has_perk") and state.has_perk("laser_rampage")) else 0.0)
		var ramp_step: float = AUTO_INTERVAL * (1.0 + float(state.research[26]) * 0.15) * ramp_mult
		if slot.laser_target_id == target_key:
			slot.laser_focus_time = minf(2.0, slot.laser_focus_time + ramp_step)
		else:
			slot.laser_target_id = target_key
			slot.laser_focus_time = 0.0
		var max_ramp_add: float = 3.0 + float(state.research[27]) * 0.3
		var ramp: float = 0.5 + (float(slot.laser_focus_time) / 2.0) * max_ramp_add
		damage *= ramp * (1.0 + float(state.research[27]) * 0.08)
		state.sound.emit("laser")
		if target.get("slow_timer", 0.0) > 0:
			damage *= 1.35
			state.effect.emit("text", target.p - Vector2(0, target.radius + 18), Color("ff7799"), "RUPTURA!")
	elif active_module == "plasma":
		damage *= (1.0 + float(state.research[18]) * 0.12)
		if target.get("slow_timer", 0.0) > 0:
			damage *= (1.45 + float(state.research[19]) * 0.15)
			state.effect.emit("text", target.p - Vector2(0, target.radius + 18), Color("ff55ff"), "CHOQUE TÉRMICO!")
		if state.has_method("has_perk") and state.has_perk("plasma_splash"):
			var splash_radius: float = 75.0
			var splash_dmg: float = damage * 0.40 * float(state.get_perk_level("plasma_splash"))
			for other in state.enemies.duplicate():
				if other == target or other.hp <= 0 or other.ghosted:
					continue
				if target.p.distance_to(other.p) <= splash_radius:
					state.damage_enemy(other, splash_dmg, false, "auto")
					state.effect.emit("burst", other.p, Color("ff2bd6"), "")

	elif active_module == "vortex":
		slot.vortex_center = target.p
		slot.vortex_time = 0.7
		slot.beam_target = target.p
		slot.beam_time = 0.22
		state.sound.emit("vortex")
		state.effect.emit("burst", target.p, Color("9933ff"), "VÓRTICE!")
		var vortex_radius: float = (160.0 + float(state.research[29]) * 12.0) * range_mult
		for enemy in state.enemies.duplicate():
			if enemy.hp <= 0 or enemy.ghosted:
				continue
			var diff: Vector2 = target.p - enemy.p
			var dist: float = diff.length()
			if dist <= vortex_radius:
				if dist > 6.0:
					enemy.p += diff.normalized() * minf(dist - 5.0, 48.0 * range_mult)
				enemy.vortex_timer = 2.0
				var v_dmg: float = base_damage * 1.25 * (1.0 + float(state.research[28]) * 0.12)
				if enemy.get("slow_timer", 0.0) > 0 or enemy.get("static_timer", 0.0) > 0:
					v_dmg *= 1.5
					state.effect.emit("text", enemy.p - Vector2(0, enemy.radius + 18), Color("9933ff"), "IMPLOSÃO!")
				state.damage_enemy(enemy, v_dmg, false, "auto")
		return
	elif active_module == "railgun":
		var origin: Vector2 = state.tower_position(slot_index)
		var fire_dir: Vector2 = (target.p - origin).normalized()
		var t_wall: float = state.bounds.y * 2.0
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
			var t_right: float = (state.bounds.x - origin.x) / fire_dir.x
			if t_right > 0.0 and t_right < t_wall:
				t_wall = t_right
				hit_side = "right"

		var p_wall: Vector2 = origin + fire_dir * t_wall
		p_wall.x = clampf(p_wall.x, 0.0, state.bounds.x)
		p_wall.y = clampf(p_wall.y, 0.0, state.bounds.y)

		var reflect_dir: Vector2 = fire_dir
		if hit_side == "top":
			reflect_dir.y = -reflect_dir.y
		else:
			reflect_dir.x = -reflect_dir.x

		var p_bounce: Vector2 = p_wall + reflect_dir * (state.bounds.y * 0.7)
		slot.beam_target = p_wall
		slot.beam_chain = [p_bounce]
		slot.beam_time = 0.20
		state.sound.emit("railgun")

		for enemy in state.enemies.duplicate():
			if enemy.hp <= 0 or enemy.ghosted:
				continue
			var d1: float = Geometry2D.get_closest_point_to_segment(enemy.p, origin, p_wall).distance_to(enemy.p)
			var d2: float = Geometry2D.get_closest_point_to_segment(enemy.p, p_wall, p_bounce).distance_to(enemy.p)
			if d1 < enemy.radius + 14.0 or d2 < enemy.radius + 14.0:
				var tag: String = "PERFURADO!" if d1 < enemy.radius + 14.0 else "RICOCHETE!"
				state.effect.emit("text", enemy.p - Vector2(0, enemy.radius + 16), Color("33ffcc"), tag)
				state.damage_enemy(enemy, base_damage * 1.6 * (1.0 + float(state.research[30]) * 0.14), false, "auto")
		return

	var targets: Array[Dictionary] = [target]
	if active_module == "arc":
		var max_hops: int = (4 if target.get("static_timer", 0.0) > 0 else 2) + (1 if state.upg_level("tower_range") >= 2 else 0)
		if state.has_method("has_perk") and state.has_perk("arc_overload"):
			max_hops += 2 * state.get_perk_level("arc_overload")
			target.static_timer = 0.25
		if target.get("static_timer", 0.0) > 0:
			state.sound.emit("spark")

		var base_arc_radius: float = (ARC_CHAIN_RADIUS + float(state.research[23]) * 18.0) * range_mult
		var chain_radius: float = base_arc_radius * 1.5 if target.get("static_timer", 0.0) > 0 else base_arc_radius
		var origin: Vector2 = target.p
		for hop in max_hops:
			var next: Dictionary = {}
			var closest: float = chain_radius * chain_radius
			for enemy in state.enemies:
				if enemy.hp <= 0 or enemy.ghosted or targets.has(enemy):
					continue
				var distance: float = origin.distance_squared_to(enemy.p)
				if distance <= closest and (next.is_empty() or distance < closest):
					next = enemy
					closest = distance
			if next.is_empty():
				break
			targets.append(next)
			origin = next.p
			slot.beam_chain.append(origin)
	for i in targets.size():
		state.damage_enemy(targets[i], damage * (1.0 if i == 0 else 0.45), false, "auto")

static func roll_piece_drop(state: Object, enemy: Dictionary, forced_roll := -1.0, forced_double_roll := -1.0) -> int:
	if not enemy.drop_allowed:
		return 0
	var enemy_type: int = int(enemy.type)
	var piece_kind: int = 0
	var chance: float = 0.06
	if enemy_type in [3, 14, 15, 20]:
		piece_kind = 3
		chance = 1.0 if enemy_type == 3 else 0.18
	elif enemy_type in [1, 4, 7, 11, 12, 16, 17]:
		piece_kind = 1
		chance = 0.05
	elif enemy_type in [2, 5, 6, 8, 9, 10, 13, 18, 19]:
		piece_kind = 2
		chance = 0.08
	else:
		piece_kind = 0
		chance = 0.06

	# Pesquisa 17: Magnetismo de Fragmentos (+3% geral por nível)
	if state.research.size() > 17:
		chance += float(state.research[17]) * 0.03

	# Pesquisa 35: Sintonia de Espólios (+3% por nível para Quadrados e Triângulos)
	if state.research.size() > 35 and piece_kind in [0, 1]:
		chance += float(state.research[35]) * 0.03

	# Pesquisa 36: Filtro de Matéria Rara (+5% por nível para Hexágonos e +10% em Elites)
	if state.research.size() > 36:
		if piece_kind == 2:
			chance += float(state.research[36]) * 0.05
		if enemy.elite:
			chance += float(state.research[36]) * 0.10

	# Pesquisa 37: Sobrecarga de Extração (+4% com Crítico ou Combo >= 10)
	var overdrive_active: bool = bool(enemy.get("last_hit_crit", false)) or int(state.combo) >= 10
	if state.research.size() > 37 and overdrive_active:
		chance += float(state.research[37]) * 0.04

	chance = minf(1.0, chance)
	if enemy.elite:
		chance = minf(1.0, chance * 2.0)
	var roll: float = randf() if forced_roll < 0 else forced_roll
	if roll >= chance:
		return 0
	var amount: int = 2 if enemy_type == 3 else 1
	if enemy.elite:
		amount += 1

	# Pesquisa 37: Chance de drop duplo (+25% por nível quando abate com Crítico ou Combo >= 10)
	if state.research.size() > 37 and state.research[37] > 0 and overdrive_active:
		var double_chance: float = float(state.research[37]) * 0.25
		var d_roll: float = randf() if forced_double_roll < 0 else forced_double_roll
		if d_roll < double_chance:
			amount += 1

	var anom_drop_mult: int = maxi(1, int(state.current_anomaly.get("drop_mult", 1.0)))
	amount *= anom_drop_mult
	state.run_pieces[piece_kind] += amount
	state.piece_dropped.emit(piece_kind, amount, enemy.p, enemy.enemy_id, enemy.elite)
	return amount
