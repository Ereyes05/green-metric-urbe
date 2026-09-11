# ============================================================
# interior_bloque.gd — NIVEL 2: Energía (Misión LED)
# Interior navegable de un bloque universitario.
# El estudiante se mueve con WASD dentro del pasillo,
# llega a cada luminaria crítica y presiona E para abrirla.
# ============================================================
extends CanvasLayer

signal mision_interior_completada(mision_id: String, xp: int, ec: int)

# ── Datos de los edificios con misiones LED ──────────────────
const BLOQUES : Array = [
	{
		"id":     "led_bloque_a",
		"nombre": "Bloque A — Aulas de Clase",
		"desc":   "Reemplaza las luminarias incandescentes de 100W por tecnología LED con sensor de movimiento.",
		"spots":  [
			{"pos": Vector2(200, 130), "nombre": "Salón A-101"},
			{"pos": Vector2(500, 130), "nombre": "Salón A-102"},
			{"pos": Vector2(350, 280), "nombre": "Pasillo Principal"},
		]
	},
	{
		"id":     "led_bloque_b",
		"nombre": "Bloque B — Laboratorios",
		"desc":   "Los laboratorios de cómputo tienen luminarias de alto consumo. Instala LED inteligente.",
		"spots":  [
			{"pos": Vector2(160, 110), "nombre": "Lab. Redes"},
			{"pos": Vector2(400, 110), "nombre": "Lab. Programación"},
			{"pos": Vector2(640, 240), "nombre": "Sala de Servidores"},
		]
	},
	{
		"id":     "led_bloque_c",
		"nombre": "Bloque C — Oficinas Docentes",
		"desc":   "Las oficinas del cuerpo docente aún usan iluminación fluorescente. Migra a LED inteligente.",
		"spots":  [
			{"pos": Vector2(220, 160), "nombre": "Coord. Académica"},
			{"pos": Vector2(560, 200), "nombre": "Sala de Reuniones"},
		]
	},
	{
		"id":     "led_bloque_d",
		"nombre": "Bloque D — Administración",
		"desc":   "Las oficinas administrativas tienen luminarias fluorescentes de alto consumo. Instala LED inteligente para reducir el consumo energético.",
		"spots":  [
			{"pos": Vector2(200, 180), "nombre": "Dirección General"},
			{"pos": Vector2(560, 180), "nombre": "Secretaría"},
			{"pos": Vector2(380, 280), "nombre": "Sala de Reuniones"},
		]
	},
	{
		"id":     "led_bloque_e",
		"nombre": "Bloque E — Computación",
		"desc":   "Centro de cómputo con servidores de alta potencia. Las luminarias LED reducen la carga térmica y el consumo total del edificio.",
		"spots":  [
			{"pos": Vector2(180, 150), "nombre": "Lab. Inteligencia Artificial"},
			{"pos": Vector2(460, 150), "nombre": "Lab. Programación Avanzada"},
			{"pos": Vector2(640, 260), "nombre": "Centro de Datos"},
		]
	},
	{
		"id":     "led_bloque_f",
		"nombre": "Bloque F — Estudios a Distancia",
		"desc":   "El edificio más grande del campus. Sus amplios pasillos y salas de videoconferencia requieren iluminación LED eficiente para reducir costos operativos.",
		"spots":  [
			{"pos": Vector2(180, 120), "nombre": "Sala de Videoconferencia A"},
			{"pos": Vector2(540, 120), "nombre": "Sala de Videoconferencia B"},
			{"pos": Vector2(350, 260), "nombre": "Pasillo Principal"},
		]
	},
]

# ── Dimensiones del mundo interior ──────────────────────────
const ROOM_W      : float = 760.0
const ROOM_H      : float = 380.0
const ROOM_X      : float = 60.0    # posición dentro del panel
const ROOM_Y      : float = 90.0
const PLAYER_R    : float = 10.0
const PLAYER_SPEED: float = 190.0
const SPOT_RADIO  : float = 24.0
const INTERACT_R  : float = 52.0

# ── Estado ───────────────────────────────────────────────────
var _bloque_idx   : int     = 0
var _mision_id    : String  = ""
var _player_pos   : Vector2 = Vector2(ROOM_W * 0.5, ROOM_H - 40)
var _spots_done   : Array   = []   # Array[bool]
var _spot_cercano : int     = -1
var _t            : float   = 0.0
var _zona_ref     : Area2D  = null

# ── Nodos UI ─────────────────────────────────────────────────
var _panel_root   : Panel  = null
var _titulo_lbl   : Label  = null
var _progress_lbl : Label  = null
var _mundo_node   : Node2D = null
var _sub_panel     : Panel  = null
var _int_visual    : Node2D = null
var _int_instr_lbl : Label  = null
var _int_paso_lbl  : Label  = null
var _int_spot_idx  : int    = 0
var _int_estado    : int    = 0   # 0=apagar, 1=retirar, 2=instalar
var _hint_e_lbl    : Label  = null
var _btn_salir     : Button = null

const INT_INSTRUCCIONES : Array[String] = [
	"⬅  Haz clic en el INTERRUPTOR para apagar el circuito",
	"Haz clic en la BOMBILLA para retirarla  ➡",
	"Haz clic en el MÓDULO LED para instalarlo  ➡",
]


