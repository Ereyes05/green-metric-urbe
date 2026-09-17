# Prueba de los cambios visibles del Plan de Movilidad (spec §12): qué se
# dibuja y dónde, sin comparar píxeles.
# Correr: $GODOT --headless --path . res://tests/test_cambios_movilidad.tscn
extends Node

const CAMBIOS := preload("res://scenes/mapa/cambios_movilidad.gd")
const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")
const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")

const MEJOR := {
	"tr_permisos": "permiso_por_necesidad", "tr_lote": "ciclovia_arborizada",
	"tr_carpool": "puestos_3_ocupantes", "tr_shuttle": "ruta_a_paradas",
	"tr_dia_sin_carros": "jornada_mensual_con_feria", "tr_flota": "carritos_electricos",
	"tr_bici_bloque_e": "techado_con_panel", "tr_bici_cafetin": "techado_con_panel",
}

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _nombres(elementos: Array) -> Array:
	var out := []
	for e in elementos:
		out.append(e["elemento"])
	return out


func _lugares_validos(c: Node2D) -> void:
	for e in c.elementos():
		_check(LUGARES.existe(e["lugar"]) and CAMBIOS.DESPLAZAMIENTO.has(e["elemento"]),
			"%s en %s con desplazamiento" % [e["elemento"], e["lugar"]])


func _ready() -> void:
	print("test_cambios_movilidad")
	var c : Node2D = CAMBIOS.new()
	add_child(c)
	var e := _nombres(c.elementos())
	_check(e.has("lote_vacio") and e.has("autos_m5") and e.size() == 2, "sin plan: lote vacío y autos")
	_check(c.autos_en_m5() == 8, "sin plan: 8 autos")
	_lugares_validos(c)

	var p = PLAN.new()
	for id in MEJOR.keys():
		p.aplicar_valida(id, MEJOR[id])
	c.actualizar(p)
	e = _nombres(c.elementos())
	for n in ["ciclovia", "senal_carpool", "cartel_permisos", "buseta", "cartel_dia_sin_carros", "carrito_electrico"]:
		_check(e.has(n), "plan de 5,00 dibuja %s" % n)
	_check(e.count("bicicletero_techado") == 2 and not e.has("lote_vacio"), "dos bicicleteros techados, lote transformado")
	_check(c.autos_en_m5() == 1, "8 - 3 - 2 - 2 = 1 auto")
	_lugares_validos(c)

	var q = PLAN.new()
	for par in [["tr_permisos", "lectoras_de_placas"], ["tr_carpool", "app_carpool"], ["tr_shuttle", "park_and_ride"],
			["tr_lote", "plaza_de_eventos"], ["tr_bici_bloque_e", "simple_con_candado"], ["tr_bici_cafetin", "simple_con_candado"]]:
		_check(q.aplicar_valida(par[0], par[1]), "aplica %s" % par[1])
	c.actualizar(q)
	e = _nombres(c.elementos())
	_check(e.has("barrera_placas") and e.has("cartel_app_carpool") and e.has("buseta") and e.has("plaza"), "otras válidas dibujan lo suyo")
	_check(e.count("bicicletero_simple") == 2, "dos bicicleteros simples")
	_check(c.autos_en_m5() == 5, "8 - 1 - 2 = 5 autos")
	_lugares_validos(c)

	var r = PLAN.new()
	r.aplicar_valida("tr_dia_sin_carros", "cierre_semanal")
	r.aplicar_valida("tr_flota", "triciclos_de_carga")
	c.actualizar(r)
	e = _nombres(c.elementos())
	_check(e.has("cartel_viernes_sin_carros") and e.has("triciclos") and not e.has("buseta"), "viernes sin carros y triciclos")
	_lugares_validos(c)

	await get_tree().process_frame
	await get_tree().process_frame
	_check(is_instance_valid(c), "dibuja dos frames sin detenerse")

	print("test_cambios_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
