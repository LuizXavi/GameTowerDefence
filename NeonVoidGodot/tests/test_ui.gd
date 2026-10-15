extends SceneTree

const WATCHDOG_SECONDS := 180.0

var app: Control
var capture_dir := ProjectSettings.globalize_path("res://").path_join("../screenshots").simplify_path() + "/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(capture_dir)
	create_timer(WATCHDOG_SECONDS).timeout.connect(func():
		printerr("FAIL: UI test watchdog timeout (%ds)" % WATCHDOG_SECONDS)
		quit(2))
	call_deferred("run")

## Falha rápida: encerra o processo com código 1 em vez de abortar a corrotina e travar.
func expect(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("FAIL: " + message)
	quit(1)

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
	expect(app.overlay.find_child("Module_cryo", true, false) == null, "Cryo research is not present in modules hangar")
	await key(KEY_ESCAPE)
	expect(app.phase == "menu", "Escape closes module selection")
	app.store.highest_wave = 5
	app.store.pieces[1] = 8
	# Pesquisar o módulo Criogênico no Laboratório (aba Torres)
	app.show_research()
	app.select_research_tab("towers")
	await process_frame
	var cryo_button: Button = app.overlay.find_child("Module_cryo", true, false)
	expect(cryo_button != null and not cryo_button.disabled, "Cryo research appears in laboratory towers tab after wave five")
	app.ensure_modal_visible(cryo_button)
	await process_frame
	await click(cryo_button.get_global_rect().get_center())
	expect(app.store.tower_modules.cryo and app.store.pieces[1] == 0, "Module research in laboratory consumes pieces and unlocks module")
	await key(KEY_ESCAPE)
	# Abrir a tela de Módulos (Hangar) e equipar o módulo desbloqueado
	app.show_modules()
	await process_frame
	expect(app.overlay.find_child("Module_cryo", true, false) == null, "Module research cards remain absent from modules screen")
	var equip_cryo: Button = app.overlay.find_child("Slot0_cryo", true, false)
	expect(equip_cryo != null and not equip_cryo.disabled, "Researched module enables equip button in hangar slot")
	app.ensure_modal_visible(equip_cryo)
	await process_frame
	await click(equip_cryo.get_global_rect().get_center())
	expect(app.store.equipped_module == "cryo", "Researched tower module can be equipped")
	await capture("NeonVoid-modulos")
	await key(KEY_ESCAPE)
	app.store.pieces[0] = 5
	app.show_research()
	await process_frame
	var research_button: Button = app.overlay.find_child("Research1", true, false)
	expect(app.overlay.find_child("Research19", true, false) != null, "Tower specialization researches appear in laboratory")
	app.ensure_modal_visible(research_button)
	await process_frame
	await click(research_button.get_global_rect().get_center())
	expect(app.store.research[0] == 1 and app.store.pieces[0] == 0, "Research purchase consumes pieces")
	app.store.research[0] = 5
	app.build_research_cards()
	await process_frame
	var toggle_hide: Button = app.overlay.find_child("ToggleHideCompleted", true, false)
	expect(toggle_hide != null, "Hide completed research button exists")
	app.ensure_modal_visible(toggle_hide)
	await process_frame
	await click(toggle_hide.get_global_rect().get_center())
	expect(app.hide_completed_research and app.overlay.find_child("Research1", true, false) == null, "Completed research is hidden when toggle is active")
	toggle_hide = app.overlay.find_child("ToggleHideCompleted", true, false)
	app.ensure_modal_visible(toggle_hide)
	await process_frame
	await click(toggle_hide.get_global_rect().get_center())
	expect(not app.hide_completed_research and app.overlay.find_child("Research1", true, false) != null, "Completed research reappears when toggle is deactivated")
	app.store.research[0] = 1
	app.build_research_cards()
	await process_frame
	await capture("NeonVoid-pesquisas")
	await key(KEY_ESCAPE)
	expect(app.phase == "menu", "Escape closes research")
	await key(KEY_ENTER)
	expect(app.phase == "playing", "Enter starts game")
	expect(app.state.tower_module == "cryo", "Equipped module configures the next run")
	await create_timer(0.15).timeout
	app.state.spawn_timer = 100
	app.state.enemies.clear()
	var enemy: Dictionary = app.state.spawn(0)
	enemy.p = Vector2(260, 240)
	enemy.hp = 1
	var persistent_before: int = app.store.pieces[0]
	app.state.roll_piece_drop(enemy, 0.0)
	expect(app.store.pieces[0] == persistent_before + 1, "Dropped piece reaches persistent inventory")
	await click(app.arena.global_position + enemy.p)
	expect(app.state.kills == 1, "Mouse hit reaches arena")
	app.state.gold = 500
	await key(KEY_2)
	expect(app.state.levels[1] == 1, "Upgrade shortcut")
	app.refresh_hud()
	await click(app.upgrades[0].get_global_rect().get_center())
	expect(app.state.levels[0] == 1, "Upgrade button")
	app.select_shop_tab("towers")
	await process_frame
	expect(app.shop_tab == "towers" and app.shop_items[0]["kind"] == "tower_slot", "Towers tab lists individual tower slots first")
	app.select_shop_tab("defense")
	await process_frame
	expect(app.shop_tab == "defense" and app.shop_items.size() == 7, "Defense tab lists hull and shield upgrades")
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
	# Validar que pesquisa avança normalmente fora do laboratório e dispara notificação toast
	app.store.pieces.assign([50, 50, 50, 50])
	expect(app.store.start_research(2, false), "Research starts while player is in battle")
	expect(app.phase == "playing" and app.store.is_researching(), "Research runs in background outside laboratory")
	var rem: float = app.store.active_research_remaining()
	app.store.tick_research(rem - 0.05)
	app._process(0.1)
	expect(not app.store.is_researching(), "Background research finishes during battle")
	expect(app.toast_panel != null and app.toast_panel.visible, "Toast notification appears on screen upon research finish")
	expect(app.toast_label != null and not app.toast_label.text.is_empty(), "Toast label displays completed research name")
	await capture("NeonVoid-jogo")
	await key(KEY_P)
	expect(app.phase == "paused", "Pause shortcut")
	var previous_time: float = app.state.play_time
	await create_timer(0.2).timeout
	expect(app.state.play_time == previous_time, "Pause freezes gameplay")
	await capture("NeonVoid-pausa")
	await key(KEY_ESCAPE)
	expect(app.phase == "playing", "Escape resumes")
	app.state.charge = 100
	await key(KEY_SPACE)
	expect(app.state.charge < 100, "Space uses Nova")
	app.start_game()
	app.state.hp = 1
	app.state.score = 500
	app.state.spawn(0).p.y = app.arena.size.y
	await process_frame
	await process_frame
	expect(app.phase == "gameover", "Game over modal")
	app.player_name.text = "TEST"
	app.submit_score()
	app.submit_score()
	expect(app.store.scores.size() == 1, "Score saved only once")
	await capture("NeonVoid-fim")
	app.show_menu()
	app.show_codex()
	await process_frame
	expect(app.overlay.find_child("Tab_codex_bosses", true, false) != null, "Codex Bosses tab exists")
	expect(app.overlay.find_child("Tab_codex_elites", true, false) != null, "Codex Elites tab exists")
	expect(app.overlay.find_child("Tab_codex_shooters", true, false) != null, "Codex Shooters tab exists")
	expect(app.overlay.find_child("Tab_codex_shields", true, false) != null, "Codex Shields tab exists")
	expect(app.overlay.find_child("Tab_codex_common", true, false) != null, "Codex Common tab exists")
	expect(app.overlay.find_child("Tab_codex_all", true, false) != null, "Codex All tab exists")
	app.select_codex_tab("bosses")
	await process_frame
	expect(app.codex_tab == "bosses", "Selecting bosses tab switches category")
	app.select_codex_tab("shooters")
	await process_frame
	expect(app.codex_tab == "shooters", "Selecting shooters tab switches category")
	app.select_codex_tab("shields")
	await process_frame
	expect(app.codex_tab == "shields", "Selecting shields tab switches category")
	app.select_codex_tab("all")
	await process_frame
	await capture("NeonVoid-codex")
	await key(KEY_ESCAPE)
	expect(app.phase == "menu", "Escape closes Codex")
	expect(app.menu.find_child("Achievements", true, false) != null, "Achievements button exists on menu")
	app.show_achievements()
	await process_frame
	expect(app.overlay.find_child("Tab_ach_all", true, false) != null, "Achievements All tab exists")
	expect(app.overlay.find_child("Tab_ach_combat", true, false) != null, "Achievements Combat tab exists")
	expect(app.overlay.find_child("Tab_ach_progression", true, false) != null, "Achievements Progression tab exists")
	expect(app.overlay.find_child("Tab_ach_special", true, false) != null, "Achievements Special tab exists")
	expect(app.overlay.find_child("Tab_ach_unlocked", true, false) != null, "Achievements Unlocked tab exists")
	app.select_achievements_tab("combat")
	await process_frame
	expect(app.achievements_tab == "combat", "Selecting achievements combat tab switches category")
	app.select_achievements_tab("all")
	await process_frame
	await capture("NeonVoid-conquistas")
	await key(KEY_ESCAPE)
	expect(app.phase == "menu", "Escape closes Achievements screen")
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
	# Pesquisar Arc no Laboratório (aba Torres)
	app.show_research()
	app.select_research_tab("towers")
	await process_frame
	var arc_button: Button = app.overlay.find_child("Module_arc", true, false)
	expect(arc_button != null and not arc_button.disabled, "Arc research appears in laboratory towers tab after wave ten")
	app.buy_tower_module("arc")
	await key(KEY_ESCAPE)
	# Equipar na tela de Módulos (Hangar)
	app.show_modules()
	await process_frame
	expect(app.overlay.find_child("Module_arc", true, false) == null, "Arc research card is absent from modules hangar")
	app.equip_tower_module(0, "arc")
	expect(app.store.equipped_module == "arc" and app.store.pieces[0] == 0, "Arc module can be researched in laboratory and equipped in hangar")
	await capture("NeonVoid-modulos-640x640")
	print("PASS: graphical UI, research, tower modules, Codex, special enemies, mouse, keyboard, pause, Nova, gameover, ranking and responsive layouts")
	root.remove_child(app)
	app.queue_free()
	await process_frame
	quit()
