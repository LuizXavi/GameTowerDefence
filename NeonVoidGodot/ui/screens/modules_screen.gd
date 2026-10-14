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
	var close := UIFactory.button("VOLTAR AO MENU", app.close_modules, PINK)
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
	var label := UIFactory.label("NOVOS MÓDULOS DE TORRE", 16, CYAN, true)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var desc := UIFactory.label("A pesquisa e síntese de novos módulos de torre é realizada no Laboratório de Pesquisas.", 15, Color("d4cee0"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(desc)
	var lab_btn := UIFactory.button("IR AO LABORATÓRIO (ABA TORRES)", func():
		app.close_modules()
		app.show_research()
		app.select_research_tab("towers")
	, CYAN)
	lab_btn.name = "GoToLabResearch"
	card.add_child(lab_btn)

static func append_module_cards(app: Control, parent: VBoxContainer) -> void:
	app.section_header_with_icon(parent, "PESQUISA DE MÓDULOS", "towers", PINK)
	if app.phase == "modules":
		app.append_hide_completed_button(parent)
	var undiscovered := false
	var shown_count := 0
	for module_id in MODULE_IDS:
		if not app.store.module_visible(module_id):
			undiscovered = true
			continue
		var info: Array = MODULE_INFO[module_id]
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
			var status := UIFactory.label("✓ PESQUISADO • disponível em todos os slots", 15, LIME)
			status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(status)
			continue
		else:
			var cost: Dictionary = app.store.module_cost(module_id)
			var index: int = int(cost.piece_index)
			var duration: float = app.store.get_module_research_duration(module_id)
			var is_active: bool = app.store.active_research.get("type") == "module" and str(app.store.active_research.get("target", "")) == module_id
			var is_busy: bool = app.store.is_researching() and not is_active
			var costs := UIFactory.label("BLOQUEADO • Custo: %d %s • Tempo: %ds • Você tem: %d" % [int(cost.amount), PIECE_SHORT[index], int(duration), app.store.pieces[index]], 16, MUTED)
			costs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(costs)
			var btn_text := "PESQUISAR NO LABORATÓRIO"
			if is_active:
				btn_text = "⚡ EM SÍNTESE • %.1fs" % app.store.active_research_remaining()
			elif is_busy:
				btn_text = "LABORATÓRIO OCUPADO"
			elif not app.store.can_research_module(module_id):
				btn_text = "PESQUISAR • PEÇAS INSUFICIENTES"
			action = UIFactory.button(btn_text, func(): app.buy_tower_module(module_id), info[2])
			action.disabled = not (app.store.can_research_module(module_id) and not is_busy)
		action.name = "Module_" + module_id
		card.add_child(action)
	if shown_count == 0 and app.hide_completed_research:
		UIFactory.center_label(parent, "✓ Todos os módulos descobertos já foram pesquisados.", 15, LIME)
	if undiscovered:
		var next_wave := 5
		for mid in MODULE_IDS:
			if not app.store.module_visible(mid):
				next_wave = int(app.store.MODULE_WAVES[mid])
				break
		var hint := UIFactory.label("◇  Novo módulo: alcance a wave %d para descobrir." % next_wave, 18, MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(hint)

static func append_tower_slots(app: Control, parent: VBoxContainer) -> void:
	UIFactory.center_label(parent, "SLOTS LIBERADOS: %d/7" % app.store.unlocked_tower_slots, 16, CYAN, true)
	for index in app.store.unlocked_tower_slots:
		var selected: String = app.store.tower_loadout[index]
		var card := UIFactory.panel(parent, MODULE_INFO[selected][2])

		var head_row := HBoxContainer.new()
		head_row.add_theme_constant_override("separation", 10)
		card.add_child(head_row)

		var slot_icon := Control.new()
		slot_icon.custom_minimum_size = Vector2(32, 32)
		slot_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot_icon.draw.connect(func(): NeonIcons.draw_tower(slot_icon, selected, 11.0))
		head_row.add_child(slot_icon)

		var heading := UIFactory.label("SLOT %d  •  %s" % [index + 1, MODULE_INFO[selected][0]], 16, MODULE_INFO[selected][2], true)
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
			var action := UIFactory.button("", func(): app.equip_tower_module(index, module_id), MODULE_INFO[module_id][2])
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
				var check := UIFactory.label("✓", 13, LIME, true)
				check.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn_content.add_child(check)

			var btn_icon := Control.new()
			btn_icon.custom_minimum_size = Vector2(26, 26)
			btn_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_icon.draw.connect(func(): NeonIcons.draw_tower(btn_icon, module_id, 8.5))
			btn_content.add_child(btn_icon)

			var btn_label := UIFactory.label(module_name, 12, Color.WHITE if equipped else MODULE_INFO[module_id][2], true)
			btn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_content.add_child(btn_label)

			choices.add_child(action)

static func append_slot_expansion(app: Control, parent: VBoxContainer, laboratory := false) -> void:
	var index: int = app.store.unlocked_tower_slots
	if index >= 7:
		parent.add_child(UIFactory.label("✓ EXPANSÃO CONCLUÍDA • 7/7 slots liberados", 17, LIME))
		return
	if not app.store.slot_visible(index):
		if not laboratory:
			var hint := UIFactory.label("◇ Próximo slot: alcance a wave %d para descobrir." % app.store.SLOT_WAVES[index], 18, MUTED)
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			parent.add_child(hint)
		return
	var card := UIFactory.panel(parent, CYAN)
	card.add_child(UIFactory.label("EXPANSÃO  •  SLOT %d" % (index + 1), 17, CYAN, true))
	var cost: Dictionary = app.store.slot_cost(index)
	var piece_index: int = int(cost.piece_index)
	var duration: float = app.store.get_slot_research_duration(index)
	var is_active: bool = app.store.active_research.get("type") == "slot" and int(app.store.active_research.get("target", -1)) == index
	var is_busy: bool = app.store.is_researching() and not is_active
	var available: bool = app.store.can_research_slot(index) and not is_busy

	var costs := UIFactory.label("DESCOBERTO • Custo: %d %s • Tempo: %ds • Você tem: %d" % [int(cost.amount), PIECE_SHORT[piece_index], int(duration), app.store.pieces[piece_index]], 17, MUTED)
	costs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(costs)

	var btn_text := "PESQUISAR SLOT %d (%ds)" % [index + 1, int(duration)]
	if is_active:
		btn_text = "⚡ EM SÍNTESE • %.1fs" % app.store.active_research_remaining()
	elif is_busy:
		btn_text = "LABORATÓRIO OCUPADO"
	elif not app.store.can_research_slot(index):
		btn_text = "PESQUISAR • PEÇAS INSUFICIENTES"

	var action := UIFactory.button(btn_text, func(): app.buy_tower_slot(index), CYAN)
	action.name = "ResearchSlot%d" % index
	action.disabled = not available
	card.add_child(action)

static func append_module_status(app: Control, parent: VBoxContainer) -> void:
	if not app.module_status.is_empty():
		var status := UIFactory.label(app.module_status, 17, AMBER)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(status)
