# ============================================================
# tests_nivel.gd — URBE Rangers: Eco-Quest
# Test al terminar cada nivel + test final (pedido del jurado de la
# predefensa: comprobar si al estudiante le quedó el mensaje del nivel).
#
# Solo arma las preguntas y decide qué test toca. Las preguntas salen
# de QUIZ_POR_MISION (SceneMapaMundo.gd), el banco validado por la
# Dirección de Sostenibilidad el 2026-10-15: NO escribir preguntas acá
# sin una nueva validación.
#
# El resultado lo guarda sql/tests_nivel.sql (registrar_test) y no suma
# al puntaje GreenMetric.
# ============================================================
extends RefCounted

const PREGUNTAS_TEST  : int = 5   # tope por nivel (hay niveles con solo 3)
const PREGUNTAS_FINAL : int = 2   # por nivel, en el test final (12 en total)
const ID_FINAL : String = "final"

# Quizzes de QUIZ_POR_MISION que cubren cada nivel. Incluye los que hoy
# ningún NPC muestra (mision_bloque_g, mision_residuos): también están en el
# banco validado. mision_rector es la introducción a GreenMetric; va con
# Educación.
const QUIZZES_POR_NIVEL : Dictionary = {
	1: ["mision_bloque_f", "mision_fotocopiado", "mision_bloque_g"],
	2: ["mision_bloque_a", "mision_bloque_b", "mision_bloque_c",
		"mision_bloque_d", "mision_bloque_e"],
	3: ["mision_residuos"],
	4: ["mision_agua"],
	5: ["mision_transporte"],
	6: ["mision_educacion", "mision_rector"],
}


static func id_nivel(nivel: int) -> String:
	return "nivel_%d" % nivel


static func titulo(test_id: String) -> String:
	if test_id == ID_FINAL:
		return "Test final"
	return "Nivel %s" % test_id.trim_prefix("nivel_")


static func banco(nivel: int, quiz_por_mision: Dictionary) -> Array:
	var out : Array = []
	for mision_id in QUIZZES_POR_NIVEL.get(nivel, []):
		out.append_array(quiz_por_mision.get(mision_id, []))
	return out


static func _tomar(lista: Array, n: int, rng: RandomNumberGenerator) -> Array:
	var copia := lista.duplicate()
	# Fisher-Yates con el rng recibido, para que las pruebas sean repetibles.
	for i in range(copia.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = copia[i]
		copia[i] = copia[j]
		copia[j] = tmp
	return copia.slice(0, mini(n, copia.size()))


static func preguntas(test_id: String, quiz_por_mision: Dictionary,
					  rng: RandomNumberGenerator) -> Array:
	if test_id == ID_FINAL:
		var out : Array = []
		for n in range(1, 7):
			out.append_array(_tomar(banco(n, quiz_por_mision), PREGUNTAS_FINAL, rng))
		return out
	var nivel := int(test_id.trim_prefix("nivel_"))
	return _tomar(banco(nivel, quiz_por_mision), PREGUNTAS_TEST, rng)


# El test pendiente más bajo, o "" si no hay ninguno. elegibles = niveles
# terminados desde que existen los tests (obtener_tests en el servidor, más
# los que se completan en la sesión): a quien terminó un nivel antes no se le
# pide. hechos = {test_id: ...} del servidor. El final solo aparece con los
# 6 tests de nivel hechos.
static func pendiente(elegibles: Array, hechos: Dictionary) -> String:
	for n in range(1, 7):
		if n in elegibles and not hechos.has(id_nivel(n)):
			return id_nivel(n)
	for n in range(1, 7):
		if not hechos.has(id_nivel(n)):
			return ""
	return "" if hechos.has(ID_FINAL) else ID_FINAL
