class_name NeonIcons
extends RefCounted
## Ãcones vetoriais neon desenhados proceduralmente (UI, torres e inimigos).
## Uso: conectar ao sinal draw de um Control e chamar NeonIcons.draw_*(control, ...).

const PINK := GameData.PINK
const CYAN := GameData.CYAN
const LIME := GameData.LIME
const AMBER := GameData.AMBER
const MUTED := GameData.MUTED
const COLORS := GameData.PIECE_COLORS
const MODULE_INFO := GameData.MODULE_INFO
const DISPLAY = preload("res://assets/fonts/DisplayBold.tres")
const BODY = preload("res://assets/fonts/Rajdhani.ttf")

static func draw_tower(control: Control, module_id: String, base_radius: float = 16.0, custom_center: Vector2 = Vector2(-1, -1)) -> void:
	var center: Vector2 = custom_center if custom_center.x >= 0.0 else control.size * 0.5
	var color: Color = MODULE_INFO.get(module_id, ["", "", PINK])[2]
	var dir := Vector2.UP # Mirando para cima
	var scale_factor: float = base_radius / 16.0

	# Anel externo da torreta com fundo escuro
	var outer_r: float = base_radius + 4.0 * scale_factor
	control.draw_circle(center, outer_r, Color("0b061c"))
	control.draw_arc(center, outer_r, 0.0, TAU, 24, Color(color, 0.35), maxf(1.0, 1.5 * scale_factor), true)
	control.draw_circle(center, base_radius, Color("140933"))
	control.draw_arc(center, base_radius, 0.0, TAU, 24, color, maxf(1.0, 2.0 * scale_factor), true)

	# Silhuetas distintivas de cada arma
	match module_id:
		"plasma":
			# Canhão principal de plasma frontal + núcleo brilhante
			control.draw_line(center, center + dir * (base_radius + 9.0 * scale_factor), color, maxf(1.5, 4.0 * scale_factor), true)
			control.draw_line(center, center + dir * (base_radius + 9.0 * scale_factor), Color.WHITE, maxf(1.0, 1.5 * scale_factor), true)
			control.draw_circle(center, maxf(1.5, 4.0 * scale_factor), Color.WHITE)
		"cryo":
			# Canhão ciano com aletas refrigeradoras em cruz
			control.draw_line(center, center + dir * (base_radius + 8.0 * scale_factor), color, maxf(1.5, 3.5 * scale_factor), true)
			var wing: Vector2 = dir.orthogonal() * (7.0 * scale_factor)
			control.draw_line(center + dir * (6.0 * scale_factor) - wing, center + dir * (6.0 * scale_factor) + wing, color, maxf(1.0, 2.0 * scale_factor), true)
			control.draw_line(center + dir * (12.0 * scale_factor) - wing * 0.6, center + dir * (12.0 * scale_factor) + wing * 0.6, Color.WHITE, maxf(1.0, 1.5 * scale_factor), true)
		"arc":
			# Bobina tesla dupla para condutores de choque
			for side in [-1, 1]:
				var offset: Vector2 = dir.orthogonal() * (float(side) * 6.0 * scale_factor)
				control.draw_line(center + offset, center + offset + dir * (base_radius + 8.0 * scale_factor), color, maxf(1.0, 2.5 * scale_factor), true)
				control.draw_circle(center + offset + dir * (base_radius + 8.0 * scale_factor), maxf(1.2, 2.5 * scale_factor), Color.WHITE)
			control.draw_line(center - dir.orthogonal() * (6.0 * scale_factor), center + dir.orthogonal() * (6.0 * scale_factor), Color(color, 0.7), maxf(1.0, 1.5 * scale_factor), true)
		"pulse":
			# Emissor sísmico com anéis concêntricos de choque
			control.draw_arc(center, base_radius * 0.5, 0.0, TAU, 16, Color.WHITE, maxf(1.0, 2.0 * scale_factor), true)
			control.draw_arc(center, base_radius + 7.0 * scale_factor, 0.0, TAU, 20, Color(color, 0.8), maxf(1.0, 2.0 * scale_factor), true)
			control.draw_circle(center, maxf(1.5, 3.0 * scale_factor), color)
		"laser":
			# Projetor óptico com lentes convergentes pontiagudas
			control.draw_line(center - dir.orthogonal() * (5.0 * scale_factor), center + dir * (base_radius + 10.0 * scale_factor), color, maxf(1.0, 2.5 * scale_factor), true)
			control.draw_line(center + dir.orthogonal() * (5.0 * scale_factor), center + dir * (base_radius + 10.0 * scale_factor), color, maxf(1.0, 2.5 * scale_factor), true)
			control.draw_line(center, center + dir * (base_radius + 10.0 * scale_factor), Color.WHITE, maxf(1.0, 2.0 * scale_factor), true)
			control.draw_circle(center + dir * (base_radius + 10.0 * scale_factor), maxf(1.5, 3.0 * scale_factor), Color("ff88aa"))
		"vortex":
			# Singularidade giratória com anéis espirais duplos
			control.draw_arc(center, base_radius * 0.6, 0.0, TAU * 0.8, 16, color, maxf(1.2, 2.5 * scale_factor), true)
			control.draw_arc(center, base_radius + 6.0 * scale_factor, PI * 0.5, PI * 0.5 + TAU * 0.8, 20, Color(color, 0.8), maxf(1.0, 2.0 * scale_factor), true)
			control.draw_circle(center, maxf(1.5, 4.0 * scale_factor), Color("050014"))
		"railgun":
			# Trilhos magnéticos paralelos com bobinas de aceleração
			var rail_norm: Vector2 = dir.orthogonal() * (4.0 * scale_factor)
			control.draw_line(center - rail_norm, center - rail_norm + dir * (base_radius + 11.0 * scale_factor), color, maxf(1.0, 2.0 * scale_factor), true)
			control.draw_line(center + rail_norm, center + rail_norm + dir * (base_radius + 11.0 * scale_factor), color, maxf(1.0, 2.0 * scale_factor), true)
			control.draw_line(center + dir * (5.0 * scale_factor) - rail_norm * 1.3, center + dir * (5.0 * scale_factor) + rail_norm * 1.3, Color.WHITE, maxf(1.0, 1.5 * scale_factor), true)
			control.draw_line(center + dir * (11.0 * scale_factor) - rail_norm * 1.3, center + dir * (11.0 * scale_factor) + rail_norm * 1.3, Color.WHITE, maxf(1.0, 1.5 * scale_factor), true)

