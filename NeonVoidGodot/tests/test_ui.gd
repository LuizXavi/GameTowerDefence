extends SceneTree

var app: Control
var capture_dir := "res://../"

func _initialize() -> void:
	call_deferred("run")

func capture(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir + file_name + ".png")

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame

func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await create_timer(0.5).timeout
	await capture("NeonVoid-menu")
	app.show_modules()
	await process_frame
	assert(app.overlay.find_child("Module_cryo", true, false) == null, "Cryo module stays hidden before wave five")
	await key(KEY_ESCAPE)
	assert(app.phase == "menu", "Escape closes module selection")
	app.store.highest_wave = 5
	app.store.pieces[1] = 8
	app.show_modules()
	await process_frame
	var cryo_button: Button = app.overlay.find_child("Module_cryo", true, false)
	assert(cryo_button != null and not cryo_button.disabled, "Cryo research appears after wave five")
	app.ensure_modal_visible(cryo_button)
	await process_frame
	await click(cryo_button.get_global_rect().get_center())
	cryo_button = app.overlay.find_child("Slot0_cryo", true, false)
	assert(app.store.tower_modules.cryo and app.store.pieces[1] == 0 and cryo_button != null and not cryo_button.disabled, "Module research consumes pieces and enables equip")
	app.ensure_modal_visible(cryo_button)
	await process_frame
	await click(cryo_button.get_global_rect().get_center())
	assert(app.store.equipped_module == "cryo", "Researched tower module can be equipped")
	await capture("NeonVoid-modulos")
	await key(KEY_ESCAPE)
	app.store.pieces[0] = 5
	app.show_research()
	await process_frame
	var research_button: Button = app.overlay.find_child("Research1", true, false)
	assert(app.overlay.find_child("Research19", true, false) != null, "Tower specialization researches appear in laboratory")
	app.ensure_modal_visible(research_button)
	await process_frame
	await click(research_button.get_global_rect().get_center())
	assert(app.store.research[0] == 1 and app.store.pieces[0] == 0, "Research purchase consumes pieces")
	app.store.research[0] = 5
	app.build_research_cards()
	await process_frame
	var toggle_hide: Button = app.overlay.find_child("ToggleHideCompleted", true, false)
	assert(toggle_hide != null, "Hide completed research button exists")
	app.ensure_modal_visible(toggle_hide)
	await process_frame
	await click(toggle_hide.get_global_rect().get_center())
	assert(app.hide_completed_research and app.overlay.find_child("Research1", true, false) == null, "Completed research is hidden when toggle is active")
	toggle_hide = app.overlay.find_child("ToggleHideCompleted", true, false)
	app.ensure_modal_visible(toggle_hide)
	await process_frame
	await click(toggle_hide.get_global_rect().get_center())
	assert(not app.hide_completed_research and app.overlay.find_child("Research1", true, false) != null, "Completed research reappears when toggle is deactivated")
	app.store.research[0] = 1
	app.build_research_cards()
	await process_frame
	await capture("NeonVoid-pesquisas")
	await key(KEY_ESCAPE)
	assert(app.phase == "menu", "Escape closes research")
	await key(KEY_ENTER)
	assert(app.phase == "playing", "Enter starts game")
	assert(app.state.tower_module == "cryo", "Equipped module configures the next run")
	await create_timer(0.15).timeout
	app.state.spawn_timer = 100
	app.state.enemies.clear()
	var enemy: Dictionary = app.state.spawn(0)
	enemy.p = Vector2(260, 240)
	enemy.hp = 1
	var persistent_before: int = app.store.pieces[0]
	app.state.roll_piece_drop(enemy, 0.0)
	assert(app.store.pieces[0] == persistent_before + 1, "Dropped piece reaches persistent inventory")
	await click(app.arena.global_position + enemy.p)
	assert(app.state.kills == 1, "Mouse hit reaches arena")
	app.state.gold = 500
	await key(KEY_2)
	assert(app.state.levels[1] == 1, "Upgrade shortcut")
	app.refresh_hud()
	await click(app.upgrades[0].get_global_rect().get_center())
	assert(app.state.levels[0] == 1, "Upgrade button")
	app.select_shop_tab("towers")
	await process_frame
	assert(app.shop_tab == "towers" and app.shop_items[0]["kind"] == "tower_slot", "Towers tab lists individual tower slots first")
	app.select_shop_tab("defense")
	await process_frame
	assert(app.shop_tab == "defense" and app.shop_items.size() == 7, "Defense tab lists hull and shield upgrades")
	app.select_shop_tab("attack")
	await process_frame
	var showcases := [[0, "armored"], [1, "ghost"], [2, "regen"], [0, "splitter"], [1, "thief"]]
	for i in showcases.size():
		enemy = app.state.spawn(showcases[i][0], showcases[i][1], false, false)
		enemy.p = Vector2(110 + i * 155, 170 + (i % 2) * 220)
		enemy.age = 2.2 if showcases[i][1] == "ghost" else 1.0
	enemy = app.state.spawn(2, "", true, true)
	enemy.p = Vector2(650, 520)
	enemy.age = 1.0
	enemy = app.state.spawn(3)
	enemy.p = Vector2(490, 230)
	enemy.age = 1.0
	app.state.auto_timer = 100
	app.state.tick(0.01)
	app.state.banner_time = 0
	app.refresh_hud()
	await capture("NeonVoid-jogo")
	await key(KEY_P)
	assert(app.phase == "paused", "Pause shortcut")
	var previous_time: float = app.state.play_time
	await create_timer(0.2).timeout
	assert(app.state.play_time == previous_time, "Pause freezes gameplay")
	await capture("NeonVoid-pausa")
	await key(KEY_ESCAPE)
	assert(app.phase == "playing", "Escape resumes")
	app.state.charge = 100
	await key(KEY_SPACE)
	assert(app.state.charge < 100, "Space uses Nova")
	app.start_game()
	app.state.hp = 1
	app.state.score = 500
	app.state.spawn(0).p.y = app.arena.size.y
	await process_frame
	await process_frame
	assert(app.phase == "gameover", "Game over modal")
	app.player_name.text = "TEST"
	app.submit_score()
	app.submit_score()
	assert(app.store.scores.size() == 1, "Score saved only once")
	await capture("NeonVoid-fim")
	app.show_menu()
	app.show_codex()
	await capture("NeonVoid-codex")
	await key(KEY_ESCAPE)
	assert(app.phase == "menu", "Escape closes Codex")
	root.content_scale_size = Vector2i(800, 900)
	root.size = Vector2i(800, 900)
	await create_timer(0.2).timeout
	app.build_menu()
	app.responsive()
	await capture("NeonVoid-menu-compacto")
	app.start_game()
	await create_timer(0.3).timeout
	await capture("NeonVoid-jogo-compacto")
	app.show_menu()
	root.content_scale_size = Vector2i(640, 800)
	root.size = Vector2i(640, 800)
	await create_timer(0.2).timeout
	app.show_research()
	await capture("NeonVoid-pesquisas-640")
	await key(KEY_ESCAPE)
	app.show_modules()
	await capture("NeonVoid-modulos-640")
	await key(KEY_ESCAPE)
	root.content_scale_size = Vector2i(640, 640)
	root.size = Vector2i(640, 640)
	app.store.highest_wave = 10
	app.store.pieces[0] = 12
	app.show_modules()
	await process_frame
	var arc_button: Button = app.overlay.find_child("Module_arc", true, false)
	assert(arc_button != null and not arc_button.disabled, "Arc research appears after wave ten")
	app.buy_tower_module("arc")
	app.equip_tower_module(0, "arc")
	assert(app.store.equipped_module == "arc" and app.store.pieces[0] == 0, "Arc module can be researched and equipped")
	await capture("NeonVoid-modulos-640x640")
	print("PASS: graphical UI, research, tower modules, Codex, special enemies, mouse, keyboard, pause, Nova, gameover, ranking and responsive layouts")
	root.remove_child(app)
	app.queue_free()
	await process_frame
	quit()
