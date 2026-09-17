# Prueba de consistencia del contenido del Plan de Movilidad (spec §5–7).
# Correr: $GODOT --headless --path . res://tests/test_plan_datos.tscn
extends Node

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_plan_datos")
	var re := RegEx.new()
	re.compile("^[a-z0-9_]{1,60}$")
	_check(DATOS.DECISIONES.size() == 8, "8 decisiones (6 + 2 bicicleteros)")
	var suma_mejores := 0.0
	var costo_mejor := 0
	var costo_caras := 0
	var costo_baratas := 0
	var mejor_no_es_la_mas_cara := 0
	for d in DATOS.DECISIONES:
		var id : String = d["id"]
		_check(re.search(id) != null, "%s: id válido" % id)
		_check(d["tipo"] in ["decision", "bicicletero"], "%s: tipo válido" % id)
		for campo in ["titulo", "lugar", "indicador", "contexto", "pregunta"]:
			_check(str(d.get(campo, "")) != "", "%s: %s no vacío" % [id, campo])
		_check(DATOS.NOMBRE_LUGAR.has(d["lugar"]), "%s: lugar con nombre legible" % id)
		var ops : Array = d["opciones"]
		_check(ops.size() == 3, "%s: 3 opciones" % id)
		var contras := 0
		var max_costo := -1
		var min_costo := 1000
		var id_mas_cara := ""
		for o in ops:
			var oid : String = o["id"]
			_check(re.search(oid) != null, "%s:%s id válido" % [id, oid])
			for campo in ["texto", "corto", "explicacion"]:
				_check(str(o.get(campo, "")) != "", "%s:%s %s no vacío" % [id, oid, campo])
			if o["contraproducente"]:
				contras += 1
				_check(is_equal_approx(float(o["puntos"]), 0.0), "%s:%s contraproducente vale 0" % [id, oid])
				_check(DATOS.objecion(id, oid).is_empty(), "%s:%s contraproducente sin objeción" % [id, oid])
			else:
				_check(o["aceptacion"] in DATOS.ACEPTACION_PESO, "%s:%s aceptación válida" % [id, oid])
				if int(o["costo"]) > max_costo:
					max_costo = int(o["costo"])
					id_mas_cara = oid
				min_costo = mini(min_costo, int(o["costo"]))
				var obj := DATOS.objecion(id, oid)
				_check(str(obj.get("texto", "")) != "", "%s:%s tiene objeción" % [id, oid])
				var args : Array = obj.get("argumentos", [])
				var correctos := 0
				for a in args:
					if a["correcto"]:
						correctos += 1
					_check(str(a["texto"]) != "" and str(a["explicacion"]) != "", "%s:%s argumento completo" % [id, oid])
				_check(args.size() == 3 and correctos == 1, "%s:%s 3 argumentos, 1 correcto" % [id, oid])
			var s := str(o.get("sinergia", ""))
			if s != "":
				_check(DATOS.SINERGIAS.has(s), "%s:%s sinergia %s existe" % [id, oid, s])
		_check(contras == 1, "%s: exactamente 1 contraproducente" % id)
		var mejor := DATOS.mejor_opcion(id)
		suma_mejores += float(DATOS.opcion(id, mejor)["puntos"])
		costo_mejor += int(DATOS.opcion(id, mejor)["costo"])
		costo_caras += max_costo
		costo_baratas += min_costo
		if mejor != id_mas_cara:
			mejor_no_es_la_mas_cara += 1
	_check(is_equal_approx(suma_mejores, 4.0), "mejores opciones suman 4,00 (%.2f)" % suma_mejores)
	var max_consejo := 0.0
	for c in DATOS.CONSEJO_OPCIONES:
		max_consejo = maxf(max_consejo, float(c["puntos"]))
	_check(is_equal_approx(suma_mejores + max_consejo, 5.0), "mejores + Consejo = 5,00")
	_check(costo_mejor == DATOS.PRESUPUESTO, "plan de mayor puntaje cuesta el presupuesto (%d)" % costo_mejor)
	_check(costo_caras == 162, "opción válida más cara por decisión suma 162 (%d)" % costo_caras)
	_check(costo_baratas == 74 and costo_baratas <= DATOS.PRESUPUESTO, "plan válido más barato = 74 (%d)" % costo_baratas)
	_check(mejor_no_es_la_mas_cara == 4, "en 4 decisiones la mejor no es la más cara (%d)" % mejor_no_es_la_mas_cara)

	_check(DATOS.CONSEJO_OPCIONES.size() == 4, "4 calificaciones del Consejo")
	for n in 4:
		_check(DATOS.calificacion(n)["id"] == "consejo_%d" % n, "calificación con %d aciertos" % n)
	_check(DATOS.calificacion(9)["id"] == "consejo_3" and DATOS.calificacion(-1)["id"] == "consejo_0", "aciertos acotados")
	_check(float(DATOS.calificacion(3)["puntos"]) > float(DATOS.calificacion(2)["puntos"]), "más aciertos, más puntos")

	var esperadas : Array = DATOS.ids_decisiones() + [DATOS.DECISION_CONSEJO]
	_check(DATOS.MISIONES == esperadas, "MISIONES = decisiones + tr_consejo")
	_check(DATOS.SINERGIAS.size() == 4, "4 sinergias")
	for s in DATOS.SINERGIAS.keys():
		_check(re.search(s) != null and int(DATOS.SINERGIAS[s]["categoria"]) in [1, 2, 6], "sinergia %s válida" % s)
		_check(DATOS.texto_sinergia(s).contains(str(DATOS.SINERGIAS[s]["efecto"])), "texto de sinergia %s" % s)
		# M4: vocabulario unificado a "Sinergia" en los textos de jugador del
		# Nivel 5 (el HUD ya decía "✨ Sinergia"; los paneles decían "Cruce").
		_check(DATOS.texto_sinergia(s).contains("Sinergia") and not DATOS.texto_sinergia(s).contains("Cruce"),
			"texto de sinergia %s usa 'Sinergia', no 'Cruce'" % s)
	_check(DATOS.NOMBRE_LUGAR.has("oficina_movilidad") and DATOS.NOMBRE_LUGAR.has("rectorado"), "nombres de Oficina y Rectorado")
	_check(DATOS.opcion("tr_lote", "no_existe").is_empty() and DATOS.decision("x").is_empty(), "consultas inexistentes devuelven {}")
	_check(DATOS.ENCARGO.contains("100"), "el encargo menciona el presupuesto")

	# I2: título legible de cada misión del Nivel 5 (antes SceneMapaMundo
	# mostraba el id crudo capitalizado: "Tr Permisos", "Tr Consejo").
	for id in DATOS.MISIONES:
		_check(DATOS.titulo(id) != "", "%s: título no vacío" % id)
	_check(DATOS.titulo("tr_consejo") == "Consejo Universitario", "título de tr_consejo")
	_check(DATOS.titulo("tr_bici_bloque_e") == "Bicicletero del Bloque E", "título del bicicletero del Bloque E")
	_check(DATOS.titulo("tr_bici_cafetin") == "Bicicletero del Cafetín", "título del bicicletero del Cafetín")
	_check(DATOS.titulo("no_existe") == "", "título de un id inexistente es vacío")

	print("test_plan_datos: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
