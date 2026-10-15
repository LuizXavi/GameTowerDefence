class_name ResearchScreen
extends RefCounted
## Constrói a tela do Laboratório de Pesquisas dividida em abas (Laboratório, Ataque, Defesa, Economia, Torres).

const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED
const COLORS := GameData.PIECE_COLORS
const PIECE_SHORT := GameData.PIECE_SHORT
const RESEARCH_NAMES := GameData.RESEARCH_NAMES
const RESEARCH_DESCS := GameData.RESEARCH_DESCS
const MODULE_IDS := GameData.MODULE_IDS
const MODULE_INFO := GameData.MODULE_INFO

static func build(app: Control, initial_focus := false) -> void:
	for child in app.research_content.get_children():
		if child.name == "DynamicResearch":
			app.research_content.remove_child(child)
			child.queue_free()
	var dynamic := VBoxContainer.new()
	dynamic.name = "DynamicResearch"
	dynamic.add_theme_constant_override("separation", 10)
	app.research_content.add_child(dynamic)

	UIFactory.pieces_bar(dynamic, app.store.pieces, 16)

	append_tab_bar(app, dynamic)
	append_active_research_banner(app, dynamic)
	app.append_hide_completed_button(dynamic)

	match app.research_tab:
		"lab":
			append_lab_tab(app, dynamic)
		"attack":
			append_attack_tab(app, dynamic)
		"defense":
			append_defense_tab(app, dynamic)
		"economy":
			append_economy_tab(app, dynamic)
		"towers":
			append_towers_tab(app, dynamic)
		_:
			append_attack_tab(app, dynamic)

	append_module_status(app, dynamic)

	var close := UIFactory.button(I18n.t("btn.back_menu"), app.close_research, CYAN)
	close.name = "CloseResearch"
	dynamic.add_child(close)

	app.contain_modal_focus()
	if initial_focus:
		app.focus_first_modal_action()

static func append_tab_bar(app: Control, parent: VBoxContainer) -> void:
	var tabs_row := HBoxContainer.new()
	tabs_row.name = "ResearchTabsBar"
	tabs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_row.add_theme_constant_override("separation", 6)
	parent.add_child(tabs_row)

	var tab_labels := {
		"lab": I18n.t("lab.tab_lab"),
		"attack": I18n.t("lab.tab_attack"),
		"defense": I18n.t("lab.tab_defense"),
		"economy": I18n.t("lab.tab_economy"),
		"towers": I18n.t("lab.tab_towers")
	}

	for tab_id in GameData.RESEARCH_TABS:
		var label_text: String = str(tab_labels.get(tab_id, tab_id.to_upper()))
		var is_selected: bool = app.research_tab == tab_id
		var tab_color: Color = CYAN if is_selected else Color("6e6382")
		var tab_btn := UIFactory.tab_button(label_text, func(): app.select_research_tab(tab_id), tab_color, is_selected, 32)
		tab_btn.name = "Tab_" + tab_id
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.custom_minimum_size.y = 38
		tab_btn.draw.connect(func():
			var icon_color: Color = Color.WHITE if is_selected else tab_color
			NeonIcons.draw_ui(tab_btn, tab_id, 7.5, Vector2(16.0, tab_btn.size.y * 0.5), icon_color)
		)
		tabs_row.add_child(tab_btn)

