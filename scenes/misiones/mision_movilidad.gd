# ============================================================
# mision_movilidad.gd — NIVEL 5: Transporte Sostenible
# Panel de decisión (mismo formato visual que simulador_decision.gd)
# pero cada escenario cuenta como una misión real del nivel.
# Se abre uno por visita a la Oficina de Movilidad — el siguiente
# escenario sin responder, no una rotación aleatoria.
# ============================================================
extends CanvasLayer

signal mision_movilidad_completada(mision_id: String, xp: int, ec: int)

const ESCENARIOS_MOVILIDAD : Array = [
	{
		"id": "mov_parqueo", "icono": "🚗", "color": Color(0.90, 0.45, 0.10),
		"titulo": "Permisos de Estacionamiento",
		"contexto": "URBE tiene un estacionamiento saturado: hay más carros y motos registrados que espacios disponibles. La proporción de vehículos por persona en el campus es uno de los indicadores que GreenMetric evalúa directamente.",
		"pregunta": "¿Qué política de permisos de estacionamiento implementarías?",
		"opciones": [
			{"texto": "Limitar permisos de carro privado a quienes no tengan alternativa de transporte",
			 "impacto": "+20% ImpactRating", "delta": 0.20,
			 "edu": "Reducir la proporción de vehículos por persona es exactamente lo que mide el indicador TR1 de GreenMetric.",
			 "color": Color(0.18, 0.82, 0.18)},
			{"texto": "Construir un nuevo estacionamiento para aumentar los espacios disponibles",
			 "impacto": "-10% ImpactRating", "delta": -0.10,
			 "edu": "Más estacionamiento incentiva más uso del vehículo privado — contradice el objetivo del indicador.",
			 "color": Color(0.90, 0.20, 0.20)},
			{"texto": "Dejar los permisos como están",
			 "impacto": "+2% ImpactRating", "delta": 0.02,
			 "edu": "No actuar mantiene la saturación actual y prácticamente no mejora el indicador.",
			 "color": Color(0.90, 0.80, 0.10)},
		],
	},
	{
		"id": "mov_shuttle", "icono": "🚌", "color": Color(0.15, 0.55, 0.92),
		"titulo": "Rutas de Shuttle Interno",
		"contexto": "El shuttle de URBE solo cubre 2 rutas y pasa cada 40 minutos, por lo que muchos estudiantes prefieren usar el carro. GreenMetric evalúa la disponibilidad de un servicio de shuttle como indicador propio.",
		"pregunta": "¿Cómo mejorarías el servicio de shuttle del campus?",
		"opciones": [
			{"texto": "Ampliar a 4 rutas con frecuencia de 15 minutos",
			 "impacto": "+20% ImpactRating", "delta": 0.20,
			 "edu": "Un shuttle frecuente y con buena cobertura satisface el indicador de servicio de shuttle (TR2) por completo.",
			 "color": Color(0.18, 0.82, 0.18)},
			{"texto": "Mantener las rutas actuales pero bajar el precio del pasaje",
			 "impacto": "+8% ImpactRating", "delta": 0.08,
			 "edu": "Ayuda a la adopción, pero sin mejorar cobertura ni frecuencia el impacto es limitado.",
			 "color": Color(0.90, 0.80, 0.10)},
			{"texto": "Eliminar el shuttle por bajo uso actual",
			 "impacto": "-15% ImpactRating", "delta": -0.15,
			 "edu": "Eliminar el servicio empeora directamente el indicador y empuja a más estudiantes al carro.",
			 "color": Color(0.90, 0.20, 0.20)},
		],
	},
	{
		"id": "mov_ciclovia", "icono": "🚲", "color": Color(0.20, 0.80, 0.40),
		"titulo": "Reducción de Área de Estacionamiento",
		"contexto": "Cerca de un tercio del área del campus está dedicada a estacionamiento de vehículos — muy por encima de lo que GreenMetric considera sostenible para un campus universitario.",
		"pregunta": "¿Qué harías con uno de los lotes de estacionamiento menos usados?",
		"opciones": [
			{"texto": "Convertirlo en ciclovía y zona verde",
			 "impacto": "+18% ImpactRating", "delta": 0.18,
			 "edu": "Reducir el área destinada a parqueo mejora directamente los indicadores de proporción y reducción de área de estacionamiento.",
			 "color": Color(0.18, 0.82, 0.18)},
			{"texto": "Reducirlo a la mitad y dejar la otra mitad para eventos",
			 "impacto": "+8% ImpactRating", "delta": 0.08,
			 "edu": "Una reducción parcial ayuda, aunque el indicador premia más una reducción sostenida y documentada.",
			 "color": Color(0.90, 0.80, 0.10)},
			{"texto": "Mantenerlo igual, por si el campus crece",
			 "impacto": "-5% ImpactRating", "delta": -0.05,
			 "edu": "No reducir el área de estacionamiento no aporta al indicador y perpetúa el uso del vehículo privado.",
			 "color": Color(0.90, 0.20, 0.20)},
		],
	},
	{
		"id": "mov_dia_sin_carros", "icono": "🚷", "color": Color(0.75, 0.30, 0.85),
		"titulo": "Día Sin Carros",
		"contexto": "Varias universidades del ranking GreenMetric implementan un día a la semana sin acceso vehicular privado al campus, como iniciativa para reducir el uso de vehículos.",
		"pregunta": "¿Implementarías un día sin carros en URBE?",
		"opciones": [
			{"texto": "Sí, un día fijo a la semana con transporte alternativo gratuito ese día",
			 "impacto": "+18% ImpactRating", "delta": 0.18,
			 "edu": "Es una iniciativa concreta y medible para reducir vehículos privados en el campus (indicador TR7).",
			 "color": Color(0.18, 0.82, 0.18)},
			{"texto": "Solo como piloto, un día al mes",
			 "impacto": "+8% ImpactRating", "delta": 0.08,
			 "edu": "Un piloto es un buen primer paso, pero el impacto medido es menor que una iniciativa sostenida.",
			 "color": Color(0.90, 0.80, 0.10)},
			{"texto": "No, afectaría demasiado la asistencia a clases",
			 "impacto": "-6% ImpactRating", "delta": -0.06,
			 "edu": "No implementar ninguna iniciativa no aporta al indicador de reducción de vehículos privados.",
			 "color": Color(0.90, 0.20, 0.20)},
		],
	},
	{
		"id": "mov_zev", "icono": "🔋", "color": Color(0.20, 0.70, 0.65),
		"titulo": "Vehículos de Cero Emisiones",
		"contexto": "La flota de mantenimiento de URBE usa vehículos de combustión. GreenMetric evalúa tanto la disponibilidad como la proporción de vehículos de cero emisiones (ZEV) en el campus.",
		"pregunta": "¿Qué harías con la flota de mantenimiento del campus?",
		"opciones": [
			{"texto": "Piloto de 2 vehículos eléctricos para las labores de mantenimiento",
			 "impacto": "+16% ImpactRating", "delta": 0.16,
			 "edu": "Introducir vehículos de cero emisiones, aunque sea un piloto pequeño, mejora los indicadores de disponibilidad y proporción de ZEV.",
			 "color": Color(0.18, 0.82, 0.18)},
			{"texto": "Evaluar el cambio en los próximos años sin comprometerse aún",
			 "impacto": "+4% ImpactRating", "delta": 0.04,
			 "edu": "Evaluar sin actuar aporta muy poco a un indicador que mide disponibilidad real, no intención.",
			 "color": Color(0.90, 0.80, 0.10)},
			{"texto": "Mantener la flota actual — es más barato a corto plazo",
			 "impacto": "-8% ImpactRating", "delta": -0.08,
			 "edu": "No invertir en ZEV mantiene el indicador en cero y penaliza la calificación de Transporte.",
			 "color": Color(0.90, 0.20, 0.20)},
		],
	},
	{
		"id": "mov_carpool", "icono": "🤝", "color": Color(0.85, 0.65, 0.10),
		"titulo": "Incentivo de Carpool",
		"contexto": "La mayoría de los vehículos que entran a URBE llevan un solo ocupante. Un incentivo de viaje compartido cuenta como iniciativa para reducir vehículos privados en el campus.",
		"pregunta": "¿Qué incentivo de viaje compartido (carpool) implementarías?",
		"opciones": [
			{"texto": "Espacios de estacionamiento preferenciales para carros con 3 o más ocupantes",
			 "impacto": "+14% ImpactRating", "delta": 0.14,
			 "edu": "Un incentivo concreto y visible es más efectivo que solo informar — cuenta como iniciativa real (TR7).",
			 "color": Color(0.18, 0.82, 0.18)},
			{"texto": "Campaña informativa sobre los beneficios del carpool",
			 "impacto": "+6% ImpactRating", "delta": 0.06,
			 "edu": "Informar ayuda a crear conciencia, pero sin un incentivo concreto el cambio de conducta es más lento.",
			 "color": Color(0.90, 0.80, 0.10)},
			{"texto": "No implementar ningún incentivo",
			 "impacto": "-4% ImpactRating", "delta": -0.04,
			 "edu": "Sin ninguna iniciativa, el indicador de reducción de vehículos privados no mejora.",
			 "color": Color(0.90, 0.20, 0.20)},
		],
	},
]

