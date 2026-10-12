extends RefCounted

var path := "user://records_v1.json"
var scores: Array = []
var best := 0
var muted := false
var writable := true
var pieces: Array[int] = [0, 0, 0, 0]
var research: Array[int] = [
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0
]
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

const RESEARCH_MAX := [
	5, 5, 5, 3, 5, 5, 5, 3,
	5, 5, 5, 5, 5, 5, 5, 5, 5, 3,
	5, 5, 5, 5, 5, 5, 5
]
const RESEARCH_BASE_COSTS := [
	5, 5, 4, 2, 8, 8, 7, 3,
	6, 6, 7, 3, 5, 6, 5, 6, 6, 4,
	6, 6, 7, 7, 3, 8, 4
]
const RESEARCH_PIECE_INDEX := [
	0, 1, 2, 3, 0, 1, 2, 3,
	0, 1, 0, 3, 1, 2, 2, 1, 2, 3,
	0, 1, 0, 2, 3, 2, 3
]
const SCHEMA_VERSION := 9
const SLOT_WAVES := [1, 3, 6, 10, 15, 22, 30]
const SLOT_COSTS := [
	{"piece_index": -1, "amount": 0},
	{"piece_index": 0, "amount": 6},
	{"piece_index": 1, "amount": 8},
	{"piece_index": 2, "amount": 10},
	{"piece_index": 3, "amount": 3},
	{"piece_index": 2, "amount": 18},
	{"piece_index": 3, "amount": 6},
]
const MODULE_WAVES := {"plasma": 1, "cryo": 5, "arc": 10, "pulse": 15, "laser": 20, "vortex": 25, "railgun": 30}
const MODULE_COSTS := {
	"plasma": {"piece_index": -1, "amount": 0},
	"cryo": {"piece_index": 1, "amount": 8},
	"arc": {"piece_index": 0, "amount": 12},
	"pulse": {"piece_index": 2, "amount": 14},
	"laser": {"piece_index": 3, "amount": 4},
	"vortex": {"piece_index": 2, "amount": 20},
	"railgun": {"piece_index": 3, "amount": 6},
}

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
		migrated["version"] = SCHEMA_VERSION
		var cur_res8: Array = migrated.get("research", [])
		while cur_res8.size() < RESEARCH_MAX.size():
			cur_res8.append(0)
		migrated["research"] = cur_res8
	return migrated

func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != SCHEMA_VERSION or not data.get("scores") is Array:
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
	return (version is int or version is float) and is_finite(float(version)) and float(version) == floor(float(version)) and int(version) in [1, 2, 3, 4, 5, 6, 7, 8]

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
	var data := {"version": SCHEMA_VERSION, "scores": scores, "best": best, "muted": muted, "pieces": pieces, "research": research, "enemy_stats": enemy_stats, "highest_wave": highest_wave, "tower_modules": tower_modules, "unlocked_tower_slots": unlocked_tower_slots, "tower_loadout": tower_loadout}
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

func qualifies(value: int) -> bool:
	return value > 0 and (scores.size() < 10 or value > scores[-1].score)

func research_cost(index: int) -> int:
	if index < 0 or index >= RESEARCH_MAX.size():
		return 0
	var base: int = RESEARCH_BASE_COSTS[index]
	return base + research[index] * base

func piece_index_for_research(index: int) -> int:
	if index < 0 or index >= RESEARCH_PIECE_INDEX.size():
		return 0
	return RESEARCH_PIECE_INDEX[index]

func can_research(index: int) -> bool:
	if index < 0 or index >= RESEARCH_MAX.size() or research[index] >= RESEARCH_MAX[index]:
		return false
	var p_idx := piece_index_for_research(index)
	return pieces[p_idx] >= research_cost(index)

func buy_research(index: int) -> bool:
	if not can_research(index):
		return false
	var p_idx := piece_index_for_research(index)
	pieces[p_idx] -= research_cost(index)
	research[index] += 1
	return true

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
	return MODULE_COSTS[module_id].duplicate(true)

func can_research_module(module_id: String) -> bool:
	if not writable or not module_visible(module_id) or module_unlocked(module_id):
		return false
	var cost := module_cost(module_id)
	return not cost.is_empty() and int(cost.piece_index) >= 0 and pieces[int(cost.piece_index)] >= int(cost.amount)

func research_module(module_id: String) -> bool:
	if not can_research_module(module_id):
		return false
	var cost := module_cost(module_id)
	pieces[int(cost.piece_index)] -= int(cost.amount)
	tower_modules[module_id] = true
	return true

func equip_module(module_id: String) -> bool:
	return equip_module_in_slot(0, module_id)

func slot_visible(index: int) -> bool:
	return index >= 0 and index < SLOT_WAVES.size() and highest_wave >= SLOT_WAVES[index]

func slot_cost(index: int) -> Dictionary:
	if index < 0 or index >= SLOT_COSTS.size():
		return {}
	return SLOT_COSTS[index].duplicate(true)

func can_research_slot(index: int) -> bool:
	if not writable or index != unlocked_tower_slots or not slot_visible(index):
		return false
	var cost := slot_cost(index)
	return not cost.is_empty() and int(cost.piece_index) >= 0 and pieces[int(cost.piece_index)] >= int(cost.amount)

func research_slot(index: int) -> bool:
	if not can_research_slot(index):
		return false
	var cost := slot_cost(index)
	pieces[int(cost.piece_index)] -= int(cost.amount)
	unlocked_tower_slots += 1
	return true

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
