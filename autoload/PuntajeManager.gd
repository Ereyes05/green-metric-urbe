# ============================================================
# PuntajeManager.gd — puntaje GreenMetric por categoría (0–100).
# Un solo número por categoría para todo el juego: HUD, mapa de calor,
# resultados e informe. Lo calcula el servidor (puntaje_greenmetric);
# acá se muestra el avance al instante y se alinea con cada respuesta.
# Diseño: docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md
#
# También sincroniza los "detalles" de NivelManager (decisiones con criterio
# propio) con el servidor: antes vivían solo en el archivo local.
# ============================================================
extends Node

const FORMULA := preload("res://autoload/puntaje_formula.gd")

signal puntaje_actualizado(categorias: Dictionary, total: float)
signal sinergia_obtenida(accion_id: String, categorias: Array)
signal decision_resuelta(decision_id: String, opcion_id: String, respuesta: Dictionary)

var categorias : Dictionary = FORMULA.normalizar({})
var total      : float      = 0.0
var cargado    : bool       = false

var _quizzes_hechos : Array = []
# Peticiones de puntaje en vuelo: se pide de nuevo solo cuando no hay otra
# esperando, para no encolar una por misión en ráfagas.
var _pidiendo : bool = false


func _ready() -> void:
	SupabaseManager.puntaje_recibido.connect(_on_puntaje_recibido)
	# Sin esto, una sola petición fallida (red caída, servidor abajo) deja
	# _pidiendo en true para siempre y ningún refresco vuelve a salir.
	SupabaseManager.puntaje_fallido.connect(_on_puntaje_fallido)
	SupabaseManager.calidad_respuesta.connect(_on_calidad_respuesta)
	SupabaseManager.progreso_guardado.connect(_on_progreso_guardado)
	NivelManager.mision_nivel_completada.connect(_on_mision_completada)
	NivelManager.detalle_guardado.connect(_on_detalle_guardado)


func _hay_sesion() -> bool:
	return not SupabaseManager.jwt_token.is_empty()


# Lo llama SceneLogin al entrar: descarta lo de la cuenta anterior.
func iniciar_sesion() -> void:
	categorias = FORMULA.normalizar({})
	total = 0.0
	cargado = false
	_quizzes_hechos = []
	_pidiendo = false
	_recalcular_avance_local()
	if _hay_sesion():
		_pedir_puntaje()


func valor(cat: int) -> float:
	return float(categorias.get(cat, {}).get("total", 0.0))


func fraccion(cat: int) -> float:
	return clampf(valor(cat) / 100.0, 0.0, 1.0)


func quiz_hecho(mision_id: String) -> bool:
	return mision_id in _quizzes_hechos


func registrar_quiz(mision_id: String, aciertos: int) -> void:
	if _hay_sesion():
		SupabaseManager.registrar_quiz(mision_id, aciertos)


func registrar_decision(decision_id: String, opcion_id: String) -> void:
	if _hay_sesion():
		SupabaseManager.registrar_decision(decision_id, opcion_id)
	else:
		decision_resuelta.emit(decision_id, opcion_id, {"ok": false, "error": "sin_sesion"})


func registrar_sinergia(accion_id: String) -> void:
	if _hay_sesion():
		SupabaseManager.registrar_sinergia(accion_id)


# Une los detalles del servidor con los locales. El servidor gana en las
# claves que tiene; las que solo existen localmente (decisiones tomadas
# antes de que existiera detalles_estudiante, o guardados que fallaron) se
# suben una vez. Solo llamar con una respuesta real del servidor: ante un
# fallo no se sabe qué claves tiene y se subirían todas las locales.
func restaurar_detalles(detalles_servidor: Dictionary) -> void:
	var locales : Dictionary = NivelManager.detalles_todos()
	for clave in locales.keys():
		if not detalles_servidor.has(clave) and _hay_sesion():
			SupabaseManager.guardar_detalle(str(clave), locales[clave])
	for clave in detalles_servidor.keys():
		if detalles_servidor[clave] is Dictionary:
			NivelManager.aplicar_detalle_servidor(str(clave), detalles_servidor[clave])


# ── Interno ───────────────────────────────────────────────────
func _pedir_puntaje() -> void:
	if _pidiendo: return
	_pidiendo = true
	SupabaseManager.obtener_puntaje()


func _aplicar(datos: Dictionary) -> void:
	categorias = FORMULA.normalizar(datos)
	total = float(datos.get("total", FORMULA.total_ponderado(categorias)))
	var hechos = datos.get("quizzes_hechos", [])
	if hechos is Array:
		_quizzes_hechos = hechos.duplicate()
	cargado = true
	puntaje_actualizado.emit(categorias, total)


func _recalcular_avance_local() -> void:
	for cat in FORMULA.PESOS.keys():
		categorias[cat] = FORMULA.con_avance(categorias[cat], NivelManager.pct_nivel(cat))
	total = FORMULA.total_ponderado(categorias)
	puntaje_actualizado.emit(categorias, total)


func _on_puntaje_recibido(datos: Dictionary) -> void:
	_pidiendo = false
	_aplicar(datos)


func _on_puntaje_fallido() -> void:
	_pidiendo = false


func _on_calidad_respuesta(respuesta: Dictionary, ctx: Dictionary) -> void:
	var tipo := str(ctx.get("tipo", ""))
	if respuesta.get("puntaje") is Dictionary:
		_aplicar(respuesta["puntaje"])
	if tipo == "sinergia" and bool(respuesta.get("nuevo", false)):
		var cats = respuesta.get("categorias", [])
		var lista : Array = cats if cats is Array else []
		sinergia_obtenida.emit(str(ctx.get("accion_id", "")), lista)
		# Telemetría (spec 6.5). nivel 0: una sinergia no es de un solo nivel.
		SupabaseManager.registrar_evento(0, str(ctx.get("accion_id", "")), "sinergia_obtenida",
			{"accion_id": str(ctx.get("accion_id", "")), "categorias": lista})
	elif tipo == "decision":
		decision_resuelta.emit(str(ctx.get("decision_id", "")), str(ctx.get("opcion_id", "")), respuesta)


# Muestra el avance ya; el servidor lo confirma cuando el guardado llega.
func _on_mision_completada(_nivel: int, _mision_id: String) -> void:
	_recalcular_avance_local()


func _on_progreso_guardado(_mision_id: String, _xp: int, _ya: bool, _corr: int) -> void:
	if _hay_sesion():
		_pedir_puntaje()


func _on_detalle_guardado(clave: String, detalle: Dictionary) -> void:
	if _hay_sesion():
		SupabaseManager.guardar_detalle(clave, detalle)