var _esc_actual    : Dictionary = {}
var _mision_id     : String     = ""
var _punto_ref     : Area2D     = null
var _opcion_sel    : int        = -1

var _overlay       : ColorRect   = null
var _panel         : Panel       = null
var _titulo_lbl    : Label       = null
var _icono_lbl     : Label       = null
var _ctx_lbl       : Label       = null
var _pregunta_lbl  : Label       = null
var _btn_ops       : Array       = []
var _barra_preview : ColorRect   = null
var _barra_fill    : ColorRect   = null
var _delta_lbl     : Label       = null
var _edu_lbl       : Label       = null
var _btn_confirmar : Button      = null
var _btn_cerrar    : Button      = null


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	layer = 20
	add_to_group("mision_movilidad")
	_crear_ui()
	hide()


func iniciar(mision_id: String, punto_node: Area2D) -> void:
	var idx := -1
	for i in ESCENARIOS_MOVILIDAD.size():
		if ESCENARIOS_MOVILIDAD[i]["id"] == mision_id:
			idx = i
			break
	if idx < 0: return
	_esc_actual = ESCENARIOS_MOVILIDAD[idx]
	_mision_id  = mision_id
	_punto_ref  = punto_node
	_opcion_sel = -1
	_poblar()
	show()
	SupabaseManager.registrar_evento(5, _mision_id, "mision_iniciada")


