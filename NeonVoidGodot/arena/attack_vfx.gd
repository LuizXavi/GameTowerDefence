class_name AttackVFX
extends RefCounted
## Renderiza os efeitos visuais das armas das torretas (Plasma, Cryo, Arco, Laser, Vórtice, Railgun).

static func glow_line(canvas: CanvasItem, a: Vector2, b: Vector2, color: Color, width := 2.0) -> void:
	for w in [14.0, 8.0, 4.0]:
		canvas.draw_line(a, b, Color(color, 0.035), width + w, true)
	canvas.draw_line(a, b, color, width, true)

static func draw_plasma(canvas: CanvasItem, from: Vector2, to: Vector2, alpha: float) -> void:
	var dist: float = from.distance_to(to)
	var dir: Vector2 = (to - from).normalized()
	var normal: Vector2 = dir.orthogonal()
	var col_plasma := Color("ff2bd6")
	col_plasma.a = alpha

	var travel: float = clampf(1.0 - (alpha * 0.75), 0.15, 1.0)
	var head_pos: Vector2 = from.lerp(to, travel)
	var tail_len: float = minf(65.0, dist * 0.45)
	var tail_pos: Vector2 = head_pos - dir * tail_len

	var p_left: Vector2 = head_pos - dir * 14.0 + normal * 7.0
	var p_right: Vector2 = head_pos - dir * 14.0 - normal * 7.0
	canvas.draw_colored_polygon(PackedVector2Array([head_pos, p_left, tail_pos, p_right]), Color(col_plasma, 0.4 * alpha))
	glow_line(canvas, tail_pos, head_pos, col_plasma, 4.0)

	canvas.draw_circle(head_pos, 8.5, Color(col_plasma, 0.75 * alpha))
	canvas.draw_circle(head_pos, 5.0, Color(1, 0.65, 0.95, alpha))
	canvas.draw_circle(head_pos, 2.5, Color(1, 1, 1, alpha))

	canvas.draw_arc(head_pos, 11.0, 0, TAU, 16, Color(col_plasma, 0.5 * alpha), 1.5, true)
	if travel >= 0.7:
		canvas.draw_arc(to, 14.0 * (1.0 - alpha), 0, TAU, 16, Color(col_plasma, alpha), 2.0, true)

static func draw_cryo(canvas: CanvasItem, from: Vector2, to: Vector2, alpha: float, clock: float) -> void:
	var dir: Vector2 = (to - from).normalized()
	var normal: Vector2 = dir.orthogonal()
	var col_ice := Color("22e6ff")
	var col_frost := Color("a5f3fc")
	col_ice.a = alpha
	col_frost.a = alpha

	var spread_factors: Array[float] = [-1.0, -0.5, 0.0, 0.5, 1.0]
	for spread_factor: float in spread_factors:
		var spread_end: Vector2 = to + normal * (spread_factor * 24.0)
		canvas.draw_line(from, spread_end, Color(col_ice, 0.16 * alpha), 2.0 + absf(spread_factor) * 1.5, true)

	glow_line(canvas, from, to, Color(col_ice, 0.6 * alpha), 3.5)
	canvas.draw_line(from, to, Color(col_frost, 0.9 * alpha), 1.5, true)

	for c in range(1, 6):
		var t: float = float(c) / 6.0
		var c_pos: Vector2 = from.lerp(to, t) + normal * sin(t * 14.0 + clock * 12.0) * 8.0
		var c_size: float = 4.5 + sin(t * PI) * 3.5
		var d_top: Vector2 = c_pos + dir * c_size * 1.8
		var d_bot: Vector2 = c_pos - dir * c_size * 1.2
		var d_left: Vector2 = c_pos + normal * c_size
		var d_right: Vector2 = c_pos - normal * c_size
		canvas.draw_colored_polygon(PackedVector2Array([d_top, d_left, d_bot, d_right]), Color(col_frost, 0.8 * alpha))
		canvas.draw_polyline(PackedVector2Array([d_top, d_left, d_bot, d_right, d_top]), Color(col_ice, alpha), 1.5, true)

	var spoke_angles: Array[float] = [0.0, PI / 3.0, 2.0 * PI / 3.0]
	for a: float in spoke_angles:
		var spoke: Vector2 = Vector2.from_angle(a) * 12.0
		canvas.draw_line(to - spoke, to + spoke, Color(col_frost, alpha), 2.0, true)