# ── Inner class: dibujo del mundo interior ───────────────────
class MundoInterior extends Node2D:
	const ROOM_W   = 760.0
	const ROOM_H   = 380.0
	const PLAYER_R = 10.0
	const SPOT_RADIO = 24.0
	var player_pos  : Vector2 = Vector2(0, 0)
	var spots       : Array   = []
	var spots_done  : Array   = []
	var spot_cerc   : int     = -1
	var tipo_bloque : int     = 0
	var _t          : float   = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		_draw_room()
		_draw_furniture()
		_draw_spots()
		_draw_player()

	func _draw_room() -> void:
		# Suelo del pasillo
		draw_rect(Rect2(0, 0, ROOM_W, ROOM_H), Color(0.10, 0.12, 0.16))
		# Baldosas
		var tile_size := 40.0
		for xi in int(ROOM_W / tile_size):
			for yi in int(ROOM_H / tile_size):
				var rx := float(xi) * tile_size + 0.5
				var ry := float(yi) * tile_size + 0.5
				draw_rect(Rect2(rx, ry, tile_size - 1.0, tile_size - 1.0),
						  Color(0.13, 0.15, 0.20))
		# Paredes (bordes)
		draw_rect(Rect2(0, 0, ROOM_W, ROOM_H), Color(0.22, 0.30, 0.45), false, 3.0)
		# Líneas de pared norte y sur (más oscuras)
		draw_rect(Rect2(0, 0, ROOM_W, 16), Color(0.15, 0.18, 0.28))
		draw_rect(Rect2(0, ROOM_H - 16, ROOM_W, 16), Color(0.15, 0.18, 0.28))

	func _draw_furniture() -> void:
		# Mobiliario según tipo de bloque
		match tipo_bloque:
			0:   # Aulas: filas de pupitres
				for row in 3:
					for col in 5:
						var fx := 60.0 + float(col) * 130.0
						var fy := 40.0 + float(row) * 95.0
						draw_rect(Rect2(fx, fy, 60, 35), Color(0.18, 0.22, 0.30))
						draw_rect(Rect2(fx, fy, 60, 35), Color(0.25, 0.32, 0.45), false, 1.5)
				# Pizarrón al fondo norte
				draw_rect(Rect2(100, 16, 560, 22), Color(0.08, 0.18, 0.14))
				draw_rect(Rect2(100, 16, 560, 22), Color(0.12, 0.28, 0.20), false, 1.5)
			1:   # Laboratorios: mesas con computadoras
				for row in 2:
					for col in 4:
						var fx := 80.0 + float(col) * 160.0
						var fy := 60.0 + float(row) * 150.0
						draw_rect(Rect2(fx, fy, 100, 50), Color(0.12, 0.16, 0.24))
						draw_rect(Rect2(fx, fy, 100, 50), Color(0.20, 0.28, 0.42), false, 1.5)
						# Pantalla
						draw_rect(Rect2(fx + 15, fy + 6, 60, 36),
								  Color(0.04, 0.06, 0.14))
						draw_rect(Rect2(fx + 15, fy + 6, 60, 36),
								  Color(0.10, 0.40, 0.65, 0.5), false, 1.0)
			2:   # Oficinas: escritorios individuales
				for col in 3:
					var fx := 100.0 + float(col) * 200.0
					draw_rect(Rect2(fx, 80, 120, 60), Color(0.14, 0.18, 0.26))
					draw_rect(Rect2(fx, 80, 120, 60), Color(0.22, 0.30, 0.44), false, 1.5)

	func _draw_spots() -> void:
		var spots_data : Array = spots
		var done : Array = spots_done
		for i in spots_data.size():
			var sp : Dictionary = spots_data[i]
			var sp_pos : Vector2 = sp["pos"]
			var is_done : bool   = i < done.size() and done[i]
			var is_cerc : bool   = (i == spot_cerc)

			if is_done:
				# LED instalado: punto verde con luz
				draw_circle(sp_pos, 20.0, Color(0.15, 0.80, 0.25, 0.22))
				_draw_led_installed(sp_pos)
			else:
				# Bombillo viejo: punto naranja pulsante
				var ga := 0.15 + 0.12 * sin(_t * 3.5 + float(i))
				draw_circle(sp_pos, 28.0, Color(0.90, 0.50, 0.05, ga))
				if is_cerc:
					draw_circle(sp_pos, 30.0, Color(0.95, 0.75, 0.15, ga * 1.5))
					draw_arc(sp_pos, 34.0, 0.0, TAU, 32,
							 Color(0.95, 0.80, 0.20, ga), 2.5)
				_draw_old_bulb(sp_pos)

			# Nombre del spot
			# (dibujamos como líneas de debug — label real en CanvasLayer)
			draw_arc(sp_pos, SPOT_RADIO, 0.0, TAU, 20,
					 Color(0.90, 0.55, 0.10) if not is_done else Color(0.22, 0.88, 0.30),
					 1.5)

	func _draw_old_bulb(p: Vector2) -> void:
		var pulse := 1.0 + 0.08 * sin(_t * 4.0)
		draw_circle(p, 10.0 * pulse, Color(0.85, 0.42, 0.08))
		draw_circle(p + Vector2(0, 6), Vector2(6, 4).x, Color(0.70, 0.30, 0.06))
		draw_arc(p + Vector2(-3, -12), 3.0, PI, TAU, 8,
				 Color(1.0, 0.90, 0.60, 0.55 * pulse), 1.5)
		# Rayos del bombillo
		for j in 6:
			var a := float(j) / 6.0 * TAU + _t * 0.5
			var r1 := 14.0 * pulse
			var r2 := 20.0 * pulse
			draw_line(p + Vector2(cos(a) * r1, sin(a) * r1),
					  p + Vector2(cos(a) * r2, sin(a) * r2),
					  Color(0.95, 0.75, 0.20, 0.30 * pulse), 1.5)

	func _draw_led_installed(p: Vector2) -> void:
		# LED: luz más fría y eficiente (azul-blanco)
		var ga := 0.10 + 0.05 * sin(_t * 1.8)
		draw_circle(p, 22.0, Color(0.70, 0.88, 1.0, ga))
		draw_circle(p, 10.0, Color(0.60, 0.82, 1.0))
		draw_arc(p, 10.0, 0.0, TAU, 16, Color(0.80, 0.94, 1.0), 2.0)
		draw_circle(p + Vector2(-3, -8), 3.0, Color(1.0, 1.0, 1.0, 0.70))
		# Checkmark pequeño
		draw_line(p + Vector2(-6, 2), p + Vector2(-2, 6), Color(0.22, 0.90, 0.30), 2.5)
		draw_line(p + Vector2(-2, 6), p + Vector2(8, -6), Color(0.22, 0.90, 0.30), 2.5)

	func _draw_player() -> void:
		var p := player_pos
		# Sombra
		draw_arc(p + Vector2(0, 8), PLAYER_R * 0.9, 0.0, PI, 12,
				 Color(0.0, 0.0, 0.0, 0.30), 6.0)
		# Cuerpo del jugador (mini personaje top-down)
		draw_circle(p, PLAYER_R, Color(0.25, 0.65, 0.35))
		draw_arc(p, PLAYER_R, 0.0, TAU, 20, Color(0.35, 0.85, 0.45), 2.0)
		# Cabeza (círculo más pequeño arriba)
		draw_circle(p + Vector2(0, -PLAYER_R * 0.5), PLAYER_R * 0.55, Color(0.88, 0.72, 0.55))
		# Indicador de dirección
		draw_arc(p, PLAYER_R + 4.0, -PI * 0.3, PI * 0.3, 8,
				 Color(0.45, 0.95, 0.55, 0.55), 2.0)

