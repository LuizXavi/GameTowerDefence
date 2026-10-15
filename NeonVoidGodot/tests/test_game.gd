extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
	checks += 1

func _init() -> void:
	var game := VoidState.new()
	game.reset()
	check(game.click_damage() == 4 and game.quota() == 10, "Initial balance")
	game.configure_research([2, 1, 3, 2])
	game.reset()
	check(game.click_damage() == 6 and game.max_hp == 130 and game.hp == 130, "Research bonuses apply on run start")
	var charge_before := game.charge
	game.tick(0.05)
	check(game.charge > charge_before + 0.1, "Nova research increases passive charge")
	var research_enemy := game.spawn(0)
	check(game.roll_piece_drop(research_enemy, 0.0) == 1 and game.run_pieces[0] == 1, "Square piece forced drop")
	var boss_piece := game.spawn(3)
	check(game.roll_piece_drop(boss_piece, 0.99) == 2 and game.run_pieces[3] == 2, "Boss always drops two cores")
	check(game.roll_piece_drop(research_enemy, 0.99) == 0 and game.run_pieces[0] == 1, "Failed roll grants nothing")
	game.configure_research([0, 0, 0, 0])
	game.reset()
	game.spawn_timer = 100
	var armored := game.spawn(0, "armored", false, false)
	armored.hp = 100.0
	armored.max_hp = 100
	game.damage_enemy(armored, 10, false, "click")
	check(is_equal_approx(armored.hp, 96.5), "Armored square resists click damage")
	game.damage_enemy(armored, 10, false, "auto")
	check(is_equal_approx(armored.hp, 79.0), "Armored square is weak to turret")
	var ghost := game.spawn(1, "ghost", false, false)
	ghost.age = 2.1
	game.tick(0.01)
	var ghost_hp: float = ghost.hp
	game.damage_enemy(ghost, 1000, false, "click")
	check(ghost.ghosted and ghost.hp == ghost_hp, "Ghost triangle is intangible during phase")
	var regenerating := game.spawn(2, "regen", false, false)
	regenerating.hp = regenerating.max_hp * 0.5
	regenerating.since_hit = 2.0
	var regen_hp: float = regenerating.hp
	game.tick(0.05)
	check(regenerating.hp > regen_hp, "Regenerator heals after not being hit")
	var splitter := game.spawn(0, "splitter", false, false)
	var count_before_split := game.enemies.size()
	game.damage_enemy(splitter, 100000)
	var mini_count := game.enemies.filter(func(e): return e.split_depth == 1).size()
	check(game.enemies.size() == count_before_split + 1 and mini_count == 2, "Duplicator creates two smaller enemies")
	var thief := game.spawn(1, "thief", false, false)
	game.gold = 100
	game.hp = 100
	thief.p.y = game.bounds.y
	game.tick(0.01)
	check(game.gold == 85 and game.hp == 95, "Thief steals gold when leaking")
	var elite := game.spawn(0, "", true, true)
	check(elite.elite and elite.modifiers.size() == 2 and elite.modifiers[0] != elite.modifiers[1], "Elite receives two unique modifiers")
	var elite_piece_before: int = game.run_pieces[0]
	check(game.roll_piece_drop(elite, 0.0) == 2 and game.run_pieces[0] == elite_piece_before + 2, "Elite improves piece drops")
	game.reset()
	game.spawn_timer = 100
	game.configure_tower_module("cryo")
	var cryo_target := game.spawn(0, "", false, false)
	cryo_target.hp = 100.0
	cryo_target.max_hp = 100
	game.auto_attack(cryo_target, 20.0)
	check(is_equal_approx(cryo_target.hp, 85.0) and is_equal_approx(cryo_target.slow_timer, 1.5), "Cryo module reduces damage and applies slow")
	var before_slow_y: float = cryo_target.p.y
	cryo_target.age = 1.0
	game.tick(0.05)
	check(cryo_target.p.y - before_slow_y < cryo_target.speed * 0.05, "Cryo slow reduces movement")
	game.reset()
	game.spawn_timer = 100
	game.configure_tower_module("arc")
	var arc_first := game.spawn(0, "", false, false)
	var arc_second := game.spawn(0, "", false, false)
	var arc_third := game.spawn(0, "", false, false)
	arc_first.p = Vector2(200, 200)
	arc_second.p = Vector2(300, 200)
	arc_third.p = Vector2(400, 200)
	for arc_enemy in [arc_first, arc_second, arc_third]:
		arc_enemy.hp = 100.0
		arc_enemy.max_hp = 100
	game.auto_attack(arc_first, 20.0)
	check(is_equal_approx(arc_first.hp, 87.0) and is_equal_approx(arc_second.hp, 94.15) and is_equal_approx(arc_third.hp, 94.15), "Arc module chains reduced damage to two targets")
	check(game.beam_chain.size() == 2, "Arc module records two visual chain links")
	game.configure_tower_module("unknown")
	check(game.tower_module == "plasma", "Invalid tower module falls back to Plasma")
	game.configure_tower_loadout(["plasma", "cryo", "arc", "plasma", "cryo", "arc", "invalid"])
	check(game.tower_loadout == ["plasma", "cryo", "arc", "plasma", "cryo", "arc", "plasma"] and game.tower_slots.size() == 7, "Tower loadout configures up to seven validated slots")
	check(game.tower_position(0).x < game.tower_position(6).x and game.tower_slots[0].auto_timer < game.tower_slots[6].auto_timer, "Seven towers are distributed and initially staggered")
	game.reset()
	check(game.tower_slots.size() == 7 and game.tower_loadout[1] == "cryo", "Restart preserves equipped tower loadout")
	game.reset()
	check(not game.buy(0) and game.levels[0] == 0, "Insufficient funds")
	game.gold = 15
	check(game.buy(0) and game.gold == 0 and game.levels[0] == 1 and game.cost(0) == 23, "Purchase consumes once")
	game.gold = 1000
	game.hp = 50
	check(game.buy(3) and game.max_hp == 115 and game.hp == 80, "Shield upgrade")
	game.paused = true
	var old_gold := game.gold
	game.tick(1)
	check(not game.buy(0) and game.gold == old_gold and game.play_time == 0, "Paused economy and timer")
	game.paused = false
	var enemy := game.spawn(0)
	enemy.p = Vector2(100, 100)
	enemy.hp = 1
	game.tap(Vector2(100, 100))
	check(game.kills == 1 and game.combo == 1 and not game.enemies.has(enemy), "Click hit, reward and removal")
	var before := game.gold
	game.damage_enemy(enemy, 100)
	check(game.gold == before and game.kills == 1, "No duplicate kill reward")
	game.combo = 10
	game.tap(Vector2(800, 400))
	check(game.combo == 7, "Miss penalty")
	game.combo_timer = 0.01
	game.tick(0.05)
	check(game.combo == 0, "Combo expires")
	game.reset()
	game.wave = 4
	game.wave_kills = game.quota() - 1
	enemy = game.spawn(0)
	game.damage_enemy(enemy, 100000)
	check(game.wave == 5 and game.enemies.any(func(e): return e.type == 3), "Boss every fifth wave")
	game.reset()
	enemy = game.spawn(0)
	game.charge = 100
	check(game.nova() and game.kills == 1 and not game.nova(), "Nova damage and single activation")
	game.reset()
	game.gold = 50
	game.buy(1)
	enemy = game.spawn(0)
	var previous_hp: float = enemy.hp
	game.tick(0.05)
	check(enemy.hp < previous_hp and game.beam_time > 0, "Automatic turret")
	game.reset()
	game.hp = 5
	enemy = game.spawn(1)
	enemy.p.y = game.bounds.y
	game.tick(0.05)
	check(game.hp == 0 and not game.running, "Leak ends run")
	game.reset()
	check(game.hp == 100 and game.gold == 0 and game.levels == [0,0,0,0] and game.enemies.is_empty(), "Restart clean")
	var store = load("res://scripts/score_store.gd").new()
	store.path = "user://test_records_%d.json" % Time.get_ticks_usec()
	store.best = 123
	store.scores = [{"name":"TEST", "score":123,"wave":5,"kills":20,"gold":90,"max_combo":7}]
	store.pieces.assign([6, 7, 8, 2])
	store.record_seen("armored_square")
	store.record_kill("armored_square", 7)
	store.record_piece("armored_square", 2)
	check(not store.module_visible("cryo") and store.record_wave_reached(5) and store.module_visible("cryo"), "Cryo research appears at wave five")
	store.pieces[1] = 8
	check(store.research_module("cryo") and store.pieces[1] == 0 and not store.research_module("cryo"), "Cryo module research consumes pieces once")
	check(store.equip_module("cryo") and store.equipped_module == "cryo" and not store.equip_module("arc"), "Only unlocked tower modules can be equipped")
	check(store.slot_visible(1) and store.slot_cost(1) == {"piece_index": 0, "amount": 6}, "Second tower slot research appears at wave three")
	check(store.research_slot(1) and store.unlocked_tower_slots == 2 and store.pieces[0] == 0 and not store.research_slot(1), "Tower slot research is sequential and consumes pieces once")
	check(store.equip_module_in_slot(1, "cryo") and store.tower_loadout[1] == "cryo" and not store.equip_module_in_slot(2, "cryo"), "Modules equip only in unlocked tower slots")
	store.pieces[0] = 6
	check(store.buy_research(0) and store.pieces[0] == 1 and store.research[0] == 1, "Research consumes exact matching pieces")
	check(not store.buy_research(0), "Research blocks insufficient pieces")
	check(store.save_data(), "Write save")
	var other = load("res://scripts/score_store.gd").new()
	other.path = store.path
	other.load_data()
	check(other.best == 123 and other.scores[0].name == "TEST" and other.pieces == [1, 0, 8, 2] and other.research[0] == 1, "Save round trip")
	check(other.highest_wave == 5 and other.tower_modules.cryo and other.equipped_module == "cryo", "Tower modules round trip")
	check(other.unlocked_tower_slots == 2 and other.tower_loadout.slice(0, 2) == ["cryo", "cryo"], "Tower slots and loadout round trip")
	check(other.enemy_stats.armored_square.kills == 1 and other.enemy_stats.armored_square.pieces == 2 and other.enemy_stats.armored_square.max_wave == 7, "Codex stats round trip")
	store.best = 200
	check(store.save_data(), "Second generation and backup")
	var file := FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	other.load_data()
	check(other.best == 123, "Recover valid backup")
	file = FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string('{"version":999}')
	file.close()
	other.load_data()
	check(not other.writable and not other.save_data(), "Future schema preserved")
	var legacy_path := "user://test_legacy_%d.json" % Time.get_ticks_usec()
	file = FileAccess.open(legacy_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1, "scores":[], "best":42, "muted":false}))
	file.close()
	var legacy = load("res://scripts/score_store.gd").new()
	legacy.path = legacy_path
	legacy.load_data()
	check(legacy.best == 42 and legacy.pieces == [0,0,0,0] and legacy.research.size() == GameData.RESEARCH_COUNT and legacy.research[0] == 0, "Schema 1 migrates to research schema")
	var schema_two_path := "user://test_schema2_%d.json" % Time.get_ticks_usec()
	file = FileAccess.open(schema_two_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":2, "scores":[], "best":8, "muted":true, "pieces":[1,2,3,4], "research":[1,0,0,0]}))
	file.close()
	var schema_two = load("res://scripts/score_store.gd").new()
	schema_two.path = schema_two_path
	schema_two.load_data()
	check(schema_two.best == 8 and schema_two.pieces == [1,2,3,4] and schema_two.research.size() == GameData.RESEARCH_COUNT and schema_two.research[0] == 1 and schema_two.enemy_stats.is_empty(), "Schema 2 migrates to Codex schema")
	var schema_three_path := "user://test_schema3_%d.json" % Time.get_ticks_usec()
	file = FileAccess.open(schema_three_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":3, "scores":[{"name":"OLD", "score":20, "wave":12, "kills":2, "gold":4, "max_combo":1}], "best":20, "muted":false, "pieces":[0,0,0,0], "research":[0,0,0,0], "enemy_stats":{}}))
	file.close()
	var schema_three = load("res://scripts/score_store.gd").new()
	schema_three.path = schema_three_path
	schema_three.load_data()
	check(schema_three.highest_wave == 12 and schema_three.module_visible("arc") and schema_three.equipped_module == "plasma", "Schema 3 discovers module research from previous highest wave")
	var schema_four_path := "user://test_schema4_%d.json" % Time.get_ticks_usec()
	file = FileAccess.open(schema_four_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":4, "scores":[], "best":0, "muted":false, "pieces":[0,0,0,0], "research":[0,0,0,0], "enemy_stats":{}, "highest_wave":10, "tower_modules":{"plasma":true,"cryo":true,"arc":false}, "equipped_module":"cryo"}))
	file.close()
	var schema_four = load("res://scripts/score_store.gd").new()
	schema_four.path = schema_four_path
	schema_four.load_data()
	check(schema_four.unlocked_tower_slots == 1 and schema_four.tower_loadout[0] == "cryo" and schema_four.tower_loadout.size() == 7, "Schema 4 migrates equipped tower into first slot")
	check(schema_four.tower_modules.has("pulse") and not schema_four.tower_modules.pulse, "Schema 4 migrates with pulse module locked")
	var schema_five_path := "user://test_schema5_%d.json" % Time.get_ticks_usec()
	file = FileAccess.open(schema_five_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":5, "scores":[], "best":0, "muted":false, "pieces":[0,0,0,0], "research":[0,0,0,0], "enemy_stats":{}, "highest_wave":20, "tower_modules":{"plasma":true,"cryo":true,"arc":true}, "unlocked_tower_slots":3, "tower_loadout":["plasma","cryo","arc","plasma","plasma","plasma","plasma"]}))
	file.close()
	var schema_five = load("res://scripts/score_store.gd").new()
	schema_five.path = schema_five_path
	schema_five.load_data()
	check(schema_five.tower_modules.has("pulse") and not schema_five.tower_modules.pulse and schema_five.tower_modules.has("laser"), "Schema 5 migrates to Schema 6 with pulse and laser locked")
	# Teste de Mecanica: Onda Sísmica (Pulse Knockback) e Laser Contínuo
	game.reset()
	game.configure_tower_loadout(["pulse"])
	var p_enemy := game.spawn(0)
	p_enemy.p = Vector2(game.bounds.x / 2, 200)
	var prev_y: float = p_enemy.p.y
	game.auto_attack(p_enemy, 10, "pulse", 0)
	check(p_enemy.p.y < prev_y and p_enemy.static_timer > 0, "Pulse tower applies vertical knockback and static charge")
	# Teste de Mecânica: Choque Térmico (Plasma em alvo desacelerado)
	game.reset()
	var t_enemy := game.spawn(0)
	t_enemy.slow_timer = 1.5
	var hp_before: float = t_enemy.hp
	game.auto_attack(t_enemy, 10, "plasma", 0)
	check(t_enemy.hp < hp_before, "Plasma applies damage with thermal shock bonus")
	var expansion = load("res://scripts/score_store.gd").new()
	expansion.highest_wave = 30
	expansion.pieces.assign([100,100,100,100])
	for slot_index in range(1, 7):
		check(expansion.research_slot(slot_index), "Sequential tower slot %d unlocks" % (slot_index + 1))
	check(expansion.unlocked_tower_slots == 7 and not expansion.research_slot(7), "Tower hangar stops at seven slots")
	# Testes de NumberFormat e Escalonamento Incremental
	check(NumberFormat.format(500) == "500", "NumberFormat units below 1000")
	check(NumberFormat.format(1500) == "1.5K", "NumberFormat thousands (K)")
	check(NumberFormat.format(2400000) == "2.4M", "NumberFormat millions (M)")
	check(NumberFormat.format(1200000000) == "1.2B", "NumberFormat billions (B)")
	check(NumberFormat.format(1000000000000) == "1T", "NumberFormat trillions (T)")
	# Testes de Síntese Procedural de Áudio (SoundManager)
	var sweep := SoundManager._synth_sweep(440.0, 220.0, 0.05, 0.5)
	check(sweep != null and sweep.data.size() > 100, "SoundManager synthesizes sweep audio stream")
	var noise := SoundManager._synth_noise_burst(0.05, 0.5)
	check(noise != null and noise.data.size() > 100, "SoundManager synthesizes noise burst audio stream")
	# Teste de Migração para Schema 7 (Vórtice e Railgun)
	var schema_six_path := "user://test_schema6_%d.json" % Time.get_ticks_usec()
	file = FileAccess.open(schema_six_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":6, "scores":[], "best":0, "muted":false, "pieces":[0,0,0,0], "research":[0,0,0,0], "enemy_stats":{}, "highest_wave":25, "tower_modules":{"plasma":true,"cryo":true,"arc":true,"pulse":true,"laser":true}, "unlocked_tower_slots":4, "tower_loadout":["plasma","cryo","arc","pulse","plasma","plasma","plasma"]}))
	file.close()
	var schema_six = load("res://scripts/score_store.gd").new()
	schema_six.path = schema_six_path
	schema_six.load_data()
	check(schema_six.tower_modules.has("vortex") and not schema_six.tower_modules.vortex and schema_six.tower_modules.has("railgun") and not schema_six.tower_modules.railgun, "Schema 6 migrates to Schema 7 with vortex and railgun")
	check(schema_six.research.size() == GameData.RESEARCH_COUNT, "Schema 6 migrates to Schema 13 with all research slots")
	# Teste de Migração Schema 7 para Schema 10
	var schema_seven_path := "user://test_schema7_%d.json" % Time.get_ticks_usec()
	file = FileAccess.open(schema_seven_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":7, "scores":[], "best":0, "muted":false, "pieces":[10,10,10,10], "research":[2,1,0,1], "enemy_stats":{}, "highest_wave":25, "tower_modules":{"plasma":true,"cryo":true,"arc":true,"pulse":true,"laser":true,"vortex":true,"railgun":true}, "unlocked_tower_slots":4, "tower_loadout":["plasma","cryo","arc","pulse","plasma","plasma","plasma"]}))
	file.close()
	var schema_seven = load("res://scripts/score_store.gd").new()
	schema_seven.path = schema_seven_path
	schema_seven.load_data()
	check(schema_seven.research.size() == GameData.RESEARCH_COUNT and schema_seven.research[0] == 2 and schema_seven.research[4] == 0, "Schema 7 migrates to Schema 13 with expanded research array")
	check(schema_seven.can_research(4) and schema_seven.buy_research(4) and schema_seven.research[4] == 1, "Purchasing expanded research 4 (Foco Critico) succeeds")
	check(schema_seven.pieces[0] == 2, "Research 4 consumes square fragments properly")
	# Teste de Mecânica: Vórtice Gravitacional puxa inimigos próximos
	game.reset()
	game.configure_tower_loadout(["vortex"])
	var v_target := game.spawn(0)
	v_target.p = Vector2(game.bounds.x / 2, 200)
	var v_nearby := game.spawn(0)
	v_nearby.p = Vector2(game.bounds.x / 2 + 80, 200)
	var dist_before: float = v_target.p.distance_to(v_nearby.p)
	game.auto_attack(v_target, 10, "vortex", 0)
	var dist_after: float = v_target.p.distance_to(v_nearby.p)
	check(dist_after < dist_before and v_nearby.get("vortex_timer", 0.0) > 0, "Vortex tower pulls nearby enemies towards singularity")
	# Teste de Mecânica: Railgun Fotônico perfura múltiplos inimigos na linha
	game.reset()
	game.configure_tower_loadout(["railgun"])
	var r_x: float = game.tower_position(0).x
	var r_target := game.spawn(0)
	r_target.p = Vector2(r_x, 250)
	var r_behind := game.spawn(0)
	r_behind.p = Vector2(r_x, 120)
	var r_target_hp: float = r_target.hp
	var r_behind_hp: float = r_behind.hp
	game.auto_attack(r_target, 10, "railgun", 0)
	check(r_target.hp < r_target_hp and r_behind.hp < r_behind_hp, "Railgun penetrates multiple enemies in firing line")
	# Testes de Formas Geométricas: Pentágono (5 lados) e Heptágono (7 lados)
	var pentagon := game.spawn(4, "", false, false)
	check(pentagon.sides == 5 and pentagon.enemy_id == "pentagon", "Pentagon spawns with 5 geometric sides")
	var heptagon := game.spawn(5, "", false, false)
	check(heptagon.sides == 7 and heptagon.enemy_id == "heptagon", "Heptagon spawns with 7 geometric sides")
	# Testes de Comandantes de Elite (substituindo antigos Mini-Bosses) e Rotação de Bosses
	var elite_commander := game.spawn(-1, "", false, true, true)
	check(elite_commander.elite and not elite_commander.get("is_miniboss", false) and not str(elite_commander.get("elite_type", "")).is_empty(), "Legacy miniboss flag converts into a specialized Elite Commander")
	game.wave = 10
	var colossus_boss := game.spawn(3)
	check(colossus_boss.sides == 10 and colossus_boss.boss_id == "boss_colossus", "Wave 10 boss has decagonal geometry (10 sides) and boss_colossus archetype")
	# Testes dos 10 Novos Inimigos com Formas Geométricas
	var octagon := game.spawn(6, "", false, false)
	check(octagon.sides == 8 and octagon.enemy_id == "octagon", "Octagon spawns with 8 sides")
	var nonagon := game.spawn(7, "", false, false)
	check(nonagon.sides == 9 and nonagon.enemy_id == "nonagon", "Nonagon spawns with 9 sides")
	var decagon := game.spawn(8, "", false, false)
	check(decagon.sides == 10 and decagon.enemy_id == "decagon", "Decagon spawns with 10 sides")
	var hendecagon := game.spawn(9, "", false, false)
	check(hendecagon.sides == 11 and hendecagon.enemy_id == "hendecagon", "Hendecagon spawns with 11 sides")
	var dodecagon := game.spawn(10, "", false, false)
	check(dodecagon.sides == 12 and dodecagon.enemy_id == "dodecagon", "Dodecagon spawns with 12 sides")
	var star4 := game.spawn(11, "", false, false)
	check(star4.enemy_id == "star4" and star4.radius == 20.0, "Star4 spawns correctly")
	var star5 := game.spawn(12, "", false, false)
	check(star5.enemy_id == "star5" and star5.radius == 25.0, "Star5 spawns correctly")
	var prism := game.spawn(13, "", false, false)
	check(prism.enemy_id == "ring_prism" and prism.sides == 6, "Ring Prism spawns with prism properties")
	var singularity := game.spawn(14, "", false, false)
	check(singularity.enemy_id == "spiral_singularity" and singularity.hp > 90, "Spiral Singularity spawns with high density")
	var titan := game.spawn(15, "", false, false)
	check(titan.enemy_id == "titan_tetrahedron" and titan.sides == 4 and titan.hp > 130, "Titan Tetrahedron spawns with massive health")
	# Testes de Inimigos que Atiram, Teleportam e Invocam Lacaios + Novos Bosses e Elites
	game.reset()
	game.spawn_timer = 100.0
	var shooter := game.spawn(16, "", false, false)
	shooter.p = Vector2(300, 180)
	shooter.shoot_timer = 0.01
	game.tick(0.02)
	check(shooter.enemy_id == "void_shooter" and game.enemy_projectiles.size() == 1, "Void Shooter fires projectile toward player base")
	var proj_pos: Vector2 = game.enemy_projectiles[0].p
	game.tap(proj_pos)
	check(game.enemy_projectiles.is_empty() and game.combo == 1, "Tapping an enemy projectile intercepts it and grants combo")
	var artillery := game.spawn(19, "", false, false)
	artillery.p = Vector2(400, 180)
	artillery.shoot_timer = 0.01
	game.tick(0.02)
	check(artillery.enemy_id == "plasma_artillery" and game.enemy_projectiles.size() == 2, "Plasma Artillery fires dual projectiles")
	var teleporter := game.spawn(17, "", false, false)
	teleporter.p = Vector2(200, 150)
	var old_tp_pos: Vector2 = teleporter.p
	teleporter.teleport_timer = 0.01
	game.tick(0.02)
	check(teleporter.enemy_id == "quantum_teleporter" and absf(teleporter.p.x - old_tp_pos.x) > 40.0 and teleporter.p.y > old_tp_pos.y + 20.0, "Quantum Teleporter warps horizontally and advances")
	var summoner := game.spawn(18, "", false, false)
	summoner.p = Vector2(500, 160)
	var enemies_before_summon := game.enemies.size()
	summoner.summon_timer = 0.01
	game.tick(0.02)
	var summoned_minions := game.enemies.filter(func(e): return e.get("is_minion", false)).size()
	check(summoner.enemy_id == "hive_summoner" and game.enemies.size() == enemies_before_summon + 2 and summoned_minions >= 2, "Hive Summoner spawns two minion drones")
	var weaver := game.spawn(20, "", false, false)
	check(weaver.enemy_id == "rift_weaver" and weaver.can_teleport and weaver.can_summon, "Rift Weaver combines teleportation and summoning")
	var elite_storm := game.spawn(0, "elite_storm", true, true)
	check(elite_storm.elite and elite_storm.elite_type == "elite_storm" and elite_storm.can_shoot and elite_storm.can_teleport, "Elite Storm archetype has teleport and shoot abilities")
	var omega_boss := game.spawn(3, "boss_omega")
	check(omega_boss.boss_id == "boss_omega" and omega_boss.sides == 20 and omega_boss.can_shoot and omega_boss.can_teleport and omega_boss.can_summon, "Omega Architect boss combines all supreme abilities")
	# Teste de Migração Schema 8 para Schema 10 e novas pesquisas de ataque/defesa/torres/escudos
	var schema_eight_path := "user://test_schema8_%d.json" % Time.get_ticks_usec()
	file = FileAccess.open(schema_eight_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":8, "scores":[], "best":0, "muted":false, "pieces":[30,30,30,30], "research":[1,1,1,1,1,1,1,1], "enemy_stats":{}, "highest_wave":30, "tower_modules":{"plasma":true,"cryo":true,"arc":true,"pulse":true,"laser":true,"vortex":true,"railgun":true}, "unlocked_tower_slots":4, "tower_loadout":["plasma","cryo","arc","pulse","plasma","plasma","plasma"]}))
	file.close()
	var schema_eight = load("res://scripts/score_store.gd").new()
	schema_eight.path = schema_eight_path
	schema_eight.load_data()
	check(schema_eight.research.size() == GameData.RESEARCH_COUNT and schema_eight.research[7] == 1 and schema_eight.research[8] == 0, "Schema 8 migrates to Schema 13 with all research slots")
	check(schema_eight.buy_research(15) and schema_eight.buy_research(18) and schema_eight.buy_research(32), "Purchasing attack/defense, tower specialization, and shield researches succeeds")
	var full_res: Array[int] = []
	for i in GameData.RESEARCH_COUNT:
		full_res.append(0)
	full_res[15] = 2 # Cofre Quântico (+40 ouro inicial)
	full_res[16] = 2 # Gerador de Emergência (+20 carga inicial)
	full_res[21] = 2 # Hipotermia Profunda (+0.5s slow na torre Cryo)
	game.configure_research(full_res)
	game.reset()
	check(game.gold == 40 and is_equal_approx(game.charge, 40.0), "Cofre Quantico and Gerador de Emergencia apply starting gold and Nova charge")
	game.configure_tower_module("cryo")
	var cryo_res_target := game.spawn(0, "", false, false)
	game.auto_attack(cryo_res_target, 20.0)
	check(is_equal_approx(cryo_res_target.slow_timer, 2.0), "Zero Absoluto tower research extends Cryo slow duration")
	# Teste de Compra Individual de Torres na Partida e Upgrades de Torres / Defesa / Escudos
	game.configure_tower_loadout(["plasma", "cryo", "arc"])
	game.reset()
	check(game.tower_slot_level(0) == 0 and game.tower_slot_level(1) == 0 and game.auto_dps() == 0, "Equipped tower slots start inactive (level 0) until bought in-game")
	game.gold = 500
	check(game.buy_tower_slot(1) and game.tower_slot_level(1) == 1 and game.tower_slot_level(0) == 0 and game.auto_dps() > 0, "Buying tower slot 1 activates only slot 1 individually")
	check(game.buy_upgrade("tower_haste") and game.upg_level("tower_haste") == 1, "Buying tower_haste upgrade increases tower fire rate")
	check(not game.can_buy_upgrade("shield_cap"), "Shield in-game upgrades are locked before researching Gerador de Escudo Quantico")
	full_res[32] = 2 # Gerador de Escudo Quântico Nv.2 -> +50 escudo inicial
	full_res[33] = 1 # Recarga Harmônica de Escudo
	full_res[34] = 1 # Barreira Reflexiva de Plasma
	game.configure_research(full_res)
	game.reset()
	game.gold = 500
	check(game.shield_unlocked() and is_equal_approx(game.max_shield, 50.0) and is_equal_approx(game.shield, 50.0), "Shield research unlocks starting Energy Shield")
	check(game.buy_upgrade("shield_cap") and is_equal_approx(game.max_shield, 85.0), "Buying shield_cap upgrade expands max_shield in-game")
	var hp_before_leak: int = game.hp
	game.apply_base_damage(1, Vector2(300, 600))
	check(game.hp == hp_before_leak and game.shield < game.max_shield, "Energy Shield absorbs base damage before hull HP")
	# Testes do Sistema de Laboratório (Schema 11, Upgrades do Lab, Fila/Timer e Descontos)
	var lab_store = load("res://scripts/score_store.gd").new()
	var lab_path := "user://test_lab_%d.json" % Time.get_ticks_usec()
	lab_store.path = lab_path
	lab_store.pieces.assign([50, 50, 50, 50])
	check(lab_store.lab_research.size() == 3 and not lab_store.is_researching(), "Laboratory initializes with 3 research slots and idle state")
	check(lab_store.buy_lab_research(0), "Buying Synthesis Accelerator upgrades lab")
	check(lab_store.lab_research[0] == 1 and lab_store.lab_time_multiplier() < 1.0, "Synthesis Accelerator reduces research duration")
	check(lab_store.buy_lab_research(1), "Buying Fragment Efficiency upgrades lab")
	check(lab_store.lab_research[1] == 1 and lab_store.lab_cost_multiplier() < 1.0, "Fragment Efficiency reduces piece cost")
	check(lab_store.buy_lab_research(2), "Buying Resonance Matrix upgrades lab")
	check(lab_store.lab_research[2] == 1, "Resonance Matrix activates bonus cashback")
	var signal_payload := {"emitted": false, "name": "", "type": ""}
	lab_store.research_completed.connect(func(res_name: String, res_type: String):
		signal_payload.emitted = true
		signal_payload.name = res_name
		signal_payload.type = res_type
	)
	check(lab_store.start_research(0, false), "Starting timed research enters synthesis state")
	check(lab_store.is_researching() and not lab_store.start_research(1, false), "Laboratory blocks concurrent researches while busy")
	var initial_remaining: float = lab_store.active_research_remaining()
	check(not lab_store.tick_research(0.5), "Research remains active before full duration")
	check(lab_store.active_research_remaining() < initial_remaining, "Research timer advances accurately")
	var pieces_before_complete: int = lab_store.pieces[0]
	check(lab_store.tick_research(initial_remaining), "Research completes upon reaching full duration")
	check(not lab_store.is_researching() and lab_store.research[0] == 1, "Completed research applies rank")
	check(lab_store.pieces[0] == pieces_before_complete + 1, "Resonance Matrix refunds 1 piece upon completion")
	check(signal_payload.emitted and signal_payload.type == "research" and not signal_payload.name.is_empty(), "Research completion emits research_completed signal with correct payload")
	# Teste de tempo de pesquisa offline via persistência e timestamp
	check(lab_store.start_research(1, false), "Second timed research starts successfully")
	lab_store.active_research["last_timestamp"] = int(Time.get_unix_time_from_system()) - 3600
	check(lab_store.save_data(), "Save data with active research and timestamp succeeds")
	var offline_store = load("res://scripts/score_store.gd").new()
	offline_store.path = lab_path
	offline_store.load_data()
	check(not offline_store.is_researching() and offline_store.research[1] == 1, "Offline research timer automatically completes after time lapse on boot")

	# Testes do Sistema de Conquistas (Achievements - Schema 12)
	var ach_signal := {"unlocked": false, "id": "", "title": ""}
	lab_store.achievement_unlocked.connect(func(aid: String, atitle: String, _adesc: String):
		ach_signal.unlocked = true
		ach_signal.id = aid
		ach_signal.title = atitle
	)
	var pieces_before_ach: int = lab_store.pieces[0]
	check(lab_store.unlock_achievement("first_kill"), "Unlocking achievement succeeds")
	check(lab_store.is_achievement_unlocked("first_kill"), "Achievement query returns true")
	check(ach_signal.unlocked and ach_signal.id == "first_kill" and not ach_signal.title.is_empty(), "Achievement signal emitted")
	check(lab_store.pieces[0] > pieces_before_ach, "Achievement awards pieces reward")
	check(not lab_store.unlock_achievement("first_kill"), "Duplicate achievement unlock is rejected")

	# Testes de Conquistas Meta e Passivas
	lab_store.unlocked_tower_slots = 7
	lab_store.check_meta_achievements()
	check(lab_store.is_achievement_unlocked("all_slots"), "Meta achievement all_slots auto-unlocks when slots reach 7")
	for m in GameData.MODULE_IDS:
		lab_store.tower_modules[m] = true
	lab_store.check_meta_achievements()
	check(lab_store.is_achievement_unlocked("all_towers"), "Meta achievement all_towers auto-unlocks when all modules researched")

	# Teste de emissão de conquistas no VoidState (wave_20, combo_30)
	var state_ach_test := VoidState.new()
	var emitted_list: Array[String] = []
	state_ach_test.achievement_triggered.connect(func(aid: String): emitted_list.append(aid))
	state_ach_test.wave = 19
	state_ach_test.next_wave()
	check(emitted_list.has("wave_20"), "Advancing to wave 20 triggers wave_20 achievement")

	# Teste de Migração Schema 11 para Schema 12
	var schema_11_data := {
		"version": 11,
		"scores": [],
		"best": 0,
		"muted": false,
		"pieces": [10, 5, 2, 0],
		"research": GameData.empty_research(),
		"lab_research": [0, 0, 0],
		"active_research": {},
		"enemy_stats": {},
		"highest_wave": 1,
		"tower_modules": {"plasma": true, "cryo": false, "arc": false, "pulse": false, "laser": false, "vortex": false, "railgun": false},
		"unlocked_tower_slots": 1,
		"tower_loadout": ["plasma", "plasma", "plasma", "plasma", "plasma", "plasma", "plasma"]
	}
	var migrated_12: Dictionary = lab_store.migrate(schema_11_data)
	check(migrated_12.get("version") == 14 and migrated_12.has("achievements") and migrated_12.achievements is Array, "Schema 11 correctly migrates to Schema 14 with achievements")
	check(lab_store.valid(migrated_12), "Migrated schema 11 payload passes strict validation")

	# Teste de Boss Multifásico (Fase 2 Overload / Phase thresholds)
	var boss_test_game := VoidState.new()
	boss_test_game.reset()
	var test_boss := boss_test_game.spawn(3)
	check(test_boss.type == 3 and int(test_boss.get("boss_phase", 1)) == 1, "Boss starts in Phase 1")
	var boss_speed_p1: float = test_boss.speed
	# Boss entra em Fase 2 ao sofrer dano abaixo do limiar (0.66)
	boss_test_game.damage_enemy(test_boss, test_boss.max_hp * 0.45)
	check(int(test_boss.get("boss_phase", 1)) == 2 and test_boss.speed > boss_speed_p1, "Boss triggers Overload Phase 2 when HP <= 66%")

	# Teste de Anomalias do Vazio (Wave Anomalies)
	boss_test_game.wave = 5
	boss_test_game.waves_since_miniboss = 0 # impede miniboss na wave 6
	# Com seed fixa determinística garantimos que a wave 6 entre no ramo de anomalia (wave % 3 == 0)
	var found_anomaly := false
	for attempt in 10:
		var anom_game := VoidState.new()
		anom_game.reset()
		anom_game.wave = 5
		anom_game.waves_since_miniboss = 0
		anom_game.next_wave()
		if not anom_game.current_anomaly.is_empty():
			found_anomaly = true
			break
	check(found_anomaly, "Wave 6 triggers void anomaly")
	boss_test_game.current_anomaly = {}
	var prev_click: int = boss_test_game.click_damage()
	boss_test_game.current_anomaly = GameData.ANOMALIES["emp"]
	check(boss_test_game.click_damage() > prev_click, "EMP anomaly multiplies click damage")

	# Teste de Colisão Radial com o Domo e Arco de Escudo
	var col_game := VoidState.new()
	col_game.reset()
	col_game.hp = 100
	var col_center := col_game.dome_center()
	var col_r := col_game.dome_radius()
	var col_enemy := col_game.spawn(0)
	col_enemy.p = col_center - Vector2(0, col_r + col_enemy.radius - 2.0)
	var hp_before_impact: int = col_game.hp
	col_game.tick(0.01)
	check(col_game.hp < hp_before_impact and col_game.enemies.is_empty(), "Enemy touching dome curvature triggers instant damage without reaching floor")

	# Teste de Projétil Inimigo colidindo com o Domo/Escudo
	col_game.reset()
	col_game.hp = 100
	var col_proj := {
		"p": col_center - Vector2(0, col_r + 4.0),
		"v": Vector2(0, 100),
		"damage": 12,
		"radius": 6.0,
		"color": Color.RED,
		"age": 0.0
	}
	col_game.enemy_projectiles.append(col_proj)
	var hp_before_proj: int = col_game.hp
	col_game.tick(0.01)
	check(col_game.hp < hp_before_proj and col_game.enemy_projectiles.is_empty(), "Enemy projectile hitting dome takes damage and is destroyed")

	# Teste de Migração Schema 12 para Schema 14 (38 slots e especializações desmembradas)
	var schema_twelve_path := "user://test_schema12_%d.json" % Time.get_ticks_usec()
	file = FileAccess.open(schema_twelve_path, FileAccess.WRITE)
	var old_res_28: Array = []
	for i in 28:
		old_res_28.append(1)
	file.store_string(JSON.stringify({
		"version": 12,
		"scores": [],
		"best": 500,
		"muted": false,
		"pieces": [50, 50, 50, 50],
		"research": old_res_28,
		"lab_research": [1, 1, 1],
		"active_research": {},
		"achievements": ["first_kill", "wave_5"],
		"enemy_stats": {},
		"highest_wave": 20,
		"tower_modules": {"plasma": true, "cryo": true, "arc": true, "pulse": true, "laser": true, "vortex": true, "railgun": true},
		"unlocked_tower_slots": 3,
		"tower_loadout": ["plasma", "cryo", "arc", "plasma", "plasma", "plasma", "plasma"]
	}))
	file.close()
	var schema_twelve = load("res://scripts/score_store.gd").new()
	schema_twelve.path = schema_twelve_path
	schema_twelve.load_data()
	check(schema_twelve.research.size() == GameData.RESEARCH_COUNT and schema_twelve.research[34] == 1 and schema_twelve.research[35] == 0 and schema_twelve.research[37] == 0, "Schema 12 migrates to Schema 14 with 38 research slots")
	check(schema_twelve.achievements.has("first_kill") and schema_twelve.achievements.has("wave_5"), "Achievements preserved across Schema 14 migration")
	check(schema_twelve.buy_research(35) and schema_twelve.buy_research(36) and schema_twelve.buy_research(37), "Purchasing new drop specialization researches 35, 36, 37 succeeds")

	# Teste de Migração Schema 13 para Schema 14
	var schema_thirteen_path := "user://test_schema13_%d.json" % Time.get_ticks_usec()
	file = FileAccess.open(schema_thirteen_path, FileAccess.WRITE)
	var old_res_31: Array = []
	for i in 31:
		old_res_31.append(2)
	file.store_string(JSON.stringify({
		"version": 13,
		"scores": [],
		"best": 600,
		"muted": false,
		"pieces": [50, 50, 50, 50],
		"research": old_res_31,
		"lab_research": [1, 1, 1],
		"active_research": {},
		"achievements": ["first_kill"],
		"enemy_stats": {},
		"highest_wave": 25,
		"tower_modules": {"plasma": true, "cryo": true, "arc": true, "pulse": true, "laser": true, "vortex": true, "railgun": true},
		"unlocked_tower_slots": 4,
		"tower_loadout": ["plasma", "cryo", "arc", "pulse", "plasma", "plasma", "plasma"]
	}))
	file.close()
	var schema_thirteen = load("res://scripts/score_store.gd").new()
	schema_thirteen.path = schema_thirteen_path
	schema_thirteen.load_data()
	check(schema_thirteen.research.size() == GameData.RESEARCH_COUNT and schema_thirteen.research[18] == 2 and schema_thirteen.research[19] == 2 and schema_thirteen.research[32] == 2 and schema_thirteen.research[37] == 2, "Schema 13 tower and shield researches correctly split and mapped into Schema 14")

	# Teste de Redução de Drops Base e Novas Pesquisas de Drop (17, 35, 36, 37)
	var drop_game := VoidState.new()
	drop_game.reset()
	drop_game.configure_research([0, 0, 0, 0])
	var d_square := drop_game.spawn(0)
	var d_triangle := drop_game.spawn(1)
	var d_hex := drop_game.spawn(2)
	var d_titan := drop_game.spawn(14)

	# Base Square: 6% drop
	check(drop_game.roll_piece_drop(d_square, 0.059) == 1, "Base square drops piece at 5.9% roll")
	check(drop_game.roll_piece_drop(d_square, 0.061) == 0, "Base square fails drop at 6.1% roll (reduced base chance)")

	# Base Triangle: 5% drop
	check(drop_game.roll_piece_drop(d_triangle, 0.049) == 1, "Base triangle drops piece at 4.9% roll")
	check(drop_game.roll_piece_drop(d_triangle, 0.051) == 0, "Base triangle fails drop at 5.1% roll (reduced base chance)")

	# Base Hexagon: 8% drop
	check(drop_game.roll_piece_drop(d_hex, 0.079) == 1, "Base hexagon drops piece at 7.9% roll")
	check(drop_game.roll_piece_drop(d_hex, 0.081) == 0, "Base hexagon fails drop at 8.1% roll (reduced base chance)")

	# Base Titan: 18% drop
	check(drop_game.roll_piece_drop(d_titan, 0.179) == 1, "Base titan drops piece at 17.9% roll")
	check(drop_game.roll_piece_drop(d_titan, 0.181) == 0, "Base titan fails drop at 18.1% roll (reduced base chance)")

	# Pesquisas de Drop 17, 35, 36, 37 ativadas
	var res_drop: Array[int] = []
	for i in GameData.RESEARCH_COUNT:
		res_drop.append(0)
	res_drop[17] = 2 # +6% geral
	res_drop[35] = 2 # +6% em quadrados e triangulos (total +12% em quadrado -> 18%)
	res_drop[36] = 2 # +10% em hexágonos (+20% em elites)
	res_drop[37] = 2 # +8% com critico/combo >= 10, e 50% chance de drop duplo
	drop_game.configure_research(res_drop)

	# Quadrado com Res 17 (+6%) e Res 35 (+6%): chance = 6% + 6% + 6% = 18%
	check(drop_game.roll_piece_drop(d_square, 0.179) == 1, "Square with Research 17 and 35 drops at 17.9% roll")
	check(drop_game.roll_piece_drop(d_square, 0.181) == 0, "Square with Research 17 and 35 fails at 18.1% roll")

	# Hexágono com Res 17 (+6%) e Res 36 (+10%): chance = 8% + 6% + 10% = 24%
	check(drop_game.roll_piece_drop(d_hex, 0.239) == 1, "Hexagon with Research 17 and 36 drops at 23.9% roll")
	check(drop_game.roll_piece_drop(d_hex, 0.241) == 0, "Hexagon with Research 17 and 36 fails at 24.1% roll")

	# Elite com Res 36 (+20% extra):
	var d_elite := drop_game.spawn(0, "", true, true)
	check(drop_game.roll_piece_drop(d_elite, 0.75) >= 2, "Elite with Research 17, 35, and 36 has amplified drop rate and drops at 75% roll")

	# Sobrecarga de Extração (Pesquisa 37):
	d_square.last_hit_crit = true
	check(drop_game.roll_piece_drop(d_square, 0.259, 0.70) == 1, "Research 37 increases drop chance on critical kill without double drop if roll is above 50%")
	check(drop_game.roll_piece_drop(d_square, 0.259, 0.40) == 2, "Research 37 triggers double drop on critical kill when double roll succeeds")

	# Testes de Internacionalização (i18n):
	var i18n = load("res://core/i18n.gd")
	var StoreClass = load("res://scripts/score_store.gd")
	i18n.set_language(i18n.LANG_PT)
	check(i18n.t("menu.play", "") == "▶  JOGAR AGORA", "I18n PT returns JOGAR AGORA")
	check(i18n.t("hud.lang_btn", "") == "IDIOMA: PT", "I18n PT returns IDIOMA: PT")
	check(i18n.get_piece_name(0) == "FRAGMENTO QUADRADO", "I18n PT piece name 0")
	i18n.set_language(i18n.LANG_EN)
	check(i18n.t("menu.play", "") == "▶  PLAY NOW", "I18n EN returns PLAY NOW")
	check(i18n.t("hud.lang_btn", "") == "LANGUAGE: EN", "I18n EN returns LANGUAGE: EN")
	check(i18n.get_piece_name(0) == "SQUARE FRAGMENT", "I18n EN piece name 0")
	check(i18n.get_upgrade_info("click_dmg")[0] == "PLASMA CLICK", "I18n EN upgrade name")
	check(i18n.get_module_info("cryo")[0] == "Cryo Tower", "I18n EN module name")
	check(i18n.get_enemy_info("square")[0] == "SQUARE", "I18n EN enemy name")
	check(i18n.get_achievement_title("first_kill") == "FIRST CONTACT", "I18n EN achievement title")

	# Persistência do Idioma no SaveStore:
	var lang_save_path := "user://test_lang_save.json"
	var lang_store = StoreClass.new()
	lang_store.path = lang_save_path
	lang_store.language = "en"
	check(lang_store.save_data(), "SaveStore successfully saves English language setting")
	var lang_load = StoreClass.new()
	lang_load.path = lang_save_path
	lang_load.load_data()
	check(lang_load.language == "en", "SaveStore correctly loads English language setting")
	check(i18n.current_lang == "en", "SaveStore loading en activates I18n EN")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(lang_save_path + suffix):
			DirAccess.remove_absolute(lang_save_path + suffix)
	i18n.set_language(i18n.LANG_PT)

	# Testes do Sistema Roguelite de Cartas e Perks
	var roguelite_game := VoidState.new()
	roguelite_game.reset()
	var draft_choices := roguelite_game.generate_perk_choices(3)
	check(draft_choices.size() == 3, "generate_perk_choices returns exactly 3 choices")
	check(draft_choices[0].id != draft_choices[1].id and draft_choices[1].id != draft_choices[2].id, "Generated perk choices are distinct")
	check(draft_choices[0].has("name") and draft_choices[0].has("desc") and draft_choices[0].has("rarity"), "Perk choice has name, desc and rarity")

	# Teste de Aplicação de Perks
	var crit_before: float = roguelite_game.crit_chance()
	roguelite_game.apply_perk("crit_surge")
	check(roguelite_game.has_perk("crit_surge") and roguelite_game.get_perk_level("crit_surge") == 1, "Applying crit_surge activates perk and sets level 1")
	check(is_equal_approx(roguelite_game.crit_chance(), crit_before + 0.06), "crit_surge increases crit chance by exactly 6%")

	# Teste de Nano-Repair (+25 max_hp)
	var hp_before_perk: int = roguelite_game.max_hp
	roguelite_game.apply_perk("nano_repair")
	check(roguelite_game.max_hp == hp_before_perk + 25, "nano_repair expands base max HP by 25")

	# Teste de Rapid Trigger (redução de cadência)
	var interval_before: float = roguelite_game.interval_for_module("plasma")
	roguelite_game.apply_perk("rapid_trigger")
	check(roguelite_game.interval_for_module("plasma") < interval_before, "rapid_trigger reduces turret fire interval")

	# Teste de Force Field (+40 max_shield)
	var shield_before: float = roguelite_game.max_shield
	roguelite_game.apply_perk("force_field")
	check(is_equal_approx(roguelite_game.max_shield, shield_before + 40.0), "force_field expands energy shield capacity by 40")

	# Teste de Glass Cannon (stack máximo = 1)
	var hp_before_glass: int = roguelite_game.max_hp
	roguelite_game.apply_perk("glass_cannon")
	check(roguelite_game.has_perk("glass_cannon") and roguelite_game.max_hp < hp_before_glass, "glass_cannon applies and reduces max HP")
	roguelite_game.apply_perk("glass_cannon")
	check(roguelite_game.get_perk_level("glass_cannon") == 1, "glass_cannon respects max_stacks = 1")

	# Teste de Disparo de Draft Pós-Boss (Wave 5 -> 6)
	var draft_emitted := {"count": 0, "choices": []}
	roguelite_game.perk_draft_requested.connect(func(choices: Array[Dictionary]):
		draft_emitted.count += 1
		draft_emitted.choices = choices
	)
	roguelite_game.wave = 5
	roguelite_game.next_wave()
	check(roguelite_game.wave == 6 and roguelite_game.pending_draft and roguelite_game.paused, "Completing boss wave 5 enters pending perk draft and pauses")
	check(draft_emitted.count == 1 and draft_emitted.choices.size() == 3, "perk_draft_requested signal emitted with 3 choices upon completing boss wave")

	# Teste de Limpeza de Perks no Reset
	roguelite_game.reset()
	check(roguelite_game.active_perks.is_empty() and not roguelite_game.pending_draft and not roguelite_game.has_perk("crit_surge"), "Resetting game clears all active ephemeral perks")


	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(lab_path + suffix):
			DirAccess.remove_absolute(lab_path + suffix)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(store.path + suffix):
			DirAccess.remove_absolute(store.path + suffix)
		if FileAccess.file_exists(legacy_path + suffix):
			DirAccess.remove_absolute(legacy_path + suffix)
		if FileAccess.file_exists(schema_two_path + suffix):
			DirAccess.remove_absolute(schema_two_path + suffix)
		if FileAccess.file_exists(schema_three_path + suffix):
			DirAccess.remove_absolute(schema_three_path + suffix)
		if FileAccess.file_exists(schema_four_path + suffix):
			DirAccess.remove_absolute(schema_four_path + suffix)
		if FileAccess.file_exists(schema_five_path + suffix):
			DirAccess.remove_absolute(schema_five_path + suffix)
		if FileAccess.file_exists(schema_six_path + suffix):
			DirAccess.remove_absolute(schema_six_path + suffix)
		if FileAccess.file_exists(schema_seven_path + suffix):
			DirAccess.remove_absolute(schema_seven_path + suffix)
		if FileAccess.file_exists(schema_eight_path + suffix):
			DirAccess.remove_absolute(schema_eight_path + suffix)
		if FileAccess.file_exists(schema_twelve_path + suffix):
			DirAccess.remove_absolute(schema_twelve_path + suffix)
		if FileAccess.file_exists(schema_thirteen_path + suffix):
			DirAccess.remove_absolute(schema_thirteen_path + suffix)
	if failures > 0:
		print("FAIL: %d of %d gameplay/save checks" % [failures, checks])
		quit(1)
	else:
		print("PASS: %d gameplay/save checks" % checks)
		quit()