static func draw_arc(canvas: CanvasItem, from: Vector2, to: Vector2, chain: Array, alpha: float, is_static_storm: bool, clock: float) -> void:
	var col_arc: Color = Color("c48aff") if not is_static_storm else Color("ffb02e")
	var col_core: Color = Color(1, 1, 1, alpha)
	col_arc.a = alpha

	var all_nodes: Array[Vector2] = [from, to]
	for p in chain:
		all_nodes.append(p)

	for seg in range(all_nodes.size() - 1):
		var p1: Vector2 = all_nodes[seg]
		var p2: Vector2 = all_nodes[seg + 1]
		var seg_dist: float = p1.distance_to(p2)
		var seg_dir: Vector2 = (p2 - p1).normalized()
		var seg_norm: Vector2 = seg_dir.orthogonal()

		var steps: int = maxi(6, int(seg_dist / 20.0))
		var lightning_pts := PackedVector2Array()
		lightning_pts.append(p1)

		for s in range(1, steps):
			var t: float = float(s) / float(steps)
			var seed_v: float = float(seg * 23 + s * 37)
			var offset_mag: float = (sin(clock * 55.0 + seed_v) * 0.65 + cos(clock * 40.0 + seed_v * 1.8) * 0.35) * 14.0
			if is_static_storm:
				offset_mag *= 1.45
			var pt: Vector2 = p1.lerp(p2, t) + seg_norm * offset_mag
			lightning_pts.append(pt)

			if s % 3 == 0:
				var fork_end: Vector2 = pt + (seg_dir + seg_norm * (1.0 if s % 2 == 0 else -1.0)).normalized() * 16.0
				canvas.draw_line(pt, fork_end, Color(col_arc, 0.6 * alpha), 1.2, true)

		lightning_pts.append(p2)

		glow_line(canvas, p1, p2, Color(col_arc, 0.25 * alpha), 8.0 if is_static_storm else 5.0)
		canvas.draw_polyline(lightning_pts, Color(col_arc, 0.9 * alpha), 3.2 if is_static_storm else 2.2, true)
		canvas.draw_polyline(lightning_pts, col_core, 1.2, true)

		canvas.draw_circle(p2, 5.0, Color(col_arc, alpha))
		canvas.draw_circle(p2, 2.5, Color.WHITE)

static func draw_laser(canvas: CanvasItem, from: Vector2, to: Vector2, focus_time: float, alpha: float, clock: float) -> void:
	var col_laser := Color("ff3355")
	var normal: Vector2 = (to - from).normalized().orthogonal()
	var dist: float = from.distance_to(to)

	var ramp_factor: float = clampf(focus_time / 2.0, 0.0, 1.0)
	var beam_core_w: float = 2.5 + ramp_factor * 5.0
	var beam_halo_w: float = 9.0 + ramp_factor * 15.0

	var jitter: Vector2 = normal * sin(clock * 70.0) * (0.8 + ramp_factor * 1.6)
	var j_from: Vector2 = from + jitter
	var j_to: Vector2 = to + jitter

	glow_line(canvas, j_from, j_to, Color(col_laser, 0.35 * alpha), beam_halo_w)
	glow_line(canvas, j_from, j_to, Color(col_laser, 0.75 * alpha), beam_core_w + 3.0)
	canvas.draw_line(j_from, j_to, Color(1, 0.9, 0.95, alpha), beam_core_w, true)

	var num_rings: int = maxi(3, int(dist / 60.0))
	for r in range(1, num_rings):
		var t: float = float(r) / float(num_rings)
		var ring_t: float = fmod(t + clock * 2.8, 1.0)
		var ring_pos: Vector2 = from.lerp(to, ring_t)
		var ring_radius: float = (5.5 + ramp_factor * 4.5) + sin(clock * 16.0 + r) * 1.5
		canvas.draw_line(ring_pos - normal * ring_radius, ring_pos + normal * ring_radius, Color(1, 0.82, 0.88, 0.85 * alpha), 2.5, true)
		canvas.draw_circle(ring_pos - normal * ring_radius, 2.2, Color(col_laser, alpha))
		canvas.draw_circle(ring_pos + normal * ring_radius, 2.2, Color(col_laser, alpha))

	var burn_radius: float = 6.5 + ramp_factor * 8.5
	canvas.draw_circle(to, burn_radius * 1.4, Color(col_laser, 0.6 * alpha))
	canvas.draw_circle(to, burn_radius, Color(1, 0.92, 0.8, alpha))
	canvas.draw_circle(to, burn_radius * 0.5, Color.WHITE)
	canvas.draw_arc(to, burn_radius * 1.8 + sin(clock * 25.0) * 2.0, 0, TAU, 20, Color(col_laser, alpha), 2.0, true)

