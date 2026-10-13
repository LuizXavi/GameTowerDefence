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
	if is_instance_valid(app.menu):
		app.remove_child(app.menu)
		app.menu.queue_free()
	app.menu = Control.new()
	app.menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.add_child(app.menu)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://shaders/menu.gdshader")
	bg.material = shader_material
	app.menu.add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	app.menu.add_child(scroll)
	var centering := CenterContainer.new()
	centering.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centering.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(centering)
	var margins := UIFactory.margin(centering, 28)
	var stack := VBoxContainer.new()
	stack.name = "MenuContent"
	stack.custom_minimum_size.x = minf(960, maxf(480, app.size.x - 70))
	stack.add_theme_constant_override("separation", 7)
	margins.add_child(stack)
	if app.store.best > 0:
		UIFactory.center_label(stack, "♛  RECORDE: %d" % app.store.best, 12, AMBER, true)
	UIFactory.center_label(stack, "//  D E F E S A  I N C R E M E N T A L  //", 12, CYAN, true)
	var title := UIFactory.center_label(stack, "NEON\nVOID", 82, Color.WHITE, true)
	title.add_theme_constant_override("line_spacing", -14)
	var title_material := ShaderMaterial.new()
	title_material.shader = preload("res://shaders/title.gdshader")
	title.material = title_material
	UIFactory.center_label(stack, "Clique. Evolua. Sobreviva.", 24, Color("d4cee0"))
	UIFactory.spacer(stack, 10)
	var start := UIFactory.button("▶  JOGAR AGORA", app.start_game, PINK, true)
	start.name = "Start"
	start.custom_minimum_size = Vector2(328, 58)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 18)
	stack.add_child(start)
	var modules_button := UIFactory.button("⌖  MÓDULOS DA TORRE", app.show_modules, PINK)
	modules_button.name = "Modules"
	modules_button.custom_minimum_size = Vector2(328, 48)
	modules_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(modules_button)
	UIFactory.center_label(stack, "Slots liberados: %d/7" % app.store.unlocked_tower_slots, 16, CYAN)
	var loadout := UIFactory.center_label(stack, tower_loadout_text(app.store), 17, MUTED)
	loadout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var research_button := UIFactory.button("⌬  LABORATÓRIO DE PESQUISAS", app.show_research, CYAN)
	research_button.name = "Research"
	research_button.custom_minimum_size = Vector2(328, 48)
	research_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(research_button)
	var codex_button := UIFactory.button("◈  CODEX DOS INIMIGOS", app.show_codex, AMBER)
	codex_button.name = "Codex"
	codex_button.custom_minimum_size = Vector2(328, 44)
	codex_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(codex_button)
	UIFactory.center_label(stack, pieces_text(app.store.pieces), 14, AMBER, true)
	UIFactory.center_label(stack, "ou pressione ENTER", 14, MUTED)
	UIFactory.spacer(stack, 5)
	UIFactory.center_label(stack, "✧  Dica: Combos aumentam dano e ouro — não erre!", 18, Color("d9cdb8"))
	UIFactory.spacer(stack, 12)
	var cards := BoxContainer.new()
	cards.name = "Cards"
	cards.vertical = app.size.x < 700
	cards.add_theme_constant_override("separation", 12)
	stack.add_child(cards)
	var headings := ["1 • DESTRUA", "2 • EVOLUA", "3 • SOBREVIVA"]
	var descriptions := ["Toque/clique nos inimigos antes que atinjam sua base. Combos dão mais dano e ouro.", "Gaste ouro em Clique, Torreta Auto, Crítico e Escudo. Custo sobe, poder explode.", "Segure as waves e o BOSS. Pulso Nova (ESPAÇO) limpa a tela em emergência."]
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
	controls.add_child(UIFactory.label("CONTROLES", 12, CYAN, true))
	controls.add_child(UIFactory.label("Mouse / Touch     Toque nos inimigos para atirar\n1–4   Upgrades        ESPAÇO   Nova\nP / ESC   Pausa       R   Reiniciar", 18, Color("bfb7cf")))
	build_ranking(lower, app.store.scores, true)
	UIFactory.spacer(stack, 8)
	var mute := UIFactory.button("Som: OFF" if app.store.muted else "Som: ON", app.toggle_mute)
	mute.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(mute)
	app.mute_buttons.append(mute)
	UIFactory.center_label(stack, "v1.0 • Godot • recorde local", 13, Color("726781"))

static func build_ranking(parent: Node, scores: Array, compact := false) -> Control:
	var content := UIFactory.panel(parent, AMBER)
	content.add_child(UIFactory.label("♛  RANKING LOCAL                         TOP 10", 11, AMBER, true))
	if scores.is_empty():
		content.add_child(UIFactory.label("Nenhum recorde ainda.\nSeja o primeiro a dominar o Void!", 18, MUTED))
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
		summary.append("%d · %s" % [index + 1, MODULE_INFO[module_id][0]])
	return "   |   ".join(summary)
