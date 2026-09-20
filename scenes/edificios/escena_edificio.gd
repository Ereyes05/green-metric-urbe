# escena_edificio.gd — URBE Rangers: Eco-Quest
# Pantalla de interior de edificio. Se muestra como overlay sobre el campus.
extends CanvasLayer

signal hablar_npc_solicitado
signal salida_solicitada

var _zona_key  : String     = ""
var _mod_id    : int        = 1
var _col       : Color      = Color(0.18, 0.55, 0.20)
var _nombre_ed : String     = "Edificio"
var _npc_nombre: String     = "Persona"
var _desc      : String     = ""

var _raiz        : Panel   = null
var _lbl_nombre  : Label   = null
var _lbl_mod     : Label   = null
var _lbl_npc     : Label   = null
var _lbl_desc    : Label   = null
var _btn_hablar  : Button  = null
var _btn_salir   : Button  = null
var _franja      : ColorRect = null
var _npc_bg      : ColorRect = null

const MOD_COLORES : Array = [
	Color(0,0,0),
	Color(0.12, 0.42, 0.15),   # M1 Entorno
	Color(0.72, 0.32, 0.00),   # M2 Energía
	Color(0.62, 0.50, 0.00),   # M3 Residuos
	Color(0.00, 0.32, 0.52),   # M4 Agua
	Color(0.08, 0.20, 0.68),   # M5 Transporte
	Color(0.28, 0.00, 0.52),   # M6 Educación
]
const MOD_ICONOS  : Array = ["?","🌿","⚡","♻","💧","🚲","📚"]
const MOD_NOMBRES : Array = [
	"?",
	"Entorno e Infraestructura",
	"Energía y Cambio Climático",
	"Gestión de Residuos",
	"Conservación del Agua",
	"Transporte Sostenible",
	"Educación e Investigación",
]


func _ready() -> void:
	layer   = 20
	visible = false
	_construir_ui()


func mostrar(zona_key: String, info: Dictionary, nombre_npc: String) -> void:
	_zona_key   = zona_key
	_mod_id     = int(info.get("modulo_id", 1))
	_nombre_ed  = str(info.get("nombre", zona_key)).replace("_", " ")
	_npc_nombre = nombre_npc
	_desc       = _obtener_desc(zona_key)
	_col        = MOD_COLORES[clamp(_mod_id, 1, 6)]
	_actualizar_visual()
	visible = true
	# CanvasLayer no tiene modulate; se anima el Panel raíz (_raiz) que sí
	# es CanvasItem y hereda la propiedad modulate.
	if is_instance_valid(_raiz):
		_raiz.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_raiz, "modulate:a", 1.0, 0.30)


func ocultar() -> void:
	if is_instance_valid(_raiz):
		var tw := create_tween()
		tw.tween_property(_raiz, "modulate:a", 0.0, 0.22)
		tw.tween_callback(func():
			visible = false
			_raiz.modulate.a = 1.0
		)
	else:
		visible = false