# ── Inner class: panel eléctrico interactivo ─────────────────
class InteractiveVisual extends Node2D:
	var estado : int   = 0   # 0=apagar, 1=retirar, 2=instalar, 3=done
	var _t     : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func set_estado(e: int) -> void:
		estado = e

	func _draw() -> void:
		_draw_fondo()
		_draw_wire()
		_draw_switch_panel()
		_draw_fixture()
		_draw_arrows()

	func _draw_fondo() -> void:
		draw_rect(Rect2(0, 0, 640, 290), Color(0.08, 0.09, 0.13))
		draw_line(Vector2(0, 22), Vector2(640, 22), Color(0.20, 0.22, 0.30), 2.0)
		draw_line(Vector2(0, 268), Vector2(640, 268), Color(0.20, 0.22, 0.30), 2.0)

	func _draw_wire() -> void:
		var live := (estado == 0)
		var col := Color(0.88, 0.70, 0.12, 0.82) if live else Color(0.35, 0.36, 0.32, 0.55)
		var pts := [Vector2(210, 118), Vector2(295, 118), Vector2(295, 18), Vector2(365, 18)]
		for i in 3:
			draw_line(pts[i], pts[i + 1], col, 4.0)
		if live:
			var pulse := 0.5 + 0.45 * sin(_t * 6.0)
			for pt in pts:
				draw_circle(pt, 5.0, Color(0.95, 0.82, 0.15, pulse * 0.7))

	func _draw_switch_panel() -> void:
		var bx := 18.0; var by := 25.0; var bw := 195.0; var bh := 238.0
		draw_rect(Rect2(bx, by, bw, bh), Color(0.16, 0.18, 0.26))
		draw_rect(Rect2(bx, by, bw, bh), Color(0.32, 0.38, 0.58), false, 3.0)
		draw_rect(Rect2(bx + 8, by + 8, bw - 16, 20), Color(0.10, 0.12, 0.20))
		for cxo in [10.0, bw - 10.0]:
			for cyo in [10.0, bh - 10.0]:
				draw_circle(Vector2(bx + cxo, by + cyo), 4.5, Color(0.38, 0.40, 0.52))
				draw_line(Vector2(bx + cxo - 3, by + cyo),
						  Vector2(bx + cxo + 3, by + cyo), Color(0.55, 0.58, 0.68), 1.5)
		var scx := bx + bw * 0.5
		var scy := by + bh * 0.5 + 8
		draw_rect(Rect2(scx - 30, scy - 58, 60, 116), Color(0.12, 0.14, 0.22))
		draw_rect(Rect2(scx - 30, scy - 58, 60, 116), Color(0.28, 0.32, 0.50), false, 2.0)
		draw_circle(Vector2(scx, scy), 7.0, Color(0.35, 0.38, 0.52))
		if estado == 0:
			var tip := Vector2(scx + 20, scy - 40)
			draw_line(Vector2(scx, scy), tip, Color(0.72, 0.22, 0.10), 14.0)
			draw_circle(tip, 9.0, Color(0.85, 0.25, 0.10))
			var pulse := 0.45 + 0.40 * sin(_t * 4.5)
			draw_circle(Vector2(scx, scy - 46), 10.0, Color(0.85, 0.12, 0.12))
			draw_circle(Vector2(scx, scy - 46), 18.0, Color(0.85, 0.12, 0.12, pulse))
			for i in 5:
				var a := _t * 4.0 + float(i) * TAU / 5.0
				var r := 12.0 + sin(_t * 7.0 + float(i)) * 4.0
				draw_circle(Vector2(scx + cos(a) * r, scy - 46 + sin(a) * r * 0.5),
							2.0, Color(0.95, 0.85, 0.20, pulse * 0.9))
			draw_arc(Vector2(scx, scy + 44), 18.0, 0.0, TAU, 20,
					 Color(0.70, 0.12, 0.12, 0.65), 3.0)
		else:
			var tip2 := Vector2(scx, scy + 40)
			draw_line(Vector2(scx, scy), tip2, Color(0.18, 0.58, 0.20), 14.0)
			draw_circle(tip2, 9.0, Color(0.22, 0.78, 0.25))
			draw_circle(Vector2(scx, scy + 50), 10.0, Color(0.22, 0.85, 0.26))
			draw_circle(Vector2(scx, scy + 50), 16.0, Color(0.22, 0.85, 0.26, 0.28))
			draw_arc(Vector2(scx, scy - 46), 18.0, 0.0, TAU, 20,
					 Color(0.22, 0.70, 0.24, 0.60), 3.0)

	func _draw_fixture() -> void:
		var fx := 365.0; var fw := 248.0; var fy := 8.0
		var fc  := fx + fw * 0.5
		draw_rect(Rect2(fx, fy, fw, 18), Color(0.28, 0.30, 0.38))
		draw_rect(Rect2(fx, fy, fw, 18), Color(0.42, 0.46, 0.60), false, 2.0)
		for mx in [fx + 18, fx + fw - 18]:
			draw_circle(Vector2(mx, fy + 9), 5.0, Color(0.44, 0.46, 0.56))
		draw_rect(Rect2(fc - 34, fy + 18, 68, 32), Color(0.22, 0.24, 0.32))
		draw_rect(Rect2(fc - 34, fy + 18, 68, 32), Color(0.38, 0.42, 0.58), false, 2.0)
		for ti in 3:
			draw_line(Vector2(fc - 30, fy + 21 + float(ti) * 8),
					  Vector2(fc + 30, fy + 21 + float(ti) * 8),
					  Color(0.32, 0.35, 0.50, 0.6), 1.0)
		var by2 := fy + 50.0
		match estado:
			0:
				_draw_bulb_inc(Vector2(fc, by2 + 36), true)
				var glow := 0.12 + 0.10 * sin(_t * 3.5)
				var cone := PackedVector2Array([
					Vector2(fc - 22, by2 + 55), Vector2(fc + 22, by2 + 55),
					Vector2(fc + 90, by2 + 195), Vector2(fc - 90, by2 + 195),
				])
				draw_colored_polygon(cone, Color(0.95, 0.80, 0.22, glow))
			1:
				_draw_bulb_inc(Vector2(fc, by2 + 36), false)
				var hp := 0.45 + 0.40 * sin(_t * 3.2)
				draw_arc(Vector2(fc, by2 + 36), 38.0, 0.0, TAU, 24,
						 Color(0.90, 0.72, 0.18, hp), 2.5)
			2:
				for wi in [-10, 0, 10]:
					var wc := Color(0.82, 0.22, 0.22) if wi < 0 \
								else (Color(0.22, 0.22, 0.82) if wi > 0 else Color(0.80, 0.80, 0.80))
					draw_line(Vector2(fc + wi, by2), Vector2(fc + wi, by2 + 7), wc, 2.5)
				draw_arc(Vector2(fc, by2 + 9), 18.0, 0.0, TAU, 16,
						 Color(0.50, 0.52, 0.62, 0.6), 1.5)
				var led_y := by2 + 112 + sin(_t * 2.2) * 7.0
				_draw_led_mod(Vector2(fc, led_y))
				draw_circle(Vector2(fc, led_y), 32.0, Color(0.60, 0.88, 1.0, 0.12))
				draw_line(Vector2(fc, led_y - 22), Vector2(fc, by2 + 16),
						  Color(0.22, 0.90, 0.30, 0.82), 3.0)
				draw_line(Vector2(fc - 9, by2 + 28), Vector2(fc, by2 + 15),
						  Color(0.22, 0.90, 0.30, 0.82), 3.0)
				draw_line(Vector2(fc + 9, by2 + 28), Vector2(fc, by2 + 15),
						  Color(0.22, 0.90, 0.30, 0.82), 3.0)
			3:
				_draw_led_mod(Vector2(fc, by2 + 24))
				var g2 := 0.16 + 0.10 * sin(_t * 2.0)
				draw_circle(Vector2(fc, by2 + 24), 65.0, Color(0.60, 0.88, 1.0, g2))
				var cone2 := PackedVector2Array([
					Vector2(fc - 36, by2 + 36), Vector2(fc + 36, by2 + 36),
					Vector2(fc + 112, by2 + 195), Vector2(fc - 112, by2 + 195),
				])
				draw_colored_polygon(cone2, Color(0.60, 0.88, 1.0, g2 * 0.70))
				for i in 8:
					var a := float(i) / 8.0 * TAU + _t * 0.6
					draw_line(Vector2(fc + cos(a) * 26, by2 + 24 + sin(a) * 26),
							  Vector2(fc + cos(a) * 56, by2 + 24 + sin(a) * 56),
							  Color(0.80, 0.95, 1.0, 0.50), 1.5)
				draw_arc(Vector2(fc + 92, by2 + 8), 22.0, 0.0, TAU, 24,
						 Color(0.22, 0.90, 0.28), 3.0)
				draw_line(Vector2(fc + 80, by2 + 8),
						  Vector2(fc + 90, by2 + 18), Color(0.22, 0.92, 0.28), 4.0)
				draw_line(Vector2(fc + 90, by2 + 18),
						  Vector2(fc + 105, by2 - 6), Color(0.22, 0.92, 0.28), 4.0)

	func _draw_bulb_inc(pos: Vector2, lit: bool) -> void:
		var col := Color(0.82, 0.68, 0.22) if lit else Color(0.42, 0.40, 0.30)
		var pts := PackedVector2Array()
		for i in 24:
			var a := float(i) / 24.0 * TAU
			pts.append(pos + Vector2(cos(a) * 24.0, sin(a) * 28.0))
		draw_colored_polygon(pts, col)
		if lit:
			draw_arc(pos, 20.0, 0.0, TAU, 20, Color(1.0, 0.92, 0.52, 0.35), 1.5)
		draw_rect(Rect2(pos.x - 12, pos.y - 18, 24, 20), Color(0.55, 0.52, 0.44))
		draw_rect(Rect2(pos.x - 14, pos.y - 22,  28, 6), Color(0.44, 0.42, 0.36))
		if lit:
			var p := 0.75 + 0.25 * sin(_t * 9.0)
			draw_line(pos + Vector2(-7, -3), pos + Vector2(0, 9), Color(1.0, 0.92, 0.55, p), 2.0)
			draw_line(pos + Vector2(0, 9),  pos + Vector2(7, -3), Color(1.0, 0.92, 0.55, p), 2.0)

	func _draw_led_mod(pos: Vector2) -> void:
		draw_rect(Rect2(pos.x - 38, pos.y - 12, 76, 18), Color(0.22, 0.26, 0.38))
		draw_rect(Rect2(pos.x - 38, pos.y + 4,  76, 14), Color(0.30, 0.36, 0.52))
		draw_rect(Rect2(pos.x - 38, pos.y - 12, 76, 30), Color(0.48, 0.56, 0.78), false, 2.5)
		for i in 6:
			var dx := -26.0 + float(i) * 10.5
			draw_circle(Vector2(pos.x + dx, pos.y - 2), 4.0, Color(0.70, 0.88, 1.0))
			draw_circle(Vector2(pos.x + dx, pos.y - 2), 2.0, Color(0.95, 0.98, 1.0))
		draw_circle(Vector2(pos.x + 30, pos.y - 2), 5.5, Color(0.10, 0.12, 0.18))
		draw_arc(Vector2(pos.x + 30, pos.y - 2), 5.5, 0.0, TAU, 12, Color(0.55, 0.78, 0.95), 1.5)
		for rs in [8.0, 13.0]:
			draw_arc(Vector2(pos.x + 30, pos.y - 2), rs, -PI * 0.55, PI * 0.55, 10,
					 Color(0.55, 0.78, 0.95, 0.35), 1.5)

	func _draw_arrows() -> void:
		var pulse := 0.55 + 0.42 * sin(_t * 2.8)
		match estado:
			0:
				for i in 3:
					var ox := -52.0 - float(i) * 20.0
					var al := pulse - float(i) * 0.18
					if al <= 0.05: continue
					draw_line(Vector2(115 + ox, 142), Vector2(115 + ox + 16, 142),
							  Color(0.95, 0.80, 0.15, al), 4.0)
					draw_line(Vector2(115 + ox + 16, 142), Vector2(115 + ox + 8, 134),
							  Color(0.95, 0.80, 0.15, al), 4.0)
					draw_line(Vector2(115 + ox + 16, 142), Vector2(115 + ox + 8, 150),
							  Color(0.95, 0.80, 0.15, al), 4.0)
			1:
				for i in 3:
					var ox := 52.0 + float(i) * 20.0
					var al := pulse - float(i) * 0.18
					if al <= 0.05: continue
					draw_line(Vector2(489 + ox, 102), Vector2(489 + ox - 16, 102),
							  Color(0.95, 0.80, 0.15, al), 4.0)
					draw_line(Vector2(489 + ox - 16, 102), Vector2(489 + ox - 8, 94),
							  Color(0.95, 0.80, 0.15, al), 4.0)
					draw_line(Vector2(489 + ox - 16, 102), Vector2(489 + ox - 8, 110),
							  Color(0.95, 0.80, 0.15, al), 4.0)




