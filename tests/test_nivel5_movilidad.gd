# Prueba del controlador del Nivel 5 sin red: puntos por lugar, encargo,
# regla Mixta, kit, Consejo, misiones, detalle, telemetría, restauración
# tardía y espejo con sql/nivel5_plan_movilidad.sql.
# Correr: $GODOT --headless --path . res://tests/test_nivel5_movilidad.tscn
extends Node

const CTRL := preload("res://scenes/misiones/nivel5_movilidad.gd")
const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")


class FakePuntaje extends Node:
	signal decision_resuelta(decision_id: String, opcion_id: String, respuesta: Dictionary)
	var decisiones : Array = []
	var sinergias : Array = []

	func registrar_decision(decision_id: String, opcion_id: String) -> void:
		decisiones.append([decision_id, opcion_id])

	func registrar_sinergia(accion_id: String) -> void:
		sinergias.append(accion_id)


class FakeSupa extends Node:
	var eventos : Array = []

	func registrar_evento(nivel: int, mision_id: String, tipo: String, detalle: Dictionary = {}, correcto = null, intento = null) -> void:
		eventos.append({"nivel": nivel, "mision_id": mision_id, "tipo": tipo, "detalle": detalle, "correcto": correcto, "intento": intento})


var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _idx(decision_id: String, opcion_id: String) -> int:
	var ops : Array = DATOS.decision(decision_id)["opciones"]
	for i in ops.size():
		if ops[i]["id"] == opcion_id:
			return i
	return -1


func _eventos(sm: FakeSupa, tipo: String) -> Array:
	return sm.eventos.filter(func(e): return e["tipo"] == tipo)


# Abre la decisión desde su punto, elige, confirma, responde como el
# servidor y cierra el panel.
func _decidir(ctrl: Node, pm: FakePuntaje, decision_id: String, opcion_id: String, respuesta: Dictionary) -> void:
	ctrl._on_interaccion(ctrl._puntos[decision_id])
	ctrl.panel_decision._on_opcion(_idx(decision_id, opcion_id))
	ctrl.panel_decision._on_accion()
	pm.decision_resuelta.emit(decision_id, opcion_id, respuesta)
	ctrl.panel_decision.cerrar()


func _verificar_espejo_sql() -> void:
	var sql := FileAccess.get_file_as_string("res://sql/nivel5_plan_movilidad.sql")
	_check(sql != "", "existe sql/nivel5_plan_movilidad.sql")
	var re := RegEx.new()
	re.compile("\\('(tr_[a-z0-9_]+)',\\s*'([a-z0-9_]+)',\\s*5,\\s*([0-9.]+),\\s*(true|false),\\s*([0-9]+)\\)")
	var filas := {}
	for m in re.search_all(sql):
		filas["%s:%s" % [m.get_string(1), m.get_string(2)]] = m
	var esperadas := 0
	for d in DATOS.DECISIONES:
		for o in d["opciones"]:
			esperadas += 1
			var m = filas.get("%s:%s" % [d["id"], o["id"]])
			_check(m != null, "SQL tiene %s:%s" % [d["id"], o["id"]])
			if m == null:
				continue
			_check(is_equal_approx(float(m.get_string(3)), float(o["puntos"]))
				and (m.get_string(4) == "true") == bool(o["contraproducente"])
				and int(m.get_string(5)) == int(o["costo"]), "SQL coincide en %s:%s" % [d["id"], o["id"]])
	for c in DATOS.CONSEJO_OPCIONES:
		esperadas += 1
		var m = filas.get("tr_consejo:%s" % c["id"])
		_check(m != null and is_equal_approx(float(m.get_string(3)), float(c["puntos"])) and m.get_string(4) == "false",
			"SQL coincide en tr_consejo:%s" % c["id"])
	_check(filas.size() == esperadas, "SQL sin filas de decisión extra (%d de %d)" % [filas.size(), esperadas])
	var re_s := RegEx.new()
	re_s.compile("\\('([a-z0-9_]+)',\\s*([1-6]),\\s*([0-9]+),\\s*'tr_consejo'\\)")
	var sins := {}
	for m in re_s.search_all(sql):
		sins[m.get_string(1)] = m
	for s in DATOS.SINERGIAS.keys():
		var m = sins.get(s)
		_check(m != null and int(m.get_string(2)) == int(DATOS.SINERGIAS[s]["categoria"])
			and int(m.get_string(3)) == int(DATOS.SINERGIAS[s]["puntos"]), "SQL coincide en sinergia %s" % s)
	_check(sins.size() == DATOS.SINERGIAS.size(), "SQL sin sinergias extra")


