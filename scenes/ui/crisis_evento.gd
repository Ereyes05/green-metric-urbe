# ============================================================
# crisis_evento.gd — URBE Rangers: Eco-Quest
# Eventos de crisis aleatorios durante la exploración.
# 3 tipos: Apagón (M2), Fuga de Agua (M4), Basura (M3).
# 10 segundos para responder. Señal crisis_resulta(modulo, ok).
# ============================================================
extends CanvasLayer

signal crisis_resulta(modulo_id: int, exito: bool)

const CRISIS : Array = [
	{
		"tipo":     "Apagón Eléctrico",
		"icono":    "⚡",
		"modulo":   2,
		"color":    Color(0.90, 0.55, 0.05),
		"desc":     "¡El campus sufrió un apagón de emergencia! La UPS del servidor central falló y varios laboratorios quedaron sin electricidad.",
		"pregunta": "¿Cuál es la acción correcta para reducir el impacto ambiental durante el apagón?",
		"ops": [
			"Encender todos los generadores diésel de respaldo",
			"Activar el sistema de energía solar de emergencia y apagar equipos no esenciales",
			"Dejar todo como está y esperar a que vuelva la corriente"
		],
		"correcta": 1,
		"feedback_ok":   "¡Correcto! La energía solar reduce emisiones y minimiza el consumo.",
		"feedback_fail":  "El diésel genera más CO₂. Lo correcto era activar la energía solar.",
	},
	{
		"tipo":     "Fuga de Agua",
		"icono":    "💧",
		"modulo":   4,
		"color":    Color(0.05, 0.50, 0.90),
		"desc":     "¡Se detectó una fuga mayor en la tubería principal del campus! El agua se desperdicia a razón de 200 litros por hora.",
		"pregunta": "¿Cuál es la acción más efectiva para minimizar el desperdicio de agua?",
		"ops": [
			"Llamar a plomería mañana cuando estén disponibles",
			"Cerrar la llave principal de inmediato y reportar a mantenimiento de emergencia",
			"Ignorar si la fuga parece pequeña visualmente"
		],
		"correcta": 1,
		"feedback_ok":   "¡Excelente! Cerrar la llave principal evita pérdidas masivas de agua potable.",
		"feedback_fail":  "Esperar agrava el desperdicio. Cerrar la llave principal es la acción urgente.",
	},
	{
		"tipo":     "Basura Desbordada",
		"icono":    "♻",
		"modulo":   3,
		"color":    Color(0.35, 0.70, 0.15),
		"desc":     "¡Los contenedores del campus están saturados! Los residuos de diferentes tipos se están mezclando. El camión de basura no llegó.",
		"pregunta": "¿Qué acción urgente tomar para el manejo correcto de los residuos?",
		"ops": [
			"Quemar los residuos en el patio trasero para eliminarlos rápido",
			"Separar manualmente lo reciclable y llamar a servicio de recolección especial",
			"Enterrar todo en el jardín del campus para que se descomponga"
		],
		"correcta": 1,
		"feedback_ok":   "¡Correcto! Separar y reportar es la práctica responsable de gestión de residuos.",
		"feedback_fail":  "Quemar o enterrar contamina el suelo y el aire. La clasificación y el reporte son clave.",
	},
]

const TIEMPO_MAX : float = 10.0

var _crisis_actual  : Dictionary = {}
var _tiempo_restante : float     = 0.0
var _activa          : bool      = false

var _overlay         : ColorRect    = null
var _panel           : Panel        = null
var _titulo_lbl      : Label        = null
var _icono_lbl       : Label        = null
var _desc_lbl        : Label        = null
var _pregunta_lbl    : Label        = null
var _barra_bg        : ColorRect    = null
var _barra_fill      : ColorRect    = null
var _tiempo_lbl      : Label        = null
var _btn_ops         : Array        = []
var _feedback_lbl    : Label        = null
var _flash_overlay   : ColorRect    = null


func _ready() -> void:
	layer = 18
	add_to_group("ui_crisis")
	_crear_ui()
	hide()


