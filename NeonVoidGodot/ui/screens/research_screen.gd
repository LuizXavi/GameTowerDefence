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

	var close := UIFactory.button("VOLTAR AO MENU", app.close_research, CYAN)
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

	for tab_id in GameData.RESEARCH_TABS:
		var label_text: String = str(GameData.RESEARCH_TAB_LABELS.get(tab_id, tab_id.to_upper()))
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

	var title := UIFactory.label("SÍNTESE EM ANDAMENTO: %s" % app.store.active_research_name(), 16, LIME, true)
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

	var time_lbl := UIFactory.label("%.1fs restantes (%d%%)" % [app.store.active_research_remaining(), int(app.store.active_research_progress() * 100.0)], 14, CYAN)
	time_lbl.name = "ActiveResearchTime"
	banner.add_child(time_lbl)

static func update_progress(app: Control) -> void:
	if not app.research_content:
		return
	var bar: ProgressBar = app.research_content.find_child("ActiveResearchBar", true, false)
	var lbl: Label = app.research_content.find_child("ActiveResearchTime", true, false)
	if bar != null and lbl != null and app.store.is_researching():
		bar.value = app.store.active_research_progress() * 100.0
		lbl.text = "%.1fs restantes (%d%%)" % [app.store.active_research_remaining(), int(app.store.active_research_progress() * 100.0)]

static func append_lab_tab(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, "MELHORIAS DO LABORATÓRIO", "lab", AMBER)
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

		var words := "%s  %s  •  Nv.%d/%d\n%s\n" % [PIECE_SHORT[p_idx], GameData.LAB_RESEARCH_NAMES[i], level, maximum, GameData.LAB_RESEARCH_DESCS[i]]
		if is_active:
			words += "⚡ EM SÍNTESE  •  %.1fs restantes" % app.store.active_research_remaining()
		elif level >= maximum:
			words += "✓ UPGRADE CONCLUÍDO"
		elif is_busy:
			words += "LABORATÓRIO OCUPADO  •  Custo: %d %s" % [cost, PIECE_SHORT[p_idx]]
		else:
			words += "Custo: %d %s  •  Tempo: %ds  •  Você tem: %d" % [cost, PIECE_SHORT[p_idx], int(duration), app.store.pieces[p_idx]]

		var btn_color: Color = COLORS[p_idx]
		var btn := UIFactory.card_button(words, func(): app.buy_lab_research(i), btn_color, "right", 58)
		btn.name = "LabResearch%d" % (i + 1)
		btn.custom_minimum_size.y = 82
		btn.disabled = not can_buy
		var icon_name: String = GameData.LAB_RESEARCH_ICONS[i]
		btn.draw.connect(func(): NeonIcons.draw_ui(btn, icon_name, 12.5, Vector2(btn.size.x - 29.0, btn.size.y * 0.5), btn_color))
		parent.add_child(btn)

	if shown == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, "✓ Todas as melhorias do laboratório foram concluídas.", 15, LIME)

static func append_attack_tab(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, "PESQUISAS DE ATAQUE E COMBATE", "attack", PINK)
	var shown := 0
	for i in GameData.RESEARCH_TAB_INDICES["attack"]:
		if append_research_card(app, parent, i):
			shown += 1
	if shown == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, "✓ Todas as pesquisas ofensivas foram concluídas.", 15, LIME)

static func append_defense_tab(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, "PESQUISAS DE DEFESA E ESCUDOS", "defense", CYAN)
	var shown := 0
	for i in GameData.RESEARCH_TAB_INDICES["defense"]:
		if append_research_card(app, parent, i):
			shown += 1
	if shown == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, "✓ Todas as pesquisas defensivas foram concluídas.", 15, LIME)

