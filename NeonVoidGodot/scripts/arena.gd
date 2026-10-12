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
	if state.max_shield > 0.0 and state.shield > 0.0:
		var s_ratio: float = clampf(state.shield / state.max_shield, 0.0, 1.0)
		var s_col := Color("00f5d4")
		var shield_y: float = base_y - 7.0
		glow_line(Vector2(0, shield_y), Vector2(size.x * s_ratio, shield_y), Color(s_col, 0.75 + sin(clock * 8.0) * 0.2), 3.0)
		draw_line(Vector2(0, shield_y), Vector2(size.x * s_ratio, shield_y), Color.WHITE, 1.2, true)
	for slot_index in state.tower_slots.size():
		var slot: Dictionary = state.tower_slots[slot_index]
		var slot_lvl: int = state.tower_slot_level(slot_index)
		var turret := state.tower_position(slot_index)
		var module_color := Color("ff2bd6")
		if slot.module_id == "cryo":
			module_color = Color("7feaff")
		elif slot.module_id == "arc":
			module_color = Color("c48aff")
		elif slot.module_id == "pulse":
			module_color = Color("b6ff2e")
		elif slot.module_id == "laser":
			module_color = Color("ff3355")
		elif slot.module_id == "vortex":
			module_color = Color("9933ff")
		elif slot.module_id == "railgun":
			module_color = Color("33ffcc")
		draw_circle(turret, 13 if slot_lvl > 0 else 9, Color("1a0f3a"))
		draw_arc(turret, 13 if slot_lvl > 0 else 9, 0, TAU, 40, Color(module_color, 1.0 if slot_lvl > 0 else 0.38), 1.5, true)
		if slot_lvl > 0:
			var direction := Vector2.from_angle(slot.turret_angle)
			glow_line(turret, turret + direction * 23, module_color, 6)
			if slot.module_id == "cryo":
				glow_line(turret + direction * 14 - direction.orthogonal() * 8, turret + direction * 14 + direction.orthogonal() * 8, module_color, 2)
			elif slot.module_id == "arc":
				for side in [-1, 1]:
					glow_line(turret + direction.orthogonal() * side * 8, turret + direction * 27 + direction.orthogonal() * side * 6, module_color, 2)
			elif slot.module_id == "pulse":
				draw_arc(turret, 17, 0, TAU, 16, module_color, 2.0, true)
				# Indicador visual de recarga da onda sismica
				var charge_pct: float = clampf(1.0 - (float(slot.get("auto_timer", 0.0)) / 2.5), 0.0, 1.0)
				if charge_pct < 1.0:
					draw_arc(turret, 20, -PI / 2, -PI / 2 + TAU * charge_pct, 24, Color(module_color, 0.7), 2.0, true)
				else:
					draw_arc(turret, 20 + sin(clock * 8) * 1.5, 0, TAU, 24, Color(module_color, 0.9), 2.0, true)
			elif slot.module_id == "laser":
				glow_line(turret + direction * 18 - direction.orthogonal() * 5, turret + direction * 26, module_color, 3)
				glow_line(turret + direction * 18 + direction.orthogonal() * 5, turret + direction * 26, module_color, 3)
			elif slot.module_id == "vortex":
				draw_arc(turret, 16, clock * 3, clock * 3 + TAU * 0.7, 24, module_color, 2.0, true)
				draw_arc(turret, 20, -clock * 4, -clock * 4 + TAU * 0.7, 24, Color(module_color, 0.7), 1.5, true)
				draw_circle(turret, 4, Color("050014"))
			elif slot.module_id == "railgun":
				var norm := direction.orthogonal()
				glow_line(turret + norm * 3.5, turret + direction * 30 + norm * 3.5, module_color, 2.0)
				glow_line(turret - norm * 3.5, turret + direction * 30 - norm * 3.5, module_color, 2.0)
				for coil in [12.0, 20.0, 28.0]:
					draw_line(turret + direction * coil - norm * 4.5, turret + direction * coil + norm * 4.5, Color.WHITE, 1.5, true)
			text_at("Nv.%d" % slot_lvl, turret + Vector2(0, 24), Color(module_color, 0.9), 9)
		else:
			text_at("#%d" % (slot_index + 1), turret + Vector2(0, 4), Color(module_color, 0.55), 9)
		if slot.get("pulse_time", 0.0) > 0:
			var ring_progress: float = 1.0 - (float(slot.pulse_time) / 0.4)
			var cur_radius: float = 20.0 + float(slot.get("pulse_ring", 200.0)) * ring_progress
			draw_arc(turret, cur_radius, 0, TAU, 48, Color(module_color, float(slot.pulse_time) / 0.4), 3.5, true)
			draw_arc(turret, cur_radius * 0.7, 0, TAU, 32, Color(module_color, (float(slot.pulse_time) / 0.4) * 0.5), 1.5, true)
		if slot.beam_time > 0:
			var alpha: float = clampf(slot.beam_time / 0.16, 0.0, 1.0)
			if slot.module_id == "plasma":
				_draw_plasma_attack(turret, slot.beam_target, alpha)
			elif slot.module_id == "cryo":
				_draw_cryo_attack(turret, slot.beam_target, alpha)
			elif slot.module_id == "arc":
				var is_static: bool = false
				for enemy in state.enemies:
					if enemy.p.distance_squared_to(slot.beam_target) < 1200.0 and enemy.get("static_timer", 0.0) > 0:
						is_static = true
						break
				_draw_arc_lightning(turret, slot.beam_target, slot.beam_chain, alpha, is_static)
			elif slot.module_id == "laser":
				var focus_time: float = float(slot.get("laser_focus_time", 0.0))
				_draw_laser_deathray(turret, slot.beam_target, focus_time, alpha)
			elif slot.module_id == "vortex":
				_draw_vortex_attack(turret, slot.beam_target, alpha)
			elif slot.module_id == "railgun":
				_draw_railgun_attack(turret, slot.beam_target, slot.beam_chain, alpha)
			else:
				glow_line(turret, slot.beam_target, Color(module_color, alpha), 3.0)
				draw_line(turret, slot.beam_target, Color.WHITE, 1.0, true)
	for enemy in state.enemies:
		draw_enemy(enemy)
	for proj in state.enemy_projectiles:
		draw_enemy_projectile(proj)
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

