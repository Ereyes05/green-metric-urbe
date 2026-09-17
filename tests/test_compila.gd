# Verifica que los scripts tocados por el proyecto A compilan y exponen su API.
# Correr: $GODOT --headless --path . res://tests/test_compila.tscn
extends Node

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_compila")
	var sm = get_node_or_null("/root/SupabaseManager")
	_check(sm != null, "SupabaseManager cargado como autoload")
	if sm:
		for f in ["obtener_puntaje", "registrar_quiz", "registrar_decision",
				  "registrar_sinergia", "guardar_detalle", "obtener_detalles"]:
			_check(sm.has_method(f), "SupabaseManager.%s existe" % f)
		for s in ["puntaje_recibido", "puntaje_fallido", "calidad_respuesta", "detalles_recibidos",
				  "detalles_fallidos"]:
			_check(sm.has_signal(s), "SupabaseManager señal %s existe" % s)
		# Un único punto que avisa el fallo por acción: lo usan tanto el fallo
		# de red como el request() que no llega a salir (sin él, quien espera
		# la respuesta queda trabado para siempre).
		_check(sm.has_method("_emitir_fallo"), "SupabaseManager._emitir_fallo existe")
		_check(sm.has_signal("ranking_fallido"), "SupabaseManager señal ranking_fallido existe")
		var src : String = FileAccess.get_file_as_string("res://autoload/SupabaseManager.gd")
		_check(src.contains("rpc/ranking_publico"), "cargar_ranking usa la RPC ranking_publico")
		_check(not src.contains("progreso_estudiante?select=user_id,xp_ganada"), "ya no lee progreso_estudiante para el ranking")
		var lb : String = FileAccess.get_file_as_string("res://scenes/ui/leaderboard.gd")
		_check(not lb.contains("qjuiwnwqkfmmfsdacpgd"), "leaderboard sin credenciales del proyecto viejo")
		_check(lb.contains("es_yo"), "leaderboard marca (Tú) con es_yo del servidor")
	var pm = get_node_or_null("/root/PuntajeManager")
	_check(pm != null, "PuntajeManager cargado como autoload")
	if pm:
		for f in ["iniciar_sesion", "valor", "fraccion", "quiz_hecho", "registrar_quiz",
				  "registrar_decision", "registrar_sinergia", "restaurar_detalles"]:
			_check(pm.has_method(f), "PuntajeManager.%s existe" % f)
		_check(pm.categorias.size() == 6, "PuntajeManager arranca con 6 categorías")
		_check(is_equal_approx(pm.valor(3), 0.0), "sin sesión el valor es 0")
	if sm:
		# Sin este enganche, una petición de puntaje fallida (red caída) deja
		# _pidiendo en true para siempre y bloquea todo refresco futuro.
		_check(sm.puntaje_fallido.get_connections().size() > 0,
			"algo escucha SupabaseManager.puntaje_fallido")
	var nm = get_node_or_null("/root/NivelManager")
	_check(nm != null and nm.has_signal("detalle_guardado"), "NivelManager emite detalle_guardado")

	var script_login := load("res://scenes/login/SceneLogin.gd")
	_check(script_login != null, "SceneLogin.gd carga")
	if script_login:
		_check(script_login.can_instantiate(), "SceneLogin.gd se puede instanciar")
		var metodos := []
		for m in script_login.get_script_method_list():
			metodos.append(m["name"])
		_check(metodos.has("_esperar_detalles_con_timeout"),
			"SceneLogin.gd tiene _esperar_detalles_con_timeout")

	var em = get_node_or_null("/root/EconomiaManager")
	_check(em != null and not ("impacto" in em), "EconomiaManager ya no tiene ImpactRating")
	_check(em != null and not em.has_method("actualizar_impacto"), "actualizar_impacto eliminado")
	for ruta in ["res://scenes/mapa/SceneMapaMundo.gd", "res://scenes/mapa/mapa_campus.gd",
				 "res://scenes/ui/simulador_decision.gd", "res://scenes/misiones/nivel5_movilidad.gd",
				 "res://scenes/misiones/mision_informe_final.gd", "res://scenes/ui/resultados_greenmetric.gd",
				 "res://scenes/ui/quiz_npc.gd", "res://scenes/ui/minijuego_residuos.gd"]:
		var s : Script = load(ruta)
		_check(s != null and s.can_instantiate(), "compila: %s" % ruta)
	var mapa : Script = load("res://scenes/mapa/SceneMapaMundo.gd")
	_check(mapa != null and mapa.get_script_method_list().any(func(m): return m["name"] == "_refrescar_progreso"),
		"SceneMapaMundo._refrescar_progreso existe")

	var mapa_src : String = FileAccess.get_file_as_string("res://scenes/mapa/SceneMapaMundo.gd")
	_check(not mapa_src.contains("const NIVELES"), "SceneMapaMundo ya no tiene rangos por XP")
	_check(not mapa_src.contains("func _construir_sidebar"), "sidebar viejo eliminado")
	_check(not mapa_src.contains("func _actualizar_indicador_verde"), "índices viejos eliminados")
	_check(mapa_src.contains("hud_ficha_jugador.gd") and mapa_src.contains("hud_panel_greenmetric.gd")
		and mapa_src.contains("hud_acciones.gd") and mapa_src.contains("hud_banner_zona.gd")
		and mapa_src.contains("hud_aviso.gd"), "SceneMapaMundo usa los componentes del HUD")
	# Nivel 5 nuevo (Plan de Movilidad): el mapa usa el controlador y los
	# scripts viejos ya no existen.
	_check(mapa_src.contains("nivel5_movilidad.gd") and mapa_src.contains("_nivel5.activar()")
		and mapa_src.contains("\"punto_movilidad\""), "SceneMapaMundo usa el Plan de Movilidad")
	# Sin el Callable inyectado, el control del kit de bicicletero del
	# controlador se salta (is_valid() falso = pasa de largo).
	_check(mapa_src.contains("_nivel5.verificar_herramienta = _verificar_herramienta"),
		"SceneMapaMundo inyecta verificar_herramienta en el Nivel 5")
	for viejo in ["oficina_movilidad.gd", "mision_movilidad.gd", "punto_bicicletero.gd", "mision_bicicletero.gd",
				  "_spawn_oficina_movilidad", "_spawn_puntos_bicicletero", "DATOS_PUNTOS_BICICLETERO"]:
		_check(not mapa_src.contains(viejo), "SceneMapaMundo sin %s" % viejo)
	for ruta_vieja in ["mision_movilidad.gd", "oficina_movilidad.gd", "mision_bicicletero.gd", "punto_bicicletero.gd"]:
		_check(not FileAccess.file_exists("res://scenes/misiones/" + ruta_vieja), "borrado %s" % ruta_vieja)
	# Sin re-pago a quien completó el Nivel 5 viejo (spec §11.1).
	var i_mov := mapa_src.find("func _on_movilidad_completado")
	var cuerpo_mov := mapa_src.substr(i_mov, 1400)
	_check(i_mov != -1 and cuerpo_mov.contains("var pagar := xp > 0 or ec > 0")
		and cuerpo_mov.find("if pagar:") < cuerpo_mov.find("EconomiaManager.acreditar_mision")
		and cuerpo_mov.contains("SupabaseManager.guardar_progreso(5, mision_id"), "movilidad: sin pago no acredita pero guarda progreso")
	var i_niv := mapa_src.find("func _on_nivel_greenmetric_completado")
	var cuerpo_niv := mapa_src.substr(i_niv, 1600)
	_check(i_niv != -1 and cuerpo_niv.contains("nm.legado_completo(nivel)")
		and cuerpo_niv.find("legado_completo(nivel)") < cuerpo_niv.find("EconomiaManager.ganar_creditos(bonus_ec"), "bono de nivel omitido con legado completo")
	# El Nivel 5 se vuelve a activar al desbloquearse en la misma sesión.
	_check(cuerpo_niv.contains("_nivel5.activar()"), "Nivel 5 se activa al completar el Nivel 4")
	var escena = load("res://scenes/mapa/SceneMapaMundo.gd")
	_check(escena != null and escena.can_instantiate(), "SceneMapaMundo compila")

	print("test_compila: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