func iniciar_aleatoria() -> void:
	if visible: return
	var idx : int = randi() % CRISIS.size()
	_lanzar(CRISIS[idx])


func _lanzar(crisis: Dictionary) -> void:
	_crisis_actual   = crisis
	_tiempo_restante = TIEMPO_MAX
	_activa          = true

	# Estilo dinámico según el módulo
	var col : Color = crisis["color"]
	_panel.get_theme_stylebox("panel").border_color = col
	_titulo_lbl.text = "⚠ CRISIS DE CAMPUS — %s" % crisis["tipo"]
	_titulo_lbl.add_theme_color_override("font_color", col)
	_icono_lbl.text  = crisis["icono"]
	_desc_lbl.text   = crisis["desc"]
	_pregunta_lbl.text = crisis["pregunta"]
	_barra_fill.color  = col
	_feedback_lbl.visible = false

	var ops : Array = crisis["ops"]
	for i in _btn_ops.size():
		if i < ops.size():
			_btn_ops[i].text    = "  %s  " % ops[i]
			_btn_ops[i].disabled = false
			_btn_ops[i].modulate = Color.WHITE

	show()

	# Efecto de entrada con flash rojo
	_flash_overlay.color = Color(0.88, 0.10, 0.10, 0.0)
	var tw := create_tween()
	tw.tween_property(_flash_overlay, "color:a", 0.30, 0.12)
	tw.tween_property(_flash_overlay, "color:a", 0.0,  0.30)


func _process(delta: float) -> void:
	if not visible or not _activa: return
	_tiempo_restante -= delta
	var pct : float = clampf(_tiempo_restante / TIEMPO_MAX, 0.0, 1.0)
	_barra_fill.size.x = 520.0 * pct
	_tiempo_lbl.text   = "⏱ %d s" % ceili(_tiempo_restante)

	if _tiempo_restante <= 3.0:
		_barra_fill.color = Color(0.90, 0.15, 0.15)
	elif _tiempo_restante <= 6.0:
		_barra_fill.color = Color(0.90, 0.65, 0.10)
	else:
		_barra_fill.color = _crisis_actual.get("color", Color(0.22, 0.78, 0.22))

	if _tiempo_restante <= 0.0:
		_resolver(false, -1)


func _resolver(correcto: bool, idx_btn: int) -> void:
	_activa = false

	# Las crisis son decisiones bajo presión de tiempo: para la tesis son
	# evidencia directa de "toma de decisiones" (empoderamiento), no solo
	# de conocimiento.
	# El id sale de "tipo" (no hay campo "id" en las crisis): se normaliza a
	# minúsculas con guiones bajos para que sea estable como identificador.
	var tipo : String = str(_crisis_actual.get("tipo", "sin_tipo"))
	SupabaseManager.registrar_evento(
		int(_crisis_actual["modulo"]),
		"crisis_%s" % tipo.to_lower().replace(" ", "_"),
		"crisis_resuelta",
		{
			"tipo"            : tipo,
			"opcion_elegida"  : idx_btn,
			"opcion_correcta" : int(_crisis_actual["correcta"]),
		},
		correcto)
	for i in _btn_ops.size():
		_btn_ops[i].disabled = true
		if i == _crisis_actual["correcta"]:
			_btn_ops[i].modulate = Color(0.30, 1.0, 0.35)
		elif i == idx_btn and not correcto:
			_btn_ops[i].modulate = Color(1.0, 0.25, 0.25)

	_feedback_lbl.text    = _crisis_actual["feedback_ok"] if correcto else _crisis_actual["feedback_fail"]
	_feedback_lbl.add_theme_color_override("font_color", Color(0.28, 0.92, 0.28) if correcto else Color(1.0, 0.35, 0.35))
	_feedback_lbl.visible = true

	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		hide()
		crisis_resulta.emit(int(_crisis_actual["modulo"]), correcto))


func _on_opcion(idx: int) -> void:
	if not _activa: return
	var correcto : bool = (idx == int(_crisis_actual["correcta"]))
	_resolver(correcto, idx)