func draw_enemy_projectile(proj: Dictionary) -> void:
	var p_pos: Vector2 = proj.p
	var p_vel: Vector2 = proj.v
	var p_col: Color = proj.color
	var p_rad: float = float(proj.get("radius", 5.0))
	var dir: Vector2 = p_vel.normalized() if p_vel.length_squared() > 0.01 else Vector2.DOWN
	var tail_pos: Vector2 = p_pos - dir * (p_rad * 3.6)
	glow_line(tail_pos, p_pos, Color(p_col, 0.85), p_rad * 1.1)
	draw_circle(p_pos, p_rad + 2.5, Color(p_col, 0.45))
	draw_circle(p_pos, p_rad, p_col)
	draw_circle(p_pos, p_rad * 0.48, Color.WHITE)
	draw_arc(p_pos, p_rad + 4.0 + sin(clock * 18.0) * 1.2, 0, TAU, 16, Color(p_col, 0.7), 1.5, true)

func draw_enemy(enemy: Dictionary) -> void:
	var radius: float = enemy.radius * minf(1, 0.4 + enemy.age * 2)
	var color: Color = enemy.get("boss_color", VoidState.COLORS[3]) if enemy.type == 3 else VoidState.COLORS[enemy.type]
	var visual_alpha := 0.24 if enemy.ghosted else 1.0
	var points := PackedVector2Array()
	var outer := PackedVector2Array()
	var b_id: String = str(enemy.get("boss_id", ""))

	if enemy.type == 11:
		# Estrela/Diamante de 4 pontas
		for i in 8:
			var angle: float = enemy.rot + i * PI / 4.0
			var r: float = radius if (i % 2 == 0) else radius * 0.45
			points.append(enemy.p + Vector2.from_angle(angle) * r)
			outer.append(enemy.p + Vector2.from_angle(angle) * (r + 5))
	elif enemy.type == 12:
		# Estrela de 5 pontas
		for i in 10:
			var angle: float = enemy.rot + i * PI / 5.0
			var r: float = radius if (i % 2 == 0) else radius * 0.48
			points.append(enemy.p + Vector2.from_angle(angle) * r)
			outer.append(enemy.p + Vector2.from_angle(angle) * (r + 5))
	elif enemy.type == 17:
		# Teleportador Quântico: Estrela de 6 pontas (MerKaba)
		for i in 12:
			var angle: float = enemy.rot + i * PI / 6.0
			var r: float = radius if (i % 2 == 0) else radius * 0.46
			points.append(enemy.p + Vector2.from_angle(angle) * r)
			outer.append(enemy.p + Vector2.from_angle(angle) * (r + 5))
	elif enemy.type == 20:
		# Tecelão de Fendas: Estrela de 7 pontas dimensional
		for i in 14:
			var angle: float = enemy.rot + i * PI / 7.0
			var r: float = radius if (i % 2 == 0) else radius * 0.44
			points.append(enemy.p + Vector2.from_angle(angle) * r)
			outer.append(enemy.p + Vector2.from_angle(angle) * (r + 5))
	elif enemy.type == 3 and b_id in ["boss_nexus", "boss_omega"]:
		# Bosses Estelares (Nexus Cósmico 8 pontas / Arquiteto Ômega 10 pontas)
		var star_pts: int = 20 if b_id == "boss_omega" else 16
		for i in star_pts:
			var angle: float = enemy.rot + i * TAU / float(star_pts)
			var r: float = radius if (i % 2 == 0) else radius * 0.56
			points.append(enemy.p + Vector2.from_angle(angle) * r)
			outer.append(enemy.p + Vector2.from_angle(angle) * (r + 7))
	else:
		# Polígonos Regulares
		for i in enemy.sides:
			var direction := Vector2.from_angle(enemy.rot + i * TAU / enemy.sides)
			points.append(enemy.p + direction * radius)
			outer.append(enemy.p + direction * (radius + 7))

	draw_colored_polygon(outer, Color(color, 0.2 * visual_alpha))
	var body_color: Color = Color.WHITE if enemy.hit > 0 else color.darkened(0.5)
	body_color.a = visual_alpha
	draw_colored_polygon(points, body_color)

	# Facetas radiais
	var num_pts: int = points.size()
	for i in num_pts:
		var core_color: Color = Color.WHITE if enemy.hit > 0 else color
		core_color.a = visual_alpha
		var edge_color := color.darkened(0.55)
		edge_color.a = visual_alpha
		draw_polygon(PackedVector2Array([enemy.p, points[i], points[(i + 1) % num_pts]]), PackedColorArray([core_color, edge_color, edge_color]))

	var loop := points.duplicate()
	loop.append(points[0])
	var line_color: Color = Color.WHITE if enemy.hit > 0 else color
	line_color.a = visual_alpha
	draw_polyline(loop, line_color, 3 if (enemy.type == 3 or enemy.type >= 14) else 2.5, true)
	draw_circle(enemy.p, maxf(2.5, radius * 0.22), Color(1, 1, 1, 0.9 * visual_alpha))

	# Efeitos específicos por geometria e habilidades
	if enemy.type == 13:
		# Prisma Anelar
		draw_arc(enemy.p, radius + 8, clock * 3, clock * 3 + TAU * 0.75, 24, Color(color, visual_alpha * 0.7), 2.0, true)
	elif enemy.type == 14:
		# Singularidade Espiral
		draw_arc(enemy.p, radius + 10, -clock * 5, -clock * 5 + TAU * 0.8, 32, Color(color, visual_alpha * 0.8), 2.5, true)
		draw_circle(enemy.p, 5.0, Color("03000a"))
	elif enemy.type == 15:
		# Titã Tetraédrico
		draw_arc(enemy.p, radius + 12, clock * 2, clock * 2 + TAU, 36, Color(color, visual_alpha * 0.9), 3.0, true)

	# Assinaturas visuais de Atiradores, Teleportadores e Invocadores
	if enemy.get("can_shoot", false):
		var cannon_col := Color(color, visual_alpha)
		if enemy.type == 19 or enemy.type == 3:
			for s in [-1.0, 1.0]:
				var barrel_start: Vector2 = enemy.p + Vector2(s * radius * 0.42, radius * 0.55)
				var barrel_end: Vector2 = barrel_start + Vector2(0, 11.0)
				glow_line(barrel_start, barrel_end, cannon_col, 3.0)
				draw_circle(barrel_end, 2.5, Color.WHITE)
		else:
			var b_start: Vector2 = enemy.p + Vector2(0, radius * 0.6)
			var b_end: Vector2 = enemy.p + Vector2(0, radius + 10.0)
			glow_line(b_start, b_end, cannon_col, 3.5)
			draw_circle(b_end, 3.0, Color.WHITE)
	if enemy.get("can_teleport", false):
		draw_arc(enemy.p, radius + 7, clock * 6.0, clock * 6.0 + PI * 0.7, 16, Color("00f5d4", visual_alpha * 0.85), 2.0, true)
		draw_arc(enemy.p, radius + 7, clock * 6.0 + PI, clock * 6.0 + PI * 1.7, 16, Color("00f5d4", visual_alpha * 0.85), 2.0, true)
	if enemy.get("can_summon", false):
		for k in 3:
			var orb_ang: float = clock * 3.6 + float(k) * TAU / 3.0
			var orb_pos: Vector2 = enemy.p + Vector2.from_angle(orb_ang) * (radius + 9.0)
			draw_circle(orb_pos, 3.5, Color(color, visual_alpha))
			draw_circle(orb_pos, 1.6, Color.WHITE)

	if enemy.slow_timer > 0:
		var frost_center: Vector2 = enemy.p + Vector2(radius + 9, 0)
		for i in 3:
			var frost_axis := Vector2.from_angle(i * PI / 3) * 6
			draw_line(frost_center - frost_axis, frost_center + frost_axis, Color(0.5, 0.92, 1, visual_alpha), 2, true)
	if enemy.get("static_timer", 0.0) > 0:
		draw_arc(enemy.p, radius + 7, clock * 6, clock * 6 + PI, 16, Color(1, 0.9, 0.3, visual_alpha * 0.8), 2.0, true)
	if enemy.variant == "armored" or enemy.modifiers.has("armor"):
		draw_arc(enemy.p, radius + 11, 0, TAU, 8, Color(0.8, 0.85, 1, 0.8 * visual_alpha), 3, true)
	if enemy.variant == "regen" or enemy.modifiers.has("regen"):
		draw_arc(enemy.p, radius + 8, -PI / 2, -PI / 2 + TAU * (0.55 + sin(clock * 3) * 0.15), 32, Color(0.71, 1, 0.18, 0.85 * visual_alpha), 2, true)
	if enemy.modifiers.has("berserk"):
		draw_arc(enemy.p, radius + 13, -clock * 5, -clock * 5 + TAU * 0.65, 24, Color("ff4d4d", 0.85 * visual_alpha), 2.5, true)
	if enemy.variant == "splitter":
		draw_circle(enemy.p + Vector2(-radius * 0.38, 0), 3, Color.WHITE)
		draw_circle(enemy.p + Vector2(radius * 0.38, 0), 3, Color.WHITE)
	if enemy.variant == "thief":
		text_at("$", enemy.p + Vector2(0, 5), Color("ffb02e"), 12)
	if enemy.elite:
		var e_col: Color = enemy.get("elite_color", Color("ffb02e"))
		draw_arc(enemy.p, radius + 15, clock * 1.8, clock * 1.8 + TAU * 0.72, 40, Color(e_col, visual_alpha), 3.0, true)
		draw_arc(enemy.p, radius + 19, -clock * 2.4, -clock * 2.4 + TAU * 0.45, 32, Color(e_col.lightened(0.25), visual_alpha * 0.75), 2.0, true)
		var e_title: String = str(enemy.get("elite_name", "ELITE"))
		text_at(e_title + " • " + "+".join(PackedStringArray(enemy.modifiers)).to_upper(), enemy.p - Vector2(0, radius + 28), e_col.lightened(0.2), 10)
	elif enemy.get("is_minion", false):
		text_at("LACAIO", enemy.p - Vector2(0, radius + 16), Color(color, visual_alpha * 0.85), 9)
	elif enemy.type == 4:
		text_at("PENTÁGONO", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[4], visual_alpha), 10)
	elif enemy.type == 5:
		text_at("HEPTÁGONO", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[5], visual_alpha), 10)
	elif enemy.type == 6:
		text_at("OCTÓGONO", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[6], visual_alpha), 10)
	elif enemy.type == 7:
		text_at("NONÁGONO", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[7], visual_alpha), 10)
	elif enemy.type == 8:
		text_at("DECÁGONO", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[8], visual_alpha), 10)
	elif enemy.type == 9:
		text_at("HENDECÁGONO", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[9], visual_alpha), 10)
	elif enemy.type == 10:
		text_at("DODECÁGONO", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[10], visual_alpha), 10)
	elif enemy.type == 11:
		text_at("DIAMANTE", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[11], visual_alpha), 10)
	elif enemy.type == 12:
		text_at("ESTRELA CADENTE", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[12], visual_alpha), 10)
	elif enemy.type == 13:
		text_at("PRISMA ANELAR", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[13], visual_alpha), 10)
	elif enemy.type == 14:
		text_at("SINGULARIDADE", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[14], visual_alpha), 10)
	elif enemy.type == 15:
		text_at("TITÃ TETRAÉDRICO", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[15], visual_alpha), 10)
	elif enemy.type == 16:
		text_at("ATIRADOR DO VAZIO", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[16], visual_alpha), 10)
	elif enemy.type == 17:
		text_at("TELEPORTADOR", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[17], visual_alpha), 10)
	elif enemy.type == 18:
		text_at("INVOCADOR", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[18], visual_alpha), 10)
	elif enemy.type == 19:
		text_at("ARTILHEIRO", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[19], visual_alpha), 10)
	elif enemy.type == 20:
		text_at("TECELÃO DE FENDAS", enemy.p - Vector2(0, radius + 20), Color(VoidState.COLORS[20], visual_alpha), 10)
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
		draw_arc(enemy.p, radius + 16, -clock * 2, -clock * 2 + TAU * 0.85, 48, Color(color, 0.7 * visual_alpha), 2.5, true)
		draw_arc(enemy.p, radius + 21, clock * 1.5, clock * 1.5 + TAU * 0.6, 40, Color(color.lightened(0.25), 0.5 * visual_alpha), 2.0, true)
		var boss_title: String = str(enemy.get("boss_name", "BOSS SUPREMO"))
		text_at("— " + boss_title + " —", enemy.p - Vector2(0, radius + 24), color, 13)

