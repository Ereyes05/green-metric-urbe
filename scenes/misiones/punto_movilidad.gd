# ============================================================
# punto_movilidad.gd — NIVEL 5: punto del Plan de Movilidad en el mapa.
# Un solo script para la Oficina, las 6 decisiones, los 2 bicicleteros y el
# Consejo. Se ubica por LUGAR (scenes/mapa/lugares_campus.gd) +
# desplazamiento: nunca con coordenadas propias. El controlador
# (nivel5_movilidad.gd) le fija el estado y escucha interaccion_solicitada.
# ============================================================
extends Area2D

const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

signal interaccion_solicitada(punto: Area2D)

const RADIO_DETEC : float = 55.0

@export var mision_id : String = ""
@export var tipo : String = "decision"        # oficina | decision | bicicletero | consejo
@export var lugar : String = ""
@export var desplazamiento : Vector2 = Vector2.ZERO
@export var nombre_punto : String = ""

var estado : String = "pendiente"              # bloqueado | pendiente | resuelto
var _jugador_cerca : bool = false
var _icono : Icono = null
var _prompt_capa : CanvasLayer = null
var _prompt : PanelContainer = null
var _prompt_lbl : Label = null


# Ícono dibujado (mismo estilo procedural que mapa_campus.gd). Solo el
# estado "pendiente" redibuja cada frame, por rendimiento en la web.
class Icono extends Node2D:
	var tipo : String = "decision"
	var estado : String = "pendiente"
	var acento : Color = Color.WHITE
	var verde : Color = Color.WHITE
	var apagado : Color = Color.WHITE
	var _t : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var col : Color = apagado if estado == "bloqueado" else acento
		if estado == "pendiente":
			draw_circle(Vector2.ZERO, 26.0, Color(col, 0.14 + 0.08 * sin(_t * 2.2)))
		draw_circle(Vector2(0, 14), 12.0, Color(0, 0, 0, 0.22))
		match tipo:
			"oficina":
				draw_rect(Rect2(-14, -6, 28, 20), col.darkened(0.45))
				draw_rect(Rect2(-14, -6, 28, 20), col, false, 2.0)
				draw_colored_polygon(PackedVector2Array([Vector2(-18, -6), Vector2(18, -6), Vector2(0, -20)]), col)
			"consejo":
				draw_colored_polygon(PackedVector2Array([Vector2(-18, -8), Vector2(18, -8), Vector2(0, -20)]), col)
				for x in [-12.0, -2.0, 8.0]:
					draw_rect(Rect2(x, -6, 4, 18), col.lightened(0.2))
				draw_rect(Rect2(-18, 12, 36, 4), col.darkened(0.3))
			"bicicletero":
				draw_rect(Rect2(-16, -16, 32, 4), col)
				for x in [-9.0, 0.0, 9.0]:
					draw_arc(Vector2(x, 8), 5.0, PI, TAU, 10, col.lightened(0.3), 2.0)
			_:
				draw_line(Vector2(0, 14), Vector2(0, -8), col.darkened(0.2), 3.0)
				draw_rect(Rect2(-14, -22, 28, 14), col.darkened(0.45))
				draw_rect(Rect2(-14, -22, 28, 14), col, false, 2.0)
		if estado == "resuelto":
			draw_line(Vector2(8, -2), Vector2(12, 3), verde, 2.5)
			draw_line(Vector2(12, 3), Vector2(20, -8), verde, 2.5)


func _ready() -> void:
	add_to_group("punto_movilidad")
	position = LUGARES.posicion(lugar, desplazamiento)
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RADIO_DETEC
	forma.shape = circulo
	add_child(forma)
	_icono = Icono.new()
	_icono.tipo = tipo
	_icono.acento = TEMA.VIOLETA
	_icono.verde = TEMA.VERDE
	_icono.apagado = TEMA.APAGADO
	_icono.z_index = 1
	add_child(_icono)
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	set_estado(estado)


func _crear_prompt() -> void:
	_prompt_capa = CanvasLayer.new()
	_prompt_capa.layer = 12
	add_child(_prompt_capa)
	_prompt = PanelContainer.new()
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_theme_stylebox_override("panel", TEMA.caja(TEMA.PANEL_BG, TEMA.VIOLETA, 2, 10, 12, 6))
	_prompt_capa.add_child(_prompt)
	_prompt_lbl = TEMA.label("", 13, TEMA.TEXTO, 600)
	_prompt.add_child(_prompt_lbl)


func set_estado(nuevo: String) -> void:
	estado = nuevo
	if _prompt_lbl:
		_prompt_lbl.text = texto_prompt()
	if _icono:
		_icono.estado = nuevo
		_icono.set_process(nuevo == "pendiente")
		_icono.queue_redraw()


func texto_prompt() -> String:
	if estado == "bloqueado":
		if tipo == "consejo":
			return "🔒 El Consejo recibe el plan con las 8 decisiones listas"
		return "🔒 Primero pasa por la Oficina de Movilidad"
	var pendiente := estado == "pendiente"
	match tipo:
		"oficina":
			return "E · Oficina de Movilidad" if pendiente else "E · Ver el Plan de Movilidad"
		"consejo":
			return "E · Presentar el plan al Consejo" if pendiente else "E · Ver resultado del Consejo"
		"bicicletero":
			return ("E · Instalar bicicletero — %s" if pendiente else "E · Revisar bicicletero — %s") % nombre_punto
	return ("E · Decidir — %s" if pendiente else "E · Revisar decisión — %s") % nombre_punto


func _process(_delta: float) -> void:
	if _prompt == null or not _prompt.visible:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var origen := cam.get_screen_center_position() - vp * 0.5 / cam.zoom
	var pantalla := (global_position + Vector2(0, -44) - origen) * cam.zoom
	_prompt.reset_size()
	_prompt.position = pantalla - Vector2(_prompt.size.x * 0.5, _prompt.size.y)


func _al_entrar(body: Node) -> void:
	if not body.is_in_group("jugador"):
		return
	_jugador_cerca = true
	_prompt_lbl.text = texto_prompt()
	_prompt.visible = true


func _al_salir(body: Node) -> void:
	if not body.is_in_group("jugador"):
		return
	_jugador_cerca = false
	_prompt.visible = false


func intentar_interactuar() -> void:
	if not _jugador_cerca or estado == "bloqueado":
		return
	_prompt.visible = false
	interaccion_solicitada.emit(self)
