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
		for s in ["puntaje_recibido", "puntaje_fallido", "calidad_respuesta", "detalles_recibidos"]:
			_check(sm.has_signal(s), "SupabaseManager señal %s existe" % s)
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
				 "res://scenes/ui/simulador_decision.gd", "res://scenes/misiones/mision_movilidad.gd",
				 "res://scenes/misiones/mision_informe_final.gd", "res://scenes/ui/resultados_greenmetric.gd"]:
		var s : Script = load(ruta)
		_check(s != null and s.can_instantiate(), "compila: %s" % ruta)
	var mapa : Script = load("res://scenes/mapa/SceneMapaMundo.gd")
	_check(mapa != null and mapa.get_script_method_list().any(func(m): return m["name"] == "_refrescar_progreso"),
		"SceneMapaMundo._refrescar_progreso existe")

	print("test_compila: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