func _draw_plasma_attack(from: Vector2, to: Vector2, alpha: float) -> void:
	var dist := from.distance_to(to)
	var dir := (to - from).normalized()
	var normal := dir.orthogonal()
	var col_plasma := Color("ff2bd6")
	col_plasma.a = alpha

	# Projétil de plasma viajando ao longo da linha
	var travel: float = clampf(1.0 - (alpha * 0.75), 0.15, 1.0)
	var head_pos := from.lerp(to, travel)
	var tail_len := minf(65.0, dist * 0.45)
	var tail_pos := head_pos - dir * tail_len

	# Cauda de plasma em degradê (cometa luminoso)
	var p_left := head_pos - dir * 14 + normal * 7
	var p_right := head_pos - dir * 14 - normal * 7
	draw_colored_polygon(PackedVector2Array([head_pos, p_left, tail_pos, p_right]), Color(col_plasma, 0.4 * alpha))
	glow_line(tail_pos, head_pos, col_plasma, 4.0)

	# Esferas concêntricas no núcleo do projétil de plasma
	draw_circle(head_pos, 8.5, Color(col_plasma, 0.75 * alpha))
	draw_circle(head_pos, 5.0, Color(1, 0.65, 0.95, alpha))
	draw_circle(head_pos, 2.5, Color(1, 1, 1, alpha))

	# Anéis pulsantes ao redor do projétil
	draw_arc(head_pos, 11.0, 0, TAU, 16, Color(col_plasma, 0.5 * alpha), 1.5, true)
	if travel >= 0.7:
		draw_arc(to, 14.0 * (1.0 - alpha), 0, TAU, 16, Color(col_plasma, alpha), 2.0, true)