static func append_active_research_banner(app: Control, parent: VBoxContainer) -> void:
	if not app.store.is_researching():
		return
	var banner := UIFactory.panel(parent, LIME)
	banner.name = "ActiveResearchBanner"
	banner.add_theme_constant_override("separation", 6)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	banner.add_child(header_row)

	var icon := Control.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.draw.connect(func(): NeonIcons.draw_ui(icon, "tower_haste", 10.0, Vector2(14, 14), LIME))
	header_row.add_child(icon)

	var title := UIFactory.label(I18n.t("lab.active_synthesis") % app.store.active_research_name(), 16, LIME, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	var progress_bar := UIFactory.make_bar(LIME)
	progress_bar.name = "ActiveResearchBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = app.store.active_research_progress() * 100.0
	progress_bar.custom_minimum_size.y = 12
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.add_child(progress_bar)

	var time_lbl := UIFactory.label(I18n.t("lab.remaining_time") % [app.store.active_research_remaining(), int(app.store.active_research_progress() * 100.0)], 14, CYAN)
	time_lbl.name = "ActiveResearchTime"
	banner.add_child(time_lbl)

static func update_progress(app: Control) -> void:
	if not app.research_content:
		return
	var bar: ProgressBar = app.research_content.find_child("ActiveResearchBar", true, false)
	var lbl: Label = app.research_content.find_child("ActiveResearchTime", true, false)
	if bar != null and lbl != null and app.store.is_researching():
		bar.value = app.store.active_research_progress() * 100.0
		lbl.text = I18n.t("lab.remaining_time") % [app.store.active_research_remaining(), int(app.store.active_research_progress() * 100.0)]

static func build_research_card_button(
	btn_name: String,
	title_text: String,
	desc_text: String,
	piece_index: int,
	cost: int,
	duration: float,
	current_pieces: int,
	level: int,
	maximum: int,
	is_active: bool,
	remaining_time: float,
	is_busy: bool,
	can_buy: bool,
	border_color: Color,
	icon_name: String,
	is_tower_icon: bool,
	callback: Callable
) -> Button:
	var btn := Button.new()
	btn.name = btn_name
	btn.text = ""
	btn.custom_minimum_size.y = 92
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.disabled = not can_buy

	var normal_box := UIFactory.box(border_color, Color("140b29"), 12, 14, 14, 8, 8)
	btn.add_theme_stylebox_override("normal", normal_box)
	var hover_box := UIFactory.box(border_color, Color("281448"), 12, 14, 14, 8, 8)
	hover_box.border_color = border_color
	hover_box.shadow_color = Color(border_color, 0.25)
	hover_box.shadow_size = 10
	btn.add_theme_stylebox_override("hover", hover_box)
	btn.add_theme_stylebox_override("pressed", UIFactory.box(border_color, Color("38204d"), 12, 14, 14, 8, 8))
	btn.add_theme_stylebox_override("focus", UIFactory.box(border_color, Color(0, 0, 0, 0), 12, 14, 14, 8, 8))
	btn.add_theme_stylebox_override("disabled", UIFactory.box(Color("42364f"), Color("100a20"), 12, 14, 14, 8, 8))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	btn.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.add_theme_constant_override("separation", 3)
	row.add_child(text_col)

	# Linha 1: Ícone Neon da Peça + Título + Nível
	var head_row := HBoxContainer.new()
	head_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_row.add_theme_constant_override("separation", 7)
	text_col.add_child(head_row)

	var head_p_icon := Control.new()
	head_p_icon.custom_minimum_size = Vector2(16, 16)
	head_p_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head_p_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_p_icon.draw.connect(func(): NeonIcons.draw_piece_icon(head_p_icon, piece_index, 14.0, Vector2(8, 8)))
	head_row.add_child(head_p_icon)

	var title_lbl := UIFactory.label("%s  •  Nv.%d/%d" % [title_text, level, maximum], 15, Color.WHITE, true)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_row.add_child(title_lbl)

	# Linha 2: Descrição
	var desc_lbl := UIFactory.label(desc_text, 14, Color("d4cee0"))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(desc_lbl)

	# Linha 3: Requisitos com Ícones Procedurais Neon das Peças
	var req_row := HBoxContainer.new()
	req_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	req_row.add_theme_constant_override("separation", 5)
	text_col.add_child(req_row)

	if is_active:
		var act_lbl := UIFactory.label(I18n.t("lab.in_synthesis") % remaining_time, 13, LIME, true)
		act_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		req_row.add_child(act_lbl)
	elif level >= maximum:
		var max_lbl := UIFactory.label(I18n.t("lab.completed"), 13, LIME, true)
		max_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		req_row.add_child(max_lbl)
	elif is_busy:
		var busy_lbl := UIFactory.label(I18n.t("lab.busy") % cost, 13, MUTED)
		busy_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		req_row.add_child(busy_lbl)
		var busy_icon := Control.new()
		busy_icon.custom_minimum_size = Vector2(14, 14)
		busy_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		busy_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		busy_icon.draw.connect(func(): NeonIcons.draw_piece_icon(busy_icon, piece_index, 13.0, Vector2(7, 7)))
		req_row.add_child(busy_icon)
	else:
		var cost_lbl := UIFactory.label(I18n.t("lab.cost") % cost, 13, Color("cfc7dd"))
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		req_row.add_child(cost_lbl)

		var cost_icon := Control.new()
		cost_icon.custom_minimum_size = Vector2(14, 14)
		cost_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_icon.draw.connect(func(): NeonIcons.draw_piece_icon(cost_icon, piece_index, 13.0, Vector2(7, 7)))
		req_row.add_child(cost_icon)

		var time_lbl := UIFactory.label(I18n.t("lab.time_have") % [int(duration), current_pieces], 13, Color("cfc7dd"))
		time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		req_row.add_child(time_lbl)

		var have_icon := Control.new()
		have_icon.custom_minimum_size = Vector2(14, 14)
		have_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		have_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		have_icon.draw.connect(func(): NeonIcons.draw_piece_icon(have_icon, piece_index, 13.0, Vector2(7, 7)))
		req_row.add_child(have_icon)

	# Coluna da Direita: Ícone do Módulo ou Pesquisa
	var icon_ctrl := Control.new()
	icon_ctrl.custom_minimum_size = Vector2(38, 38)
	icon_ctrl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_tower_icon:
		icon_ctrl.draw.connect(func(): NeonIcons.draw_tower(icon_ctrl, icon_name, 12.0, Vector2(19, 19)))
	else:
		icon_ctrl.draw.connect(func(): NeonIcons.draw_ui(icon_ctrl, icon_name, 12.0, Vector2(19, 19), border_color))
	row.add_child(icon_ctrl)

	btn.pressed.connect(callback)
	return btn

static func append_lab_tab(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, I18n.t("lab.header_lab", "MELHORIAS DO LABORATÓRIO"), "lab", AMBER)
	var shown := 0
	for i in GameData.LAB_RESEARCH_COUNT:
		var level: int = app.store.lab_research[i]
		var maximum: int = GameData.LAB_RESEARCH_MAX[i]
		if app.hide_completed_research and level >= maximum:
			continue
		shown += 1
		var cost: int = app.store.lab_research_cost(i)
		var p_idx: int = int(GameData.LAB_RESEARCH_PIECE_INDEX[i])
		var duration: float = app.store.get_lab_research_duration(i)
		var is_active: bool = app.store.active_research.get("type") == "lab" and int(app.store.active_research.get("target", -1)) == i
		var is_busy: bool = app.store.is_researching() and not is_active
		var can_buy: bool = app.store.can_lab_research(i) and not is_busy

		var btn_color: Color = COLORS[p_idx]
		var icon_name: String = GameData.LAB_RESEARCH_ICONS[i]
		var btn := build_research_card_button(
			"LabResearch%d" % (i + 1),
			I18n.get_lab_research_name(i),
			I18n.get_lab_research_desc(i),
			p_idx,
			cost,
			duration,
			app.store.pieces[p_idx],
			level,
			maximum,
			is_active,
			app.store.active_research_remaining(),
			is_busy,
			can_buy,
			btn_color,
			icon_name,
			false,
			func(): app.buy_lab_research(i)
		)
		parent.add_child(btn)

	if shown == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, I18n.t("lab.all_lab_done", "✓ Todas as melhorias do laboratório foram concluídas."), 15, LIME)

