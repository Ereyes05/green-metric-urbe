# ============================================================
# plan_movilidad.gd — estado y reglas del Plan de Movilidad (Nivel 5).
# Lógica pura, sin autoloads ni nodos (tests/test_plan_movilidad.gd). Se
# guarda en detalles_estudiante con la clave "plan_movilidad" (forma exacta:
# a_detalle(); spec §9).
# El presupuesto lo calcula el cliente (no es moneda: limitación documentada
# en la spec §18); cada opción la valida registrar_decision en el servidor.
# ============================================================
extends RefCounted

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")

const VERSION := 1
const MAX_CAMBIOS_CONSEJO := 2

var encargo_aceptado : bool = false
# decision_id -> {"opcion": String, "costo": int, "contraproducentes": Array, "cambios": int}
var decisiones : Dictionary = {}
var cambios_en_consejo : int = 0
# {} hasta presentar; ver presentar().
var consejo : Dictionary = {}


# Tolerante a datos viejos o corruptos: ignora decisiones/opciones que no
# existen, trata una contraproducente guardada como elegida como vacía y
# toma los costos de DATOS, no del JSON.
func cargar(d: Dictionary) -> void:
	encargo_aceptado = bool(d.get("encargo_aceptado", false))
	decisiones = {}
	var decs = d.get("decisiones", {})
	if decs is Dictionary:
		for id in decs.keys():
			var e = decs[id]
			if not (e is Dictionary) or DATOS.decision(str(id)).is_empty():
				continue
			var contras : Array = []
			var guardadas = e.get("contraproducentes", [])
			if guardadas is Array:
				for x in guardadas:
					if not DATOS.opcion(str(id), str(x)).is_empty() and not (str(x) in contras):
						contras.append(str(x))
			var op := str(e.get("opcion", ""))
			var dato_op := DATOS.opcion(str(id), op)
			if dato_op.is_empty() or bool(dato_op["contraproducente"]):
				op = ""
			decisiones[str(id)] = {
				"opcion": op,
				"costo": int(dato_op["costo"]) if op != "" else 0,
				"contraproducentes": contras,
				"cambios": int(e.get("cambios", 0)),
			}
	cambios_en_consejo = int(d.get("cambios_en_consejo", 0))
	var con = d.get("consejo", {})
	consejo = con.duplicate(true) if con is Dictionary else {}


func a_detalle() -> Dictionary:
	return {
		"version": VERSION,
		"encargo_aceptado": encargo_aceptado,
		"presupuesto": {"total": DATOS.PRESUPUESTO, "comprometido": costo_comprometido()},
		"decisiones": decisiones.duplicate(true),
		"cambios_en_consejo": cambios_en_consejo,
		"consejo": consejo.duplicate(true),
	}


func vacio() -> bool:
	return not encargo_aceptado and decisiones.is_empty()


func opcion_actual(decision_id: String) -> String:
	return str(decisiones.get(decision_id, {}).get("opcion", ""))


func resuelta(decision_id: String) -> bool:
	return opcion_actual(decision_id) != ""


func costo_comprometido(excepto: String = "") -> int:
	var total := 0
	for id in decisiones.keys():
		if id != excepto:
			total += int(decisiones[id].get("costo", 0))
	return total


func restante(excepto: String = "") -> int:
	return DATOS.PRESUPUESTO - costo_comprometido(excepto)


# La opción actual siempre alcanza; otra, si su costo entra liberando el de
# la opción actual de esa decisión.
func alcanza(decision_id: String, opcion_id: String) -> bool:
	var o := DATOS.opcion(decision_id, opcion_id)
	if o.is_empty():
		return false
	if opcion_actual(decision_id) == opcion_id:
		return true
	return int(o["costo"]) <= restante(decision_id)


func faltante(decision_id: String, opcion_id: String) -> int:
	var o := DATOS.opcion(decision_id, opcion_id)
	if o.is_empty() or alcanza(decision_id, opcion_id):
		return 0
	return int(o["costo"]) - restante(decision_id)


func descartada(decision_id: String, opcion_id: String) -> bool:
	return opcion_id in decisiones.get(decision_id, {}).get("contraproducentes", [])


func _entrada(decision_id: String) -> Dictionary:
	if not decisiones.has(decision_id):
		decisiones[decision_id] = {"opcion": "", "costo": 0, "contraproducentes": [], "cambios": 0}
	return decisiones[decision_id]