# ── _ready ────────────────────────────────────────────────────
func _ready() -> void:
	layer = 20
	add_to_group("interior_bloque")
	_crear_ui()
	hide()


func iniciar(bloque_idx: int, zona_node: Area2D) -> void:
	_bloque_idx  = clampi(bloque_idx, 0, BLOQUES.size() - 1)
	_zona_ref    = zona_node
	var b : Dictionary = BLOQUES[_bloque_idx]
	_mision_id   = b["id"]
	SupabaseManager.registrar_evento(2, _mision_id, "mision_iniciada",
		{"luminarias": (b["spots"] as Array).size()})
	_player_pos  = Vector2(ROOM_W * 0.5, ROOM_H - 40)
	_spots_done  = []
	for _i in (b["spots"] as Array).size():
		_spots_done.append(false)
	_spot_cercano = -1
	_sub_panel.visible = false
	_hint_e_lbl.visible = false

	# Inicializar mundo
	(_mundo_node as MundoInterior).spots      = b["spots"]
	(_mundo_node as MundoInterior).spots_done = _spots_done
	(_mundo_node as MundoInterior).tipo_bloque = _bloque_idx

	_titulo_lbl.text = "🏛️  " + (b["nombre"] as String)
	_actualizar_progress()
	show()
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("interior_led",
			"⚡ Muévete con WASD y presiona [E] al acercarte a las luminarias naranjas.")


