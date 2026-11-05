# ============================================================
# minimapa.gd — minimapa del campus (pedido del jurado, nov. 2026).
# Botón 📍 encima del "?" de la Bitácora, o tecla M (ver
# SceneMapaMundo._input). Muestra la imagen del campus en pequeño con un
# punto rojo que titila por cada misión pendiente del nivel en curso y un
# punto claro donde está el jugador. Al completar una misión su punto se va.
# Los pendientes salen de indicador_misiones.pendientes(), la misma lógica
# de las flechas amarillas del mapa.
# No es una ventana modal: se puede caminar con él abierto.
# ============================================================
extends CanvasLayer

const TEMA := preload("res://scenes/ui/hud_tema.gd")
const INDICADOR := preload("res://scenes/mapa/indicador_misiones.gd")

const ANCHO_MAPA := 300.0
const ROJO := Color("#FF3B3B")

# SceneMapaMundo: borde_mapa() y el Sprite2D del fondo.
var mapa : Node = null

var _boton  : Button = null
var _panel  : PanelContainer = null
var _titulo : Label = null
var _vista  : Control = null
var _puntos : Array[Node2D] = []
var _t := 0.0
var _buscar_en := 0.0


func _ready() -> void:
	# Encima del HUD (capa 5) y debajo de toda ventana (diálogo 10 en adelante):
	# un diálogo, la Bitácora o el ranking lo tapan, nunca al revés.
	layer = 6
	_crear_boton()
	_crear_panel()
	_panel.hide()


func esta_abierto() -> bool:
	return _panel.visible


func alternar() -> void:
	if esta_abierto():
		_panel.hide()
	else:
		# La imagen y su proporción no cambian en la partida: se ponen al abrir.
		(_vista.get_child(0) as TextureRect).texture = _textura()
		var borde := _borde()
		_vista.custom_minimum_size = Vector2(ANCHO_MAPA, ANCHO_MAPA * borde.size.y / maxf(borde.size.x, 1.0))
		_actualizar()
		_panel.show()


func _process(delta: float) -> void:
	if not esta_abierto():
		return
	_t += delta
	_buscar_en -= delta
	if _buscar_en <= 0.0:
		_actualizar()
	_vista.queue_redraw()


func _actualizar() -> void:
	_buscar_en = 1.0
	var nm = get_node_or_null("/root/NivelManager")
	_puntos = INDICADOR.pendientes(mapa, nm)
	var nivel : int = INDICADOR.nivel_actual(nm) if nm else 0
	if nivel == 0:
		_titulo.text = "Minimapa · completaste los seis niveles"
	elif _puntos.is_empty():
		_titulo.text = "Minimapa · Nivel %d · habla con los personajes" % nivel
	else:
		_titulo.text = "Minimapa · Nivel %d · faltan %d" % [nivel, _puntos.size()]


# Posición en la vista del minimapa de un punto del mundo. Con el tamaño real
# de la vista (la imagen la llena entera), no con el mínimo: si el título
# ensancha el panel, la imagen se estira y los puntos tienen que seguirla.
func a_vista(p: Vector2) -> Vector2:
	var b := _borde()
	var r := (p - b.position) / b.size
	var tam := _vista.size if _vista.size.x > 0.0 else _vista.custom_minimum_size
	return Vector2(clampf(r.x, 0.0, 1.0), clampf(r.y, 0.0, 1.0)) * tam


func _borde() -> Rect2:
	if mapa and mapa.has_method("borde_mapa"):
		return mapa.borde_mapa()
	return Rect2(0, 0, 1408, 768)


func _textura() -> Texture2D:
	var fondo := mapa.get_node_or_null("Sprite2D") as Sprite2D if mapa else null
	return fondo.texture if fondo else null


func _dibujar() -> void:
	var latido := 0.5 + 0.5 * sin(_t * 6.0)
	for o in _puntos:
		if not is_instance_valid(o):
			continue
		var p := a_vista(o.global_position)
		_vista.draw_circle(p, 6.0 + 2.0 * latido, Color(ROJO, 0.25 * latido))
		_vista.draw_circle(p, 4.0, Color(ROJO, 0.45 + 0.55 * latido))
		_vista.draw_arc(p, 4.0, 0.0, TAU, 16, Color(0, 0, 0, 0.7), 1.0, true)
	var jugador := get_tree().get_first_node_in_group("jugador") as Node2D
	if jugador:
		var pj := a_vista(jugador.global_position)
		_vista.draw_circle(pj, 5.0, Color.WHITE)
		_vista.draw_circle(pj, 3.0, TEMA.CIAN)


func _crear_boton() -> void:
	_boton = Button.new()
	_boton.text = "📍"
	_boton.tooltip_text = "Minimapa (M)"
	_boton.focus_mode = Control.FOCUS_NONE
	_boton.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_boton.offset_left = -58; _boton.offset_top = -104
	_boton.offset_right = -18; _boton.offset_bottom = -64
	_boton.add_theme_font_size_override("font_size", 18)
	_boton.add_theme_stylebox_override("normal", TEMA.caja(TEMA.PANEL_BG, Color(ROJO, 0.7), 2, 20))
	_boton.add_theme_stylebox_override("hover", TEMA.caja(Color(ROJO, 0.25), ROJO, 2, 20))
	_boton.add_theme_stylebox_override("pressed", TEMA.caja(Color(ROJO, 0.35), ROJO, 2, 20))
	_boton.pressed.connect(alternar)
	add_child(_boton)


func _crear_panel() -> void:
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", TEMA.caja(TEMA.POPOVER_BG, Color(ROJO, 0.6), 2, 10, 10, 8))
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Abajo a la derecha, a la izquierda de los botones 📍 y ?; crece hacia
	# arriba y hacia la izquierda.
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_right = -70; _panel.offset_bottom = -18
	_panel.offset_left = -70; _panel.offset_top = -18
	add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(vb)
	_titulo = TEMA.label("Minimapa", 12, TEMA.TEXTO, 600)
	vb.add_child(_titulo)
	_vista = Control.new()
	_vista.clip_contents = true
	_vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista.custom_minimum_size = Vector2(ANCHO_MAPA, ANCHO_MAPA * 0.55)
	_vista.draw.connect(_dibujar)
	vb.add_child(_vista)
	var fondo := TextureRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.show_behind_parent = true
	_vista.add_child(fondo)
	var ley := HBoxContainer.new()
	ley.add_theme_constant_override("separation", 4)
	vb.add_child(ley)
	for par in [["●", ROJO], ["misión pendiente   ", TEMA.LEYENDA], ["●", TEMA.CIAN],
			["tú   ·   M o 📍 para cerrar", TEMA.LEYENDA]]:
		ley.add_child(TEMA.label(par[0], 10, par[1]))
