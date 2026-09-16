# Prueba de la barra de acciones, el banner de zona y el aviso central.
# Correr: $GODOT --headless --path . res://tests/test_hud_controles.tscn
extends Node

const ACCIONES := preload("res://scenes/ui/hud_acciones.gd")
const BANNER   := preload("res://scenes/ui/hud_banner_zona.gd")
const AVISO    := preload("res://scenes/ui/hud_aviso.gd")
const LEYENDA  := preload("res://scenes/ui/hud_leyenda_avance.gd")
const TEMA     := preload("res://scenes/ui/hud_tema.gd")

var _fallos := 0
var _recibidas : Array = []


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_hud_controles")
	var a = ACCIONES.new()
	add_child(a)
	a.accion.connect(func(i): _recibidas.append(i))
	_check(a.botones.size() == 5, "5 botones")
	_check(a.botones[0].custom_minimum_size == Vector2(56, 59), "botón 56×59")
	_check(a.tecla(KEY_3), "tecla 3 se maneja")
	_check(not a.tecla(KEY_7), "tecla 7 no se maneja")
	a.botones[4].pressed.emit()
	_check(_recibidas == [2, 4], "acciones emitidas: %s" % [_recibidas])

	# El fondo normal arranca en TEMA.PANEL_BG (casi opaco, #101C26 86%);
	# activo usa el mismo tinte de color que "hover" (0.18 alfa del color
	# del botón) — no es más opaco, pero es un fondo con color reconocible
	# donde antes había gris neutro: por eso se compara contra ese color
	# esperado en lugar de solo el canal alfa (que en PANEL_BG es más alto).
	var bg_inactivo : Color = a.botones[0].get_theme_stylebox("normal").bg_color
	_check(bg_inactivo.is_equal_approx(TEMA.PANEL_BG), "botón 0 arranca con el fondo normal del panel")
	a.set_activo(0, true)
	var bg_activo : Color = a.botones[0].get_theme_stylebox("normal").bg_color
	_check(not bg_activo.is_equal_approx(bg_inactivo), "botón activo cambia el fondo respecto al inactivo")
	_check(bg_activo.is_equal_approx(a.botones[0].get_theme_stylebox("hover").bg_color), "botón activo usa el mismo fondo coloreado que el hover")
	a.set_activo(0, false)
	_check(a.botones[0].get_theme_stylebox("normal").bg_color.is_equal_approx(bg_inactivo), "botón vuelve a inactivo")

	var b = BANNER.new()
	add_child(b)
	_check(not b.visible, "banner oculto al inicio")
	b.mostrar("🌿", "Plaza Central", "Nivel 1 · Entorno", Color("#62D06A"))
	_check(b.visible and b.activo, "banner visible al entrar")
	_check(b.titulo_lbl.text == "Plaza Central", "banner título")
	b.ocultar()
	_check(not b.activo, "banner inactivo al salir")

	var v = AVISO.new()
	add_child(v)
	v.avisar("a")
	v.avisar("b")
	v.avisar("c")
	v.avisar("d")
	_check(v.mostrando and v.texto_lbl.text == "a", "muestra el primero")
	_check(v.cola.size() == 2, "cola máx. 2")
	_check(v.cola[0]["texto"] == "c" and v.cola[1]["texto"] == "d", "descarta el más viejo pendiente")
	v.avisar("x", true)
	_check(v.cola[1]["bloqueo"] == true, "aviso de bloqueo encolado")

	var l = LEYENDA.new()
	add_child(l)
	_check(not l.visible, "leyenda de avance oculta al inicio")
	l.set_activo(true)
	_check(l.visible, "leyenda de avance visible al activar")
	l.set_activo(false)
	_check(not l.visible, "leyenda de avance oculta al desactivar")
	_check(l.filas_nivel.size() == 3, "leyenda tiene 3 filas de nivel: %d" % l.filas_nivel.size())

	print("test_hud_controles: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
