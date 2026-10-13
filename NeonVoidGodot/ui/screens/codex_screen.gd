class_name CodexScreen
extends RefCounted
## Constrói a tela do Codex dos Inimigos com ícones procedurais e estatísticas de descoberta.

const CYAN := GameData.CYAN
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED
const CODEX_ORDER := GameData.CODEX_ORDER
const ENEMY_INFO := GameData.ENEMY_INFO

static func build(app: Control, content: VBoxContainer) -> void:
	content.custom_minimum_size.x = minf(760, app.size.x - 48)
	UIFactory.center_label(content, "◈  CODEX DOS INIMIGOS", 23, AMBER, true)
	UIFactory.center_label(content, "Descobertas registradas durante suas expedições ao Void.", 18, Color("cfc7dd"))
	for enemy_id in CODEX_ORDER:
		var known: bool = app.store.enemy_stats.has(enemy_id) and app.store.enemy_stats[enemy_id].discovered
		if not known:
			var unknown := UIFactory.button("◇  ???\nContinue avançando pelas waves para descobrir.", func(): pass, Color("42364f"))
			unknown.disabled = true
			unknown.custom_minimum_size.y = 62
			content.add_child(unknown)
			continue
		var info: Array = ENEMY_INFO[enemy_id]
		var stats: Dictionary = app.store.enemy_stats[enemy_id]
		var is_special_card: bool = enemy_id.begins_with("elite") or enemy_id.begins_with("boss")
		var border_color: Color = AMBER if is_special_card else CYAN

		var card_frame := PanelContainer.new()
		card_frame.add_theme_stylebox_override("panel", UIFactory.box(border_color, Color("140b29"), 12))
		card_frame.custom_minimum_size.y = 96
		content.add_child(card_frame)

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

		var title_lbl := UIFactory.label(info[0], 18, border_color, true)
		text_col.add_child(title_lbl)

		var line1 := "Abates: %d   •   Peças: %d   •   Maior wave: %d" % [stats.kills, stats.pieces, stats.max_wave]
		var lbl1 := UIFactory.label(line1, 15, Color.WHITE)
		text_col.add_child(lbl1)

		var line2 := "Drop: %s   •   Fraqueza: %s" % [info[1], info[2]]
		var lbl2 := UIFactory.label(line2, 14, MUTED)
		text_col.add_child(lbl2)

		var line3 := "%s   •   Pesquisa: %s" % [info[3], info[4]]
		var lbl3 := UIFactory.label(line3, 14, MUTED)
		text_col.add_child(lbl3)

	var close := UIFactory.button("VOLTAR AO MENU", app.close_codex, AMBER)
	close.name = "CloseCodex"
	content.add_child(close)
	close.grab_focus()
