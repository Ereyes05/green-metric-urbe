# ============================================================
# mision_inicio.gd — URBE Rangers: Eco-Quest
# Pantalla intermedia que aparece al presionar E en una zona.
# Muestra: módulo, zona, descripción GreenMetric, NPC y estado.
# Emite: mision_aceptada(mision_id) o mision_cancelada()
# ============================================================
extends CanvasLayer

signal mision_aceptada(mision_id: String)
signal mision_cancelada()

# — Nodos internos ————————————————————————————————————————
var _icono_lbl    : Label     = null
var _modulo_lbl   : Label     = null
var _zona_lbl     : Label     = null
var _desc_lbl     : Label     = null
var _barra_bg     : ColorRect = null
var _barra_fill   : ColorRect = null
var _estado_lbl   : Label     = null
var _npc_lbl      : Label     = null
var _btn_aceptar  : Button    = null
var _btn_cancelar : Button    = null

# — Estado ————————————————————————————————————————————————
var _mision_id_actual : String = ""

# — Datos de cada módulo GreenMetric ──────────────────────
const MODULOS_INFO : Dictionary = {
	1: {
		"icono":  "🌿",
		"nombre": "Entorno e Infraestructura",
		"desc":   "GreenMetric evalúa los espacios verdes del campus, políticas ambientales institucionales y certificaciones ecológicas. No fija un mínimo: puntúa la proporción de área abierta y verde del campus, y a mayor proporción, mayor puntaje.",
		"color":  Color(0.18, 0.49, 0.20),
	},
	2: {
		"icono":  "⚡",
		"nombre": "Energía y Cambio Climático",
		"desc":   "Se mide el consumo eléctrico por edificio, el uso de energías renovables y las emisiones de CO₂ generadas por las actividades del campus. Reducir el consumo y adoptar paneles solares mejora directamente el ranking.",
		"color":  Color(0.90, 0.50, 0.00),
	},
	3: {
		"icono":  "♻",
		"nombre": "Residuos",
		"desc":   "GreenMetric evalúa los programas de clasificación de residuos, compostaje orgánico y reducción de plásticos de un solo uso. Solo el 30% de los residuos del campus se clasifica correctamente actualmente.",
		"color":  Color(0.80, 0.65, 0.00),
	},
	4: {
		"icono":  "💧",
		"nombre": "Agua",
		"desc":   "Se evalúa si el campus cuenta con hidrómetros instalados, programas de conservación hídrica y sistemas de reutilización de aguas grises. La Biblioteca es el edificio con mayor consumo sin medición.",
		"color":  Color(0.00, 0.45, 0.75),
	},
	5: {
		"icono":  "🚲",
		"nombre": "Transporte",
		"desc":   "GreenMetric mide cuántos miembros de la comunidad universitaria usan transporte público, bicicleta o caminan. Actualmente el 78% llega en vehículo privado, lo que impacta negativamente el puntaje.",
		"color":  Color(0.10, 0.30, 0.80),
	},
	6: {
		"icono":  "📚",
		"nombre": "Educación e Investigación",
		"desc":   "Evalúa las asignaturas de sostenibilidad ofrecidas, las publicaciones científicas ambientales y los eventos de concienciación. Este módulo actúa como multiplicador del efecto de todos los demás indicadores.",
		"color":  Color(0.35, 0.00, 0.65),
	},
}


func _ready() -> void:
	layer = 12
	add_to_group("ui_mision_inicio")
	_crear_ui()
	hide()


# ── API pública ───────────────────────────────────────────
func mostrar(modulo_id: int, nombre_zona: String,
			 nombre_npc: String, mision_id: String,
			 progreso: float = 0.40) -> void:

	_mision_id_actual = mision_id

	var info : Dictionary = MODULOS_INFO.get(modulo_id, {
		"icono": "🌍", "nombre": "Módulo", "desc": "", "color": Color.GRAY
	})

	_icono_lbl.text  = info["icono"]
	_modulo_lbl.text = "MÓDULO %d — %s" % [modulo_id, info["nombre"]]
	_modulo_lbl.add_theme_color_override("font_color", info["color"])
	_zona_lbl.text   = "📍 " + nombre_zona
	_desc_lbl.text   = info["desc"]

	var pct : float = clampf(progreso, 0.0, 1.0)
	_barra_fill.size.x = 480.0 * pct
	_barra_fill.color  = _color_estado(pct)

	var pct_int : int = int(pct * 100.0)
	var estado_txt : String
	if pct < 0.40:
		estado_txt = "⚠ En riesgo"
		_estado_lbl.add_theme_color_override("font_color", Color(0.95, 0.30, 0.30))
	elif pct < 0.75:
		estado_txt = "● Moderado"
		_estado_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.10))
	else:
		estado_txt = "✓ Óptimo"
		_estado_lbl.add_theme_color_override("font_color", Color(0.25, 0.88, 0.25))
	_estado_lbl.text = "%d%%  %s" % [pct_int, estado_txt]

	_npc_lbl.text = "👤 NPC disponible:  " + nombre_npc

	show()


