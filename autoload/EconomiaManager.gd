# ============================================================
# EconomiaManager.gd — URBE Rangers: Eco-Quest
# Autoload: EcoCredits, Energía/Vidas, Insignias.
# ============================================================
extends Node

# ── Señales ──────────────────────────────────────────────────
signal ecocredits_cambiados(total: int)
signal energia_cambiada(actual: int, maximo: int)
signal insignia_obtenida(id: String, nombre: String, icono: String)

# ── EcoCredits ────────────────────────────────────────────────
# Desde el 2026-09-14 el saldo vive en el servidor (movimientos_ecocredits,
# ver sql/tienda_ecocredits.sql). Antes vivía solo acá, en memoria, y volvía
# a 50 cada vez que se abría el juego.
#
# Modelo: el cambio se muestra al instante en el HUD (optimista) y se manda
# al servidor; cuando no queda ninguna operación de EC en vuelo, el saldo
# local se reemplaza por el del servidor. Así el HUD responde rápido pero la
# fuente de verdad es siempre el servidor (una trampa local se corrige sola
# en la siguiente respuesta).
#
# Sin sesión (correr una escena directo desde el editor) todo funciona solo
# en memoria, como antes.
var ecocredits : int = 50

signal inventario_cambiado()
signal catalogo_listo()
# mensaje: texto listo para mostrar al estudiante
signal compra_terminada(ok: bool, item_id: String, mensaje: String)
# refs de mejoras/adopciones de zona ya pagadas, para reconstruir su estado
signal zonas_restauradas(refs: Array)

var inventario : Array = []        # item_id de lo comprado
var catalogo   : Array = []        # filas de catalogo_tienda
# Refs de mejoras/adopciones de zonas verdes ya pagadas. HOY NADIE LAS USA:
# las zonas verdes mejorables están eliminadas del mapa
# (SceneMapaMundo._spawn_zonas_verdes() es un `pass`). Si se reactivan, hay
# que reconstruir su nivel/adopción a partir de esto al entrar, o el
# estudiante perdería lo pagado (el EC gastado persiste, el nivel de la zona no).
var refs_zonas : Array = []
var billetera_cargada : bool = false

# Operaciones de EC mandadas al servidor que todavía no respondieron (más
# las misiones que esperan que se guarde su progreso para poder cobrarse).
var _ops_en_vuelo : int = 0
# Misiones completadas cuyo EC se cobra recién cuando llega la confirmación
# de guardar_progreso: el servidor solo paga misiones ya registradas, y en
# los callbacks de SceneMapaMundo el cobro ocurre ANTES que el guardado.
var _misiones_por_cobrar : Dictionary = {}
var _contador_refs : int = 0

# ── Energía / Vidas ──────────────────────────────────────────
const MAX_ENERGIA   : int = 3
var energia_actual  : int = 3
var _fallos_racha   : int = 0

# ── Insignias ─────────────────────────────────────────────────
const INSIGNIAS : Dictionary = {
	"m1_completo":    {"nombre": "Guardián Verde",    "icono": "🌿"},
	"m2_completo":    {"nombre": "Ahorrista Solar",   "icono": "⚡"},
	"m3_completo":    {"nombre": "Eco Clasificador",  "icono": "♻"},
	"m4_completo":    {"nombre": "Gota Vital",        "icono": "💧"},
	"m5_completo":    {"nombre": "Ciclista Campus",   "icono": "🚲"},
	"m6_completo":    {"nombre": "EcoInvestigador",   "icono": "📚"},
	"quiz_perfecto":  {"nombre": "Puntaje Perfecto",  "icono": "⭐"},
	"racha_fuego":    {"nombre": "Racha Ardiente",    "icono": "🔥"},
	"crisis_resuelta":{"nombre": "Héroe de Crisis",   "icono": "🚨"},
	"ecolider":       {"nombre": "EcoLíder URBE",     "icono": "🏆"},
}
var _insignias_obtenidas : Array = []