func _poblar() -> void:
	var e   : Dictionary = _esc_actual
	var col : Color       = e["color"]

	_panel.get_theme_stylebox("panel").border_color = col
	_icono_lbl.text    = e["icono"]
	_titulo_lbl.text   = e["titulo"]
	_titulo_lbl.add_theme_color_override("font_color", col)
	_ctx_lbl.text      = e["contexto"]
	_pregunta_lbl.text = e["pregunta"]

	_barra_fill.size.x = 0.0
	_barra_fill.color  = Color(0.22, 0.72, 0.22)
	_delta_lbl.text    = ""
	_edu_lbl.text      = ""
	_btn_confirmar.disabled = true

	var ops : Array = e["opciones"]
	for i in _btn_ops.size():
		if i < ops.size():
			var op : Dictionary = ops[i]
			_btn_ops[i].text     = "  %s  " % op["texto"]
			_btn_ops[i].modulate = Color.WHITE
			_btn_ops[i].disabled = false
			var etq : Node = _btn_ops[i].get_node_or_null("Etiqueta")
			if etq:
				etq.text = op["impacto"]
				etq.add_theme_color_override("font_color", op["color"])
			var s := StyleBoxFlat.new()
			s.bg_color = Color(0.06, 0.10, 0.08)
			s.border_color = Color(0.25, 0.35, 0.25)
			s.set_border_width_all(2); s.set_corner_radius_all(10)
			_btn_ops[i].add_theme_stylebox_override("normal", s)