func _draw_cryo_attack(from: Vector2, to: Vector2, alpha: float) -> void:
	var dir := (to - from).normalized()
	var normal := dir.orthogonal()
	var col_ice := Color("22e6ff")
	var col_frost := Color("a5f3fc")
	col_ice.a = alpha
	col_frost.a = alpha

	# Spray de névoa e geada cônica
	var spread_factors: Array[float] = [-1.0, -0.5, 0.0, 0.5, 1.0]
	for spread_factor: float in spread_factors:
		var spread_end: Vector2 = to + normal * (spread_factor * 24.0)
		draw_line(from, spread_end, Color(col_ice, 0.16 * alpha), 2.0 + absf(spread_factor) * 1.5, true)

	# Feixe cristalino central
	glow_line(from, to, Color(col_ice, 0.6 * alpha), 3.5)
	draw_line(from, to, Color(col_frost, 0.9 * alpha), 1.5, true)

	# Estilhaços pontiagudos de gelo / cristais diamantados ao longo da trajetória
	for c in range(1, 6):
		var t := float(c) / 6.0
		var c_pos := from.lerp(to, t) + normal * sin(t * 14.0 + clock * 12.0) * 8.0
		var c_size := 4.5 + sin(t * PI) * 3.5
		var d_top := c_pos + dir * c_size * 1.8
		var d_bot := c_pos - dir * c_size * 1.2
		var d_left := c_pos + normal * c_size
		var d_right := c_pos - normal * c_size
		draw_colored_polygon(PackedVector2Array([d_top, d_left, d_bot, d_right]), Color(col_frost, 0.8 * alpha))
		draw_polyline(PackedVector2Array([d_top, d_left, d_bot, d_right, d_top]), Color(col_ice, alpha), 1.5, true)

	# Flocos de impacto nos alvos
	var spoke_angles: Array[float] = [0.0, PI / 3.0, 2.0 * PI / 3.0]
	for a: float in spoke_angles:
		var spoke: Vector2 = Vector2.from_angle(a) * 12.0
		draw_line(to - spoke, to + spoke, Color(col_frost, alpha), 2.0, true)

