# ============================================================
# simulador_decision.gd — URBE Rangers: Eco-Quest
# Simulador de decisiones para Agua (M4) y Residuos (M3).
# MODO PRÁCTICA: no suma puntaje ni EcoCredits. Antes de elegir, las
# opciones sólo muestran su texto (sin adelantar el impacto). Al elegir
# y confirmar, se revela el impacto de TODAS las opciones (color según
# qué tan buena es cada una), se marca la elegida y se explica la
# consecuencia educativa; si la elegida no era la mejor, se indica cuál
# lo era. El botón pasa entonces a "Siguiente caso →" para rotar entre
# los escenarios de Agua (M4) y Residuos (M3).
# La señal decision_tomada se conserva por compatibilidad de firma, pero
# ya NO se emite: este simulador no afecta el puntaje GreenMetric ni los
# EcoCredits.
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
var _confirmado    : bool       = false

var _overlay       : ColorRect   = null
var _panel         : PanelContainer = null
var _mg            : MarginContainer = null
var _titulo_lbl    : Label       = null
var _icono_lbl     : Label       = null
var _ctx_lbl       : Label       = null
var _pregunta_lbl  : Label       = null
var _btn_ops       : Array       = []
var _etq_ops       : Array       = []
var _edu_box       : PanelContainer = null
var _edu_lbl       : Label       = null
var _mejor_lbl     : Label       = null
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

	_confirmado = false
	_panel.get_theme_stylebox("panel").border_color = col
	_icono_lbl.text    = e["icono"]
	_titulo_lbl.text   = e["titulo"]
	_titulo_lbl.add_theme_color_override("font_color", col)
	_ctx_lbl.text      = e["contexto"]
	_pregunta_lbl.text = e["pregunta"]

	_edu_lbl.text   = ""
	_edu_box.visible = false
	_mejor_lbl.text    = ""
	_mejor_lbl.visible = false
	_btn_confirmar.text     = "✓  Confirmar Decisión"
	_btn_confirmar.disabled = true

	var ops : Array = e["opciones"]
	for i in _btn_ops.size():
		if i < ops.size():
			var op  : Dictionary = ops[i]
			_btn_ops[i].text     = "  %s  " % op["texto"]
			_btn_ops[i].modulate = Color.WHITE
			_btn_ops[i].disabled = false
			var s := StyleBoxFlat.new()
			s.bg_color = Color(0.06, 0.10, 0.08)
			s.border_color = Color(0.25, 0.35, 0.25)
			s.set_border_width_all(2); s.set_corner_radius_all(10)
			_btn_ops[i].add_theme_stylebox_override("normal", s)
			_btn_ops[i].remove_theme_color_override("font_color")
			_btn_ops[i].remove_theme_color_override("font_disabled_color")
			_btn_ops[i].remove_theme_stylebox_override("disabled")
			var etq : Label = _etq_ops[i]
			etq.text    = ""
			etq.visible = false


func _seleccionar(idx: int) -> void:
	if _confirmado:
		return
	_opcion_sel = idx

	for i in _btn_ops.size():
		var s := StyleBoxFlat.new()
		if i == idx:
			s.bg_color     = Color(0.08, 0.22, 0.08)
			s.border_color = Color(0.30, 0.85, 0.95)
		else:
			s.bg_color     = Color(0.06, 0.10, 0.08)
			s.border_color = Color(0.25, 0.35, 0.25)
		s.set_border_width_all(2); s.set_corner_radius_all(10)
		_btn_ops[i].add_theme_stylebox_override("normal", s)

	_btn_confirmar.disabled = false


func _confirmar() -> void:
	if _opcion_sel < 0 or _confirmado:
		return
	_confirmado = true

	var ops       : Array = _esc_actual["opciones"]
	var mejor_idx : int   = 0
	var mejor_delta : float = -INF
	for i in ops.size():
		var d : float = float(ops[i]["delta"])
		if d > mejor_delta:
			mejor_delta = d
			mejor_idx   = i

	for i in _btn_ops.size():
		var btn : Button = _btn_ops[i]
		btn.disabled = true
		if i < ops.size():
			var op  : Dictionary = ops[i]
			var etq : Label = _etq_ops[i]
			var es_elegida : bool = (i == _opcion_sel)
			var txt : String = op["impacto"]
			if es_elegida:
				txt += "   ·   Tu elección"
			etq.text    = txt
			etq.visible = true
			etq.add_theme_color_override("font_color", op["color"])

			# La opción elegida mantiene su borde/fondo resaltado aun
			# deshabilitada; las demás se atenúan para que "Tu elección"
			# no sea sólo un texto chico sino visualmente evidente.
			# Godot usa el stylebox "disabled" (no "normal") para un botón
			# deshabilitado, así que hay que sobrescribir ambos.
			var s := StyleBoxFlat.new()
			if es_elegida:
				s.bg_color     = Color(0.08, 0.22, 0.08)
				s.border_color = op["color"]
				s.set_border_width_all(3)
			else:
				s.bg_color     = Color(0.05, 0.07, 0.06)
				s.border_color = Color(0.18, 0.22, 0.18)
				s.set_border_width_all(1)
			s.set_corner_radius_all(10)
			btn.add_theme_stylebox_override("normal", s)
			btn.add_theme_stylebox_override("disabled", s)

			var col_txt : Color = Color(0.95, 0.95, 0.95) if es_elegida else Color(0.42, 0.45, 0.42)
			btn.add_theme_color_override("font_color", col_txt)
			btn.add_theme_color_override("font_disabled_color", col_txt)

	var op_sel : Dictionary = ops[_opcion_sel]
	_edu_lbl.text    = op_sel["edu"]
	_edu_box.visible = true

	if _opcion_sel != mejor_idx:
		_mejor_lbl.text    = "💡 La mejor opción era: %s" % ops[mejor_idx]["texto"]
		_mejor_lbl.visible = true
	else:
		_mejor_lbl.text    = ""
		_mejor_lbl.visible = false

	_btn_confirmar.text     = "Siguiente caso →"
	_btn_confirmar.disabled = false