# ── Internos ──────────────────────────────────────────────
func _color_estado(pct: float) -> Color:
	if pct < 0.40:
		return Color(0.80, 0.18, 0.18)
	elif pct < 0.75:
		return Color(0.88, 0.65, 0.08)
	else:
		return Color(0.18, 0.75, 0.18)


func _on_aceptar() -> void:
	hide()
	await get_tree().process_frame
	mision_aceptada.emit(_mision_id_actual)


func _on_cancelar() -> void:
	hide()
	await get_tree().process_frame
	mision_cancelada.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_cancelar()


# ── Construcción de UI ────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.70)
	add_child(overlay)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(620, 400)
	panel.offset_left   = -310.0
	panel.offset_top    = -200.0
	panel.offset_right  =  310.0
	panel.offset_bottom =  200.0

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.08, 0.12, 0.98)
	ps.border_color = Color(0.20, 0.68, 0.20)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   28)
	mg.add_theme_constant_override("margin_right",  28)
	mg.add_theme_constant_override("margin_top",    22)
	mg.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(header_hbox)

	_icono_lbl = Label.new()
	_icono_lbl.add_theme_font_size_override("font_size", 28)
	header_hbox.add_child(_icono_lbl)

	_modulo_lbl = Label.new()
	_modulo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modulo_lbl.add_theme_font_size_override("font_size", 16)
	_modulo_lbl.add_theme_color_override("font_color", Color(0.25, 0.88, 0.25))
	header_hbox.add_child(_modulo_lbl)

	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.20, 0.68, 0.20, 0.40)
	sep_style.content_margin_top    = 1.0
	sep_style.content_margin_bottom = 1.0

	var sep1 := HSeparator.new()
	sep1.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep1)

	_zona_lbl = Label.new()
	_zona_lbl.add_theme_font_size_override("font_size", 13)
	_zona_lbl.add_theme_color_override("font_color", Color(0.70, 0.85, 1.00))
	vbox.add_child(_zona_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc_lbl.add_theme_font_size_override("font_size", 13)
	_desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	vbox.add_child(_desc_lbl)

	var barra_lbl := Label.new()
	barra_lbl.text = "Estado actual del módulo:"
	barra_lbl.add_theme_font_size_override("font_size", 11)
	barra_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(barra_lbl)

	var barra_row := HBoxContainer.new()
	barra_row.add_theme_constant_override("separation", 10)
	vbox.add_child(barra_row)

	_barra_bg = ColorRect.new()
	_barra_bg.custom_minimum_size   = Vector2(480, 18)
	_barra_bg.color                 = Color(0.12, 0.16, 0.22)
	_barra_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra_row.add_child(_barra_bg)

	var barra_cont := Control.new()
	barra_cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_barra_bg.add_child(barra_cont)

	_barra_fill = ColorRect.new()
	_barra_fill.position = Vector2(0, 0)
	_barra_fill.size     = Vector2(200, 18)
	barra_cont.add_child(_barra_fill)

	_estado_lbl = Label.new()
	_estado_lbl.add_theme_font_size_override("font_size", 12)
	barra_row.add_child(_estado_lbl)

	var sep2 := HSeparator.new()
	sep2.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep2)

	_npc_lbl = Label.new()
	_npc_lbl.add_theme_font_size_override("font_size", 13)
	_npc_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.40))
	vbox.add_child(_npc_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	_btn_aceptar = Button.new()
	_btn_aceptar.text = "  Aceptar misión  "
	_btn_aceptar.custom_minimum_size = Vector2(180, 40)
	_btn_aceptar.add_theme_font_size_override("font_size", 14)
	var s_acep := StyleBoxFlat.new()
	s_acep.bg_color     = Color(0.10, 0.42, 0.10)
	s_acep.border_color = Color(0.22, 0.80, 0.22)
	s_acep.set_border_width_all(2)
	s_acep.set_corner_radius_all(8)
	_btn_aceptar.add_theme_stylebox_override("normal", s_acep)
	var s_acep_h := s_acep.duplicate()
	s_acep_h.bg_color = Color(0.14, 0.55, 0.14)
	_btn_aceptar.add_theme_stylebox_override("hover", s_acep_h)
	_btn_aceptar.pressed.connect(_on_aceptar)
	btn_row.add_child(_btn_aceptar)

	_btn_cancelar = Button.new()
	_btn_cancelar.text = "  Cancelar  "
	_btn_cancelar.custom_minimum_size = Vector2(120, 40)
	_btn_cancelar.add_theme_font_size_override("font_size", 14)
	var s_can := StyleBoxFlat.new()
	s_can.bg_color     = Color(0.18, 0.10, 0.10)
	s_can.border_color = Color(0.55, 0.22, 0.22)
	s_can.set_border_width_all(2)
	s_can.set_corner_radius_all(8)
	_btn_cancelar.add_theme_stylebox_override("normal", s_can)
	var s_can_h := s_can.duplicate()
	s_can_h.bg_color = Color(0.30, 0.12, 0.12)
	_btn_cancelar.add_theme_stylebox_override("hover", s_can_h)
	_btn_cancelar.pressed.connect(_on_cancelar)
	btn_row.add_child(_btn_cancelar)