func _draw_arc_lightning(from: Vector2, to: Vector2, chain: Array, alpha: float, is_static_storm: bool) -> void:
	var col_arc := Color("c48aff") if not is_static_storm else Color("ffb02e")
	var col_core := Color(1, 1, 1, alpha)
	col_arc.a = alpha

	var all_nodes: Array[Vector2] = [from, to]
	for p in chain:
		all_nodes.append(p)

	for seg in range(all_nodes.size() - 1):
		var p1: Vector2 = all_nodes[seg]
		var p2: Vector2 = all_nodes[seg + 1]
		var seg_dist := p1.distance_to(p2)
		var seg_dir := (p2 - p1).normalized()
		var seg_norm := seg_dir.orthogonal()

		var steps := maxi(6, int(seg_dist / 20.0))
		var lightning_pts := PackedVector2Array()
		lightning_pts.append(p1)

		for s in range(1, steps):
			var t := float(s) / float(steps)
			var seed_v := float(seg * 23 + s * 37)
			var offset_mag := (sin(clock * 55.0 + seed_v) * 0.65 + cos(clock * 40.0 + seed_v * 1.8) * 0.35) * 14.0
			if is_static_storm:
				offset_mag *= 1.45
			var pt := p1.lerp(p2, t) + seg_norm * offset_mag
			lightning_pts.append(pt)

			# Ramificações laterais elétricas
			if s % 3 == 0:
				var fork_end := pt + (seg_dir + seg_norm * (1.0 if s % 2 == 0 else -1.0)).normalized() * 16.0
				draw_line(pt, fork_end, Color(col_arc, 0.6 * alpha), 1.2, true)

		lightning_pts.append(p2)

		# Brilho eletrostático e traçado em zigue-zague
		glow_line(p1, p2, Color(col_arc, 0.25 * alpha), 8.0 if is_static_storm else 5.0)
		draw_polyline(lightning_pts, Color(col_arc, 0.9 * alpha), 3.2 if is_static_storm else 2.2, true)
		draw_polyline(lightning_pts, col_core, 1.2, true)

		# Centelhas no ponto de contato
		draw_circle(p2, 5.0, Color(col_arc, alpha))
		draw_circle(p2, 2.5, Color.WHITE)

