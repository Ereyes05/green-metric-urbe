# ============================================================
# mapa_campus.gd — URBE Rangers: Eco-Quest
# Posiciones alineadas a cuadrícula 16px.
# Pasillos horizontales: 32px entre filas (2 tiles).
# ============================================================
extends Node2D

# ── Ambiente: pájaros y shimmer del lago ─────────────────────
var _t_mapa  : float = 0.0
var _pajaros : Array = []   # [{x, y, vx, f, wing_f}]
var _destellos : Array = [] # [{x, y, fase}] reflejos en el lago

func _ready() -> void:
	for i in 6:
		_pajaros.append({
			"x": randf_range(0.0, 1408.0),
			"y": randf_range(18.0, 135.0),
			"vx": randf_range(35.0, 75.0),
			"f": randf_range(0.0, TAU),
			"wf": randf_range(5.0, 10.0),
		})
	for i in 12:
		_destellos.append({
			"x": randf_range(40.0, 1368.0),
			"y": randf_range(30.0, 140.0),
			"f": randf_range(0.0, TAU),
		})

	_capa_ambiente = CapaAmbiente.new()
	_capa_ambiente.mapa = self
	add_child(_capa_ambiente)


# ── Capa animada, separada del campus fijo ───────────────────
# Antes _process() llamaba queue_redraw() sobre ESTE nodo en cada frame para
# mover 6 pájaros y 12 reflejos, y eso obligaba a volver a dibujar el campus
# entero (céspedes, edificios, caminos, árboles, textos) 60 veces por
# segundo. Medido en el export web: congelar ese redibujado subió el mapa de
# 8-10 a 12-13 FPS.
#
# Ahora el campus se dibuja una sola vez (Godot guarda los comandos de
# dibujo hasta el próximo queue_redraw, que solo ocurre cuando cambia el
# progreso o el mapa de avance) y lo único que se redibuja por frame es esta
# capa, que son 18 líneas.
#
# Diferencia visual aceptada: al ser hija, la capa queda por encima del mapa
# de avance; solo se nota si un pájaro pasa por la franja y=120-140 con el
# mapa de avance activo.
var _capa_ambiente : Node2D = null

class CapaAmbiente extends Node2D:
	var mapa : Node2D = null

	func _draw() -> void:
		if mapa == null: return
		var t : float = mapa._t_mapa
		# ── PÁJAROS AMBIENTALES ──────────────────────────────
		for p in mapa._pajaros:
			var bx   : float = float(p["x"])
			var by   : float = float(p["y"]) + sin(t * float(p["wf"]) * 0.5 + float(p["f"])) * 2.5
			var wing : float = 4.5 + sin(t * float(p["wf"]) + float(p["f"])) * 3.0
			var bird_col := Color(0.08, 0.08, 0.10, 0.70)
			draw_line(Vector2(bx - wing, by - wing * 0.5), Vector2(bx, by), bird_col, 1.3)
			draw_line(Vector2(bx, by), Vector2(bx + wing, by - wing * 0.5), bird_col, 1.3)
		# ── REFLEJOS DEL LAGO ────────────────────────────────
		for d in mapa._destellos:
			var dx  : float = float(d["x"])
			var dy  : float = float(d["y"])
			var df  : float = float(d["f"])
			var a   : float = 0.08 + 0.07 * sin(t * 1.3 + df)
			var len : float = 12.0 + 6.0 * sin(t * 0.9 + df * 1.7)
			draw_line(Vector2(dx - len, dy), Vector2(dx + len, dy),
					  Color(0.75, 0.92, 1.0, a), 1.5)


func _process(delta: float) -> void:
	_t_mapa += delta
	for p in _pajaros:
		p["x"] = float(p["x"]) + float(p["vx"]) * delta
		if float(p["x"]) > 1430.0:
			p["x"] = -15.0
			p["y"] = randf_range(18.0, 135.0)
	if _capa_ambiente:
		_capa_ambiente.queue_redraw()   # solo la capa animada, no el campus

