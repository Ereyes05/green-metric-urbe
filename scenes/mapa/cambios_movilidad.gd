# ============================================================
# cambios_movilidad.gd — NIVEL 5: lo que el Plan de Movilidad cambia en el
# mapa (spec §12), dibujado con _draw en el mismo estilo procedural que
# mapa_campus.gd. Todo anclado a lugares con nombre (lugares_campus.gd) +
# DESPLAZAMIENTO, para no tapar los puntos. Se redibuja solo al cambiar el
# plan. La lista de elementos (elementos()) se prueba sin dibujar.
# ============================================================
extends Node2D

const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")
const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

const AUTOS_BASE := 8
const REDUCCION_AUTOS : Dictionary = {
	"permiso_por_necesidad": 3, "puestos_3_ocupantes": 2, "app_carpool": 1,
	"ruta_a_paradas": 2, "park_and_ride": 2,
}
# Dónde se dibuja cada elemento respecto de su lugar. Ajustar con el mapa nuevo.
const DESPLAZAMIENTO : Dictionary = {
	"autos_m5": Vector2(-40, -62),
	"senal_carpool": Vector2(48, -30),
	"cartel_app_carpool": Vector2(48, -30),
	"cartel_permisos": Vector2(0, -52),
	"barrera_placas": Vector2(0, -52),
	"lote_vacio": Vector2(0, 0),
	"ciclovia": Vector2(0, 0),
	"plaza": Vector2(0, 0),
	"buseta": Vector2(-70, -18),
	"cartel_dia_sin_carros": Vector2(70, -30),
	"cartel_viernes_sin_carros": Vector2(70, -30),
	"carrito_electrico": Vector2(0, -50),
	"triciclos": Vector2(0, -50),
	"bicicletero_techado": Vector2(-46, 4),
	"bicicletero_simple": Vector2(-46, 4),
}
const ELEMENTO_POR_OPCION : Dictionary = {
	"ciclovia_arborizada": "ciclovia", "plaza_de_eventos": "plaza",
	"puestos_3_ocupantes": "senal_carpool", "app_carpool": "cartel_app_carpool",
	"permiso_por_necesidad": "cartel_permisos", "lectoras_de_placas": "barrera_placas",
	"ruta_a_paradas": "buseta", "park_and_ride": "buseta",
	"jornada_mensual_con_feria": "cartel_dia_sin_carros", "cierre_semanal": "cartel_viernes_sin_carros",
	"carritos_electricos": "carrito_electrico", "triciclos_de_carga": "triciclos",
	"techado_con_panel": "bicicletero_techado", "simple_con_candado": "bicicletero_simple",
}

var _elecciones : Dictionary = {}   # decision_id -> opcion_id


func actualizar(plan) -> void:
	_elecciones = {}
	for id in DATOS.ids_decisiones():
		var op : String = plan.opcion_actual(id)
		if op != "":
			_elecciones[id] = op
	queue_redraw()


func autos_en_m5() -> int:
	var n := AUTOS_BASE
	for op in _elecciones.values():
		n -= int(REDUCCION_AUTOS.get(op, 0))
	return maxi(1, n)


func elementos() -> Array:
	var out : Array = [{"elemento": "autos_m5", "lugar": "estacionamiento_m5"}]
	if not _elecciones.has("tr_lote"):
		out.append({"elemento": "lote_vacio", "lugar": "lote_este"})
	for id in DATOS.ids_decisiones():
		if not _elecciones.has(id):
			continue
		var elemento := str(ELEMENTO_POR_OPCION.get(_elecciones[id], ""))
		if elemento != "":
			out.append({"elemento": elemento, "lugar": DATOS.decision(id)["lugar"]})
	return out


func _draw() -> void:
	var fuente := TEMA.rubik(700)
	for e in elementos():
		var pos := LUGARES.posicion(e["lugar"], DESPLAZAMIENTO.get(e["elemento"], Vector2.ZERO))
		match e["elemento"]:
			"autos_m5": _autos(pos)
			"lote_vacio": _lote(pos, false)
			"plaza": _lote(pos, true)
			"ciclovia": _ciclovia(pos)
			"senal_carpool": _cartel(pos, "3+", TEMA.VERDE, fuente)
			"cartel_app_carpool": _cartel(pos, "CARPOOL", TEMA.CIAN, fuente)
			"cartel_permisos": _cartel(pos, "PERMISOS", TEMA.DORADO, fuente)
			"barrera_placas": _barrera(pos)
			"buseta": _buseta(pos)
			"cartel_dia_sin_carros": _cartel(pos, "DÍA SIN CARROS", TEMA.VIOLETA, fuente)
			"cartel_viernes_sin_carros": _cartel(pos, "VIERNES SIN CARROS", TEMA.VIOLETA, fuente)
			"carrito_electrico": _carrito(pos)
			"triciclos": _triciclos(pos)
			"bicicletero_techado": _bicicletero(pos, true)
			"bicicletero_simple": _bicicletero(pos, false)


func _autos(pos: Vector2) -> void:
	var colores := [Color(0.78, 0.22, 0.20), Color(0.20, 0.42, 0.78), Color(0.85, 0.85, 0.82), Color(0.25, 0.25, 0.28)]
	for i in autos_en_m5():
		var x := pos.x + float(i % 4) * 20.0
		var y := pos.y + float(floori(i / 4.0)) * 14.0
		draw_rect(Rect2(x, y, 16, 9), colores[i % colores.size()])
		draw_rect(Rect2(x + 4, y + 2, 8, 5), Color(0.55, 0.75, 0.90, 0.8))


