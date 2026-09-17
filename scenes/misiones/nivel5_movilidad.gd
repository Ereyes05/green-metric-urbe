# ============================================================
# nivel5_movilidad.gd — NIVEL 5: controlador del Plan de Movilidad.
# Reemplaza a oficina_movilidad.gd, mision_movilidad.gd,
# punto_bicicletero.gd y mision_bicicletero.gd.
# Tiene el plan, crea los 10 puntos (por lugar) y el nodo de cambios del
# mapa, abre los paneles, guarda el detalle "plan_movilidad", completa
# misiones (una vez), registra decisiones/cruces/telemetría y emite
# mision_completada para que SceneMapaMundo dé XP/EC y guarde el progreso.
# Dependencias inyectadas (configurar, de una sola vez: ver guarda al
# principio) para probarlo sin red.
# Ciclo de vida asumido: vive tanto como el mapa (SceneMapaMundo lo crea una
# vez y no lo saca de la escena mientras el mapa esté cargado). Por eso no
# libera los 10 puntos ni _cambios en _exit_tree(): se van con el mapa
# cuando SceneMapaMundo se destruye, junto con este controlador.
# Diseño: docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md
# ============================================================
extends Node

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")
const PUNTO := preload("res://scenes/misiones/punto_movilidad.gd")
const PANEL_DECISION := preload("res://scenes/misiones/panel_decision_movilidad.gd")
const PANEL_OFICINA := preload("res://scenes/misiones/panel_oficina_movilidad.gd")
const PANEL_CONSEJO := preload("res://scenes/misiones/panel_consejo_movilidad.gd")
const CAMBIOS := preload("res://scenes/mapa/cambios_movilidad.gd")

const NIVEL := 5
const CLAVE_DETALLE := "plan_movilidad"

signal mision_completada(mision_id: String, xp: int, ec: int)

var plan = PLAN.new()
# (tipo: String, punto: Node) -> bool. SceneMapaMundo pasa _verificar_herramienta.
var verificar_herramienta : Callable = Callable()

var panel_decision = null
var panel_oficina = null
var panel_consejo = null

var _mapa : Node = null
var _nm : Node = null
var _pm : Node = null
var _sm : Node = null
var _puntos : Dictionary = {}          # "oficina" | decision_id | "tr_consejo" -> punto
var _cambios = null
var _volver_a_consejo : bool = false


func configurar(mapa: Node, nivel_mgr: Node, puntaje_mgr: Node, supa: Node) -> void:
	# De una sola vez: una segunda llamada duplicaría los tres paneles y las
	# conexiones a PuntajeManager.decision_resuelta (a diferencia de
	# activar(), que ya es idempotente).
	if panel_decision != null:
		return
	_mapa = mapa
	_nm = nivel_mgr
	_pm = puntaje_mgr
	_sm = supa
	plan.cargar(_nm.obtener_detalle(CLAVE_DETALLE))

	panel_decision = PANEL_DECISION.new()
	add_child(panel_decision)
	panel_decision.plan = plan
	panel_decision.registrar = Callable(_pm, "registrar_decision")
	panel_decision.decision_registrada.connect(_on_decision_registrada)
	panel_decision.cerrado.connect(_on_panel_decision_cerrado)

	panel_oficina = PANEL_OFICINA.new()
	add_child(panel_oficina)
	panel_oficina.encargo_aceptado.connect(_on_encargo_aceptado)

	panel_consejo = PANEL_CONSEJO.new()
	add_child(panel_consejo)
	panel_consejo.cambio_solicitado.connect(_on_cambio_solicitado)
	panel_consejo.argumento_elegido.connect(_on_argumento_elegido)
	panel_consejo.plan_presentado.connect(_on_plan_presentado)
	panel_consejo.reintentar_registro.connect(_registrar_calificacion)

	_pm.decision_resuelta.connect(panel_decision.recibir_respuesta)
	_pm.decision_resuelta.connect(_on_decision_resuelta)


