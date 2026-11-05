# ============================================================
# punto_captacion.gd — NIVEL 4: Uso del Agua
# Punto interactivo en el mapa que abre mision_captacion.gd
# (instalación de sistema de captación de agua de lluvia).
# ============================================================
extends Area2D

@export var mision_id     : String = "captacion_1"
@export var nombre_punto  : String = "Techo del Rectorado"
@export var indice_mision : int    = 0

signal captacion_solicitada(punto: Area2D)

const AJUSTE := preload("res://scenes/ui/ui_ajuste.gd")
const RADIO_DETEC : float = 55.0

var _jugador_cerca : bool  = false
var _completado    : bool  = false

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null


# ── Inner class: icono visual en el mapa ─────────────────────
class CisternIcon extends Node2D:
	var completado : bool  = false
	var _t          : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		# Sombra
		draw_arc(Vector2(0, 12), 14.0, 0.0, PI, 16, Color(0.0, 0.0, 0.0, 0.22), 10.0)
		# Halo pulsante celeste
		var glow_a := 0.10 + 0.08 * sin(_t * 2.2)
		draw_circle(Vector2(0, 0), 28.0, Color(0.20, 0.60, 0.95, glow_a))
		# Canaleta sobre el techo
		draw_rect(Rect2(-20, -22, 40, 4), Color(0.55, 0.56, 0.60))
		# Tubería bajante
		draw_rect(Rect2(-2, -18, 4, 16), Color(0.50, 0.52, 0.56))
		# Cisterna / tanque
		var col_tanque : Color = Color(0.15, 0.55, 0.85) if not completado else Color(0.18, 0.85, 0.35)
		draw_rect(Rect2(-13, -2, 26, 22), col_tanque)
		draw_rect(Rect2(-13, -2, 26, 22), col_tanque.darkened(0.35), false, 2.0)
		draw_rect(Rect2(-13, -2, 26, 4), col_tanque.lightened(0.25))
		if completado:
			draw_line(Vector2(-5, 9), Vector2(-1, 14), Color.WHITE, 2.2)
			draw_line(Vector2(-1, 14), Vector2(7, 3), Color.WHITE, 2.2)
		else:
			# Gotas cayendo de la canaleta hacia el tanque
			var ciclo : float = fmod(_t * 1.3, 1.0)
			var drop_y : float = -18.0 + ciclo * 16.0
			draw_circle(Vector2(0, drop_y), 1.6, Color(0.35, 0.75, 1.0, 1.0 - ciclo))


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("punto_captacion")
	_crear_collision()
	_crear_visual()
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var nm = _nivel_mgr()
	if nm and nm.mision_completada_q(4, mision_id):
		_marcar_completado()


func _crear_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIO_DETEC
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _crear_visual() -> void:
	var icon := CisternIcon.new()
	icon.z_index = 1
	add_child(icon)
	set_meta("cistern_icon", icon)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(300, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.03, 0.07, 0.10, 0.93)
	ps.border_color = Color(0.20, 0.60, 0.92)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.05, 0.30, 0.50, 0.40)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 13)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.80, 0.92, 1.0))
	_prompt_panel.add_child(_prompt_lbl)


func _process(_delta: float) -> void:
	if _jugador_cerca:
		_actualizar_prompt_texto()
	if not _prompt_panel.visible: return
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var gp := global_position + Vector2(-150, -90)
	var vp_size   := get_viewport().get_visible_rect().size
	var cam_zoom  := cam.zoom
	var cam_off   := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (gp - cam_off) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	AJUSTE.colocar_aviso(_prompt_panel, _prompt_lbl, screen_pos)


func _actualizar_prompt_texto() -> void:
	if _completado:
		_prompt_lbl.text = "✅ Captación instalada — %s" % nombre_punto
	else:
		_prompt_lbl.text = "🌧 [E] Instalar captación de lluvia — %s" % nombre_punto


func _al_entrar(body: Node) -> void:
	if not body.is_in_group("jugador"): return
	_jugador_cerca = true
	_actualizar_prompt_texto()
	_prompt_panel.modulate.a = 0.0
	_prompt_panel.visible    = true
	var tw := create_tween()
	tw.tween_property(_prompt_panel, "modulate:a", 1.0, 0.20)


func _al_salir(body: Node) -> void:
	if not body.is_in_group("jugador"): return
	_jugador_cerca = false
	var tw := create_tween()
	tw.tween_property(_prompt_panel, "modulate:a", 0.0, 0.16)
	tw.tween_callback(func(): _prompt_panel.visible = false)


func intentar_interactuar() -> void:
	if not _jugador_cerca or _completado: return
	_prompt_panel.visible = false
	captacion_solicitada.emit(self)


func _marcar_completado() -> void:
	_completado = true
	var icon = get_meta("cistern_icon", null)
	if icon and is_instance_valid(icon):
		icon.completado = true
		icon.modulate.a = 0.5