func _ready() -> void:
	print("test_nivel5_movilidad")
	var nm : Node = load("res://autoload/NivelManager.gd").new()
	for n in range(1, 5):
		var d := {}
		for id in nm.MISIONES_NIVEL[n]:
			d[id] = true
		nm._misiones[str(n)] = d
	var pm := FakePuntaje.new()
	var sm := FakeSupa.new()
	add_child(pm)
	add_child(sm)
	var mapa := Node2D.new()
	add_child(mapa)
	var ctrl : Node = CTRL.new()
	add_child(ctrl)
	ctrl.configurar(mapa, nm, pm, sm)
	var completadas := []
	var pagos := []
	ctrl.mision_completada.connect(func(id, xp, ec):
		completadas.append(id)
		pagos.append([xp, ec]))
	ctrl.activar()
	ctrl.activar()

	# ── Puntos y lugares ───────────────────────────────────
	_check(DATOS.MISIONES == nm.MISIONES_NIVEL[5], "espejo DATOS.MISIONES = NivelManager.MISIONES_NIVEL[5]")
	for d in DATOS.DECISIONES:
		_check(LUGARES.existe(d["lugar"]), "lugar de %s existe" % d["id"])
	_check(get_tree().get_nodes_in_group("punto_movilidad").size() == 10, "10 puntos (activar es idempotente)")
	_check(ctrl._puntos["tr_lote"].position == LUGARES.posicion("lote_este"), "tr_lote en lote_este")
	_check(ctrl._puntos["tr_consejo"].position == LUGARES.posicion("rectorado"), "Consejo en el Rectorado")
	_check(ctrl._puntos["oficina"].estado == "pendiente" and ctrl._puntos["tr_lote"].estado == "bloqueado"
		and ctrl._puntos["tr_consejo"].estado == "bloqueado", "estados antes del encargo")
	var hay_cambios := false
	for c in mapa.get_children():
		if c.has_method("elementos"):
			hay_cambios = true
	_check(hay_cambios, "nodo de cambios del mapa creado")

	ctrl._on_interaccion(ctrl._puntos["tr_lote"])
	_check(not ctrl.hay_panel_abierto(), "sin encargo no se abre la decisión")

	# ── Encargo ────────────────────────────────────────────
	ctrl._on_interaccion(ctrl._puntos["oficina"])
	_check(ctrl.panel_oficina.visible and ctrl.hay_panel_abierto(), "la Oficina abre el encargo")
	ctrl.panel_oficina._on_aceptar()
	_check(ctrl.plan.encargo_aceptado, "encargo aceptado")
	_check(bool(nm.obtener_detalle("plan_movilidad").get("encargo_aceptado", false)), "encargo guardado en el detalle")
	_check(_eventos(sm, "encargo_aceptado").size() == 1, "evento encargo_aceptado")
	ctrl.panel_oficina.cerrar()
	_check(ctrl._puntos["tr_lote"].estado == "pendiente", "decisiones pendientes tras el encargo")

	# ── Regla Mixta ────────────────────────────────────────
	_decidir(ctrl, pm, "tr_carpool", "vender_puestos_reservados", {"ok": true, "contraproducente": true, "penalizado": true})
	_check(not nm.mision_completada_q(5, "tr_carpool") and completadas.is_empty(), "contraproducente no completa la misión")
	_check(ctrl.plan.descartada("tr_carpool", "vender_puestos_reservados") and ctrl.plan.restante() == 100, "descartada y sin gasto")
	var ev : Array = _eventos(sm, "decision_tomada")
	_check(ev.size() == 1 and ev[0]["correcto"] == false and ev[0]["detalle"]["contraproducente"] == true, "telemetría de contraproducente")
	_check(nm.obtener_detalle("plan_movilidad")["decisiones"]["tr_carpool"]["contraproducentes"] == ["vender_puestos_reservados"], "descarte guardado")
	_check(pm.decisiones.back() == ["tr_carpool", "vender_puestos_reservados"], "registró la decisión en el servidor")

	_decidir(ctrl, pm, "tr_carpool", "app_carpool", {"ok": true, "contraproducente": false})
	_check(nm.mision_completada_q(5, "tr_carpool") and completadas == ["tr_carpool"], "válida completa la misión")
	_check(pagos == [[35, 12]], "jugador sin el Nivel 5 viejo: paga XP y EC")
	_check(ctrl._puntos["tr_carpool"].estado == "resuelto", "punto resuelto")
	ev = _eventos(sm, "decision_tomada")
	_check(ev.size() == 2 and ev[1]["correcto"] == true and int(ev[1]["detalle"]["costo"]) == 26
		and int(ev[1]["detalle"]["presupuesto_restante"]) == 74, "telemetría de válida")
	_decidir(ctrl, pm, "tr_carpool", "puestos_3_ocupantes", {"ok": true, "contraproducente": false})
	_check(completadas == ["tr_carpool"], "cambiar de opción no vuelve a pagar")
	_check(ctrl.plan.opcion_actual("tr_carpool") == "puestos_3_ocupantes", "cambio aplicado")

	# ── Kit del bicicletero ────────────────────────────────
	ctrl.verificar_herramienta = func(_tipo, _punto): return false
	ctrl._on_interaccion(ctrl._puntos["tr_bici_cafetin"])
	_check(not ctrl.hay_panel_abierto(), "sin kit no se abre el bicicletero")
	ctrl.verificar_herramienta = func(_tipo, _punto): return true

	# ── Resto del plan ─────────────────────────────────────
	_check(ctrl._puntos["tr_consejo"].estado == "bloqueado", "Consejo bloqueado con decisiones pendientes")
	var mejores := {
		"tr_permisos": "permiso_por_necesidad", "tr_lote": "ciclovia_arborizada",
		"tr_shuttle": "ruta_a_paradas", "tr_dia_sin_carros": "jornada_mensual_con_feria",
		"tr_flota": "carritos_electricos", "tr_bici_bloque_e": "techado_con_panel",
		"tr_bici_cafetin": "techado_con_panel",
	}
	for id in mejores.keys():
		_decidir(ctrl, pm, id, mejores[id], {"ok": true, "contraproducente": false})
	_check(ctrl.plan.todas_resueltas() and ctrl.plan.restante() == 0, "plan completo con 100 de presupuesto")
	_check(completadas.size() == 8, "8 misiones de decisión (%d)" % completadas.size())
	_check(ctrl._puntos["tr_consejo"].estado == "pendiente", "Consejo disponible")

	# ── Consejo ────────────────────────────────────────────
	ctrl._on_interaccion(ctrl._puntos["tr_consejo"])
	_check(ctrl.panel_consejo.visible and ctrl.panel_consejo.fase == "revision", "Consejo abre la revisión")
	ctrl.panel_consejo._iniciar_objeciones()
	for k in 3:
		var obj : Dictionary = ctrl.panel_consejo._objeciones[ctrl.panel_consejo._idx]
		var args : Array = obj["argumentos"]
		for i in args.size():
			if args[i]["correcto"]:
				ctrl.panel_consejo._on_argumento(i)
				break
		ctrl.panel_consejo._on_siguiente()
	_check(ctrl.plan.presentado() and ctrl.plan.consejo["calificacion"] == "consejo_3", "presentado con 3 aciertos")
	_check(nm.mision_completada_q(5, "tr_consejo") and completadas.size() == 9, "tr_consejo completa")
	_check(pagos.size() == 9 and pagos.back() == [35, 12], "el Consejo también paga normal")
	_check(pm.decisiones.back() == ["tr_consejo", "consejo_3"], "calificación registrada")
	_check(pm.sinergias == ["ciclovia_lote", "dia_sin_carros_feria", "flota_electrica", "bicicletero_techado_solar"], "cruces del plan registrados")
	_check(nm.nivel_completo(5), "Nivel 5 completo con las 9 misiones")
	_check(_eventos(sm, "argumento_consejo").size() == 3 and _eventos(sm, "plan_presentado").size() == 1, "telemetría del Consejo")
	_check(not bool(ctrl.plan.consejo["registrado"]), "sin respuesta todavía: no registrado")
	pm.decision_resuelta.emit("tr_consejo", "consejo_3", {"ok": true, "contraproducente": false})
	_check(bool(nm.obtener_detalle("plan_movilidad")["consejo"]["registrado"]), "registro confirmado y guardado")
	_check(ctrl._puntos["tr_consejo"].estado == "resuelto", "Consejo resuelto")
	ctrl.panel_consejo.cerrar()
	var det_txt := JSON.stringify(nm.obtener_detalle("plan_movilidad"))
	_check(det_txt.length() < 8192, "detalle < 8 KB (%d)" % det_txt.length())

	ctrl._on_interaccion(ctrl._puntos["tr_lote"])
	_check(ctrl.panel_decision.estado == "solo_lectura", "plan presentado: decisión de solo lectura")
	ctrl.panel_decision.cerrar()

	var antes : int = pm.sinergias.size()
	ctrl._on_interaccion(ctrl._puntos["tr_consejo"])
	_check(ctrl.panel_consejo.fase == "resultado" and pm.sinergias.size() == antes + 4, "resultado y cruces reenviados")
	ctrl.panel_consejo.cerrar()

	# ── Restauración tardía ────────────────────────────────
	var nm2 : Node = load("res://autoload/NivelManager.gd").new()
	nm2._misiones = nm._misiones.duplicate(true)
	var mapa2 := Node2D.new()
	add_child(mapa2)
	var ctrl2 : Node = CTRL.new()
	add_child(ctrl2)
	ctrl2.configurar(mapa2, nm2, pm, sm)
	ctrl2.activar()
	_check(ctrl2.plan.vacio(), "sin detalle todavía: plan vacío")
	nm2.aplicar_detalle_servidor("plan_movilidad", nm.obtener_detalle("plan_movilidad"))
	ctrl2._on_interaccion(ctrl2._puntos["oficina"])
	_check(ctrl2.plan.presentado() and ctrl2._puntos["tr_consejo"].estado == "resuelto", "el plan se recarga en la primera interacción")
	ctrl2.panel_oficina.cerrar()

	# ── Sin re-pago a quien completó el Nivel 5 viejo ───────
	var nm3 : Node = load("res://autoload/NivelManager.gd").new()
	nm3._misiones = nm._misiones.duplicate(true)
	var viejo5 := {}
	for id in nm3.MISIONES_LEGADO[5]:
		viejo5[id] = true
	nm3._misiones["5"] = viejo5
	var mapa3 := Node2D.new()
	add_child(mapa3)
	var ctrl3 : Node = CTRL.new()
	add_child(ctrl3)
	var pm3 := FakePuntaje.new()
	add_child(pm3)
	ctrl3.configurar(mapa3, nm3, pm3, sm)
	ctrl3.activar()
	var pagos3 := []
	ctrl3.mision_completada.connect(func(id, xp, ec): pagos3.append([id, xp, ec]))
	ctrl3._on_interaccion(ctrl3._puntos["oficina"])
	ctrl3.panel_oficina._on_aceptar()
	ctrl3.panel_oficina.cerrar()
	_decidir(ctrl3, pm3, "tr_lote", "ciclovia_arborizada", {"ok": true, "contraproducente": false})
	_check(pagos3 == [["tr_lote", 0, 0]], "Nivel 5 viejo completo: la misión se completa sin XP ni EC")
	_check(nm3.mision_completada_q(5, "tr_lote") and nm3.nivel_desbloqueado(6), "igual cuenta como completa y el 6 sigue abierto")
	_check(pm3.decisiones.back() == ["tr_lote", "ciclovia_arborizada"], "igual registra la decisión (puntaje)")

	_verificar_espejo_sql()

	nm.free()
	nm2.free()
	nm3.free()
	print("test_nivel5_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