static func append_attack_tab(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, I18n.t("lab.header_attack", "PESQUISAS DE ATAQUE E COMBATE"), "attack", PINK)
	var shown := 0
	for i in GameData.RESEARCH_TAB_INDICES["attack"]:
		if append_research_card(app, parent, i):
			shown += 1
	if shown == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, I18n.t("lab.all_attack_done", "✓ Todas as pesquisas ofensivas foram concluídas."), 15, LIME)

static func append_defense_tab(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, I18n.t("lab.header_defense", "PESQUISAS DE DEFESA E ESCUDOS"), "defense", CYAN)
	var shown := 0
	for i in GameData.RESEARCH_TAB_INDICES["defense"]:
		if append_research_card(app, parent, i):
			shown += 1
	if shown == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, I18n.t("lab.all_defense_done", "✓ Todas as pesquisas defensivas foram concluídas."), 15, LIME)

static func append_economy_tab(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, I18n.t("lab.header_economy", "PESQUISAS DE ECONOMIA E FRAGMENTOS"), "economy", LIME)
	var shown := 0
	for i in GameData.RESEARCH_TAB_INDICES["economy"]:
		if append_research_card(app, parent, i):
			shown += 1
	if shown == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, I18n.t("lab.all_economy_done", "✓ Todas as pesquisas de economia foram concluídas."), 15, LIME)

static func append_research_card(app: Control, parent: VBoxContainer, i: int) -> bool:
	var level: int = app.store.research[i]
	var maximum: int = app.store.RESEARCH_MAX[i]
	if app.hide_completed_research and level >= maximum:
		return false

	var cost: int = app.store.research_cost(i)
	var p_idx: int = app.store.piece_index_for_research(i)
	var duration: float = app.store.get_research_duration(i)
	var is_active: bool = app.store.active_research.get("type") == "research" and int(app.store.active_research.get("target", -1)) == i
	var is_busy: bool = app.store.is_researching() and not is_active
	var can_buy: bool = app.store.can_research(i) and not is_busy

	var is_tower_res: bool = (i >= 18 and i < 32)
	var tower_mod_idx: int = (i - 18) / 2
	var btn_color: Color = MODULE_INFO[MODULE_IDS[tower_mod_idx]][2] if is_tower_res else COLORS[p_idx]
	var icon_name: String = MODULE_IDS[tower_mod_idx] if is_tower_res else GameData.research_icon(i)

	var research_button := build_research_card_button(
		"Research%d" % (i + 1),
		I18n.get_research_name(i),
		I18n.get_research_desc(i),
		p_idx,
		cost,
		duration,
		app.store.pieces[p_idx],
		level,
		maximum,
		is_active,
		app.store.active_research_remaining(),
		is_busy,
		can_buy,
		btn_color,
		icon_name,
		is_tower_res,
		func(): app.buy_research(i)
	)
	parent.add_child(research_button)
	return true

