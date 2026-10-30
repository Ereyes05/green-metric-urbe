# ============================================================
# touch_controls.gd — URBE Rangers: Eco-Quest
# Controles táctiles para móvil.
# Izquierda: joystick flotante dinámico.
# Derecha: botón de interacción [E].
# Se oculta automáticamente en PC (sin pantalla táctil).
# ============================================================
extends CanvasLayer

# ── Estado público que jugador.gd lee cada frame ─────────────
var joy_dir         : Vector2 = Vector2.ZERO
var interact_fired  : bool    = false  # true solo 1 frame

# ── Constantes visuales ───────────────────────────────────────
const JOY_RADIO_BASE  : float = 70.0
const JOY_RADIO_KNOB  : float = 28.0
const BTN_RADIO       : float = 48.0
const BTN_MARGIN      : float = 90.0   # distancia desde el borde
const ALPHA_BASE      : float = 0.35
const ALPHA_KNOB      : float = 0.80
const ALPHA_BTN       : float = 0.70
const ALPHA_BTN_PRESS : float = 0.95
const DEADZONE        : float = 0.18

# ── Estado interno joystick ───────────────────────────────────
var _joy_idx      : int     = -1
var _joy_base     : Vector2 = Vector2.ZERO
var _joy_knob     : Vector2 = Vector2.ZERO
var _joy_activo   : bool    = false

# ── Estado interno botón ──────────────────────────────────────
var _int_idx      : int  = -1
var _int_pressed  : bool = false
var _btn_pos      : Vector2 = Vector2.ZERO  # se calcula en _ready

# ── Nodo de dibujo ────────────────────────────────────────────
var _canvas       : Control = null


func _ready() -> void:
	layer = 25
	add_to_group("touch_controls")

	# Solo mostrar en dispositivos táctiles
	if not DisplayServer.is_touchscreen_available():
		hide()
		set_process_input(false)
		set_process(false)
		return

	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_canvas)

	# La posición del botón se recalcula en _process (viewport puede cambiar)
	_canvas.draw.connect(_on_draw)


func _process(_delta: float) -> void:
	if not visible: return
	var vp := get_viewport().get_visible_rect().size
	_btn_pos = Vector2(vp.x - BTN_MARGIN, vp.y - BTN_MARGIN)
	_canvas.queue_redraw()
	# Reset de interact_fired cada frame
	if interact_fired:
		interact_fired = false


func _input(event: InputEvent) -> void:
	if not visible: return

	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)


func _on_touch(ev: InputEventScreenTouch) -> void:
	var pos := ev.position
	var vp  := get_viewport().get_visible_rect().size
	var es_izquierda : bool = pos.x < vp.x * 0.55

	if ev.pressed:
		if es_izquierda and _joy_idx == -1:
			_joy_idx    = ev.index
			_joy_activo = true
			_joy_base   = pos
			_joy_knob   = pos
		elif not es_izquierda and _int_idx == -1:
			_int_idx     = ev.index
			_int_pressed = true
			interact_fired = true
	else:
		if ev.index == _joy_idx:
			_joy_idx    = -1
			_joy_activo = false
			joy_dir     = Vector2.ZERO
			_joy_knob   = _joy_base
		elif ev.index == _int_idx:
			_int_idx     = -1
			_int_pressed = false


func _on_drag(ev: InputEventScreenDrag) -> void:
	if ev.index != _joy_idx: return

	var delta : Vector2 = ev.position - _joy_base
	if delta.length() > JOY_RADIO_BASE:
		delta = delta.normalized() * JOY_RADIO_BASE
	_joy_knob = _joy_base + delta

	# Calcular dirección con zona muerta
	joy_dir = delta / JOY_RADIO_BASE
	if joy_dir.length() < DEADZONE:
		joy_dir = Vector2.ZERO


func _on_draw() -> void:
	if not visible: return

	# ── Joystick ──────────────────────────────────────────────
	if _joy_activo:
		# Base (aro exterior)
		_canvas.draw_arc(_joy_base, JOY_RADIO_BASE,
			0.0, TAU, 64,
			Color(0.22, 0.85, 0.30, ALPHA_BASE), 4.0)
		_canvas.draw_circle(_joy_base, JOY_RADIO_BASE,
			Color(0.08, 0.20, 0.10, ALPHA_BASE * 0.5))

		# Knob (punto de control)
		_canvas.draw_circle(_joy_knob, JOY_RADIO_KNOB,
			Color(0.28, 0.92, 0.38, ALPHA_KNOB))
		_canvas.draw_arc(_joy_knob, JOY_RADIO_KNOB,
			0.0, TAU, 32,
			Color(1.0, 1.0, 1.0, 0.55), 2.5)

		# Línea base → knob
		_canvas.draw_line(_joy_base, _joy_knob,
			Color(1.0, 1.0, 1.0, 0.25), 2.0)
	else:
		# Hint tenue cuando no se usa (solo en móvil)
		_canvas.draw_arc(Vector2(BTN_MARGIN * 0.9, _btn_pos.y),
			JOY_RADIO_BASE * 0.45, 0.0, TAU, 32,
			Color(1.0, 1.0, 1.0, 0.08), 2.0)

	# ── Botón interactuar (E) ─────────────────────────────────
	var btn_alpha : float = ALPHA_BTN_PRESS if _int_pressed else ALPHA_BTN
	var btn_col   := Color(0.20, 0.60, 0.88, btn_alpha)
	_canvas.draw_circle(_btn_pos, BTN_RADIO, btn_col)
	_canvas.draw_arc(_btn_pos, BTN_RADIO, 0.0, TAU, 48,
		Color(1.0, 1.0, 1.0, 0.50 if not _int_pressed else 0.90), 3.0)

	# Texto "E" en el botón
	# (Godot 4 no tiene draw_string fácil sin font, usamos string approach)
	var font := ThemeDB.fallback_font
	if font:
		var lbl : String = "E"
		var fs   : int   = 26
		var sz   := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		_canvas.draw_string(font, _btn_pos - sz * 0.5 + Vector2(0, sz.y * 0.35),
			lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(1.0, 1.0, 1.0, 0.95 if _int_pressed else 0.85))
