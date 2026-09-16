# ============================================================
# rangos.gd — rango del jugador: uno por nivel completado.
# Antes el rango salía del XP (Semilla 0 … EcoLíder 12000), pero el
# juego entero da ~2.800 XP y nadie pasaba de Árbol. Ahora cada nivel
# completado sube un rango; con 6 niveles y 6 rangos, Investigador
# cubre 4 y 5 niveles, y EcoLíder exige los 6.
# Espejo en el servidor: public.ranking_publico (sql/ranking_publico.sql).
# Sin referencias a autoloads, para poder probarlo solo.
# ============================================================
extends RefCounted

const NOMBRES : Array[String] = ["Semilla", "Brote", "Árbol", "Estratega", "Investigador", "EcoLíder"]


static func indice(niveles_completos: int) -> int:
	if niveles_completos >= 6:
		return 5
	return clampi(niveles_completos, 0, 4)


static func nombre(niveles_completos: int) -> String:
	return NOMBRES[indice(niveles_completos)]


static func siguiente(niveles_completos: int) -> String:
	var i := indice(niveles_completos)
	return "" if i == NOMBRES.size() - 1 else NOMBRES[i + 1]


# nm: NivelManager (o cualquier objeto con nivel_superado(n)).
static func niveles_superados(nm: Object) -> int:
	var c := 0
	for n in range(1, 7):
		if nm.nivel_superado(n):
			c += 1
	return c


# Niveles cuyo avance llena la barra hacia el siguiente rango.
static func _niveles_para_siguiente(c: int) -> Array[int]:
	if c >= 6:
		return []
	if c >= 4:
		return [5, 6]
	return [c + 1]


static func fraccion_siguiente(nm: Object) -> float:
	var niveles := _niveles_para_siguiente(niveles_superados(nm))
	if niveles.is_empty():
		return 1.0
	var suma := 0.0
	for n in niveles:
		suma += 1.0 if nm.nivel_superado(n) else clampf(nm.pct_nivel(n), 0.0, 1.0)
	return suma / niveles.size()


# Decide si corresponde mostrar el aviso "⭐ Nuevo rango". `anunciado` es el
# último índice de rango ya avisado (-1 = todavía sin línea base). Extraído
# como función pura para que quien recalcula el rango en cada refresco del
# HUD (que puede pasar varias veces por el mismo valor, o antes de tener una
# línea base real —arranque, progreso recién repoblado desde el servidor—)
# pueda decidir sin duplicar la lógica ni depender de CUÁNDO llega la señal
# nivel_completado respecto de la que repinta el HUD.
static func debe_anunciar(anunciado: int, nuevo: int) -> bool:
	return anunciado >= 0 and nuevo > anunciado