# Se alimenta desde SceneMapaMundo._refrescar_progreso (PuntajeManager).
# Antes arrancaba con valores inventados (0.35, 0.40...).
var impacto : Dictionary = {
	1: 0.0, 2: 0.0, 3: 0.0,
	4: 0.0, 5: 0.0, 6: 0.0
}

var mostrar_avance : bool = false

const HUD_TEMA := preload("res://scenes/ui/hud_tema.gd")

# Zonas con su módulo GreenMetric asociado — layout real URBE.
# NOTA: estos rects deben actualizarse cuando llegue el nuevo mapa del
# campus (está en rediseño); "lugar" es solo referencia para quien edite.
const ZONAS_AVANCE : Array = [
	{"lugar": "Estac. M5",  "rect": Rect2(   0, 120, 220, 420), "mod": 5},
	{"lugar": "Cafetín",    "rect": Rect2( 280, 120, 200, 160), "mod": 3},
	{"lugar": "Bloque E",   "rect": Rect2( 700, 120, 380, 300), "mod": 2},
	{"lugar": "Est. Dist.", "rect": Rect2(1120, 120, 288, 540), "mod": 1},
	{"lugar": "Bloque D",   "rect": Rect2( 280, 320, 200, 160), "mod": 2},
	{"lugar": "Patio",      "rect": Rect2( 480, 120, 220, 360), "mod": 4},
	{"lugar": "Bloque C",   "rect": Rect2( 280, 520, 180, 120), "mod": 2},
	{"lugar": "Bloque B",   "rect": Rect2( 520, 520, 180, 120), "mod": 2},
	{"lugar": "Rectorado",  "rect": Rect2( 740, 480, 320, 180), "mod": 6},
	{"lugar": "Fotocop.",   "rect": Rect2(   0, 580, 180, 120), "mod": 1},
	{"lugar": "Bloque A",   "rect": Rect2( 280, 680, 420,  60), "mod": 2},
]

func toggle_mapa_avance() -> bool:
	mostrar_avance = not mostrar_avance
	queue_redraw()
	return mostrar_avance

func actualizar_modulo(modulo_id: int, nuevo_progreso: float) -> void:
	impacto[modulo_id] = clampf(nuevo_progreso, 0.0, 1.0)
	queue_redraw()

# Único lugar con los umbrales rojo/amarillo/verde del mapa de avance;
# los usa tanto _dibujar_mapa_avance() como _color_indicador() (los puntos
# sobre cada edificio) para no repetir los mismos números dos veces.
static func color_nivel(pct: float) -> Color:
	if pct < 0.40:   return Color(0.90, 0.18, 0.18)
	elif pct < 0.75: return Color(0.92, 0.72, 0.08)
	else:            return Color(0.18, 0.85, 0.18)

func _dibujar_mapa_avance(font: Font) -> void:
	# Overlay oscuro sobre todo el mapa para resaltar las zonas coloreadas.
	draw_rect(Rect2(0, 0, 1408, 768), Color(0, 0, 0, 0.45))
	for info : Dictionary in ZONAS_AVANCE:
		var mod_id : int   = int(info["mod"])
		var rect   : Rect2 = info["rect"]
		var pct    : float = clampf(float(impacto.get(mod_id, 0.0)), 0.0, 1.0)
		var col    : Color = color_nivel(pct)
		draw_rect(rect, Color(col.r, col.g, col.b, 0.42))
		draw_rect(rect, col, false, 2.0)
		_dibujar_badge_avance(font, rect, mod_id, pct, col)