# ── Preguntas remediales para recuperar energía ───────────────
const PREGUNTAS_REMEDIALES : Array = [
	{"q": "¿Qué evalúa principalmente UI GreenMetric?",
	 "ops": ["Deportes universitarios", "Sostenibilidad del campus", "Rendimiento académico"], "c": 1},
	{"q": "¿Qué color corresponde a contenedores de papel reciclable?",
	 "ops": ["Rojo", "Azul", "Negro"], "c": 1},
	{"q": "¿Qué significa CO₂ en el contexto ambiental?",
	 "ops": ["Dióxido de carbono — gas de efecto invernadero", "Cloruro de calcio", "Combustible fósil"], "c": 0},
	{"q": "¿Qué porcentaje mínimo de área verde promueve GreenMetric?",
	 "ops": ["5%", "15%", "25%"], "c": 2},
	{"q": "¿Qué transporte prioriza GreenMetric en campus?",
	 "ops": ["Auto privado", "Moto", "Bicicleta y transporte público"], "c": 2},
	{"q": "¿Cuál es el módulo GreenMetric que evalúa el consumo eléctrico?",
	 "ops": ["Entorno", "Energía", "Transporte"], "c": 1},
	{"q": "¿Qué acción reduce más el consumo de agua en un campus?",
	 "ops": ["Regar jardines a mediodía", "Instalar grifos temporizadores", "Usar manguera libre"], "c": 1},
]
var _remedial_idx : int = 0


func _ready() -> void:
	randomize()
	SupabaseManager.billetera_cargada.connect(_on_billetera_cargada)
	SupabaseManager.catalogo_cargado.connect(_on_catalogo_cargado)
	SupabaseManager.billetera_actualizada.connect(_on_billetera_actualizada)
	SupabaseManager.compra_resuelta.connect(_on_compra_resuelta)
	SupabaseManager.progreso_guardado.connect(_on_progreso_guardado)
	SupabaseManager.progreso_guardado_fallido.connect(_on_progreso_guardado_fallido)


# ── Sesión ────────────────────────────────────────────────────
# Lo llama SceneLogin al entrar con una cuenta: descarta el estado de la
# cuenta anterior y pide saldo, inventario y catálogo al servidor.
func iniciar_sesion() -> void:
	ecocredits = 50
	inventario = []
	refs_zonas = []
	billetera_cargada = false
	_ops_en_vuelo = 0
	_misiones_por_cobrar = {}
	if _hay_sesion():
		SupabaseManager.obtener_billetera()
		SupabaseManager.cargar_catalogo()


func _hay_sesion() -> bool:
	return not SupabaseManager.jwt_token.is_empty()


# Referencia única para movimientos que pueden repetirse (una decisión, un
# riego...). Las que NO deben repetirse (un nivel, una zona) usan una ref
# fija y así el servidor no las paga dos veces.
func _ref_unica() -> String:
	_contador_refs += 1
	return "%d-%d-%04x" % [Time.get_unix_time_from_system() * 1000.0, _contador_refs, randi() % 0xFFFF]


# ── EcoCredits ────────────────────────────────────────────────
# motivo: uno de los que acepta sumar_ecocredits en el servidor ('minijuego',
# 'decision', 'adopcion_zona', 'contenedor', 'nivel', 'riego', 'quiz').
# Sin motivo, el cambio es solo local (no se guarda).
func ganar_creditos(cantidad: int, motivo: String = "", ref: String = "") -> void:
	if cantidad <= 0: return
	ecocredits += cantidad
	ecocredits_cambiados.emit(ecocredits)
	if motivo != "" and _hay_sesion():
		_ops_en_vuelo += 1
		SupabaseManager.sumar_ecocredits(cantidad, motivo, ref if ref != "" else _ref_unica())


