# Prueba de RANGOS.debe_anunciar(): decide cuándo el HUD debe mostrar
# "⭐ Nuevo rango". Extraída como función pura porque SceneMapaMundo.gd no
# se puede instanciar en headless (sus @onready dependen de nodos hijos que
# solo existen en la .tscn real: Jugador, ZonasCampus, FondoCampus, etc.).
#
# Motivo del fix (ver task-6-report.md, fix round 1, finding 1): en
# NivelManager.completar_mision() la señal mision_nivel_completada se emite
# ANTES que nivel_completado (autoload/NivelManager.gd:207-216). PuntajeManager
# reacciona a esa primera señal de forma síncrona y termina emitiendo
# puntaje_actualizado, que SceneMapaMundo escucha con _refrescar_progreso()
# → _actualizar_hud(), la cual YA actualiza _nivel_actual al rango nuevo.
# Recién después llega nivel_completado y dispara
# _on_nivel_greenmetric_completado(): si ese handler comparaba
# "_nivel_actual antes" contra "_nivel_actual después" tomando ambas
# fotos ahí mismo, las dos siempre coincidían (ya estaba actualizado) y el
# aviso nunca se disparaba. La solución mueve la decisión a
# _actualizar_hud() mismo (que corre en cada refresco, sin importar qué
# señal lo disparó) comparando contra la última línea base ya avisada.
#
# Correr: $GODOT --headless --path . res://tests/test_hud_rango_aviso.tscn
extends Node

const RANGOS := preload("res://autoload/rangos.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_hud_rango_aviso")

	# Línea base sin establecer (-1): ni con "nuevo" en 0 ni con un progreso
	# ya avanzado (repoblado desde el servidor en SceneLogin, primer refresco
	# del HUD en el mapa) debe anunciar — sería un falso "ascenso" de algo
	# que el jugador ya tenía de antes.
	_check(not RANGOS.debe_anunciar(-1, 0), "sin línea base y rango 0: no anuncia")
	_check(not RANGOS.debe_anunciar(-1, 3), "sin línea base y progreso ya alto: no anuncia (carga inicial)")

	# Ascenso real en vivo: línea base ya establecida y el nuevo rango es mayor.
	_check(RANGOS.debe_anunciar(0, 1), "de Semilla a Brote en vivo: anuncia")
	_check(RANGOS.debe_anunciar(4, 5), "de Investigador a EcoLíder en vivo: anuncia")

	# Mismo rango (refresco repetido, p.ej. dos señales por la misma misión):
	# no debe volver a anunciar.
	_check(not RANGOS.debe_anunciar(2, 2), "mismo rango: no vuelve a anunciar")

	# Rango "hacia atrás" no debería pasar en el juego real, pero la función
	# no debe anunciar un descenso.
	_check(not RANGOS.debe_anunciar(3, 1), "rango menor al ya anunciado: no anuncia")

	# Simulación de la secuencia real del bug: primer _actualizar_hud() en
	# _ready() establece línea base en 0 sin avisar; luego una misión sube
	# el rango a 1 y _actualizar_hud() se llama de nuevo (vía
	# _refrescar_progreso, ANTES de que _on_nivel_greenmetric_completado
	# corra) — ahí sí debe anunciar. Si _on_nivel_greenmetric_completado
	# vuelve a llamar _actualizar_hud() después (idempotente), ya no debe
	# volver a anunciar el mismo ascenso.
	var anunciado := -1
	_check(not RANGOS.debe_anunciar(anunciado, 0), "primer refresco (arranque): no anuncia")
	anunciado = 0
	_check(RANGOS.debe_anunciar(anunciado, 1), "refresco tras completar una misión: anuncia")
	anunciado = 1
	_check(not RANGOS.debe_anunciar(anunciado, 1), "refresco idempotente posterior (mismo rango): no repite el aviso")

	print("test_hud_rango_aviso: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
