extends Control

const Arena = preload("res://scenes/arena.tscn")
const Store = preload("res://scripts/score_store.gd")
const DISPLAY = preload("res://assets/fonts/DisplayBold.tres")
const BODY = preload("res://assets/fonts/Rajdhani.ttf")
# Dados de design centralizados em res://data/game_data.gd (GameData)
const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED
const NAMES := GameData.LEGACY_UPGRADE_NAMES
const DESCS := GameData.LEGACY_UPGRADE_DESCS
const COLORS := GameData.PIECE_COLORS
const PIECE_NAMES := GameData.PIECE_NAMES
const PIECE_SHORT := GameData.PIECE_SHORT
const RESEARCH_NAMES := GameData.RESEARCH_NAMES
const RESEARCH_DESCS := GameData.RESEARCH_DESCS
const MODULE_IDS := GameData.MODULE_IDS
const MODULE_INFO := GameData.MODULE_INFO
const CODEX_ORDER := GameData.CODEX_ORDER
const ENEMY_INFO := GameData.ENEMY_INFO
var state := VoidState.new()
var store = Store.new()
var phase := "menu"
var menu: Control
var game: VBoxContainer
var arena: Control
var overlay: Control
var body: BoxContainer
var shop: VBoxContainer
var shop_tabs_row: HBoxContainer
var shop_scroll: ScrollContainer
var shop_grid: GridContainer
var shop_tab: String = "attack"
var shop_items: Array[Dictionary] = []
var hud_score: Label
var hud_gold: Label
var hud_wave: Label
var hud_hp: Label
var hp_bar: ProgressBar
var wave_bar: ProgressBar
var mini_stats: Label
var nova_button: Button
var upgrades: Array[Button] = []
var mute_buttons: Array[Button] = []
var sfx: Dictionary = {}
var saved := false
var save_status: Label
var player_name: LineEdit
var final_ranking: Control
var sound_pool: Array[AudioStreamPlayer] = []
var pool_index := 0
var update_time := 0.0
var test_mode := false
var hud_pieces: Label
var research_content: VBoxContainer
var modules_content: VBoxContainer
var module_status := ""
var modal_return_focus: Control
var hide_completed_research := false

const UPG_ATTACK_IDS := GameData.UPG_ATTACK_IDS
const UPG_TOWER_IDS := GameData.UPG_TOWER_IDS
const UPG_DEFENSE_IDS := GameData.UPG_DEFENSE_IDS
const IN_GAME_UPG_INFO := GameData.UPGRADE_INFO

func _ready() -> void:
	get_window().min_size = Vector2i(640, 640)
	test_mode = "--test-mode" in OS.get_cmdline_user_args()
	if test_mode:
		store.path = "user://test_ui_records.json"
	else:
		store.load_data()
	state.configure_research(store.research)
	state.configure_tower_loadout(store.tower_loadout.slice(0, store.unlocked_tower_slots))
	theme = preload("res://ui/neon_theme.tres")
	for kind in ["click", "crit", "kill", "leak", "buy", "deny", "wave", "bomb", "gameover", "start", "shield"]:
		sfx[kind] = load("res://assets/audio/" + kind + ".wav")
	# Síntese procedural de efeitos sonoros especiais em tempo real
	sfx["laser"] = SoundManager._synth_sweep(880.0, 260.0, 0.12, 0.35)
	sfx["pulse"] = SoundManager._synth_sweep(130.0, 42.0, 0.35, 0.55)
	sfx["spark"] = SoundManager._synth_sweep(1600.0, 600.0, 0.06, 0.25)
	sfx["boss"] = SoundManager._synth_sweep(240.0, 75.0, 0.65, 0.60)
	sfx["vortex"] = SoundManager._synth_sweep(320.0, 65.0, 0.45, 0.45)
	sfx["railgun"] = SoundManager._synth_sweep(1800.0, 150.0, 0.22, 0.55)
	for i in 12:
		var player := AudioStreamPlayer.new()
		player.volume_db = -7
		add_child(player)
		sound_pool.append(player)
	state.sound.connect(play_sound)
	state.ended.connect(game_over)
	state.piece_dropped.connect(on_piece_dropped)
	state.enemy_discovered.connect(on_enemy_discovered)
	state.enemy_defeated.connect(on_enemy_defeated)
	build_game()
	state.effect.connect(arena.fx)
	build_menu()
	resized.connect(responsive)
	get_window().focus_exited.connect(func():
		if phase == "playing" and not test_mode:
			pause_game())
	responsive()
	show_menu()

