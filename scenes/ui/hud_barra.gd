# Barra de progreso plana: track negro al 50 % + relleno redondeado.
# El relleno se anima con anchor_right (tween 0,3 s ease_out), sin redibujar
# por frame.
extends Panel

const TEMA := preload("res://scenes/ui/hud_tema.gd")

var fraccion : float = 0.0
var _fill : Panel = null
var _tween : Tween = null


func configurar(color: Color, alto: int) -> void:
	custom_minimum_size.y = alto
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", TEMA.caja(TEMA.TRACK, Color.TRANSPARENT, 0, alto / 2))
	_fill = Panel.new()
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill.add_theme_stylebox_override("panel", TEMA.caja(color, Color.TRANSPARENT, 0, alto / 2))
	_fill.anchor_top = 0.0
	_fill.anchor_bottom = 1.0
	_fill.anchor_left = 0.0
	_fill.anchor_right = 0.0
	add_child(_fill)


func set_fraccion(f: float, animar: bool = true) -> void:
	fraccion = clampf(f, 0.0, 1.0)
	if _fill == null:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	if animar and is_inside_tree():
		_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_tween.tween_property(_fill, "anchor_right", fraccion, 0.3)
	else:
		_fill.anchor_right = fraccion