func _actualizar_progress() -> void:
	var total := (BLOQUES[_bloque_idx]["spots"] as Array).size()
	var hecho := 0
	for d in _spots_done:
		if d: hecho += 1
	_progress_lbl.text = "Luminarias reemplazadas: %d / %d" % [hecho, total]


# ── Proceso y movimiento ──────────────────────────────────────
func _process(delta: float) -> void:
	if not visible: return
	if _sub_panel.visible: return   # sin movimiento mientras hay subdiálogo
	_t += delta
	_mover_jugador(delta)
	_verificar_spot_cercano()
	(_mundo_node as MundoInterior).player_pos  = _player_pos
	(_mundo_node as MundoInterior).spot_cerc   = _spot_cercano


func _mover_jugador(delta: float) -> void:
	var vel := Vector2.ZERO
	if Input.is_action_pressed("ui_up")    or Input.is_key_pressed(KEY_W): vel.y -= 1
	if Input.is_action_pressed("ui_down")  or Input.is_key_pressed(KEY_S): vel.y += 1
	if Input.is_action_pressed("ui_left")  or Input.is_key_pressed(KEY_A): vel.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): vel.x += 1
	if vel.length_squared() > 0:
		vel = vel.normalized() * PLAYER_SPEED
	_player_pos += vel * delta
	# Limitar a los bordes del cuarto
	_player_pos.x = clampf(_player_pos.x, PLAYER_R + 4, ROOM_W - PLAYER_R - 4)
	_player_pos.y = clampf(_player_pos.y, PLAYER_R + 20, ROOM_H - PLAYER_R - 4)


