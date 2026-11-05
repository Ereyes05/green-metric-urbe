# Nivel 1 (pedido del jurado, nov. 2026): cada misión de plantar del juego
# tiene una planta mejor y una válida con ficha, la tarjeta responde al clic
# en toda su superficie y tocar una tarjeta no planta: primero muestra la
# ficha y se planta con "Plantar esta".
# Correr: $GODOT --headless --path . res://tests/test_plantar_fichas.tscn
extends Node

const PLANTAR := preload("res://scenes/misiones/mision_plantar.gd")
const MAPA := preload("res://scenes/mapa/SceneMapaMundo.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _carta(ui, pid: String) -> Panel:
	for c in ui._cartas:
		if c.get_meta("planta_id") == pid:
			return c
	return null


func _ready() -> void:
	print("test_plantar_fichas")
	var nm := get_node_or_null("/root/NivelManager")
	if nm:
		nm.name = "NivelManagerApagado"

	# Datos: las 6 misiones que usa el mapa.
	for z in MAPA.DATOS_ZONAS_TIERRA:
		var m : Dictionary = PLANTAR.MISIONES[z["indice"]]
		var ids : Array = m["plantas"].map(func(p): return p["id"])
		_check(ids.has(m["correcta"]) and ids.has(m.get("valida", "")) and m["correcta"] != m.get("valida", ""),
			"%s: tiene planta mejor (%s) y válida (%s)" % [m["id"], m["correcta"], m.get("valida", "")])
		_check(ids.all(func(i): return PLANTAR.FICHAS.has(i)), "%s: las 4 plantas tienen ficha" % m["id"])
		_check(ids.all(func(i): return m["feedback"].has(i)), "%s: las 4 plantas tienen respuesta" % m["id"])
		_check(not ids.has("pino_canadiense"), "%s: sin pino canadiense" % m["id"])

	var ui = PLANTAR.new()
	add_child(ui)
	await get_tree().process_frame
	var m0 : Dictionary = PLANTAR.MISIONES[0]
	ui.iniciar(0, null)
	await get_tree().process_frame

	# Clic: nada dentro de la tarjeta se queda con el clic.
	var bloquea := false
	for c in ui._cartas:
		for h in c.get_children():
			if h is Control and h.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				bloquea = true
	_check(not bloquea, "ningún hijo de la tarjeta tapa el clic (dibujo incluido)")

	# Tocar una tarjeta muestra la ficha y no planta.
	_check(ui._btn_plantar.disabled, "sin tarjeta elegida, 'Plantar esta' está apagado")
	var valida := _carta(ui, m0["valida"])
	var clic := InputEventMouseButton.new()
	clic.button_index = MOUSE_BUTTON_LEFT
	clic.pressed = true
	ui._on_carta_input(clic, valida)
	_check(not ui._seleccion_ok and not ui._feedback_panel.visible, "el clic en la tarjeta no planta")
	_check(ui._ficha_lbl.text.contains("Sombra") and ui._ficha_lbl.text.contains("Agua"), "el clic muestra la ficha")
	_check(not ui._btn_plantar.disabled, "con tarjeta elegida, 'Plantar esta' se enciende")

	# Una incorrecta queda descartada.
	var mala : Panel = null
	for c in ui._cartas:
		if not c.get_meta("es_correcta") and not c.get_meta("es_valida"):
			mala = c
			break
	ui._seleccionar_carta(mala)
	ui._on_plantar_esta()
	_check(not ui._seleccion_ok, "la incorrecta no completa")
	_check(ui._btn_plantar.disabled, "la incorrecta queda descartada")
	ui._feedback_panel.visible = false

	# La válida completa con menos XP que la mejor.
	ui._seleccionar_carta(valida)
	ui._on_plantar_esta()
	_check(ui._seleccion_ok and ui._calidad == "valida", "la válida completa la misión")
	_check(ui._xp_mision() == 40 - PLANTAR.XP_MENOS_VALIDA, "la válida da %d XP" % (40 - PLANTAR.XP_MENOS_VALIDA))

	ui.iniciar(0, null)
	ui._seleccionar_carta(_carta(ui, m0["correcta"]))
	ui._on_plantar_esta()
	_check(ui._seleccion_ok and ui._calidad == "mejor" and ui._xp_mision() == 40, "la mejor da 40 XP")

	if nm:
		nm.name = "NivelManager"
	print("test_plantar_fichas: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
