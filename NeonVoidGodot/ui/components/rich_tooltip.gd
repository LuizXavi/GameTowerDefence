class_name RichTooltip
extends PanelContainer
## Componente de Tooltip Rico Cyberpunk Neon para torres, upgrades, pesquisas e conquistas.
## Renderiza ícones procedurais (NeonIcons), DPS atual e próximo, deltas percentuais, custo/benefício e payback.

const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED
const DISPLAY = preload("res://assets/fonts/DisplayBold.tres")
const BODY = preload("res://assets/fonts/Rajdhani.ttf")

static var _instance: Control = null

var _header_box: HBoxContainer
var _icon_ctrl: Control
var _title_lbl: Label
var _category_lbl: Label
var _desc_lbl: Label
var _stats_col: VBoxContainer
var _dps_lbl: Label
var _delta_lbl: Label
var _ratio_lbl: Label
var _payback_lbl: Label
var _extra_lbl: Label

var _current_provider: Callable
var _target_control: Control = null
var _timer: float = 0.0
var _is_hovered: bool = false
var _delay: float = 0.25

func _init() -> void:
	name = "RichTooltip"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 200
	visible = false

	var box_style := UIFactory.box(CYAN, Color("0f0728"), 14, 14, 14, 10, 10)
	box_style.border_color = Color(CYAN, 0.9)
	box_style.shadow_color = Color(CYAN, 0.25)
	box_style.shadow_size = 14
	add_theme_stylebox_override("panel", box_style)
	custom_minimum_size = Vector2(260, 0)

	var main_vbox := VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_theme_constant_override("separation", 6)
	add_child(main_vbox)

	_header_box = HBoxContainer.new()
	_header_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_box.add_theme_constant_override("separation", 10)
	main_vbox.add_child(_header_box)

	_icon_ctrl = Control.new()
	_icon_ctrl.custom_minimum_size = Vector2(36, 36)
	_icon_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_box.add_child(_icon_ctrl)

	var title_col := VBoxContainer.new()
	title_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 1)
	_header_box.add_child(title_col)

	_title_lbl = UIFactory.label("", 16, Color.WHITE, true)
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_col.add_child(_title_lbl)

	_category_lbl = UIFactory.label("", 11, CYAN, true)
	title_col.add_child(_category_lbl)

	_desc_lbl = UIFactory.label("", 14, Color("d4cee0"))
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(_desc_lbl)

	_stats_col = VBoxContainer.new()
	_stats_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_col.add_theme_constant_override("separation", 3)
	main_vbox.add_child(_stats_col)

	_dps_lbl = UIFactory.label("", 14, LIME, true)
	_stats_col.add_child(_dps_lbl)

	_delta_lbl = UIFactory.label("", 13, Color.WHITE)
	_stats_col.add_child(_delta_lbl)

	_ratio_lbl = UIFactory.label("", 13, AMBER)
	_stats_col.add_child(_ratio_lbl)

	_payback_lbl = UIFactory.label("", 13, Color("7feaff"))
	_stats_col.add_child(_payback_lbl)

	_extra_lbl = UIFactory.label("", 12, MUTED)
	_extra_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_col.add_child(_extra_lbl)

func _process(dt: float) -> void:
	if not _is_hovered or not is_instance_valid(_target_control) or not _target_control.is_visible_in_tree():
		if visible:
			hide_tooltip()
		return

	if not visible:
		_timer += dt
		if _timer >= _delay:
			_render_content()
			visible = true

	if visible:
		_update_position()

func _update_position() -> void:
	var viewport := get_viewport()
	if not is_instance_valid(viewport):
		return
	var mouse_pos: Vector2 = viewport.get_mouse_position()
	var vp_size: Vector2 = viewport.get_visible_rect().size
	var target_pos := mouse_pos + Vector2(16, 16)

	if target_pos.x + size.x > vp_size.x - 12:
		target_pos.x = mouse_pos.x - size.x - 16
	if target_pos.y + size.y > vp_size.y - 12:
		target_pos.y = mouse_pos.y - size.y - 16

	target_pos.x = clampf(target_pos.x, 8.0, maxf(8.0, vp_size.x - size.x - 8.0))
	target_pos.y = clampf(target_pos.y, 8.0, maxf(8.0, vp_size.y - size.y - 8.0))
	global_position = target_pos