func _on_btn_accion_pressed() -> void:
	if not _confirmado:
		_confirmar()
	else:
		mostrar()


# ── Construcción UI ───────────────────────────────────────────
func _crear_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.76)
	add_child(_overlay)

	# CenterContainer + PanelContainer: el panel se ajusta automáticamente
	# a la altura de su contenido (VBoxContainer) y queda centrado, tanto
	# antes como después de confirmar — sin cálculos manuales de tamaño.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.07, 0.06, 0.99)
	ps.border_color = Color(0.22, 0.78, 0.22)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.12, 0.60, 0.18, 0.45)
	ps.shadow_size  = 26
	_panel.add_theme_stylebox_override("panel", ps)
	center.add_child(_panel)

	_mg = MarginContainer.new()
	for m in ["margin_left","margin_right","margin_top","margin_bottom"]:
		_mg.add_theme_constant_override(m, 22)
	_panel.add_child(_mg)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(676, 0)
	vbox.add_theme_constant_override("separation", 7)
	_mg.add_child(vbox)

	# Rótulo fijo de modo práctica
	var modo_lbl := Label.new()
	modo_lbl.text = "🔬 Simulador · Modo práctica"
	modo_lbl.add_theme_font_size_override("font_size", 13)
	modo_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 0.95))
	vbox.add_child(modo_lbl)

	var subtitulo_lbl := Label.new()
	subtitulo_lbl.text = "Practicá decisiones reales del campus. No suma puntaje ni EcoCredits."
	subtitulo_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitulo_lbl.add_theme_font_size_override("font_size", 11)
	subtitulo_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(subtitulo_lbl)

	var sep0_s := StyleBoxFlat.new()
	sep0_s.bg_color = Color(0.22, 0.55, 0.22, 0.20)
	sep0_s.content_margin_top = 1.0; sep0_s.content_margin_bottom = 1.0
	var sep0 := HSeparator.new(); sep0.add_theme_stylebox_override("separator", sep0_s)
	vbox.add_child(sep0)

	# Encabezado del escenario
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

	# Opciones: botón + etiqueta de impacto DEBAJO (oculta hasta confirmar,
	# nunca superpuesta al texto del botón).
	_btn_ops.clear()
	_etq_ops.clear()
	for i in 3:
		var op_col := VBoxContainer.new()
		op_col.add_theme_constant_override("separation", 2)
		vbox.add_child(op_col)

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
		op_col.add_child(btn)

		var etq := Label.new()
		etq.name = "Etiqueta"
		etq.autowrap_mode = TextServer.AUTOWRAP_WORD
		etq.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		etq.add_theme_font_size_override("font_size", 11)
		etq.visible = false
		op_col.add_child(etq)

		_btn_ops.append(btn)
		_etq_ops.append(etq)

	# Caja de explicación educativa (visible sólo tras confirmar)
	_edu_box = PanelContainer.new()
	var edu_s := StyleBoxFlat.new()
	edu_s.bg_color     = Color(0.05, 0.10, 0.07)
	edu_s.border_color = Color(0.28, 0.55, 0.28)
	edu_s.set_border_width_all(1); edu_s.set_corner_radius_all(8)
	edu_s.content_margin_left = 10.0; edu_s.content_margin_right = 10.0
	edu_s.content_margin_top = 6.0; edu_s.content_margin_bottom = 6.0
	_edu_box.add_theme_stylebox_override("panel", edu_s)
	_edu_box.visible = false
	vbox.add_child(_edu_box)

	_edu_lbl = Label.new()
	_edu_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_edu_lbl.add_theme_font_size_override("font_size", 11)
	_edu_lbl.add_theme_color_override("font_color", Color(0.62, 0.80, 0.62))
	_edu_box.add_child(_edu_lbl)

	# Línea "la mejor opción era..." (sólo si la elegida no fue la mejor)
	_mejor_lbl = Label.new()
	_mejor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_mejor_lbl.add_theme_font_size_override("font_size", 11)
	_mejor_lbl.add_theme_color_override("font_color", Color(0.90, 0.80, 0.30))
	_mejor_lbl.visible = false
	vbox.add_child(_mejor_lbl)

	# Botón de acción: Confirmar Decisión → Siguiente caso →
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
	_btn_confirmar.pressed.connect(_on_btn_accion_pressed)
	vbox.add_child(_btn_confirmar)