static func append_economy_tab(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, "PESQUISAS DE ECONOMIA E FRAGMENTOS", "economy", LIME)
	var shown := 0
	for i in GameData.RESEARCH_TAB_INDICES["economy"]:
		if append_research_card(app, parent, i):
			shown += 1
	if shown == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, "✓ Todas as pesquisas de economia foram concluídas.", 15, LIME)

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

	var words := "%s  %s  •  Nv.%d/%d\n%s\n" % [PIECE_SHORT[p_idx], RESEARCH_NAMES[i], level, maximum, RESEARCH_DESCS[i]]
	if is_active:
		words += "⚡ EM SÍNTESE  •  %.1fs restantes" % app.store.active_research_remaining()
	elif level >= maximum:
		words += "✓ PESQUISA CONCLUÍDA"
	elif is_busy:
		words += "LABORATÓRIO OCUPADO  •  Custo: %d %s" % [cost, PIECE_SHORT[p_idx]]
	else:
		words += "Custo: %d %s  •  Tempo: %ds  •  Você tem: %d" % [cost, PIECE_SHORT[p_idx], int(duration), app.store.pieces[p_idx]]

	var btn_color: Color = MODULE_INFO[MODULE_IDS[i - 18]][2] if (i >= 18 and i < 25) else COLORS[p_idx]
	var research_button := UIFactory.card_button(words, func(): app.buy_research(i), btn_color, "right", 58)
	research_button.name = "Research%d" % (i + 1)
	research_button.custom_minimum_size.y = 82
	research_button.disabled = not can_buy

	if i >= 18 and i < 25:
		var tower_mod_id: String = MODULE_IDS[i - 18]
		research_button.draw.connect(func(): NeonIcons.draw_tower(research_button, tower_mod_id, 12.0, Vector2(research_button.size.x - 29.0, research_button.size.y * 0.5)))
	else:
		var r_icon: String = GameData.research_icon(i)
		research_button.draw.connect(func(): NeonIcons.draw_ui(research_button, r_icon, 12.0, Vector2(research_button.size.x - 29.0, research_button.size.y * 0.5), btn_color))

	parent.add_child(research_button)
	return true

static func append_towers_tab(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, "DESBLOQUEIO DE MÓDULOS DE TORRE", "towers", PINK)
	var shown_modules := 0
	var undiscovered := false
	for module_id in MODULE_IDS:
		if module_id == "plasma":
			continue
		if not app.store.module_visible(module_id):
			undiscovered = true
			continue
		var info: Array = MODULE_INFO[module_id]
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
			var status := UIFactory.label("✓ DESBLOQUEADO • disponível no hangar", 15, LIME)
			status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(status)
		else:
			var cost: Dictionary = app.store.module_cost(module_id)
			var p_idx: int = int(cost.piece_index)
			var duration: float = app.store.get_module_research_duration(module_id)
			var is_active: bool = app.store.active_research.get("type") == "module" and str(app.store.active_research.get("target", "")) == module_id
			var is_busy: bool = app.store.is_researching() and not is_active
			var can_buy: bool = app.store.can_research_module(module_id) and not is_busy

			var btn_text := "PESQUISAR (%ds)" % int(duration)
			if is_active:
				btn_text = "⚡ EM SÍNTESE • %.1fs" % app.store.active_research_remaining()
			elif is_busy:
				btn_text = "LABORATÓRIO OCUPADO"
			elif not app.store.can_research_module(module_id):
				btn_text = "PEÇAS INSUFICIENTES"

			var costs := UIFactory.label("Custo: %d %s  •  Tempo: %ds  •  Você tem: %d" % [int(cost.amount), PIECE_SHORT[p_idx], int(duration), app.store.pieces[p_idx]], 15, MUTED)
			costs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(costs)

			var action := UIFactory.button(btn_text, func(): app.buy_tower_module(module_id), info[2])
			action.name = "Module_" + module_id
			action.disabled = not can_buy
			card.add_child(action)

	if shown_modules == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, "✓ Todos os módulos de torre foram desbloqueados.", 15, LIME)
	if undiscovered:
		var next_wave := 5
		for mid in MODULE_IDS:
			if not app.store.module_visible(mid):
				next_wave = int(app.store.MODULE_WAVES[mid])
				break
		var hint := UIFactory.label("◇ Novo módulo de torre: alcance a wave %d para descobrir." % next_wave, 16, MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(hint)

	ModulesScreen.append_slot_expansion(app, parent, true)

static func append_module_status(app: Control, parent: VBoxContainer) -> void:
	if not app.module_status.is_empty():
		var status := UIFactory.label(app.module_status, 16, AMBER)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(status)