func _verificar_spot_cercano() -> void:
	var b : Dictionary = BLOQUES[_bloque_idx]
	var spots : Array = b["spots"]
	_spot_cercano = -1
	var min_dist  := INTERACT_R
	for i in spots.size():
		if _spots_done[i]: continue
		var sp_pos : Vector2 = (spots[i] as Dictionary)["pos"]
		var dist := _player_pos.distance_to(sp_pos)
		if dist < min_dist:
			min_dist      = dist
			_spot_cercano = i
	_hint_e_lbl.visible = (_spot_cercano >= 0)
	if _spot_cercano >= 0:
		var sp_nombre : String = (spots[_spot_cercano] as Dictionary)["nombre"]
		_hint_e_lbl.text = "⚡ [E]  Reemplazar luminaria — %s" % sp_nombre


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if _sub_panel.visible:
		return
	if event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		if _spot_cercano >= 0:
			_iniciar_interactivo(_spot_cercano)
		else:
			# E sin spot → preguntar si salir
			pass
	if event is InputEventKey and (event as InputEventKey).pressed:
		var ke := event as InputEventKey
		if ke.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_salir()


# ── Panel interactivo: proceso de reemplazo ──────────────────
func _iniciar_interactivo(spot_idx: int) -> void:
	_int_spot_idx = spot_idx
	_int_estado   = 0
	var sp_nombre : String = (BLOQUES[_bloque_idx]["spots"] as Array)[spot_idx]["nombre"]
	_int_paso_lbl.text  = "Paso 1 de 3 — %s" % sp_nombre
	_int_instr_lbl.text = INT_INSTRUCCIONES[0]
	(_int_visual as InteractiveVisual).set_estado(0)
	_sub_panel.modulate.a = 0.0
	_sub_panel.visible    = true
	var tw := create_tween()
	tw.tween_property(_sub_panel, "modulate:a", 1.0, 0.22)
	tw.parallel().tween_property(_sub_panel, "scale",
		Vector2(1.0, 1.0), 0.22).from(Vector2(0.88, 0.88))


func _on_click_switch() -> void:
	if _int_estado != 0: return
	_int_estado = 1
	_int_paso_lbl.text  = "Paso 2 de 3 — Retirar bombillo"
	_int_instr_lbl.text = INT_INSTRUCCIONES[1]
	(_int_visual as InteractiveVisual).set_estado(1)


func _on_click_fixture() -> void:
	match _int_estado:
		1:
			_int_estado = 2
			_int_paso_lbl.text  = "Paso 3 de 3 — Instalar módulo LED"
			_int_instr_lbl.text = INT_INSTRUCCIONES[2]
			(_int_visual as InteractiveVisual).set_estado(2)
		2:
			(_int_visual as InteractiveVisual).set_estado(3)
			_int_instr_lbl.text = "✅ ¡Luminaria LED instalada!"
			_int_paso_lbl.text  = "✅ ¡LED instalado con éxito!"
			var tw := create_tween()
			tw.tween_interval(1.0)
			tw.tween_callback(func(): _completar_spot(_int_spot_idx))


func _on_vis_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton): return
	var ev := event as InputEventMouseButton
	if not (ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT): return
	var mp := ev.position
	if _int_estado == 0 and Rect2(0, 0, 290, 290).has_point(mp):
		_on_click_switch()
	elif _int_estado in [1, 2] and Rect2(330, 0, 310, 290).has_point(mp):
		_on_click_fixture()


func _completar_spot(spot_idx: int) -> void:
	_spots_done[spot_idx] = true
	(_mundo_node as MundoInterior).spots_done = _spots_done
	_actualizar_progress()
	_sub_panel.visible = false
	# Verificar si todos los spots están completos
	var todos_listos := true
	for d in _spots_done:
		if not d: todos_listos = false; break
	if todos_listos:
		_completar_mision()


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _completar_mision() -> void:
	SupabaseManager.registrar_evento(2, _mision_id, "mision_completada")
	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(2, _mision_id)
	if is_instance_valid(_zona_ref) and _zona_ref.has_method("_marcar_completado"):
		_zona_ref._marcar_completado()
	var xp : int = int(nm.XP_POR_MISION.get(2, 50)) if nm else 50
	var ec : int = int(nm.EC_POR_MISION.get(2, 20)) if nm else 20
	mision_interior_completada.emit(_mision_id, xp, ec)
	_mostrar_panel_metricas_led(xp, ec)


