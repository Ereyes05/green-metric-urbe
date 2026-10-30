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

	# El quiz cuenta una sola vez; después solo se ofrece practicar (HU-006).
	var quiz = mapa._quiz_ui
	mapa._on_dialogo_terminado("mision_bloque_f")
	_check(quiz.visible and not quiz.esta_ofreciendo_practica(), "primera vez: quiz de verdad")
	_check(quiz._titulo_lbl.text.begins_with("QUIZ"), "primera vez: título QUIZ")
	quiz.hide()
	PuntajeManager.registrar_quiz("mision_bloque_f", 3)
	mapa._on_dialogo_terminado("mision_bloque_f")
	_check(quiz.esta_ofreciendo_practica(), "ya respondido: ofrece practicar, no arranca solo")
	quiz._cerrar_oferta_practica()
	_check(not quiz.visible, "«Ahora no» cierra sin quiz")
	mapa._on_dialogo_terminado("mision_bloque_f")
	quiz._on_aceptar_practica()
	_check(quiz.visible and quiz._es_practica, "«Practicar» abre la práctica")
	_check(quiz._titulo_lbl.text.begins_with("PRÁCTICA"), "título PRÁCTICA")
	_check(quiz._sin_puntos(), "la práctica no da XP")
	var emitidos := []
	quiz.quiz_completado.connect(func(xp): emitidos.append(xp))
	quiz._finalizar()
	await get_tree().create_timer(0.4).timeout
	_check(emitidos.is_empty(), "la práctica no emite quiz_completado (sin XP ni EcoCredits)")

	# Minijuego de Yulimar: hasta aprobarlo se juega de verdad (HU-007).
	var mj = mapa._minijuego_residuos
	PuntajeManager._quizzes_hechos.append("mision_residuos_minijuego")
	NivelManager._detalles.erase(mj.CLAVE_DETALLE)
	mapa._on_dialogo_terminado("mision_residuos")
	_check(mj.visible and not mj._practica, "sin aprobar: se juega de verdad aunque ya lo intentó")
	var pagos := []
	mj.minijuego_completado.connect(func(xp): pagos.append(xp))
	mj._aciertos = mj.APROBACION - 1
	mj._terminar()
	_check(mj._res_botones.visible, "no aprueba: aparece Reintentar")
	await get_tree().create_timer(3.6).timeout
	_check(pagos.is_empty(), "no aprueba: sin XP")
	mj._on_reintentar()
	_check(mj.visible and mj._activo, "Reintentar vuelve a empezar")
	mj._aciertos = mj.APROBACION
	mj._xp_total = mj.APROBACION * mj.XP_POR_ACIERTO
	mj._terminar()
	_check(not mj._res_botones.visible, "aprueba: sin botones")
	await get_tree().create_timer(3.6).timeout
	_check(pagos == [mj.APROBACION * mj.XP_POR_ACIERTO], "aprueba: paga una vez")
	_check(mj.aprobado_antes(), "queda guardado que aprobó")
	mapa._on_dialogo_terminado("mision_residuos")
	_check(quiz.esta_ofreciendo_practica() and not mj.visible, "ya aprobado: solo ofrece practicar")
	quiz._on_aceptar_practica()
	_check(mj.visible and mj._practica, "practicar el minijuego")
	mj._aciertos = 10
	mj._terminar()
	await get_tree().create_timer(3.6).timeout
	_check(pagos.size() == 1, "la práctica del minijuego no paga")

	print("test_npcs_nivel: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