# Insignia en la PARTE SUPERIOR del rect (nunca al centro, donde va el
# nombre del edificio): "<icono> <categoría> <NN>%", con fondo redondeado.
func _dibujar_badge_avance(font: Font, rect: Rect2, mod_id: int, pct: float, col: Color) -> void:
	if mod_id < 0 or mod_id >= HUD_TEMA.CATEGORIAS.size():
		return
	var cat : Dictionary = HUD_TEMA.CATEGORIAS[mod_id]
	if cat.is_empty():
		return
	var txt   : String = "%s %s %d%%" % [cat["icono"], cat["nombre"], int(pct * 100)]
	var fsize : int     = 10
	var tam   : Vector2 = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var pad_h : float = 6.0
	var pad_v : float = 3.0
	var badge_w : float = tam.x + pad_h * 2.0
	var badge_h : float = tam.y + pad_v * 2.0
	var badge_x : float = rect.position.x + (rect.size.x - badge_w) * 0.5
	var badge_y : float = rect.position.y + 6.0
	var badge_rect := Rect2(badge_x, badge_y, badge_w, badge_h)

	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(16 / 255.0, 28 / 255.0, 38 / 255.0, 0.9)
	caja.border_color = col
	caja.set_border_width_all(1)
	caja.set_corner_radius_all(6)
	draw_style_box(caja, badge_rect)

	draw_string(font, Vector2(badge_x + pad_h, badge_y + badge_h - pad_v - 2.0), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(1, 1, 1, 0.95))

func _color_edif(modulo_id: int, base: Color) -> Color:
	if not impacto.has(modulo_id):
		return base
	var pct : float = impacto[modulo_id]
	if pct < 0.40:
		return base.lerp(Color(0.72, 0.18, 0.18), 0.38)
	elif pct < 0.75:
		return base.lerp(Color(0.72, 0.58, 0.08), 0.28)
	else:
		return base.lerp(Color(0.18, 0.62, 0.18), 0.35)

func _color_indicador(modulo_id: int) -> Color:
	if not impacto.has(modulo_id):
		return Color.TRANSPARENT
	return color_nivel(impacto[modulo_id])