func _draw_laser_deathray(from: Vector2, to: Vector2, focus_time: float, alpha: float) -> void:
	var col_laser := Color("ff3355")
	var normal := (to - from).normalized().orthogonal()
	var dist := from.distance_to(to)

	var ramp_factor := clampf(focus_time / 2.0, 0.0, 1.0)
	var beam_core_w := 2.5 + ramp_factor * 5.0
	var beam_halo_w := 9.0 + ramp_factor * 15.0

	var jitter := normal * sin(clock * 70.0) * (0.8 + ramp_factor * 1.6)
	var j_from := from + jitter
	var j_to := to + jitter

	glow_line(j_from, j_to, Color(col_laser, 0.35 * alpha), beam_halo_w)
	glow_line(j_from, j_to, Color(col_laser, 0.75 * alpha), beam_core_w + 3.0)
	draw_line(j_from, j_to, Color(1, 0.9, 0.95, alpha), beam_core_w, true)

	# Bobinas magnéticas de contenção ao longo do feixe
	var num_rings := maxi(3, int(dist / 60.0))
	for r in range(1, num_rings):
		var t := float(r) / float(num_rings)
		var ring_t := fmod(t + clock * 2.8, 1.0)
		var ring_pos := from.lerp(to, ring_t)
		var ring_radius := (5.5 + ramp_factor * 4.5) + sin(clock * 16.0 + r) * 1.5
		draw_line(ring_pos - normal * ring_radius, ring_pos + normal * ring_radius, Color(1, 0.82, 0.88, 0.85 * alpha), 2.5, true)
		draw_circle(ring_pos - normal * ring_radius, 2.2, Color(col_laser, alpha))
		draw_circle(ring_pos + normal * ring_radius, 2.2, Color(col_laser, alpha))

	# Ponto de corte e desintegração incandescente no alvo
	var burn_radius := 6.5 + ramp_factor * 8.5
	draw_circle(to, burn_radius * 1.4, Color(col_laser, 0.6 * alpha))
	draw_circle(to, burn_radius, Color(1, 0.92, 0.8, alpha))
	draw_circle(to, burn_radius * 0.5, Color.WHITE)
	draw_arc(to, burn_radius * 1.8 + sin(clock * 25.0) * 2.0, 0, TAU, 20, Color(col_laser, alpha), 2.0, true)

