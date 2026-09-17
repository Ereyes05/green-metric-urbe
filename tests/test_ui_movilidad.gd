# Prueba de las piezas de interfaz del Nivel 5 (tokens de hud_tema).
# Correr: $GODOT --headless --path . res://tests/test_ui_movilidad.tscn
extends Node

const UI := preload("res://scenes/misiones/ui_movilidad.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_ui_movilidad")
	var capa := CanvasLayer.new()
	add_child(capa)
	var vb := UI.panel_modal(capa, 640)
	_check(vb is VBoxContainer and is_equal_approx(vb.custom_minimum_size.x, 640.0), "panel modal con ancho mínimo")
	_check(capa.get_node_or_null("Fondo") != null and capa.get_node_or_null("Centro/Panel/Contenido") == vb, "estructura Fondo + Centro/Panel/Contenido")
	var caja := (capa.get_node("Centro/Panel") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	_check(caja != null and caja.border_color == TEMA.VIOLETA, "panel con borde de Transporte")

	var b := UI.boton("Hola")
	_check(b.get_theme_stylebox("normal") is StyleBoxFlat and b.focus_mode == Control.FOCUS_NONE, "botón con estilo del tema")
	_check(b.get_theme_font_size("font_size") == 13, "botón con tamaño 13")
	UI.pintar_boton(b, TEMA.VERDE, true)
	_check((b.get_theme_stylebox("normal") as StyleBoxFlat).border_color == TEMA.VERDE, "resaltado usa el color")
	UI.pintar_boton(b, TEMA.VERDE, false)
	_check((b.get_theme_stylebox("normal") as StyleBoxFlat).border_color == TEMA.VACIO, "normal usa borde apagado")
	b.free()

	var l := UI.texto("x")
	_check(l.autowrap_mode != TextServer.AUTOWRAP_OFF and l.text == "x", "texto con autowrap")
	l.free()
	var barra := UI.barra(0.25)
	_check(is_equal_approx(barra.value, 25.0) and not barra.show_percentage, "barra al 25 %")
	barra.free()
	UI.separador().free()

	_check(UI.puntos(0.6) == "+0,60", "puntos positivos")
	_check(UI.puntos(-1.0) == "-1,00", "puntos negativos")
	_check(UI.decimal(4.35) == "4,35", "decimal con coma")

	for i in 3:
		vb.add_child(Label.new())
	UI.limpiar(vb)
	_check(vb.get_child_count() == 0, "limpiar vacía el contenedor")

	print("test_ui_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
