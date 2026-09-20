# Prueba del llenado ambiental de las papeleras (zona_reciclaje.gd).
# Fija el ritmo en segundos, no la constante: lo que importa es cuánto
# dura la papelera limpia después de vaciarla, y que ninguna arranque la
# partida pidiendo el servicio.
# Correr: $GODOT --headless --path . res://tests/test_reciclaje_llenado.tscn
extends Node

const ZONA := preload("res://scenes/misiones/zona_reciclaje.gd")

# Los dos umbrales que lee zona_reciclaje: 0.35 habilita llamar al
# servicio con [E], 0.40 cambia el texto del prompt a "escanear QR".
const UMBRAL_SERVICIO : float = 0.35

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


# Avanza el llenado simulando `segundos` de juego sin tocar el reloj real.
func _avanzar(z: Node, segundos: float) -> void:
	for i in int(segundos):
		z._process(1.0)


func _ready() -> void:
	print("test_reciclaje_llenado")

	# Ninguna papelera arranca pidiendo servicio. 40 instancias porque el
	# nivel inicial es aleatorio: con el rango viejo (0.20..0.50) esto
	# fallaba en la mayoría de las corridas.
	var peor : float = 0.0
	for i in 40:
		var z0 = ZONA.new()
		add_child(z0)
		peor = maxf(peor, z0.nivel_llenado)
		remove_child(z0)
		z0.free()
	_check(peor < UMBRAL_SERVICIO,
		"ninguna papelera arranca sobre el umbral de servicio (peor: %d%%)" % int(peor * 100))

	var z = ZONA.new()
	add_child(z)

	# Recién vaciada: cinco minutos de papelera limpia como mínimo.
	z.nivel_llenado = 0.0
	_avanzar(z, 300.0)
	_check(z.nivel_llenado < UMBRAL_SERVICIO,
		"a los 5 min de vaciarla sigue limpia (%d%%)" % int(z.nivel_llenado * 100))

	# Pero se llena: no es decorado estático.
	z.nivel_llenado = 0.0
	_avanzar(z, 600.0)
	_check(z.nivel_llenado >= UMBRAL_SERVICIO,
		"a los 10 min ya pide servicio (%d%%)" % int(z.nivel_llenado * 100))

	# Y no se pasa de 1.0 aunque la partida dure horas.
	z.nivel_llenado = 0.0
	_avanzar(z, 3600.0)
	_check(is_equal_approx(z.nivel_llenado, 1.0), "tope en 100%%: %f" % z.nivel_llenado)

	# En servicio el llenado se congela: el trabajador tarda en llegar y
	# sería absurdo que la papelera siguiera llenándose mientras tanto.
	z.nivel_llenado = 0.5
	z.en_servicio = true
	_avanzar(z, 300.0)
	_check(is_equal_approx(z.nivel_llenado, 0.5), "en servicio no se llena: %f" % z.nivel_llenado)
	z.en_servicio = false

	remove_child(z)
	z.free()

	print("test_reciclaje_llenado: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
