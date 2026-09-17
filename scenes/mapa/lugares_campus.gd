# ============================================================
# lugares_campus.gd — registro único de lugares con nombre del campus.
# Todo lo nuevo (Nivel 5 Plan de Movilidad, minijuegos del proyecto C) se
# ubica por LUGAR + un desplazamiento chico, nunca con coordenadas en el
# código de la misión.
#
# PROVISIONAL: coordenadas del mapa actual (1408×768, mapa_campus.gd). El
# mapa se está rediseñando aparte; cuando llegue, reubicar = editar SOLO
# este archivo y volver a correr tests/test_lugares_campus.tscn (chequeo de
# solapamientos contra los puntos existentes).
# Diseño: docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md §3
# ============================================================
extends RefCounted

const LUGARES : Dictionary = {
	# Mismas coordenadas que tenían los puntos del Nivel 5 viejo.
	"oficina_movilidad":    Vector2(600, 100),   # camino norte, frente al Patio
	"bicicletero_bloque_e": Vector2(1020, 460),  # plaza entre Bloque E y Rectorado
	"bicicletero_cafetin":  Vector2(200, 360),   # borde este del M5, camino al Cafetín
	# Nuevos (Plan de Movilidad).
	"garita_m5":            Vector2(60, 330),    # entrada vehicular del M5
	"estacionamiento_m5":   Vector2(110, 240),   # zona norte del M5
	"lote_este":            Vector2(1340, 710),  # lote poco usado detrás de Estudios a Distancia
	"parada_rectorado":     Vector2(1060, 752),  # Av. URBE frente a la esquina del Rectorado
	"porton_vehicular":     Vector2(600, 752),   # portón de la Av. URBE
	"zona_mantenimiento":   Vector2(1190, 715),  # patio de servicios, sureste
	"rectorado":            Vector2(720, 560),   # entrada oeste del Rectorado (Consejo)
}


static func existe(lugar: String) -> bool:
	return LUGARES.has(lugar)


static func posicion(lugar: String, desplazamiento: Vector2 = Vector2.ZERO) -> Vector2:
	if not LUGARES.has(lugar):
		push_error("lugares_campus: lugar desconocido '%s'" % lugar)
		return Vector2.ZERO
	return LUGARES[lugar] + desplazamiento
