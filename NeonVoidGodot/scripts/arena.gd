extends Control

var state: VoidState
var particles: Array = []
var rings: Array = []
var floaters: Array = []
var stars: Array = []
var trauma := 0.0
var flash := 0.0
var red := 0.0
var clock := 0.0
var font = preload("res://assets/fonts/DisplayBold.tres")
var background: GradientTexture2D

func _ready() -> void:
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	background = GradientTexture2D.new()
	background.gradient = Gradient.new()
	background.gradient.colors = PackedColorArray([Color("070214"), Color("12062e")])
	background.fill_to = Vector2(0, 1)
	for i in 100:
		stars.append(Vector3(randf(), randf(), randf_range(0.5, 1.8)))
	gui_input.connect(_input_arena)

func _input_arena(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		state.tap(event.position)
		accept_event()

func fx(kind: String, point: Vector2, color: Color, words: String) -> void:
	if kind != "text":
		rings.append({"p": point, "color": color, "life": 0.4, "max": maxf(size.x, size.y) * 0.75 if kind == "nova" else (90 if kind == "burst" else 44)})
	if kind in ["burst", "hit", "leak", "nova"]:
		for i in (36 if kind in ["burst", "nova"] else 8):
			particles.append({"p": point, "v": Vector2.from_angle(randf() * TAU) * randf_range(60, 320), "life": randf_range(0.3, 0.8), "color": color, "s": randf_range(1.5, 4.5)})
		while particles.size() > 380:
			particles.pop_front()
	if not words.is_empty():
		floaters.append({"p": point, "text": words, "color": color, "life": 0.9, "size": 28 if kind == "nova" else 15})
		while floaters.size() > 48:
			floaters.pop_front()
	if kind == "nova":
		trauma = 0.85
		flash = 1
	if kind == "leak":
		trauma = 0.45
		red = 1

func clear_fx() -> void:
	particles.clear()
	rings.clear()
	floaters.clear()
	trauma = 0
	flash = 0
	red = 0

func _process(dt: float) -> void:
	if state == null or state.paused:
		return
	clock += dt
	state.bounds = size
	trauma = maxf(0, trauma - dt * 1.6)
	flash = maxf(0, flash - dt * 2.2)
	red = maxf(0, red - dt * 1.8)
	for p in particles.duplicate():
		p.life -= dt
		p.v.y += 320 * dt
		p.v *= 1 - minf(0.9, 2.8 * dt)
		p.p += p.v * dt
		if p.life <= 0:
			particles.erase(p)
	for group in [rings, floaters]:
		for item in group.duplicate():
			item.life -= dt
			if group == floaters:
				item.p.y -= 46 * dt
			if item.life <= 0:
				group.erase(item)
	queue_redraw()

func glow_line(a: Vector2, b: Vector2, color: Color, width := 2.0) -> void:
	for w in [14.0, 8.0, 4.0]:
		draw_line(a, b, Color(color, 0.035), width + w, true)
	draw_line(a, b, color, width, true)

func text_at(words: String, point: Vector2, color: Color, font_size: int) -> void:
	var start := point - Vector2(font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2, 0)
	draw_string_outline(font, start, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, color.a * 0.7))
	draw_string(font, start, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if state == null or background == null:
		return
	draw_texture_rect(background, Rect2(Vector2.ZERO, size), false)
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * trauma * trauma * 22
	draw_set_transform(shake)
	for star in stars:
		draw_circle(Vector2(star.x, star.y) * size, star.z * 0.65, Color(1, 1, 1, 0.25 + 0.5 * (0.5 + 0.5 * sin(clock * star.z + star.x * 70))))
	for x in range(22, int(size.x), 44):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.545, 0.36, 0.96, 0.14))
	for y in range(-44, int(size.y) + 44, 44):
		var yy := y + fmod(state.play_time * 26, 44)
		draw_line(Vector2(0, yy), Vector2(size.x, yy), Color(0.545, 0.36, 0.96, 0.14))
	var base_y := size.y - 30
	var base_color := Color("22e6ff") if state.hp > state.max_hp * 0.35 else Color("ff3355")
	for i in 90:
		draw_line(Vector2(0, base_y - i), Vector2(size.x, base_y - i), Color(base_color, 0.08 * (1 - i / 90.0)))
	glow_line(Vector2(0, base_y), Vector2(size.x, base_y), base_color, 3)
	draw_rect(Rect2(0, base_y, size.x, 30), Color(base_color, 0.08))
	for slot_index in state.tower_slots.size():
		var slot: Dictionary = state.tower_slots[slot_index]
		var turret := state.tower_position(slot_index)
		var module_color := Color("b6ff2e")
		if slot.module_id == "cryo":
			module_color = Color("7feaff")
		elif slot.module_id == "arc":
			module_color = Color("c48aff")
		draw_circle(turret, 13 if state.levels[1] else 9, Color("1a0f3a"))
		draw_arc(turret, 13 if state.levels[1] else 9, 0, TAU, 40, module_color, 1.5, true)
		if state.levels[1] > 0:
			var direction := Vector2.from_angle(slot.turret_angle)
			glow_line(turret, turret + direction * 23, module_color, 6)
			if slot.module_id == "cryo":
				glow_line(turret + direction * 14 - direction.orthogonal() * 8, turret + direction * 14 + direction.orthogonal() * 8, module_color, 2)
			elif slot.module_id == "arc":
				for side in [-1, 1]:
					glow_line(turret + direction.orthogonal() * side * 8, turret + direction * 27 + direction.orthogonal() * side * 6, module_color, 2)
		if slot.beam_time > 0:
			glow_line(turret, slot.beam_target, Color(module_color, slot.beam_time / 0.16), 3)
			draw_line(turret, slot.beam_target, Color.WHITE, 1, true)
			var previous: Vector2 = slot.beam_target
			for point in slot.beam_chain:
				var midpoint: Vector2 = previous.lerp(point, 0.5) + (point - previous).orthogonal().normalized() * 8
				glow_line(previous, midpoint, Color(module_color, slot.beam_time / 0.16), 2)
				glow_line(midpoint, point, Color(module_color, slot.beam_time / 0.16), 2)
				previous = point
	for enemy in state.enemies:
		draw_enemy(enemy)
	for p in particles:
		draw_rect(Rect2(p.p, Vector2.ONE * p.s), Color(p.color, minf(1, p.life * 2)))
	for ring in rings:
		draw_arc(ring.p, 6 + (ring.max - 6) * (1 - pow(ring.life / 0.4, 3)), 0, TAU, 64, Color(ring.color, ring.life / 0.4), 2, true)
	for f in floaters:
		text_at(f.text, f.p, Color(f.color, minf(1, f.life * 1.8)), f.size)
	if state.banner_time > 0 and state.running:
		text_at(state.banner, size * Vector2(0.5, 0.32), Color(0.9, 0.8, 1, minf(1, state.banner_time)), 32)
	if state.combo >= 5:
		text_at("x%d   •   x%.2f dano + ouro" % [state.combo, state.multiplier()], Vector2(215, 35), Color("ffb02e"), 14)
	if state.play_time < 4 and state.kills == 0:
		text_at("TOQUE NOS INIMIGOS!", size * Vector2(0.5, 0.46), Color("a5f3fc"), 19)
	if state.hp <= state.max_hp * 0.32:
		text_at("BASE CRÍTICA — PROTEJA O NÚCLEO", Vector2(size.x / 2, 70), Color("ff7799"), 14)
	draw_set_transform(Vector2.ZERO)
	if flash > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, flash * 0.45))
	if red > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.04, 0.15, red * 0.15))
	for y in range(0, int(size.y), 3):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.018))

