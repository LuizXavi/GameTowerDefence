class_name CodexScreen
extends RefCounted
## Constrói a tela do Codex dos Inimigos dividida por abas (Todos, Comuns, Escudos, Atiradores, Elites, Bosses).

const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED
const CODEX_ORDER := GameData.CODEX_ORDER
const ENEMY_INFO := GameData.ENEMY_INFO

const TAB_COLORS := {
	"all": Color("c084fc"),
	"common": Color("00ffff"),
	"shields": Color("00e5ff"),
	"shooters": Color("ff007f"),
	"elites": Color("ffb703"),
	"bosses": Color("ff0055")
}

static func build(app: Control, content: VBoxContainer) -> void:
	for child in content.get_children():
		if child.name == "DynamicCodex":
			content.remove_child(child)
			child.queue_free()

	content.custom_minimum_size.x = minf(760, app.size.x - 48)

	var dynamic := VBoxContainer.new()
	dynamic.name = "DynamicCodex"
	dynamic.add_theme_constant_override("separation", 10)
	content.add_child(dynamic)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 3)
	dynamic.add_child(header_box)

	var title := UIFactory.center_label(header_box, "CODEX DOS INIMIGOS", 23, AMBER, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var total_known := 0
	for enemy_id in CODEX_ORDER:
		if app.store.enemy_stats.has(enemy_id) and app.store.enemy_stats[enemy_id].discovered:
			total_known += 1

	var progress_text := "Descobertas registradas no Void: %d / %d" % [total_known, CODEX_ORDER.size()]
	var subtitle := UIFactory.center_label(header_box, progress_text, 15, Color("cfc7dd"))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	append_tab_bar(app, dynamic)
	append_enemy_cards(app, dynamic)

	var close := UIFactory.button("VOLTAR AO MENU", app.close_codex, AMBER)
	close.name = "CloseCodex"
	dynamic.add_child(close)

static func append_tab_bar(app: Control, parent: VBoxContainer) -> void:
	var tabs_row := HBoxContainer.new()
	tabs_row.name = "CodexTabsBar"
	tabs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_row.add_theme_constant_override("separation", 5)
	parent.add_child(tabs_row)

	for tab_id in GameData.CODEX_TABS:
		var label_text: String = str(GameData.CODEX_TAB_LABELS.get(tab_id, tab_id.to_upper()))
		var is_selected: bool = app.codex_tab == tab_id
		var tab_color: Color = TAB_COLORS.get(tab_id, CYAN)
		var btn_color: Color = tab_color if is_selected else Color("6e6382")
		var tab_btn := UIFactory.tab_button(label_text, func(): app.select_codex_tab(tab_id), btn_color, is_selected, 26)
		tab_btn.name = "Tab_codex_" + tab_id
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.custom_minimum_size.y = 38
		tab_btn.add_theme_font_size_override("font_size", 10)
		tab_btn.draw.connect(func():
			var icon_color: Color = Color.WHITE if is_selected else btn_color
			NeonIcons.draw_ui(tab_btn, tab_id, 6.5, Vector2(13.0, tab_btn.size.y * 0.5), icon_color)
		)
		tabs_row.add_child(tab_btn)

static func append_enemy_cards(app: Control, parent: VBoxContainer) -> void:
	var enemy_ids: Array = GameData.CODEX_TAB_LISTS.get(app.codex_tab, CODEX_ORDER)
	var shown_count := 0
	var discovered_in_tab := 0

	for enemy_id in enemy_ids:
		var known: bool = app.store.enemy_stats.has(enemy_id) and app.store.enemy_stats[enemy_id].discovered
		shown_count += 1
		if not known:
			var unknown := UIFactory.button("◇  ???\nContinue avançando pelas waves para descobrir.", func(): pass, Color("42364f"))
			unknown.disabled = true
			unknown.custom_minimum_size.y = 62
			unknown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			unknown.clip_text = true
			parent.add_child(unknown)
			continue

		discovered_in_tab += 1
		var info: Array = ENEMY_INFO[enemy_id]
		var stats: Dictionary = app.store.enemy_stats[enemy_id]
		var is_special_card: bool = enemy_id.begins_with("elite") or enemy_id.begins_with("boss")
		var border_color: Color = AMBER if is_special_card else CYAN

		var card_frame := PanelContainer.new()
		card_frame.add_theme_stylebox_override("panel", UIFactory.box(border_color, Color("140b29"), 12))
		card_frame.custom_minimum_size.y = 96
		parent.add_child(card_frame)

		var card_row := HBoxContainer.new()
		card_row.add_theme_constant_override("separation", 16)
		card_frame.add_child(card_row)

		var icon := Control.new()
		icon.custom_minimum_size = Vector2(76, 76)
		icon.draw.connect(func(): NeonIcons.draw_enemy(icon, enemy_id))
		card_row.add_child(icon)

		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.add_theme_constant_override("separation", 2)
		card_row.add_child(text_col)

		var title_lbl := UIFactory.label(info[0], 17, border_color, true)
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(title_lbl)

		var line1 := "Abates: %d   •   Peças: %d   •   Maior wave: %d" % [stats.kills, stats.pieces, stats.max_wave]
		var lbl1 := UIFactory.label(line1, 14, Color.WHITE)
		lbl1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(lbl1)

		var line2 := "Drop: %s   •   Fraqueza: %s" % [info[1], info[2]]
		var lbl2 := UIFactory.label(line2, 13, MUTED)
		lbl2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(lbl2)

		var line3 := "%s   •   Pesquisa: %s" % [info[3], info[4]]
		var lbl3 := UIFactory.label(line3, 13, MUTED)
		lbl3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(lbl3)

	if shown_count == 0:
		UIFactory.center_label(parent, "Nenhum espécime cadastrado nesta categoria.", 15, MUTED)