static func draw_vortex(canvas: CanvasItem, from: Vector2, to: Vector2, alpha: float, clock: float) -> void:
	var col_vortex := Color("9933ff")
	col_vortex.a = alpha
	var col_inner := Color("d88aff")
	col_inner.a = alpha

	glow_line(canvas, from, to, Color(col_vortex, 0.35 * alpha), 4.0)
	canvas.draw_line(from, to, Color(col_inner, 0.7 * alpha), 1.5, true)

	var base_r: float = 18.0 + sin(clock * 12.0) * 3.0
	canvas.draw_arc(to, base_r * 2.2, clock * 5.0, clock * 5.0 + TAU * 0.8, 32, Color(col_vortex, 0.4 * alpha), 2.0, true)
	canvas.draw_arc(to, base_r * 1.5, -clock * 7.0, -clock * 7.0 + TAU * 0.85, 28, Color(col_vortex, 0.7 * alpha), 2.5, true)
	canvas.draw_arc(to, base_r, clock * 9.0, clock * 9.0 + TAU * 0.9, 24, Color(col_inner, 0.9 * alpha), 3.0, true)

	canvas.draw_circle(to, 12.0, Color("050014"))
	canvas.draw_circle(to, 6.0, Color("000000"))
	canvas.draw_arc(to, 12.0, 0, TAU, 24, Color(col_inner, alpha), 1.5, true)

	for i in 6:
		var ang: float = float(i) * (TAU / 6.0) + clock * 4.0
		var p_outer: Vector2 = to + Vector2.from_angle(ang) * (base_r * 2.8)
		var p_mid: Vector2 = to + Vector2.from_angle(ang + 0.6) * (base_r * 1.4)
		canvas.draw_line(p_outer, p_mid, Color(col_vortex, 0.5 * alpha), 1.5, true)

static func draw_railgun(canvas: CanvasItem, from: Vector2, wall_hit: Vector2, chain: Array, alpha: float) -> void:
	var col_rail := Color("33ffcc")
	col_rail.a = alpha
	var col_core := Color(1, 1, 1, alpha)

	glow_line(canvas, from, wall_hit, Color(col_rail, 0.4 * alpha), 10.0)
	glow_line(canvas, from, wall_hit, Color(col_rail, 0.85 * alpha), 4.5)
	canvas.draw_line(from, wall_hit, col_core, 2.0, true)

	var dist_1: float = from.distance_to(wall_hit)
	var dir_1: Vector2 = (wall_hit - from).normalized()
	var norm_1: Vector2 = dir_1.orthogonal()
	var rings_count: int = maxi(2, int(dist_1 / 90.0))
	for r in range(1, rings_count):
		var t: float = float(r) / float(rings_count)
		var r_pos: Vector2 = from.lerp(wall_hit, t)
		canvas.draw_line(r_pos - norm_1 * 9.0, r_pos + norm_1 * 9.0, Color(col_rail, 0.7 * alpha), 2.0, true)

	canvas.draw_circle(wall_hit, 8.0, Color(col_rail, alpha))
	canvas.draw_circle(wall_hit, 4.0, Color.WHITE)
	canvas.draw_arc(wall_hit, 16.0 * (1.0 - alpha * 0.5), 0, TAU, 20, Color(col_rail, alpha), 2.0, true)

	if not chain.is_empty():
		var bounce_end: Vector2 = chain[0]
		glow_line(canvas, wall_hit, bounce_end, Color(col_rail, 0.3 * alpha), 7.0)
		glow_line(canvas, wall_hit, bounce_end, Color(col_rail, 0.7 * alpha), 3.5)
		canvas.draw_line(wall_hit, bounce_end, col_core, 1.5, true)
		var dist_2: float = wall_hit.distance_to(bounce_end)
		var dir_2: Vector2 = (bounce_end - wall_hit).normalized()
		var norm_2: Vector2 = dir_2.orthogonal()
		var rings_count_2: int = maxi(1, int(dist_2 / 100.0))
		for r in range(1, rings_count_2):
			var t2: float = float(r) / float(rings_count_2)
			var r_pos2: Vector2 = wall_hit.lerp(bounce_end, t2)
			canvas.draw_line(r_pos2 - norm_2 * 7.0, r_pos2 + norm_2 * 7.0, Color(col_rail, 0.6 * alpha), 1.5, true)