func _draw() -> void:
	var font := ThemeDB.fallback_font

	# ── Paleta ───────────────────────────────────────────────
	var C_CESPED   := Color(0.22, 0.48, 0.22)
	var C_CESPED2  := Color(0.18, 0.42, 0.18)
	var C_LAGO     := Color(0.08, 0.42, 0.78)
	var C_ORILLA   := Color(0.55, 0.45, 0.25)
	var C_CAMINO   := Color(0.78, 0.65, 0.42)
	var C_CAMINO2  := Color(0.60, 0.48, 0.28)
	var C_PATIO    := Color(0.26, 0.54, 0.26)
	var C_EDIF     := Color(0.52, 0.38, 0.28)
	var C_EDIF_VIP := Color(0.36, 0.22, 0.12)
	var C_TECHO    := Color(0.28, 0.14, 0.06)
	var C_ESTAC    := Color(0.32, 0.40, 0.46)
	var C_LINEA    := Color(0.52, 0.62, 0.68)
	var C_TEXTO    := Color.WHITE
	var C_AMARILLO := Color(0.97, 0.80, 0.10)
	var C_AZUL_OS  := Color(0.06, 0.16, 0.44)
	var C_CAFETIN  := Color(0.38, 0.28, 0.10)

	# ── FONDO CÉSPED ─────────────────────────────────────────
	draw_rect(Rect2(0, 0, 1408, 768), C_CESPED)
	for gy in range(0, 768, 32):
		draw_rect(Rect2(0, gy, 1408, 16), C_CESPED2)

	# ── LAGO NORTE  y=0..80 ──────────────────────────────────
	draw_rect(Rect2(0, 0, 1408, 80), C_LAGO)
	for ox in range(0, 1408, 110):
		draw_arc(Vector2(float(ox) + 55.0, 55.0), 24.0, 0.0, PI, 16, Color(1,1,1,0.10), 2.0)
	draw_rect(Rect2(0, 76, 1408, 6), C_ORILLA)
	draw_circle(Vector2(200, 42), 7, Color(0.90, 0.85, 0.60))
	draw_circle(Vector2(700, 38), 7, Color(0.90, 0.85, 0.60))
	draw_circle(Vector2(1250, 48), 7, Color(0.90, 0.85, 0.60))
	_draw_str(font, "Lago URBE / Área Deportiva Norte",
			  Vector2(704, 50), Color(1,1,1,0.55), 9)

	# ── CAMINO NORTE HORIZONTAL  y=82..120 ───────────────────
	draw_rect(Rect2(0, 82, 1408, 38), C_CAMINO)
	draw_rect(Rect2(0, 82,  1408, 2), C_CAMINO2)
	draw_rect(Rect2(0, 118, 1408, 2), C_CAMINO2)

	# ── CORREDOR OESTE  x=220..280, y=82..740 ─────────────────
	draw_rect(Rect2(220, 82, 60, 658), C_CAMINO)
	draw_rect(Rect2(220, 82,  2, 658), C_CAMINO2)
	draw_rect(Rect2(278, 82,  2, 658), C_CAMINO2)

	# ── PATIO CENTRAL  x=480..700, y=82..520 ─────────────────
	draw_rect(Rect2(480, 82, 220, 438), C_PATIO)
	for gy in range(82, 520, 24):
		draw_rect(Rect2(480, gy, 220, 12), C_CESPED2)
	# Fuente del patio
	var FC := Vector2(590.0, 290.0)
	draw_circle(FC, 30, Color(0.06, 0.28, 0.62))
	draw_arc(FC, 30, 0.0, TAU, 28, Color(0.30, 0.70, 0.95), 2.5)
	draw_circle(FC, 18, Color(0.12, 0.45, 0.82))
	draw_arc(FC, 5, 0.0, TAU, 10, Color(0.70, 0.92, 1.0), 1.5)
	_draw_str(font, "Patio Central", FC + Vector2(0.0, 42.0), Color(1,1,1,0.72), 8)
	# Árboles del patio
	for ap in [Vector2(498, 130), Vector2(680, 130), Vector2(498, 450),
			   Vector2(680, 450), Vector2(498, 290), Vector2(680, 290)]:
		draw_circle(ap, 12, Color(0.14, 0.38, 0.14))
		draw_circle(ap - Vector2(3,3), 5, Color(0.22, 0.54, 0.18))

	# ── CORREDOR BloqueE–EstDistancia  x=1080..1120 ──────────
	draw_rect(Rect2(1080, 82, 40, 658), C_CAMINO)
	draw_rect(Rect2(1080, 82,  2, 658), C_CAMINO2)
	draw_rect(Rect2(1118, 82,  2, 658), C_CAMINO2)

	# ── PASILLO BloqueE↔Rectorado  y=420..480 ────────────────
	draw_rect(Rect2(700, 420, 380, 60), C_CAMINO)
	draw_rect(Rect2(700, 420, 380,  2), C_CAMINO2)
	draw_rect(Rect2(700, 478, 380,  2), C_CAMINO2)

	# ── PASILLOS HORIZONTALES INTERNOS ───────────────────────
	# Cafetín ↔ Bloque D  (y=280..320)
	draw_rect(Rect2(280, 280, 200, 40), C_CAMINO)
	# Bloque D ↔ Bloque C  (y=480..520)
	draw_rect(Rect2(280, 480, 220, 40), C_CAMINO)
	draw_rect(Rect2(500, 480, 200, 40), C_PATIO)   # patio se conecta aquí
	# Pasillo C ↔ B  (x=460..520, y=520..640)
	draw_rect(Rect2(460, 520, 60, 120), C_CAMINO)
	# Pasillo B ↔ Rectorado  (x=700..740, y=480..680)
	draw_rect(Rect2(700, 480, 40, 200), C_CAMINO)
	# C/B ↔ Bloque A  (y=640..680)
	draw_rect(Rect2(280, 640, 420, 40), C_CAMINO)
	# Este del Rectorado y EstDistancia ↔ Avenida (y=660..740)
	draw_rect(Rect2(740, 660, 340, 80), C_CAMINO)
	draw_rect(Rect2(1060, 660, 60, 80), C_CAMINO)
	# Entre Estac y Fotocopiado (y=540..580)
	draw_rect(Rect2(0, 540, 220, 40), C_CAMINO)
	# Fotocopiado ↔ Bloque C  (x=180..280, y=520..700)
	draw_rect(Rect2(180, 520, 100, 180), C_CAMINO)

	# ── AVENIDA PRINCIPAL  y=740..768 ────────────────────────
	draw_rect(Rect2(0, 740, 1408, 28), C_CAMINO)
	draw_rect(Rect2(0, 740, 1408,  3), C_CAMINO2)
	draw_rect(Rect2(0, 765, 1408,  3), C_CAMINO2)
	for lx in range(0, 1408, 50):
		draw_rect(Rect2(lx, 752, 24, 3), Color(0.95, 0.88, 0.30, 0.70))

	# ════════════════════════════════════════════════════════
	# EDIFICIOS — layout real URBE (foto aérea)
	# ════════════════════════════════════════════════════════

	# ESTACIONAMIENTO M5  x=0..220, y=120..540
	var c_estac := _color_edif(5, C_ESTAC)
	draw_rect(Rect2(0, 120, 220, 420), c_estac)
	# Líneas de parqueo
	for i in range(1, 7):
		draw_line(Vector2(float(i) * 30.0, 120.0), Vector2(float(i) * 30.0, 540.0), C_LINEA, 1.0)
	for i in range(1, 14):
		draw_line(Vector2(0.0, 120.0 + float(i) * 30.0), Vector2(220.0, 120.0 + float(i) * 30.0), C_LINEA, 0.6)
	draw_rect(Rect2(0, 120, 220, 420), C_TECHO, false, 2.0)
	_txt(font, "P",           Rect2(0, 120, 40, 420), C_AMARILLO, 28)
	_txt(font, "Estacion.\nM5", Rect2(40, 120, 180, 420), C_TEXTO, 10)
	_dibujar_indicador(Vector2(210, 130), 5)

	# CAFETÍN M3  x=280..480, y=120..280
	_edif(font, Rect2(280, 120, 200, 160), "Cafetín\nM3",
		_color_edif(3, C_CAFETIN), C_TECHO, C_TEXTO, 3)
	# Banderines cafetín
	draw_rect(Rect2(284, 122, 10, 12), Color(0.08, 0.28, 0.68))
	draw_rect(Rect2(298, 122, 10, 12), Color(0.62, 0.48, 0.05))
	draw_rect(Rect2(312, 122, 10, 12), Color(0.14, 0.50, 0.14))

	# BLOQUE E M2  x=700..1080, y=120..420  (grande)
	_edif(font, Rect2(700, 120, 380, 300), "Bloque E\nM2\n(Laboratorios)",
		_color_edif(2, C_EDIF), C_TECHO, C_TEXTO, 2)
	# Sub-división visual del Bloque E (2 alas)
	draw_line(Vector2(890.0, 120.0), Vector2(890.0, 420.0), C_TECHO.lightened(0.2), 2.0)

	# BLOQUE D M2  x=280..480, y=320..480
	_edif(font, Rect2(280, 320, 200, 160), "Bloque D\nM2",
		_color_edif(2, C_EDIF), C_TECHO, C_TEXTO, 2)

	# ESTUDIOS A DISTANCIA M1  x=1120..1408, y=120..660
	_edif(font, Rect2(1120, 120, 288, 540), "Est. a Distancia\nM1",
		_color_edif(1, C_EDIF_VIP), C_TECHO, C_TEXTO, 1)
	# Banner SERVIEDUCA
	draw_rect(Rect2(1130, 140, 200, 22), Color(0.08, 0.18, 0.08))
	_draw_str(font, "SERVIEDUCA", Vector2(1230, 155), Color(0.40, 0.90, 0.45), 9)

	# BLOQUE C M2  x=280..460, y=520..640
	_edif(font, Rect2(280, 520, 180, 120), "Bloque C\nM2",
		_color_edif(2, C_EDIF), C_TECHO, C_TEXTO, 2)

	# BLOQUE B M2  x=520..700, y=520..640
	_edif(font, Rect2(520, 520, 180, 120), "Bloque B\nM2",
		_color_edif(2, C_EDIF), C_TECHO, C_TEXTO, 2)

	# RECTORADO M6  x=740..1060, y=480..660
	_edif(font, Rect2(740, 480, 320, 180), "Rectorado  M6",
		_color_edif(6, C_EDIF_VIP), C_TECHO, C_TEXTO, 6)

	# FOTOCOPIADO M1  x=0..180, y=580..700
	_edif(font, Rect2(0, 580, 180, 120), "Fotocop.\nM1",
		_color_edif(1, C_EDIF), C_TECHO, C_TEXTO, 1)

	# BLOQUE A M2  x=280..700, y=680..740  (franja inferior, el más sur)
	_edif(font, Rect2(280, 680, 420, 60), "Bloque A     M2",
		_color_edif(2, C_EDIF), C_TECHO, C_TEXTO, 2)

	# ── ÁRBOLES del campus ────────────────────────────────────
	for a in [
		# Corredor oeste
		Vector2(250, 180), Vector2(250, 420), Vector2(250, 610),
		# Sur del Estac
		Vector2(110, 550),
		# Entre patio y edificios
		Vector2(465, 330), Vector2(465, 500),
		# Este del Rectorado / sur de BloqueE
		Vector2(720, 450), Vector2(1060, 450),
		# Frente avenida
		Vector2(120, 720), Vector2(740, 720), Vector2(1190, 720),
	]:
		draw_circle(a, 12, Color(0.14, 0.38, 0.14))
		draw_circle(a - Vector2(3,3), 5, Color(0.22, 0.54, 0.18))

	# ── CONTENEDORES DE RECICLAJE (ahora gestionados como nodos interactivos zona_reciclaje.gd) ──
	# _dibujar_contenedores(font)

	# (Pájaros y reflejos del lago: los dibuja CapaAmbiente, ver arriba.)

	# ── SEÑAL DE ENTRADA ─────────────────────────────────────
	draw_rect(Rect2(380, 744, 140, 20), C_TECHO)
	draw_rect(Rect2(383, 746, 134, 16), C_AZUL_OS)
	draw_rect(Rect2(383, 746, 134, 16), C_AMARILLO, false, 1.5)
	_draw_str(font, "ENTRADA CAMPUS URBE", Vector2(450, 757), C_TEXTO, 8)

	draw_circle(Vector2(560, 754), 9, C_AMARILLO)
	draw_arc(Vector2(560, 754), 9, 0.0, TAU, 16, C_TECHO, 1.5)
	_draw_str(font, "U", Vector2(560, 757), C_AZUL_OS, 7)

	# ── MAPA DE AVANCE (opcional, encima de todo) ─────────────
	if mostrar_avance:
		_dibujar_mapa_avance(font)


