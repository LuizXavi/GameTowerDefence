class_name VoidState
extends RefCounted

signal effect(kind: String, position: Vector2, color: Color, text: String)
signal sound(kind: String)
signal ended
signal piece_dropped(kind: int, amount: int, position: Vector2, enemy_id: String, from_elite: bool)
signal enemy_discovered(enemy_id: String)
signal enemy_defeated(enemy_id: String, at_wave: int)
signal achievement_triggered(ach_id: String)

var current_anomaly: Dictionary = {}

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

const EnemySpawner = preload("res://core/enemy_spawner.gd")
const TowerCombat = preload("res://core/tower_combat.gd")
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
	var anom_cadence: float = float(current_anomaly.get("turret_cadence", 1.0))
	return (base / (1.0 + haste_bonus)) * anom_cadence
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
	if slot_index > 0 and next_lvl == 1:
		achievement_triggered.emit("slot_expanded")
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

func dome_center() -> Vector2:
	return Vector2(bounds.x * 0.5, bounds.y - 30.0)

func dome_radius() -> float:
	return clampf(bounds.x * 0.085, 46.0, 72.0)

func tower_position(slot_index: int) -> Vector2:
	var total_slots: int = maxi(1, tower_slots.size())
	var center_x: float = bounds.x * 0.5
	var dome_r: float = dome_radius()
	var dome_margin: float = 24.0
	var side_margin: float = clampf(bounds.x * 0.04, 30.0, 48.0)
	var left_count: int = total_slots / 2
	var right_count: int = total_slots - left_count
	var pos_x: float = center_x
	if slot_index < left_count:
		var t: float = (float(slot_index) + 0.5) / float(maxi(1, left_count))
		pos_x = lerp(side_margin, center_x - dome_r - dome_margin, t)
	else:
		var right_idx: int = slot_index - left_count
		var t: float = (float(right_idx) + 0.5) / float(maxi(1, right_count))
		pos_x = lerp(center_x + dome_r + dome_margin, bounds.x - side_margin, t)
	return Vector2(pos_x, bounds.y - 40.0)

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
	var anom_mult: float = float(current_anomaly.get("click_dmg", 1.0))
	return roundi((3 + research[0] + levels[0] * 3 + wave * 0.6) * multiplier() * anom_mult)

func auto_dps() -> int:
	var total := 0
	for i in tower_slots.size():
		total += slot_dps(i)
	return total

func auto_attack(target: Dictionary, base_damage: float, module_id: String = "", slot_index: int = 0) -> void:
	TowerCombat.auto_attack(self, target, base_damage, module_id, slot_index)

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
			if combo >= 15:
				achievement_triggered.emit("combo_15")
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
	if combo >= 15:
		achievement_triggered.emit("combo_15")
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
	achievement_triggered.emit("nova_blast")
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
	if kills == 0:
		achievement_triggered.emit("first_kill")
	kills += 1
	wave_kills += 1
	var gold_mult: float = 1.0 + float(research[6]) * 0.08 # Extração Quântica
	var anom_gold: float = float(current_anomaly.get("gold_mult", 1.0))
	var anom_score: float = float(current_anomaly.get("score_mult", 1.0))
	var gain := roundi(enemy.gold * multiplier() * gold_mult * anom_gold)
	gold += gain
	total_gold += gain
	score += roundi(enemy.score * (1 + wave * 0.15) * (1.5 if critical else 1.0) * anom_score)
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
		achievement_triggered.emit("first_boss")
		var b_id: String = str(enemy.get("boss_id", "boss"))
		if b_id != "boss":
			enemy_defeated.emit("boss", wave)
		effect.emit("nova", bounds * Vector2(0.5, 0.35), enemy.get("boss_color", COLORS[3]), str(enemy.get("boss_name", "BOSS")) + " DESTRUÍDO!")
	if wave_kills >= quota():
		next_wave()

func roll_piece_drop(enemy: Dictionary, forced_roll := -1.0) -> int:
	return TowerCombat.roll_piece_drop(self, enemy, forced_roll)

func next_wave() -> void:
	wave += 1
	wave_kills = 0
	if wave >= 5:
		achievement_triggered.emit("wave_5")
	if wave >= 10:
		achievement_triggered.emit("wave_10")
	var bonus := 10 + wave * 6
	gold += bonus
	total_gold += bonus
	score += wave * 250
	hp = mini(max_hp, hp + 6 + research[14] * 4)
	if wave % 5 == 0:
		current_anomaly = {}
		var boss_idx: int = maxi(0, int(wave / 5) - 1) % BOSS_TYPES.size()
		var boss_cfg: Dictionary = BOSS_TYPES[boss_idx]
		banner = "BOSS — " + str(boss_cfg.name)
		banner_time = 2.2
		sound.emit("boss")
		spawn(3)
	elif wave % 5 == 3 and wave >= 3:
		current_anomaly = {}
		sound.emit("boss")
		var elite_cmd := spawn(-1, "", true, true)
		banner = "COMANDANTE — " + str(elite_cmd.get("elite_name", "ELITE"))
		banner_time = 1.9
	elif wave % 3 == 0:
		var a_idx: int = randi() % GameData.ANOMALY_KEYS.size()
		var a_key: String = GameData.ANOMALY_KEYS[a_idx]
		current_anomaly = GameData.ANOMALIES[a_key]
		banner = "ANOMALIA — " + str(current_anomaly.name)
		banner_time = 2.4
		sound.emit("boss")
		effect.emit("nova", bounds * Vector2(0.5, 0.4), current_anomaly.color, str(current_anomaly.name))
	else:
		current_anomaly = {}
		banner = "WAVE %d" % wave
		banner_time = 1.6
		sound.emit("wave")

