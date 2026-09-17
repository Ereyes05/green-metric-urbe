# Prueba de las reglas del Plan de Movilidad sin interfaz: presupuesto,
# descartes, cambios, objeciones, calificación, sinergias y serialización.
# Correr: $GODOT --headless --path . res://tests/test_plan_movilidad.tscn
extends Node

const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")

const MEJOR := {
	"tr_permisos": "permiso_por_necesidad", "tr_lote": "ciclovia_arborizada",
	"tr_carpool": "puestos_3_ocupantes", "tr_shuttle": "ruta_a_paradas",
	"tr_dia_sin_carros": "jornada_mensual_con_feria", "tr_flota": "carritos_electricos",
	"tr_bici_bloque_e": "techado_con_panel", "tr_bici_cafetin": "techado_con_panel",
}
const BARATO := {
	"tr_permisos": "permiso_por_necesidad", "tr_lote": "plaza_de_eventos",
	"tr_carpool": "puestos_3_ocupantes", "tr_shuttle": "ruta_a_paradas",
	"tr_dia_sin_carros": "jornada_mensual_con_feria", "tr_flota": "triciclos_de_carga",
	"tr_bici_bloque_e": "simple_con_candado", "tr_bici_cafetin": "simple_con_candado",
}

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _con(elecciones: Dictionary):
	var p = PLAN.new()
	p.encargo_aceptado = true
	for id in elecciones.keys():
		p.aplicar_valida(id, elecciones[id])
	return p


func _ids(objeciones: Array) -> Array:
	var out := []
	for o in objeciones:
		out.append(o["decision"])
	return out