func _mostrar_panel_metricas_led(xp: int, ec: int) -> void:
	var nombre_bloque : String = BLOQUES[_bloque_idx]["nombre"]
	var met := Panel.new()
	met.set_anchors_preset(Control.PRESET_CENTER)
	met.custom_minimum_size = Vector2(540, 390)
	met.offset_left  = -270.0; met.offset_top    = -195.0
	met.offset_right =  270.0; met.offset_bottom =  195.0
	var mps := StyleBoxFlat.new()
	mps.bg_color     = Color(0.04, 0.08, 0.06, 0.99)
	mps.border_color = Color(0.22, 0.90, 0.28)
	mps.set_border_width_all(3)
	mps.set_corner_radius_all(16)
	mps.shadow_color = Color(0.10, 0.55, 0.18, 0.55)
	mps.shadow_size  = 24
	met.add_theme_stylebox_override("panel", mps)
	add_child(met)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 20; vb.offset_top = 16
	vb.offset_right = -20; vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 9)
	met.add_child(vb)

	var tit := Label.new()
	tit.text = "⚡ ¡Misión completada!\n%s" % nombre_bloque
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 15)
	tit.add_theme_color_override("font_color", Color(0.30, 1.00, 0.40))
	tit.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(tit)

	var sep1 := HSeparator.new()
	sep1.add_theme_color_override("color", Color(0.22, 0.88, 0.30, 0.4))
	vb.add_child(sep1)

	var sub := Label.new()
	sub.text = "🏆  Impacto en las métricas GreenMetric URBE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.95, 0.70, 0.20))
	vb.add_child(sub)

	var met_lbl := Label.new()
	met_lbl.text = (
		"⚡ Energía y Cambio Climático\n"
		+ "   • Consumo: 100 W → 12 W  (−88%)\n"
		+ "   • CO₂ evitado: ~0.8 t/año por bloque\n"
		+ "   • Vida útil LED: 50,000 h vs 1,000 h incandescente\n\n"
		+ "🏛  Infraestructura y Configuración\n"
		+ "   • Temperatura ambiente: ↓ 1–2 °C (menos calor residual)\n"
		+ "   • Sensor de movimiento: ahorro adicional ~30%\n\n"
		+ "📚  Educación e Investigación\n"
		+ "   • Proceso documentado y replicable en todo el campus"
	)
	met_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	met_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	met_lbl.add_theme_font_size_override("font_size", 11)
	met_lbl.add_theme_color_override("font_color", Color(0.80, 0.92, 0.80))
	vb.add_child(met_lbl)

	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("color", Color(0.22, 0.88, 0.30, 0.3))
	vb.add_child(sep2)

	var recomp := Label.new()
	recomp.text = "+%d XP   ·   +%d EcoCredits" % [xp, ec]
	recomp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recomp.add_theme_font_size_override("font_size", 14)
	recomp.add_theme_color_override("font_color", Color(0.95, 0.80, 0.20))
	vb.add_child(recomp)

	var btn := Button.new()
	btn.text = "  ¡Genial!  ✓  "
	btn.custom_minimum_size   = Vector2(180, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 14)
	var bst := StyleBoxFlat.new()
	bst.bg_color = Color(0.06, 0.30, 0.08); bst.border_color = Color(0.22, 0.84, 0.22)
	bst.set_border_width_all(2); bst.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", bst)
	btn.add_theme_color_override("font_color", Color(0.88, 1.0, 0.88))
	btn.pressed.connect(func(): met.queue_free(); _on_salir())
	vb.add_child(btn)

	met.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(met, "modulate:a", 1.0, 0.25)


func _on_salir() -> void:
	var tw := create_tween()
	tw.tween_property(_panel_root, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): hide(); _panel_root.modulate.a = 1.0)