# ── CONTENEDORES DE RECICLAJE ─────────────────────────────
# 5 contenedores por cluster: orgánico(café) plástico(amarillo)
# papel(azul) vidrio(verde) general(gris)
func _dibujar_contenedores(font: Font) -> void:
	var spots : Array = [
		Vector2(380,  96),   # Cafetín (camino norte, frente al edificio)
		Vector2(590,  96),   # Patio (camino norte)
		Vector2(250, 560),   # Corredor oeste (entre Estac y Fotocopiado)
		Vector2(380, 298),   # Pasillo Cafetín↔BloqueD
		Vector2(380, 498),   # Pasillo BloqueD↔BloqueC
		Vector2(460, 580),   # Pasillo entre Bloque C y B
		Vector2(760, 448),   # Zona sur BloqueE / norte Rectorado
		Vector2(490, 750),   # Avenida (frente a BloqueA)
		Vector2(900, 710),   # Sur del Rectorado / norte avenida
	]
	for sp in spots:
		_cluster_contenedor(sp, font)


func _cluster_contenedor(pos: Vector2, font: Font) -> void:
	var colores : Array = [
		Color(0.40, 0.20, 0.05),   # orgánico  (café)
		Color(0.94, 0.78, 0.04),   # plástico  (amarillo)
		Color(0.08, 0.25, 0.80),   # papel     (azul)
		Color(0.10, 0.62, 0.18),   # vidrio    (verde)
		Color(0.52, 0.52, 0.52),   # general   (gris)
	]
	var W : float = 7.0
	var H : float = 11.0
	var GAP : float = 1.5
	var total_w : float = colores.size() * W + (colores.size() - 1) * GAP
	var x0 : float = pos.x - total_w * 0.5
	for i in range(colores.size()):
		var cx : float = x0 + i * (W + GAP)
		draw_rect(Rect2(cx, pos.y, W, H), colores[i])
		draw_rect(Rect2(cx, pos.y, W, H), Color(0,0,0,0.7), false, 0.8)
		# tapa
		draw_rect(Rect2(cx - 0.5, pos.y - 2.5, W + 1, 3.5), colores[i].darkened(0.25))
		draw_rect(Rect2(cx - 0.5, pos.y - 2.5, W + 1, 3.5), Color(0,0,0,0.5), false, 0.6)
	# etiqueta ♻
	_draw_str(font, "♻", pos + Vector2(0, -8), Color(1,1,1,0.65), 7)


