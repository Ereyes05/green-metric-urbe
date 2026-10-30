# NPC por nivel y quiz de una sola vez (SceneMapaMundo.NIVEL_NPC,
# _actualizar_bloqueo_npcs, _on_dialogo_terminado).
# Correr: $GODOT --headless --path . res://tests/test_npcs_nivel.tscn
extends Node

const MAPA := preload("res://scenes/mapa/SceneMapaMundo.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _npc(mapa: Node, mision_id: String) -> Node:
	for n in mapa.get_tree().get_nodes_in_group("npcs_mapa"):
		if n.mision_id == mision_id:
			return n
	return null


func _ready() -> void:
	print("test_npcs_nivel")
	for d in MAPA.new().DATOS_NPCS:
		_check(MAPA.NIVEL_NPC.has(d["mision_id"]), "%s tiene nivel" % d["mision_id"])
	_check(MAPA.quiz_de_npc("mision_residuos") == "mision_residuos_minijuego", "Yulimar → minijuego")
	_check(MAPA.quiz_de_npc("mision_agua") == "mision_agua", "Lic. Torres → su quiz")

	# Cuenta nueva: nada completado.
	NivelManager._misiones = {}
	NivelManager.nivel_actual = 1
	PuntajeManager._quizzes_hechos = []
	var mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(mapa)
	await get_tree().create_timer(1.0).timeout

	_check(not _npc(mapa, "mision_rector").bloqueado, "Rector libre desde el inicio")
	_check(not _npc(mapa, "mision_bloque_f").bloqueado, "Ing. Ramírez (Nivel 1) libre")
	_check(_npc(mapa, "mision_bloque_a").bloqueado, "Prof. González (Nivel 2) bloqueado")
	_check(_npc(mapa, "mision_educacion").bloqueado, "Dra. Luna (Nivel 6) bloqueada")
	_check(_npc(mapa, "mision_bloque_a").aviso_bloqueo.begins_with("🔒 Disponible en el Nivel 2"), "aviso con el nivel")

	var avisos : Array = []
	_npc(mapa, "mision_bloque_a").bloqueo_tocado.connect(func(t): avisos.append(t))
	_npc(mapa, "mision_bloque_a").iniciar_dialogo()
	_check(avisos.size() == 1 and not mapa._dialogo_ui.visible, "E en bloqueado: aviso y sin diálogo")

	# Nivel 1 completo → se encienden los del Nivel 2 sin recargar.
	var hechas := {}
	for m in NivelManager.MISIONES_NIVEL[1]:
		hechas[m] = true
	NivelManager._misiones = {"1": hechas}
	mapa._actualizar_hud()
	_check(not _npc(mapa, "mision_bloque_a").bloqueado, "Nivel 1 completo: Prof. González libre")
	_check(_npc(mapa, "mision_residuos").bloqueado, "Yulimar (Nivel 3) sigue bloqueada")

	# Quiz de una sola vez.
	mapa._on_dialogo_terminado("mision_bloque_f")
	_check(mapa._quiz_ui.visible, "primera vez: quiz")
	mapa._quiz_ui.hide()
	PuntajeManager.registrar_quiz("mision_bloque_f", 3)
	mapa._on_dialogo_terminado("mision_bloque_f")
	_check(not mapa._quiz_ui.visible, "ya respondido: sin quiz")
	PuntajeManager._quizzes_hechos.append("mision_residuos_minijuego")
	mapa._on_dialogo_terminado("mision_residuos")
	_check(not mapa._minijuego_residuos.visible, "minijuego hecho: no se repite")

	print("test_npcs_nivel: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
