# ============================================================
# tutorial_onboarding.gd — URBE Rangers: Eco-Quest
# Intro de 4 pasos: explicación rápida del juego y GreenMetric.
# Bloqueante (ui_tutorial). El resto se enseña con pistas
# contextuales (hint_bubble.gd) cuando el jugador descubre algo.
# ============================================================
extends CanvasLayer

signal tutorial_completado()

# ── Contenido de los 4 pasos ────────────────────────────────
const PASOS : Array = [
	{
		"emoji":  "🌿",
		"titulo": "¡Bienvenido a URBE Rangers: Eco-Quest!",
		"texto":  "Eres un Eco-Ranger del campus de la Universidad Rafael Belloso Chacín (URBE).\n\nTu misión: explorar el campus, hablar con los coordinadores de cada área y responder cuestionarios para mejorar la sostenibilidad universitaria.",
		"color":  Color(0.22, 0.88, 0.28),
	},
	{
		"emoji":  "📊",
		"titulo": "¿Qué es UI GreenMetric?",
		"texto":  "UI GreenMetric es el ranking mundial de sostenibilidad universitaria.\nEvalúa 6 módulos:\n\n  🌿 Entorno e Infraestructura\n  ⚡ Energía y Cambio Climático\n  ♻ Manejo de Residuos\n  💧 Uso del Agua\n  🚲 Transporte Sostenible\n  📚 Educación e Investigación",
		"color":  Color(0.28, 0.88, 0.95),
	},
	{
		"emoji":  "🕹️",
		"titulo": "¿Cómo jugar?",
		"texto":  "Muévete con  W A S D  o las flechas del teclado.\n\nCuando veas un NPC con un nombre flotante encima, acércate y presiona  [E]  para interactuar.\n\nEn móvil: usa el joystick izquierdo y el botón  E  de la pantalla.",
		"color":  Color(0.95, 0.80, 0.22),
	},
	{
		"emoji":  "🏛️",
		"titulo": "¡Tu primera misión!",
		"texto":  "Dirígete al Rectorado (zona central del campus) y habla con el Rector Morales.\n\nÉl te explicará los detalles del ranking GreenMetric y te dará tu primera misión oficial.\n\n¡Buena suerte, Eco-Ranger! 🌍",
		"color":  Color(0.88, 0.50, 0.22),
	},
]

const CHARS_SEG : float = 42.0

var _paso_actual    : int    = 0
var _texto_completo : String = ""
var _chars_vis      : int    = 0
var _timer_tw       : float  = 0.0
var _escribiendo    : bool   = false

var _overlay       : ColorRect     = null
var _panel         : Panel         = null
var _emoji_lbl     : Label         = null
var _titulo_lbl    : Label         = null
var _texto_lbl     : Label         = null
var _dots_row      : HBoxContainer = null
var _btn_siguiente : Button        = null
var _acento        : ColorRect     = null


func _ready() -> void:
	layer = 20
	add_to_group("ui_tutorial")
	_crear_ui()
	hide()


func iniciar() -> void:
	_paso_actual = 0
	show()
	_mostrar_paso()


func _mostrar_paso() -> void:
	var p : Dictionary = PASOS[_paso_actual]
	_emoji_lbl.text  = p["emoji"]
	_titulo_lbl.text = p["titulo"]
	_titulo_lbl.add_theme_color_override("font_color", p["color"])
	_acento.color    = Color(p["color"].r, p["color"].g, p["color"].b, 0.55)

	_texto_completo = p["texto"]
	_chars_vis      = 0
	_timer_tw       = 0.0
	_escribiendo    = true
	_texto_lbl.text = ""

	var es_ultimo := (_paso_actual == PASOS.size() - 1)
	_btn_siguiente.text = "  ¡Comenzar!  🚀" if es_ultimo else "  Siguiente  →  "

	_actualizar_dots()

	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)


func _process(delta: float) -> void:
	if not visible or not _escribiendo: return
	_timer_tw += delta
	var meta : int = int(_timer_tw * CHARS_SEG)
	if meta > _chars_vis:
		_chars_vis      = mini(meta, _texto_completo.length())
		_texto_lbl.text = _texto_completo.substr(0, _chars_vis)
		if _chars_vis >= _texto_completo.length():
			_escribiendo = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		if _escribiendo:
			_chars_vis      = _texto_completo.length()
			_texto_lbl.text = _texto_completo
			_escribiendo    = false
		else:
			_on_siguiente()


func _on_siguiente() -> void:
	_paso_actual += 1
	if _paso_actual >= PASOS.size():
		_finalizar()
	else:
		_mostrar_paso()