static func append_towers_tab(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, I18n.t("lab.header_towers", "DESBLOQUEIO DE MÓDULOS DE TORRE"), "towers", PINK)
	var shown_modules := 0
	var undiscovered := false
	for module_id in MODULE_IDS:
		if module_id == "plasma":
			continue
		if not app.store.module_visible(module_id):
			undiscovered = true
			continue
		var info: Array = I18n.get_module_info(module_id)
		var unlocked: bool = app.store.module_unlocked(module_id)
		if app.hide_completed_research and unlocked:
			continue
		shown_modules += 1

		var card := UIFactory.panel(parent, info[2])
		var card_row := HBoxContainer.new()
		card_row.add_theme_constant_override("separation", 14)
		card.add_child(card_row)

		var icon := Control.new()
		icon.custom_minimum_size = Vector2(58, 58)
		icon.draw.connect(func(): NeonIcons.draw_tower(icon, module_id))
		card_row.add_child(icon)

		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.add_theme_constant_override("separation", 3)
		card_row.add_child(text_col)

		var heading := UIFactory.label(info[0], 17, info[2], true)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(heading)
		var desc := UIFactory.label(info[1], 15, Color("d4cee0"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(desc)

		if unlocked:
			var status := UIFactory.label(I18n.t("lab.unlocked_status", "✓ DESBLOQUEADO • disponível no hangar"), 15, LIME)
			status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(status)
		else:
			var cost: Dictionary = app.store.module_cost(module_id)
			var p_idx: int = int(cost.piece_index)
			var duration: float = app.store.get_module_research_duration(module_id)
			var is_active: bool = app.store.active_research.get("type") == "module" and str(app.store.active_research.get("target", "")) == module_id
			var is_busy: bool = app.store.is_researching() and not is_active
			var can_buy: bool = app.store.can_research_module(module_id) and not is_busy

			var btn_text := "PESQUISAR (%ds)" % int(duration) if not I18n.is_en() else "RESEARCH (%ds)" % int(duration)
			if is_active:
				btn_text = I18n.t("modules.btn_in_synthesis") % app.store.active_research_remaining()
			elif is_busy:
				btn_text = I18n.t("modules.btn_lab_busy")
			elif not app.store.can_research_module(module_id):
				btn_text = I18n.t("modules.btn_no_pieces")

			var costs_row := HBoxContainer.new()
			costs_row.add_theme_constant_override("separation", 4)
			card.add_child(costs_row)

			var cost_lbl := UIFactory.label(I18n.t("lab.cost") % int(cost.amount), 15, MUTED)
			costs_row.add_child(cost_lbl)

			var cost_p_icon := Control.new()
			cost_p_icon.custom_minimum_size = Vector2(16, 16)
			cost_p_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cost_p_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cost_p_icon.draw.connect(func(): NeonIcons.draw_piece_icon(cost_p_icon, p_idx, 14.0, Vector2(8, 8)))
			costs_row.add_child(cost_p_icon)

			var time_have_lbl := UIFactory.label(I18n.t("lab.time_have") % [int(duration), app.store.pieces[p_idx]], 15, MUTED)
			costs_row.add_child(time_have_lbl)

			var have_p_icon := Control.new()
			have_p_icon.custom_minimum_size = Vector2(16, 16)
			have_p_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			have_p_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			have_p_icon.draw.connect(func(): NeonIcons.draw_piece_icon(have_p_icon, p_idx, 14.0, Vector2(8, 8)))
			costs_row.add_child(have_p_icon)

			var action := UIFactory.button(btn_text, func(): app.buy_tower_module(module_id), info[2])
			action.name = "Module_" + module_id
			action.disabled = not can_buy
			card.add_child(action)

	if shown_modules == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, I18n.t("lab.all_unlocked"), 15, LIME)
	if undiscovered:
		var next_wave := 5
		for mid in MODULE_IDS:
			if not app.store.module_visible(mid):
				next_wave = int(app.store.MODULE_WAVES[mid])
				break
		var hint := UIFactory.label(I18n.t("lab.next_module_hint") % next_wave, 16, MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(hint)

	ModulesScreen.append_slot_expansion(app, parent, true)

static func append_module_status(app: Control, parent: VBoxContainer) -> void:
	if not app.module_status.is_empty():
		var status := UIFactory.label(app.module_status, 16, AMBER)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(status)