func registrar_contraproducente(decision_id: String, opcion_id: String) -> void:
	if DATOS.opcion(decision_id, opcion_id).is_empty():
		return
	var e := _entrada(decision_id)
	if not (opcion_id in e["contraproducentes"]):
		e["contraproducentes"].append(opcion_id)


# Aplica una opción válida ya confirmada por el servidor. false si no se
# aplica: inexistente, contraproducente, sin presupuesto, plan presentado o,
# en el Consejo, sin cambios disponibles.
func aplicar_valida(decision_id: String, opcion_id: String, en_consejo: bool = false) -> bool:
	var o := DATOS.opcion(decision_id, opcion_id)
	if o.is_empty() or bool(o["contraproducente"]) or presentado():
		return false
	var anterior := opcion_actual(decision_id)
	if anterior == opcion_id:
		return true
	if not alcanza(decision_id, opcion_id):
		return false
	if en_consejo and not puede_cambiar_en_consejo():
		return false
	var e := _entrada(decision_id)
	e["opcion"] = opcion_id
	e["costo"] = int(o["costo"])
	if anterior != "":
		e["cambios"] = int(e["cambios"]) + 1
		if en_consejo:
			cambios_en_consejo += 1
	return true


func todas_resueltas() -> bool:
	for id in DATOS.ids_decisiones():
		if not resuelta(id):
			return false
	return true


func presentado() -> bool:
	return bool(consejo.get("presentado", false))


func puede_presentar() -> bool:
	return encargo_aceptado and todas_resueltas() and not presentado()


func puede_cambiar_en_consejo() -> bool:
	return not presentado() and cambios_en_consejo < MAX_CAMBIOS_CONSEJO


func penalizaciones(decision_id: String) -> int:
	return mini(3, decisiones.get(decision_id, {}).get("contraproducentes", []).size())


# Spec §7.2: aceptación (baja 3, media 2, alta 1) + 2 si no es la mejor
# opción + contraproducentes probadas (máx. 3).
func debilidad(decision_id: String) -> int:
	var op := opcion_actual(decision_id)
	if op == "":
		return 0
	var o := DATOS.opcion(decision_id, op)
	var d := int(DATOS.ACEPTACION_PESO.get(o["aceptacion"], 1))
	if op != DATOS.mejor_opcion(decision_id):
		d += 2
	return d + penalizaciones(decision_id)


# Las 3 decisiones más débiles; empate = orden de DATOS.DECISIONES.
func objeciones() -> Array:
	var ids := DATOS.ids_decisiones()
	var orden := []
	for i in ids.size():
		if resuelta(ids[i]):
			orden.append({"id": ids[i], "d": debilidad(ids[i]), "i": i})
	orden.sort_custom(func(a, b): return a["d"] > b["d"] or (a["d"] == b["d"] and a["i"] < b["i"]))
	var out := []
	for e in orden:
		if out.size() == 3:
			break
		var op := opcion_actual(e["id"])
		var obj := DATOS.objecion(e["id"], op)
		if obj.is_empty():
			continue
		out.append({"decision": e["id"], "opcion": op, "texto": obj["texto"], "argumentos": obj["argumentos"]})
	return out


func puntos_opciones() -> float:
	var total := 0.0
	for id in decisiones.keys():
		var op := opcion_actual(id)
		if op != "":
			total += float(DATOS.opcion(id, op)["puntos"])
	return total


# Estimación local del componente Decisiones de Transporte (0–5), con la
# misma fórmula del servidor. El número oficial es el de puntaje_greenmetric.
func calificacion_estimada() -> float:
	var total := puntos_opciones()
	if presentado():
		total += float(DATOS.calificacion(int(consejo.get("aciertos", 0)))["puntos"])
	for id in decisiones.keys():
		total -= penalizaciones(id)
	return clampf(total, 0.0, 5.0)


func sinergias() -> Array:
	var out := []
	for id in DATOS.ids_decisiones():
		var op := opcion_actual(id)
		if op == "":
			continue
		var s := str(DATOS.opcion(id, op).get("sinergia", ""))
		if s != "" and not (s in out):
			out.append(s)
	return out


func presentar(resultados: Array) -> void:
	var aciertos := 0
	for r in resultados:
		if r is Dictionary and bool(r.get("correcto_primer_intento", false)):
			aciertos += 1
	aciertos = mini(aciertos, 3)
	consejo = {
		"presentado": true,
		"aciertos": aciertos,
		"calificacion": DATOS.calificacion(aciertos)["id"],
		"objeciones": resultados.duplicate(true),
		"sinergias": sinergias(),
		"registrado": false,
	}
