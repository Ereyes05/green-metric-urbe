# ============================================================
# simulador_decision.gd — URBE Rangers: Eco-Quest
# Simulador de decisiones para Agua (M4) y Residuos (M3).
# 3 opciones por escenario. Muestra el impacto estimado de cada opción y,
# en la barra, el puntaje actual de la categoría (PuntajeManager).
# Señal decision_tomada(modulo_id, delta_impacto).
# ============================================================
extends CanvasLayer

signal decision_tomada(modulo_id: int, delta: float)

const ESCENARIOS : Array = [
	# ── M4 Agua ──────────────────────────────────────────────
	{
		"modulo": 4, "icono": "💧", "color": Color(0.05, 0.50, 0.90),
		"titulo": "Gestión del Agua — Cafetería URBE",
		"contexto": "La cafetería del campus usa lavavajillas industriales que consumen 300 litros/hora durante 6 horas diarias. El consumo mensual es de 54,000 litros. GreenMetric califica el ahorro hídrico como prioridad crítica.",
		"pregunta": "¿Cuál estrategia implementarías para reducir el consumo de agua?",
		"opciones": [
			{
				"texto":   "Renovar los 3 lavavajillas por modelos de bajo consumo (90 L/hora)",
				"impacto": "Impacto estimado: +18%",
				"delta":   0.18,
				"edu":     "Los equipos eficientes reducen el consumo en un 70%. Es la solución de mayor impacto a largo plazo.",
				"color":   Color(0.18, 0.82, 0.18),
			},
			{
				"texto":   "Reducir el horario de la cafetería de 6h a 4h diarias",
				"impacto": "Impacto estimado: +6%",
				"delta":   0.06,
				"edu":     "Reducir horarios ayuda, pero impacta el servicio al estudiante y no resuelve la ineficiencia del equipo.",
				"color":   Color(0.90, 0.80, 0.10),
			},
			{
				"texto":   "Mantener el sistema actual — el costo de cambio es muy alto",
				"impacto": "Impacto estimado: -8%",
				"delta":  -0.08,
				"edu":     "No actuar perpetúa el gasto hídrico. GreenMetric penaliza la falta de inversión en eficiencia.",
				"color":   Color(0.90, 0.20, 0.20),
			},
		],
	},
	{
		"modulo": 4, "icono": "💧", "color": Color(0.05, 0.50, 0.90),
		"titulo": "Plan de Ahorro Hídrico — Jardines del Campus",
		"contexto": "Los jardines de URBE se riegan diariamente con aspersores que desperdician agua por evaporación. El sistema actual consume 120,000 litros mensuales. Hay 3 propuestas del Departamento de Mantenimiento.",
		"pregunta": "¿Qué sistema de riego implementarías en los jardines del campus?",
		"opciones": [
			{
				"texto":   "Instalar riego por goteo y programarlo para la madrugada",
				"impacto": "Impacto estimado: +20%",
				"delta":   0.20,
				"edu":     "El riego por goteo reduce el consumo hasta en un 60% y la programación nocturna minimiza la evaporación.",
				"color":   Color(0.18, 0.82, 0.18),
			},
			{
				"texto":   "Mantener aspersores pero regar solo 3 días a la semana",
				"impacto": "Impacto estimado: +8%",
				"delta":   0.08,
				"edu":     "Reducir frecuencia ayuda pero los aspersores siguen siendo ineficientes en distribución.",
				"color":   Color(0.90, 0.80, 0.10),
			},
			{
				"texto":   "Reemplazar las plantas por especies de cemento decorativo",
				"impacto": "Impacto estimado: -12%",
				"delta":  -0.12,
				"edu":     "Eliminar la vegetación reduce la biodiversidad y el área verde, dos factores que GreenMetric evalúa negativamente.",
				"color":   Color(0.90, 0.20, 0.20),
			},
		],
	},
	# ── M3 Residuos ──────────────────────────────────────────
	{
		"modulo": 3, "icono": "♻", "color": Color(0.35, 0.70, 0.15),
		"titulo": "Gestión de Residuos — Campus URBE",
		"contexto": "URBE genera 500 kg de residuos diarios. Actualmente solo el 20% se clasifica correctamente. GreenMetric exige al menos un 60% de clasificación para una calificación aceptable en el módulo de Residuos.",
		"pregunta": "¿Qué estrategia implementarías para mejorar la clasificación de residuos?",
		"opciones": [
			{
				"texto":   "Instalar 50 estaciones de clasificación con señalización clara y colores",
				"impacto": "Impacto estimado: +22%",
				"delta":   0.22,
				"edu":     "La infraestructura visible y accesible es el principal factor para mejorar la tasa de clasificación.",
				"color":   Color(0.18, 0.82, 0.18),
			},
			{
				"texto":   "Contratar empresa especializada en reciclaje para procesar los residuos mezclados",
				"impacto": "Impacto estimado: +10%",
				"delta":   0.10,
				"edu":     "Tercerizar el procesamiento ayuda, pero no genera conciencia ambiental en la comunidad universitaria.",
				"color":   Color(0.90, 0.80, 0.10),
			},
			{
				"texto":   "Emitir multas a quienes no clasifiquen los residuos",
				"impacto": "Impacto estimado: +4%",
				"delta":   0.04,
				"edu":     "Las multas sin educación generan resistencia. GreenMetric valora más los programas de concientización.",
				"color":   Color(0.90, 0.65, 0.10),
			},
		],
	},
]

