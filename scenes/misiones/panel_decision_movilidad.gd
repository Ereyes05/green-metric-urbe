# ============================================================
# panel_decision_movilidad.gd — NIVEL 5: panel de una decisión del Plan de
# Movilidad (también los bicicleteros). Regla Mixta (spec §8): antes de
# confirmar solo se ve el costo; la contraproducente resta 1, no gasta y
# permite reintentar; la válida revela las tres opciones.
# Mismo patrón de interacción que simulador_decision.gd. Estilo: solo
# tokens de hud_tema.gd vía ui_movilidad.gd.
# Modifica el plan en memoria; guardar, misiones y telemetría son del
# controlador (nivel5_movilidad.gd), que escucha decision_registrada.
# ============================================================
extends CanvasLayer

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const UI := preload("res://scenes/misiones/ui_movilidad.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

signal decision_registrada(decision_id: String, opcion_id: String, contraproducente: bool, penalizado: bool, ms_hasta_elegir: int)
signal cerrado()

var plan = null                           # plan_movilidad.gd
# (decision_id, opcion_id) -> void. La respuesta llega por recibir_respuesta().
var registrar : Callable = Callable()

var decision_id : String = ""
var estado : String = "cerrado"
var modo_consejo : bool = false
var _sel : String = ""
var _t_abierto : int = 0

var _titulo : Label = null
var _lugar : Label = null
var _presupuesto : Label = null
var _contexto : Label = null
var _pregunta : Label = null
var _botones : Array = []
var _detalles : Array = []
var _estado_lbl : Label = null
var _accion : Button = null
var _cerrar : Button = null


func _ready() -> void:
	layer = 20
	_construir()
	visible = false


func abrir(id: String, en_consejo: bool = false) -> void:
	var d := DATOS.decision(id)
	if d.is_empty() or plan == null:
		return
	decision_id = id
	modo_consejo = en_consejo
	_sel = plan.opcion_actual(id)
	_t_abierto = Time.get_ticks_msec()
	_titulo.text = d["titulo"]
	_lugar.text = "%s · %s" % [DATOS.NOMBRE_LUGAR.get(d["lugar"], ""), d["indicador"]]
	_contexto.text = d["contexto"]
	_pregunta.text = d["pregunta"]
	if plan.presentado() or (en_consejo and not plan.puede_cambiar_en_consejo()):
		estado = "solo_lectura"
	else:
		estado = "eligiendo"
	_estado_lbl.text = ""
	_pintar()
	visible = true


func cerrar() -> void:
	if estado == "esperando":
		return
	estado = "cerrado"
	visible = false
	cerrado.emit()


func _on_opcion(i: int) -> void:
	if estado != "eligiendo":
		return
	var ops : Array = DATOS.decision(decision_id)["opciones"]
	_sel = ops[i]["id"]
	_pintar()


func _on_accion() -> void:
	match estado:
		"eligiendo":
			_confirmar()
		"revelado_contra":
			estado = "eligiendo"
			_sel = plan.opcion_actual(decision_id)
			_estado_lbl.text = ""
			_pintar()
		"revelado_valida", "solo_lectura":
			cerrar()


func _confirmar() -> void:
	var actual : String = plan.opcion_actual(decision_id)
	if _sel == "" or _sel == actual or not plan.alcanza(decision_id, _sel) or plan.descartada(decision_id, _sel):
		return
	estado = "esperando"
	_estado_lbl.text = "Registrando tu decisión…"
	_estado_lbl.add_theme_color_override("font_color", TEMA.TEXTO_3)
	_pintar()
	if registrar.is_valid():
		registrar.call(decision_id, _sel)
	else:
		recibir_respuesta(decision_id, _sel, {"ok": false, "error": "sin_sesion"})


# Conectado a PuntajeManager.decision_resuelta. NUNCA reintenta solo: ante un
# error vuelve a "eligiendo" y el estudiante confirma de nuevo (un reintento
# automático de una contraproducente sumaría otra penalización).
func recibir_respuesta(id: String, opcion_id: String, respuesta: Dictionary) -> void:
	if estado != "esperando" or id != decision_id or opcion_id != _sel:
		return
	var o := DATOS.opcion(decision_id, opcion_id)
	var ok := bool(respuesta.get("ok", false))
	var sin_sesion := str(respuesta.get("error", "")) == "sin_sesion"
	if not ok and not sin_sesion:
		estado = "eligiendo"
		_estado_lbl.text = "No se pudo registrar la decisión (sin conexión o error del servidor). No se aplicó nada: vuelve a confirmar cuando tengas conexión."
		_estado_lbl.add_theme_color_override("font_color", TEMA.NARANJA)
		_pintar()
		return
	var contra : bool = bool(respuesta.get("contraproducente", false)) if ok else bool(o["contraproducente"])
	var penalizado : bool = ok and bool(respuesta.get("penalizado", false))
	var ms : int = Time.get_ticks_msec() - _t_abierto
	if contra:
		plan.registrar_contraproducente(decision_id, opcion_id)
		estado = "revelado_contra"
		if penalizado:
			_estado_lbl.text = "Opción contraproducente: -1 en Decisiones de Transporte. El presupuesto no se gastó; puedes reintentar."
		elif sin_sesion:
			_estado_lbl.text = "Opción contraproducente (sin sesión: no se registró penalización). El presupuesto no se gastó; puedes reintentar."
		else:
			_estado_lbl.text = "Opción contraproducente. Ya tenías el máximo de 3 penalizaciones en esta decisión. El presupuesto no se gastó; puedes reintentar."
		_estado_lbl.add_theme_color_override("font_color", TEMA.ALERTA)
	else:
		plan.aplicar_valida(decision_id, opcion_id, modo_consejo)
		estado = "revelado_valida"
		_estado_lbl.text = "Decisión registrada. Así quedan las tres opciones:"
		_estado_lbl.add_theme_color_override("font_color", TEMA.VERDE)
	_pintar()
	decision_registrada.emit(decision_id, opcion_id, contra, penalizado, ms)


func _consecuencias(o: Dictionary) -> String:
	var partes := PackedStringArray()
	if o["contraproducente"]:
		partes.append("Contraproducente según GreenMetric")
	else:
		partes.append("Transporte %s" % UI.puntos(float(o["puntos"])))
		partes.append(str(DATOS.ACEPTACION_TEXTO.get(o["aceptacion"], "")))
	partes.append("Costo %d" % int(o["costo"]))
	var texto := " · ".join(partes) + "\n" + str(o["explicacion"])
	var s := str(o.get("sinergia", ""))
	if s != "":
		texto += "\n" + DATOS.texto_sinergia(s)
	return texto


func _pintar() -> void:
	var ops : Array = DATOS.decision(decision_id)["opciones"]
	var ya_resuelta : bool = plan.resuelta(decision_id)
	var revelar_todo : bool = ya_resuelta or estado == "revelado_valida" or estado == "solo_lectura"
	_presupuesto.text = "Presupuesto disponible: %d de %d" % [plan.restante(), DATOS.PRESUPUESTO]
	for i in ops.size():
		var o : Dictionary = ops[i]
		var b : Button = _botones[i]
		var det : Label = _detalles[i]
		b.text = o["texto"]
		var elegida : bool = o["id"] == _sel
		UI.pintar_boton(b, UI.ACENTO, elegida)
		var bloqueo := ""
		if plan.descartada(decision_id, o["id"]):
			bloqueo = "Descartada: es contraproducente."
		elif not plan.alcanza(decision_id, o["id"]):
			bloqueo = "No alcanza el presupuesto (faltan %d)." % plan.faltante(decision_id, o["id"])
		b.disabled = estado != "eligiendo" or bloqueo != ""
		var revelada : bool = revelar_todo or (estado == "revelado_contra" and elegida)
		det.text = _consecuencias(o) if revelada else "Costo: %d" % int(o["costo"])
		if bloqueo != "" and estado == "eligiendo":
			det.text += "  ·  " + bloqueo
		var color := TEMA.TEXTO_3
		if revelada:
			color = TEMA.ALERTA if o["contraproducente"] else TEMA.TEXTO_2
		det.add_theme_color_override("font_color", color)
	match estado:
		"eligiendo":
			_accion.text = "Cambiar decisión" if ya_resuelta else "Confirmar decisión"
			_accion.disabled = _sel == "" or _sel == plan.opcion_actual(decision_id)
		"esperando":
			_accion.text = "Registrando…"
			_accion.disabled = true
		"revelado_contra":
			_accion.text = "Reintentar"
			_accion.disabled = false
		_:
			_accion.text = "Listo"
			_accion.disabled = false
	_cerrar.disabled = estado == "esperando"


func _construir() -> void:
	var vb := UI.panel_modal(self, 700)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	vb.add_child(cab)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	cab.add_child(col)
	col.add_child(UI.texto("🚲 Plan de Movilidad", 11, TEMA.VIOLETA, 600))
	_titulo = UI.texto("", 17, TEMA.TEXTO, 700)
	col.add_child(_titulo)
	_lugar = UI.texto("", 11, TEMA.TEXTO_3)
	col.add_child(_lugar)
	_cerrar = UI.boton("Cerrar", TEMA.VACIO, 30)
	_cerrar.custom_minimum_size = Vector2(80, 30)
	_cerrar.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cerrar.pressed.connect(cerrar)
	cab.add_child(_cerrar)
	_presupuesto = UI.texto("", 12, TEMA.DORADO, 600)
	vb.add_child(_presupuesto)
	_contexto = UI.texto("", 12, TEMA.TEXTO_2)
	vb.add_child(_contexto)
	vb.add_child(UI.separador())
	_pregunta = UI.texto("", 13, TEMA.TEXTO, 600)
	vb.add_child(_pregunta)
	_estado_lbl = UI.texto("", 12, TEMA.TEXTO_3, 600)
	vb.add_child(_estado_lbl)
	_botones.clear()
	_detalles.clear()
	for i in 3:
		var b := UI.boton("")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_opcion.bind(i))
		vb.add_child(b)
		_botones.append(b)
		var det := UI.texto("", 11, TEMA.TEXTO_3)
		vb.add_child(det)
		_detalles.append(det)
	_accion = UI.boton("Confirmar decisión", TEMA.VERDE, 42)
	_accion.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_accion.pressed.connect(_on_accion)
	vb.add_child(_accion)
