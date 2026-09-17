# ============================================================
# panel_consejo_movilidad.gd — NIVEL 5: Consejo Universitario (Rectorado).
# Revisión del plan (hasta 2 cambios), 3 objeciones sobre los puntos
# débiles reales (plan.objeciones(), spec §7.2) con reintento en la misma
# objeción, y resultado (spec §7.5). Llama a plan.presentar(); guardar,
# misión, registro y cruces son del controlador (señal plan_presentado).
# ============================================================
extends CanvasLayer

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")
const UI := preload("res://scenes/misiones/ui_movilidad.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

signal cambio_solicitado(decision_id: String)
signal argumento_elegido(decision_id: String, opcion_id: String, indice: int, correcto: bool, intento: int)
signal plan_presentado()
signal reintentar_registro()
signal cerrado()

var plan = null
var fase : String = "cerrado"          # revision | objeciones | resultado
var _vb : VBoxContainer = null
var _objeciones : Array = []
var _idx : int = 0
var _resultados : Array = []
var _intentos : int = 0
var _descartados : Array = []
var _resuelta : bool = false
var _elegido : int = -1
var _feedback : String = ""
var _feedback_ok : bool = false
# Ya se presentó el plan (o se pidió reintentar) y todavía no llegó la
# primera respuesta del registro de la calificación (I1): mientras esto sea
# true, la pantalla de resultado muestra un aviso neutral y no el aviso
# naranja de "no registrada" ni el botón de reintento — ese solo aparece si
# la respuesta, cuando llega, no fue exitosa (ver marcar_registro_resuelto()).
var _esperando_registro : bool = false


func _ready() -> void:
	layer = 20
	_vb = UI.panel_modal(self, 680)
	visible = false


func abrir(p) -> void:
	plan = p
	fase = "resultado" if plan.presentado() else "revision"
	_reconstruir()
	visible = true


func cerrar() -> void:
	visible = false
	cerrado.emit()


func _reconstruir() -> void:
	UI.limpiar(_vb)
	_vb.add_child(UI.texto("🏆 Consejo Universitario · Plan de Movilidad", 11, TEMA.VIOLETA, 600))
	match fase:
		"revision":
			_pintar_revision()
		"objeciones":
			_pintar_objecion()
		"resultado":
			_pintar_resultado()


func _pintar_revision() -> void:
	_vb.add_child(UI.texto("Revisión antes de presentar", 17, TEMA.TEXTO, 700))
	var disponibles : int = PLAN.MAX_CAMBIOS_CONSEJO - int(plan.cambios_en_consejo)
	_vb.add_child(UI.texto("Puedes cambiar hasta %d decisiones si el presupuesto alcanza. Cambios disponibles: %d. Quedan %d de presupuesto." % [
		PLAN.MAX_CAMBIOS_CONSEJO, disponibles, plan.restante()], 12, TEMA.TEXTO_2))
	for d in DATOS.DECISIONES:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		var o := DATOS.opcion(d["id"], plan.opcion_actual(d["id"]))
		var nombre := TEMA.label("%s: %s" % [d["titulo"], o.get("corto", "Pendiente")], 12, TEMA.TEXTO, 600)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nombre)
		fila.add_child(TEMA.label("%s · costo %d" % [
			DATOS.ACEPTACION_TEXTO.get(o.get("aceptacion", ""), ""), int(o.get("costo", 0))], 11, TEMA.TEXTO_3))
		var cambiar := UI.boton("Cambiar", UI.ACENTO, 28)
		cambiar.custom_minimum_size = Vector2(84, 28)
		cambiar.alignment = HORIZONTAL_ALIGNMENT_CENTER
		cambiar.disabled = not plan.puede_cambiar_en_consejo()
		cambiar.pressed.connect(_on_cambiar.bind(str(d["id"])))
		fila.add_child(cambiar)
		_vb.add_child(fila)
	var presentar := UI.boton("Presentar al Consejo", TEMA.VERDE, 42)
	presentar.alignment = HORIZONTAL_ALIGNMENT_CENTER
	presentar.disabled = not plan.puede_presentar()
	presentar.pressed.connect(_iniciar_objeciones)
	_vb.add_child(presentar)
	var despues := UI.boton("Ahora no", TEMA.VACIO, 34)
	despues.alignment = HORIZONTAL_ALIGNMENT_CENTER
	despues.pressed.connect(cerrar)
	_vb.add_child(despues)


func _on_cambiar(decision_id: String) -> void:
	visible = false
	cambio_solicitado.emit(decision_id)


func _iniciar_objeciones() -> void:
	if not plan.puede_presentar():
		return
	_objeciones = plan.objeciones()
	_idx = 0
	_resultados = []
	_nueva_objecion()
	if _objeciones.is_empty():
		_terminar()
		return
	fase = "objeciones"
	_reconstruir()


func _nueva_objecion() -> void:
	_intentos = 0
	_descartados = []
	_resuelta = false
	_elegido = -1
	_feedback = ""
	_feedback_ok = false