# Requisito de revisión (Task 10): _pm es un autoload que sobrevive al
# controlador. Si el nivel se destruye mientras una respuesta del servidor
# está en camino, sin este desconecte esa respuesta podría llegar a un panel
# ya liberado. En una destrucción normal los paneles (hijos de este nodo)
# TODAVÍA son válidos acá: Godot llama _exit_tree() de los hijos antes que
# el del padre, pero los libera después de que el padre termina de salir del
# árbol. Los is_instance_valid() son la guarda para el caso ya liberado
# (por ejemplo, si algo externo liberó _pm o el panel antes de este método).
func _exit_tree() -> void:
	if _pm == null or not is_instance_valid(_pm):
		return
	if is_instance_valid(panel_decision) and _pm.decision_resuelta.is_connected(panel_decision.recibir_respuesta):
		_pm.decision_resuelta.disconnect(panel_decision.recibir_respuesta)
	if _pm.decision_resuelta.is_connected(_on_decision_resuelta):
		_pm.decision_resuelta.disconnect(_on_decision_resuelta)


func activar() -> void:
	if not _puntos.is_empty() or _mapa == null or not _nm.nivel_desbloqueado(NIVEL):
		return
	_cambios = CAMBIOS.new()
	_mapa.add_child(_cambios)
	_crear_punto("oficina", "oficina", "oficina_movilidad", "Oficina de Movilidad")
	for d in DATOS.DECISIONES:
		_crear_punto(d["id"], d["tipo"], d["lugar"], d["titulo"])
	_crear_punto(DATOS.DECISION_CONSEJO, "consejo", "rectorado", "Consejo Universitario")
	_refrescar()


func hay_panel_abierto() -> bool:
	for p in [panel_decision, panel_oficina, panel_consejo]:
		if p != null and p.visible:
			return true
	return false


func _crear_punto(clave: String, tipo: String, lugar: String, nombre: String) -> void:
	var p = PUNTO.new()
	p.mision_id = "" if tipo == "oficina" else clave
	p.tipo = tipo
	p.lugar = lugar
	p.nombre_punto = nombre
	p.z_index = 1
	_mapa.add_child(p)
	p.interaccion_solicitada.connect(_on_interaccion)
	_puntos[clave] = p


func _refrescar() -> void:
	if _puntos.is_empty():
		return
	_puntos["oficina"].set_estado("resuelto" if plan.encargo_aceptado else "pendiente")
	for id in DATOS.ids_decisiones():
		var e := "bloqueado"
		if plan.encargo_aceptado:
			e = "resuelto" if plan.resuelta(id) else "pendiente"
		_puntos[id].set_estado(e)
	var ec := "bloqueado"
	if plan.presentado():
		ec = "resuelto"
	elif plan.encargo_aceptado and plan.todas_resueltas():
		ec = "pendiente"
	_puntos[DATOS.DECISION_CONSEJO].set_estado(ec)
	if _cambios:
		_cambios.actualizar(plan)


func _on_interaccion(punto) -> void:
	if hay_panel_abierto():
		return
	# Restauración tardía: el detalle pudo llegar del servidor después de
	# crear el controlador (timeout del login).
	if plan.vacio():
		plan.cargar(_nm.obtener_detalle(CLAVE_DETALLE))
		_refrescar()
	var tipo := str(punto.get("tipo"))
	match tipo:
		"oficina":
			panel_oficina.abrir(plan)
		"consejo":
			if plan.presentado():
				_reenviar_sinergias()
			elif not (plan.encargo_aceptado and plan.todas_resueltas()):
				return
			panel_consejo.abrir(plan)
		_:
			var id := str(punto.get("mision_id"))
			if not plan.encargo_aceptado:
				return
			if not plan.resuelta(id):
				if tipo == "bicicletero" and verificar_herramienta.is_valid() \
						and not verificar_herramienta.call("bicicletero", punto):
					return
				_evento(id, "mision_iniciada", {})
			panel_decision.abrir(id)


func _on_encargo_aceptado() -> void:
	plan.encargo_aceptado = true
	_guardar()
	_evento(CLAVE_DETALLE, "encargo_aceptado", {})
	panel_oficina.abrir(plan)
	_refrescar()