func _seleccionar(idx: int) -> void:
	_opcion_sel = idx
	var op    : Dictionary = _esc_actual["opciones"][idx]
	var delta : float      = float(op["delta"])

	for i in _btn_ops.size():
		var s := StyleBoxFlat.new()
		if i == idx:
			s.bg_color     = Color(0.08, 0.22, 0.08)
			s.border_color = _esc_actual["opciones"][i]["color"]
		else:
			s.bg_color     = Color(0.06, 0.10, 0.08)
			s.border_color = Color(0.25, 0.35, 0.25)
		s.set_border_width_all(2); s.set_corner_radius_all(10)
		_btn_ops[i].add_theme_stylebox_override("normal", s)

	var pct : float = clampf(PuntajeManager.fraccion(5) + delta, 0.0, 1.0)
	_barra_fill.color = op["color"]
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_barra_fill, "size:x", 360.0 * pct, 0.40)

	_delta_lbl.text = op["impacto"]
	_delta_lbl.add_theme_color_override("font_color", op["color"])
	_edu_lbl.text   = op["edu"]
	_btn_confirmar.disabled = false


func _confirmar() -> void:
	if _opcion_sel < 0: return
	var op_elegida : Dictionary = _esc_actual["opciones"][_opcion_sel]
	var delta : float = float(op_elegida["delta"])
	hide()

	SupabaseManager.registrar_evento(5, _mision_id, "opcion_elegida",
		{"texto": op_elegida["texto"], "delta": delta, "impacto": op_elegida["impacto"]})

	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(5, _mision_id)
	if is_instance_valid(_punto_ref) and _punto_ref.has_method("_notificar_escenario_resuelto"):
		_punto_ref._notificar_escenario_resuelto()

	var xp : int = int(nm.XP_POR_MISION.get(5, 35)) if nm else 35
	var ec : int = int(nm.EC_POR_MISION.get(5, 12)) if nm else 12
	mision_movilidad_completada.emit(_mision_id, xp, ec)