func build_game() -> void:
	game = VBoxContainer.new()
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.add_theme_constant_override("separation", 0)
	add_child(game)
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", UIFactory.box(Color("8b5cf6"), Color("0b0420"), 0))
	game.add_child(header_panel)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 22)
	header_panel.add_child(header)
	var logo := UIFactory.label("NEON VOID\nDEFESA INCREMENTAL", 12, CYAN, true)
	logo.name = "Logo"
	header.add_child(logo)
	hud_score = UIFactory.label("PONTOS\n0", 17, Color.WHITE, true)
	header.add_child(hud_score)
	hud_gold = UIFactory.label("◈ 0", 17, LIME, true)
	header.add_child(hud_gold)
	hud_pieces = UIFactory.label("■0 ▲0 ⬢0 ✦0", 12, AMBER, true)
	header.add_child(hud_pieces)
	hud_wave = UIFactory.label("WAVE 1", 13, PINK, true)
	header.add_child(hud_wave)
	wave_bar = UIFactory.make_bar(PINK)
	wave_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wave_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(wave_bar)
	hp_bar = UIFactory.make_bar(CYAN)
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(hp_bar)
	hud_hp = UIFactory.label("100", 13, CYAN, true)
	header.add_child(hud_hp)
	var mute := UIFactory.button("SOM", toggle_mute)
	header.add_child(mute)
	mute_buttons.append(mute)
	header.add_child(UIFactory.button("Ⅱ", pause_game))
	body = BoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	game.add_child(body)
	var arena_wrap := Control.new()
	arena_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(arena_wrap)
	arena = Arena.instantiate()
	arena.name = "Arena"
	arena.state = state
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_wrap.add_child(arena)
	mini_stats = UIFactory.label("", 15, MUTED)
	mini_stats.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mini_stats.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	mini_stats.position = Vector2(-330, 12)
	mini_stats.size.x = 310
	mini_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	arena_wrap.add_child(mini_stats)
	nova_button = UIFactory.button("NOVA\n20%", func(): state.nova(), PINK, true)
	nova_button.name = "Nova"
	nova_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	nova_button.offset_left = -104
	nova_button.offset_top = -95
	nova_button.offset_right = -18
	nova_button.offset_bottom = -14
	arena_wrap.add_child(nova_button)
	var shop_panel := PanelContainer.new()
	shop_panel.name = "Upgrades"
	shop_panel.add_theme_stylebox_override("panel", UIFactory.box(Color("8b5cf6"), Color("0b0420"), 0))
	shop_panel.custom_minimum_size.x = 308
	body.add_child(shop_panel)
	shop = VBoxContainer.new()
	shop.add_theme_constant_override("separation", 10)
	shop_panel.add_child(shop)
	shop.add_child(UIFactory.label("↑  EVOLUÇÕES", 15, Color.WHITE, true))
	shop.add_child(UIFactory.label("Gaste ouro por categoria.", 16, MUTED))
	shop_tabs_row = HBoxContainer.new()
	shop_tabs_row.name = "ShopTabs"
	shop_tabs_row.add_theme_constant_override("separation", 6)
	shop.add_child(shop_tabs_row)
	var tab_defs := [
		["attack", "   ATAQUE", PINK, "TabAttack"],
		["towers", "   TORRES", LIME, "TabTowers"],
		["defense", "   DEFESA", CYAN, "TabDefense"]
	]
	for tdef in tab_defs:
		var tid: String = tdef[0]
		var tlabel: String = tdef[1]
		var tcol: Color = tdef[2]
		var tname: String = tdef[3]
		var tbtn := UIFactory.button(tlabel, func(): select_shop_tab(tid), tcol, shop_tab == tid)
		tbtn.name = tname
		tbtn.custom_minimum_size.y = 38
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.add_theme_font_size_override("font_size", 11)
		tbtn.draw.connect(func(): NeonIcons.draw_ui(tbtn, tid, 7.5, Vector2(18.0, tbtn.size.y * 0.5), Color.WHITE if shop_tab == tid else tcol))
		shop_tabs_row.add_child(tbtn)
	shop_scroll = ScrollContainer.new()
	shop_scroll.name = "ShopScroll"
	shop_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_scroll.custom_minimum_size.y = 320
	shop.add_child(shop_scroll)
	shop_grid = GridContainer.new()
	shop_grid.columns = 1
	shop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_grid.add_theme_constant_override("v_separation", 10)
	shop_grid.add_theme_constant_override("h_separation", 10)
	shop_scroll.add_child(shop_grid)
	rebuild_shop_cards()
	var note := UIFactory.label("1–4  atalho rápido\nESPAÇO  Pulso Nova\nP / ESC  pausar", 16, MUTED)
	note.name = "Note"
	shop.add_child(note)
	var help := UIFactory.panel(shop, CYAN)
	help.get_parent().name = "TipPanel"
	var words := UIFactory.label("COMBOS = MAIS PODER\nCompre cada torre na aba TORRES\ne pesquise Escudos no Laboratório.", 15, MUTED)
	help.add_child(words)