func _draw_vortex_attack(from: Vector2, to: Vector2, alpha: float) -> void:
	var col_vortex := Color("9933ff")
	col_vortex.a = alpha
	var col_inner := Color("d88aff")
	col_inner.a = alpha

	# Linha de ancoragem gravitacional da torre à singularidade
	glow_line(from, to, Color(col_vortex, 0.35 * alpha), 4.0)
	draw_line(from, to, Color(col_inner, 0.7 * alpha), 1.5, true)

	# Disco de acréscimo em espiral e ondas de curvatura
	var base_r: float = 18.0 + sin(clock * 12.0) * 3.0
	draw_arc(to, base_r * 2.2, clock * 5.0, clock * 5.0 + TAU * 0.8, 32, Color(col_vortex, 0.4 * alpha), 2.0, true)
	draw_arc(to, base_r * 1.5, -clock * 7.0, -clock * 7.0 + TAU * 0.85, 28, Color(col_vortex, 0.7 * alpha), 2.5, true)
	draw_arc(to, base_r, clock * 9.0, clock * 9.0 + TAU * 0.9, 24, Color(col_inner, 0.9 * alpha), 3.0, true)

	# Horizonte de Eventos / Núcleo do Buraco Negro
	draw_circle(to, 12.0, Color("050014"))
	draw_circle(to, 6.0, Color("000000"))
	draw_arc(to, 12.0, 0, TAU, 24, Color(col_inner, alpha), 1.5, true)

	# Linhas de sucção gravitacional
	for i in 6:
		var ang: float = float(i) * (TAU / 6.0) + clock * 4.0
		var p_outer: Vector2 = to + Vector2.from_angle(ang) * (base_r * 2.8)
		var p_mid: Vector2 = to + Vector2.from_angle(ang + 0.6) * (base_r * 1.4)
		draw_line(p_outer, p_mid, Color(col_vortex, 0.5 * alpha), 1.5, true)

