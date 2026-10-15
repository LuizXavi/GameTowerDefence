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
const RichTooltipScript = preload("res://ui/components/rich_tooltip.gd")
const UpgradeDeltaScript = preload("res://ui/components/upgrade_delta.gd")

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
			RichTooltipScript.attach(buy, func() -> Dictionary:
				var mod: String = app.state.tower_loadout[slot_idx]
				var minfo: Array = I18n.get_module_info(mod)
				var cur_l: int = app.state.tower_slot_level(slot_idx)
				var c_gold: int = app.state.tower_slot_cost(slot_idx)
				var cur_d: int = app.state.slot_dps(slot_idx)
				var res_r: int = app.state.research[1] if app.state.research.size() > 1 else 0
				var syn_l: int = app.state.upg_level("tower_synergy")
				var nxt_d: int = TowerCombat.calculate_slot_dps(cur_l + 1, app.state.wave, res_r, syn_l)
				var delta_str: String = UpgradeDeltaScript.format_delta(float(cur_d), float(nxt_d), "DPS", c_gold)
				var ratio_str: String = ""
				var d_gain: float = float(nxt_d - cur_d)
				if c_gold > 0 and d_gain > 0.0:
					ratio_str = "Custo-Benefício: %s DPS por ◈" % NumberFormat.format(d_gain / float(c_gold), 2)
				var payback_str: String = "Payback estimado: ~%d waves" % [maxi(1, roundi(float(c_gold) / maxf(1.0, float(app.state.gold_per_wave if "gold_per_wave" in app.state else 120))))]
				return {
					"title": minfo[0],
					"category": "Módulo de Torre",
					"description": minfo[1],
					"color": col,
					"icon_kind": "tower",
					"icon_id": mod,
					"current_dps": cur_d,
					"next_dps": nxt_d,
					"delta": delta_str,
					"ratio": ratio_str,
					"payback": payback_str,
					"extra": "Nv. Atual: %d • Custo: %s ◈" % [cur_l, NumberFormat.format(float(c_gold), 1)]
				}
			)
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
		RichTooltipScript.attach(buy, func() -> Dictionary:
			var loc_uinfo: Array = I18n.get_upgrade_info(upg_id)
			var cur_lvl: int = app.state.upg_level(upg_id)
			var c_gold: int = app.state.upg_cost(upg_id)
			var cat_name: String = "Ataque" if upg_id in UPG_ATTACK_IDS else ("Torre" if upg_id in UPG_TOWER_IDS else "Defesa")
			var delta_str: String = ""
			if upg_id == "click_dmg":
				var cur_val: float = float(app.state.click_damage())
				var next_val: float = cur_val + (3.0 * (1.25 if (cur_lvl + 1) % 5 == 0 else 1.0))
				delta_str = UpgradeDeltaScript.format_delta(cur_val, next_val, "Dano Clique", c_gold)
			elif upg_id == "tower_haste":
				delta_str = "+12.0% Cadência • Custo: %s ◈" % NumberFormat.format(float(c_gold), 1)
			elif upg_id == "tower_range":
				delta_str = "+8.0% Alcance • Custo: %s ◈" % NumberFormat.format(float(c_gold), 1)
			return {
				"title": loc_uinfo[0],
				"category": cat_name,
				"description": loc_uinfo[1],
				"color": ucol,
				"icon_kind": "ui",
				"icon_id": upg_id,
				"delta": delta_str,
				"extra": "Nv. %d • Próximo custo: %s ◈" % [cur_lvl, NumberFormat.format(float(c_gold), 1)]
			}
		)

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
			var info: Array = I18n.get_module_info(mod_id)
			var lvl: int = app.state.tower_slot_level(slot_idx)
			var c: int = app.state.tower_slot_cost(slot_idx)
			var mod_name: String = info[0].to_upper()
			if mod_name.begins_with("TORRE DE "):
				mod_name = mod_name.substr(9)
			elif mod_name.begins_with("TORRE "):
				mod_name = mod_name.substr(6)
			elif mod_name.ends_with(" TOWER"):
				mod_name = mod_name.substr(0, mod_name.length() - 6)

			var status_line: String = I18n.t("hud.buy_activate", "COMPRAR  •  Ativar") if lvl == 0 else (I18n.t("hud.dps_upgrade", "%s dano/s  •  Evoluir") % NumberFormat.format_int(app.state.slot_dps(slot_idx)))
			var slot_header_text: String = (I18n.t("hud.slot_prefix", "SLOT %d") % (slot_idx + 1)) + (": %s  •  %s" % [mod_name, I18n.t("hud.inactive", "INATIVA") if lvl == 0 else (I18n.t("hud.level_prefix", "Nv.%d") % lvl)])
			btn.text = "%s\n%s\n%s   ◈ %s" % [
				slot_header_text,
				status_line,
				"▰".repeat(mini(lvl, 10)) + "▱".repeat(maxi(0, 10 - lvl)),
				NumberFormat.format(float(c), 1)
			]
			btn.disabled = app.state.gold < c
			btn.queue_redraw()
		else:
			var upg_id: String = item["id"]
			var uinfo: Array = I18n.get_upgrade_info(upg_id)
			var lvl: int = app.state.upg_level(upg_id)
			var max_lvl: int = int(app.state.UPGRADE_DEFS[upg_id].get("max_level", 999))
			var c: int = app.state.upg_cost(upg_id)
			var detail: String = uinfo[1]
			if upg_id == "click_dmg":
				var click_fmt: String = I18n.t("hud.click_damage_desc", "%s dano/clique (+25%% a cada 5 nv)")
				detail = click_fmt % NumberFormat.format_int(app.state.click_damage())
			if upg_id in ["shield_cap", "shield_regen", "shield_pulse"] and not app.state.shield_unlocked():
				var locked_shield_txt: String = I18n.t("hud.shield_locked_tip", "%s  •  BLOQUEADO\nRequer pesquisa no Laboratório\nGerador de Escudo Quântico") % uinfo[0]
				btn.text = locked_shield_txt
				btn.disabled = true
			elif lvl >= max_lvl:
				var max_level_txt: String = I18n.t("hud.max_level_reached", "✓ NÍVEL MÁXIMO ATINGIDO")
				var max_badge: String = I18n.t("hud.max_badge", "MÁX")
				btn.text = "%s  •  %s.%d (%s)\n%s\n%s" % [uinfo[0], I18n.t("hud.level_short", "Nv"), lvl, max_badge, detail, max_level_txt]
				btn.disabled = true
			else:
				var lvl_short: String = I18n.t("hud.level_short", "Nv")
				var lvl_text := ("%s.%d/%d" % [lvl_short, lvl, max_lvl]) if max_lvl < 900 else ("%s.%d" % [lvl_short, lvl])
				btn.text = "%s  •  %s\n%s\n%s   ◈ %s" % [
					uinfo[0],
					lvl_text,
					detail,
					"▰".repeat(mini(lvl, 10)) + "▱".repeat(maxi(0, 10 - lvl)),
					NumberFormat.format(float(c), 1)
				]
				btn.disabled = not app.state.can_buy_upgrade(upg_id)
			btn.queue_redraw()
