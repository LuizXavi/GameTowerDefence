class_name SaveStore
extends RefCounted

signal research_completed(research_name: String, research_type: String)
signal achievement_unlocked(ach_id: String, ach_title: String, ach_desc: String)

var path := "user://records_v1.json"
var scores: Array = []
var best := 0
var muted := false
var writable := true
var pieces: Array[int] = [0, 0, 0, 0]
var research: Array[int] = GameData.empty_research()
var lab_research: Array[int] = [0, 0, 0]
var active_research: Dictionary = {}
var achievements: Array[String] = []
var enemy_stats: Dictionary = {}
var highest_wave := 1
var tower_modules: Dictionary = {"plasma": true, "cryo": false, "arc": false, "pulse": false, "laser": false, "vortex": false, "railgun": false}
var unlocked_tower_slots := 1
var tower_loadout: Array[String] = ["plasma", "plasma", "plasma", "plasma", "plasma", "plasma", "plasma"]
var equipped_module: String:
	get:
		return tower_loadout[0]
	set(value):
		if module_unlocked(value):
			tower_loadout[0] = value

const RESEARCH_MAX := GameData.RESEARCH_MAX
const RESEARCH_BASE_COSTS := GameData.RESEARCH_BASE_COSTS
const RESEARCH_PIECE_INDEX := GameData.RESEARCH_PIECE_INDEX
const SCHEMA_VERSION := 13
const SLOT_WAVES := GameData.SLOT_WAVES
const SLOT_COSTS := GameData.SLOT_COSTS
const MODULE_WAVES := GameData.MODULE_WAVES
const MODULE_COSTS := GameData.MODULE_COSTS

