class_name ShopView
extends RefCounted
## Gerencia a construção dos cards de evolução por aba (Ataque, Torres e Defesa)
## e a atualização contínua de custos, níveis e bloqueios no HUD da partida.

const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const MODULE_INFO := GameData.MODULE_INFO
const UPG_ATTACK_IDS := GameData.UPG_ATTACK_IDS
const UPG_TOWER_IDS := GameData.UPG_TOWER_IDS
const UPG_DEFENSE_IDS := GameData.UPG_DEFENSE_IDS
const IN_GAME_UPG_INFO := GameData.UPGRADE_INFO
const BODY = preload("res://assets/fonts/Rajdhani.ttf")

static func style_tabs(shop_tabs_row: HBoxContainer, active_tab: String) -> void:
	if not is_instance_valid(shop_tabs_row):
		return
	var tab_colors := {"attack": PINK, "towers": LIME, "defense": CYAN}
	var tab_map := {"TabAttack": "attack", "TabTowers": "towers", "TabDefense": "defense"}
	for child in shop_tabs_row.get_children():
		if child is Button and tab_map.has(child.name):
			var tid: String = tab_map[child.name]
			var col: Color = tab_colors[tid]
			var active := (tid == active_tab)
			child.add_theme_stylebox_override("normal", UIFactory.box(col, Color("3b1778") if active else Color("140b29"), 10, 24, 4, 8, 8))
			child.add_theme_color_override("font_color", Color.WHITE if active else col)
			child.queue_redraw()

static func rebuild_cards(app: Control) -> void:
	if not is_instance_valid(app.shop_grid):
		return
	for child in app.shop_grid.get_children():
		app.shop_grid.remove_child(child)
		child.queue_free()
	app.upgrades.clear()
	app.shop_items.clear()
	var narrow: bool = app.size.x < 1000
	var card_index := 0
	if app.shop_tab == "towers":
		for slot_idx in app.state.tower_loadout.size():
			card_index += 1
			var mod_id: String = app.state.tower_loadout[slot_idx]
			var info: Array = MODULE_INFO.get(mod_id, MODULE_INFO["plasma"])
			var col: Color = info[2]
			var buy := UIFactory.card_button("", func(): app.buy_in_game_tower_slot(slot_idx), col, "right", 54)
			buy.name = "TowerSlot%d" % (slot_idx + 1)
			buy.custom_minimum_size.y = 78 if narrow else 92
			buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buy.add_theme_font_override("font", BODY)
			buy.add_theme_font_size_override("font_size", 14)
			buy.add_theme_color_override("font_color", col)
			buy.draw.connect(func(): NeonIcons.draw_tower(buy, mod_id, 12.0, Vector2(buy.size.x - 27.0, buy.size.y * 0.5)))
			app.shop_grid.add_child(buy)
			app.upgrades.append(buy)
			app.shop_items.append({"kind": "tower_slot", "slot_index": slot_idx, "button": buy})
	var upg_list: Array = UPG_ATTACK_IDS if app.shop_tab == "attack" else (UPG_TOWER_IDS if app.shop_tab == "towers" else UPG_DEFENSE_IDS)
	for upg_id in upg_list:
		card_index += 1
		var uinfo: Array = IN_GAME_UPG_INFO[upg_id]
		var ucol: Color = uinfo[2]
		var buy := UIFactory.card_button("", func(): app.buy_in_game_upgrade(upg_id), ucol, "right", 54)
		buy.name = "Upgrade%d" % card_index
		buy.custom_minimum_size.y = 78 if narrow else 92
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy.add_theme_font_override("font", BODY)
		buy.add_theme_font_size_override("font_size", 14)
		buy.add_theme_color_override("font_color", ucol)
		buy.draw.connect(func():
			var is_locked_shield: bool = (upg_id in ["shield_cap", "shield_regen", "shield_pulse"] and not app.state.shield_unlocked())
			NeonIcons.draw_ui(buy, "lock" if is_locked_shield else str(upg_id), 12.0, Vector2(buy.size.x - 27.0, buy.size.y * 0.5), Color("756d83") if is_locked_shield else ucol)
		)
		app.shop_grid.add_child(buy)
		app.upgrades.append(buy)
		app.shop_items.append({"kind": "upgrade", "id": upg_id, "button": buy})

static func refresh_items(app: Control) -> void:
	for item in app.shop_items:
		var btn: Button = item["button"]
		if not is_instance_valid(btn):
			continue
		if item["kind"] == "tower_slot":
			var slot_idx: int = int(item["slot_index"])
			if slot_idx < 0 or slot_idx >= app.state.tower_loadout.size():
				continue
			var mod_id: String = app.state.tower_loadout[slot_idx]
			var info: Array = MODULE_INFO.get(mod_id, MODULE_INFO["plasma"])
			var lvl: int = app.state.tower_slot_level(slot_idx)
			var c: int = app.state.tower_slot_cost(slot_idx)
			var mod_name: String = info[0].replace("Torre ", "").to_upper()
			if mod_name.begins_with("DE "):
				mod_name = mod_name.substr(3)
			var status_line: String = "COMPRAR  •  Ativar" if lvl == 0 else "%s dano/s  •  Evoluir" % NumberFormat.format_int(app.state.slot_dps(slot_idx))
			btn.text = "SLOT %d: %s  •  %s\n%s\n%s   ◈ %s" % [
				slot_idx + 1,
				mod_name,
				"INATIVA" if lvl == 0 else ("Nv.%d" % lvl),
				status_line,
				"▰".repeat(mini(lvl, 10)) + "▱".repeat(maxi(0, 10 - lvl)),
				NumberFormat.format(float(c), 1)
			]
			btn.disabled = app.state.gold < c
			btn.queue_redraw()
		else:
			var upg_id: String = item["id"]
			var uinfo: Array = IN_GAME_UPG_INFO[upg_id]
			var lvl: int = app.state.upg_level(upg_id)
			var max_lvl: int = int(app.state.UPGRADE_DEFS[upg_id].get("max_level", 999))
			var c: int = app.state.upg_cost(upg_id)
			var detail: String = uinfo[1]
			if upg_id == "click_dmg":
				detail = "%s dano/clique (+25%% a cada 5 nv)" % NumberFormat.format_int(app.state.click_damage())
			if upg_id in ["shield_cap", "shield_regen", "shield_pulse"] and not app.state.shield_unlocked():
				btn.text = "%s  •  BLOQUEADO\nRequer pesquisa no Laboratório\nGerador de Escudo Quântico" % uinfo[0]
				btn.disabled = true
			elif lvl >= max_lvl:
				btn.text = "%s  •  Nv.%d (MÁX)\n%s\n✓ NÍVEL MÁXIMO ATINGIDO" % [uinfo[0], lvl, detail]
				btn.disabled = true
			else:
				var lvl_text := ("Nv.%d/%d" % [lvl, max_lvl]) if max_lvl < 900 else ("Nv.%d" % lvl)
				btn.text = "%s  •  %s\n%s\n%s   ◈ %s" % [
					uinfo[0],
					lvl_text,
					detail,
					"▰".repeat(mini(lvl, 10)) + "▱".repeat(maxi(0, 10 - lvl)),
					NumberFormat.format(float(c), 1)
				]
				btn.disabled = not app.state.can_buy_upgrade(upg_id)
			btn.queue_redraw()