func _ready() -> void:
	print("test_plan_movilidad")
	var p = PLAN.new()
	_check(p.vacio() and p.restante() == 100 and not p.resuelta("tr_lote"), "plan nuevo vacío con 100")
	_check(not p.aplicar_valida("tr_lote", "asfaltar_lote"), "contraproducente no se aplica como válida")
	_check(not p.aplicar_valida("tr_lote", "no_existe"), "opción inexistente rechazada")
	_check(p.aplicar_valida("tr_shuttle", "park_and_ride") and p.restante() == 66, "válida gasta su costo")
	_check(p.aplicar_valida("tr_dia_sin_carros", "cierre_semanal"), "segunda válida")
	_check(p.aplicar_valida("tr_lote", "ciclovia_arborizada") and p.restante() == 16, "quedan 16")
	_check(not p.alcanza("tr_flota", "carritos_electricos") and p.faltante("tr_flota", "carritos_electricos") == 2, "faltan 2")
	_check(p.alcanza("tr_flota", "triciclos_de_carga") and p.faltante("tr_flota", "triciclos_de_carga") == 0, "triciclos alcanzan")
	_check(not p.aplicar_valida("tr_flota", "carritos_electricos"), "sin presupuesto no se aplica")
	_check(p.restante("tr_shuttle") == 50, "restante liberando la opción actual")
	_check(p.aplicar_valida("tr_shuttle", "ruta_a_paradas") and p.restante() == 24, "cambio libera el costo anterior")
	_check(int(p.decisiones["tr_shuttle"]["cambios"]) == 1, "cambio contado")
	_check(p.aplicar_valida("tr_shuttle", "ruta_a_paradas") and int(p.decisiones["tr_shuttle"]["cambios"]) == 1, "misma opción no cuenta cambio")
	_check(p.alcanza("tr_shuttle", "ruta_a_paradas"), "la opción actual siempre alcanza")

	p.registrar_contraproducente("tr_flota", "camioneta_diesel")
	p.registrar_contraproducente("tr_flota", "camioneta_diesel")
	_check(p.descartada("tr_flota", "camioneta_diesel") and p.penalizaciones("tr_flota") == 1, "descarte único")
	_check(not p.resuelta("tr_flota") and p.restante() == 24, "contraproducente no gasta ni resuelve")
	_check(not p.vacio(), "con decisiones ya no está vacío")

	var m = _con(MEJOR)
	_check(m.todas_resueltas() and m.restante() == 0, "plan de 5,00 cuesta 100 exacto")
	_check(is_equal_approx(m.puntos_opciones(), 4.0), "mejores opciones = 4,00")
	_check(m.puede_presentar(), "puede presentar")
	var obj : Array = m.objeciones()
	_check(_ids(obj) == ["tr_permisos", "tr_carpool", "tr_dia_sin_carros"], "objeciones del plan de 5,00: %s" % str(_ids(obj)))
	_check(obj.size() == 3 and obj[0]["argumentos"].size() == 3 and str(obj[0]["texto"]) != "" and obj[0]["opcion"] == "permiso_por_necesidad", "objeción completa")
	_check(m.sinergias() == ["ciclovia_lote", "dia_sin_carros_feria", "flota_electrica", "bicicletero_techado_solar"], "cruces del plan de 5,00")

	var b = _con(BARATO)
	_check(b.costo_comprometido() == 74, "plan barato cuesta 74")
	_check(b.debilidad("tr_lote") == 4 and b.debilidad("tr_carpool") == 2 and b.debilidad("tr_permisos") == 3, "debilidades")
	_check(_ids(b.objeciones()) == ["tr_lote", "tr_flota", "tr_bici_bloque_e"], "objeciones del plan barato: %s" % str(_ids(b.objeciones())))
	b.registrar_contraproducente("tr_permisos", "pintar_mas_puestos")
	_check(_ids(b.objeciones()) == ["tr_permisos", "tr_lote", "tr_flota"], "contraproducente probada sube la debilidad")
	_check(is_equal_approx(b.calificacion_estimada(), 2.35), "3,35 - 1 = 2,35 (%.2f)" % b.calificacion_estimada())
	_check(b.sinergias() == ["dia_sin_carros_feria"], "cruces del plan barato")

	_check(b.puede_cambiar_en_consejo(), "puede cambiar en el Consejo")
	_check(b.aplicar_valida("tr_lote", "ciclovia_arborizada", true), "primer cambio en el Consejo")
	_check(b.aplicar_valida("tr_flota", "carritos_electricos", true), "segundo cambio en el Consejo")
	_check(b.cambios_en_consejo == 2 and not b.puede_cambiar_en_consejo(), "máximo 2 cambios")
	_check(not b.aplicar_valida("tr_bici_bloque_e", "techado_con_panel", true), "tercer cambio rechazado")

	var res := [
		{"decision": "tr_permisos", "opcion": "permiso_por_necesidad", "primer_argumento": 1, "correcto_primer_intento": true, "intentos": 1},
		{"decision": "tr_lote", "opcion": "ciclovia_arborizada", "primer_argumento": 0, "correcto_primer_intento": false, "intentos": 2},
		{"decision": "tr_flota", "opcion": "carritos_electricos", "primer_argumento": 0, "correcto_primer_intento": true, "intentos": 1},
	]
	b.presentar(res)
	_check(b.presentado() and not b.puede_presentar(), "presentado")
	_check(int(b.consejo["aciertos"]) == 2 and b.consejo["calificacion"] == "consejo_2", "calificación consejo_2")
	_check(b.consejo["registrado"] == false, "todavía sin registrar")
	_check(is_equal_approx(b.calificacion_estimada(), 3.4), "3,80 + 0,60 - 1 = 3,40 (%.2f)" % b.calificacion_estimada())
	_check(b.consejo["sinergias"] == ["ciclovia_lote", "dia_sin_carros_feria", "flota_electrica"], "cruces congelados al presentar")
	_check(not b.aplicar_valida("tr_bici_cafetin", "techado_con_panel"), "plan presentado: cerrado")
	_check(not b.puede_cambiar_en_consejo(), "sin cambios tras presentar")

	var det : Dictionary = b.a_detalle()
	_check(det["version"] == 1 and det["presupuesto"]["total"] == 100 and det["presupuesto"]["comprometido"] == 94, "detalle con presupuesto")
	var txt := JSON.stringify(det)
	_check(txt.length() < 8192, "detalle < 8 KB (%d)" % txt.length())
	var c = PLAN.new()
	c.cargar(JSON.parse_string(txt))
	_check(c.presentado() and c.opcion_actual("tr_flota") == "carritos_electricos" and c.costo_comprometido() == 94, "ida y vuelta")
	_check(c.descartada("tr_permisos", "pintar_mas_puestos") and c.cambios_en_consejo == 2 and c.encargo_aceptado, "ida y vuelta conserva descartes y cambios")

	var roto = PLAN.new()
	roto.cargar({"encargo_aceptado": true, "consejo": "roto", "decisiones": {
		"tr_lote": {"opcion": "asfaltar_lote", "costo": 0},
		"inventada": {"opcion": "x"},
		"tr_flota": "no es un diccionario",
		"tr_carpool": {"opcion": "app_carpool", "costo": 1},
	}})
	_check(not roto.resuelta("tr_lote"), "contraproducente guardada como elegida se ignora")
	_check(not roto.decisiones.has("inventada") and not roto.decisiones.has("tr_flota"), "entradas inválidas ignoradas")
	_check(roto.costo_comprometido() == 26, "el costo sale de los datos, no del JSON")
	_check(roto.consejo.is_empty(), "consejo corrupto se ignora")
	var vacio = PLAN.new()
	vacio.cargar({})
	_check(vacio.vacio(), "detalle vacío = plan vacío")

	print("test_plan_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