# ── Construcción UI ───────────────────────────────────────────
func _crear_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	add_child(_overlay)

	_flash_overlay = ColorRect.new()
	_flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_overlay.color          = Color(0.88, 0.10, 0.10, 0.0)
	_flash_overlay.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_overlay)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(680, 460)
	_panel.offset_left   = -340.0
	_panel.offset_top    = -230.0
	_panel.offset_right  =  340.0
	_panel.offset_bottom =  230.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.04, 0.04, 0.98)
	ps.border_color = Color(0.88, 0.18, 0.18)
	ps.set_border_width_all(4)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.80, 0.10, 0.10, 0.50)
	ps.shadow_size  = 30
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(m, 28)
	_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	# Título con ícono
	var titulo_row := HBoxContainer.new()
	titulo_row.alignment = BoxContainer.ALIGNMENT_CENTER
	titulo_row.add_theme_constant_override("separation", 10)
	vbox.add_child(titulo_row)

	_icono_lbl = Label.new()
	_icono_lbl.add_theme_font_size_override("font_size", 32)
	titulo_row.add_child(_icono_lbl)

	_titulo_lbl = Label.new()
	_titulo_lbl.add_theme_font_size_override("font_size", 17)
	_titulo_lbl.add_theme_color_override("font_color", Color(0.90, 0.20, 0.20))
	_titulo_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo_row.add_child(_titulo_lbl)

	# Descripción
	_desc_lbl = Label.new()
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_desc_lbl.add_theme_font_size_override("font_size", 13)
	_desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
	vbox.add_child(_desc_lbl)

	# Barra de tiempo
	var sep_t := StyleBoxFlat.new()
	sep_t.bg_color = Color(0.18, 0.10, 0.10)
	sep_t.content_margin_top = 1.0; sep_t.content_margin_bottom = 1.0
	var sep := HSeparator.new(); sep.add_theme_stylebox_override("separator", sep_t)
	vbox.add_child(sep)

	var barra_row := HBoxContainer.new()
	barra_row.add_theme_constant_override("separation", 10)
	vbox.add_child(barra_row)

	_tiempo_lbl = Label.new()
	_tiempo_lbl.custom_minimum_size = Vector2(60, 0)
	_tiempo_lbl.add_theme_font_size_override("font_size", 14)
	_tiempo_lbl.add_theme_color_override("font_color", Color(0.90, 0.30, 0.10))
	barra_row.add_child(_tiempo_lbl)

	_barra_bg = ColorRect.new()
	_barra_bg.custom_minimum_size    = Vector2(520, 14)
	_barra_bg.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	_barra_bg.color = Color(0.15, 0.10, 0.10)
	barra_row.add_child(_barra_bg)

	_barra_fill = ColorRect.new()
	_barra_fill.size  = Vector2(520, 14)
	_barra_fill.color = Color(0.90, 0.18, 0.18)
	_barra_bg.add_child(_barra_fill)

	# Pregunta
	_pregunta_lbl = Label.new()
	_pregunta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_pregunta_lbl.add_theme_font_size_override("font_size", 14)
	_pregunta_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	vbox.add_child(_pregunta_lbl)

	# Opciones
	_btn_ops.clear()
	for i in 3:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", 13)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		var s := StyleBoxFlat.new()
		s.bg_color     = Color(0.12, 0.08, 0.08)
		s.border_color = Color(0.40, 0.25, 0.25)
		s.set_border_width_all(1)
		s.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("normal", s)
		var s_h := s.duplicate(); s_h.bg_color = Color(0.22, 0.12, 0.12)
		btn.add_theme_stylebox_override("hover", s_h)
		var ci := i
		btn.pressed.connect(func(): _on_opcion(ci))
		vbox.add_child(btn)
		_btn_ops.append(btn)

	# Feedback
	_feedback_lbl = Label.new()
	_feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_lbl.add_theme_font_size_override("font_size", 13)
	_feedback_lbl.visible = false
	vbox.add_child(_feedback_lbl)
