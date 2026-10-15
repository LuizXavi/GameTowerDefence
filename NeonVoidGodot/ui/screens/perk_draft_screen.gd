class_name PerkDraftScreen
extends RefCounted
## Constrói a tela modal de Draft Roguelite de 3 cartas/perks após ondas de chefe.

const CYAN := GameData.CYAN
const PINK := GameData.PINK
const LIME := GameData.LIME
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED

static func build(app: Control, choices: Array[Dictionary]) -> void:
	var content: VBoxContainer = app.modal()
	content.name = "PerkDraftContent"
	content.custom_minimum_size.x = minf(780, app.size.x - 48)
	content.add_theme_constant_override("separation", 16)

	# Cabeçalho
	UIFactory.center_label(content, "✦  " + I18n.t("draft.title", "ESCOLHA UM PROTOCOLO DO VOID") + "  ✦", 22, AMBER, true)
	UIFactory.center_label(content, I18n.t("draft.subtitle", "Recompensa de Chefe Derrotado • Efeito dura até o fim da partida"), 14, Color("cfc7dd"))

	# Container dos 3 cards (responsivo: HBoxContainer se tela larga, VBoxContainer se tela estreita)
	var is_compact: bool = app.size.x < 740
	var cards_container: BoxContainer
	if is_compact:
		cards_container = VBoxContainer.new()
	else:
		cards_container = HBoxContainer.new()
	cards_container.name = "CardsRow"
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 16)
	cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(cards_container)

	for i in choices.size():
		var choice: Dictionary = choices[i]
		var perk_id: String = choice.get("id", "")
		var perk_color: Color = choice.get("color", CYAN)
		var rarity_str: String = str(choice.get("rarity", "common")).to_lower()
		var rarity_tag: String = I18n.t("draft.rarity_" + rarity_str, rarity_str.to_upper())
		var cur_lvl: int = int(choice.get("current_level", 0))
		var max_s: int = int(choice.get("max_stacks", 1))
		var icon_id: String = str(choice.get("icon", perk_id))

		# Painel do Card
		var card_frame := PanelContainer.new()
		card_frame.name = "PerkCard_%d" % (i + 1)
		card_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not is_compact:
			card_frame.custom_minimum_size = Vector2(220, 310)
		else:
			card_frame.custom_minimum_size.y = 100
		card_frame.add_theme_stylebox_override("panel", UIFactory.box(perk_color, Color("140b29"), 12))
		cards_container.add_child(card_frame)

		var card_margin := UIFactory.margin(card_frame, 14)
		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 10)
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_margin.add_child(card_vbox)

		# Tag de Raridade
		var badge := UIFactory.badge(rarity_tag, perk_color)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_vbox.add_child(badge)

		# Ícone vetorial procedural
		var icon_ctrl := Control.new()
		icon_ctrl.custom_minimum_size = Vector2(60, 60)
		icon_ctrl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_ctrl.draw.connect(func():
			NeonIcons.draw_ui(icon_ctrl, icon_id, 24.0, Vector2(-1, -1), perk_color)
		)
		card_vbox.add_child(icon_ctrl)

		# Nome do Perk
		var perk_name: String = I18n.get_perk_name(perk_id)
		var title_lbl := UIFactory.center_label(card_vbox, perk_name, 16, perk_color, true)
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		# Stacks / Nível
		if max_s > 1:
			var stacks_fmt: String = I18n.t("draft.stacks", "Nível %d / %d")
			UIFactory.center_label(card_vbox, stacks_fmt % [cur_lvl + 1, max_s], 12, MUTED)

		# Descrição
		var perk_desc: String = I18n.get_perk_desc(perk_id)
		var desc_lbl := UIFactory.center_label(card_vbox, perk_desc, 13, Color("d8d0e5"))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL

		# Botão Selecionar
		var btn_text: String = I18n.t("draft.btn_select", "INSTALAR [%d]") % (i + 1)
		var select_btn := UIFactory.button(btn_text, func():
			app.choose_perk(perk_id)
		, perk_color, true)
		select_btn.name = "SelectPerk_%d" % (i + 1)
		card_vbox.add_child(select_btn)

	app.contain_modal_focus()
	app.focus_first_modal_action()