# ── Crear UI ──────────────────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.92)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Panel principal
	_panel_root = Panel.new()
	_panel_root.custom_minimum_size = Vector2(900, 560)
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left   = -450.0
	_panel_root.offset_top    = -280.0
	_panel_root.offset_right  =  450.0
	_panel_root.offset_bottom =  280.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.08, 0.14, 0.98)
	ps.border_color = Color(0.95, 0.60, 0.10)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.50, 0.30, 0.05, 0.50)
	ps.shadow_size  = 24
	_panel_root.add_theme_stylebox_override("panel", ps)
	add_child(_panel_root)

	# Franja naranja/energía en la parte superior
	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 4)
	acento.offset_bottom       = 4.0
	acento.color               = Color(0.95, 0.58, 0.08, 0.85)
	acento.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(acento)

	# Botón salir
	_btn_salir = Button.new()
	_btn_salir.text = "✕ Salir"
	_btn_salir.custom_minimum_size = Vector2(80, 30)
	_btn_salir.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn_salir.offset_left   = -92.0
	_btn_salir.offset_top    =  8.0
	_btn_salir.offset_right  = -8.0
	_btn_salir.offset_bottom =  38.0
	_btn_salir.add_theme_font_size_override("font_size", 11)
	var bss := StyleBoxFlat.new()
	bss.bg_color = Color(0.18, 0.06, 0.06, 0.90)
	bss.border_color = Color(0.65, 0.15, 0.15)
	bss.set_border_width_all(2)
	bss.set_corner_radius_all(8)
	_btn_salir.add_theme_stylebox_override("normal", bss)
	_btn_salir.add_theme_color_override("font_color", Color(0.92, 0.50, 0.50))
	_btn_salir.pressed.connect(_on_salir)
	_panel_root.add_child(_btn_salir)

	# Título
	_titulo_lbl = Label.new()
	_titulo_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_titulo_lbl.offset_left   = 14.0
	_titulo_lbl.offset_top    = 10.0
	_titulo_lbl.offset_right  = 760.0
	_titulo_lbl.offset_bottom = 42.0
	_titulo_lbl.add_theme_font_size_override("font_size", 17)
	_titulo_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.65))
	_panel_root.add_child(_titulo_lbl)

	# Badge nivel
	var badge := Label.new()
	badge.text = "⚡ NIVEL 2"
	badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
	badge.offset_left   = 14.0
	badge.offset_top    = 42.0
	badge.offset_right  = 200.0
	badge.offset_bottom = 60.0
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.95, 0.65, 0.20))
	_panel_root.add_child(badge)

	# Progreso
	_progress_lbl = Label.new()
	_progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_progress_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_progress_lbl.offset_left   = -380.0
	_progress_lbl.offset_top    = 42.0
	_progress_lbl.offset_right  = -96.0
	_progress_lbl.offset_bottom = 60.0
	_progress_lbl.add_theme_font_size_override("font_size", 11)
	_progress_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
	_panel_root.add_child(_progress_lbl)

	# Zona de mundo: Control con clip
	var mundo_cont := Control.new()
	mundo_cont.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mundo_cont.offset_left   = float(ROOM_X - 2)
	mundo_cont.offset_top    = float(ROOM_Y - 2)
	mundo_cont.offset_right  = float(ROOM_X + ROOM_W + 2)
	mundo_cont.offset_bottom = float(ROOM_Y + ROOM_H + 2)
	mundo_cont.clip_contents = true
	_panel_root.add_child(mundo_cont)

	_mundo_node = MundoInterior.new()
	_mundo_node.position = Vector2(0, 0)
	mundo_cont.add_child(_mundo_node)

	# Borde del mundo
	var world_border := ColorRect.new()
	world_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_border.color        = Color(0.22, 0.40, 0.65, 0)
	world_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mundo_cont.add_child(world_border)

	# Hint de la tecla E
	_hint_e_lbl = Label.new()
	_hint_e_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_e_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint_e_lbl.offset_left   =  14.0
	_hint_e_lbl.offset_top    = -52.0
	_hint_e_lbl.offset_right  = 860.0
	_hint_e_lbl.offset_bottom = -28.0
	_hint_e_lbl.visible = false
	_hint_e_lbl.add_theme_font_size_override("font_size", 14)
	_hint_e_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.20))
	_panel_root.add_child(_hint_e_lbl)

	# Instrucciones WASD
	var wasd_lbl := Label.new()
	wasd_lbl.text = "WASD — Moverse   |   [E] — Interactuar"
	wasd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wasd_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	wasd_lbl.offset_left   = 14.0
	wasd_lbl.offset_top    = -24.0
	wasd_lbl.offset_right  = 860.0
	wasd_lbl.offset_bottom = -6.0
	wasd_lbl.add_theme_font_size_override("font_size", 10)
	wasd_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.40))
	_panel_root.add_child(wasd_lbl)

	# ── Panel eléctrico interactivo ──────────────────────────────
	_sub_panel = Panel.new()
	_sub_panel.set_anchors_preset(Control.PRESET_CENTER)
	_sub_panel.custom_minimum_size = Vector2(700, 400)
	_sub_panel.offset_left   = -350.0
	_sub_panel.offset_top    = -200.0
	_sub_panel.offset_right  =  350.0
	_sub_panel.offset_bottom =  200.0
	_sub_panel.visible = false
	var sps := StyleBoxFlat.new()
	sps.bg_color     = Color(0.04, 0.06, 0.12, 0.99)
	sps.border_color = Color(0.30, 0.55, 0.90)
	sps.set_border_width_all(3)
	sps.set_corner_radius_all(16)
	sps.shadow_color = Color(0.05, 0.15, 0.50, 0.60)
	sps.shadow_size  = 24
	_sub_panel.add_theme_stylebox_override("panel", sps)
	add_child(_sub_panel)

	var smg := MarginContainer.new()
	smg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		smg.add_theme_constant_override(k, 16)
	_sub_panel.add_child(smg)

	var svbox := VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 10)
	smg.add_child(svbox)

	# Fila superior: salir + título paso
	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 10)
	svbox.add_child(top_hb)

	_btn_salir = Button.new()
	_btn_salir.text = "← Salir"
	_btn_salir.add_theme_font_size_override("font_size", 12)
	_btn_salir.custom_minimum_size = Vector2(90, 32)
	_btn_salir.pressed.connect(func(): _sub_panel.visible = false)
	top_hb.add_child(_btn_salir)

	_int_paso_lbl = Label.new()
	_int_paso_lbl.text = "Paso 1 de 3"
	_int_paso_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_int_paso_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_int_paso_lbl.add_theme_font_size_override("font_size", 15)
	_int_paso_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	top_hb.add_child(_int_paso_lbl)

	# Instrucción actual
	_int_instr_lbl = Label.new()
	_int_instr_lbl.text = INT_INSTRUCCIONES[0]
	_int_instr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_int_instr_lbl.add_theme_font_size_override("font_size", 13)
	_int_instr_lbl.add_theme_color_override("font_color", Color(0.70, 0.88, 1.0))
	_int_instr_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	svbox.add_child(_int_instr_lbl)

	# Área interactiva (captura clics)
	var vis_ctrl := Control.new()
	vis_ctrl.custom_minimum_size   = Vector2(640, 290)
	vis_ctrl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vis_ctrl.mouse_filter          = Control.MOUSE_FILTER_STOP
	svbox.add_child(vis_ctrl)

	_int_visual = InteractiveVisual.new()
	_int_visual.position = Vector2(0, 0)
	vis_ctrl.add_child(_int_visual)
	vis_ctrl.gui_input.connect(_on_vis_input)
