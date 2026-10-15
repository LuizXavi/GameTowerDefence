class_name ModulesScreen
extends RefCounted
## Constrói a tela de Módulos da Torre (slots do hangar, pesquisa de módulos e expansão).

const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED
const PIECE_SHORT := GameData.PIECE_SHORT
const MODULE_IDS := GameData.MODULE_IDS
const MODULE_INFO := GameData.MODULE_INFO

static func build(app: Control, initial_focus := false) -> void:
	for child in app.modules_content.get_children():
		if child.name == "DynamicModules":
			app.modules_content.remove_child(child)
			child.queue_free()
	var dynamic := VBoxContainer.new()
	dynamic.name = "DynamicModules"
	dynamic.add_theme_constant_override("separation", 10)
	app.modules_content.add_child(dynamic)
	UIFactory.pieces_bar(dynamic, app.store.pieces, 16)
	append_tower_slots(app, dynamic)
	append_slot_expansion(app, dynamic)
	append_lab_shortcut(app, dynamic)
	append_module_status(app, dynamic)
	var close := UIFactory.button(I18n.t("menu.back_to_menu", "VOLTAR AO MENU"), app.close_modules, PINK)
	close.name = "CloseModules"
	dynamic.add_child(close)
	app.contain_modal_focus()
	if initial_focus:
		app.focus_first_modal_action()