func _finalizar() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.20)
	tw.tween_callback(func():
		hide()
		tutorial_completado.emit())


func _actualizar_dots() -> void:
	var hijos := _dots_row.get_children()
	for i in hijos.size():
		var d : Panel = hijos[i]
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(6)
		s.set_border_width_all(2)
		if i == _paso_actual:
			s.bg_color     = PASOS[_paso_actual]["color"]
			s.border_color = (PASOS[_paso_actual]["color"] as Color).lightened(0.30)
		elif i < _paso_actual:
			s.bg_color     = Color(0.22, 0.72, 0.22)
			s.border_color = Color(0.30, 0.92, 0.30)
		else:
			s.bg_color     = Color(0.12, 0.18, 0.28)
			s.border_color = Color(0.22, 0.32, 0.50)
		d.add_theme_stylebox_override("panel", s)
		# Pop en el dot activo
		if i == _paso_actual:
			var tw2 := d.create_tween().set_ease(Tween.EASE_OUT)
			tw2.tween_property(d, "scale", Vector2(1.0, 1.0), 0.14).from(Vector2(1.5, 1.5))


# ── Construcción UI ───────────────────────────────────────────
func _crear_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.82)
	add_child(_overlay)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(720, 460)
	_panel.offset_left   = -360.0
	_panel.offset_top    = -230.0
	_panel.offset_right  =  360.0
	_panel.offset_bottom =  230.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.07, 0.12, 0.99)
	ps.border_color = Color(0.22, 0.78, 0.22)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(20)
	ps.shadow_color = Color(0.10, 0.60, 0.18, 0.50)
	ps.shadow_size  = 30
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	# Franja de color en la parte superior (cambia con cada paso)
	_acento = ColorRect.new()
	_acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_acento.custom_minimum_size = Vector2(0, 4)
	_acento.offset_bottom       = 4.0
	_acento.color               = Color(0.22, 0.78, 0.22, 0.55)
	_acento.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_acento)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(m, 36)
	_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	mg.add_child(vbox)

	# Emoji grande
	_emoji_lbl = Label.new()
	_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emoji_lbl.add_theme_font_size_override("font_size", 48)
	vbox.add_child(_emoji_lbl)

	# Título del paso
	_titulo_lbl = Label.new()
	_titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	_titulo_lbl.add_theme_font_size_override("font_size", 20)
	_titulo_lbl.add_theme_color_override("font_color", Color(0.28, 0.95, 0.28))
	vbox.add_child(_titulo_lbl)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.22, 0.72, 0.22, 0.30)
	sep_s.content_margin_top    = 1.0
	sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	# Texto con typewriter
	_texto_lbl = Label.new()
	_texto_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_texto_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texto_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_TOP
	_texto_lbl.add_theme_font_size_override("font_size", 14)
	_texto_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.85))
	vbox.add_child(_texto_lbl)

	# Dots de progreso (círculos)
	_dots_row = HBoxContainer.new()
	_dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_row.add_theme_constant_override("separation", 12)
	for _i in PASOS.size():
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(12, 12)
		var ds := StyleBoxFlat.new()
		ds.bg_color     = Color(0.12, 0.18, 0.28)
		ds.border_color = Color(0.22, 0.32, 0.50)
		ds.set_border_width_all(2)
		ds.set_corner_radius_all(6)
		dot.add_theme_stylebox_override("panel", ds)
		_dots_row.add_child(dot)
	vbox.add_child(_dots_row)

	# Botones
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)


	_btn_siguiente = Button.new()
	_btn_siguiente.text = "  Siguiente  →  "
	_btn_siguiente.custom_minimum_size = Vector2(220, 48)
	_btn_siguiente.add_theme_font_size_override("font_size", 15)
	var s_next := StyleBoxFlat.new()
	s_next.bg_color     = Color(0.06, 0.34, 0.08)
	s_next.border_color = Color(0.22, 0.84, 0.22)
	s_next.set_border_width_all(2)
	s_next.set_corner_radius_all(12)
	_btn_siguiente.add_theme_stylebox_override("normal", s_next)
	var s_next_h := s_next.duplicate()
	(s_next_h as StyleBoxFlat).bg_color = Color(0.10, 0.48, 0.12)
	_btn_siguiente.add_theme_stylebox_override("hover", s_next_h)
	_btn_siguiente.pressed.connect(_on_siguiente)
	btn_row.add_child(_btn_siguiente)

	var hint_lbl := Label.new()
	hint_lbl.text = "[E] para avanzar"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.add_theme_color_override("font_color", Color(0.32, 0.32, 0.32))
	vbox.add_child(hint_lbl)