func variant_for(kind: int) -> String:
	return EnemySpawner.variant_for(wave, kind)

func id_for(kind: int, variant: String) -> String:
	return EnemySpawner.id_for(kind, variant)

func spawn(kind: int = -1, forced_variant := "", force_elite := false, allow_elite := true, legacy_force_elite := false) -> Dictionary:
	return EnemySpawner.spawn(self, kind, forced_variant, force_elite, allow_elite, legacy_force_elite)

func apply_elite(enemy: Dictionary, forced_elite_type := "") -> void:
	EnemySpawner.apply_elite(enemy, forced_elite_type)

func shoot_from_enemy(enemy: Dictionary) -> void:
	EnemySpawner.shoot_from_enemy(self, enemy)

func teleport_enemy(enemy: Dictionary) -> void:
	EnemySpawner.teleport_enemy(self, enemy)

func spawn_minions(parent: Dictionary, count: int = 2) -> Array[Dictionary]:
	return EnemySpawner.spawn_minions(self, parent, count)

func spawn_split_children(parent: Dictionary) -> void:
	EnemySpawner.spawn_split_children(self, parent)

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
		if shield >= 25.0:
			achievement_triggered.emit("shield_active")
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
	var d_center := dome_center()
	var d_rad := dome_radius()
	var has_active_shield: bool = (shield >= 1.0)
	var effective_dome_r: float = d_rad + (14.0 if has_active_shield else 0.0)

	for proj in enemy_projectiles.duplicate():
		proj.age = float(proj.get("age", 0.0)) + dt
		proj.p += Vector2(proj.v) * dt
		var p_rad: float = float(proj.get("radius", 6.0))
		var hit_dome: bool = (proj.p.distance_to(d_center) <= effective_dome_r + p_rad and proj.p.y <= d_center.y + 6.0)
		var hit_floor: bool = (proj.p.y >= bounds.y - 34.0)
		if hit_dome or hit_floor:
			enemy_projectiles.erase(proj)
			var impact_pos: Vector2 = proj.p
			if hit_dome:
				impact_pos = d_center + (proj.p - d_center).normalized() * effective_dome_r
			apply_base_damage(int(proj.damage), impact_pos, 0, true)
			if not running:
				return
	for enemy in enemies.duplicate():
		enemy.age += dt
		enemy.since_hit += dt
		enemy.hit = maxf(0, enemy.hit - dt)
		enemy.ghosted = (enemy.variant == "ghost" or enemy.modifiers.has("phase")) and fmod(enemy.age, 3.0) > 2.0
		if (enemy.variant == "regen" or enemy.modifiers.has("regen")) and enemy.since_hit > 1.5 and enemy.hp < enemy.max_hp:
			enemy.hp = minf(enemy.max_hp, enemy.hp + enemy.max_hp * 0.035 * dt)
		# Chefe Multifásico: Transição para Fase 2 (Overload) ao atingir 50% de vida
		if enemy.type == 3 and enemy.hp <= enemy.max_hp * 0.5 and not enemy.get("overload", false):
			enemy.overload = true
			enemy.phase = 2
			enemy.speed *= 1.25
			enemy.rot_speed *= 1.8
			enemy.shoot_timer = 0.35
			effect.emit("burst", enemy.p, Color("ff007f"), "SOBRECARGA // FASE 2")
			sound.emit("boss")
		if enemy.get("can_shoot", false) and enemy.p.y > 10.0 and enemy.p.y < bounds.y - 110.0:
			enemy.shoot_timer = float(enemy.get("shoot_timer", 2.2)) - dt
			if enemy.shoot_timer <= 0.0:
				enemy.shoot_timer = (1.4 if enemy.get("overload", false) else 2.0) if enemy.type == 3 else (2.4 if enemy.type == 19 else 2.2)
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
		var anom_speed_mult: float = float(current_anomaly.get("enemy_speed", 1.0))
		enemy.p.y += enemy.speed * berserk_mult * anom_speed_mult * (1 + play_time * 0.0012) * movement_dt * (0.4 if enemy.age < 0.5 else 1.0)
		var dome_pull: float = (bounds.x * 0.5 - enemy.p.x) * 0.18 * movement_dt if enemy.p.y > bounds.y * 0.45 else 0.0
		enemy.p.x = clampf(enemy.p.x + cos(enemy.wob) * enemy.wob_amp * movement_dt + dome_pull, enemy.radius * 0.6, bounds.x - enemy.radius * 0.6)

		# Colisão com o arco do domo/escudo ou solo
		var hit_dome: bool = (enemy.p.distance_to(d_center) <= effective_dome_r + enemy.radius and enemy.p.y <= d_center.y + 6.0)
		var hit_floor: bool = (enemy.p.y >= bounds.y - 36.0)
		if hit_dome or hit_floor:
			enemies.erase(enemy)
			var stolen := 0
			if enemy.variant == "thief":
				var steal_factor: float = maxf(0.2, 1.0 - float(research[15]) * 0.12)
				stolen = mini(gold, maxi(1, roundi(maxi(10, roundi(gold * 0.15)) * steal_factor)))
				gold -= stolen
			combo = maxi(0, combo - 6)
			var impact_pos: Vector2 = enemy.p
			if hit_dome:
				impact_pos = d_center + (enemy.p - d_center).normalized() * effective_dome_r
			apply_base_damage(int(enemy.leak), impact_pos, stolen, false)
			if not running:
				break
