# Prueba del botón Avance (panel de avance por nivel) y de los límites de
# la cámara del mapa.
# Correr: $GODOT --headless --path . res://tests/test_hud_avance.tscn
extends Node

const AVANCE := preload("res://scenes/ui/hud_panel_avance.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_hud_avance")
	_probar_panel()
	await _probar_camara()
	print("test_hud_avance: %d fallas" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)


func _probar_panel() -> void:
	# Sin cuenta activa (_uid_activo vacío) NivelManager no escribe a disco.
	var guardado : Dictionary = NivelManager._misiones
	var nivel1 := {}
	for id in NivelManager.misiones_nivel[1]:
		nivel1[id] = true
	NivelManager._misiones = {"1": nivel1, "2": {"led_bloque_a": true, "solar_rectorado": true}}

	var p = AVANCE.new()
	add_child(p)
	_check(not p.visible, "arranca cerrado")
	_check(p.alternar(), "alternar() lo abre")
	_check(p.filas.size() == 6, "una fila por nivel (%d)" % p.filas.size())

	var f1 : Dictionary = p.filas[0]
	var f2 : Dictionary = p.filas[1]
	var f3 : Dictionary = p.filas[2]
	_check(f1["estado"] == "completo" and f1["cuenta"].text == "6/6", "nivel 1: completo, 6/6")
	_check(f2["estado"] == "en_curso" and f2["cuenta"].text == "2/8", "nivel 2: en curso, 2/8")
	_check(f3["estado"] == "bloqueado" and f3["cuenta"].text == "0/6", "nivel 3: bloqueado, 0/6")
	_check(p._resumen.text == "8 de 41 misiones completadas", "resumen: %s" % p._resumen.text)

	# Al reabrir lee el estado nuevo, sin duplicar filas.
	NivelManager._misiones["2"]["led_bloque_b"] = true
	p.cerrar()
	p.mostrar()
	_check(p.filas.size() == 6 and p.filas[1]["cuenta"].text == "3/8", "reabrir refresca (3/8)")
	_check(not p.alternar(), "alternar() lo cierra")

	p.free()
	NivelManager._misiones = guardado


func _probar_camara() -> void:
	var escena : Node2D = (load("res://scenes/mapa/scene_mapa_mundo.tscn") as PackedScene).instantiate()
	add_child(escena)
	await get_tree().process_frame
	var cam : Camera2D = escena.get_node("Jugador/Camera2D")
	var fondo : Sprite2D = escena.get_node("Sprite2D")
	var borde : Rect2 = escena.borde_mapa()
	var esperado : Rect2 = fondo.global_transform * fondo.get_rect()
	_check(borde == esperado, "borde_mapa() es el rectángulo de la imagen del campus")
	_check(borde.size.x > 1408.0 and borde.size.y > 768.0,
		"el borde es el del mapa nuevo, no el de 1408×768 (%s)" % borde.size)
	_check(cam.limit_enabled, "los límites de la cámara están encendidos")
	_check(cam.limit_left == int(ceil(borde.position.x)) and cam.limit_top == int(ceil(borde.position.y))
		and cam.limit_right == int(floor(borde.end.x)) and cam.limit_bottom == int(floor(borde.end.y)),
		"límites = borde de la imagen (%d,%d → %d,%d)" % [cam.limit_left, cam.limit_top, cam.limit_right, cam.limit_bottom])
	escena.queue_free()
