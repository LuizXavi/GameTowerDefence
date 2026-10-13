class_name ResearchScreen
extends RefCounted
## Constrói a tela do Laboratório de Pesquisas (Ataque/Defesa, Especialização de Torretas e Escudos).

const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const AMBER := GameData.AMBER
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
	UIFactory.center_label(dynamic, app.pieces_text(), 16, AMBER, true)
	app.append_hide_completed_button(dynamic)
	app.section_header_with_icon(dynamic, "PESQUISAS DE ATAQUE E DEFESA", "attack", CYAN)
	var combat_shown := 0
	var tower_shown := 0
	var shield_shown := 0
	for i in RESEARCH_NAMES.size():
		if i == 18:
			if combat_shown == 0 and app.hide_completed_research:
				UIFactory.center_label(dynamic, "✓ Todas as pesquisas de ataque e defesa foram concluídas.", 15, LIME)
			app.section_header_with_icon(dynamic, "ESPECIALIZAÇÃO DE TORRETAS", "towers", PINK)
		elif i == 25:
			if tower_shown == 0 and app.hide_completed_research:
				UIFactory.center_label(dynamic, "✓ Todas as especializações de torretas foram concluídas.", 15, LIME)
			app.section_header_with_icon(dynamic, "TECNOLOGIA DE ESCUDOS", "defense", CYAN)
		var level: int = app.store.research[i]
		var maximum: int = app.store.RESEARCH_MAX[i]
		if app.hide_completed_research and level >= maximum:
			continue
		if i < 18:
			combat_shown += 1
		elif i < 25:
			tower_shown += 1
		else:
			shield_shown += 1
		var cost: int = app.store.research_cost(i)
		var p_idx: int = app.store.piece_index_for_research(i)
		var words := "%s  %s  •  Nv.%d/%d\n%s\n" % [PIECE_SHORT[p_idx], RESEARCH_NAMES[i], level, maximum, RESEARCH_DESCS[i]]
		words += "✓ PESQUISA CONCLUÍDA" if level >= maximum else "Custo: %d %s   •   Você tem: %d" % [cost, PIECE_SHORT[p_idx], app.store.pieces[p_idx]]
		var btn_color: Color = MODULE_INFO[MODULE_IDS[i - 18]][2] if (i >= 18 and i < 25) else COLORS[p_idx]
		var research_button := UIFactory.button(words, func(): app.buy_research(i), btn_color)
		research_button.name = "Research%d" % (i + 1)
		research_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		research_button.custom_minimum_size.y = 78
		research_button.disabled = not app.store.can_research(i)
		if i >= 18 and i < 25:
			var tower_mod_id: String = MODULE_IDS[i - 18]
			research_button.draw.connect(func(): NeonIcons.draw_tower(research_button, tower_mod_id, 13.0, Vector2(research_button.size.x - 36.0, research_button.size.y * 0.5)))
		else:
			var r_icon: String = GameData.research_icon(i)
			research_button.draw.connect(func(): NeonIcons.draw_ui(research_button, r_icon, 13.0, Vector2(research_button.size.x - 36.0, research_button.size.y * 0.5), btn_color))
		dynamic.add_child(research_button)
	if shield_shown == 0 and app.hide_completed_research:
		UIFactory.center_label(dynamic, "✓ Todas as pesquisas de tecnologia de escudos foram concluídas.", 15, LIME)
	ModulesScreen.append_module_cards(app, dynamic)
	ModulesScreen.append_slot_expansion(app, dynamic, true)
	ModulesScreen.append_module_status(app, dynamic)
	var close := UIFactory.button("VOLTAR AO MENU", app.close_research, CYAN)
	close.name = "CloseResearch"
	dynamic.add_child(close)
	app.contain_modal_focus()
	if initial_focus:
		app.focus_first_modal_action()
