# ============================================================
# hint_bubble.gd — URBE Rangers: Eco-Quest
# Sistema de pistas contextuales (toast notifications).
# Se muestra cuando el jugador descubre algo por primera vez.
# No bloquea el gameplay. Se auto-descarta tras 5 segundos.
# Persistencia: user://hints_vistas.dat
# ============================================================
extends CanvasLayer

const DURACION     : float = 5.2
const CHARS_SEG    : float = 45.0
const SLIDE_DIST   : float = 280.0

var _vistas        : Dictionary = {}   # id -> true
var _cola          : Array      = []   # [{id, msg}]
var _mostrando     : bool       = false

# — Nodos UI ─────────────────────────────────────────────────
var _panel         : Panel   = null
var _icono_lbl     : Label   = null
var _msg_lbl       : Label   = null
var _barra_fill    : ColorRect = null
var _btn_x         : Button  = null

# — Estado interno ────────────────────────────────────────────
var _timer         : float   = 0.0
var _texto_full    : String  = ""
var _chars_vis     : int     = 0
var _tw_timer      : float   = 0.0
var _escribiendo   : bool    = false


func _ready() -> void:
	layer = 30
	add_to_group("hint_bubble")
	_cargar_vistas()
	_crear_ui()


# ── API pública ───────────────────────────────────────────────
func push(id: String, mensaje: String) -> void:
	if _vistas.has(id): return          # ya fue vista, ignorar
	if _esta_en_cola(id): return        # ya está en cola
	_cola.append({"id": id, "msg": mensaje})
	if not _mostrando:
		_mostrar_siguiente()


# ── Internos ─────────────────────────────────────────────────
func _esta_en_cola(id: String) -> bool:
	for item in _cola:
		if item["id"] == id: return true
	return false


func _mostrar_siguiente() -> void:
	if _cola.is_empty():
		_mostrando = false
		return
	_mostrando = true
	var item : Dictionary = _cola.pop_front()
	_vistas[item["id"]] = true
	_guardar_vistas()
	_animar_entrada(item["msg"])


func _animar_entrada(mensaje: String) -> void:
	_texto_full  = mensaje
	_chars_vis   = 0
	_tw_timer    = 0.0
	_escribiendo = true
	_timer       = 0.0
	_msg_lbl.text = ""
	_barra_fill.size.x = SLIDE_DIST

	_panel.modulate.a   = 0.0
	_panel.position.x   = -SLIDE_DIST
	_panel.visible      = true

	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "position:x", 0.0, 0.28)
	tw.parallel().tween_property(_panel, "modulate:a", 1.0, 0.22)


func _animar_salida() -> void:
	var tw := create_tween().set_ease(Tween.EASE_IN)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.22)
	tw.tween_property(_panel, "position:x", -SLIDE_DIST, 0.22)
	tw.tween_callback(func():
		_panel.visible = false
		_mostrar_siguiente())


func _process(delta: float) -> void:
	if not _panel.visible: return

	# Typewriter del mensaje
	if _escribiendo:
		_tw_timer += delta
		var meta : int = int(_tw_timer * CHARS_SEG)
		if meta > _chars_vis:
			_chars_vis     = mini(meta, _texto_full.length())
			_msg_lbl.text  = _texto_full.substr(0, _chars_vis)
			if _chars_vis >= _texto_full.length():
				_escribiendo = false

	# Cuenta regresiva
	_timer += delta
	var pct : float = clampf(1.0 - (_timer / DURACION), 0.0, 1.0)
	_barra_fill.size.x = SLIDE_DIST * pct

	if _timer >= DURACION:
		_animar_salida()


# ── UI ────────────────────────────────────────────────────────
func _crear_ui() -> void:
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_panel.offset_left   = 18.0
	_panel.offset_top    = -120.0
	_panel.offset_right  = 18.0 + SLIDE_DIST
	_panel.offset_bottom = -20.0
	_panel.visible       = false

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.08, 0.12, 0.96)
	ps.border_color = Color(0.22, 0.82, 0.28)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(12)
	ps.shadow_color = Color(0.10, 0.55, 0.18, 0.40)
	ps.shadow_size  = 12
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	# Barra de progreso (auto-dismiss)
	var barra_bg := ColorRect.new()
	barra_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barra_bg.custom_minimum_size = Vector2(0, 3)
	barra_bg.offset_top    = -3.0
	barra_bg.offset_bottom =  0.0
	barra_bg.color = Color(0.10, 0.16, 0.22)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(barra_bg)

	_barra_fill = ColorRect.new()
	_barra_fill.size     = Vector2(SLIDE_DIST, 3)
	_barra_fill.color    = Color(0.22, 0.82, 0.28)
	_barra_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_bg.add_child(_barra_fill)

	# Contenido
	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   12)
	mg.add_theme_constant_override("margin_right",  36)
	mg.add_theme_constant_override("margin_top",    10)
	mg.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(mg)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	mg.add_child(hbox)

	_icono_lbl = Label.new()
	_icono_lbl.text = "💡"
	_icono_lbl.add_theme_font_size_override("font_size", 18)
	_icono_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(_icono_lbl)

	_msg_lbl = Label.new()
	_msg_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_msg_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_msg_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	_msg_lbl.add_theme_font_size_override("font_size", 12)
	_msg_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.88))
	hbox.add_child(_msg_lbl)

	# Botón cerrar
	_btn_x = Button.new()
	_btn_x.text = "✕"
	_btn_x.custom_minimum_size = Vector2(22, 22)
	_btn_x.add_theme_font_size_override("font_size", 11)
	_btn_x.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn_x.offset_left   = -26.0
	_btn_x.offset_top    =  4.0
	_btn_x.offset_right  = -4.0
	_btn_x.offset_bottom =  26.0
	var sx := StyleBoxFlat.new()
	sx.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	_btn_x.add_theme_stylebox_override("normal", sx)
	_btn_x.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	_btn_x.pressed.connect(_animar_salida)
	_panel.add_child(_btn_x)


# ── Persistencia ─────────────────────────────────────────────
# Por cuenta, no por máquina: las pistas son "lo que ya vio ESTE
# estudiante". Con un archivo global, en una computadora compartida el
# segundo estudiante en adelante nunca vería ninguna pista.
func _ruta_vistas() -> String:
	return NivelManager.ruta_usuario("hints_vistas")


func _cargar_vistas() -> void:
	var ruta := _ruta_vistas()
	if not FileAccess.file_exists(ruta): return
	var f := FileAccess.open(ruta, FileAccess.READ)
	if not f: return
	while not f.eof_reached():
		var linea := f.get_line().strip_edges()
		if linea != "":
			_vistas[linea] = true
	f.close()


func _guardar_vistas() -> void:
	var f := FileAccess.open(_ruta_vistas(), FileAccess.WRITE)
	if not f: return
	for k in _vistas.keys():
		f.store_line(k)
	f.close()