static func draw_ui(control: Control, icon_id: String, base_radius: float = 12.0, custom_center: Vector2 = Vector2(-1, -1), color: Color = CYAN) -> void:
	var center: Vector2 = custom_center if custom_center.x >= 0.0 else control.size * 0.5
	var s: float = base_radius / 12.0
	var outer_r: float = base_radius + 3.5 * s
	# Halo neon escuro e anel de moldura geométrica
	control.draw_circle(center, outer_r, Color("0b061c"))
	control.draw_arc(center, outer_r, 0.0, TAU, 24, Color(color, 0.32), maxf(1.0, 1.4 * s), true)
	control.draw_circle(center, base_radius, Color("140933"))
	control.draw_arc(center, base_radius, 0.0, TAU, 24, Color(color, 0.75), maxf(1.0, 1.6 * s), true)

	match icon_id:
		"attack", "click_dmg":
			# Mira de plasma com losango energético central e 4 hastes
			for k in 4:
				var dir := Vector2.from_angle(k * PI * 0.5)
				control.draw_line(center + dir * (4.0 * s), center + dir * (base_radius + 2.5 * s), color, maxf(1.2, 2.0 * s), true)
			var diamond := PackedVector2Array([
				center + Vector2(0, -4.5 * s),
				center + Vector2(4.5 * s, 0),
				center + Vector2(0, 4.5 * s),
				center + Vector2(-4.5 * s, 0)
			])
			control.draw_colored_polygon(diamond, Color.WHITE)
		"towers":
			# Torreta dupla com base hexagonal e canhões gêmeos
			for side in [-1.0, 1.0]:
				var bx: float = side * 3.2 * s
				control.draw_line(center + Vector2(bx, 2.0 * s), center + Vector2(bx, -base_radius - 1.5 * s), color, maxf(1.2, 2.2 * s), true)
				control.draw_circle(center + Vector2(bx, -base_radius - 1.5 * s), maxf(1.2, 1.8 * s), Color.WHITE)
			control.draw_arc(center + Vector2(0, 2.0 * s), 5.0 * s, 0.0, TAU, 16, Color.WHITE, maxf(1.0, 1.6 * s), true)
		"defense", "shield_cap":
			# Escudo hexagonal energético com núcleo brilhante
			var pts := PackedVector2Array([
				center + Vector2(0, -8.5 * s),
				center + Vector2(7.0 * s, -4.0 * s),
				center + Vector2(5.8 * s, 4.5 * s),
				center + Vector2(0, 8.8 * s),
				center + Vector2(-5.8 * s, 4.5 * s),
				center + Vector2(-7.0 * s, -4.0 * s),
				center + Vector2(0, -8.5 * s)
			])
			control.draw_colored_polygon(pts.slice(0, 6), Color(color, 0.25))
			control.draw_polyline(pts, color, maxf(1.3, 2.0 * s), true)
			control.draw_circle(center, maxf(1.5, 2.5 * s), Color.WHITE)
		"eye_on", "eye_off":
			# Visor cibernético neon (olho geométrico)
			var top_arc := PackedVector2Array([
				center + Vector2(-8.5 * s, 0),
				center + Vector2(-3.5 * s, -5.0 * s),
				center + Vector2(3.5 * s, -5.0 * s),
				center + Vector2(8.5 * s, 0),
				center + Vector2(3.5 * s, 5.0 * s),
				center + Vector2(-3.5 * s, 5.0 * s),
				center + Vector2(-8.5 * s, 0)
			])
			control.draw_polyline(top_arc, color, maxf(1.2, 1.8 * s), true)
			control.draw_circle(center, maxf(1.5, 2.6 * s), Color.WHITE if icon_id == "eye_on" else color)
			if icon_id == "eye_off":
				control.draw_line(center + Vector2(-7.0 * s, 6.5 * s), center + Vector2(7.0 * s, -6.5 * s), PINK, maxf(1.4, 2.2 * s), true)
		"lock":
			# Cadeado holográfico geométrico
			control.draw_arc(center + Vector2(0, -2.5 * s), 4.2 * s, PI, TAU, 16, color, maxf(1.2, 2.0 * s), true)
			var rect := Rect2(center + Vector2(-5.5 * s, -2.0 * s), Vector2(11.0 * s, 8.5 * s))
			control.draw_rect(rect, Color("0b061c"), true)
			control.draw_rect(rect, color, false, maxf(1.2, 1.8 * s))
			control.draw_circle(center + Vector2(0, 2.2 * s), maxf(1.2, 1.8 * s), Color.WHITE)
		"crit_chance":
			# Estrela crítica de 4 pontas
			var star := PackedVector2Array()
			for k in 8:
				var ang: float = k * PI * 0.25 - PI * 0.5
				var r: float = (8.5 * s) if (k % 2 == 0) else (3.0 * s)
				star.append(center + Vector2.from_angle(ang) * r)
			control.draw_colored_polygon(star, color)
			control.draw_circle(center, maxf(1.4, 2.2 * s), Color.WHITE)
		"crit_mult":
			# Duplo chevron ascendente de potência letal
			for idx in [-1, 1]:
				var y_off: float = idx * 2.8 * s
				var chev := PackedVector2Array([
					center + Vector2(-5.5 * s, y_off + 2.5 * s),
					center + Vector2(0, y_off - 3.0 * s),
					center + Vector2(5.5 * s, y_off + 2.5 * s)
				])
				control.draw_polyline(chev, Color.WHITE if idx == -1 else color, maxf(1.3, 2.2 * s), true)
		"combo_drive":
			# Raio de corrente de combo
			var bolt := PackedVector2Array([
				center + Vector2(2.0 * s, -8.0 * s),
				center + Vector2(-4.5 * s, -0.5 * s),
				center + Vector2(1.5 * s, -0.5 * s),
				center + Vector2(-2.0 * s, 8.0 * s)
			])
			control.draw_polyline(bolt, Color.WHITE, maxf(1.4, 2.2 * s), true)
		"click_splash":
			# Anéis concêntricos de impacto em área
			control.draw_arc(center, 4.2 * s, 0.0, TAU, 16, Color.WHITE, maxf(1.2, 1.8 * s), true)
			control.draw_arc(center, 8.0 * s, 0.0, TAU, 20, color, maxf(1.0, 1.6 * s), true)
			control.draw_circle(center, maxf(1.4, 2.0 * s), color)
		"nova_overdrive":
			# Supernova de 8 raios
			for k in 8:
				var dir := Vector2.from_angle(k * PI * 0.25)
				var len_r: float = (8.5 * s) if (k % 2 == 0) else (5.5 * s)
				control.draw_line(center, center + dir * len_r, Color.WHITE if (k % 2 == 0) else color, maxf(1.2, 1.8 * s), true)
			control.draw_circle(center, maxf(1.8, 2.8 * s), Color.WHITE)
		"tower_haste":
			# Setas duplas de cadência acelerada
			for idx in [-1, 1]:
				var x_off: float = idx * 2.6 * s
				var arr := PackedVector2Array([
					center + Vector2(x_off - 2.5 * s, -5.0 * s),
					center + Vector2(x_off + 3.0 * s, 0),
					center + Vector2(x_off - 2.5 * s, 5.0 * s)
				])
				control.draw_polyline(arr, Color.WHITE if idx == 1 else color, maxf(1.3, 2.0 * s), true)
		"tower_range":
			# Radar de longo alcance
			control.draw_arc(center + Vector2(0, 3.0 * s), 5.0 * s, -PI * 0.85, -PI * 0.15, 14, color, maxf(1.2, 1.8 * s), true)
			control.draw_arc(center + Vector2(0, 3.0 * s), 8.8 * s, -PI * 0.85, -PI * 0.15, 18, Color.WHITE, maxf(1.2, 1.8 * s), true)
			control.draw_circle(center + Vector2(0, 3.5 * s), maxf(1.5, 2.4 * s), color)
		"tower_pierce":
			# Lança perfurante anti-titã
			control.draw_line(center + Vector2(-7.0 * s, 7.0 * s), center + Vector2(7.0 * s, -7.0 * s), Color.WHITE, maxf(1.4, 2.2 * s), true)
			var tip := PackedVector2Array([
				center + Vector2(1.5 * s, -7.0 * s),
				center + Vector2(7.0 * s, -7.0 * s),
				center + Vector2(7.0 * s, -1.5 * s)
			])
			control.draw_polyline(tip, color, maxf(1.4, 2.2 * s), true)
		"tower_synergy":
			# Tríade sincronizada de nós de bateria
			var nodes := PackedVector2Array()
			for k in 3:
				var p := center + Vector2.from_angle(k * TAU / 3.0 - PI * 0.5) * (6.2 * s)
				nodes.append(p)
			nodes.append(nodes[0])
			control.draw_polyline(nodes, color, maxf(1.1, 1.6 * s), true)
			for k in 3:
				control.draw_circle(nodes[k], maxf(1.6, 2.4 * s), Color.WHITE)
		"base_hull", "hull_vitality":
			# Cruz de integridade estrutural de titânio
			var arm: float = 6.5 * s
			control.draw_line(center + Vector2(-arm, 0), center + Vector2(arm, 0), color, maxf(1.8, 3.2 * s), true)
			control.draw_line(center + Vector2(0, -arm), center + Vector2(0, arm), color, maxf(1.8, 3.2 * s), true)
			control.draw_circle(center, maxf(1.5, 2.2 * s), Color.WHITE)
		"nano_regen":
			# Órbita de nanorreparo
			control.draw_line(center + Vector2(-4.5 * s, 0), center + Vector2(4.5 * s, 0), Color.WHITE, maxf(1.4, 2.2 * s), true)
			control.draw_line(center + Vector2(0, -4.5 * s), center + Vector2(0, 4.5 * s), Color.WHITE, maxf(1.4, 2.2 * s), true)
			for k in 3:
				var orb := center + Vector2.from_angle(k * TAU / 3.0) * (7.5 * s)
				control.draw_circle(orb, maxf(1.3, 2.0 * s), color)
		"reactive_plating":
			# Placas de blindagem reativa em losango duplo
			for scale_r in [4.5, 8.0]:
				var d := PackedVector2Array([
					center + Vector2(0, -scale_r * s),
					center + Vector2(scale_r * s, 0),
					center + Vector2(0, scale_r * s),
					center + Vector2(-scale_r * s, 0),
					center + Vector2(0, -scale_r * s)
				])
				control.draw_polyline(d, Color.WHITE if scale_r < 6.0 else color, maxf(1.2, 1.8 * s), true)
		"shield_regen":
			# Anel de recarga harmônica de escudo
			control.draw_arc(center, 6.5 * s, 0.3, PI - 0.3, 14, color, maxf(1.3, 2.0 * s), true)
			control.draw_arc(center, 6.5 * s, PI + 0.3, TAU - 0.3, 14, Color.WHITE, maxf(1.3, 2.0 * s), true)
			control.draw_circle(center, maxf(1.6, 2.5 * s), color)
		"shield_pulse":
			# Escudo com onda de repulsão externa
			control.draw_arc(center, 4.5 * s, 0.0, TAU, 16, Color.WHITE, maxf(1.2, 1.8 * s), true)
			control.draw_arc(center, 8.2 * s, -PI * 0.75, -PI * 0.25, 14, color, maxf(1.4, 2.2 * s), true)
			control.draw_arc(center, 8.2 * s, PI * 0.25, PI * 0.75, 14, color, maxf(1.4, 2.2 * s), true)
		"lab", "research":
			# Reator / Núcleo de Síntese Quântica com órbitas em elipse e anel
			control.draw_circle(center, maxf(2.0, 3.2 * s), Color.WHITE)
			control.draw_arc(center, 6.0 * s, 0.0, TAU, 20, color, maxf(1.2, 1.8 * s), true)
			var orb1 := PackedVector2Array([
				center + Vector2(-8.0 * s, -2.5 * s),
				center + Vector2(0, -6.5 * s),
				center + Vector2(8.0 * s, 2.5 * s),
				center + Vector2(0, 6.5 * s),
				center + Vector2(-8.0 * s, -2.5 * s)
			])
			control.draw_polyline(orb1, Color(color, 0.7), maxf(1.0, 1.4 * s), true)
			control.draw_circle(center + Vector2(6.5 * s, 2.0 * s), maxf(1.0, 1.5 * s), Color.WHITE)
		"economy":
			# Diamante / Losango cibernético com núcleo de prisma monetário
			var diamond_pts := PackedVector2Array([
				center + Vector2(0, -8.0 * s),
				center + Vector2(7.0 * s, 0),
				center + Vector2(0, 8.0 * s),
				center + Vector2(-7.0 * s, 0),
				center + Vector2(0, -8.0 * s)
			])
			control.draw_polyline(diamond_pts, color, maxf(1.3, 2.0 * s), true)
			control.draw_circle(center, maxf(1.5, 2.5 * s), Color.WHITE)
			control.draw_line(center + Vector2(0, -4.5 * s), center + Vector2(0, 4.5 * s), Color.WHITE, maxf(1.0, 1.5 * s), true)
		"piece_0", "piece_square":
			var sq_r: float = 6.0 * s
			var sq := Rect2(center - Vector2(sq_r, sq_r), Vector2(sq_r * 2.0, sq_r * 2.0))
			control.draw_rect(sq, Color(color, 0.35), true)
			control.draw_rect(sq, color, false, maxf(1.2, 1.8 * s))
			control.draw_circle(center, maxf(1.0, 1.8 * s), Color.WHITE)
		"piece_1", "piece_triangle":
			var tri_r: float = 7.0 * s
			var tri := PackedVector2Array([
				center + Vector2(0, -tri_r),
				center + Vector2(tri_r * 0.9, tri_r * 0.65),
				center + Vector2(-tri_r * 0.9, tri_r * 0.65),
				center + Vector2(0, -tri_r)
			])
			control.draw_colored_polygon(tri.slice(0, 3), Color(color, 0.35))
			control.draw_polyline(tri, color, maxf(1.2, 1.8 * s), true)
			control.draw_circle(center + Vector2(0, 1.0 * s), maxf(1.0, 1.8 * s), Color.WHITE)
		"piece_2", "piece_hexagon":
			var hex_r: float = 6.8 * s
			var hex_pts := PackedVector2Array()
			for k in 6:
				hex_pts.append(center + Vector2.from_angle(k * TAU / 6.0) * hex_r)
			hex_pts.append(hex_pts[0])
			control.draw_colored_polygon(hex_pts.slice(0, 6), Color(color, 0.35))
			control.draw_polyline(hex_pts, color, maxf(1.2, 1.8 * s), true)
			control.draw_circle(center, maxf(1.0, 1.8 * s), Color.WHITE)
		"piece_3", "piece_core":
			var core_r: float = 7.5 * s
			for k in 4:
				var dir := Vector2.from_angle(k * PI * 0.5)
				control.draw_line(center - dir * core_r, center + dir * core_r, color, maxf(1.2, 1.8 * s), true)
			for k in 4:
				var dir := Vector2.from_angle(k * PI * 0.5 + PI * 0.25)
				control.draw_line(center - dir * (core_r * 0.5), center + dir * (core_r * 0.5), Color(color, 0.7), maxf(1.0, 1.4 * s), true)
			control.draw_circle(center, maxf(1.5, 2.5 * s), Color.WHITE)
		"codex", "codex_all", "all":
			# Visor de varredura global / matriz de detecção
			for i in 4:
				var ang: float = i * PI * 0.5 + PI * 0.25
				var pt := center + Vector2.from_angle(ang) * (5.5 * s)
				control.draw_circle(pt, maxf(1.2, 1.8 * s), color)
			control.draw_arc(center, 7.5 * s, 0.0, TAU, 16, Color(color, 0.5), maxf(1.0, 1.4 * s), true)
			control.draw_circle(center, maxf(1.5, 2.2 * s), Color.WHITE)
		"codex_common", "common":
			# Polígono geométrico regular padrão dos espécimes comuns
			var poly := PackedVector2Array([
				center + Vector2(0, -6.5 * s),
				center + Vector2(6.5 * s, 0),
				center + Vector2(0, 6.5 * s),
				center + Vector2(-6.5 * s, 0),
				center + Vector2(0, -6.5 * s)
			])
			control.draw_polyline(poly, color, maxf(1.3, 1.8 * s), true)
			control.draw_circle(center, maxf(1.5, 2.2 * s), Color.WHITE)
		"codex_shields", "shields":
			# Escudo de barreira energética fortificada
			var sh_pts := PackedVector2Array([
				center + Vector2(0, -7.5 * s),
				center + Vector2(6.5 * s, -3.5 * s),
				center + Vector2(5.5 * s, 4.0 * s),
				center + Vector2(0, 7.5 * s),
				center + Vector2(-5.5 * s, 4.0 * s),
				center + Vector2(-6.5 * s, -3.5 * s),
				center + Vector2(0, -7.5 * s)
			])
			control.draw_colored_polygon(sh_pts.slice(0, 6), Color(color, 0.25))
			control.draw_polyline(sh_pts, color, maxf(1.3, 2.0 * s), true)
			control.draw_line(center + Vector2(-3.5 * s, 0), center + Vector2(3.5 * s, 0), Color.WHITE, maxf(1.0, 1.5 * s), true)
		"codex_shooters", "shooters":
			# Mira e canhão emissor de projéteis
			control.draw_line(center + Vector2(0, 4.0 * s), center + Vector2(0, -7.5 * s), color, maxf(1.4, 2.5 * s), true)
			control.draw_circle(center + Vector2(0, -7.5 * s), maxf(1.2, 1.8 * s), Color.WHITE)
			control.draw_arc(center, 5.5 * s, -PI * 0.8, -PI * 0.2, 12, Color.WHITE, maxf(1.0, 1.5 * s), true)
			control.draw_circle(center + Vector2(0, 2.0 * s), maxf(1.5, 2.2 * s), color)
		"codex_elites", "elites":
			# Insígnia de comandante de elite estrelada
			for i in 4:
				var dir := Vector2.from_angle(i * PI * 0.5)
				control.draw_line(center, center + dir * (7.5 * s), color, maxf(1.4, 2.2 * s), true)
			control.draw_circle(center, maxf(1.8, 2.5 * s), Color.WHITE)
		"codex_bosses", "bosses":
			# Coroa cibernética / brasão supremo de chefes
			var crown := PackedVector2Array([
				center + Vector2(-7.0 * s, -5.5 * s),
				center + Vector2(-4.0 * s, 1.0 * s),
				center + Vector2(0, -7.0 * s),
				center + Vector2(4.0 * s, 1.0 * s),
				center + Vector2(7.0 * s, -5.5 * s),
				center + Vector2(5.5 * s, 6.0 * s),
				center + Vector2(-5.5 * s, 6.0 * s),
				center + Vector2(-7.0 * s, -5.5 * s)
			])
			control.draw_colored_polygon(crown.slice(0, 7), Color(color, 0.25))
			control.draw_polyline(crown, color, maxf(1.3, 2.0 * s), true)
			control.draw_circle(center + Vector2(0, -1.0 * s), maxf(1.5, 2.2 * s), Color.WHITE)
		_:
			control.draw_circle(center, maxf(2.0, 3.5 * s), Color.WHITE)