func select_shop_tab(tab_id: String) -> void:
	shop_tab = tab_id
	ShopView.style_tabs(shop_tabs_row, shop_tab)
	rebuild_shop_cards()
	refresh_hud()

func buy_in_game_upgrade(upg_id: String) -> void:
	if state.buy_upgrade(upg_id):
		refresh_hud()

func buy_in_game_tower_slot(slot_idx: int) -> void:
	if state.buy_tower_slot(slot_idx):
		refresh_hud()

func rebuild_shop_cards() -> void:
	ShopView.rebuild_cards(self)

func build_menu() -> void:
	MenuScreen.build(self)

func ranking(parent: Node, compact := false) -> Control:
	return MenuScreen.build_ranking(parent, store.scores, compact)

func responsive() -> void:
	if not is_instance_valid(body):
		return
	if phase == "modules" and is_instance_valid(modules_content):
		modules_content.custom_minimum_size.x = minf(620, size.x - 112)
	if phase == "research" and is_instance_valid(research_content):
		research_content.custom_minimum_size.x = minf(680, size.x - 112)
	if is_instance_valid(overlay):
		for choices in overlay.find_children("SlotChoices*", "GridContainer", true, false):
			choices.columns = 1 if size.x < 700 else 3
	var narrow := size.x < 1000
	body.vertical = narrow
	shop_grid.columns = 2 if narrow else 1
	body.get_node("Upgrades").custom_minimum_size.x = 0 if narrow else 308
	shop.get_node("Note").visible = not narrow
	shop.get_node("TipPanel").visible = not narrow
	for buy in upgrades:
		if is_instance_valid(buy):
			buy.custom_minimum_size.y = 76 if narrow else 92
	var header: HBoxContainer = game.get_child(0).get_child(0)
	header.get_node("Logo").visible = size.x >= 1100
	hp_bar.visible = size.x >= 800
	header.add_theme_constant_override("separation", 10 if narrow else 22)
	mini_stats.visible = size.x >= 900
	if is_instance_valid(menu):
		var stack := menu.find_child("MenuContent", true, false) as VBoxContainer
		if stack != null:
			stack.custom_minimum_size.x = minf(960, maxf(480, size.x - 70))
			stack.get_node("Cards").vertical = size.x < 700
			stack.get_node("Lower").vertical = size.x < 1000