func _render_content() -> void:
	if not _current_provider.is_valid():
		hide_tooltip()
		return
	var data: Dictionary = _current_provider.call()
	if data.is_empty():
		hide_tooltip()
		return

	var theme_color: Color = data.get("color", CYAN)
	var box_style := UIFactory.box(theme_color, Color("0e0624"), 14, 14, 14, 10, 10)
	box_style.border_color = Color(theme_color, 0.9)
	box_style.shadow_color = Color(theme_color, 0.28)
	box_style.shadow_size = 14
	add_theme_stylebox_override("panel", box_style)

	_title_lbl.text = str(data.get("title", ""))
	_title_lbl.add_theme_color_override("font_color", theme_color)

	var cat_text: String = str(data.get("category", ""))
	_category_lbl.visible = not cat_text.is_empty()
	_category_lbl.text = cat_text.to_upper()
	_category_lbl.add_theme_color_override("font_color", Color(theme_color, 0.8))

	var desc_text: String = str(data.get("description", ""))
	_desc_lbl.visible = not desc_text.is_empty()
	_desc_lbl.text = desc_text

	# Ícone
	var icon_kind: String = str(data.get("icon_kind", ""))
	var icon_id: String = str(data.get("icon_id", ""))
	_icon_ctrl.visible = not icon_kind.is_empty()
	if _icon_ctrl.visible:
		if _icon_ctrl.is_connected("draw", _on_icon_draw):
			_icon_ctrl.disconnect("draw", _on_icon_draw)
		_icon_ctrl.set_meta("kind", icon_kind)
		_icon_ctrl.set_meta("id", icon_id)
		_icon_ctrl.set_meta("color", theme_color)
		_icon_ctrl.draw.connect(_on_icon_draw)
		_icon_ctrl.queue_redraw()

	# DPS
	var cur_dps: int = int(data.get("current_dps", 0))
	var next_dps: int = int(data.get("next_dps", 0))
	if cur_dps > 0 or next_dps > 0:
		_dps_lbl.visible = true
		if cur_dps > 0 and next_dps > cur_dps:
			_dps_lbl.text = "DPS: %s  ➜  %s" % [NumberFormat.format_int(cur_dps), NumberFormat.format_int(next_dps)]
		elif next_dps > 0:
			_dps_lbl.text = "DPS: +%s" % NumberFormat.format_int(next_dps)
		else:
			_dps_lbl.text = "DPS: %s" % NumberFormat.format_int(cur_dps)
	else:
		_dps_lbl.visible = false

	# Delta
	var delta_text: String = str(data.get("delta", ""))
	_delta_lbl.visible = not delta_text.is_empty()
	_delta_lbl.text = delta_text

	# Custo / Benefício (Dano por ouro)
	var ratio_text: String = str(data.get("ratio", ""))
	_ratio_lbl.visible = not ratio_text.is_empty()
	_ratio_lbl.text = ratio_text

	# Tempo de retorno estimado (Payback)
	var payback_text: String = str(data.get("payback", ""))
	_payback_lbl.visible = not payback_text.is_empty()
	_payback_lbl.text = payback_text

	# Informações adicionais / requisitos
	var extra_text: String = str(data.get("extra", ""))
	_extra_lbl.visible = not extra_text.is_empty()
	_extra_lbl.text = extra_text

	reset_size()

func _on_icon_draw() -> void:
	var kind: String = str(_icon_ctrl.get_meta("kind", ""))
	var id: String = str(_icon_ctrl.get_meta("id", ""))
	var col: Color = _icon_ctrl.get_meta("color", CYAN)
	var center := _icon_ctrl.size * 0.5
	match kind:
		"tower":
			NeonIcons.draw_tower(_icon_ctrl, id, 10.0, center)
		"enemy":
			NeonIcons.draw_enemy(_icon_ctrl, id)
		"piece":
			NeonIcons.draw_piece_icon(_icon_ctrl, int(id), 12.0, center)
		"ui":
			NeonIcons.draw_ui(_icon_ctrl, id, 10.0, center, col)
		_:
			NeonIcons.draw_ui(_icon_ctrl, "attack", 10.0, center, col)

func show_for(control: Control, provider: Callable, delay: float = 0.25) -> void:
	_target_control = control
	_current_provider = provider
	_delay = delay
	_timer = 0.0
	_is_hovered = true

func hide_tooltip() -> void:
	_is_hovered = false
	_timer = 0.0
	visible = false
	_target_control = null

static func get_or_create(tree: SceneTree) -> Control:
	if is_instance_valid(_instance):
		return _instance
	var root: Window = tree.root
	_instance = (load("res://ui/components/rich_tooltip.gd") as GDScript).new()
	root.add_child(_instance)
	return _instance

static func attach(control: Control, provider: Callable, delay: float = 0.25) -> void:
	if not is_instance_valid(control):
		return
	control.mouse_entered.connect(func():
		var inst := get_or_create(control.get_tree())
		inst.show_for(control, provider, delay)
	)
	control.mouse_exited.connect(func():
		if is_instance_valid(_instance) and _instance._target_control == control:
			_instance.hide_tooltip()
	)
	control.tree_exited.connect(func():
		if is_instance_valid(_instance) and _instance._target_control == control:
			_instance.hide_tooltip()
	)

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		hide_tooltip()
