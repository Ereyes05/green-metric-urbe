# Prueba del panel de decisión: costo antes de confirmar, regla Mixta,
# error de red sin reintento automático, presupuesto y solo lectura.
# Correr: $GODOT --headless --path . res://tests/test_panel_decision_movilidad.tscn
extends Node

const PANEL := preload("res://scenes/misiones/panel_decision_movilidad.gd")
const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")
const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")

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


func _ready() -> void:
	print("test_panel_decision_movilidad")
	var plan = PLAN.new()
	plan.encargo_aceptado = true
	var panel : CanvasLayer = PANEL.new()
	add_child(panel)
	panel.plan = plan
	var llamadas := []
	panel.registrar = func(d, o): llamadas.append([d, o])
	var senales := []
	panel.decision_registrada.connect(func(d, o, c, p, _ms): senales.append([d, o, c, p]))
	var cerrados := [0]
	panel.cerrado.connect(func(): cerrados[0] += 1)

	var i_app := _idx("tr_carpool", "app_carpool")
	var i_3 := _idx("tr_carpool", "puestos_3_ocupantes")
	var i_contra := _idx("tr_carpool", "vender_puestos_reservados")

	panel.abrir("tr_carpool")
	_check(panel.visible and panel.estado == "eligiendo", "abre eligiendo")
	var solo_costo := true
	for det in panel._detalles:
		if det.text.contains("Transporte") or det.text.contains("Aceptación") or not det.text.contains("Costo"):
			solo_costo = false
	_check(solo_costo, "antes de confirmar: solo el costo")
	_check(panel._accion.disabled, "confirmar deshabilitado sin elección")
	panel._on_opcion(i_contra)
	_check(not panel._accion.disabled and panel._detalles[i_contra].text.begins_with("Costo"), "elegir no revela")
	panel._on_accion()
	_check(panel.estado == "esperando" and llamadas == [["tr_carpool", "vender_puestos_reservados"]], "confirmar registra una vez")
	_check(panel._cerrar.disabled and panel._botones[i_app].disabled, "esperando: nada clicable")
	panel.cerrar()
	_check(panel.visible, "no se cierra mientras espera")
	panel.recibir_respuesta("tr_lote", "asfaltar_lote", {"ok": true, "contraproducente": true, "penalizado": true})
	_check(panel.estado == "esperando", "ignora respuestas de otra decisión")

	panel.recibir_respuesta("tr_carpool", "vender_puestos_reservados", {"ok": true, "contraproducente": true, "penalizado": true})
	_check(panel.estado == "revelado_contra", "contraproducente revelada")
	_check(plan.descartada("tr_carpool", "vender_puestos_reservados") and plan.restante() == 100, "descartada y presupuesto intacto")
	_check(panel._detalles[i_contra].text.contains("Contraproducente"), "revela la elegida")
	_check(not panel._detalles[i_3].text.contains("Transporte"), "no revela las otras")
	_check(panel._estado_lbl.text.contains("-1"), "informa la penalización")
	_check(senales.back() == ["tr_carpool", "vender_puestos_reservados", true, true], "señal de contraproducente")
	panel._on_accion()
	_check(panel.estado == "eligiendo" and panel._botones[i_contra].disabled and panel._detalles[i_contra].text.contains("Descartada"), "reintento con la contraproducente descartada")

	panel._on_opcion(i_3)
	panel._on_accion()
	panel.recibir_respuesta("tr_carpool", "puestos_3_ocupantes", {"ok": false, "error": "red"})
	_check(panel.estado == "eligiendo" and not plan.resuelta("tr_carpool"), "error de red: no aplica")
	_check(llamadas.size() == 2, "error de red: no reintenta solo")
	_check(panel._estado_lbl.text.contains("No se pudo"), "error de red: lo explica")

	panel._on_accion()
	_check(llamadas.size() == 3, "el estudiante reconfirma")
	panel.recibir_respuesta("tr_carpool", "puestos_3_ocupantes", {"ok": true, "contraproducente": false})
	_check(panel.estado == "revelado_valida" and plan.opcion_actual("tr_carpool") == "puestos_3_ocupantes" and plan.restante() == 94, "válida aplicada")
	_check(panel._detalles[i_3].text.contains("Transporte +0,60") and panel._detalles[i_app].text.contains("Aceptación alta") and panel._detalles[i_contra].text.contains("Contraproducente"), "revela las tres")
	_check(senales.back() == ["tr_carpool", "puestos_3_ocupantes", false, false], "señal de válida")
	panel._on_accion()
	_check(not panel.visible and cerrados[0] == 1, "Listo cierra")

	panel.abrir("tr_carpool")
	_check(panel._detalles[i_app].text.contains("Transporte") and panel._accion.disabled and panel._accion.text == "Cambiar decisión", "reabrir: ya revelado, sin confirmar lo mismo")
	panel.cerrar()

	plan.aplicar_valida("tr_shuttle", "park_and_ride")
	plan.aplicar_valida("tr_dia_sin_carros", "cierre_semanal")
	plan.aplicar_valida("tr_lote", "ciclovia_arborizada")
	_check(plan.restante() == 10, "quedan 10")
	var i_el := _idx("tr_flota", "carritos_electricos")
	var i_tri := _idx("tr_flota", "triciclos_de_carga")
	var i_die := _idx("tr_flota", "camioneta_diesel")
	panel.abrir("tr_flota")
	_check(panel._botones[i_el].disabled and panel._detalles[i_el].text.contains("faltan 8"), "sin presupuesto: deshabilitada con faltante")
	_check(panel._botones[i_die].disabled and panel._detalles[i_die].text.contains("faltan 10"), "la contraproducente también respeta el presupuesto")
	_check(not panel._botones[i_tri].disabled, "la que alcanza queda habilitada")

	panel.registrar = Callable()
	panel._on_opcion(i_tri)
	panel._on_accion()
	_check(panel.estado == "revelado_valida" and plan.opcion_actual("tr_flota") == "triciclos_de_carga", "sin sesión: aplica en local")
	panel.cerrar()

	plan.presentar([])
	panel.abrir("tr_flota")
	var deshabilitados := true
	for b in panel._botones:
		if not b.disabled:
			deshabilitados = false
	_check(panel.estado == "solo_lectura" and deshabilitados and panel._accion.text == "Listo", "plan presentado: solo lectura")
	panel.cerrar()

	var src := FileAccess.get_file_as_string("res://scenes/misiones/panel_decision_movilidad.gd")
	_check(not src.contains("Color("), "sin colores literales: solo tokens del tema")

	print("test_panel_decision_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