# EC de una misión de campo. El monto real lo decide el servidor (según el
# módulo y el Termo reutilizable); `ec_estimado` es solo para mostrarlo ya.
func acreditar_mision(mision_id: String, ec_estimado: int) -> void:
	var estimado := ec_estimado
	if tiene_item("termo_reutilizable"):
		estimado = int(round(ec_estimado * 1.10))
	ecocredits += estimado
	ecocredits_cambiados.emit(ecocredits)
	if _hay_sesion() and not _misiones_por_cobrar.has(mision_id):
		_misiones_por_cobrar[mision_id] = true
		_ops_en_vuelo += 1


# motivo: 'energia', 'mejora_zona' o 'semana_verde'. Devuelve false si no
# alcanza el saldo local (el servidor vuelve a validarlo igual).
func gastar_creditos(cantidad: int, motivo: String = "", ref: String = "") -> bool:
	if ecocredits < cantidad: return false
	if cantidad <= 0: return true   # nada que cobrar (ej. Semana Verde sin actividades)
	ecocredits -= cantidad
	ecocredits_cambiados.emit(ecocredits)
	if motivo != "" and _hay_sesion():
		_ops_en_vuelo += 1
		SupabaseManager.gastar_ecocredits(cantidad, motivo, ref if ref != "" else _ref_unica())
	return true


# ── Respuestas del servidor ───────────────────────────────────
func _on_progreso_guardado(mision_id: String, _xp: int, _ya: bool, _corr: int) -> void:
	if _misiones_por_cobrar.has(mision_id):
		_misiones_por_cobrar.erase(mision_id)
		# _ops_en_vuelo ya contaba esta misión: se "transfiere" al pedido.
		SupabaseManager.acreditar_mision(mision_id)


func _on_progreso_guardado_fallido(mision_id: String, _xp: int) -> void:
	if _misiones_por_cobrar.has(mision_id):
		_misiones_por_cobrar.erase(mision_id)
		_terminar_op(-1)   # no se va a cobrar: realinear con el servidor


func _on_billetera_actualizada(respuesta: Dictionary, _ctx: Dictionary) -> void:
	_terminar_op(int(respuesta.get("saldo", -1)))


# saldo_servidor < 0 = no vino un saldo válido (error de red): se pide la
# billetera de nuevo en vez de quedarse con un saldo local que puede estar mal.
func _terminar_op(saldo_servidor: int) -> void:
	_ops_en_vuelo = maxi(0, _ops_en_vuelo - 1)
	if _ops_en_vuelo > 0:
		return
	if saldo_servidor >= 0:
		if saldo_servidor != ecocredits:
			ecocredits = saldo_servidor
			ecocredits_cambiados.emit(ecocredits)
	elif _hay_sesion():
		SupabaseManager.obtener_billetera()


func _on_billetera_cargada(datos: Dictionary) -> void:
	inventario = (datos.get("inventario", []) as Array).duplicate()
	refs_zonas = (datos.get("refs_zonas", []) as Array).duplicate()
	billetera_cargada = true
	# Si hay operaciones en vuelo, su respuesta traerá el saldo final.
	if _ops_en_vuelo == 0:
		ecocredits = int(datos.get("saldo", ecocredits))
		ecocredits_cambiados.emit(ecocredits)
	inventario_cambiado.emit()
	zonas_restauradas.emit(refs_zonas)


func _on_catalogo_cargado(items: Array) -> void:
	catalogo = items
	catalogo_listo.emit()


# ── Tienda ────────────────────────────────────────────────────
func tiene_item(item_id: String) -> bool:
	return item_id in inventario


func item_catalogo(item_id: String) -> Dictionary:
	for it in catalogo:
		if str(it.get("item_id", "")) == item_id:
			return it
	return {}


# Herramienta que exige un tipo de misión ('solar', 'captacion',
# 'bicicletero'), o {} si ese tipo no exige ninguna.
func herramienta_para(tipo_mision: String) -> Dictionary:
	for it in catalogo:
		if str(it.get("requerido_para", "")) == tipo_mision:
			return it
	return {}