func _lote(pos: Vector2, plaza: bool) -> void:
	var r := Rect2(pos - Vector2(56, 30), Vector2(112, 60))
	if plaza:
		draw_rect(r, Color(0.72, 0.66, 0.55))
		for esquina in [Vector2(-56, -30), Vector2(56, -30), Vector2(-56, 30), Vector2(56, 30)]:
			draw_circle(pos + esquina, 3.0, Color(0.30, 0.30, 0.32))
	else:
		draw_rect(r, Color(0.55, 0.47, 0.36))
		for i in range(1, 5):
			var x := r.position.x + float(i) * 22.4
			draw_line(Vector2(x, r.position.y + 4), Vector2(x, r.end.y - 4), Color(1, 1, 1, 0.25), 1.0)
	draw_rect(r, Color(0, 0, 0, 0.35), false, 1.5)


func _ciclovia(pos: Vector2) -> void:
	var r := Rect2(pos - Vector2(56, 30), Vector2(112, 60))
	draw_rect(r, Color(0.36, 0.62, 0.30))
	draw_rect(Rect2(r.position.x, pos.y - 7, r.size.x, 14), Color(0.30, 0.32, 0.36))
	var x := r.position.x + 4.0
	while x < r.end.x - 8.0:
		draw_line(Vector2(x, pos.y), Vector2(x + 8.0, pos.y), TEMA.VERDE, 2.0)
		x += 16.0
	for dx in [-40.0, 0.0, 40.0]:
		draw_circle(pos + Vector2(dx, -19), 9.0, Color(0.14, 0.38, 0.14))
		draw_circle(pos + Vector2(dx, 19), 9.0, Color(0.14, 0.38, 0.14))


func _cartel(pos: Vector2, texto: String, color: Color, fuente: Font) -> void:
	var tam := 9
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 10.0
	draw_line(pos + Vector2(0, 6), pos + Vector2(0, 22), Color(0.45, 0.45, 0.48), 2.0)
	var r := Rect2(pos.x - ancho * 0.5, pos.y - 8, ancho, 14)
	draw_rect(r, TEMA.PANEL_BG)
	draw_rect(r, color, false, 1.5)
	draw_string(fuente, Vector2(r.position.x + 5, pos.y + 3), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)


func _barrera(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 20, pos.y - 6, 8, 14), Color(0.35, 0.35, 0.38))
	draw_line(pos + Vector2(-12, -2), pos + Vector2(24, -2), Color(0.92, 0.25, 0.22), 3.0)
	draw_line(pos + Vector2(0, -2), pos + Vector2(8, -2), Color.WHITE, 3.0)
	draw_rect(Rect2(pos.x - 22, pos.y - 16, 10, 7), Color(0.15, 0.15, 0.18))
	draw_circle(pos + Vector2(-17, -12.5), 2.0, TEMA.CIAN)


func _buseta(pos: Vector2) -> void:
	var r := Rect2(pos - Vector2(24, 9), Vector2(48, 18))
	draw_rect(r, TEMA.VIOLETA)
	for i in 4:
		draw_rect(Rect2(r.position.x + 4 + i * 10, r.position.y + 3, 8, 6), Color(0.80, 0.92, 1.0))
	draw_circle(pos + Vector2(-14, 9), 4.0, Color(0.1, 0.1, 0.1))
	draw_circle(pos + Vector2(14, 9), 4.0, Color(0.1, 0.1, 0.1))
	draw_line(pos + Vector2(34, 10), pos + Vector2(34, -14), Color(0.45, 0.45, 0.48), 2.0)
	draw_rect(Rect2(pos.x + 28, pos.y - 20, 12, 8), TEMA.DORADO)


func _carrito(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 14, pos.y - 6, 28, 12), Color(0.90, 0.92, 0.94))
	draw_rect(Rect2(pos.x - 14, pos.y - 12, 16, 6), Color(0.70, 0.74, 0.78))
	draw_circle(pos + Vector2(-9, 7), 3.5, Color(0.1, 0.1, 0.1))
	draw_circle(pos + Vector2(9, 7), 3.5, Color(0.1, 0.1, 0.1))
	draw_polyline(PackedVector2Array([pos + Vector2(6, -5), pos + Vector2(2, 0), pos + Vector2(6, 0), pos + Vector2(2, 5)]), TEMA.DORADO, 2.0)


func _triciclos(pos: Vector2) -> void:
	for k in 3:
		var p := pos + Vector2(-22 + k * 22, 0)
		draw_arc(p + Vector2(-5, 4), 3.5, 0.0, TAU, 10, Color(0.1, 0.1, 0.1), 1.5)
		draw_arc(p + Vector2(5, 4), 3.5, 0.0, TAU, 10, Color(0.1, 0.1, 0.1), 1.5)
		draw_rect(Rect2(p.x - 7, p.y - 6, 10, 7), TEMA.NARANJA)
		draw_line(p + Vector2(3, -2), p + Vector2(7, -8), Color(0.3, 0.3, 0.3), 1.5)


func _bicicletero(pos: Vector2, techado: bool) -> void:
	for k in 3:
		draw_arc(pos + Vector2(-10 + k * 10, 4), 4.5, PI, TAU, 8, Color(0.62, 0.64, 0.68), 2.0)
	if techado:
		draw_rect(Rect2(pos.x - 18, pos.y - 12, 36, 4), Color(0.40, 0.42, 0.45))
		draw_rect(Rect2(pos.x - 8, pos.y - 17, 16, 5), Color(0.15, 0.30, 0.62))
		draw_circle(pos + Vector2(16, -6), 2.5, TEMA.DORADO)
