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
var preview_tower_id: int = -1
var preview_pos: Vector2 = Vector2.ZERO
var preview_radius: float = 0.0
var hovered_tower_slot: int = -1
var font = preload("res://assets/fonts/DisplayBold.tres")
var background: GradientTexture2D
@onready var hit_particles: CPUParticles2D = get_node_or_null("HitParticles")
@onready var nova_particles: CPUParticles2D = get_node_or_null("NovaParticles")

var screen_shake := ScreenShake.new()
var damage_numbers := DamageNumbers.new()
var boss_defeat_fx := BossDefeatFX.new()

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
	mouse_exited.connect(func():
		hovered_tower_slot = -1
		if is_instance_valid(state):
			state.range_preview_cleared.emit()
	)
	if Accessibility.instance:
		screen_shake.set_enabled(not Accessibility.instance.reduce_shake)
		Accessibility.instance.settings_changed.connect(func():
			screen_shake.set_enabled(not Accessibility.instance.reduce_shake)
		)
	if is_instance_valid(state):
		_connect_state_preview()

func set_state(new_state: VoidState) -> void:
	state = new_state
	if is_instance_valid(state):
		_connect_state_preview()

func _connect_state_preview() -> void:
	if not state.is_connected("range_preview_requested", _on_range_preview_requested):
		state.range_preview_requested.connect(_on_range_preview_requested)
	if not state.is_connected("range_preview_cleared", _on_range_preview_cleared):
		state.range_preview_cleared.connect(_on_range_preview_cleared)
	if not state.is_connected("screen_shake_requested", _on_screen_shake_requested):
		state.screen_shake_requested.connect(_on_screen_shake_requested)
	if not state.is_connected("boss_defeat_cinematic", _on_boss_defeat_cinematic):
		state.boss_defeat_cinematic.connect(_on_boss_defeat_cinematic)
	if not state.is_connected("damage_dealt", _on_damage_dealt):
		state.damage_dealt.connect(_on_damage_dealt)

func _on_screen_shake_requested(shake_type: String, custom_intensity: float) -> void:
	screen_shake.add_event_shake(shake_type, custom_intensity)

func _on_boss_defeat_cinematic(boss_pos: Vector2, _boss_data: Dictionary) -> void:
	var reduce: bool = false
	if Accessibility.instance and (Accessibility.instance.reduce_shake or Accessibility.instance.reduce_motion):
		reduce = true
	boss_defeat_fx.trigger(boss_pos, reduce)

func _on_damage_dealt(target_id: int, pos: Vector2, amount: float, damage_type: String, is_crit: bool, extra: String) -> void:
	damage_numbers.spawn_number(target_id, pos, amount, damage_type, is_crit, extra)

func _on_range_preview_requested(tower_id: int, pos: Vector2, radius: float) -> void:
	preview_tower_id = tower_id
	preview_pos = pos
	preview_radius = radius
	queue_redraw()

func _on_range_preview_cleared() -> void:
	preview_tower_id = -1
	preview_radius = 0.0
	queue_redraw()