# La compra se aplica recién cuando el servidor la confirma: acá no hay nada
# optimista, porque los criterios de HU-012 (saldo, precio, no recompra) los
# valida el servidor.
func comprar(item_id: String) -> void:
	if not _hay_sesion():
		compra_terminada.emit(false, item_id, "Necesitás iniciar sesión para comprar.")
		return
	if tiene_item(item_id):
		compra_terminada.emit(false, item_id, "Ya tenés este ítem.")
		return
	_ops_en_vuelo += 1
	SupabaseManager.comprar_item(item_id)


func _on_compra_resuelta(respuesta: Dictionary, item_id: String) -> void:
	var ok := bool(respuesta.get("ok", false))
	if ok and not tiene_item(item_id):
		inventario.append(item_id)
		inventario_cambiado.emit()
	_terminar_op(int(respuesta.get("saldo", -1)))
	var mensaje := ""
	if ok:
		mensaje = "¡Compraste %s!" % str(item_catalogo(item_id).get("nombre", item_id))
	else:
		match str(respuesta.get("error", "")):
			"saldo_insuficiente": mensaje = "EcoCredits insuficientes."
			"ya_comprado":        mensaje = "Ya tenés este ítem."
			"item_inexistente":   mensaje = "Ese ítem ya no está disponible."
			"red":                mensaje = "Sin conexión: no se pudo completar la compra."
			_:                    mensaje = "No se pudo completar la compra."
	compra_terminada.emit(ok, item_id, mensaje)


# Credencial de voluntario: +10% de XP en cada misión de campo.
func aplicar_bono_xp(xp: int) -> int:
	if tiene_item("credencial_voluntario"):
		return int(round(xp * 1.10))
	return xp


# ── Energía ───────────────────────────────────────────────────
func tiene_energia() -> bool:
	return energia_actual > 0


func on_fallo_quiz() -> void:
	_fallos_racha += 1
	if _fallos_racha >= 2:
		_fallos_racha = 0
		energia_actual = maxi(0, energia_actual - 1)
		energia_cambiada.emit(energia_actual, MAX_ENERGIA)


func on_acierto_quiz() -> void:
	_fallos_racha = 0


func recuperar_con_creditos() -> bool:
	if not gastar_creditos(25, "energia"): return false
	energia_actual = mini(MAX_ENERGIA, energia_actual + 1)
	energia_cambiada.emit(energia_actual, MAX_ENERGIA)
	return true


func recuperar_con_remedial() -> void:
	energia_actual = mini(MAX_ENERGIA, energia_actual + 1)
	energia_cambiada.emit(energia_actual, MAX_ENERGIA)


func siguiente_pregunta_remedial() -> Dictionary:
	var p : Dictionary = PREGUNTAS_REMEDIALES[_remedial_idx % PREGUNTAS_REMEDIALES.size()]
	_remedial_idx += 1
	return p


# ── Insignias ─────────────────────────────────────────────────
func otorgar_insignia(id: String) -> void:
	if id in _insignias_obtenidas or not INSIGNIAS.has(id): return
	_insignias_obtenidas.append(id)
	var ins : Dictionary = INSIGNIAS[id]
	insignia_obtenida.emit(id, ins["nombre"], ins["icono"])


func on_modulo_completado(modulo_id: int, xp_ganado: int, xp_maximo: int) -> void:
	ganar_creditos(xp_ganado / 5, "quiz")
	otorgar_insignia("m%d_completo" % modulo_id)
	if xp_ganado >= xp_maximo:
		otorgar_insignia("quiz_perfecto")
	if _insignias_obtenidas.size() >= INSIGNIAS.size() - 1:
		otorgar_insignia("ecolider")


func insignias_lista() -> Array:
	return _insignias_obtenidas.duplicate()