func migrate(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	var raw_version: Variant = data.get("version")
	if (not raw_version is int and not raw_version is float) or not is_finite(float(raw_version)) or float(raw_version) != floor(float(raw_version)):
		return migrated
	var version := int(raw_version)
	if version == 1:
		migrated["version"] = 2
		migrated["pieces"] = [0, 0, 0, 0]
		migrated["research"] = [0, 0, 0, 0]
		version = 2
	if version == 2:
		migrated["version"] = 3
		migrated["enemy_stats"] = {}
		version = 3
	if version == 3:
		var previous_highest := 1
		var previous_scores: Variant = migrated.get("scores")
		if previous_scores is Array:
			for item in previous_scores:
				if item is Dictionary:
					var reached: Variant = item.get("wave")
					if (reached is int or reached is float) and is_finite(float(reached)):
						previous_highest = maxi(previous_highest, int(reached))
		migrated["version"] = 4
		migrated["highest_wave"] = previous_highest
		migrated["tower_modules"] = {"plasma": true, "cryo": false, "arc": false}
		migrated["equipped_module"] = "plasma"
		version = 4
	if version == 4:
		migrated["version"] = 5
		migrated["unlocked_tower_slots"] = 1
		migrated["tower_loadout"] = [migrated.get("equipped_module"), "plasma", "plasma", "plasma", "plasma", "plasma", "plasma"]
		migrated.erase("equipped_module")
		version = 5
	if version == 5:
		migrated["version"] = 6
		var current_modules: Dictionary = migrated.get("tower_modules", {})
		current_modules["pulse"] = false
		current_modules["laser"] = false
		migrated["tower_modules"] = current_modules
		version = 6
	if version == 6:
		migrated["version"] = 7
		var current_modules_v6: Dictionary = migrated.get("tower_modules", {})
		current_modules_v6["vortex"] = false
		current_modules_v6["railgun"] = false
		migrated["tower_modules"] = current_modules_v6
		version = 7
	if version == 7:
		migrated["version"] = 8
		var cur_res: Array = migrated.get("research", [0, 0, 0, 0])
		while cur_res.size() < 8:
			cur_res.append(0)
		migrated["research"] = cur_res
		version = 8
	if version == 8:
		migrated["version"] = 9
		var cur_res8: Array = migrated.get("research", [])
		while cur_res8.size() < 25:
			cur_res8.append(0)
		migrated["research"] = cur_res8
		version = 9
	if version == 9:
		migrated["version"] = 10
		var cur_res9: Array = migrated.get("research", [])
		while cur_res9.size() < 28:
			cur_res9.append(0)
		migrated["research"] = cur_res9
		version = 10
	if version == 10:
		migrated["version"] = 11
		var cur_lab: Variant = migrated.get("lab_research")
		if not cur_lab is Array or cur_lab.size() != GameData.LAB_RESEARCH_COUNT:
			migrated["lab_research"] = [0, 0, 0]
		if not migrated.get("active_research") is Dictionary:
			migrated["active_research"] = {}
		version = 11
	if version == 11:
		migrated["version"] = 12
		var cur_ach: Variant = migrated.get("achievements")
		if not cur_ach is Array:
			migrated["achievements"] = []
		version = 12
	if version == 12:
		migrated["version"] = SCHEMA_VERSION
		var cur_res12: Array = migrated.get("research", [])
		while cur_res12.size() < GameData.RESEARCH_COUNT:
			cur_res12.append(0)
		migrated["research"] = cur_res12
		version = 13
	return migrated

func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != SCHEMA_VERSION or not data.get("scores") is Array:
		return false
	if not data.get("achievements") is Array:
		return false
	for ach in data.get("achievements"):
		if not ach is String:
			return false
	if not data.get("best") is float and not data.get("best") is int:
		return false
	if not is_finite(float(data.best)) or data.best < 0 or not data.get("muted") is bool:
		return false
	for item in data.scores:
		if not item is Dictionary or not item.get("name") is String:
			return false
		for key in ["score", "wave", "kills", "gold", "max_combo"]:
			if (not item.get(key) is float and not item.get(key) is int) or not is_finite(float(item.get(key))) or item.get(key) < 0:
				return false
	if not data.get("pieces") is Array or data.get("pieces").size() != 4:
		return false
	for value in data.get("pieces"):
		if (not value is float and not value is int) or not is_finite(float(value)) or value < 0:
			return false
	if not data.get("research") is Array or data.get("research").size() != RESEARCH_MAX.size():
		return false
	for value in data.get("research"):
		if (not value is float and not value is int) or not is_finite(float(value)) or value < 0:
			return false
	for i in RESEARCH_MAX.size():
		if int(data.research[i]) > RESEARCH_MAX[i]:
			return false
	if not data.get("lab_research") is Array or data.get("lab_research").size() != GameData.LAB_RESEARCH_COUNT:
		return false
	for i in GameData.LAB_RESEARCH_COUNT:
		var value: Variant = data.lab_research[i]
		if (not value is float and not value is int) or not is_finite(float(value)) or value < 0 or int(value) > GameData.LAB_RESEARCH_MAX[i]:
			return false
	if not data.get("active_research") is Dictionary:
		return false
	if not data.get("enemy_stats") is Dictionary:
		return false
	for enemy_id in data.enemy_stats:
		var stats: Variant = data.enemy_stats[enemy_id]
		if not enemy_id is String or not stats is Dictionary:
			return false
		for field in ["kills", "pieces", "max_wave"]:
			var value: Variant = stats.get(field)
			if (not value is float and not value is int) or not is_finite(float(value)) or value < 0:
				return false
		if not stats.get("discovered") is bool:
			return false
	var reached: Variant = data.get("highest_wave")
	if (not reached is int and not reached is float) or not is_finite(float(reached)) or reached < 1 or float(reached) != floor(float(reached)):
		return false
	var modules: Variant = data.get("tower_modules")
	if not modules is Dictionary or modules.size() != MODULE_WAVES.size():
		return false
	for module_id in MODULE_WAVES:
		if not modules.get(module_id) is bool:
			return false
	if not modules.plasma:
		return false
	var unlocked: Variant = data.get("unlocked_tower_slots")
	if (not unlocked is int and not unlocked is float) or not is_finite(float(unlocked)) or float(unlocked) != floor(float(unlocked)) or unlocked < 1 or unlocked > SLOT_WAVES.size():
		return false
	var loadout: Variant = data.get("tower_loadout")
	if not loadout is Array or loadout.size() != SLOT_WAVES.size():
		return false
	for module_id in loadout:
		if not module_id is String or not modules.has(module_id) or not modules[module_id]:
			return false
	return true

func read_data(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return null
	return parser.data

func is_future_schema(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var version: Variant = data.get("version")
	return (version is int or version is float) and is_finite(float(version)) and version > SCHEMA_VERSION

func is_legacy_schema(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var version: Variant = data.get("version")
	return (version is int or version is float) and is_finite(float(version)) and float(version) == floor(float(version)) and int(version) in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

func load_data() -> void:
	var data: Variant = read_data(path)
	if is_future_schema(data):
		writable = false
		return
	var migrated := false
	if is_legacy_schema(data):
		data = migrate(data)
		migrated = true
	if not valid(data):
		data = read_data(path + ".bak")
		if is_future_schema(data):
			writable = false
			return
		migrated = false
		if is_legacy_schema(data):
			data = migrate(data)
			migrated = true
	if valid(data):
		scores = data.scores
		scores.sort_custom(func(a, b): return a.score > b.score)
		scores = scores.slice(0, 10)
		best = int(data.best)
		muted = data.muted
		pieces.assign(data.pieces.map(func(value): return int(value)))
		research.assign(data.research.map(func(value): return int(value)))
		while research.size() < GameData.RESEARCH_COUNT:
			research.append(0)
		lab_research.assign(data.get("lab_research", [0, 0, 0]).map(func(value): return int(value)))
		active_research = data.get("active_research", {}).duplicate(true)
		achievements.clear()
		for a in data.get("achievements", []):
			achievements.append(str(a))
		if not active_research.is_empty() and active_research.has("last_timestamp"):
			var saved_ts: int = int(active_research.get("last_timestamp", 0))
			var current_ts: int = int(Time.get_unix_time_from_system())
			if saved_ts > 0 and current_ts > saved_ts:
				var delta_offline: float = float(current_ts - saved_ts)
				tick_research(delta_offline)
		enemy_stats = data.enemy_stats.duplicate(true)
		highest_wave = int(data.highest_wave)
		tower_modules = data.tower_modules.duplicate(true)
		unlocked_tower_slots = int(data.unlocked_tower_slots)
		tower_loadout.assign(data.tower_loadout)
		if migrated:
			save_data()

func save_data() -> bool:
	if not writable:
		return false
	var data := {
		"version": SCHEMA_VERSION,
		"scores": scores,
		"best": best,
		"muted": muted,
		"pieces": pieces,
		"research": research,
		"lab_research": lab_research,
		"active_research": active_research,
		"achievements": achievements,
		"enemy_stats": enemy_stats,
		"highest_wave": highest_wave,
		"tower_modules": tower_modules,
		"unlocked_tower_slots": unlocked_tower_slots,
		"tower_loadout": tower_loadout
	}

	if not valid(data):
		return false
	var previous: Variant = read_data(path)
	if is_future_schema(previous):
		writable = false
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if not valid(read_data(path + ".tmp")):
		return false
	if previous is Dictionary and valid(migrate(previous)):
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func unlock_achievement(ach_id: String) -> bool:
	for a in achievements:
		if a == ach_id:
			return false
	achievements.append(ach_id)
	for info in GameData.ACHIEVEMENTS:
		if info.id == ach_id:
			var p_rew: int = int(info.get("reward_pieces", 0))
			if p_rew > 0:
				pieces[0] += p_rew
			achievement_unlocked.emit(ach_id, str(info.title), str(info.desc))
			save_data()
			return true
	achievement_unlocked.emit(ach_id, ach_id, "")
	save_data()
	return true

func is_achievement_unlocked(ach_id: String) -> bool:
	return achievements.has(ach_id)

func qualifies(value: int) -> bool:
	return value > 0 and (scores.size() < 10 or value > scores[-1].score)

func lab_time_multiplier() -> float:
	var reduction: float = 0.18 * lab_research[0] + 0.08 * lab_research[2]
	return maxf(0.1, 1.0 - reduction)

func lab_cost_multiplier() -> float:
	var reduction: float = 0.10 * lab_research[1]
	return maxf(0.5, 1.0 - reduction)

func is_researching() -> bool:
	return not active_research.is_empty()

func active_research_progress() -> float:
	if active_research.is_empty():
		return 0.0
	var total: float = maxf(0.01, float(active_research.get("total_time", 1.0)))
	return clampf(float(active_research.get("elapsed", 0.0)) / total, 0.0, 1.0)

func active_research_remaining() -> float:
	if active_research.is_empty():
		return 0.0
	var total: float = float(active_research.get("total_time", 1.0))
	var elapsed: float = float(active_research.get("elapsed", 0.0))
	return maxf(0.0, total - elapsed)

func active_research_name() -> String:
	if active_research.is_empty():
		return ""
	var type: String = str(active_research.get("type", ""))
	var target: Variant = active_research.get("target")
	match type:
		"research":
			var idx := int(target)
			return GameData.RESEARCH_NAMES[idx] if idx >= 0 and idx < GameData.RESEARCH_NAMES.size() else "Pesquisa"
		"lab":
			var idx := int(target)
			return GameData.LAB_RESEARCH_NAMES[idx] if idx >= 0 and idx < GameData.LAB_RESEARCH_NAMES.size() else "Laboratório"
		"module":
			var mid := str(target)
			return str(GameData.MODULE_INFO.get(mid, ["Módulo", "", Color.WHITE])[0])
		"slot":
			return "Slot %d" % (int(target) + 1)
	return ""

func apply_resonance_cashback(p_idx: int) -> void:
	if lab_research.size() > 2 and lab_research[2] > 0 and p_idx >= 0 and p_idx < pieces.size():
		pieces[p_idx] += 1

func get_research_duration(index: int) -> float:
	var base: float = GameData.RESEARCH_BASE_TIMES[index] if index >= 0 and index < GameData.RESEARCH_BASE_TIMES.size() else 10.0
	return maxf(1.0, base * lab_time_multiplier())

func get_lab_research_duration(index: int) -> float:
	var base: float = GameData.LAB_RESEARCH_BASE_TIMES[index] if index >= 0 and index < GameData.LAB_RESEARCH_BASE_TIMES.size() else 12.0
	return maxf(1.0, base * lab_time_multiplier())

func get_module_research_duration(module_id: String) -> float:
	var base: float = float(GameData.MODULE_BASE_TIMES.get(module_id, 20.0))
	return maxf(1.0, base * lab_time_multiplier())

func get_slot_research_duration(index: int) -> float:
	var base: float = float(GameData.SLOT_BASE_TIMES[index]) if index >= 0 and index < GameData.SLOT_BASE_TIMES.size() else 20.0
	return maxf(1.0, base * lab_time_multiplier())

func research_cost(index: int) -> int:
	if index < 0 or index >= RESEARCH_MAX.size():
		return 0
	var base: int = RESEARCH_BASE_COSTS[index]
	var raw: int = base + research[index] * base
	return maxi(1, int(round(float(raw) * lab_cost_multiplier())))

func piece_index_for_research(index: int) -> int:
	if index < 0 or index >= RESEARCH_PIECE_INDEX.size():
		return 0
	return RESEARCH_PIECE_INDEX[index]

func can_research(index: int) -> bool:
	if index < 0 or index >= RESEARCH_MAX.size() or research[index] >= RESEARCH_MAX[index]:
		return false
	var p_idx := piece_index_for_research(index)
	return pieces[p_idx] >= research_cost(index)

func start_research(index: int, instant := false) -> bool:
	if not can_research(index):
		return false
	if not instant and is_researching():
		return false
	var p_idx := piece_index_for_research(index)
	pieces[p_idx] -= research_cost(index)
	if instant:
		research[index] += 1
		apply_resonance_cashback(p_idx)
		return true
	active_research = {
		"type": "research",
		"target": index,
		"elapsed": 0.0,
		"total_time": get_research_duration(index),
		"piece_index": p_idx,
		"last_timestamp": int(Time.get_unix_time_from_system())
	}
	return true

func buy_research(index: int) -> bool:
	return start_research(index, true)

func lab_research_cost(index: int) -> int:
	if index < 0 or index >= GameData.LAB_RESEARCH_COUNT:
		return 0
	var base: int = GameData.LAB_RESEARCH_BASE_COSTS[index]
	var raw: int = base + lab_research[index] * base
	return maxi(1, int(round(float(raw) * lab_cost_multiplier())))

func can_lab_research(index: int) -> bool:
	if index < 0 or index >= GameData.LAB_RESEARCH_COUNT or lab_research[index] >= GameData.LAB_RESEARCH_MAX[index]:
		return false
	var p_idx: int = int(GameData.LAB_RESEARCH_PIECE_INDEX[index])
	return pieces[p_idx] >= lab_research_cost(index)

func start_lab_research(index: int, instant := false) -> bool:
	if not can_lab_research(index):
		return false
	if not instant and is_researching():
		return false
	var p_idx: int = int(GameData.LAB_RESEARCH_PIECE_INDEX[index])
	pieces[p_idx] -= lab_research_cost(index)
	if instant:
		lab_research[index] += 1
		apply_resonance_cashback(p_idx)
		return true
	active_research = {
		"type": "lab",
		"target": index,
		"elapsed": 0.0,
		"total_time": get_lab_research_duration(index),
		"piece_index": p_idx,
		"last_timestamp": int(Time.get_unix_time_from_system())
	}
	return true

func buy_lab_research(index: int) -> bool:
	return start_lab_research(index, true)

func record_wave_reached(value: int) -> bool:
	if value <= highest_wave:
		return false
	highest_wave = value
	return true

func module_visible(module_id: String) -> bool:
	return MODULE_WAVES.has(module_id) and highest_wave >= int(MODULE_WAVES[module_id])

func module_unlocked(module_id: String) -> bool:
	return MODULE_WAVES.has(module_id) and tower_modules.get(module_id, false) == true

func module_cost(module_id: String) -> Dictionary:
	if not MODULE_COSTS.has(module_id):
		return {}
	var cost: Dictionary = MODULE_COSTS[module_id].duplicate(true)
	cost.amount = maxi(1, int(round(float(cost.amount) * lab_cost_multiplier())))
	return cost

func can_research_module(module_id: String) -> bool:
	if not writable or not module_visible(module_id) or module_unlocked(module_id):
		return false
	var cost := module_cost(module_id)
	return not cost.is_empty() and int(cost.piece_index) >= 0 and pieces[int(cost.piece_index)] >= int(cost.amount)

func start_module_research(module_id: String, instant := false) -> bool:
	if not can_research_module(module_id):
		return false
	if not instant and is_researching():
		return false
	var cost := module_cost(module_id)
	var p_idx: int = int(cost.piece_index)
	pieces[p_idx] -= int(cost.amount)
	if instant:
		tower_modules[module_id] = true
		apply_resonance_cashback(p_idx)
		return true
	active_research = {
		"type": "module",
		"target": module_id,
		"elapsed": 0.0,
		"total_time": get_module_research_duration(module_id),
		"piece_index": p_idx,
		"last_timestamp": int(Time.get_unix_time_from_system())
	}
	return true

func research_module(module_id: String) -> bool:
	return start_module_research(module_id, true)

func equip_module(module_id: String) -> bool:
	return equip_module_in_slot(0, module_id)

func slot_visible(index: int) -> bool:
	return index >= 0 and index < SLOT_WAVES.size() and highest_wave >= SLOT_WAVES[index]

func slot_cost(index: int) -> Dictionary:
	if index < 0 or index >= SLOT_COSTS.size():
		return {}
	var cost: Dictionary = SLOT_COSTS[index].duplicate(true)
	cost.amount = maxi(1, int(round(float(cost.amount) * lab_cost_multiplier())))
	return cost

func can_research_slot(index: int) -> bool:
	if not writable or index != unlocked_tower_slots or not slot_visible(index):
		return false
	var cost := slot_cost(index)
	return not cost.is_empty() and int(cost.piece_index) >= 0 and pieces[int(cost.piece_index)] >= int(cost.amount)

func start_slot_research(index: int, instant := false) -> bool:
	if not can_research_slot(index):
		return false
	if not instant and is_researching():
		return false
	var cost := slot_cost(index)
	var p_idx: int = int(cost.piece_index)
	pieces[p_idx] -= int(cost.amount)
	if instant:
		unlocked_tower_slots += 1
		apply_resonance_cashback(p_idx)
		return true
	active_research = {
		"type": "slot",
		"target": index,
		"elapsed": 0.0,
		"total_time": get_slot_research_duration(index),
		"piece_index": p_idx,
		"last_timestamp": int(Time.get_unix_time_from_system())
	}
	return true

func research_slot(index: int) -> bool:
	return start_slot_research(index, true)

func tick_research(dt: float) -> bool:
	if active_research.is_empty():
		return false
	active_research.elapsed = float(active_research.get("elapsed", 0.0)) + dt
	active_research["last_timestamp"] = int(Time.get_unix_time_from_system())
	var total_time := float(active_research.get("total_time", 1.0))
	if float(active_research.elapsed) >= total_time:
		complete_active_research()
		return true
	return false

func complete_active_research() -> void:
	if active_research.is_empty():
		return
	var type: String = str(active_research.get("type", ""))
	var target: Variant = active_research.get("target")
	var p_idx: int = int(active_research.get("piece_index", 0))
	match type:
		"research":
			var idx := int(target)
			if idx >= 0 and idx < research.size() and research[idx] < RESEARCH_MAX[idx]:
				research[idx] += 1
		"lab":
			var idx := int(target)
			if idx >= 0 and idx < lab_research.size() and lab_research[idx] < GameData.LAB_RESEARCH_MAX[idx]:
				lab_research[idx] += 1
		"module":
			var mid := str(target)
			if tower_modules.has(mid):
				tower_modules[mid] = true
		"slot":
			var s_idx := int(target)
			if s_idx == unlocked_tower_slots:
				unlocked_tower_slots += 1
	var res_name: String = active_research_name()
	apply_resonance_cashback(p_idx)
	active_research = {}
	research_completed.emit(res_name, type)

func equip_module_in_slot(index: int, module_id: String) -> bool:
	if not writable or index < 0 or index >= unlocked_tower_slots or not module_unlocked(module_id):
		return false
	tower_loadout[index] = module_id
	return true

func ensure_enemy(enemy_id: String) -> Dictionary:
	if not enemy_stats.has(enemy_id):
		enemy_stats[enemy_id] = {"discovered": false, "kills": 0, "pieces": 0, "max_wave": 0}
	return enemy_stats[enemy_id]

func record_seen(enemy_id: String) -> bool:
	var stats := ensure_enemy(enemy_id)
	if stats.discovered:
		return false
	stats.discovered = true
	return true

func record_kill(enemy_id: String, at_wave: int) -> void:
	var stats := ensure_enemy(enemy_id)
	stats.discovered = true
	stats.kills += 1
	stats.max_wave = maxi(int(stats.max_wave), at_wave)

func record_piece(enemy_id: String, amount: int) -> void:
	var stats := ensure_enemy(enemy_id)
	stats.discovered = true
	stats.pieces += maxi(0, amount)