func _input_arena(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_check_tower_hover(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		state.tap(event.position)
		accept_event()

func _check_tower_hover(mouse_pos: Vector2) -> void:
	if state == null or not state.running:
		return
	var found_slot := -1
	for slot_idx in state.tower_slots.size():
		var pos := state.tower_position(slot_idx)
		if mouse_pos.distance_to(pos) <= 24.0:
			found_slot = slot_idx
			break
	if found_slot != hovered_tower_slot:
		hovered_tower_slot = found_slot
		if hovered_tower_slot >= 0:
			var slot_pos := state.tower_position(hovered_tower_slot)
			var r: float = get_tower_attack_range(hovered_tower_slot)
			state.range_preview_requested.emit(hovered_tower_slot, slot_pos, r)
		else:
			state.range_preview_cleared.emit()

func get_tower_attack_range(slot_index: int) -> float:
	if state == null or slot_index < 0 or slot_index >= state.tower_slots.size():
		return 180.0
	var mod_id: String = state.tower_slots[slot_index].module_id
	var range_mult: float = 1.0 + float(state.upg_level("tower_range")) * 0.15
	match mod_id:
		"pulse":
			return state.bounds.x * 0.75 * range_mult
		"vortex":
			return (160.0 + float(state.research[29]) * 12.0) * range_mult
		"railgun":
			return state.bounds.y * 1.1 * range_mult
		"cryo":
			return 210.0 * range_mult
		"arc":
			return (160.0 + float(state.research[23]) * 18.0) * range_mult
		"laser":
			return 240.0 * range_mult
		_:
			return 200.0 * range_mult

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
		if is_instance_valid(nova_particles):
			nova_particles.position = point
			nova_particles.color = color
			nova_particles.restart()
	elif kind in ["burst", "hit"] and is_instance_valid(hit_particles):
		hit_particles.position = point
		hit_particles.color = color
		hit_particles.restart()
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
	screen_shake.stop()
	damage_numbers.clear()
	boss_defeat_fx.reset()

func _process(dt: float) -> void:
	if state == null or state.paused:
		return
	clock += dt
	state.bounds = size
	trauma = maxf(0, trauma - dt * 1.6)
	flash = maxf(0, flash - dt * 2.2)
	red = maxf(0, red - dt * 1.8)
	screen_shake.update(dt)
	damage_numbers.update(dt)
	boss_defeat_fx.update(dt)
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
	var mapped_color: Color = Accessibility.remap_color(color)
	if not PerformanceMode.is_enabled():
		for w in [14.0, 8.0, 4.0]:
			draw_line(a, b, Color(mapped_color, 0.035), width + w, true)
	draw_line(a, b, mapped_color, width, true)

func glow_line_circle(center_pos: Vector2, radius: float, color: Color, width := 2.0) -> void:
	var mapped_color: Color = Accessibility.remap_color(color)
	if not PerformanceMode.is_enabled():
		for w in [12.0, 6.0, 3.0]:
			draw_arc(center_pos, radius, 0, TAU, 48, Color(mapped_color, 0.04), width + w, true)
	draw_arc(center_pos, radius, 0, TAU, 48, mapped_color, width, true)
	draw_arc(center_pos, radius, 0, TAU, 48, Color.WHITE, 1.0, true)

func text_at(words: String, point: Vector2, color: Color, font_size: int) -> void:
	var start := point - Vector2(font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2, 0)
	draw_string_outline(font, start, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, color.a * 0.7))
	draw_string(font, start, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if state == null or background == null:
		return
	draw_texture_rect(background, Rect2(Vector2.ZERO, size), false)
	var shake_offset: Vector2 = screen_shake.offset + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * trauma * trauma * 22
	if boss_defeat_fx.active and not is_equal_approx(boss_defeat_fx.current_zoom, 1.0):
		draw_set_transform_matrix(boss_defeat_fx.get_zoom_transform(size).translated(shake_offset))
	else:
		draw_set_transform(shake_offset)
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
	var dome_center := Vector2(size.x * 0.5, base_y)
	var dome_r: float = state.dome_radius()
	_draw_base_dome(dome_center, dome_r, base_color)
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
		var pedestal_h: float = 13.0 if slot_lvl > 0 else 9.0
		var pedestal_top := turret + Vector2(0, pedestal_h)
		var pedestal_bot := Vector2(turret.x, base_y)
		draw_line(pedestal_top, pedestal_bot, Color(module_color, 0.35 if slot_lvl > 0 else 0.18), 2.0, true)
		draw_line(pedestal_top + Vector2(-3, 0), pedestal_top + Vector2(3, 0), Color(module_color, 0.5), 1.5, true)
		draw_line(pedestal_bot + Vector2(-5, 0), pedestal_bot + Vector2(5, 0), Color(module_color, 0.7), 2.0, true)
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
	# Preview de Alcance (Hover na torreta ou requisição externa)
	if preview_radius > 0.0 and preview_tower_id >= 0:
		var preview_col := Color("22e6ff")
		if state != null and preview_tower_id < state.tower_slots.size():
			var slot_mod: String = state.tower_slots[preview_tower_id].module_id
			preview_col = GameData.MODULE_INFO.get(slot_mod, ["", "", preview_col])[2]
		var pulse: float = sin(clock * TAU / 0.8) * 0.04
		var eff_radius: float = preview_radius * (1.0 + pulse)
		draw_circle(preview_pos, eff_radius, Color(preview_col, 0.08))
		glow_line_circle(preview_pos, eff_radius, preview_col, 2.0)
		if state != null and preview_tower_id < state.tower_slots.size():
			var mid: String = state.tower_slots[preview_tower_id].module_id
			if mid in ["pulse", "vortex"]:
				var inner_r: float = eff_radius * 0.45
				draw_arc(preview_pos, inner_r, 0, TAU, 32, Color(preview_col, 0.6), 1.5, true)
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
	if damage_numbers != null and damage_numbers.enabled:
		for entry in damage_numbers.pool:
			if not entry.active:
				continue
			var alpha: float = clampf(entry.life / 0.25, 0.0, 1.0)
			var display_str: String = entry.text
			if not entry.extra_text.is_empty():
				display_str += " " + entry.extra_text
			var font_size: int = roundi(16 * entry.scale) if entry.is_crit else roundi(12 * entry.scale)
			text_at(display_str, entry.position, Color(entry.color, alpha), font_size)
	if state.banner_time > 0 and state.running:
		text_at(state.banner, size * Vector2(0.5, 0.32), Color(0.9, 0.8, 1, minf(1, state.banner_time)), 32)
	if state.combo >= 5:
		var combo_str: String = I18n.t("arena.combo_format", "x%d   •   x%.2f dano + ouro")
		text_at(combo_str % [state.combo, state.multiplier()], Vector2(215, 35), Color("ffb02e"), 14)
	if state.play_time < 4 and state.kills == 0:
		text_at(I18n.t("arena.tap_hint", "TOQUE NOS INIMIGOS!"), size * Vector2(0.5, 0.46), Color("a5f3fc"), 19)
	if state.hp <= state.max_hp * 0.32:
		text_at(I18n.t("arena.critical_base", "BASE CRÍTICA — PROTEJA O NÚCLEO"), Vector2(size.x / 2, 70), Color("ff7799"), 14)
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
	var is_tele: bool = bool(proj.get("is_telegraphed", false))
	var tele_t: float = float(proj.get("telegraph_timer", 0.0))

	if is_tele:
		var target_pos: Vector2 = proj.get("target_pos", p_pos + Vector2(0, 150))
		if tele_t > 0.0:
			draw_line(p_pos, target_pos, Color(p_col, 0.40 + 0.35 * sin(clock * 20.0)), 2.0)
			draw_arc(target_pos, 16.0, 0, TAU, 16, Color(p_col, 0.6 + 0.4 * sin(clock * 16.0)), 2.0, true)
			draw_arc(p_pos, p_rad + 8.0 * tele_t, 0, TAU, 24, Color.WHITE, 2.0, true)
			text_at("!", p_pos, Color.WHITE, 13)
		else:
			draw_line(p_pos, target_pos, Color(p_col, 0.2), 1.0)
			draw_arc(target_pos, 14.0, 0, TAU, 16, Color(p_col, 0.4), 1.5, true)
			draw_arc(p_pos, p_rad + 3.0, 0, TAU, 20, Color(p_col, 0.9), 2.5, true)
			draw_circle(p_pos, p_rad, p_col)
			draw_circle(p_pos, p_rad * 0.5, Color.WHITE)
			text_at("✦", p_pos, Color.WHITE, 11)
		return

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
	var is_boss: bool = (enemy.type == 3)
	var is_miniboss: bool = bool(enemy.get("is_miniboss", false))
	if enemy.hp < enemy.max_hp or is_boss or is_miniboss:
		var width := maxf(74, radius * 2.2) if is_boss else (maxf(48, radius * 2.0) if is_miniboss else maxf(30, radius * 1.9))
		var rect := Rect2(enemy.p.x - width / 2, enemy.p.y - radius - (16 if is_boss else 13), width, 5 if is_boss else 4)
		draw_rect(rect.grow(1), Color(0, 0, 0, 0.75))
		var hp_rect := rect
		hp_rect.size.x *= maxf(0, enemy.hp / enemy.max_hp)
		draw_rect(hp_rect, color)
		if is_boss:
			var m66_x: float = rect.position.x + width * 0.66
			var m33_x: float = rect.position.x + width * 0.33
			draw_line(Vector2(m66_x, rect.position.y - 2), Vector2(m66_x, rect.position.y + rect.size.y + 2), Color.WHITE, 1.5)
			draw_line(Vector2(m33_x, rect.position.y - 2), Vector2(m33_x, rect.position.y + rect.size.y + 2), Color.WHITE, 1.5)

	if is_boss:
		draw_arc(enemy.p, radius + 16, -clock * 2, -clock * 2 + TAU * 0.85, 48, Color(color, 0.7 * visual_alpha), 2.5, true)
		draw_arc(enemy.p, radius + 21, clock * 1.5, clock * 1.5 + TAU * 0.6, 40, Color(color.lightened(0.25), 0.5 * visual_alpha), 2.0, true)
		var boss_title: String = str(enemy.get("boss_name", "BOSS SUPREMO"))
		var b_phase: int = int(enemy.get("boss_phase", 1))
		var invul: float = float(enemy.get("invulnerable_timer", 0.0))
		if invul > 0.0:
			draw_arc(enemy.p, radius + 30.0 * (1.0 - invul * 0.5), 0, TAU, 32, Color.WHITE, 3.0, true)
			text_at("INVULNERÁVEL", enemy.p - Vector2(0, radius + 36), Color.WHITE, 12)
		if b_phase >= 2:
			draw_arc(enemy.p, radius + 26, clock * 6.0, clock * 6.0 + TAU, 32, Color("ff007f", 0.9 * visual_alpha), 3.0, true)
			for spk in 8:
				var spk_ang: float = clock * 4.0 + float(spk) * TAU / 8.0
				var p1: Vector2 = enemy.p + Vector2.from_angle(spk_ang) * (radius + 18.0)
				var p2: Vector2 = enemy.p + Vector2.from_angle(spk_ang) * (radius + 28.0)
				glow_line(p1, p2, Color("ff007f", visual_alpha), 2.5)
			text_at("FASE %d // %s" % [b_phase, boss_title], enemy.p - Vector2(0, radius + 24), Color("ff007f").lightened(0.3), 13)
		else:
			text_at("FASE 1 // %s" % boss_title, enemy.p - Vector2(0, radius + 24), color, 13)
	elif is_miniboss:
		draw_arc(enemy.p, radius + 8.0 + sin(clock * 6.0) * 2.0, 0, TAU, 32, Color("ffb02e", 0.8), 2.0, true)
		text_at(str(enemy.get("miniboss_name", "MINI-CHEFE")), enemy.p - Vector2(0, radius + 20), Color("ffb02e"), 11)

func _draw_plasma_attack(from: Vector2, to: Vector2, alpha: float) -> void:
	AttackVFX.draw_plasma(self, from, to, alpha)

func _draw_cryo_attack(from: Vector2, to: Vector2, alpha: float) -> void:
	AttackVFX.draw_cryo(self, from, to, alpha, clock)

func _draw_arc_lightning(from: Vector2, to: Vector2, chain: Array, alpha: float, is_static_storm: bool) -> void:
	AttackVFX.draw_arc(self, from, to, chain, alpha, is_static_storm, clock)

func _draw_laser_deathray(from: Vector2, to: Vector2, focus_time: float, alpha: float) -> void:
	AttackVFX.draw_laser(self, from, to, focus_time, alpha, clock)

func _draw_vortex_attack(from: Vector2, to: Vector2, alpha: float) -> void:
	AttackVFX.draw_vortex(self, from, to, alpha, clock)

func _draw_railgun_attack(from: Vector2, wall_hit: Vector2, chain: Array, alpha: float) -> void:
	AttackVFX.draw_railgun(self, from, wall_hit, chain, alpha)

func _draw_base_dome(center: Vector2, radius: float, base_color: Color) -> void:
	# 1. Estrutura geométrica: semicírculo sólido de fundo escuro bloqueando o grid estelar
	var dome_pts := PackedVector2Array()
	dome_pts.append(center)
	for i in range(33):
		var ang: float = PI + (PI * float(i) / 32.0)
		dome_pts.append(center + Vector2(cos(ang), sin(ang)) * radius)
	draw_colored_polygon(dome_pts, Color("0a0418", 0.95))

	# 2. Arcos internos concêntricos de atmosfera/energia
	for r_step in [0.85, 0.65, 0.45]:
		draw_arc(center, radius * r_step, PI, TAU, 28, Color(base_color, 0.12), 1.0, true)

	# 3. Nervuras radiais geodésicas (vigas da cúpula com nós iluminados)
	var rib_angles := [PI * 1.15, PI * 1.32, PI * 1.5, PI * 1.68, PI * 1.85]
	for ang in rib_angles:
		var dir_v := Vector2(cos(ang), sin(ang))
		var rib_outer := center + dir_v * radius
		draw_line(center, rib_outer, Color(base_color, 0.32), 1.2, true)
		draw_circle(rib_outer, 2.0, base_color)

	# 4. Arcos estruturais principais da cúpula
	draw_arc(center, radius, PI, TAU, 48, Color(base_color, 0.22), 5.0, true)
	draw_arc(center, radius, PI, TAU, 48, base_color, 2.2, true)
	draw_arc(center, radius, PI, TAU, 48, Color.WHITE, 1.0, true)
	draw_arc(center, radius * 0.72, PI, TAU, 36, Color(base_color, 0.55), 1.4, true)
	draw_arc(center, radius * 0.44, PI, TAU, 28, Color(base_color, 0.7), 1.4, true)

	# 5. Fundação reforçada da base
	glow_line(center - Vector2(radius + 12.0, 0), center + Vector2(radius + 12.0, 0), base_color, 2.5)
	draw_line(center - Vector2(radius, 0), center - Vector2(radius + 12.0, -8.0), base_color, 2.0, true)
	draw_line(center + Vector2(radius, 0), center + Vector2(radius + 12.0, -8.0), base_color, 2.0, true)

	# 6. Reator / Núcleo Central de Energia
	var core_pos := center - Vector2(0, 16.0)
	var pulse: float = 0.5 + 0.5 * sin(clock * 5.0)
	draw_circle(core_pos, 11.0 + pulse * 3.5, Color(base_color, 0.22 + pulse * 0.18))
	draw_circle(core_pos, 7.0, base_color)
	draw_circle(core_pos, 3.0, Color.WHITE)
	var rot_a := clock * 2.2
	draw_arc(core_pos, 13.0, rot_a, rot_a + PI * 1.2, 20, Color("00ffff", 0.75), 1.5, true)
	draw_arc(core_pos, 13.0, rot_a + PI, rot_a + PI * 2.2, 20, Color("00ffff", 0.75), 1.5, true)

	# 7. Escudo Defensivo Ativo do Domo (Arco Energético Visível)
	if state.max_shield > 0.0 and state.shield > 0.0:
		var s_ratio: float = clampf(state.shield / state.max_shield, 0.0, 1.0)
		var s_col := Color("00f5d4")
		var shield_r: float = radius + 14.0 + sin(clock * 5.0) * 1.5

		# 7.1 Polígono do Campo de Força Translúcido entre domo e arco de escudo
		var field_pts := PackedVector2Array()
		for i in range(33):
			var ang: float = PI + (PI * float(i) / 32.0)
			field_pts.append(center + Vector2(cos(ang), sin(ang)) * shield_r)
		for i in range(32, -1, -1):
			var ang: float = PI + (PI * float(i) / 32.0)
			field_pts.append(center + Vector2(cos(ang), sin(ang)) * radius)
		draw_colored_polygon(field_pts, Color(s_col, 0.14 + 0.08 * sin(clock * 6.0) * s_ratio))

		# 7.2 Camadas de brilho (Glow) e linhas do arco de força
		for glow_w in [12.0, 7.0, 3.5]:
			draw_arc(center, shield_r, PI, TAU, 48, Color(s_col, 0.12 * s_ratio), glow_w, true)
		draw_arc(center, shield_r, PI, TAU, 48, Color(s_col, 0.9 * (0.6 + 0.4 * s_ratio)), 3.0, true)
		draw_arc(center, shield_r, PI, TAU, 48, Color.WHITE, 1.4, true)

		# 7.3 Nodos emissores de energia ao longo do arco
		var node_angles := [PI * 1.08, PI * 1.25, PI * 1.5, PI * 1.75, PI * 1.92]
		for a in node_angles:
			var n_pos := center + Vector2(cos(a), sin(a)) * shield_r
			draw_circle(n_pos, 3.5, s_col)
			draw_circle(n_pos, 1.8, Color.WHITE)
			draw_arc(n_pos, 6.0 + sin(clock * 10.0) * 1.2, 0, TAU, 16, Color(s_col, 0.7), 1.0, true)

		# 7.4 Arcos de pulsação secundários correndo no escudo
		var run_a: float = PI + fmod(clock * 2.5, PI * 0.7)
		draw_arc(center, shield_r + 2.0, run_a, run_a + PI * 0.25, 16, Color.WHITE, 2.0, true)

		# 7.5 Status numérico do escudo flutuando sobre o arco
		text_at("ESCUDO %d / %d" % [roundi(state.shield), roundi(state.max_shield)], center - Vector2(0, shield_r + 8.0), s_col, 9)

	# 8. Identificação Tática e Indicador de Vida (% HP)
	var hp_pct: int = roundi(float(state.hp) / float(maxi(1, state.max_hp)) * 100.0)
	var hp_col := base_color if hp_pct > 35 else Color("ff3355")
	text_at("%d%% HP" % hp_pct, center - Vector2(0, radius * 0.48), hp_col, 10)
	text_at("BASE // NÚCLEO", center + Vector2(0, 18), Color(base_color, 0.85), 10)
