class_name AchievementsScreen
extends RefCounted
## Constrói a tela de Sala de Conquistas e Troféus Cyberpunk do Neon Void.
## Dividida em abas (Todas, Combate, Progresso, Desafios, Obtidas).

const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED
const DISABLED := GameData.DISABLED
const ACHIEVEMENTS := GameData.ACHIEVEMENTS

const TAB_COLORS := {
	"all": GameData.AMBER,
	"combat": GameData.PINK,
	"progression": GameData.CYAN,
	"special": Color("9d4edd"),
	"unlocked": GameData.LIME
}

const TAB_ICONS := {
	"all": "trophy",
	"combat": "attack",
	"progression": "progression",
	"special": "crit_chance",
	"unlocked": "trophy"
}

static func build(app: Control, content: VBoxContainer) -> void:
	for child in content.get_children():
		if child.name == "DynamicAchievements":
			content.remove_child(child)
			child.queue_free()

	content.custom_minimum_size.x = minf(760, app.size.x - 48)

	var dynamic := VBoxContainer.new()
	dynamic.name = "DynamicAchievements"
	dynamic.add_theme_constant_override("separation", 10)
	content.add_child(dynamic)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 5)
	dynamic.add_child(header_box)

	var title := UIFactory.center_label(header_box, I18n.t("ach.title", "SALA DE CONQUISTAS DO VAZIO"), 24, AMBER, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var total_count: int = ACHIEVEMENTS.size()
	var unlocked_count := 0
	for ach in ACHIEVEMENTS:
		if app.store.is_achievement_unlocked(str(ach.get("id", ""))):
			unlocked_count += 1

	var pct: float = (float(unlocked_count) / float(total_count)) * 100.0 if total_count > 0 else 0.0
	var progress_fmt: String = I18n.t("ach.progress", "Troféus Desbloqueados: %d / %d  •  %.0f%% Concluído")
	var progress_text := progress_fmt % [unlocked_count, total_count, pct]
	var subtitle := UIFactory.center_label(header_box, progress_text, 16, Color("cfc7dd"))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var bar_center := CenterContainer.new()
	bar_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(bar_center)

	var bar := UIFactory.make_bar(AMBER)
	bar.custom_minimum_size = Vector2(minf(380.0, app.size.x - 80), 10)
	bar.max_value = float(total_count)
	bar.value = float(unlocked_count)
	bar_center.add_child(bar)

	UIFactory.pieces_bar(dynamic, app.store.pieces, 14)

	append_tab_bar(app, dynamic)
	append_achievement_cards(app, dynamic)

	var close := UIFactory.button(I18n.t("menu.back_to_menu", "VOLTAR AO MENU"), app.close_achievements, AMBER)
	close.name = "CloseAchievements"
	dynamic.add_child(close)

static func append_tab_bar(app: Control, parent: VBoxContainer) -> void:
	var tabs_row := HBoxContainer.new()
	tabs_row.name = "AchievementsTabsBar"
	tabs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_row.add_theme_constant_override("separation", 5)
	parent.add_child(tabs_row)

	for tab_id in GameData.ACHIEVEMENT_TABS:
		var default_label: String = str(GameData.ACHIEVEMENT_TAB_LABELS.get(tab_id, tab_id.to_upper()))
		var label_text: String = I18n.t("ach.tab." + tab_id, default_label)
		var is_selected: bool = app.achievements_tab == tab_id
		var tab_color: Color = TAB_COLORS.get(tab_id, CYAN)
		var btn_color: Color = tab_color if is_selected else Color("6e6382")
		var tab_btn := UIFactory.tab_button(label_text, func(): app.select_achievements_tab(tab_id), btn_color, is_selected, 26)
		tab_btn.name = "Tab_ach_" + tab_id
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.custom_minimum_size.y = 38
		tab_btn.add_theme_font_size_override("font_size", 10)
		var icon_key: String = TAB_ICONS.get(tab_id, "trophy")
		tab_btn.draw.connect(func():
			var icon_color: Color = Color.WHITE if is_selected else btn_color
			NeonIcons.draw_ui(tab_btn, icon_key, 6.5, Vector2(13.0, tab_btn.size.y * 0.5), icon_color)
		)
		tabs_row.add_child(tab_btn)

static func append_achievement_cards(app: Control, parent: VBoxContainer) -> void:
	var list_box := VBoxContainer.new()
	list_box.name = "AchievementsList"
	list_box.add_theme_constant_override("separation", 8)
	parent.add_child(list_box)

	var current_tab: String = app.achievements_tab
	var shown_count := 0

	for ach in ACHIEVEMENTS:
		var ach_id: String = str(ach.get("id", ""))
		var ach_category: String = str(ach.get("category", "combat"))
		var is_unlocked: bool = app.store.is_achievement_unlocked(ach_id)

		if current_tab == "combat" and ach_category != "combat":
			continue
		elif current_tab == "progression" and ach_category != "progression":
			continue
		elif current_tab == "special" and ach_category != "special":
			continue
		elif current_tab == "unlocked" and not is_unlocked:
			continue

		shown_count += 1
		var card_color: Color = AMBER if is_unlocked else Color("322543")
		var card := UIFactory.panel(list_box, card_color)

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)

		# Ícone da Conquista
		var icon_ctrl := Control.new()
		icon_ctrl.custom_minimum_size = Vector2(46, 46)
		icon_ctrl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_name: String = str(ach.get("icon", "trophy"))
		icon_ctrl.draw.connect(func():
			if is_unlocked:
				NeonIcons.draw_ui(icon_ctrl, icon_name, 12.0, Vector2(23, 23), AMBER)
			else:
				NeonIcons.draw_ui(icon_ctrl, "lock", 11.0, Vector2(23, 23), DISABLED)
		)
		row.add_child(icon_ctrl)

		# Textos da Conquista
		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.add_theme_constant_override("separation", 3)
		row.add_child(text_col)

		var title_row := HBoxContainer.new()
		title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_row.add_theme_constant_override("separation", 8)
		text_col.add_child(title_row)

		var title_color: Color = Color.WHITE if is_unlocked else MUTED
		var ach_title: String = I18n.get_achievement_title(ach_id)
		var title_lbl := UIFactory.label(ach_title, 16, title_color, true)
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_row.add_child(title_lbl)

		var badge_text: String = I18n.t("ach.unlocked_badge", "✓ DESBLOQUEADA") if is_unlocked else I18n.t("ach.locked_badge", "[BLOQUEADA]")
		var badge_color: Color = LIME if is_unlocked else DISABLED
		var badge_lbl := UIFactory.label(badge_text, 11, badge_color, true)
		badge_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
		title_row.add_child(badge_lbl)

		var ach_desc: String = I18n.get_achievement_desc(ach_id)
		var desc_color: Color = Color("d4cee0") if is_unlocked else Color("756d83")
		var desc_lbl := UIFactory.label(ach_desc, 15, desc_color)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(desc_lbl)

		var reward_pieces: int = int(ach.get("reward_pieces", 0))
		var reward_gold: int = int(ach.get("reward_gold", 0))

		var rew_row := HBoxContainer.new()
		rew_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rew_row.add_theme_constant_override("separation", 6)
		text_col.add_child(rew_row)

		var rew_color: Color = LIME if is_unlocked else AMBER
		var claimed_fmt: String = I18n.t("ach.reward_claimed", "Recompensa Resgatada: +%d ")
		var pending_fmt: String = I18n.t("ach.reward_pending", "Recompensa: +%d ")
		var rew_prefix := claimed_fmt % reward_pieces if is_unlocked else pending_fmt % reward_pieces
		var rew_lbl := UIFactory.label(rew_prefix, 13, rew_color)
		rew_row.add_child(rew_lbl)

		var p_icon := Control.new()
		p_icon.custom_minimum_size = Vector2(16, 16)
		p_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p_icon.draw.connect(func():
			NeonIcons.draw_piece_icon(p_icon, 0, 13.0, Vector2(8, 8))
		)
		rew_row.add_child(p_icon)

		var gold_fmt: String = I18n.t("ach.reward_gold", "  •  +%d Ouro")
		var gold_lbl := UIFactory.label(gold_fmt % reward_gold, 13, rew_color)
		rew_row.add_child(gold_lbl)

	if shown_count == 0:
		var empty_lbl := UIFactory.center_label(list_box, I18n.t("ach.empty", "Nenhuma conquista nesta categoria ainda."), 16, MUTED)
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