func start_game() -> void:
	record_wave_progress()
	close_overlay()
	phase = "playing"
	menu.hide()
	game.show()
	arena.clear_fx()
	state.configure_research(store.research)
	state.configure_tower_loadout(store.tower_loadout.slice(0, store.unlocked_tower_slots))
	state.reset()
	record_wave_progress()
	saved = false
	select_shop_tab("attack")

func pieces_text(values: Array = store.pieces) -> String:
	return MenuScreen.pieces_text(values)

func focus_menu_button(node_name: String) -> void:
	var target := menu.find_child(node_name, true, false) as Control
	if target != null:
		target.grab_focus()

func tower_loadout_text() -> String:
	return MenuScreen.tower_loadout_text(store)

func show_modules() -> void:
	phase = "modules"
	module_status = ""
	modules_content = modal()
	modules_content.custom_minimum_size.x = minf(620, size.x - 112)
	var title := UIFactory.center_label(modules_content, "⌖  MÓDULOS DA TORRE", 23, PINK, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var intro := UIFactory.center_label(modules_content, "Pesquise módulos e libere até 7 slots.\nEscolha um módulo por slot antes da partida.\nMódulos podem se repetir; cada slot dispara sozinho.", 18, MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_module_cards(true)

func build_module_cards(initial_focus := false) -> void:
	ModulesScreen.build(self, initial_focus)

func get_modal_scroll_v() -> int:
	if not is_instance_valid(overlay):
		return 0
	var scroll := overlay.find_child("ModalScroll", true, false) as ScrollContainer
	return scroll.scroll_vertical if scroll != null else 0

func restore_modal_scroll_v(saved_v: int, target_action: String = "") -> void:
	if not is_instance_valid(overlay):
		return
	var scroll := overlay.find_child("ModalScroll", true, false) as ScrollContainer
	if scroll == null:
		return
	scroll.scroll_vertical = saved_v
	var restore_cb := func():
		if not is_instance_valid(scroll):
			return
		scroll.scroll_vertical = saved_v
		if not target_action.is_empty():
			var btn := overlay.find_child(target_action, true, false) as Button
			if btn != null and not btn.disabled:
				btn.grab_focus()
			elif is_instance_valid(btn):
				scroll.ensure_control_visible(btn)
	restore_cb.call_deferred()

func section_header_with_icon(parent: Node, title_text: String, icon_id: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var icon_ctrl := Control.new()
	icon_ctrl.custom_minimum_size = Vector2(24, 24)
	icon_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_ctrl.draw.connect(func(): NeonIcons.draw_ui(icon_ctrl, icon_id, 8.5, icon_ctrl.size * 0.5, color))
	row.add_child(icon_ctrl)
	var lbl := UIFactory.label(title_text, 15, color, true)
	row.add_child(lbl)
	parent.add_child(row)
	return row

func append_hide_completed_button(parent: VBoxContainer) -> void:
	var toggle_text := "      OCULTAR PESQUISAS CONCLUÍDAS: ATIVO" if hide_completed_research else "      OCULTAR PESQUISAS CONCLUÍDAS: INATIVO"
	var toggle_col := LIME if hide_completed_research else MUTED
	var toggle_btn := UIFactory.button(toggle_text, toggle_hide_completed_research, toggle_col)
	toggle_btn.name = "ToggleHideCompleted"
	toggle_btn.custom_minimum_size.y = 40
	toggle_btn.draw.connect(func():
		var icon_x := maxf(24.0, toggle_btn.size.x * 0.5 - 190.0)
		NeonIcons.draw_ui(toggle_btn, "eye_on" if hide_completed_research else "eye_off", 8.5, Vector2(icon_x, toggle_btn.size.y * 0.5), LIME if hide_completed_research else CYAN)
	)
	parent.add_child(toggle_btn)

func toggle_hide_completed_research() -> void:
	var saved_scroll := get_modal_scroll_v()
	hide_completed_research = not hide_completed_research
	play_sound("click")
	if phase == "research":
		build_research_cards(false)
	elif phase == "modules":
		build_module_cards(false)
	restore_modal_scroll_v(saved_scroll, "ToggleHideCompleted")

func append_module_cards(parent: VBoxContainer) -> void:
	ModulesScreen.append_module_cards(self, parent)

func append_tower_slots(parent: VBoxContainer) -> void:
	ModulesScreen.append_tower_slots(self, parent)

func append_slot_expansion(parent: VBoxContainer, laboratory := false) -> void:
	ModulesScreen.append_slot_expansion(self, parent, laboratory)

func append_module_status(parent: VBoxContainer) -> void:
	ModulesScreen.append_module_status(self, parent)

func buy_tower_module(module_id: String) -> void:
	var previous_pieces: Array = store.pieces.duplicate()
	var previous_modules: Dictionary = store.tower_modules.duplicate(true)
	if not store.research_module(module_id):
		play_sound("deny")
		return
	if not test_mode and not store.save_data():
		store.pieces.assign(previous_pieces)
		store.tower_modules = previous_modules
		module_status = "Falha ao salvar. Peças preservadas; tente novamente."
		play_sound("deny")
	else:
		module_status = "✓ Módulo pesquisado. Escolha em qualquer slot na seleção de módulos."
		play_sound("buy")
	refresh_module_screen("Module_" + module_id)

func buy_tower_slot(index: int) -> void:
	var previous_pieces: Array = store.pieces.duplicate()
	var previous_slots: int = store.unlocked_tower_slots
	var previous_loadout: Array = store.tower_loadout.duplicate()
	if not store.research_slot(index):
		play_sound("deny")
		return
	if not test_mode and not store.save_data():
		store.pieces.assign(previous_pieces)
		store.unlocked_tower_slots = previous_slots
		store.tower_loadout.assign(previous_loadout)
		module_status = "Falha ao salvar. Peças e slots preservados; tente novamente."
		play_sound("deny")
	else:
		module_status = "✓ Slot %d liberado com Plasma. Escolha seu módulo antes da partida." % (index + 1)
		play_sound("buy")
	refresh_module_screen("Slot%d_plasma" % index if phase == "modules" else "ResearchSlot%d" % store.unlocked_tower_slots)

func equip_tower_module(index: int, module_id: String) -> void:
	var previous: Array = store.tower_loadout.duplicate()
	if not store.equip_module_in_slot(index, module_id):
		play_sound("deny")
		return
	if not test_mode and not store.save_data():
		store.tower_loadout.assign(previous)
		module_status = "Falha ao salvar a seleção. Tente novamente."
		play_sound("deny")
	else:
		module_status = "✓ %s equipada no slot %d para a próxima partida." % [MODULE_INFO[module_id][0], index + 1]
		play_sound("buy")
	refresh_module_screen("Slot%d_%s" % [index, module_id])

func refresh_module_screen(action_name: String) -> void:
	var saved_scroll := get_modal_scroll_v()
	if phase == "research":
		build_research_cards(false)
	else:
		build_module_cards(false)
	restore_modal_scroll_v(saved_scroll, action_name)

func close_modules() -> void:
	show_menu()
	focus_menu_button("Modules")

func focus_first_modal_action() -> void:
	for candidate in overlay.find_children("*", "Button", true, false):
		if not candidate.disabled:
			candidate.grab_focus()
			return

func contain_modal_focus() -> void:
	var controls: Array[Control] = []
	for candidate in overlay.find_children("*", "Control", true, false):
		if candidate.focus_mode != Control.FOCUS_NONE and candidate.is_visible_in_tree():
			if candidate is BaseButton and candidate.disabled:
				continue
			controls.append(candidate)
	for i in controls.size():
		var previous := controls[(i - 1 + controls.size()) % controls.size()]
		var following := controls[(i + 1) % controls.size()]
		controls[i].focus_previous = controls[i].get_path_to(previous)
		controls[i].focus_next = controls[i].get_path_to(following)
		controls[i].focus_neighbor_top = controls[i].get_path_to(previous)
		controls[i].focus_neighbor_bottom = controls[i].get_path_to(following)
		controls[i].focus_neighbor_left = controls[i].get_path_to(previous)
		controls[i].focus_neighbor_right = controls[i].get_path_to(following)

func record_wave_progress() -> void:
	if phase not in ["playing", "paused", "gameover"] or state.wave <= store.highest_wave:
		return
	var previous: int = store.highest_wave
	store.record_wave_reached(state.wave)
	for mid in store.MODULE_WAVES:
		var target_wave: int = store.MODULE_WAVES[mid]
		if previous < target_wave and store.highest_wave >= target_wave:
			arena.fx("piece", arena.size * Vector2(0.5, 0.25), CYAN, "NOVO MÓDULO NO MENU: %s" % MODULE_INFO[mid][0].to_upper())
	for index in range(1, store.SLOT_WAVES.size()):
		var discovered_wave: int = store.SLOT_WAVES[index]
		if previous < discovered_wave and store.highest_wave >= discovered_wave:
			arena.fx("piece", arena.size * Vector2(0.5, 0.34), LIME, "SLOT %d DESCOBERTO • LABORATÓRIO" % (index + 1))
	if not test_mode and not store.save_data():
		push_warning("A maior wave foi mantida nesta sessão, mas ainda não pôde ser gravada.")

func show_research() -> void:
	phase = "research"
	module_status = ""
	research_content = modal()
	research_content.custom_minimum_size.x = minf(680, size.x - 112)
	var title := UIFactory.center_label(research_content, "⌬  LABORATÓRIO DE PESQUISAS", 23, CYAN, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var intro := UIFactory.center_label(research_content, "Inimigos podem soltar peças da própria estrutura.\n■ 30%   ▲ 22%   ⬢ 40%   ✦ Boss: 100% (2 peças)\nUse cada família para liberar melhorias permanentes.", 18, Color("cfc7dd"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_research_cards(true)

func build_research_cards(initial_focus := false) -> void:
	ResearchScreen.build(self, initial_focus)

func research_icon_id(index: int) -> String:
	return GameData.research_icon(index)

func buy_research(index: int) -> void:
	var saved_scroll := get_modal_scroll_v()
	var previous_pieces: Array[int] = store.pieces.duplicate()
	var previous_research: Array[int] = store.research.duplicate()
	if not store.buy_research(index):
		play_sound("deny")
		return
	if not test_mode and not store.save_data():
		store.pieces.assign(previous_pieces)
		store.research.assign(previous_research)
		play_sound("deny")
		return
	state.configure_research(store.research)
	play_sound("buy")
	var action_name := "Research%d" % (index + 1)
	build_research_cards(false)
	restore_modal_scroll_v(saved_scroll, action_name)

func close_research() -> void:
	show_menu()
	focus_menu_button("Research")

func show_codex() -> void:
	phase = "codex"
	var content := modal()
	CodexScreen.build(self, content)

func close_codex() -> void:
	phase = "menu"
	close_overlay()

func on_piece_dropped(kind: int, amount: int, position: Vector2, enemy_id: String, from_elite: bool) -> void:
	store.pieces[kind] += amount
	store.record_piece(enemy_id, amount)
	if from_elite:
		store.record_piece("elite", amount)
	arena.fx("piece", position - Vector2(0, 26), COLORS[kind], "+%d %s" % [amount, PIECE_SHORT[kind]])

func on_enemy_discovered(enemy_id: String) -> void:
	if store.record_seen(enemy_id) and not test_mode and not store.save_data():
		push_warning("A descoberta foi mantida nesta sessão, mas ainda não pôde ser gravada.")

func on_enemy_defeated(enemy_id: String, at_wave: int) -> void:
	store.record_kill(enemy_id, at_wave)
	if not test_mode and not store.save_data():
		push_warning("O progresso do Codex foi mantido nesta sessão, mas ainda não pôde ser gravado.")

func show_menu() -> void:
	record_wave_progress()
	state.running = false
	state.paused = false
	phase = "menu"
	close_overlay()
	game.hide()
	build_menu()
	menu.show()

func close_overlay() -> void:
	if is_instance_valid(modal_return_focus):
		modal_return_focus.grab_focus()
	modal_return_focus = null
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
		overlay = null

func modal() -> VBoxContainer:
	close_overlay()
	modal_return_focus = get_viewport().gui_get_focus_owner()
	overlay = ColorRect.new()
	overlay.color = Color(0.005, 0.002, 0.02, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var scroll := ScrollContainer.new()
	scroll.name = "ModalScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	overlay.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var margins := UIFactory.margin(center, 24)
	var content := UIFactory.panel(margins, CYAN)
	content.custom_minimum_size.x = 480
	content.add_theme_constant_override("separation", 14)
	return content

func ensure_modal_visible(target: Control) -> void:
	if not is_instance_valid(overlay) or not is_instance_valid(target):
		return
	var scroll := overlay.find_child("ModalScroll", true, false) as ScrollContainer
	if scroll != null:
		scroll.ensure_control_visible(target)

func pause_game() -> void:
	if phase == "paused":
		phase = "playing"
		state.paused = false
		close_overlay()
		return
	if phase != "playing":
		return
	phase = "paused"
	state.paused = true
	var content := modal()
	UIFactory.center_label(content, "Ⅱ", 38, CYAN, true)
	UIFactory.center_label(content, "PAUSADO", 28, Color.WHITE, true)
	UIFactory.center_label(content, "%d PONTOS     W%d     %d OURO" % [state.score, state.wave, state.gold], 14, LIME, true)
	var resume := UIFactory.button("▶  CONTINUAR", pause_game, LIME, true)
	content.add_child(resume)
	content.add_child(UIFactory.button("REINICIAR", start_game))
	content.add_child(UIFactory.button("MENU", show_menu))
	UIFactory.center_label(content, "P / ESC para continuar • R reinicia", 16, MUTED)
	resume.grab_focus()

func game_over() -> void:
	record_wave_progress()
	phase = "gameover"
	var record: bool = state.score > store.best
	store.best = maxi(store.best, state.score)
	var persisted: bool = true if test_mode else store.save_data()
	var content := modal()
	UIFactory.center_label(content, "BASE DESTRUÍDA", 27, Color("ff5577"), true)
	if record:
		UIFactory.center_label(content, "♛  NOVO RECORDE!", 14, AMBER, true)
	UIFactory.center_label(content, str(state.score), 48, Color.WHITE, true)
	UIFactory.center_label(content, "P O N T U A Ç Ã O  F I N A L", 12, MUTED)
	UIFactory.center_label(content, "W%d     %d ABATES     %d OURO\nx%d COMBO     %s" % [state.wave, state.kills, state.total_gold, state.max_combo, time_text(state.play_time)], 17, CYAN)
	UIFactory.center_label(content, "PEÇAS COLETADAS   " + pieces_text(state.run_pieces), 14, AMBER, true)
	if store.qualifies(state.score):
		UIFactory.center_label(content, "TOP 10 — REGISTRE SEU NOME", 12, AMBER, true)
		player_name = LineEdit.new()
		player_name.placeholder_text = "SEU NOME"
		player_name.max_length = 10
		player_name.custom_minimum_size.y = 42
		content.add_child(player_name)
		var save_button := UIFactory.button("SALVAR", submit_score, AMBER, true)
		save_button.name = "SaveScore"
		content.add_child(save_button)
		player_name.text_submitted.connect(func(_text): submit_score())
		player_name.grab_focus()
	save_status = UIFactory.center_label(content, "" if persisted else "Não foi possível salvar o recorde no disco.", 15, AMBER)
	content.add_child(UIFactory.button("JOGAR NOVAMENTE", start_game, PINK, true))
	content.add_child(UIFactory.button("VOLTAR AO MENU", show_menu))
	final_ranking = ranking(content)

func submit_score() -> void:
	if saved or phase != "gameover":
		return
	var nickname := player_name.text.strip_edges().to_upper()
	if nickname.is_empty():
		nickname = "JOGADOR"
	var previous: Array = store.scores.duplicate(true)
	store.scores.append({"name": nickname, "score": state.score, "wave": state.wave, "kills": state.kills, "gold": state.total_gold, "max_combo": state.max_combo})
	store.scores.sort_custom(func(a, b): return a.score > b.score)
	store.scores = store.scores.slice(0, 10)
	if not test_mode and not store.save_data():
		store.scores = previous
		save_status.text = "Falha ao salvar. Tente novamente."
		return
	saved = true
	player_name.editable = false
	save_status.text = "✓ Pontuação salva no ranking!"
	save_status.add_theme_color_override("font_color", LIME)
	var content := save_status.get_parent()
	content.get_node("SaveScore").disabled = true
	content.remove_child(final_ranking)
	final_ranking.queue_free()
	final_ranking = ranking(content)
	play_sound("buy")

func toggle_mute() -> void:
	store.muted = not store.muted
	if store.muted:
		for player in sound_pool:
			player.stop()
	for b in mute_buttons:
		if is_instance_valid(b):
			b.text = "Som: OFF" if store.muted else "Som: ON"
	if not test_mode and not store.save_data():
		push_warning("Não foi possível salvar a preferência de som.")

func play_sound(kind: String) -> void:
	if kind == "wave":
		record_wave_progress()
	if store.muted or not sfx.has(kind):
		return
	var player := sound_pool[pool_index]
	pool_index = (pool_index + 1) % sound_pool.size()
	player.stream = sfx[kind]
	player.pitch_scale = 1 + minf(1.2, state.combo * 0.06) if kind == "kill" else 1.0
	player.play()

func time_text(seconds: float) -> String:
	return "%d:%02d" % [int(seconds / 60), int(seconds) % 60]

func refresh_hud() -> void:
	record_wave_progress()
	hud_score.text = "PONTOS\n%s" % NumberFormat.format_int(state.score)
	hud_gold.text = "◈ %s" % NumberFormat.format(float(state.gold), 1)
	hud_pieces.text = pieces_text(state.run_pieces)
	hud_wave.text = "WAVE %d\n%d/%d" % [state.wave, state.wave_kills, state.quota()]
	hud_hp.text = "%d  +%d ESC" % [state.hp, int(floor(state.shield))] if state.max_shield > 0 else str(state.hp)
	hp_bar.value = state.hp * 100.0 / state.max_hp
	wave_bar.value = state.wave_kills * 100.0 / state.quota()
	mini_stats.text = "%s abates   |   %s   |   %s dmg   |   %s/s" % [NumberFormat.format_int(state.kills), time_text(state.play_time), NumberFormat.format_int(state.click_damage()), NumberFormat.format_int(state.auto_dps())]
	nova_button.text = "NOVA!\nESPAÇO" if state.charge >= 100 else "NOVA\n%d%%" % state.charge
	nova_button.disabled = state.charge < 100
	ShopView.refresh_items(self)

func _process(dt: float) -> void:
	state.tick(dt)
	update_time += dt
	if update_time >= 0.1 and phase == "playing":
		update_time = 0
		refresh_hud()

const UPGRADE_ACTIONS := ["upgrade_1", "upgrade_2", "upgrade_3", "upgrade_4"]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_action("confirm") and phase in ["menu", "gameover"]:
		start_game()
	elif event.is_action("cancel") and phase == "research":
		close_research()
	elif event.is_action("cancel") and phase == "modules":
		close_modules()
	elif event.is_action("cancel") and phase == "codex":
		close_codex()
	elif event.is_action("restart") and phase in ["playing", "paused", "gameover"]:
		start_game()
	elif event.is_action("pause"):
		pause_game()
	elif event.is_action("mute"):
		toggle_mute()
	elif phase == "playing":
		if event.is_action("nova"):
			state.nova()
		else:
			for i in UPGRADE_ACTIONS.size():
				if event.is_action(UPGRADE_ACTIONS[i]):
					state.buy(i)
					break
	get_viewport().set_input_as_handled()