# ── HELPERS DE DIBUJO ─────────────────────────────────────

func _dibujar_indicador(pos: Vector2, modulo_id: int) -> void:
	var col := _color_indicador(modulo_id)
	if col == Color.TRANSPARENT:
		return
	draw_circle(pos, 6, col)
	draw_arc(pos, 6, 0.0, TAU, 16, Color(0,0,0,0.5), 1.5)


func _edif(font: Font, rect: Rect2, nombre: String,
		   color: Color, techo: Color, c_txt: Color,
		   modulo_id: int = -1) -> void:
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 10)), techo)
	if rect.size.x >= 80 and rect.size.y >= 50:
		var wx : float = rect.size.x / 3.0
		for wi in range(1, 3):
			draw_rect(
				Rect2(rect.position.x + wi * wx - 6, rect.position.y + 20, 12, 10),
				Color(0.60, 0.80, 1.0, 0.5)
			)
	draw_rect(rect, techo, false, 2.5)
	_txt(font, nombre, rect, c_txt, 10)
	if modulo_id != -1:
		var ind_pos := Vector2(rect.position.x + rect.size.x - 9, rect.position.y + 18)
		_dibujar_indicador(ind_pos, modulo_id)


func _txt(font: Font, texto: String, rect: Rect2, color: Color, size: int) -> void:
	var lineas := texto.split("\n")
	var bloque : float = float(lineas.size()) * float(size + 3)
	var y0 : float = rect.position.y + (rect.size.y - bloque) * 0.5 + size + 2
	for l in lineas:
		draw_string(font, Vector2(rect.position.x, y0), l,
					HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, color)
		y0 += size + 3


func _draw_str(font: Font, texto: String, centro: Vector2,
			   color: Color, size: int) -> void:
	draw_string(font, centro, texto, HORIZONTAL_ALIGNMENT_CENTER, -1, size, color)
