# El mapa no dibuja lo que nadie ve. En la web cada llamada de dibujo es cara:
# el 2026-10-30 el juego iba a 18 FPS con 430 llamadas por cuadro, y 121 eran
# del campus viejo (mapa_campus.gd) dibujándose debajo de la imagen del mapa
# nuevo, que es opaca y lo tapa entero.
# Correr (NO headless, necesita dibujar):
#   $GODOT --path . --resolution 1280x720 res://tests/test_rendimiento_mapa.tscn
extends Node

const TECHO_DRAW_CALLS := 170   # cuenta con los 6 niveles completos

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_rendimiento_mapa")
	get_window().size = Vector2i(1280, 720)
	NivelManager._misiones = {}
	for n in range(1, 7):
		var h := {}
		for m in NivelManager.MISIONES_NIVEL[n]: h[m] = true
		NivelManager._misiones[str(n)] = h
	NivelManager.nivel_actual = 6
	var mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(mapa)
	await get_tree().create_timer(3.0).timeout
	for i in 3: await get_tree().process_frame

	var fondo : CanvasItem = mapa.get_node("FondoCampus")
	_check(not fondo.is_visible_in_tree(), "el campus viejo (tapado por el mapa nuevo) no se dibuja")
	_check(fondo.process_mode == Node.PROCESS_MODE_DISABLED, "ni corre su animación")
	# Los indicadores animados fuera de cámara no corren su _process.
	mapa._cull_recoger_t = 0.0
	mapa._cull_t = 0.0
	for i in 3: await get_tree().process_frame
	var animados : Array = mapa._animados
	_check(animados.size() >= 40, "se recogen los indicadores animados del mapa (%d)" % animados.size())
	var vista : Rect2 = mapa.get_viewport().get_canvas_transform().affine_inverse() 		* mapa.get_viewport().get_visible_rect()
	vista = vista.grow(mapa.CULL_MARGEN)
	var mal := 0
	var fuera := 0
	for n in animados:
		var en_vista : bool = vista.has_point(n.global_position)
		if not en_vista:
			fuera += 1
			if n.is_processing(): mal += 1
	_check(fuera > 0 and mal == 0, "fuera de cámara: %d pausados, %d sin pausar" % [fuera - mal, mal])
	var uno : Node2D = null
	for n in mapa._pausados.keys():
		uno = n
		break
	if uno:
		mapa.jugador.global_position = uno.global_position
		for i in 3: await get_tree().process_frame
		mapa._cull_t = 0.0
		for i in 3: await get_tree().process_frame
		_check(uno.is_processing(), "al acercarse, el indicador vuelve a animarse")
	var calmo := Node2D.new()
	_check(not mapa.es_visual_animado(calmo), "un nodo sin script no cuenta como visual")
	calmo.free()

	var dc := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if DisplayServer.get_name() == "headless":
		print("  (headless: no se cuentan llamadas de dibujo)")
	else:
		_check(dc <= TECHO_DRAW_CALLS, "%d llamadas de dibujo (techo %d)" % [dc, TECHO_DRAW_CALLS])

	print("test_rendimiento_mapa: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
