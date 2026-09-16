# Prueba del Simulador de decisiones en modo práctica: sin impacto visible
# antes de confirmar, sin decision_tomada, sin EcoCredits.
# Correr: $GODOT --headless --path . res://tests/test_simulador.tscn
extends Node

const SIMULADOR := preload("res://scenes/ui/simulador_decision.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _impactos_visibles(sim: Node) -> bool:
	for etq in sim._etq_ops:
		if etq.visible and etq.text != "":
			return true
	return false


func _ready() -> void:
	print("test_simulador")

	var sim : Node = SIMULADOR.new()
	add_child(sim)

	var emitido := [0]
	sim.decision_tomada.connect(func(_modulo_id, _delta): emitido[0] += 1)

	var ec_antes : int = EconomiaManager.ecocredits

	sim.mostrar(4)

	_check(not _impactos_visibles(sim), "antes de elegir: ningún impacto visible")
	_check(sim._btn_confirmar.disabled, "confirmar deshabilitado antes de elegir")

	sim._seleccionar(0)
	_check(not sim._btn_confirmar.disabled, "confirmar habilitado tras elegir")
	_check(not _impactos_visibles(sim), "tras elegir (sin confirmar): sigue sin impacto visible")

	sim._confirmar()

	_check(_impactos_visibles(sim), "tras confirmar: impactos visibles")
	var todos_visibles := true
	for etq in sim._etq_ops:
		if not (etq.visible and etq.text != ""):
			todos_visibles = false
	_check(todos_visibles, "tras confirmar: TODAS las opciones muestran su impacto")

	_check(sim._edu_box.visible and sim._edu_lbl.text != "", "explicación educativa visible y no vacía")

	_check(emitido[0] == 0, "decision_tomada NO se emite en modo práctica")
	_check(EconomiaManager.ecocredits == ec_antes, "EcoCredits sin cambios")

	var opciones_deshabilitadas := true
	for btn in sim._btn_ops:
		if not btn.disabled:
			opciones_deshabilitadas = false
	_check(opciones_deshabilitadas, "tras confirmar: opciones ya no son clicables")

	_check(sim._btn_confirmar.text.findn("siguiente") != -1, "botón pasa a 'Siguiente caso'")

	# Siguiente caso: vuelve a ocultar los impactos.
	sim._on_btn_accion_pressed()
	_check(not _impactos_visibles(sim), "tras 'siguiente caso': impactos ocultos de nuevo")
	_check(sim._btn_confirmar.disabled, "tras 'siguiente caso': confirmar vuelve a estar deshabilitado")

	sim.queue_free()

	print("test_simulador: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
