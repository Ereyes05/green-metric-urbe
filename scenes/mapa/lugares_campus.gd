# ============================================================
# lugares_campus.gd — registro único de lugares con nombre del campus.
# Todo lo nuevo (Nivel 5 Plan de Movilidad, minijuegos del proyecto C) se
# ubica por LUGAR + un desplazamiento chico, nunca con coordenadas en el
# código de la misión.
#
# Mapa nuevo (urbe_removed (1).png): las coordenadas son LOCALES al nodo
# raíz SceneMapaMundo, igual que los DATOS_* de SceneMapaMundo.gd:
# posición = píxel de la imagen − (816, 412). Validadas contra las
# colisiones de la escena, sin solaparse con otra misión ni con un NPC, y
# con su decorado (cambios_movilidad.gd) sobre asfalto o camino libre.
# Reubicar = editar SOLO este archivo y volver a correr
# tests/test_lugares_campus.tscn.
# Diseño: docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md §3
# ============================================================
extends RefCounted

const LUGARES : Dictionary = {
	"oficina_movilidad":    Vector2(-166, 870),    # frente a la caseta del lote sur
	"bicicletero_bloque_e": Vector2(1584, -45),   # césped al este del Bloque D/E
	"bicicletero_cafetin":  Vector2(1764, 672),   # camino principal, entrada del picnic
	"garita_m5":            Vector2(-511, -187),   # entrada vehicular del estacionamiento norte
	"estacionamiento_m5":   Vector2(-236, -182),   # carril del estacionamiento norte
	"lote_este":            Vector2(-386, 973),    # lote de estacionamiento sur
	"parada_rectorado":     Vector2(434, 676),    # camino principal al sur de la Plazoleta
	"porton_vehicular":     Vector2(-316, 748),   # portón con barrera de la entrada oeste
	"zona_mantenimiento":   Vector2(1869, 523),   # patio de servicios, al este del edificio este
	"rectorado":            Vector2(684, 262),    # frente al Rectorado (Consejo Universitario)
}


static func existe(lugar: String) -> bool:
	return LUGARES.has(lugar)


static func posicion(lugar: String, desplazamiento: Vector2 = Vector2.ZERO) -> Vector2:
	if not LUGARES.has(lugar):
		push_error("lugares_campus: lugar desconocido '%s'" % lugar)
		return Vector2.ZERO
	return LUGARES[lugar] + desplazamiento