func draw_enemy(enemy: Dictionary) -> void:
	var radius: float = enemy.radius * minf(1, 0.4 + enemy.age * 2)
	var color: Color = VoidState.COLORS[enemy.type]
	var visual_alpha := 0.24 if enemy.ghosted else 1.0
	var points := PackedVector2Array()
	var outer := PackedVector2Array()
	for i in enemy.sides:
		var direction := Vector2.from_angle(enemy.rot + i * TAU / enemy.sides)
		points.append(enemy.p + direction * radius)
		outer.append(enemy.p + direction * (radius + 7))
	draw_colored_polygon(outer, Color(color, 0.2 * visual_alpha))
	var body_color: Color = Color.WHITE if enemy.hit > 0 else color.darkened(0.5)
	body_color.a = visual_alpha
	draw_colored_polygon(points, body_color)
	# Radial facets match the original canvas's bright center and darker edges.
	for i in enemy.sides:
		var core_color: Color = Color.WHITE if enemy.hit > 0 else color
		core_color.a = visual_alpha
		var edge_color := color.darkened(0.55)
		edge_color.a = visual_alpha
		draw_polygon(PackedVector2Array([enemy.p, points[i], points[(i + 1) % enemy.sides]]), PackedColorArray([core_color, edge_color, edge_color]))
	points.append(points[0])
	var line_color: Color = Color.WHITE if enemy.hit > 0 else color
	line_color.a = visual_alpha
	draw_polyline(points, line_color, 3 if enemy.type == 3 else 2.5, true)
	draw_circle(enemy.p, maxf(2.5, radius * 0.22), Color(1, 1, 1, 0.9 * visual_alpha))
	if enemy.slow_timer > 0:
		var frost_center: Vector2 = enemy.p + Vector2(radius + 9, 0)
		for i in 3:
			var frost_axis := Vector2.from_angle(i * PI / 3) * 6
			draw_line(frost_center - frost_axis, frost_center + frost_axis, Color(0.5, 0.92, 1, visual_alpha), 2, true)
	if enemy.variant == "armored" or enemy.modifiers.has("armor"):
		draw_arc(enemy.p, radius + 11, 0, TAU, 8, Color(0.8, 0.85, 1, 0.8 * visual_alpha), 3, true)
	if enemy.variant == "regen" or enemy.modifiers.has("regen"):
		draw_arc(enemy.p, radius + 8, -PI / 2, -PI / 2 + TAU * (0.55 + sin(clock * 3) * 0.15), 32, Color(0.71, 1, 0.18, 0.85 * visual_alpha), 2, true)
	if enemy.variant == "splitter":
		draw_circle(enemy.p + Vector2(-radius * 0.38, 0), 3, Color.WHITE)
		draw_circle(enemy.p + Vector2(radius * 0.38, 0), 3, Color.WHITE)
	if enemy.variant == "thief":
		text_at("$", enemy.p + Vector2(0, 5), Color("ffb02e"), 12)
	if enemy.elite:
		draw_arc(enemy.p, radius + 16, clock, clock + TAU * 0.72, 40, Color("ffb02e"), 3, true)
		text_at("ELITE • " + "+".join(PackedStringArray(enemy.modifiers)).to_upper(), enemy.p - Vector2(0, radius + 28), Color("ffcf66"), 10)
	elif enemy.variant == "ghost":
		text_at("FANTASMA", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[1], visual_alpha), 10)
	elif enemy.variant == "armored":
		text_at("BLINDADO", enemy.p - Vector2(0, radius + 20), Color("dce6ff"), 10)
	elif enemy.variant == "regen":
		text_at("REGEN", enemy.p - Vector2(0, radius + 20), Color("b6ff2e"), 10)
	elif enemy.variant == "splitter":
		text_at("DUPLICADOR", enemy.p - Vector2(0, radius + 20), Color("ff8bea"), 10)
	elif enemy.variant == "thief":
		text_at("LADRÃO", enemy.p - Vector2(0, radius + 20), Color("ffb02e"), 10)
	if enemy.hp < enemy.max_hp:
		var width := maxf(30, radius * 1.9)
		var rect := Rect2(enemy.p.x - width / 2, enemy.p.y - radius - 13, width, 4)
		draw_rect(rect.grow(1), Color(0, 0, 0, 0.7))
		rect.size.x *= maxf(0, enemy.hp / enemy.max_hp)
		draw_rect(rect, color)
	if enemy.type == 3:
		text_at("— BOSS —", enemy.p - Vector2(0, radius + 20), color, 13)