# ── Construcción de UI ───────────────────────────────────────
func _construir_ui() -> void:
	_raiz = Panel.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.06, 0.08)
	_raiz.add_theme_stylebox_override("panel", ps)
	add_child(_raiz)

	# ── Pared del fondo (parte superior) ──────────────────────
	var techo := ColorRect.new()
	techo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	techo.offset_bottom = 150.0
	techo.color = Color(0.10, 0.10, 0.13)
	_raiz.add_child(techo)

	# Franja de color del módulo
	_franja = ColorRect.new()
	_franja.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_franja.offset_bottom = 7.0
	_franja.color = Color(0.30, 0.75, 0.35)
	_raiz.add_child(_franja)

	# Ventanas (3)
	for wi : int in 3:
		var win := ColorRect.new()
		win.set_anchors_preset(Control.PRESET_TOP_LEFT)
		var wx : float = 160.0 + float(wi) * 340.0
		win.offset_left   = wx
		win.offset_top    = 18.0
		win.offset_right  = wx + 150.0
		win.offset_bottom = 118.0
		win.color = Color(0.55, 0.78, 1.0, 0.45)
		_raiz.add_child(win)
		var marco := Panel.new()
		marco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var ms := StyleBoxFlat.new()
		ms.bg_color     = Color(0,0,0,0)
		ms.border_color = Color(0.82, 0.82, 0.86)
		ms.set_border_width_all(4)
		win.add_child(marco)

	# Nombre del edificio
	_lbl_nombre = Label.new()
	_lbl_nombre.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_lbl_nombre.offset_top    = 8.0
	_lbl_nombre.offset_bottom = 60.0
	_lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_nombre.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_lbl_nombre.add_theme_font_size_override("font_size", 28)
	_lbl_nombre.add_theme_color_override("font_color", Color.WHITE)
	_raiz.add_child(_lbl_nombre)

	# Módulo
	_lbl_mod = Label.new()
	_lbl_mod.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_lbl_mod.offset_top    = 62.0
	_lbl_mod.offset_bottom = 100.0
	_lbl_mod.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_mod.add_theme_font_size_override("font_size", 13)
	_lbl_mod.add_theme_color_override("font_color", Color(0.76, 0.88, 0.78))
	_raiz.add_child(_lbl_mod)

	# ── Piso del pasillo ──────────────────────────────────────
	var piso := ColorRect.new()
	piso.set_anchors_preset(Control.PRESET_FULL_RECT)
	piso.offset_top    = 150.0
	piso.offset_bottom = -110.0
	piso.color = Color(0.72, 0.68, 0.62)
	_raiz.add_child(piso)

	# Baldosas (alternadas)
	var TS : float = 48.0
	for row : int in 12:
		for col : int in 30:
			if (row + col) % 2 == 0:
				var tile := ColorRect.new()
				tile.set_anchors_preset(Control.PRESET_TOP_LEFT)
				tile.offset_left   = float(col) * TS
				tile.offset_top    = 150.0 + float(row) * TS
				tile.offset_right  = float(col) * TS + TS
				tile.offset_bottom = 150.0 + float(row) * TS + TS
				tile.color = Color(0.66, 0.62, 0.56, 1.0)
				tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_raiz.add_child(tile)

	# Paredes laterales
	var pared_izq := ColorRect.new()
	pared_izq.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	pared_izq.offset_top    = 150.0
	pared_izq.offset_bottom = -110.0
	pared_izq.offset_right  = 90.0
	pared_izq.color = Color(0.14, 0.14, 0.18)
	_raiz.add_child(pared_izq)

	var pared_der := ColorRect.new()
	pared_der.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	pared_der.offset_top    = 150.0
	pared_der.offset_bottom = -110.0
	pared_der.offset_left   = -90.0
	pared_der.color = Color(0.14, 0.14, 0.18)
	_raiz.add_child(pared_der)

	# Casilleros (pared izquierda)
	for li : int in 4:
		var lk := ColorRect.new()
		lk.set_anchors_preset(Control.PRESET_TOP_LEFT)
		lk.offset_left   = 5.0
		lk.offset_top    = 160.0 + float(li) * 110.0
		lk.offset_right  = 83.0
		lk.offset_bottom = 258.0 + float(li) * 110.0
		lk.color = Color(0.20, 0.20, 0.26)
		_raiz.add_child(lk)
		var lk2 := ColorRect.new()
		lk2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lk2.offset_left   = 4.0
		lk2.offset_top    = 4.0
		lk2.offset_right  = -4.0
		lk2.offset_bottom = -4.0
		lk2.color = Color(0.26, 0.26, 0.34)
		lk.add_child(lk2)

	# Tablón de anuncios (pared derecha)
	var board_outer := ColorRect.new()
	board_outer.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	board_outer.offset_left   = -87.0
	board_outer.offset_top    = 168.0
	board_outer.offset_right  = -5.0
	board_outer.offset_bottom = 500.0
	board_outer.color = Color(0.40, 0.26, 0.10)
	_raiz.add_child(board_outer)

	var board_inner := ColorRect.new()
	board_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_inner.offset_left   = 5.0
	board_inner.offset_top    = 5.0
	board_inner.offset_right  = -5.0
	board_inner.offset_bottom = -5.0
	board_inner.color = Color(0.24, 0.52, 0.22)
	board_outer.add_child(board_inner)

	for pi : int in 4:
		var papel := ColorRect.new()
		papel.set_anchors_preset(Control.PRESET_TOP_WIDE)
		papel.offset_left   = 5.0
		papel.offset_top    = 6.0 + float(pi) * 72.0
		papel.offset_right  = -5.0
		papel.offset_bottom = 58.0 + float(pi) * 72.0
		papel.color = Color(0.96, 0.94, 0.86)
		board_inner.add_child(papel)

	# Área de NPC (centro)
	_npc_bg = ColorRect.new()
	_npc_bg.set_anchors_preset(Control.PRESET_CENTER)
	_npc_bg.offset_left   = -80.0
	_npc_bg.offset_top    = -90.0
	_npc_bg.offset_right  =  80.0
	_npc_bg.offset_bottom =  80.0
	_npc_bg.color = Color(0.10, 0.28, 0.12, 0.55)
	_raiz.add_child(_npc_bg)

	var npc_emoji := Label.new()
	npc_emoji.text = "🧑‍🏫"
	npc_emoji.set_anchors_preset(Control.PRESET_CENTER)
	npc_emoji.offset_left   = -40.0
	npc_emoji.offset_top    = -100.0
	npc_emoji.offset_right  =  40.0
	npc_emoji.offset_bottom = -10.0
	npc_emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_emoji.add_theme_font_size_override("font_size", 62)
	_raiz.add_child(npc_emoji)

	_lbl_npc = Label.new()
	_lbl_npc.set_anchors_preset(Control.PRESET_CENTER)
	_lbl_npc.offset_left   = -140.0
	_lbl_npc.offset_top    =  -5.0
	_lbl_npc.offset_right  =  140.0
	_lbl_npc.offset_bottom =  24.0
	_lbl_npc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_npc.add_theme_font_size_override("font_size", 14)
	_lbl_npc.add_theme_color_override("font_color", Color(0.28, 0.90, 0.35))
	_raiz.add_child(_lbl_npc)

	_lbl_desc = Label.new()
	_lbl_desc.set_anchors_preset(Control.PRESET_CENTER)
	_lbl_desc.offset_left   = -220.0
	_lbl_desc.offset_top    =  32.0
	_lbl_desc.offset_right  =  220.0
	_lbl_desc.offset_bottom =  88.0
	_lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_desc.add_theme_font_size_override("font_size", 11)
	_lbl_desc.add_theme_color_override("font_color", Color(0.65, 0.72, 0.65))
	_lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_raiz.add_child(_lbl_desc)

	# ── Barra inferior con botones ────────────────────────────
	var bar := ColorRect.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -110.0
	bar.color = Color(0.08, 0.08, 0.10)
	_raiz.add_child(bar)

	# Puerta visual
	var puerta := ColorRect.new()
	puerta.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	puerta.offset_top    = -110.0
	puerta.offset_left   =  570.0
	puerta.offset_right  = -570.0
	puerta.color = Color(0.26, 0.20, 0.12)
	_raiz.add_child(puerta)

	# Botón hablar
	_btn_hablar = Button.new()
	_btn_hablar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_btn_hablar.offset_left   = 60.0
	_btn_hablar.offset_top    = -96.0
	_btn_hablar.offset_right  = 500.0
	_btn_hablar.offset_bottom = -14.0
	_btn_hablar.add_theme_font_size_override("font_size", 15)
	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color     = Color(0.08, 0.22, 0.10)
	sb_h.border_color = Color(0.28, 0.78, 0.32)
	sb_h.set_border_width_all(2)
	sb_h.set_corner_radius_all(8)
	_btn_hablar.add_theme_stylebox_override("normal", sb_h)
	_btn_hablar.pressed.connect(func(): hablar_npc_solicitado.emit())
	_raiz.add_child(_btn_hablar)

	# Botón salir
	_btn_salir = Button.new()
	_btn_salir.text = "🚪  Salir al campus"
	_btn_salir.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_btn_salir.offset_left   = -500.0
	_btn_salir.offset_top    = -96.0
	_btn_salir.offset_right  = -60.0
	_btn_salir.offset_bottom = -14.0
	_btn_salir.add_theme_font_size_override("font_size", 15)
	var sb_s := StyleBoxFlat.new()
	sb_s.bg_color     = Color(0.16, 0.06, 0.06)
	sb_s.border_color = Color(0.62, 0.20, 0.20)
	sb_s.set_border_width_all(2)
	sb_s.set_corner_radius_all(8)
	_btn_salir.add_theme_stylebox_override("normal", sb_s)
	_btn_salir.pressed.connect(func(): salida_solicitada.emit())
	_raiz.add_child(_btn_salir)


