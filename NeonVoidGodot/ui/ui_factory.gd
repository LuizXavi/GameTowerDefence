class_name UIFactory
extends RefCounted
## Fábrica de widgets com o estilo visual neon do jogo (botões, painéis, rótulos, barras).

const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED
const MODULE_INFO := GameData.MODULE_INFO
const DISPLAY = preload("res://assets/fonts/DisplayBold.tres")
const BODY = preload("res://assets/fonts/Rajdhani.ttf")

static func box(color: Color = Color("8b5cf6"), fill: Color = Color("110727"), radius: int = 16, margin_left: int = 16, margin_right: int = 16, margin_top: int = 12, margin_bottom: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(color, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_left
	style.content_margin_right = margin_right
	style.content_margin_top = margin_top
	style.content_margin_bottom = margin_bottom
	return style

static func label(words: String, font_size := 18, color := Color.WHITE, display := false) -> Label:
	var node := Label.new()
	node.text = words
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	if display:
		node.add_theme_font_override("font", DISPLAY)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func button(words: String, callback: Callable, color := CYAN, primary := false) -> Button:
	var node := Button.new()
	node.text = words
	node.custom_minimum_size.y = 44
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", DISPLAY)
	node.add_theme_font_size_override("font_size", 12)
	node.add_theme_stylebox_override("normal", box(color, Color("5122a1") if primary else Color("140b29"), 12))
	if primary:
		var gradient_style := StyleBoxTexture.new()
		gradient_style.texture = preload("res://assets/button_gradient.svg")
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			gradient_style.set_texture_margin(side, 16)
			gradient_style.set_content_margin(side, 14)
		node.add_theme_stylebox_override("normal", gradient_style)
	var hover := box(color, Color("281448"), 12)
	hover.border_color = color
	hover.shadow_color = Color(color, 0.2)
	hover.shadow_size = 12
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("pressed", box(color, Color("38204d"), 12))
	node.add_theme_stylebox_override("focus", box(color, Color(0, 0, 0, 0), 12))
	node.add_theme_stylebox_override("disabled", box(Color("42364f"), Color("100a20"), 12))
	node.add_theme_color_override("font_disabled_color", Color("756d83"))
	node.pressed.connect(callback)
	return node

static func card_button(words: String, callback: Callable, color := CYAN, icon_side: String = "right", icon_space: int = 56) -> Button:
	var node := Button.new()
	node.text = words
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", BODY)
	node.add_theme_font_size_override("font_size", 14)
	var left_m: int = icon_space if icon_side == "left" else 14
	var right_m: int = icon_space if icon_side == "right" else 14
	node.add_theme_stylebox_override("normal", box(color, Color("140b29"), 12, left_m, right_m, 10, 10))
	var hover := box(color, Color("281448"), 12, left_m, right_m, 10, 10)
	hover.border_color = color
	hover.shadow_color = Color(color, 0.2)
	hover.shadow_size = 10
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("pressed", box(color, Color("38204d"), 12, left_m, right_m, 10, 10))
	node.add_theme_stylebox_override("focus", box(color, Color(0, 0, 0, 0), 12, left_m, right_m, 10, 10))
	node.add_theme_stylebox_override("disabled", box(Color("42364f"), Color("100a20"), 12, left_m, right_m, 10, 10))
	node.add_theme_color_override("font_disabled_color", Color("756d83"))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.clip_text = true
	node.pressed.connect(callback)
	return node

static func tab_button(words: String, callback: Callable, color := CYAN, is_active := false, icon_space: int = 30) -> Button:
	var node := Button.new()
	node.text = words
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", DISPLAY)
	node.add_theme_font_size_override("font_size", 11)
	var active_fill := Color("3b1778")
	var normal_fill := Color("140b29")
	node.add_theme_stylebox_override("normal", box(color, active_fill if is_active else normal_fill, 10, icon_space, 8, 8, 8))
	var hover := box(color, Color("281448"), 10, icon_space, 8, 8, 8)
	hover.border_color = color
	hover.shadow_color = Color(color, 0.2)
	hover.shadow_size = 8
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("pressed", box(color, Color("38204d"), 10, icon_space, 8, 8, 8))
	node.add_theme_stylebox_override("focus", box(color, Color(0, 0, 0, 0), 10, icon_space, 8, 8, 8))
	node.add_theme_stylebox_override("disabled", box(Color("42364f"), Color("100a20"), 10, icon_space, 8, 8, 8))
	node.add_theme_color_override("font_color", Color.WHITE if is_active else color)
	node.clip_text = true
	node.pressed.connect(callback)
	return node

static func panel(parent: Node, color := Color("8b5cf6")) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", box(color))
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(frame)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	frame.add_child(content)
	return content

static func margin(parent: Node, amount: int) -> MarginContainer:
	var node := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		node.add_theme_constant_override("margin_" + side, amount)
	parent.add_child(node)
	return node

static func center_label(parent: Node, words: String, font_size: int, color: Color, display := false) -> Label:
	var node := label(words, font_size, color, display)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(node)
	return node

static func spacer(parent: Node, height: float) -> void:
	var node := Control.new()
	node.custom_minimum_size.y = height
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)

static func make_bar(color: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.custom_minimum_size = Vector2(100, 8)
	node.add_theme_stylebox_override("background", box(Color.TRANSPARENT, Color("282136"), 8))
	var fill := box(Color.TRANSPARENT, color, 8)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	node.add_theme_stylebox_override("fill", fill)
	return node

static func pieces_bar(parent: Node, values: Array, font_size: int = 15) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var colors := GameData.PIECE_COLORS
	for k in 4:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 5)
		var icon_ctrl := Control.new()
		icon_ctrl.custom_minimum_size = Vector2(16, 16)
		icon_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_ctrl.draw.connect(func():
			NeonIcons.draw_piece_icon(icon_ctrl, k, 13.0, Vector2(8, 8))
		)
		item.add_child(icon_ctrl)
		var val: int = int(values[k]) if k < values.size() else 0
		var lbl := label(str(val), font_size, colors[k], true)
		item.add_child(lbl)
		row.add_child(item)
	parent.add_child(row)
	return row

static func badge(words: String, color: Color = CYAN) -> PanelContainer:
	var container := PanelContainer.new()
	var style := box(color, Color("140b29"), 6, 8, 8, 3, 3)
	container.add_theme_stylebox_override("panel", style)
	var lbl := label(words, 11, color, true)
	container.add_child(lbl)
	return container


