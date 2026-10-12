class_name NumberFormat
extends RefCounted

const SUFFIXES: Array[String] = [
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"
]

static func format(value: float, decimals: int = 1) -> String:
	if is_nan(value) or is_inf(value):
		return "0"
	var sign_str: String = "-" if value < 0.0 else ""
	var abs_val: float = absf(value)

	if abs_val < 1000.0:
		if abs_val == floorf(abs_val):
			return sign_str + str(int(abs_val))
		return sign_str + ("%.*f" % [decimals, abs_val])

	var tier: int = int(floor(log(abs_val) / log(1000.0)))
	if tier < SUFFIXES.size():
		var scaled: float = abs_val / pow(1000.0, float(tier))
		var fmt: String = "%.*f" % [decimals, scaled]
		# Trim trailing zeros after decimal if clean
		if fmt.ends_with(".0") and decimals == 1:
			fmt = fmt.substr(0, fmt.length() - 2)
		return sign_str + fmt + SUFFIXES[tier]
	else:
		return sign_str + ("%.2e" % abs_val)

static func format_int(value: int) -> String:
	return format(float(value), 1)

static func format_scrap(value: float) -> String:
	return format(value, 1) + " SCRAP"

static func format_alloys(value: int) -> String:
	return str(value) + " HEX"

static func format_cores(value: int) -> String:
	return str(value) + " CORES"