static func append_lab_shortcut(app: Control, parent: VBoxContainer) -> void:
	var card := UIFactory.panel(parent, CYAN)
	card.add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.draw.connect(func(): NeonIcons.draw_ui(icon, "lab", 10.0, Vector2(14, 14), CYAN))
	row.add_child(icon)
	var label := UIFactory.label(I18n.t("modules.lab_shortcut_title", "NOVOS MÓDULOS DE TORRE"), 16, CYAN, true)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var desc := UIFactory.label(I18n.t("modules.lab_shortcut_desc", "A pesquisa e síntese de novos módulos de torre é realizada no Laboratório de Pesquisas."), 15, Color("d4cee0"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(desc)
	var lab_btn := UIFactory.button(I18n.t("modules.lab_shortcut_btn", "IR AO LABORATÓRIO (ABA TORRES)"), func():
		app.close_modules()
		app.show_research()
		app.select_research_tab("towers")
	, CYAN)
	lab_btn.name = "GoToLabResearch"
	card.add_child(lab_btn)

static func append_module_cards(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, I18n.t("modules.title", "PESQUISA DE MÓDULOS"), "towers", PINK)
	if app.phase == "modules":
		app.append_hide_completed_button(parent)
	var undiscovered := false
	var shown_count := 0
	for module_id in MODULE_IDS:
		if not app.store.module_visible(module_id):
			undiscovered = true
			continue
		var info: Array = I18n.get_module_info(module_id)
		var unlocked: bool = app.store.module_unlocked(module_id)
		if app.hide_completed_research and unlocked:
			continue
		shown_count += 1
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
		var desc := UIFactory.label(info[1], 16, Color("d4cee0"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(desc)

		var action: Button
		if unlocked:
			var status := UIFactory.label(I18n.t("modules.unlocked_all_slots", "✓ PESQUISADO • disponível em todos os slots"), 15, LIME)
			status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(status)
			continue
		else:
			var cost: Dictionary = app.store.module_cost(module_id)
			var index: int = int(cost.piece_index)
			var duration: float = app.store.get_module_research_duration(module_id)
			var is_active: bool = app.store.active_research.get("type") == "module" and str(app.store.active_research.get("target", "")) == module_id
			var is_busy: bool = app.store.is_researching() and not is_active
			var costs_str: String = I18n.t("modules.cost_format", "BLOQUEADO • Custo: %d %s • Tempo: %ds • Você tem: %d")
			var costs := UIFactory.label(costs_str % [int(cost.amount), PIECE_SHORT[index], int(duration), app.store.pieces[index]], 16, MUTED)
			costs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(costs)
			var btn_text := I18n.t("modules.research_in_lab", "PESQUISAR NO LABORATÓRIO")
			if is_active:
				btn_text = I18n.t("research.in_synthesis", "⚡ EM SÍNTESE • %.1fs") % app.store.active_research_remaining()
			elif is_busy:
				btn_text = I18n.t("research.lab_busy", "LABORATÓRIO OCUPADO")
			elif not app.store.can_research_module(module_id):
				btn_text = I18n.t("research.insufficient_pieces", "PESQUISAR • PEÇAS INSUFICIENTES")
			action = UIFactory.button(btn_text, func(): app.buy_tower_module(module_id), info[2])
			action.disabled = not (app.store.can_research_module(module_id) and not is_busy)
		action.name = "Module_" + module_id
		card.add_child(action)
	if shown_count == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, I18n.t("modules.all_completed", "✓ Todos os módulos descobertos já foram pesquisados."), 15, LIME)
	if undiscovered:
		var next_wave := 5
		for mid in MODULE_IDS:
			if not app.store.module_visible(mid):
				next_wave = int(app.store.MODULE_WAVES[mid])
				break
		var hint_str: String = I18n.t("modules.next_wave_hint", "◇  Novo módulo: alcance a wave %d para descobrir.")
		var hint := UIFactory.label(hint_str % next_wave, 18, MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(hint)

static func append_tower_slots(app: Control, parent: VBoxContainer) -> void:
	var slots_fmt: String = I18n.t("modules.slots_unlocked", "SLOTS LIBERADOS: %d/7")
	UIFactory.center_label(parent, slots_fmt % app.store.unlocked_tower_slots, 16, CYAN, true)
	for index in app.store.unlocked_tower_slots:
		var selected: String = app.store.tower_loadout[index]
		var info: Array = I18n.get_module_info(selected)
		var card := UIFactory.panel(parent, info[2])

		var head_row := HBoxContainer.new()
		head_row.add_theme_constant_override("separation", 10)
		card.add_child(head_row)

		var slot_icon := Control.new()
		slot_icon.custom_minimum_size = Vector2(32, 32)
		slot_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot_icon.draw.connect(func(): NeonIcons.draw_tower(slot_icon, selected, 11.0))
		head_row.add_child(slot_icon)

		var heading := UIFactory.label(I18n.t("modules.slot_header", "SLOT %d  •  %s") % [index + 1, info[0]], 16, info[2], true)
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head_row.add_child(heading)

		var choices := GridContainer.new()
		choices.name = "SlotChoices%d" % index
		choices.columns = 1 if app.size.x < 700 else 3
		choices.add_theme_constant_override("h_separation", 8)
		choices.add_theme_constant_override("v_separation", 8)
		card.add_child(choices)
		for module_id in MODULE_IDS:
			if not app.store.module_unlocked(module_id):
				continue
			var minfo: Array = I18n.get_module_info(module_id)
			var module_name: String = str(minfo[0]).to_upper()
			if module_name.begins_with("TORRE DE "):
				module_name = module_name.substr(9)
			elif module_name.begins_with("TORRE "):
				module_name = module_name.substr(6)
			elif module_name.ends_with(" TOWER"):
				module_name = module_name.substr(0, module_name.length() - 6)
			var equipped: bool = selected == module_id
			var action := UIFactory.button("", func(): app.equip_tower_module(index, module_id), minfo[2])
			action.name = "Slot%d_%s" % [index, module_id]
			action.tooltip_text = I18n.t("modules.equipped_in_slot", "Equipado neste slot") if equipped else I18n.t("modules.equip_in_slot", "Equipar %s no slot %d") % [minfo[0], index + 1]
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
				var check := UIFactory.label("✓", 13, LIME, true)
				check.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn_content.add_child(check)

			var btn_icon := Control.new()
			btn_icon.custom_minimum_size = Vector2(26, 26)
			btn_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_icon.draw.connect(func(): NeonIcons.draw_tower(btn_icon, module_id, 8.5))
			btn_content.add_child(btn_icon)

			var btn_label := UIFactory.label(module_name, 12, Color.WHITE if equipped else minfo[2], true)
			btn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_content.add_child(btn_label)

			choices.add_child(action)

static func append_slot_expansion(app: Control, parent: VBoxContainer, laboratory := false) -> void:
	var index: int = app.store.unlocked_tower_slots
	if index >= 7:
		parent.add_child(UIFactory.label(I18n.t("modules.expansion_completed", "✓ EXPANSÃO CONCLUÍDA • 7/7 slots liberados"), 17, LIME))
		return
	if not app.store.slot_visible(index):
		if not laboratory:
			var hint_fmt: String = I18n.t("modules.next_slot_hint", "◇ Próximo slot: alcance a wave %d para descobrir.")
			var hint := UIFactory.label(hint_fmt % app.store.SLOT_WAVES[index], 18, MUTED)
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			parent.add_child(hint)
		return
	var card := UIFactory.panel(parent, CYAN)
	card.add_child(UIFactory.label(I18n.t("modules.expansion_slot", "EXPANSÃO  •  SLOT %d") % (index + 1), 17, CYAN, true))
	var cost: Dictionary = app.store.slot_cost(index)
	var piece_index: int = int(cost.piece_index)
	var duration: float = app.store.get_slot_research_duration(index)
	var is_active: bool = app.store.active_research.get("type") == "slot" and int(app.store.active_research.get("target", -1)) == index
	var is_busy: bool = app.store.is_researching() and not is_active
	var available: bool = app.store.can_research_slot(index) and not is_busy

	var costs_row := HBoxContainer.new()
	costs_row.add_theme_constant_override("separation", 4)
	card.add_child(costs_row)

	var cost_lbl := UIFactory.label(I18n.t("modules.discovered_cost", "DESCOBERTO  •  Custo: %d ") % int(cost.amount), 17, MUTED)
	costs_row.add_child(cost_lbl)

	var cost_p_icon := Control.new()
	cost_p_icon.custom_minimum_size = Vector2(16, 16)
	cost_p_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cost_p_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_p_icon.draw.connect(func(): NeonIcons.draw_piece_icon(cost_p_icon, piece_index, 14.0, Vector2(8, 8)))
	costs_row.add_child(cost_p_icon)

	var time_have_lbl := UIFactory.label(I18n.t("modules.time_you_have", "  •  Tempo: %ds  •  Você tem: %d ") % [int(duration), app.store.pieces[piece_index]], 17, MUTED)
	costs_row.add_child(time_have_lbl)

	var have_p_icon := Control.new()
	have_p_icon.custom_minimum_size = Vector2(16, 16)
	have_p_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	have_p_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	have_p_icon.draw.connect(func(): NeonIcons.draw_piece_icon(have_p_icon, piece_index, 14.0, Vector2(8, 8)))
	costs_row.add_child(have_p_icon)

	var btn_text := I18n.t("modules.research_slot_btn", "PESQUISAR SLOT %d (%ds)") % [index + 1, int(duration)]
	if is_active:
		btn_text = I18n.t("research.in_synthesis", "⚡ EM SÍNTESE • %.1fs") % app.store.active_research_remaining()
	elif is_busy:
		btn_text = I18n.t("research.lab_busy", "LABORATÓRIO OCUPADO")
	elif not app.store.can_research_slot(index):
		btn_text = I18n.t("research.insufficient_pieces", "PESQUISAR • PEÇAS INSUFICIENTES")

	var action := UIFactory.button(btn_text, func(): app.buy_tower_slot(index), CYAN)
	action.name = "ResearchSlot%d" % index
	action.disabled = not available
	card.add_child(action)

static func append_module_status(app: Control, parent: VBoxContainer) -> void:
	if not app.module_status.is_empty():
		var status := UIFactory.label(app.module_status, 17, AMBER)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(status)