var _esc_actual    : Dictionary = {}
var _escenario_idx : int        = 0
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


func _ready() -> void:
	layer = 16
	_crear_ui()
	hide()


func mostrar(modulo_id: int = 0) -> void:
	# Busca un escenario del módulo solicitado, o el siguiente en rotación
	if modulo_id > 0:
		for i in ESCENARIOS.size():
			if ESCENARIOS[i]["modulo"] == modulo_id:
				_escenario_idx = i
				break
	_esc_actual = ESCENARIOS[_escenario_idx]
	_escenario_idx = (_escenario_idx + 1) % ESCENARIOS.size()
	_opcion_sel    = -1
	_poblar()
	show()


func _poblar() -> void:
	var e  : Dictionary = _esc_actual
	var col : Color     = e["color"]

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
			var op  : Dictionary = ops[i]
			_btn_ops[i].text     = "  %s  " % op["texto"]
			_btn_ops[i].modulate = Color.WHITE
			_btn_ops[i].disabled = false
			var etq : Node = _btn_ops[i].get_node_or_null("Etiqueta")
			if etq:
				etq.text  = op["impacto"]
				etq.add_theme_color_override("font_color", op["color"])


func _seleccionar(idx: int) -> void:
	_opcion_sel = idx
	var op   : Dictionary = _esc_actual["opciones"][idx]

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

	# Barra animada con el puntaje actual de la categoría, el mismo número
	# que el HUD. No se le suma el delta de la opción: esa ganancia ya no
	# existe (el índice de impacto se eliminó) y mostraría otro número.
	var pct : float = PuntajeManager.fraccion(int(_esc_actual["modulo"]))
	_barra_fill.color = op["color"]
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_barra_fill, "size:x", 360.0 * pct, 0.40)

	_delta_lbl.text = op["impacto"]
	_delta_lbl.add_theme_color_override("font_color", op["color"])
	_edu_lbl.text   = op["edu"]
	_btn_confirmar.disabled = false


func _confirmar() -> void:
	if _opcion_sel < 0: return
	var delta : float  = float(_esc_actual["opciones"][_opcion_sel]["delta"])
	var mod_id : int   = int(_esc_actual["modulo"])
	hide()
	decision_tomada.emit(mod_id, delta)


