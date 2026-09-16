# Prueba de la barra de acciones, el banner de zona y el aviso central.
# Correr: $GODOT --headless --path . res://tests/test_hud_controles.tscn
extends Node

const ACCIONES := preload("res://scenes/ui/hud_acciones.gd")
const BANNER   := preload("res://scenes/ui/hud_banner_zona.gd")
const AVISO    := preload("res://scenes/ui/hud_aviso.gd")

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

	print("test_hud_controles: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