# ── Construcción UI (mismo lenguaje visual que simulador_decision.gd) ──
func _crear_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.76)
	add_child(_overlay)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(720, 520)
	_panel.offset_left   = -360.0
	_panel.offset_top    = -260.0
	_panel.offset_right  =  360.0
	_panel.offset_bottom =  260.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.05, 0.06, 0.08, 0.99)
	ps.border_color = Color(0.20, 0.55, 0.92)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.08, 0.30, 0.55, 0.45)
	ps.shadow_size  = 26
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(m, 26)
	_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	mg.add_child(vbox)

	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)

	_icono_lbl = Label.new()
	_icono_lbl.add_theme_font_size_override("font_size", 28)
	hdr.add_child(_icono_lbl)

	_titulo_lbl = Label.new()
	_titulo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titulo_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	_titulo_lbl.add_theme_font_size_override("font_size", 16)
	_titulo_lbl.add_theme_color_override("font_color", Color(0.35, 0.75, 0.98))
	hdr.add_child(_titulo_lbl)

	var badge := Label.new()
	badge.text = "🚲 NIVEL 5 — Transporte"
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.35, 0.65, 0.98))
	hdr.add_child(badge)

	_btn_cerrar = Button.new()
	_btn_cerrar.text = "✕"
	_btn_cerrar.custom_minimum_size = Vector2(30, 30)
	var s_c := StyleBoxFlat.new()
	s_c.bg_color = Color(0.15, 0.06, 0.06)
	s_c.border_color = Color(0.55, 0.15, 0.15); s_c.set_border_width_all(1); s_c.set_corner_radius_all(6)
	_btn_cerrar.add_theme_stylebox_override("normal", s_c)
	_btn_cerrar.pressed.connect(func(): hide())
	hdr.add_child(_btn_cerrar)

	_ctx_lbl = Label.new()
	_ctx_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_ctx_lbl.add_theme_font_size_override("font_size", 12)
	_ctx_lbl.add_theme_color_override("font_color", Color(0.70, 0.72, 0.75))
	vbox.add_child(_ctx_lbl)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.20, 0.50, 0.75, 0.30)
	sep_s.content_margin_top = 1.0; sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new(); sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	_pregunta_lbl = Label.new()
	_pregunta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_pregunta_lbl.add_theme_font_size_override("font_size", 13)
	_pregunta_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	vbox.add_child(_pregunta_lbl)

	_btn_ops.clear()
	for i in 3:
		var op_row := HBoxContainer.new()
		op_row.add_theme_constant_override("separation", 6)
		vbox.add_child(op_row)

		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size   = Vector2(0, 42)
		btn.add_theme_font_size_override("font_size", 12)
		btn.autowrap_mode         = TextServer.AUTOWRAP_WORD
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.06, 0.10, 0.08)
		s.border_color = Color(0.25, 0.35, 0.25)
		s.set_border_width_all(2); s.set_corner_radius_all(10)
		btn.add_theme_stylebox_override("normal", s)
		var ci := i
		btn.pressed.connect(func(): _seleccionar(ci))
		op_row.add_child(btn)

		var etq := Label.new()
		etq.name = "Etiqueta"
		etq.custom_minimum_size = Vector2(100, 0)
		etq.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		etq.add_theme_font_size_override("font_size", 11)
		btn.add_child(etq)

		_btn_ops.append(btn)

	var imp_row := HBoxContainer.new()
	imp_row.add_theme_constant_override("separation", 10)
	vbox.add_child(imp_row)

	var imp_lbl := Label.new()
	imp_lbl.text = "ImpactRating:"
	imp_lbl.add_theme_font_size_override("font_size", 11)
	imp_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	imp_row.add_child(imp_lbl)

	_barra_preview = ColorRect.new()
	_barra_preview.custom_minimum_size = Vector2(360, 12)
	_barra_preview.color = Color(0.10, 0.14, 0.18)
	imp_row.add_child(_barra_preview)

	_barra_fill = ColorRect.new()
	_barra_fill.size  = Vector2(0, 12)
	_barra_fill.color = Color(0.22, 0.72, 0.22)
	_barra_preview.add_child(_barra_fill)

	_delta_lbl = Label.new()
	_delta_lbl.add_theme_font_size_override("font_size", 12)
	imp_row.add_child(_delta_lbl)

	_edu_lbl = Label.new()
	_edu_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_edu_lbl.add_theme_font_size_override("font_size", 11)
	_edu_lbl.add_theme_color_override("font_color", Color(0.60, 0.75, 0.90))
	_edu_lbl.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(_edu_lbl)

	_btn_confirmar = Button.new()
	_btn_confirmar.text = "✓  Confirmar Decisión"
	_btn_confirmar.custom_minimum_size = Vector2(0, 44)
	_btn_confirmar.disabled = true
	_btn_confirmar.add_theme_font_size_override("font_size", 14)
	var s_ok := StyleBoxFlat.new()
	s_ok.bg_color = Color(0.06, 0.22, 0.32)
	s_ok.border_color = Color(0.20, 0.62, 0.90); s_ok.set_border_width_all(2); s_ok.set_corner_radius_all(12)
	_btn_confirmar.add_theme_stylebox_override("normal", s_ok)
	var s_ok_h := s_ok.duplicate(); s_ok_h.bg_color = Color(0.10, 0.34, 0.46)
	_btn_confirmar.add_theme_stylebox_override("hover", s_ok_h)
	_btn_confirmar.pressed.connect(_confirmar)
	vbox.add_child(_btn_confirmar)
