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
	var ui_theme := Theme.new()
	ui_theme.default_font = BODY
	ui_theme.default_font_size = 18
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

func box(color: Color = Color("8b5cf6"), fill: Color = Color("110727"), radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(color, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func label(words: String, font_size := 18, color := Color.WHITE, display := false) -> Label:
	var node := Label.new()
	node.text = words
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	if display:
		node.add_theme_font_override("font", DISPLAY)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func button(words: String, callback: Callable, color := CYAN, primary := false) -> Button:
	var node := Button.new()
	node.text = words
	node.custom_minimum_size.y = 44
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", DISPLAY)
	node.add_theme_font_size_override("font_size", 12)
	node.add_theme_stylebox_override("normal", box(color, Color("5122a1") if primary else Color("140b29"), 12))
	if primary:
		var gradient_style := StyleBoxTexture.new()
		gradient_style.texture = preload("res://assets/button_gradient.svg")
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			gradient_style.set_texture_margin(side, 16)
			gradient_style.set_content_margin(side, 14)
		node.add_theme_stylebox_override("normal", gradient_style)
	var hover := box(color, Color("281448"), 12)
	hover.border_color = color
	hover.shadow_color = Color(color, 0.2)
	hover.shadow_size = 12
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("pressed", box(color, Color("38204d"), 12))
	node.add_theme_stylebox_override("focus", box(color, Color(0, 0, 0, 0), 12))
	node.add_theme_stylebox_override("disabled", box(Color("42364f"), Color("100a20"), 12))
	node.add_theme_color_override("font_disabled_color", Color("756d83"))
	node.pressed.connect(callback)
	return node

func panel(parent: Node, color := Color("8b5cf6")) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", box(color))
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(frame)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	frame.add_child(content)
	return content

func margin(parent: Node, amount: int) -> MarginContainer:
	var node := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		node.add_theme_constant_override("margin_" + side, amount)
	parent.add_child(node)
	return node

func center_label(parent: Node, words: String, font_size: int, color: Color, display := false) -> Label:
	var node := label(words, font_size, color, display)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(node)
	return node

func spacer(parent: Node, height: float) -> void:
	var node := Control.new()
	node.custom_minimum_size.y = height
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)

func make_bar(color: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.custom_minimum_size = Vector2(100, 8)
	node.add_theme_stylebox_override("background", box(Color.TRANSPARENT, Color("282136"), 8))
	var fill := box(Color.TRANSPARENT, color, 8)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	node.add_theme_stylebox_override("fill", fill)
	return node

func build_game() -> void:
	game = VBoxContainer.new()
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.add_theme_constant_override("separation", 0)
	add_child(game)
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", box(Color("8b5cf6"), Color("0b0420"), 0))
	game.add_child(header_panel)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 22)
	header_panel.add_child(header)
	var logo := label("NEON VOID\nDEFESA INCREMENTAL", 12, CYAN, true)
	logo.name = "Logo"
	header.add_child(logo)
	hud_score = label("PONTOS\n0", 17, Color.WHITE, true)
	header.add_child(hud_score)
	hud_gold = label("◈ 0", 17, LIME, true)
	header.add_child(hud_gold)
	hud_pieces = label("■0 ▲0 ⬢0 ✦0", 12, AMBER, true)
	header.add_child(hud_pieces)
	hud_wave = label("WAVE 1", 13, PINK, true)
	header.add_child(hud_wave)
	wave_bar = make_bar(PINK)
	wave_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wave_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(wave_bar)
	hp_bar = make_bar(CYAN)
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(hp_bar)
	hud_hp = label("100", 13, CYAN, true)
	header.add_child(hud_hp)
	var mute := button("SOM", toggle_mute)
	header.add_child(mute)
	mute_buttons.append(mute)
	header.add_child(button("Ⅱ", pause_game))
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
	mini_stats = label("", 15, MUTED)
	mini_stats.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mini_stats.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	mini_stats.position = Vector2(-330, 12)
	mini_stats.size.x = 310
	mini_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	arena_wrap.add_child(mini_stats)
	nova_button = button("NOVA\n20%", func(): state.nova(), PINK, true)
	nova_button.name = "Nova"
	nova_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	nova_button.offset_left = -104
	nova_button.offset_top = -95
	nova_button.offset_right = -18
	nova_button.offset_bottom = -14
	arena_wrap.add_child(nova_button)
	var shop_panel := PanelContainer.new()
	shop_panel.name = "Upgrades"
	shop_panel.add_theme_stylebox_override("panel", box(Color("8b5cf6"), Color("0b0420"), 0))
	shop_panel.custom_minimum_size.x = 308
	body.add_child(shop_panel)
	shop = VBoxContainer.new()
	shop.add_theme_constant_override("separation", 10)
	shop_panel.add_child(shop)
	shop.add_child(label("↑  EVOLUÇÕES", 15, Color.WHITE, true))
	shop.add_child(label("Gaste ouro por categoria.", 16, MUTED))
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
		var tbtn := button(tlabel, func(): select_shop_tab(tid), tcol, shop_tab == tid)
		tbtn.name = tname
		tbtn.custom_minimum_size.y = 38
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.add_theme_font_size_override("font_size", 11)
		tbtn.draw.connect(func(): draw_neon_ui_icon(tbtn, tid, 7.5, Vector2(18.0, tbtn.size.y * 0.5), Color.WHITE if shop_tab == tid else tcol))
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
	var note := label("1–4  atalho rápido\nESPAÇO  Pulso Nova\nP / ESC  pausar", 16, MUTED)
	note.name = "Note"
	shop.add_child(note)
	var help := panel(shop, CYAN)
	help.get_parent().name = "TipPanel"
	var words := label("COMBOS = MAIS PODER\nCompre cada torre na aba TORRES\ne pesquise Escudos no Laboratório.", 15, MUTED)
	help.add_child(words)

func select_shop_tab(tab_id: String) -> void:
	shop_tab = tab_id
	if is_instance_valid(shop_tabs_row):
		var tab_colors := {"attack": PINK, "towers": LIME, "defense": CYAN}
		var tab_map := {"TabAttack": "attack", "TabTowers": "towers", "TabDefense": "defense"}
		for child in shop_tabs_row.get_children():
			if child is Button and tab_map.has(child.name):
				var tid: String = tab_map[child.name]
				var col: Color = tab_colors[tid]
				var active := (tid == shop_tab)
				child.add_theme_stylebox_override("normal", box(col, Color("3b1778") if active else Color("140b29"), 10))
				child.add_theme_color_override("font_color", Color.WHITE if active else col)
				child.queue_redraw()
	rebuild_shop_cards()
	refresh_hud()

func buy_in_game_upgrade(upg_id: String) -> void:
	if state.buy_upgrade(upg_id):
		refresh_hud()

func buy_in_game_tower_slot(slot_idx: int) -> void:
	if state.buy_tower_slot(slot_idx):
		refresh_hud()

func rebuild_shop_cards() -> void:
	if not is_instance_valid(shop_grid):
		return
	for child in shop_grid.get_children():
		shop_grid.remove_child(child)
		child.queue_free()
	upgrades.clear()
	shop_items.clear()
	var narrow := size.x < 1000
	var card_index := 0
	if shop_tab == "towers":
		for slot_idx in state.tower_loadout.size():
			card_index += 1
			var mod_id: String = state.tower_loadout[slot_idx]
			var info: Array = MODULE_INFO.get(mod_id, MODULE_INFO["plasma"])
			var col: Color = info[2]
			var buy := button("", func(): buy_in_game_tower_slot(slot_idx), col)
			buy.name = "TowerSlot%d" % (slot_idx + 1)
			buy.alignment = HORIZONTAL_ALIGNMENT_LEFT
			buy.custom_minimum_size.y = 76 if narrow else 92
			buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buy.add_theme_font_override("font", BODY)
			buy.add_theme_font_size_override("font_size", 16)
			buy.add_theme_color_override("font_color", col)
			buy.draw.connect(func(): draw_tower_module_icon(buy, mod_id, 13.0, Vector2(buy.size.x - 32.0, buy.size.y * 0.5)))
			shop_grid.add_child(buy)
			upgrades.append(buy)
			shop_items.append({"kind": "tower_slot", "slot_index": slot_idx, "button": buy})
	var upg_list: Array = UPG_ATTACK_IDS if shop_tab == "attack" else (UPG_TOWER_IDS if shop_tab == "towers" else UPG_DEFENSE_IDS)
	for upg_id in upg_list:
		card_index += 1
		var uinfo: Array = IN_GAME_UPG_INFO[upg_id]
		var ucol: Color = uinfo[2]
		var buy := button("", func(): buy_in_game_upgrade(upg_id), ucol)
		buy.name = "Upgrade%d" % card_index
		buy.alignment = HORIZONTAL_ALIGNMENT_LEFT
		buy.custom_minimum_size.y = 76 if narrow else 92
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy.add_theme_font_override("font", BODY)
		buy.add_theme_font_size_override("font_size", 16)
		buy.add_theme_color_override("font_color", ucol)
		buy.draw.connect(func():
			var is_locked_shield: bool = (upg_id in ["shield_cap", "shield_regen", "shield_pulse"] and not state.shield_unlocked())
			draw_neon_ui_icon(buy, "lock" if is_locked_shield else str(upg_id), 12.5, Vector2(buy.size.x - 32.0, buy.size.y * 0.5), Color("756d83") if is_locked_shield else ucol)
		)
		shop_grid.add_child(buy)
		upgrades.append(buy)
		shop_items.append({"kind": "upgrade", "id": upg_id, "button": buy})


func build_menu() -> void:
	if is_instance_valid(menu):
		remove_child(menu)
		menu.queue_free()
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://shaders/menu.gdshader")
	bg.material = shader_material
	menu.add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	menu.add_child(scroll)
	var centering := CenterContainer.new()
	centering.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centering.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(centering)
	var margins := margin(centering, 28)
	var stack := VBoxContainer.new()
	stack.name = "MenuContent"
	stack.custom_minimum_size.x = minf(960, maxf(480, size.x - 70))
	stack.add_theme_constant_override("separation", 7)
	margins.add_child(stack)
	if store.best > 0:
		center_label(stack, "♛  RECORDE: %d" % store.best, 12, AMBER, true)
	center_label(stack, "//  D E F E S A  I N C R E M E N T A L  //", 12, CYAN, true)
	var title := center_label(stack, "NEON\nVOID", 82, Color.WHITE, true)
	title.add_theme_constant_override("line_spacing", -14)
	var title_material := ShaderMaterial.new()
	title_material.shader = preload("res://shaders/title.gdshader")
	title.material = title_material
	center_label(stack, "Clique. Evolua. Sobreviva.", 24, Color("d4cee0"))
	spacer(stack, 10)
	var start := button("▶  JOGAR AGORA", start_game, PINK, true)
	start.name = "Start"
	start.custom_minimum_size = Vector2(328, 58)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 18)
	stack.add_child(start)
	var modules_button := button("⌖  MÓDULOS DA TORRE", show_modules, PINK)
	modules_button.name = "Modules"
	modules_button.custom_minimum_size = Vector2(328, 48)
	modules_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(modules_button)
	center_label(stack, "Slots liberados: %d/7" % store.unlocked_tower_slots, 16, CYAN)
	var loadout := center_label(stack, tower_loadout_text(), 17, MUTED)
	loadout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var research_button := button("⌬  LABORATÓRIO DE PESQUISAS", show_research, CYAN)
	research_button.name = "Research"
	research_button.custom_minimum_size = Vector2(328, 48)
	research_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(research_button)
	var codex_button := button("◈  CODEX DOS INIMIGOS", show_codex, AMBER)
	codex_button.name = "Codex"
	codex_button.custom_minimum_size = Vector2(328, 44)
	codex_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(codex_button)
	center_label(stack, pieces_text(), 14, AMBER, true)
	center_label(stack, "ou pressione ENTER", 14, MUTED)
	spacer(stack, 5)
	center_label(stack, "✧  Dica: Combos aumentam dano e ouro — não erre!", 18, Color("d9cdb8"))
	spacer(stack, 12)
	var cards := BoxContainer.new()
	cards.name = "Cards"
	cards.vertical = size.x < 700
	cards.add_theme_constant_override("separation", 12)
	stack.add_child(cards)
	var headings := ["1 • DESTRUA", "2 • EVOLUA", "3 • SOBREVIVA"]
	var descriptions := ["Toque/clique nos inimigos antes que atinjam sua base. Combos dão mais dano e ouro.", "Gaste ouro em Clique, Torreta Auto, Crítico e Escudo. Custo sobe, poder explode.", "Segure as waves e o BOSS. Pulso Nova (ESPAÇO) limpa a tela em emergência."]
	for i in 3:
		var content := panel(cards, [PINK, LIME, CYAN][i])
		content.add_child(label(["⌖", "↑", "✧"][i], 24, [PINK, LIME, CYAN][i], true))
		content.add_child(label(headings[i], 13, [PINK, LIME, CYAN][i], true))
		var desc := label(descriptions[i], 18, Color("bfb7cf"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(desc)
	var lower := BoxContainer.new()
	lower.name = "Lower"
	lower.vertical = size.x < 1000
	lower.add_theme_constant_override("separation", 12)
	stack.add_child(lower)
	var controls := panel(lower, CYAN)
	controls.add_child(label("CONTROLES", 12, CYAN, true))
	controls.add_child(label("Mouse / Touch     Toque nos inimigos para atirar\n1–4   Upgrades        ESPAÇO   Nova\nP / ESC   Pausa       R   Reiniciar", 18, Color("bfb7cf")))
	ranking(lower, true)
	spacer(stack, 8)
	var mute := button("Som: OFF" if store.muted else "Som: ON", toggle_mute)
	mute.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(mute)
	mute_buttons.append(mute)
	center_label(stack, "v1.0 • Godot • recorde local", 13, Color("726781"))

func ranking(parent: Node, compact := false) -> Control:
	var content := panel(parent, AMBER)
	content.add_child(label("♛  RANKING LOCAL                         TOP 10", 11, AMBER, true))
	if store.scores.is_empty():
		content.add_child(label("Nenhum recorde ainda.\nSeja o primeiro a dominar o Void!", 18, MUTED))
	else:
		for i in mini(store.scores.size(), 3 if compact else 10):
			var entry: Dictionary = store.scores[i]
			content.add_child(label("#%d   %-10s     W%d     %d" % [i + 1, entry.name, entry.wave, entry.score], 15, AMBER if i == 0 else Color("cfc7dd")))
	return content.get_parent()

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
	return "  ".join(PackedStringArray([
		"■ %d" % int(values[0]),
		"▲ %d" % int(values[1]),
		"⬢ %d" % int(values[2]),
		"✦ %d" % int(values[3])
	]))

func focus_menu_button(node_name: String) -> void:
	var target := menu.find_child(node_name, true, false) as Control
	if target != null:
		target.grab_focus()

func tower_loadout_text() -> String:
	var summary: PackedStringArray = []
	for index in store.unlocked_tower_slots:
		var module_id: String = store.tower_loadout[index]
		summary.append("%d · %s" % [index + 1, MODULE_INFO[module_id][0]])
	return "   |   ".join(summary)

func show_modules() -> void:
	phase = "modules"
	module_status = ""
	modules_content = modal()
	modules_content.custom_minimum_size.x = minf(620, size.x - 112)
	var title := center_label(modules_content, "⌖  MÓDULOS DA TORRE", 23, PINK, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var intro := center_label(modules_content, "Pesquise módulos e libere até 7 slots.\nEscolha um módulo por slot antes da partida.\nMódulos podem se repetir; cada slot dispara sozinho.", 18, MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_module_cards()

func build_module_cards() -> void:
	for child in modules_content.get_children():
		if child.name == "DynamicModules":
			modules_content.remove_child(child)
			child.queue_free()
	var dynamic := VBoxContainer.new()
	dynamic.name = "DynamicModules"
	dynamic.add_theme_constant_override("separation", 10)
	modules_content.add_child(dynamic)
	center_label(dynamic, pieces_text(), 16, AMBER, true)
	append_tower_slots(dynamic)
	append_slot_expansion(dynamic)
	append_module_cards(dynamic)
	append_module_status(dynamic)
	var close := button("VOLTAR AO MENU", close_modules, PINK)
	close.name = "CloseModules"
	dynamic.add_child(close)
	contain_modal_focus()
	focus_first_modal_action()

func section_header_with_icon(parent: Node, title_text: String, icon_id: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var icon_ctrl := Control.new()
	icon_ctrl.custom_minimum_size = Vector2(24, 24)
	icon_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_ctrl.draw.connect(func(): draw_neon_ui_icon(icon_ctrl, icon_id, 8.5, icon_ctrl.size * 0.5, color))
	row.add_child(icon_ctrl)
	var lbl := label(title_text, 15, color, true)
	row.add_child(lbl)
	parent.add_child(row)
	return row

func append_hide_completed_button(parent: VBoxContainer) -> void:
	var toggle_text := "      OCULTAR PESQUISAS CONCLUÍDAS: ATIVO" if hide_completed_research else "      OCULTAR PESQUISAS CONCLUÍDAS: INATIVO"
	var toggle_col := LIME if hide_completed_research else MUTED
	var toggle_btn := button(toggle_text, toggle_hide_completed_research, toggle_col)
	toggle_btn.name = "ToggleHideCompleted"
	toggle_btn.custom_minimum_size.y = 40
	toggle_btn.draw.connect(func():
		var icon_x := maxf(24.0, toggle_btn.size.x * 0.5 - 190.0)
		draw_neon_ui_icon(toggle_btn, "eye_on" if hide_completed_research else "eye_off", 8.5, Vector2(icon_x, toggle_btn.size.y * 0.5), LIME if hide_completed_research else CYAN)
	)
	parent.add_child(toggle_btn)

func toggle_hide_completed_research() -> void:
	hide_completed_research = not hide_completed_research
	play_sound("click")
	if phase == "research":
		build_research_cards()
	elif phase == "modules":
		build_module_cards()
	var toggle_btn := overlay.find_child("ToggleHideCompleted", true, false) as Button
	if toggle_btn != null:
		toggle_btn.grab_focus()

func append_module_cards(parent: VBoxContainer) -> void:
	section_header_with_icon(parent, "PESQUISA DE MÓDULOS", "towers", PINK)
	if phase == "modules":
		append_hide_completed_button(parent)
	var undiscovered := false
	var shown_count := 0
	for module_id in MODULE_IDS:
		if not store.module_visible(module_id):
			undiscovered = true
			continue
		var info: Array = MODULE_INFO[module_id]
		var unlocked: bool = store.module_unlocked(module_id)
		if hide_completed_research and unlocked:
			continue
		shown_count += 1
		var card := panel(parent, info[2])

		var card_row := HBoxContainer.new()
		card_row.add_theme_constant_override("separation", 14)
		card.add_child(card_row)

		var icon := Control.new()
		icon.custom_minimum_size = Vector2(58, 58)
		icon.draw.connect(func(): draw_tower_module_icon(icon, module_id))
		card_row.add_child(icon)

		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.add_theme_constant_override("separation", 3)
		card_row.add_child(text_col)

		var heading := label(info[0], 17, info[2], true)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(heading)
		var desc := label(info[1], 16, Color("d4cee0"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(desc)

		var action: Button
		if unlocked:
			var status := label("✓ PESQUISADO • disponível em todos os slots", 15, LIME)
			status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(status)
			continue
		else:
			var cost: Dictionary = store.module_cost(module_id)
			var index: int = cost.piece_index
			var costs := label("BLOQUEADO • Custo: %d %s • Você tem: %d" % [int(cost.amount), PIECE_SHORT[index], store.pieces[index]], 16, MUTED)
			costs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(costs)
			action = button("PESQUISAR" if store.can_research_module(module_id) else "PESQUISAR • PEÇAS INSUFICIENTES", func(): buy_tower_module(module_id), info[2])
			action.disabled = not store.can_research_module(module_id)
		action.name = "Module_" + module_id
		card.add_child(action)
	if shown_count == 0 and hide_completed_research:
		center_label(parent, "✓ Todos os módulos descobertos já foram pesquisados.", 15, LIME)
	if undiscovered:
		var next_wave := 5
		for mid in MODULE_IDS:
			if not store.module_visible(mid):
				next_wave = int(store.MODULE_WAVES[mid])
				break
		var hint := label("◇  Novo módulo: alcance a wave %d para descobrir." % next_wave, 18, MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(hint)

func append_tower_slots(parent: VBoxContainer) -> void:
	center_label(parent, "SLOTS LIBERADOS: %d/7" % store.unlocked_tower_slots, 16, CYAN, true)
	for index in store.unlocked_tower_slots:
		var selected: String = store.tower_loadout[index]
		var card := panel(parent, MODULE_INFO[selected][2])

		var head_row := HBoxContainer.new()
		head_row.add_theme_constant_override("separation", 10)
		card.add_child(head_row)

		var slot_icon := Control.new()
		slot_icon.custom_minimum_size = Vector2(32, 32)
		slot_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot_icon.draw.connect(func(): draw_tower_module_icon(slot_icon, selected, 11.0))
		head_row.add_child(slot_icon)

		var heading := label("SLOT %d  •  %s" % [index + 1, MODULE_INFO[selected][0]], 16, MODULE_INFO[selected][2], true)
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head_row.add_child(heading)

		var choices := GridContainer.new()
		choices.name = "SlotChoices%d" % index
		choices.columns = 1 if size.x < 700 else 3
		choices.add_theme_constant_override("h_separation", 8)
		choices.add_theme_constant_override("v_separation", 8)
		card.add_child(choices)
		for module_id in MODULE_IDS:
			if not store.module_unlocked(module_id):
				continue
			var module_names: Dictionary = {
				"plasma": "PLASMA",
				"cryo": "CRIOGÊNICA",
				"arc": "ARCO",
				"pulse": "SÍSMICA",
				"laser": "LASER",
				"vortex": "VÓRTICE",
				"railgun": "RAILGUN"
			}
			var module_name: String = str(module_names.get(module_id, module_id.to_upper()))
			var equipped: bool = selected == module_id
			var action := button("", func(): equip_tower_module(index, module_id), MODULE_INFO[module_id][2])
			action.name = "Slot%d_%s" % [index, module_id]
			action.tooltip_text = "Equipado neste slot" if equipped else "Equipar %s no slot %d" % [MODULE_INFO[module_id][0], index + 1]
			action.disabled = equipped
			action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			action.custom_minimum_size = Vector2(0, 48)

			var btn_content := HBoxContainer.new()
			btn_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			btn_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_content.alignment = BoxContainer.ALIGNMENT_CENTER
			btn_content.add_theme_constant_override("separation", 8)
			action.add_child(btn_content)

			if equipped:
				var check := label("✓", 13, LIME, true)
				check.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn_content.add_child(check)

			var btn_icon := Control.new()
			btn_icon.custom_minimum_size = Vector2(26, 26)
			btn_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_icon.draw.connect(func(): draw_tower_module_icon(btn_icon, module_id, 8.5))
			btn_content.add_child(btn_icon)

			var btn_label := label(module_name, 12, Color.WHITE if equipped else MODULE_INFO[module_id][2], true)
			btn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_content.add_child(btn_label)

			choices.add_child(action)

func draw_tower_module_icon(control: Control, module_id: String, base_radius: float = 16.0, custom_center: Vector2 = Vector2(-1, -1)) -> void:
	var center: Vector2 = custom_center if custom_center.x >= 0.0 else control.size * 0.5
	var color: Color = MODULE_INFO.get(module_id, ["", "", PINK])[2]
	var dir := Vector2.UP # Mirando para cima
	var scale_factor: float = base_radius / 16.0

	# Anel externo da torreta com fundo escuro
	var outer_r: float = base_radius + 4.0 * scale_factor
	control.draw_circle(center, outer_r, Color("0b061c"))
	control.draw_arc(center, outer_r, 0.0, TAU, 24, Color(color, 0.35), maxf(1.0, 1.5 * scale_factor), true)
	control.draw_circle(center, base_radius, Color("140933"))
	control.draw_arc(center, base_radius, 0.0, TAU, 24, color, maxf(1.0, 2.0 * scale_factor), true)

	# Silhuetas distintivas de cada arma
	match module_id:
		"plasma":
			# Canhão principal de plasma frontal + núcleo brilhante
			control.draw_line(center, center + dir * (base_radius + 9.0 * scale_factor), color, maxf(1.5, 4.0 * scale_factor), true)
			control.draw_line(center, center + dir * (base_radius + 9.0 * scale_factor), Color.WHITE, maxf(1.0, 1.5 * scale_factor), true)
			control.draw_circle(center, maxf(1.5, 4.0 * scale_factor), Color.WHITE)
		"cryo":
			# Canhão ciano com aletas refrigeradoras em cruz
			control.draw_line(center, center + dir * (base_radius + 8.0 * scale_factor), color, maxf(1.5, 3.5 * scale_factor), true)
			var wing: Vector2 = dir.orthogonal() * (7.0 * scale_factor)
			control.draw_line(center + dir * (6.0 * scale_factor) - wing, center + dir * (6.0 * scale_factor) + wing, color, maxf(1.0, 2.0 * scale_factor), true)
			control.draw_line(center + dir * (12.0 * scale_factor) - wing * 0.6, center + dir * (12.0 * scale_factor) + wing * 0.6, Color.WHITE, maxf(1.0, 1.5 * scale_factor), true)
		"arc":
			# Bobina tesla dupla para condutores de choque
			for side in [-1, 1]:
				var offset: Vector2 = dir.orthogonal() * (float(side) * 6.0 * scale_factor)
				control.draw_line(center + offset, center + offset + dir * (base_radius + 8.0 * scale_factor), color, maxf(1.0, 2.5 * scale_factor), true)
				control.draw_circle(center + offset + dir * (base_radius + 8.0 * scale_factor), maxf(1.2, 2.5 * scale_factor), Color.WHITE)
			control.draw_line(center - dir.orthogonal() * (6.0 * scale_factor), center + dir.orthogonal() * (6.0 * scale_factor), Color(color, 0.7), maxf(1.0, 1.5 * scale_factor), true)
		"pulse":
			# Emissor sísmico com anéis concêntricos de choque
			control.draw_arc(center, base_radius * 0.5, 0.0, TAU, 16, Color.WHITE, maxf(1.0, 2.0 * scale_factor), true)
			control.draw_arc(center, base_radius + 7.0 * scale_factor, 0.0, TAU, 20, Color(color, 0.8), maxf(1.0, 2.0 * scale_factor), true)
			control.draw_circle(center, maxf(1.5, 3.0 * scale_factor), color)
		"laser":
			# Projetor óptico com lentes convergentes pontiagudas
			control.draw_line(center - dir.orthogonal() * (5.0 * scale_factor), center + dir * (base_radius + 10.0 * scale_factor), color, maxf(1.0, 2.5 * scale_factor), true)
			control.draw_line(center + dir.orthogonal() * (5.0 * scale_factor), center + dir * (base_radius + 10.0 * scale_factor), color, maxf(1.0, 2.5 * scale_factor), true)
			control.draw_line(center, center + dir * (base_radius + 10.0 * scale_factor), Color.WHITE, maxf(1.0, 2.0 * scale_factor), true)
			control.draw_circle(center + dir * (base_radius + 10.0 * scale_factor), maxf(1.5, 3.0 * scale_factor), Color("ff88aa"))
		"vortex":
			# Singularidade giratória com anéis espirais duplos
			control.draw_arc(center, base_radius * 0.6, 0.0, TAU * 0.8, 16, color, maxf(1.2, 2.5 * scale_factor), true)
			control.draw_arc(center, base_radius + 6.0 * scale_factor, PI * 0.5, PI * 0.5 + TAU * 0.8, 20, Color(color, 0.8), maxf(1.0, 2.0 * scale_factor), true)
			control.draw_circle(center, maxf(1.5, 4.0 * scale_factor), Color("050014"))
		"railgun":
			# Trilhos magnéticos paralelos com bobinas de aceleração
			var rail_norm: Vector2 = dir.orthogonal() * (4.0 * scale_factor)
			control.draw_line(center - rail_norm, center - rail_norm + dir * (base_radius + 11.0 * scale_factor), color, maxf(1.0, 2.0 * scale_factor), true)
			control.draw_line(center + rail_norm, center + rail_norm + dir * (base_radius + 11.0 * scale_factor), color, maxf(1.0, 2.0 * scale_factor), true)
			control.draw_line(center + dir * (5.0 * scale_factor) - rail_norm * 1.3, center + dir * (5.0 * scale_factor) + rail_norm * 1.3, Color.WHITE, maxf(1.0, 1.5 * scale_factor), true)
			control.draw_line(center + dir * (11.0 * scale_factor) - rail_norm * 1.3, center + dir * (11.0 * scale_factor) + rail_norm * 1.3, Color.WHITE, maxf(1.0, 1.5 * scale_factor), true)

func append_slot_expansion(parent: VBoxContainer, laboratory := false) -> void:
	var index: int = store.unlocked_tower_slots
	if index >= 7:
		parent.add_child(label("✓ EXPANSÃO CONCLUÍDA • 7/7 slots liberados", 17, LIME))
		return
	if not store.slot_visible(index):
		if not laboratory:
			var hint := label("◇ Próximo slot: alcance a wave %d para descobrir." % store.SLOT_WAVES[index], 18, MUTED)
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			parent.add_child(hint)
		return
	var card := panel(parent, CYAN)
	card.add_child(label("EXPANSÃO  •  SLOT %d" % (index + 1), 17, CYAN, true))
	var cost: Dictionary = store.slot_cost(index)
	var piece_index: int = cost.piece_index
	var costs := label("DESCOBERTO • Custo: %d %s • Você tem: %d" % [int(cost.amount), PIECE_SHORT[piece_index], store.pieces[piece_index]], 17, MUTED)
	costs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(costs)
	var available: bool = store.can_research_slot(index)
	var action := button("PESQUISAR SLOT %d" % (index + 1) if available else "PESQUISAR • PEÇAS INSUFICIENTES", func(): buy_tower_slot(index), CYAN)
	action.name = "ResearchSlot%d" % index
	action.disabled = not available
	card.add_child(action)

func append_module_status(parent: VBoxContainer) -> void:
	if not module_status.is_empty():
		var status := label(module_status, 17, AMBER)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(status)

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
	if phase == "research":
		build_research_cards()
	else:
		build_module_cards()
	var action := overlay.find_child(action_name, true, false) as Button
	if action != null:
		if not action.disabled:
			action.grab_focus()
		elif action_name.begins_with("Slot"):
			for choice in action.get_parent().get_children():
				if choice is Button and not choice.disabled:
					choice.grab_focus()
					break

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
	var title := center_label(research_content, "⌬  LABORATÓRIO DE PESQUISAS", 23, CYAN, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var intro := center_label(research_content, "Inimigos podem soltar peças da própria estrutura.\n■ 30%   ▲ 22%   ⬢ 40%   ✦ Boss: 100% (2 peças)\nUse cada família para liberar melhorias permanentes.", 18, Color("cfc7dd"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_research_cards()

func build_research_cards() -> void:
	for child in research_content.get_children():
		if child.name == "DynamicResearch":
			research_content.remove_child(child)
			child.queue_free()
	var dynamic := VBoxContainer.new()
	dynamic.name = "DynamicResearch"
	dynamic.add_theme_constant_override("separation", 10)
	research_content.add_child(dynamic)
	center_label(dynamic, pieces_text(), 16, AMBER, true)
	append_hide_completed_button(dynamic)
	section_header_with_icon(dynamic, "PESQUISAS DE ATAQUE E DEFESA", "attack", CYAN)
	var combat_shown := 0
	var tower_shown := 0
	var shield_shown := 0
	for i in RESEARCH_NAMES.size():
		if i == 18:
			if combat_shown == 0 and hide_completed_research:
				center_label(dynamic, "✓ Todas as pesquisas de ataque e defesa foram concluídas.", 15, LIME)
			section_header_with_icon(dynamic, "ESPECIALIZAÇÃO DE TORRETAS", "towers", PINK)
		elif i == 25:
			if tower_shown == 0 and hide_completed_research:
				center_label(dynamic, "✓ Todas as especializações de torretas foram concluídas.", 15, LIME)
			section_header_with_icon(dynamic, "TECNOLOGIA DE ESCUDOS", "defense", CYAN)
		var level: int = store.research[i]
		var maximum: int = store.RESEARCH_MAX[i]
		if hide_completed_research and level >= maximum:
			continue
		if i < 18:
			combat_shown += 1
		elif i < 25:
			tower_shown += 1
		else:
			shield_shown += 1
		var cost: int = store.research_cost(i)
		var p_idx: int = store.piece_index_for_research(i)
		var words := "%s  %s  •  Nv.%d/%d\n%s\n" % [PIECE_SHORT[p_idx], RESEARCH_NAMES[i], level, maximum, RESEARCH_DESCS[i]]
		words += "✓ PESQUISA CONCLUÍDA" if level >= maximum else "Custo: %d %s   •   Você tem: %d" % [cost, PIECE_SHORT[p_idx], store.pieces[p_idx]]
		var btn_color: Color = MODULE_INFO[MODULE_IDS[i - 18]][2] if (i >= 18 and i < 25) else COLORS[p_idx]
		var research_button := button(words, func(): buy_research(i), btn_color)
		research_button.name = "Research%d" % (i + 1)
		research_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		research_button.custom_minimum_size.y = 78
		research_button.disabled = not store.can_research(i)
		if i >= 18 and i < 25:
			var tower_mod_id: String = MODULE_IDS[i - 18]
			research_button.draw.connect(func(): draw_tower_module_icon(research_button, tower_mod_id, 13.0, Vector2(research_button.size.x - 36.0, research_button.size.y * 0.5)))
		else:
			var r_icon := research_icon_id(i)
			research_button.draw.connect(func(): draw_neon_ui_icon(research_button, r_icon, 13.0, Vector2(research_button.size.x - 36.0, research_button.size.y * 0.5), btn_color))
		dynamic.add_child(research_button)
	if shield_shown == 0 and hide_completed_research:
		center_label(dynamic, "✓ Todas as pesquisas de tecnologia de escudos foram concluídas.", 15, LIME)
	append_module_cards(dynamic)
	append_slot_expansion(dynamic, true)
	append_module_status(dynamic)
	var close := button("VOLTAR AO MENU", close_research, CYAN)
	close.name = "CloseResearch"
	dynamic.add_child(close)
	contain_modal_focus()
	focus_first_modal_action()

func research_icon_id(index: int) -> String:
	return GameData.research_icon(index)

func draw_neon_ui_icon(control: Control, icon_id: String, base_radius: float = 12.0, custom_center: Vector2 = Vector2(-1, -1), color: Color = CYAN) -> void:
	var center: Vector2 = custom_center if custom_center.x >= 0.0 else control.size * 0.5
	var s: float = base_radius / 12.0
	var outer_r: float = base_radius + 3.5 * s
	# Halo neon escuro e anel de moldura geométrica
	control.draw_circle(center, outer_r, Color("0b061c"))
	control.draw_arc(center, outer_r, 0.0, TAU, 24, Color(color, 0.32), maxf(1.0, 1.4 * s), true)
	control.draw_circle(center, base_radius, Color("140933"))
	control.draw_arc(center, base_radius, 0.0, TAU, 24, Color(color, 0.75), maxf(1.0, 1.6 * s), true)

	match icon_id:
		"attack", "click_dmg":
			# Mira de plasma com losango energético central e 4 hastes
			for k in 4:
				var dir := Vector2.from_angle(k * PI * 0.5)
				control.draw_line(center + dir * (4.0 * s), center + dir * (base_radius + 2.5 * s), color, maxf(1.2, 2.0 * s), true)
			var diamond := PackedVector2Array([
				center + Vector2(0, -4.5 * s),
				center + Vector2(4.5 * s, 0),
				center + Vector2(0, 4.5 * s),
				center + Vector2(-4.5 * s, 0)
			])
			control.draw_colored_polygon(diamond, Color.WHITE)
		"towers":
			# Torreta dupla com base hexagonal e canhões gêmeos
			for side in [-1.0, 1.0]:
				var bx: float = side * 3.2 * s
				control.draw_line(center + Vector2(bx, 2.0 * s), center + Vector2(bx, -base_radius - 1.5 * s), color, maxf(1.2, 2.2 * s), true)
				control.draw_circle(center + Vector2(bx, -base_radius - 1.5 * s), maxf(1.2, 1.8 * s), Color.WHITE)
			control.draw_arc(center + Vector2(0, 2.0 * s), 5.0 * s, 0.0, TAU, 16, Color.WHITE, maxf(1.0, 1.6 * s), true)
		"defense", "shield_cap":
			# Escudo hexagonal energético com núcleo brilhante
			var pts := PackedVector2Array([
				center + Vector2(0, -8.5 * s),
				center + Vector2(7.0 * s, -4.0 * s),
				center + Vector2(5.8 * s, 4.5 * s),
				center + Vector2(0, 8.8 * s),
				center + Vector2(-5.8 * s, 4.5 * s),
				center + Vector2(-7.0 * s, -4.0 * s),
				center + Vector2(0, -8.5 * s)
			])
			control.draw_colored_polygon(pts.slice(0, 6), Color(color, 0.25))
			control.draw_polyline(pts, color, maxf(1.3, 2.0 * s), true)
			control.draw_circle(center, maxf(1.5, 2.5 * s), Color.WHITE)
		"eye_on", "eye_off":
			# Visor cibernético neon (olho geométrico)
			var top_arc := PackedVector2Array([
				center + Vector2(-8.5 * s, 0),
				center + Vector2(-3.5 * s, -5.0 * s),
				center + Vector2(3.5 * s, -5.0 * s),
				center + Vector2(8.5 * s, 0),
				center + Vector2(3.5 * s, 5.0 * s),
				center + Vector2(-3.5 * s, 5.0 * s),
				center + Vector2(-8.5 * s, 0)
			])
			control.draw_polyline(top_arc, color, maxf(1.2, 1.8 * s), true)
			control.draw_circle(center, maxf(1.5, 2.6 * s), Color.WHITE if icon_id == "eye_on" else color)
			if icon_id == "eye_off":
				control.draw_line(center + Vector2(-7.0 * s, 6.5 * s), center + Vector2(7.0 * s, -6.5 * s), PINK, maxf(1.4, 2.2 * s), true)
		"lock":
			# Cadeado holográfico geométrico
			control.draw_arc(center + Vector2(0, -2.5 * s), 4.2 * s, PI, TAU, 16, color, maxf(1.2, 2.0 * s), true)
			var rect := Rect2(center + Vector2(-5.5 * s, -2.0 * s), Vector2(11.0 * s, 8.5 * s))
			control.draw_rect(rect, Color("0b061c"), true)
			control.draw_rect(rect, color, false, maxf(1.2, 1.8 * s))
			control.draw_circle(center + Vector2(0, 2.2 * s), maxf(1.2, 1.8 * s), Color.WHITE)
		"crit_chance":
			# Estrela crítica de 4 pontas
			var star := PackedVector2Array()
			for k in 8:
				var ang: float = k * PI * 0.25 - PI * 0.5
				var r: float = (8.5 * s) if (k % 2 == 0) else (3.0 * s)
				star.append(center + Vector2.from_angle(ang) * r)
			control.draw_colored_polygon(star, color)
			control.draw_circle(center, maxf(1.4, 2.2 * s), Color.WHITE)
		"crit_mult":
			# Duplo chevron ascendente de potência letal
			for idx in [-1, 1]:
				var y_off: float = idx * 2.8 * s
				var chev := PackedVector2Array([
					center + Vector2(-5.5 * s, y_off + 2.5 * s),
					center + Vector2(0, y_off - 3.0 * s),
					center + Vector2(5.5 * s, y_off + 2.5 * s)
				])
				control.draw_polyline(chev, Color.WHITE if idx == -1 else color, maxf(1.3, 2.2 * s), true)
		"combo_drive":
			# Raio de corrente de combo
			var bolt := PackedVector2Array([
				center + Vector2(2.0 * s, -8.0 * s),
				center + Vector2(-4.5 * s, -0.5 * s),
				center + Vector2(1.5 * s, -0.5 * s),
				center + Vector2(-2.0 * s, 8.0 * s)
			])
			control.draw_polyline(bolt, Color.WHITE, maxf(1.4, 2.2 * s), true)
		"click_splash":
			# Anéis concêntricos de impacto em área
			control.draw_arc(center, 4.2 * s, 0.0, TAU, 16, Color.WHITE, maxf(1.2, 1.8 * s), true)
			control.draw_arc(center, 8.0 * s, 0.0, TAU, 20, color, maxf(1.0, 1.6 * s), true)
			control.draw_circle(center, maxf(1.4, 2.0 * s), color)
		"nova_overdrive":
			# Supernova de 8 raios
			for k in 8:
				var dir := Vector2.from_angle(k * PI * 0.25)
				var len_r: float = (8.5 * s) if (k % 2 == 0) else (5.5 * s)
				control.draw_line(center, center + dir * len_r, Color.WHITE if (k % 2 == 0) else color, maxf(1.2, 1.8 * s), true)
			control.draw_circle(center, maxf(1.8, 2.8 * s), Color.WHITE)
		"tower_haste":
			# Setas duplas de cadência acelerada
			for idx in [-1, 1]:
				var x_off: float = idx * 2.6 * s
				var arr := PackedVector2Array([
					center + Vector2(x_off - 2.5 * s, -5.0 * s),
					center + Vector2(x_off + 3.0 * s, 0),
					center + Vector2(x_off - 2.5 * s, 5.0 * s)
				])
				control.draw_polyline(arr, Color.WHITE if idx == 1 else color, maxf(1.3, 2.0 * s), true)
		"tower_range":
			# Radar de longo alcance
			control.draw_arc(center + Vector2(0, 3.0 * s), 5.0 * s, -PI * 0.85, -PI * 0.15, 14, color, maxf(1.2, 1.8 * s), true)
			control.draw_arc(center + Vector2(0, 3.0 * s), 8.8 * s, -PI * 0.85, -PI * 0.15, 18, Color.WHITE, maxf(1.2, 1.8 * s), true)
			control.draw_circle(center + Vector2(0, 3.5 * s), maxf(1.5, 2.4 * s), color)
		"tower_pierce":
			# Lança perfurante anti-titã
			control.draw_line(center + Vector2(-7.0 * s, 7.0 * s), center + Vector2(7.0 * s, -7.0 * s), Color.WHITE, maxf(1.4, 2.2 * s), true)
			var tip := PackedVector2Array([
				center + Vector2(1.5 * s, -7.0 * s),
				center + Vector2(7.0 * s, -7.0 * s),
				center + Vector2(7.0 * s, -1.5 * s)
			])
			control.draw_polyline(tip, color, maxf(1.4, 2.2 * s), true)
		"tower_synergy":
			# Tríade sincronizada de nós de bateria
			var nodes := PackedVector2Array()
			for k in 3:
				var p := center + Vector2.from_angle(k * TAU / 3.0 - PI * 0.5) * (6.2 * s)
				nodes.append(p)
			nodes.append(nodes[0])
			control.draw_polyline(nodes, color, maxf(1.1, 1.6 * s), true)
			for k in 3:
				control.draw_circle(nodes[k], maxf(1.6, 2.4 * s), Color.WHITE)
		"base_hull", "hull_vitality":
			# Cruz de integridade estrutural de titânio
			var arm: float = 6.5 * s
			control.draw_line(center + Vector2(-arm, 0), center + Vector2(arm, 0), color, maxf(1.8, 3.2 * s), true)
			control.draw_line(center + Vector2(0, -arm), center + Vector2(0, arm), color, maxf(1.8, 3.2 * s), true)
			control.draw_circle(center, maxf(1.5, 2.2 * s), Color.WHITE)
		"nano_regen":
			# Órbita de nanorreparo
			control.draw_line(center + Vector2(-4.5 * s, 0), center + Vector2(4.5 * s, 0), Color.WHITE, maxf(1.4, 2.2 * s), true)
			control.draw_line(center + Vector2(0, -4.5 * s), center + Vector2(0, 4.5 * s), Color.WHITE, maxf(1.4, 2.2 * s), true)
			for k in 3:
				var orb := center + Vector2.from_angle(k * TAU / 3.0) * (7.5 * s)
				control.draw_circle(orb, maxf(1.3, 2.0 * s), color)
		"reactive_plating":
			# Placas de blindagem reativa em losango duplo
			for scale_r in [4.5, 8.0]:
				var d := PackedVector2Array([
					center + Vector2(0, -scale_r * s),
					center + Vector2(scale_r * s, 0),
					center + Vector2(0, scale_r * s),
					center + Vector2(-scale_r * s, 0),
					center + Vector2(0, -scale_r * s)
				])
				control.draw_polyline(d, Color.WHITE if scale_r < 6.0 else color, maxf(1.2, 1.8 * s), true)
		"shield_regen":
			# Anel de recarga harmônica de escudo
			control.draw_arc(center, 6.5 * s, 0.3, PI - 0.3, 14, color, maxf(1.3, 2.0 * s), true)
			control.draw_arc(center, 6.5 * s, PI + 0.3, TAU - 0.3, 14, Color.WHITE, maxf(1.3, 2.0 * s), true)
			control.draw_circle(center, maxf(1.6, 2.5 * s), color)
		"shield_pulse":
			# Escudo com onda de repulsão externa
			control.draw_arc(center, 4.5 * s, 0.0, TAU, 16, Color.WHITE, maxf(1.2, 1.8 * s), true)
			control.draw_arc(center, 8.2 * s, -PI * 0.75, -PI * 0.25, 14, color, maxf(1.4, 2.2 * s), true)
			control.draw_arc(center, 8.2 * s, PI * 0.25, PI * 0.75, 14, color, maxf(1.4, 2.2 * s), true)
		_:
			control.draw_circle(center, maxf(2.0, 3.5 * s), Color.WHITE)


func buy_research(index: int) -> void:
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
	build_research_cards()

func close_research() -> void:
	show_menu()
	focus_menu_button("Research")

func show_codex() -> void:
	phase = "codex"
	var content := modal()
	content.custom_minimum_size.x = minf(760, size.x - 48)
	center_label(content, "◈  CODEX DOS INIMIGOS", 23, AMBER, true)
	center_label(content, "Descobertas registradas durante suas expedições ao Void.", 18, Color("cfc7dd"))
	for enemy_id in CODEX_ORDER:
		var known: bool = store.enemy_stats.has(enemy_id) and store.enemy_stats[enemy_id].discovered
		if not known:
			var unknown := button("◇  ???\nContinue avançando pelas waves para descobrir.", func(): pass, Color("42364f"))
			unknown.disabled = true
			unknown.custom_minimum_size.y = 62
			content.add_child(unknown)
			continue
		var info: Array = ENEMY_INFO[enemy_id]
		var stats: Dictionary = store.enemy_stats[enemy_id]
		var is_special_card: bool = enemy_id.begins_with("elite") or enemy_id.begins_with("boss")
		var border_color: Color = AMBER if is_special_card else CYAN

		var card_frame := PanelContainer.new()
		card_frame.add_theme_stylebox_override("panel", box(border_color, Color("140b29"), 12))
		card_frame.custom_minimum_size.y = 96
		content.add_child(card_frame)

		var card_row := HBoxContainer.new()
		card_row.add_theme_constant_override("separation", 16)
		card_frame.add_child(card_row)

		var icon := Control.new()
		icon.custom_minimum_size = Vector2(76, 76)
		icon.draw.connect(func(): draw_codex_enemy_icon(icon, enemy_id))
		card_row.add_child(icon)

		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.add_theme_constant_override("separation", 2)
		card_row.add_child(text_col)

		var title_lbl := label(info[0], 18, border_color, true)
		text_col.add_child(title_lbl)

		var line1 := "Abates: %d   •   Peças: %d   •   Maior wave: %d" % [stats.kills, stats.pieces, stats.max_wave]
		var lbl1 := label(line1, 15, Color.WHITE)
		text_col.add_child(lbl1)

		var line2 := "Drop: %s   •   Fraqueza: %s" % [info[1], info[2]]
		var lbl2 := label(line2, 14, MUTED)
		text_col.add_child(lbl2)

		var line3 := "%s   •   Pesquisa: %s" % [info[3], info[4]]
		var lbl3 := label(line3, 14, MUTED)
		text_col.add_child(lbl3)

	var close := button("VOLTAR AO MENU", close_codex, AMBER)
	close.name = "CloseCodex"
	content.add_child(close)
	close.grab_focus()

func draw_codex_enemy_icon(control: Control, enemy_id: String) -> void:
	var center := control.size * 0.5
	var radius := 24.0
	var sides := 4
	var color := VoidState.COLORS[0]
	var variant := ""
	var is_elite := false
	var is_boss := false
	var has_cannon := false
	var has_dual_cannon := false
	var has_teleport := false
	var has_summon := false

	match enemy_id:
		"square":
			sides = 4; color = VoidState.COLORS[0]
		"armored_square":
			sides = 4; color = VoidState.COLORS[0]; variant = "armored"
		"splitter":
			sides = 4; color = VoidState.COLORS[0]; variant = "splitter"
		"triangle":
			sides = 3; color = VoidState.COLORS[1]
		"ghost_triangle":
			sides = 3; color = VoidState.COLORS[1]; variant = "ghost"
		"thief":
			sides = 3; color = VoidState.COLORS[1]; variant = "thief"
		"pentagon":
			sides = 5; color = VoidState.COLORS[4]
		"hexagon":
			sides = 6; color = VoidState.COLORS[2]
		"regen_hexagon":
			sides = 6; color = VoidState.COLORS[2]; variant = "regen"
		"heptagon":
			sides = 7; color = VoidState.COLORS[5]
		"octagon":
			sides = 8; color = VoidState.COLORS[6]
		"nonagon":
			sides = 9; color = VoidState.COLORS[7]
		"decagon":
			sides = 10; color = VoidState.COLORS[8]
		"hendecagon":
			sides = 11; color = VoidState.COLORS[9]
		"dodecagon":
			sides = 12; color = VoidState.COLORS[10]
		"star4":
			sides = 4; color = VoidState.COLORS[11]
		"star5":
			sides = 5; color = VoidState.COLORS[12]
		"ring_prism":
			sides = 6; color = VoidState.COLORS[13]
		"spiral_singularity":
			sides = 12; color = VoidState.COLORS[14]
		"titan_tetrahedron":
			sides = 4; color = VoidState.COLORS[15]
		"void_shooter":
			sides = 6; color = VoidState.COLORS[16]; has_cannon = true
		"quantum_teleporter":
			sides = 6; color = VoidState.COLORS[17]; has_teleport = true
		"hive_summoner":
			sides = 8; color = VoidState.COLORS[18]; has_summon = true
		"plasma_artillery":
			sides = 10; color = VoidState.COLORS[19]; has_dual_cannon = true
		"rift_weaver":
			sides = 7; color = VoidState.COLORS[20]; has_teleport = true; has_summon = true
		"elite":
			sides = 5; color = AMBER; is_elite = true
		"elite_vanguard":
			sides = 6; color = Color("ffb02e"); is_elite = true; variant = "armored"
		"elite_phantom":
			sides = 5; color = Color("00f5d4"); is_elite = true; has_teleport = true
		"elite_artillery":
			sides = 6; color = Color("ff4d6d"); is_elite = true; has_cannon = true
		"elite_overlord":
			sides = 8; color = Color("e056fd"); is_elite = true; has_summon = true
		"elite_berserker":
			sides = 7; color = Color("ff7f50"); is_elite = true
		"elite_storm":
			sides = 6; color = Color("fee440"); is_elite = true; has_cannon = true; has_teleport = true
		"boss":
			sides = 8; color = Color("ffb02e"); is_boss = true; has_dual_cannon = true
		"boss_colossus":
			sides = 10; color = Color("ff3b30"); is_boss = true; has_summon = true; variant = "regen"
		"boss_primordial":
			sides = 12; color = Color("00f2fe"); is_boss = true; has_teleport = true; has_dual_cannon = true
		"boss_nexus":
			sides = 8; color = Color("c471ed"); is_boss = true; has_summon = true
		"boss_leviathan":
			sides = 16; color = Color("00ff87"); is_boss = true; has_dual_cannon = true; variant = "armored"
		"boss_omega":
			sides = 10; color = Color("ff007f"); is_boss = true; has_teleport = true; has_summon = true; has_dual_cannon = true

	var rot: float = -PI / 2.0 if sides == 3 else 0.0
	var points := PackedVector2Array()
	var outer := PackedVector2Array()

	if enemy_id == "star4":
		for i in 8:
			var angle: float = rot + i * PI / 4.0
			var r: float = radius if (i % 2 == 0) else radius * 0.45
			points.append(center + Vector2.from_angle(angle) * r)
			outer.append(center + Vector2.from_angle(angle) * (r + 4))
	elif enemy_id == "star5":
		for i in 10:
			var angle: float = rot + i * PI / 5.0
			var r: float = radius if (i % 2 == 0) else radius * 0.48
			points.append(center + Vector2.from_angle(angle) * r)
			outer.append(center + Vector2.from_angle(angle) * (r + 4))
	elif enemy_id == "quantum_teleporter":
		for i in 12:
			var angle: float = rot + i * PI / 6.0
			var r: float = radius if (i % 2 == 0) else radius * 0.46
			points.append(center + Vector2.from_angle(angle) * r)
			outer.append(center + Vector2.from_angle(angle) * (r + 4))
	elif enemy_id == "rift_weaver":
		for i in 14:
			var angle: float = rot + i * PI / 7.0
			var r: float = radius if (i % 2 == 0) else radius * 0.44
			points.append(center + Vector2.from_angle(angle) * r)
			outer.append(center + Vector2.from_angle(angle) * (r + 4))
	elif enemy_id in ["boss_nexus", "boss_omega"]:
		var star_pts: int = 20 if enemy_id == "boss_omega" else 16
		for i in star_pts:
			var angle: float = rot + i * TAU / float(star_pts)
			var r: float = radius if (i % 2 == 0) else radius * 0.56
			points.append(center + Vector2.from_angle(angle) * r)
			outer.append(center + Vector2.from_angle(angle) * (r + 5))
	else:
		for i in sides:
			var dir := Vector2.from_angle(rot + i * TAU / sides)
			points.append(center + dir * radius)
			outer.append(center + dir * (radius + 5))

	control.draw_colored_polygon(outer, Color(color, 0.2))
	var body_color := color.darkened(0.5)
	control.draw_colored_polygon(points, body_color)

	var num_pts: int = points.size()
	for i in num_pts:
		var edge_color := color.darkened(0.55)
		control.draw_polygon(
			PackedVector2Array([center, points[i], points[(i + 1) % num_pts]]),
			PackedColorArray([color, edge_color, edge_color])
		)

	var loop := points.duplicate()
	loop.append(points[0])
	control.draw_polyline(loop, color, 2.5, true)
	control.draw_circle(center, maxf(2.5, radius * 0.22), Color(1, 1, 1, 0.9))

	# Acessórios específicos
	if enemy_id == "ring_prism":
		control.draw_arc(center, radius + 7, 0, TAU, 24, Color(color, 0.7), 2.0, true)
	elif enemy_id == "spiral_singularity":
		control.draw_arc(center, radius + 8, 0, TAU * 0.8, 28, Color(color, 0.8), 2.5, true)
		control.draw_circle(center, 4.0, Color("050014"))
	elif enemy_id == "titan_tetrahedron":
		control.draw_arc(center, radius + 9, 0, TAU, 32, Color(color, 0.85), 2.5, true)

	if has_cannon:
		var b_start: Vector2 = center + Vector2(0, radius * 0.55)
		var b_end: Vector2 = center + Vector2(0, radius + 8.0)
		control.draw_line(b_start, b_end, color, 3.0, true)
		control.draw_circle(b_end, 2.5, Color.WHITE)
	if has_dual_cannon:
		for s in [-1.0, 1.0]:
			var bs: Vector2 = center + Vector2(s * radius * 0.4, radius * 0.5)
			var be: Vector2 = bs + Vector2(0, 8.0)
			control.draw_line(bs, be, color, 2.5, true)
			control.draw_circle(be, 2.0, Color.WHITE)
	if has_teleport:
		control.draw_arc(center, radius + 5, 0.2, PI - 0.2, 14, Color("00f5d4", 0.9), 2.0, true)
		control.draw_arc(center, radius + 5, PI + 0.2, TAU - 0.2, 14, Color("00f5d4", 0.9), 2.0, true)
	if has_summon:
		for k in 3:
			var orb_ang: float = float(k) * TAU / 3.0 - PI / 2.0
			var orb_pos: Vector2 = center + Vector2.from_angle(orb_ang) * (radius + 7.5)
			control.draw_circle(orb_pos, 3.0, color)
			control.draw_circle(orb_pos, 1.4, Color.WHITE)

	# Acessórios de variantes
	if variant == "armored":
		control.draw_arc(center, radius + 7, 0, TAU, 16, Color(0.8, 0.85, 1, 0.8), 2.5, true)
	elif variant == "regen":
		control.draw_arc(center, radius + 6, -PI / 2, -PI / 2 + TAU * 0.75, 24, Color(0.71, 1, 0.18, 0.85), 2.0, true)
	elif variant == "ghost":
		control.draw_arc(center, radius + 5, 0, TAU, 16, Color(VoidState.COLORS[1], 0.4), 1.5, true)
	elif variant == "splitter":
		control.draw_circle(center + Vector2(-radius * 0.4, 0), 2.5, Color.WHITE)
		control.draw_circle(center + Vector2(radius * 0.4, 0), 2.5, Color.WHITE)
	elif variant == "thief":
		var font: Font = DISPLAY
		control.draw_string(font, center + Vector2(-4, 5), "$", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color("ffb02e"))
	if is_elite:
		control.draw_arc(center, radius + 9, 0, TAU * 0.75, 28, color.lightened(0.2), 2.5, true)
	elif is_boss:
		control.draw_arc(center, radius + 9, 0, TAU, 32, Color(color, 0.75), 2.2, true)
		control.draw_arc(center, radius + 12, 0, TAU * 0.65, 24, Color(color.lightened(0.3), 0.55), 1.5, true)

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
	var margins := margin(center, 24)
	var content := panel(margins, CYAN)
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
	center_label(content, "Ⅱ", 38, CYAN, true)
	center_label(content, "PAUSADO", 28, Color.WHITE, true)
	center_label(content, "%d PONTOS     W%d     %d OURO" % [state.score, state.wave, state.gold], 14, LIME, true)
	var resume := button("▶  CONTINUAR", pause_game, LIME, true)
	content.add_child(resume)
	content.add_child(button("REINICIAR", start_game))
	content.add_child(button("MENU", show_menu))
	center_label(content, "P / ESC para continuar • R reinicia", 16, MUTED)
	resume.grab_focus()

func game_over() -> void:
	record_wave_progress()
	phase = "gameover"
	var record: bool = state.score > store.best
	store.best = maxi(store.best, state.score)
	var persisted: bool = true if test_mode else store.save_data()
	var content := modal()
	center_label(content, "BASE DESTRUÍDA", 27, Color("ff5577"), true)
	if record:
		center_label(content, "♛  NOVO RECORDE!", 14, AMBER, true)
	center_label(content, str(state.score), 48, Color.WHITE, true)
	center_label(content, "P O N T U A Ç Ã O  F I N A L", 12, MUTED)
	center_label(content, "W%d     %d ABATES     %d OURO\nx%d COMBO     %s" % [state.wave, state.kills, state.total_gold, state.max_combo, time_text(state.play_time)], 17, CYAN)
	center_label(content, "PEÇAS COLETADAS   " + pieces_text(state.run_pieces), 14, AMBER, true)
	if store.qualifies(state.score):
		center_label(content, "TOP 10 — REGISTRE SEU NOME", 12, AMBER, true)
		player_name = LineEdit.new()
		player_name.placeholder_text = "SEU NOME"
		player_name.max_length = 10
		player_name.custom_minimum_size.y = 42
		content.add_child(player_name)
		var save_button := button("SALVAR", submit_score, AMBER, true)
		save_button.name = "SaveScore"
		content.add_child(save_button)
		player_name.text_submitted.connect(func(_text): submit_score())
		player_name.grab_focus()
	save_status = center_label(content, "" if persisted else "Não foi possível salvar o recorde no disco.", 15, AMBER)
	content.add_child(button("JOGAR NOVAMENTE", start_game, PINK, true))
	content.add_child(button("VOLTAR AO MENU", show_menu))
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
	for item in shop_items:
		var btn: Button = item["button"]
		if not is_instance_valid(btn):
			continue
		if item["kind"] == "tower_slot":
			var slot_idx: int = int(item["slot_index"])
			if slot_idx < 0 or slot_idx >= state.tower_loadout.size():
				continue
			var mod_id: String = state.tower_loadout[slot_idx]
			var info: Array = MODULE_INFO.get(mod_id, MODULE_INFO["plasma"])
			var lvl: int = state.tower_slot_level(slot_idx)
			var c: int = state.tower_slot_cost(slot_idx)
			var status_line: String = "COMPRAR TORRE  •  Ativa disparo" if lvl == 0 else "%s dano/s  •  Evoluir torre" % NumberFormat.format_int(state.slot_dps(slot_idx))
			btn.text = "SLOT %d: %s  •  %s\n%s\n%s   ◈ %s" % [
				slot_idx + 1,
				info[0].to_upper(),
				"INATIVA" if lvl == 0 else ("Nv.%d" % lvl),
				status_line,
				"▰".repeat(mini(lvl, 10)) + "▱".repeat(maxi(0, 10 - lvl)),
				NumberFormat.format(float(c), 1)
			]
			btn.disabled = state.gold < c
			btn.queue_redraw()
		else:
			var upg_id: String = item["id"]
			var uinfo: Array = IN_GAME_UPG_INFO[upg_id]
			var lvl: int = state.upg_level(upg_id)
			var max_lvl: int = int(state.UPGRADE_DEFS[upg_id].get("max_level", 999))
			var c: int = state.upg_cost(upg_id)
			var detail: String = uinfo[1]
			if upg_id == "click_dmg":
				detail = "%s dano/clique (+25%% a cada 5 nv)" % NumberFormat.format_int(state.click_damage())
			if upg_id in ["shield_cap", "shield_regen", "shield_pulse"] and not state.shield_unlocked():
				btn.text = "%s  •  BLOQUEADO\nRequer pesquisa: Gerador de Escudo Quântico\nDesbloqueie no Laboratório" % uinfo[0]
				btn.disabled = true
			elif lvl >= max_lvl:
				btn.text = "%s  •  Nv.%d (MÁX)\n%s\n✓ NÍVEL MÁXIMO ATINGIDO" % [uinfo[0], lvl, detail]
				btn.disabled = true
			else:
				var lvl_text := ("Nv.%d/%d" % [lvl, max_lvl]) if max_lvl < 900 else ("Nv.%d" % lvl)
				btn.text = "%s  •  %s\n%s\n%s   ◈ %s" % [
					uinfo[0],
					lvl_text,
					detail,
					"▰".repeat(mini(lvl, 10)) + "▱".repeat(maxi(0, 10 - lvl)),
					NumberFormat.format(float(c), 1)
				]
				btn.disabled = not state.can_buy_upgrade(upg_id)
			btn.queue_redraw()

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