static func draw_piece_icon(control: Control, kind: int, size: float = 14.0, custom_center: Vector2 = Vector2(-1, -1)) -> void:
	var center: Vector2 = custom_center if custom_center.x >= 0.0 else control.size * 0.5
	var color: Color = COLORS[kind] if kind >= 0 and kind < COLORS.size() else AMBER
	var icon_key := "piece_%d" % kind
	draw_ui(control, icon_key, size * 0.5, center, color)

static func draw_enemy(control: Control, enemy_id: String) -> void:
	var center := control.size * 0.5
	var radius := 24.0
	var sides := 4
	var color := VoidState.COLORS[0]
	var variant := ""
	var is_elite := false
	var is_boss := false
	var has_cannon := false
	var has_dual_cannon := false
	var has_teleport := false
	var has_summon := false

	match enemy_id:
		"square":
			sides = 4; color = VoidState.COLORS[0]
		"armored_square":
			sides = 4; color = VoidState.COLORS[0]; variant = "armored"
		"splitter":
			sides = 4; color = VoidState.COLORS[0]; variant = "splitter"
		"triangle":
			sides = 3; color = VoidState.COLORS[1]
		"ghost_triangle":
			sides = 3; color = VoidState.COLORS[1]; variant = "ghost"
		"thief":
			sides = 3; color = VoidState.COLORS[1]; variant = "thief"
		"pentagon":
			sides = 5; color = VoidState.COLORS[4]
		"hexagon":
			sides = 6; color = VoidState.COLORS[2]
		"regen_hexagon":
			sides = 6; color = VoidState.COLORS[2]; variant = "regen"
		"heptagon":
			sides = 7; color = VoidState.COLORS[5]
		"octagon":
			sides = 8; color = VoidState.COLORS[6]
		"nonagon":
			sides = 9; color = VoidState.COLORS[7]
		"decagon":
			sides = 10; color = VoidState.COLORS[8]
		"hendecagon":
			sides = 11; color = VoidState.COLORS[9]
		"dodecagon":
			sides = 12; color = VoidState.COLORS[10]
		"star4":
			sides = 4; color = VoidState.COLORS[11]
		"star5":
			sides = 5; color = VoidState.COLORS[12]
		"ring_prism":
			sides = 6; color = VoidState.COLORS[13]
		"spiral_singularity":
			sides = 12; color = VoidState.COLORS[14]
		"titan_tetrahedron":
			sides = 4; color = VoidState.COLORS[15]
		"void_shooter":
			sides = 6; color = VoidState.COLORS[16]; has_cannon = true
		"quantum_teleporter":
			sides = 6; color = VoidState.COLORS[17]; has_teleport = true
		"hive_summoner":
			sides = 8; color = VoidState.COLORS[18]; has_summon = true
		"plasma_artillery":
			sides = 10; color = VoidState.COLORS[19]; has_dual_cannon = true
		"rift_weaver":
			sides = 7; color = VoidState.COLORS[20]; has_teleport = true; has_summon = true
		"elite":
			sides = 5; color = AMBER; is_elite = true
		"elite_vanguard":
			sides = 6; color = Color("ffb02e"); is_elite = true; variant = "armored"
		"elite_phantom":
			sides = 5; color = Color("00f5d4"); is_elite = true; has_teleport = true
		"elite_artillery":
			sides = 6; color = Color("ff4d6d"); is_elite = true; has_cannon = true
		"elite_overlord":
			sides = 8; color = Color("e056fd"); is_elite = true; has_summon = true
		"elite_berserker":
			sides = 7; color = Color("ff7f50"); is_elite = true
		"elite_storm":
			sides = 6; color = Color("fee440"); is_elite = true; has_cannon = true; has_teleport = true
		"boss":
			sides = 8; color = Color("ffb02e"); is_boss = true; has_dual_cannon = true
		"boss_colossus":
			sides = 10; color = Color("ff3b30"); is_boss = true; has_summon = true; variant = "regen"
		"boss_primordial":
			sides = 12; color = Color("00f2fe"); is_boss = true; has_teleport = true; has_dual_cannon = true
		"boss_nexus":
			sides = 8; color = Color("c471ed"); is_boss = true; has_summon = true
		"boss_leviathan":
			sides = 16; color = Color("00ff87"); is_boss = true; has_dual_cannon = true; variant = "armored"
		"boss_omega":
			sides = 10; color = Color("ff007f"); is_boss = true; has_teleport = true; has_summon = true; has_dual_cannon = true

	var rot: float = -PI / 2.0 if sides == 3 else 0.0
	var points := PackedVector2Array()
	var outer := PackedVector2Array()

	if enemy_id == "star4":
		for i in 8:
			var angle: float = rot + i * PI / 4.0
			var r: float = radius if (i % 2 == 0) else radius * 0.45
			points.append(center + Vector2.from_angle(angle) * r)
			outer.append(center + Vector2.from_angle(angle) * (r + 4))
	elif enemy_id == "star5":
		for i in 10:
			var angle: float = rot + i * PI / 5.0
			var r: float = radius if (i % 2 == 0) else radius * 0.48
			points.append(center + Vector2.from_angle(angle) * r)
			outer.append(center + Vector2.from_angle(angle) * (r + 4))
	elif enemy_id == "quantum_teleporter":
		for i in 12:
			var angle: float = rot + i * PI / 6.0
			var r: float = radius if (i % 2 == 0) else radius * 0.46
			points.append(center + Vector2.from_angle(angle) * r)
			outer.append(center + Vector2.from_angle(angle) * (r + 4))
	elif enemy_id == "rift_weaver":
		for i in 14:
			var angle: float = rot + i * PI / 7.0
			var r: float = radius if (i % 2 == 0) else radius * 0.44
			points.append(center + Vector2.from_angle(angle) * r)
			outer.append(center + Vector2.from_angle(angle) * (r + 4))
	elif enemy_id in ["boss_nexus", "boss_omega"]:
		var star_pts: int = 20 if enemy_id == "boss_omega" else 16
		for i in star_pts:
			var angle: float = rot + i * TAU / float(star_pts)
			var r: float = radius if (i % 2 == 0) else radius * 0.56
			points.append(center + Vector2.from_angle(angle) * r)
			outer.append(center + Vector2.from_angle(angle) * (r + 5))
	else:
		for i in sides:
			var dir := Vector2.from_angle(rot + i * TAU / sides)
			points.append(center + dir * radius)
			outer.append(center + dir * (radius + 5))

	control.draw_colored_polygon(outer, Color(color, 0.2))
	var body_color := color.darkened(0.5)
	control.draw_colored_polygon(points, body_color)

	var num_pts: int = points.size()
	for i in num_pts:
		var edge_color := color.darkened(0.55)
		control.draw_polygon(
			PackedVector2Array([center, points[i], points[(i + 1) % num_pts]]),
			PackedColorArray([color, edge_color, edge_color])
		)

	var loop := points.duplicate()
	loop.append(points[0])
	control.draw_polyline(loop, color, 2.5, true)
	control.draw_circle(center, maxf(2.5, radius * 0.22), Color(1, 1, 1, 0.9))

	# Acessórios específicos
	if enemy_id == "ring_prism":
		control.draw_arc(center, radius + 7, 0, TAU, 24, Color(color, 0.7), 2.0, true)
	elif enemy_id == "spiral_singularity":
		control.draw_arc(center, radius + 8, 0, TAU * 0.8, 28, Color(color, 0.8), 2.5, true)
		control.draw_circle(center, 4.0, Color("050014"))
	elif enemy_id == "titan_tetrahedron":
		control.draw_arc(center, radius + 9, 0, TAU, 32, Color(color, 0.85), 2.5, true)

	if has_cannon:
		var b_start: Vector2 = center + Vector2(0, radius * 0.55)
		var b_end: Vector2 = center + Vector2(0, radius + 8.0)
		control.draw_line(b_start, b_end, color, 3.0, true)
		control.draw_circle(b_end, 2.5, Color.WHITE)
	if has_dual_cannon:
		for s in [-1.0, 1.0]:
			var bs: Vector2 = center + Vector2(s * radius * 0.4, radius * 0.5)
			var be: Vector2 = bs + Vector2(0, 8.0)
			control.draw_line(bs, be, color, 2.5, true)
			control.draw_circle(be, 2.0, Color.WHITE)
	if has_teleport:
		control.draw_arc(center, radius + 5, 0.2, PI - 0.2, 14, Color("00f5d4", 0.9), 2.0, true)
		control.draw_arc(center, radius + 5, PI + 0.2, TAU - 0.2, 14, Color("00f5d4", 0.9), 2.0, true)
	if has_summon:
		for k in 3:
			var orb_ang: float = float(k) * TAU / 3.0 - PI / 2.0
			var orb_pos: Vector2 = center + Vector2.from_angle(orb_ang) * (radius + 7.5)
			control.draw_circle(orb_pos, 3.0, color)
			control.draw_circle(orb_pos, 1.4, Color.WHITE)

	# Acessórios de variantes
	if variant == "armored":
		control.draw_arc(center, radius + 7, 0, TAU, 16, Color(0.8, 0.85, 1, 0.8), 2.5, true)
	elif variant == "regen":
		control.draw_arc(center, radius + 6, -PI / 2, -PI / 2 + TAU * 0.75, 24, Color(0.71, 1, 0.18, 0.85), 2.0, true)
	elif variant == "ghost":
		control.draw_arc(center, radius + 5, 0, TAU, 16, Color(VoidState.COLORS[1], 0.4), 1.5, true)
	elif variant == "splitter":
		control.draw_circle(center + Vector2(-radius * 0.4, 0), 2.5, Color.WHITE)
		control.draw_circle(center + Vector2(radius * 0.4, 0), 2.5, Color.WHITE)
	elif variant == "thief":
		var font: Font = DISPLAY
		control.draw_string(font, center + Vector2(-4, 5), "$", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color("ffb02e"))
	if is_elite:
		control.draw_arc(center, radius + 9, 0, TAU * 0.75, 28, color.lightened(0.2), 2.5, true)
	elif is_boss:
		control.draw_arc(center, radius + 9, 0, TAU, 32, Color(color, 0.75), 2.2, true)
		control.draw_arc(center, radius + 12, 0, TAU * 0.65, 24, Color(color.lightened(0.3), 0.55), 1.5, true)