# ── Construcción UI ───────────────────────────────────────────
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
	ps.bg_color     = Color(0.04, 0.07, 0.06, 0.99)
	ps.border_color = Color(0.22, 0.78, 0.22)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.12, 0.60, 0.18, 0.45)
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

	# Encabezado
	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)

	_icono_lbl = Label.new()
	_icono_lbl.add_theme_font_size_override("font_size", 28)
	hdr.add_child(_icono_lbl)

	_titulo_lbl = Label.new()
	_titulo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titulo_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	_titulo_lbl.add_theme_font_size_override("font_size", 16)
	_titulo_lbl.add_theme_color_override("font_color", Color(0.28, 0.95, 0.28))
	hdr.add_child(_titulo_lbl)

	_btn_cerrar = Button.new()
	_btn_cerrar.text = "✕"
	_btn_cerrar.custom_minimum_size = Vector2(30, 30)
	var s_c := StyleBoxFlat.new()
	s_c.bg_color = Color(0.15, 0.06, 0.06)
	s_c.border_color = Color(0.55, 0.15, 0.15); s_c.set_border_width_all(1); s_c.set_corner_radius_all(6)
	_btn_cerrar.add_theme_stylebox_override("normal", s_c)
	_btn_cerrar.pressed.connect(func(): hide())
	hdr.add_child(_btn_cerrar)

	# Contexto
	_ctx_lbl = Label.new()
	_ctx_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_ctx_lbl.add_theme_font_size_override("font_size", 12)
	_ctx_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
	vbox.add_child(_ctx_lbl)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.22, 0.55, 0.22, 0.25)
	sep_s.content_margin_top = 1.0; sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new(); sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	_pregunta_lbl = Label.new()
	_pregunta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_pregunta_lbl.add_theme_font_size_override("font_size", 13)
	_pregunta_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	vbox.add_child(_pregunta_lbl)

	# Opciones
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

	# Barra de impacto preview
	var imp_row := HBoxContainer.new()
	imp_row.add_theme_constant_override("separation", 10)
	vbox.add_child(imp_row)

	var imp_lbl := Label.new()
	imp_lbl.text = "Puntaje de la categoría:"
	imp_lbl.add_theme_font_size_override("font_size", 11)
	imp_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	imp_row.add_child(imp_lbl)

	_barra_preview = ColorRect.new()
	_barra_preview.custom_minimum_size = Vector2(360, 12)
	_barra_preview.color = Color(0.10, 0.18, 0.12)
	imp_row.add_child(_barra_preview)

	_barra_fill = ColorRect.new()
	_barra_fill.size  = Vector2(0, 12)
	_barra_fill.color = Color(0.22, 0.72, 0.22)
	_barra_preview.add_child(_barra_fill)

	_delta_lbl = Label.new()
	_delta_lbl.add_theme_font_size_override("font_size", 12)
	imp_row.add_child(_delta_lbl)

	# Explicación educativa
	_edu_lbl = Label.new()
	_edu_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_edu_lbl.add_theme_font_size_override("font_size", 11)
	_edu_lbl.add_theme_color_override("font_color", Color(0.62, 0.80, 0.62))
	_edu_lbl.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(_edu_lbl)

	# Botón confirmar
	_btn_confirmar = Button.new()
	_btn_confirmar.text = "✓  Confirmar Decisión"
	_btn_confirmar.custom_minimum_size = Vector2(0, 44)
	_btn_confirmar.disabled = true
	_btn_confirmar.add_theme_font_size_override("font_size", 14)
	var s_ok := StyleBoxFlat.new()
	s_ok.bg_color = Color(0.06, 0.28, 0.08)
	s_ok.border_color = Color(0.22, 0.84, 0.22); s_ok.set_border_width_all(2); s_ok.set_corner_radius_all(12)
	_btn_confirmar.add_theme_stylebox_override("normal", s_ok)
	var s_ok_h := s_ok.duplicate(); s_ok_h.bg_color = Color(0.10, 0.42, 0.12)
	_btn_confirmar.add_theme_stylebox_override("hover", s_ok_h)
	_btn_confirmar.pressed.connect(_confirmar)
	vbox.add_child(_btn_confirmar)