func _on_decision_registrada(decision_id: String, opcion_id: String, contraproducente: bool, _penalizado: bool, ms: int) -> void:
	var o := DATOS.opcion(decision_id, opcion_id)
	_evento(decision_id, "decision_tomada", {
		"decision_id": decision_id, "opcion_id": opcion_id,
		"contraproducente": contraproducente, "costo": int(o.get("costo", 0)),
		"presupuesto_restante": plan.restante(), "ms_hasta_elegir": ms,
	}, not contraproducente)
	_guardar()
	# plan.resuelta(decision_id): si el servidor dice "válida" pero el plan no
	# la aplicó (desincronización con el catálogo local — p. ej. el cliente
	# la sigue viendo contraproducente), no completar la misión: el plan
	# queda sin esa decisión y el Consejo la exigiría para siempre.
	if not contraproducente and plan.resuelta(decision_id) and not _nm.mision_completada_q(NIVEL, decision_id):
		_completar(decision_id)
	_refrescar()


func _on_panel_decision_cerrado() -> void:
	if _volver_a_consejo:
		_volver_a_consejo = false
		panel_consejo.abrir(plan)


func _on_cambio_solicitado(decision_id: String) -> void:
	_volver_a_consejo = true
	panel_consejo.visible = false
	panel_decision.abrir(decision_id, true)


func _on_argumento_elegido(decision_id: String, opcion_id: String, indice: int, correcto: bool, intento: int) -> void:
	_evento(DATOS.DECISION_CONSEJO, "argumento_consejo",
		{"decision_id": decision_id, "opcion_id": opcion_id, "argumento": indice}, correcto, intento)


func _on_plan_presentado() -> void:
	_guardar()
	_evento(DATOS.DECISION_CONSEJO, "plan_presentado", {
		"aciertos": int(plan.consejo.get("aciertos", 0)),
		"calificacion": str(plan.consejo.get("calificacion", "")),
		"presupuesto_restante": plan.restante(),
		"sinergias": plan.consejo.get("sinergias", []),
	})
	if not _nm.mision_completada_q(NIVEL, DATOS.DECISION_CONSEJO):
		_completar(DATOS.DECISION_CONSEJO)
	_registrar_calificacion()
	# Después de _completar: guardar_progreso(tr_consejo) ya está en la cola
	# FIFO de SupabaseManager y el servidor exige esa misión como requisito.
	_reenviar_sinergias()
	_refrescar()


# Registro de la calificación del Consejo. Se llama al presentar y solo a
# pedido del estudiante ("Reintentar registro"): nunca en automático.
func _registrar_calificacion() -> void:
	var cal := str(plan.consejo.get("calificacion", ""))
	if cal != "":
		_pm.registrar_decision(DATOS.DECISION_CONSEJO, cal)


# Idempotente en el servidor (una sinergia se gana una sola vez).
func _reenviar_sinergias() -> void:
	for s in plan.consejo.get("sinergias", []):
		_pm.registrar_sinergia(str(s))


func _on_decision_resuelta(decision_id: String, _opcion_id: String, respuesta: Dictionary) -> void:
	if decision_id != DATOS.DECISION_CONSEJO or not plan.presentado():
		return
	if bool(respuesta.get("ok", false)):
		plan.consejo["registrado"] = true
		_guardar()
		if panel_consejo.visible:
			panel_consejo.abrir(plan)


# Sin re-pago (spec §11.1): quien completó el Nivel 5 viejo recibe 0 y 0;
# SceneMapaMundo interpreta eso como "no dar XP ni EC" pero igual guarda el
# progreso (Avance de Transporte y requisito de los cruces).
func _completar(mision_id: String) -> void:
	var sin_pago : bool = _nm.legado_completo(NIVEL)
	_nm.completar_mision(NIVEL, mision_id)
	var xp : int = 0 if sin_pago else int(_nm.XP_POR_MISION.get(NIVEL, 35))
	var ec : int = 0 if sin_pago else int(_nm.EC_POR_MISION.get(NIVEL, 12))
	mision_completada.emit(mision_id, xp, ec)


func _guardar() -> void:
	_nm.guardar_detalle(CLAVE_DETALLE, plan.a_detalle())


func _evento(mision_id: String, tipo: String, detalle: Dictionary, correcto = null, intento = null) -> void:
	if _sm != null and _sm.has_method("registrar_evento"):
		_sm.registrar_evento(NIVEL, mision_id, tipo, detalle, correcto, intento)