func _actualizar_visual() -> void:
	_col = MOD_COLORES[clamp(_mod_id, 1, 6)]
	var idx    : int    = clamp(_mod_id, 1, 6)
	var icono  : String = MOD_ICONOS[idx]
	var mod_nm : String = MOD_NOMBRES[idx]

	if is_instance_valid(_franja):
		_franja.color = _col.lightened(0.15)
	if is_instance_valid(_npc_bg):
		_npc_bg.color = Color(_col.r, _col.g, _col.b, 0.30)
	if is_instance_valid(_lbl_nombre):
		_lbl_nombre.text = "🏫  %s" % _nombre_ed
	if is_instance_valid(_lbl_mod):
		_lbl_mod.text = "%s  Módulo %d — %s" % [icono, _mod_id, mod_nm]
	if is_instance_valid(_lbl_npc):
		_lbl_npc.text = "👤  %s" % _npc_nombre
	if is_instance_valid(_lbl_desc):
		_lbl_desc.text = _desc
	if is_instance_valid(_btn_hablar):
		_btn_hablar.text     = "💬  Hablar con %s" % _npc_nombre
		_btn_hablar.disabled = false
		_btn_hablar.remove_theme_color_override("font_color")


func _obtener_desc(zona_key: String) -> String:
	var desc : Dictionary = {
		"ZonaEstacionamiento": "Estacionamiento M5 — Alta concentración de vehículos privados.\nGreenMetric evalúa la movilidad sostenible del campus.",
		"ZonaCafetin":         "Cafetín SNÖ URBE — Principal zona de generación de residuos.\nGreenMetric evalúa la clasificación y manejo de desechos.",
		"ZonaBloqueE":         "Bloque E — Laboratorios de cómputo de alto consumo.\nGreenMetric evalúa energía, cambio climático y emisiones.",
		"ZonaBloqueD":         "Bloque D — Aulas con paneles solares en el techo.\nEnergía renovable como factor clave del ranking.",
		"ZonaBloqueC":         "Bloque C — Iluminación ineficiente en pasillos.\nCambio a LED y sensores de movimiento pendiente.",
		"ZonaBloqueB":         "Bloque B — Laboratorios de alta demanda energética.\nCO₂ y emisiones bajo evaluación GreenMetric.",
		"ZonaBloqueA":         "Bloque A — Aulas con alto consumo por aire acondicionado.\nGreenMetric mide eficiencia energética por edificio.",
		"ZonaRectorado":       "Rectorado — Centro de coordinación institucional de URBE.\nNodo principal del ranking UI GreenMetric.",
		"ZonaFotocopiado":     "Centro de Fotocopiado — Millones de hojas anuales.\nGreenMetric evalúa políticas de reducción de papel.",
		"ZonaBloqueF":         "Estudios a Distancia — Infraestructura para educación virtual.\nGreenMetric valora sostenibilidad en entorno construido.",
		"ZonaAreaServicios":   "SERVIEDUCA — Servicios Educativos CA.\nPublicaciones científicas e investigación en sostenibilidad.",
		"ZonaPatio":           "Patio Central — Área verde con fuentes y arborización.\nGreenMetric evalúa gestión del agua y áreas verdes.",
	}
	return desc.get(zona_key, "Área del campus URBE bajo evaluación GreenMetric.")