func _pintar_objecion() -> void:
	var obj : Dictionary = _objeciones[_idx]
	var d := DATOS.decision(obj["decision"])
	_vb.add_child(UI.texto("Objeción %d de %d · %s" % [_idx + 1, _objeciones.size(), d["titulo"]], 12, TEMA.TEXTO_3, 600))
	_vb.add_child(UI.texto(obj["texto"], 15, TEMA.TEXTO, 600))
	_vb.add_child(UI.texto("Elige el argumento con el que respondes:", 12, TEMA.TEXTO_2))
	var args : Array = obj["argumentos"]
	for i in args.size():
		var b := UI.boton(str(args[i]["texto"]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UI.pintar_boton(b, TEMA.VERDE if i == _elegido else UI.ACENTO, i == _elegido)
		b.disabled = _resuelta or i in _descartados
		b.pressed.connect(_on_argumento.bind(i))
		_vb.add_child(b)
	if _feedback != "":
		_vb.add_child(UI.texto(_feedback, 12, TEMA.VERDE if _feedback_ok else TEMA.NARANJA))
	if _resuelta:
		var ultimo := _idx + 1 >= _objeciones.size()
		var sig := UI.boton("Ver resultado" if ultimo else "Siguiente objeción", TEMA.VERDE, 42)
		sig.alignment = HORIZONTAL_ALIGNMENT_CENTER
		sig.pressed.connect(_on_siguiente)
		_vb.add_child(sig)


func _on_argumento(i: int) -> void:
	if fase != "objeciones" or _resuelta or i in _descartados:
		return
	var obj : Dictionary = _objeciones[_idx]
	var arg : Dictionary = obj["argumentos"][i]
	var correcto := bool(arg["correcto"])
	_intentos += 1
	if _intentos == 1:
		_resultados.append({"decision": obj["decision"], "opcion": obj["opcion"],
			"primer_argumento": i, "correcto_primer_intento": correcto, "intentos": 1})
	else:
		_resultados[_idx]["intentos"] = _intentos
	_feedback = ("Convence: " if correcto else "No convence: ") + str(arg["explicacion"])
	_feedback_ok = correcto
	if correcto:
		_resuelta = true
		_elegido = i
	else:
		_descartados.append(i)
	argumento_elegido.emit(str(obj["decision"]), str(obj["opcion"]), i, correcto, _intentos)
	_reconstruir()


func _on_siguiente() -> void:
	if fase != "objeciones" or not _resuelta:
		return
	_idx += 1
	if _idx >= _objeciones.size():
		_terminar()
		return
	_nueva_objecion()
	_reconstruir()


func _terminar() -> void:
	plan.presentar(_resultados)
	fase = "resultado"
	_esperando_registro = true
	plan_presentado.emit()
	_reconstruir()


func _on_reintentar() -> void:
	_esperando_registro = true
	_reconstruir()
	reintentar_registro.emit()


# Conectado (indirectamente, vía nivel5_movilidad._on_decision_resuelta) a la
# respuesta del registro de la calificación — llega tanto si salió bien como
# si falló. No recibe el resultado: lo lee de plan.consejo["registrado"],
# que el controlador ya actualizó antes de llamar acá.
func marcar_registro_resuelto() -> void:
	if fase != "resultado":
		return
	_esperando_registro = false
	_reconstruir()


func _pintar_resultado() -> void:
	var c : Dictionary = plan.consejo
	var aciertos := int(c.get("aciertos", 0))
	_vb.add_child(UI.texto(str(DATOS.calificacion(aciertos)["nombre"]), 20, TEMA.VERDE, 700))
	_vb.add_child(UI.texto("Argumentos convincentes al primer intento: %d de 3" % aciertos, 13, TEMA.TEXTO_2))
	_vb.add_child(UI.texto("Calificación estimada del plan (Decisiones de Transporte): %s de 5. El número oficial es el del panel GreenMetric." % UI.decimal(plan.calificacion_estimada()), 13, TEMA.DORADO, 600))
	for r in c.get("objeciones", []):
		var d := DATOS.decision(str(r.get("decision", "")))
		var titulo := str(d.get("titulo", ""))
		var linea := ("%s: convenciste al primer intento" % titulo) if bool(r.get("correcto_primer_intento", false)) \
			else ("%s: lo resolviste en %d intentos" % [titulo, int(r.get("intentos", 1))])
		_vb.add_child(UI.texto(linea, 12, TEMA.TEXTO_2))
	var sins : Array = c.get("sinergias", [])
	if not sins.is_empty():
		_vb.add_child(UI.separador())
		for s in sins:
			_vb.add_child(UI.texto("✨ Sinergia ganada: %s" % DATOS.SINERGIAS.get(s, {}).get("efecto", ""), 12, TEMA.VERDE))
	if _esperando_registro:
		_vb.add_child(UI.texto("Registrando la calificación…", 12, TEMA.TEXTO_3))
	elif not bool(c.get("registrado", false)):
		_vb.add_child(UI.texto("La calificación todavía no quedó registrada en el servidor (sin conexión o sin sesión).", 12, TEMA.NARANJA))
		var reintentar := UI.boton("Reintentar registro", TEMA.NARANJA, 34)
		reintentar.alignment = HORIZONTAL_ALIGNMENT_CENTER
		reintentar.pressed.connect(_on_reintentar)
		_vb.add_child(reintentar)
	var cerrar_btn := UI.boton("Cerrar", TEMA.VACIO, 34)
	cerrar_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	cerrar_btn.pressed.connect(cerrar)
	_vb.add_child(cerrar_btn)
