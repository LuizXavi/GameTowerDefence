class_name MenuScreen
extends RefCounted
## Constrói a tela inicial (Menu Principal) e o painel de Ranking Local.

const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED
const MODULE_INFO := GameData.MODULE_INFO

static func build(app: Control) -> void:
	var stack: VBoxContainer = null
	if is_instance_valid(app.menu):
		stack = app.menu.find_child("MenuContent", true, false) as VBoxContainer
	elif app.has_node("Menu"):
		app.menu = app.get_node("Menu") as Control
		stack = app.menu.find_child("MenuContent", true, false) as VBoxContainer

	if stack != null:
		for child in stack.get_children():
			stack.remove_child(child)
			child.queue_free()
	else:
		if is_instance_valid(app.menu):
			app.remove_child(app.menu)
			app.menu.queue_free()
		app.menu = Control.new()
		app.menu.name = "Menu"
		app.menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		app.add_child(app.menu)
		var bg := ColorRect.new()
		bg.name = "MenuBg"
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var shader_material := ShaderMaterial.new()
		shader_material.shader = preload("res://shaders/menu.gdshader")
		bg.material = shader_material
		app.menu.add_child(bg)
		var scroll := ScrollContainer.new()
		scroll.name = "MenuScroll"
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		app.menu.add_child(scroll)
		var centering := CenterContainer.new()
		centering.name = "Center"
		centering.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		centering.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(centering)
		var margins := UIFactory.margin(centering, 28)
		margins.name = "Margin"
		stack = VBoxContainer.new()
		stack.name = "MenuContent"
		margins.add_child(stack)
	stack.custom_minimum_size.x = minf(960, maxf(480, app.size.x - 70))
	stack.add_theme_constant_override("separation", 7)
	if app.store.best > 0:
		UIFactory.center_label(stack, I18n.t("menu.record") % app.store.best, 12, AMBER, true)
	UIFactory.center_label(stack, I18n.t("menu.tagline"), 12, CYAN, true)
	var title := UIFactory.center_label(stack, "NEON\nVOID", 82, Color.WHITE, true)
	title.add_theme_constant_override("line_spacing", -14)
	var title_material := ShaderMaterial.new()
	title_material.shader = preload("res://shaders/title.gdshader")
	title.material = title_material
	UIFactory.center_label(stack, I18n.t("menu.subtitle"), 24, Color("d4cee0"))
	UIFactory.spacer(stack, 10)
	var start := UIFactory.button(I18n.t("menu.play"), app.start_game, PINK, true)
	start.name = "Start"
	start.custom_minimum_size = Vector2(328, 58)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 18)
	stack.add_child(start)
	var modules_button := UIFactory.button(I18n.t("menu.modules"), app.show_modules, PINK)
	modules_button.name = "Modules"
	modules_button.custom_minimum_size = Vector2(328, 48)
	modules_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(modules_button)
	UIFactory.center_label(stack, I18n.t("menu.slots_unlocked") % app.store.unlocked_tower_slots, 16, CYAN)
	var loadout := UIFactory.center_label(stack, tower_loadout_text(app.store), 17, MUTED)
	loadout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var research_button := UIFactory.button(I18n.t("menu.research"), app.show_research, CYAN)
	research_button.name = "Research"
	research_button.custom_minimum_size = Vector2(328, 48)
	research_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	research_button.draw.connect(func(): NeonIcons.draw_ui(research_button, "lab", 9.0, Vector2(18.0, research_button.size.y * 0.5), CYAN))
	stack.add_child(research_button)
	var codex_button := UIFactory.button(I18n.t("menu.codex"), app.show_codex, AMBER)
	codex_button.name = "Codex"
	codex_button.custom_minimum_size = Vector2(328, 44)
	codex_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	codex_button.draw.connect(func(): NeonIcons.draw_ui(codex_button, "codex", 8.5, Vector2(18.0, codex_button.size.y * 0.5), AMBER))
	stack.add_child(codex_button)
	var achievements_button := UIFactory.button(I18n.t("menu.achievements"), app.show_achievements, LIME)
	achievements_button.name = "Achievements"
	achievements_button.custom_minimum_size = Vector2(328, 44)
	achievements_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	achievements_button.draw.connect(func(): NeonIcons.draw_ui(achievements_button, "trophy", 8.5, Vector2(18.0, achievements_button.size.y * 0.5), LIME))
	stack.add_child(achievements_button)
	var ach_label := UIFactory.center_label(stack, I18n.t("menu.trophies") % [app.store.achievements.size(), GameData.ACHIEVEMENTS.size()], 15, MUTED)
	ach_label.name = "AchievementsProgressLabel"
	UIFactory.pieces_bar(stack, app.store.pieces, 14)
	UIFactory.center_label(stack, I18n.t("menu.or_enter"), 14, MUTED)
	UIFactory.spacer(stack, 5)
	UIFactory.center_label(stack, I18n.t("menu.tip"), 18, Color("d9cdb8"))
	UIFactory.spacer(stack, 12)
	var cards := BoxContainer.new()
	cards.name = "Cards"
	cards.vertical = app.size.x < 700
	cards.add_theme_constant_override("separation", 12)
	stack.add_child(cards)
	var headings := [I18n.t("menu.card1_title"), I18n.t("menu.card2_title"), I18n.t("menu.card3_title")]
	var descriptions := [I18n.t("menu.card1_desc"), I18n.t("menu.card2_desc"), I18n.t("menu.card3_desc")]
	for i in 3:
		var content := UIFactory.panel(cards, [PINK, LIME, CYAN][i])
		content.add_child(UIFactory.label(["⌖", "↑", "✧"][i], 24, [PINK, LIME, CYAN][i], true))
		content.add_child(UIFactory.label(headings[i], 13, [PINK, LIME, CYAN][i], true))
		var desc := UIFactory.label(descriptions[i], 18, Color("bfb7cf"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(desc)
	var lower := BoxContainer.new()
	lower.name = "Lower"
	lower.vertical = app.size.x < 1000
	lower.add_theme_constant_override("separation", 12)
	stack.add_child(lower)
	var controls := UIFactory.panel(lower, CYAN)
	controls.add_child(UIFactory.label(I18n.t("menu.controls_title"), 12, CYAN, true))
	controls.add_child(UIFactory.label(I18n.t("menu.controls_desc"), 18, Color("bfb7cf")))
	build_ranking(lower, app.store.scores, true)
	UIFactory.spacer(stack, 8)
	var bottom_row := HBoxContainer.new()
	bottom_row.name = "MenuBottomControls"
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 12)
	stack.add_child(bottom_row)

	var mute_text: String = I18n.t("hud.sound_off") if app.store.muted else I18n.t("hud.sound_on")
	var mute := UIFactory.button(mute_text, app.toggle_mute)
	mute.name = "Mute"
	mute.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottom_row.add_child(mute)
	app.mute_buttons.append(mute)

	var lang_btn := UIFactory.button(I18n.t("hud.lang_btn"), app.toggle_language, CYAN)
	lang_btn.name = "Language"
	lang_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottom_row.add_child(lang_btn)
	if not app.lang_buttons.has(lang_btn):
		app.lang_buttons.append(lang_btn)

	var options_row := HBoxContainer.new()
	options_row.name = "MenuOptionsRow"
	options_row.alignment = BoxContainer.ALIGNMENT_CENTER
	options_row.add_theme_constant_override("separation", 10)
	stack.add_child(options_row)

	var shake_text: String = I18n.t("menu.shake_opt", "TREMORES: ") + (I18n.t("menu.off", "OFF") if app.store.reduce_shake else I18n.t("menu.on", "ON"))
	var shake_btn := UIFactory.button(shake_text, app.toggle_reduce_shake, AMBER)
	shake_btn.name = "ReduceShakeButton"
	shake_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	options_row.add_child(shake_btn)

	var fx_text: String = I18n.t("menu.effects_opt", "EFEITOS: ") + (I18n.t("menu.reduced", "REDUZIDOS") if app.store.reduce_effects else I18n.t("menu.normal", "NORMAIS"))
	var fx_btn := UIFactory.button(fx_text, app.toggle_reduce_effects, PINK)
	fx_btn.name = "ReduceEffectsButton"
	fx_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	options_row.add_child(fx_btn)

	var dmg_text: String = I18n.t("menu.numbers_opt", "DANO: ") + (I18n.t("menu.on", "ON") if app.store.damage_numbers else I18n.t("menu.off", "OFF"))
	var dmg_btn := UIFactory.button(dmg_text, app.toggle_damage_numbers, LIME)
	dmg_btn.name = "DamageNumbersButton"
	dmg_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	options_row.add_child(dmg_btn)

	UIFactory.center_label(stack, I18n.t("menu.version"), 13, Color("726781"))

static func build_ranking(parent: Node, scores: Array, compact := false) -> Control:
	var content := UIFactory.panel(parent, AMBER)
	content.add_child(UIFactory.label(I18n.t("menu.ranking_title"), 11, AMBER, true))
	if scores.is_empty():
		content.add_child(UIFactory.label(I18n.t("menu.no_records"), 18, MUTED))
	else:
		for i in mini(scores.size(), 3 if compact else 10):
			var entry: Dictionary = scores[i]
			content.add_child(UIFactory.label("#%d   %-10s     W%d     %d" % [i + 1, entry.name, entry.wave, entry.score], 15, AMBER if i == 0 else Color("cfc7dd")))
	return content.get_parent()

static func pieces_text(values: Array) -> String:
	return "  ".join(PackedStringArray([
		"■ %d" % int(values[0]),
		"▲ %d" % int(values[1]),
		"⬢ %d" % int(values[2]),
		"✦ %d" % int(values[3])
	]))

static func tower_loadout_text(store: Variant) -> String:
	var summary: PackedStringArray = []
	for index in store.unlocked_tower_slots:
		var module_id: String = store.tower_loadout[index]
		summary.append("%d · %s" % [index + 1, I18n.get_module_info(module_id)[0]])
	return "   |   ".join(summary)
