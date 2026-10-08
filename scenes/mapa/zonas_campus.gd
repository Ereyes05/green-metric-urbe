# ============================================================
# zonas_campus.gd - URBE Rangers: Eco-Quest
# Zonas de los NPCs sobre el mapa nuevo (urbe_removed (1).png).
# pos = CENTRO del area de zona (igual que el Area2D).
# La señal emite zona_key para lookup directo en SceneMapaMundo.
# ============================================================
extends Node2D

signal zona_activada(zona_key: String, modulo_id: int, nombre_modulo: String, color: Color)
signal zona_salida()

# ─────────────────────────────────────────────────────────────
# Mapa nuevo: cada zona está centrada en su NPC (10 px por encima de
# sus pies) y mide 150x130, apenas más que el radio de 60 px en el que
# el NPC responde a la E. Así el cartel del módulo aparece justo cuando
# ya se puede hablar, y ninguna zona se solapa con otra.
# pos = misma posición LOCAL que el NPC en DATOS_NPCS (SceneMapaMundo.gd).
# Las claves no cambian: las usan ZONA_A_MISION y escena_edificio.gd.
# ─────────────────────────────────────────────────────────────
const ZONAS : Dictionary = {
	"ZonaEstacionamiento": {   # Carlos
		"modulo_id": 5,
		"nombre":    "Transporte - Estacionamiento M5",
		"color":     Color(0.05, 0.27, 0.63),
		"pos":       Vector2(136, -86),
		"size":      Vector2(150, 130),
	},
	"ZonaCafetin": {   # Yulimar
		"modulo_id": 3,
		"nombre":    "Residuos - Canchas Deportivas",
		"color":     Color(0.80, 0.65, 0.00),
		"pos":       Vector2(587, 770),
		"size":      Vector2(150, 130),
	},
	"ZonaPatio": {   # Lic. Torres
		"modulo_id": 4,
		"nombre":    "Agua - Laguna URBE",
		"color":     Color(0.00, 0.42, 0.51),
		"pos":       Vector2(1249, 694),
		"size":      Vector2(150, 130),
	},
	"ZonaBloqueE": {   # Coord. Salinas
		"modulo_id": 2,
		"nombre":    "Energia - Bloque E",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(1074, 69),
		"size":      Vector2(150, 130),
	},
	"ZonaBloqueF": {   # Ing. Ramírez
		"modulo_id": 1,
		"nombre":    "Entorno - Bloque F",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(1074, 328),
		"size":      Vector2(150, 130),
	},
	"ZonaBloqueD": {   # Técn. Ruiz
		"modulo_id": 2,
		"nombre":    "Energia - Bloque D",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(1074, -122),
		"size":      Vector2(150, 130),
	},
	"ZonaBloqueA": {   # Prof. González
		"modulo_id": 2,
		"nombre":    "Energia - Bloque A",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(78, 53),
		"size":      Vector2(150, 130),
	},
	"ZonaBloqueB": {   # Dr. Pérez
		"modulo_id": 2,
		"nombre":    "Energia - Bloque B",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(78, 267),
		"size":      Vector2(150, 130),
	},
	"ZonaFotocopiado": {   # Sr. Blanco
		"modulo_id": 1,
		"nombre":    "Entorno - Bloque G (Fotocopiado)",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(1074, 505),
		"size":      Vector2(150, 130),
	},
	"ZonaBloqueC": {   # Ing. Herrera
		"modulo_id": 2,
		"nombre":    "Energia - Bloque C",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(78, 481),
		"size":      Vector2(150, 130),
	},
	"ZonaRectorado": {   # Rector Morales
		"modulo_id": 6,
		"nombre":    "Educacion e Investigacion - Rectorado",
		"color":     Color(0.27, 0.00, 0.56),
		"pos":       Vector2(536, 259),
		"size":      Vector2(150, 130),
	},
	"ZonaAreaServicios": {   # Dra. Luna
		"modulo_id": 6,
		"nombre":    "Educacion - Biblioteca",
		"color":     Color(0.27, 0.00, 0.56),
		"pos":       Vector2(624, -82),
		"size":      Vector2(150, 130),
	},
}


func _ready() -> void:
	for hijo in get_children():
		hijo.queue_free()
	await get_tree().process_frame
	_configurar_zonas()


func _configurar_zonas() -> void:
	for nombre_zona in ZONAS.keys():
		var datos : Dictionary = ZONAS[nombre_zona]
		var zona              := Area2D.new()
		zona.name              = nombre_zona
		zona.position          = datos["pos"]
		zona.collision_layer   = 0
		zona.collision_mask    = 1
		add_child(zona)
		var cs   := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = datos["size"]
		cs.shape  = rect
		zona.add_child(cs)
		zona.body_entered.connect(_on_zona_entrada.bind(nombre_zona))
		zona.body_exited.connect(_on_zona_salida_body.bind(nombre_zona))


func _on_zona_entrada(cuerpo: Node, nombre_zona: String) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	var d : Dictionary = ZONAS[nombre_zona]
	zona_activada.emit(nombre_zona, d["modulo_id"], d["nombre"], d["color"])


func _on_zona_salida_body(cuerpo: Node, _nombre_zona: String) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	zona_salida.emit()
