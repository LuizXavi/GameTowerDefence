class_name UpgradeDelta
extends HBoxContainer
## Componente reutilizável para comparar valores atuais e futuros de upgrades (Dano, Cadência, Alcance, etc).
## Exibe percentual formatado e razão custo/benefício (delta por ouro).

const LIME := GameData.LIME
const PINK := GameData.PINK
const CYAN := GameData.CYAN
const MUTED := GameData.MUTED
const AMBER := GameData.AMBER
const DISPLAY = preload("res://assets/fonts/DisplayBold.tres")
const BODY = preload("res://assets/fonts/Rajdhani.ttf")

var label_delta: Label
var label_ratio: Label

func _init() -> void:
	name = "UpgradeDelta"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 8)

	label_delta = Label.new()
	label_delta.name = "DeltaLabel"
	label_delta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_delta.add_theme_font_override("font", BODY)
	label_delta.add_theme_font_size_override("font_size", 14)
	add_child(label_delta)

	label_ratio = Label.new()
	label_ratio.name = "RatioLabel"
	label_ratio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_ratio.add_theme_font_override("font", BODY)
	label_ratio.add_theme_font_size_override("font_size", 12)
	label_ratio.add_theme_color_override("font_color", AMBER)
	add_child(label_ratio)

func update_values(current_val: float, next_val: float, stat_name: String, cost: int = 0, is_higher_better: bool = true) -> void:
	var diff: float = next_val - current_val
	if is_zero_approx(diff):
		label_delta.text = "±0% %s" % stat_name
		label_delta.add_theme_color_override("font_color", CYAN)
		label_ratio.text = ""
		return

	var pct: float = (diff / maxf(0.0001, absf(current_val))) * 100.0 if current_val > 0.0 else 100.0
	var sign_str: String = "+" if diff > 0 else ""
	label_delta.text = "%s%.1f%% %s" % [sign_str, pct, stat_name]

	var is_positive_gain: bool = (diff > 0.0 and is_higher_better) or (diff < 0.0 and not is_higher_better)
	var col: Color = LIME if is_positive_gain else PINK
	label_delta.add_theme_color_override("font_color", col)

	if cost > 0 and diff > 0:
		var ratio: float = diff / float(cost)
		if ratio >= 1.0:
			label_ratio.text = "(%s/◈)" % NumberFormat.format(ratio, 1)
		elif ratio >= 0.01:
			label_ratio.text = "(%.2f/◈)" % ratio
		else:
			label_ratio.text = "(<0.01/◈)"
	else:
		label_ratio.text = ""

static func format_delta(current_val: float, next_val: float, stat_name: String, cost: int = 0) -> String:
	var diff: float = next_val - current_val
	if is_zero_approx(diff):
		return "±0% " + stat_name
	var pct: float = (diff / maxf(0.0001, absf(current_val))) * 100.0 if current_val > 0.0 else 100.0
	var sign_str: String = "+" if diff > 0 else ""
	var result: String = "%s%.1f%% %s" % [sign_str, pct, stat_name]
	if cost > 0 and diff > 0:
		var ratio: float = diff / float(cost)
		result += " • %s/◈" % NumberFormat.format(ratio, 2)
	return result