func _draw_railgun_attack(from: Vector2, wall_hit: Vector2, chain: Array, alpha: float) -> void:
	var col_rail := Color("33ffcc")
	col_rail.a = alpha
	var col_core := Color(1, 1, 1, alpha)

	# Segmento 1: Da Torre até a Parede de Impacto
	glow_line(from, wall_hit, Color(col_rail, 0.4 * alpha), 10.0)
	glow_line(from, wall_hit, Color(col_rail, 0.85 * alpha), 4.5)
	draw_line(from, wall_hit, col_core, 2.0, true)

	# Anéis de choque de Mach ao longo do primeiro segmento
	var dist_1: float = from.distance_to(wall_hit)
	var dir_1: Vector2 = (wall_hit - from).normalized()
	var norm_1: Vector2 = dir_1.orthogonal()
	var rings_count: int = maxi(2, int(dist_1 / 90.0))
	for r in range(1, rings_count):
		var t: float = float(r) / float(rings_count)
		var r_pos: Vector2 = from.lerp(wall_hit, t)
		draw_line(r_pos - norm_1 * 9.0, r_pos + norm_1 * 9.0, Color(col_rail, 0.7 * alpha), 2.0, true)

	# Ponto de impacto na parede da arena com faíscas reflexivas
	draw_circle(wall_hit, 8.0, Color(col_rail, alpha))
	draw_circle(wall_hit, 4.0, Color.WHITE)
	draw_arc(wall_hit, 16.0 * (1.0 - alpha * 0.5), 0, TAU, 20, Color(col_rail, alpha), 2.0, true)

	# Segmento 2: Ricochete da Parede em direção à tela
	if not chain.is_empty():
		var bounce_end: Vector2 = chain[0]
		glow_line(wall_hit, bounce_end, Color(col_rail, 0.3 * alpha), 7.0)
		glow_line(wall_hit, bounce_end, Color(col_rail, 0.7 * alpha), 3.5)
		draw_line(wall_hit, bounce_end, col_core, 1.5, true)
		var dist_2: float = wall_hit.distance_to(bounce_end)
		var dir_2: Vector2 = (bounce_end - wall_hit).normalized()
		var norm_2: Vector2 = dir_2.orthogonal()
		var rings_count_2: int = maxi(1, int(dist_2 / 100.0))
		for r in range(1, rings_count_2):
			var t2: float = float(r) / float(rings_count_2)
			var r_pos2: Vector2 = wall_hit.lerp(bounce_end, t2)
			draw_line(r_pos2 - norm_2 * 7.0, r_pos2 + norm_2 * 7.0, Color(col_rail, 0.6 * alpha), 1.5, true)
