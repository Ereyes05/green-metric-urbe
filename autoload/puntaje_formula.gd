# ============================================================
# puntaje_formula.gd — espejo local del cálculo de
# public._puntaje_greenmetric (sql/puntaje_greenmetric.sql).
# Solo se usa para mostrar el avance al instante mientras llega la
# respuesta del servidor, que es la fuente de verdad.
# Sin referencias a autoloads, para poder probarlo solo.
# ============================================================
extends RefCounted

const PESOS : Dictionary = {1: 15, 2: 21, 3: 18, 4: 10, 5: 18, 6: 18}
const TOPES : Dictionary = {"avance": 80.0, "comprension": 10.0, "decisiones": 5.0, "sinergias": 5.0}


static func _vacia() -> Dictionary:
	return {"avance": 0.0, "comprension": 0.0, "decisiones": 0.0, "sinergias": 0.0, "total": 0.0}


# {"categorias": {"1": {...}}} (JSON del servidor) -> {1: {... floats}, ... 6}
static func normalizar(datos: Dictionary) -> Dictionary:
	var fuente : Dictionary = datos.get("categorias", {})
	var out : Dictionary = {}
	for cat in PESOS.keys():
		var c : Dictionary = fuente.get(str(cat), {})
		var fila := _vacia()
		for k in TOPES.keys():
			fila[k] = float(c.get(k, 0.0))
		fila["total"] = float(c.get("total", 0.0))
		out[cat] = fila
	return out


static func total_ponderado(categorias: Dictionary) -> float:
	var suma := 0.0
	for cat in PESOS.keys():
		suma += float(categorias.get(cat, _vacia()).get("total", 0.0)) * float(PESOS[cat])
	return suma / 100.0


# Copia de la categoría con el avance recalculado desde el % de misiones
# local, con los mismos topes que el servidor.
static func con_avance(categoria: Dictionary, pct_misiones: float) -> Dictionary:
	var fila := _vacia()
	for k in TOPES.keys():
		fila[k] = clampf(float(categoria.get(k, 0.0)), 0.0, TOPES[k])
	fila["avance"] = clampf(pct_misiones, 0.0, 1.0) * TOPES["avance"]
	fila["total"] = fila["avance"] + fila["comprension"] + fila["decisiones"] + fila["sinergias"]
	return fila
