# ============================================================
# punto_semana_verde.gd — NIVEL 6: Educación e Investigación
# Punto interactivo (Auditorio) que abre mision_semana_verde.gd
# (organización del evento "Semana Verde URBE", ED4).
# ============================================================
extends Area2D

# Los íconos se redibujan a ~12 Hz, no en cada cuadro (ver redibujo.gd).
const Redibujo := preload("res://scenes/mapa/redibujo.gd")

@export var mision_id    : String = "semana_verde"
@export var nombre_punto : String = "Auditorio — Semana Verde URBE"

signal semana_verde_solicitada(punto: Area2D)

const AJUSTE := preload("res://scenes/ui/ui_ajuste.gd")
const RADIO_DETEC : float = 55.0

var _jugador_cerca : bool = false
var _completado    : bool = false

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null


class EventoIcon extends Node2D:
	var completado : bool  = false
	var _t          : float = 0.0

	var _redibujo : float = randf() * Redibujo.CADA   # fase al azar: no todos en el mismo cuadro

	func _process(delta: float) -> void:
		_t += delta
		_redibujo -= delta
		if _redibujo <= 0.0:
			_redibujo = Redibujo.CADA
			queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2(0, 12), 16.0, 0.0, PI, 16, Color(0.0, 0.0, 0.0, 0.22), 10.0)
		var glow_a := 0.10 + 0.08 * sin(_t * 2.0)
		draw_circle(Vector2(0, 0), 30.0, Color(0.95, 0.28, 0.55, glow_a))
		# Escenario / carpa de evento
		var col_base : Color = Color(0.78, 0.20, 0.48) if not completado else Color(0.18, 0.85, 0.35)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-20, 6), Vector2(20, 6), Vector2(14, -14), Vector2(-14, -14)
		]), col_base)
		draw_rect(Rect2(-16, 6, 32, 4), col_base.darkened(0.35))
		# Banderines
		for i in 4:
			var bx := -15.0 + float(i) * 10.0
			var by := -14.0 - sin(_t * 3.0 + float(i)) * 2.0
			draw_circle(Vector2(bx, by), 2.0, Color(1.0, 0.85, 0.20))
		if completado:
			draw_line(Vector2(-6, -2), Vector2(-1, 4), Color.WHITE, 2.2)
			draw_line(Vector2(-1, 4), Vector2(8, -8), Color.WHITE, 2.2)


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("punto_semana_verde")
	_crear_collision()
	_crear_visual()
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var nm = _nivel_mgr()
	if nm and nm.mision_completada_q(6, mision_id):
		_marcar_completado()


func _crear_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIO_DETEC
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _crear_visual() -> void:
	var icon := EventoIcon.new()
	icon.z_index = 1
	add_child(icon)
	set_meta("evento_icon", icon)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(320, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.10, 0.03, 0.06, 0.93)
	ps.border_color = Color(0.90, 0.28, 0.55)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.45, 0.08, 0.25, 0.40)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 13)
	_prompt_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.90))
	_prompt_panel.add_child(_prompt_lbl)


func _process(_delta: float) -> void:
	if _jugador_cerca:
		_actualizar_prompt_texto()
	if not _prompt_panel.visible: return
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var gp := global_position + Vector2(-160, -90)
	var vp_size   := get_viewport().get_visible_rect().size
	var cam_zoom  := cam.zoom
	var cam_off   := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (gp - cam_off) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	AJUSTE.colocar_aviso(_prompt_panel, _prompt_lbl, screen_pos)


func _actualizar_prompt_texto() -> void:
	if _completado:
		_prompt_lbl.text = "✅ Semana Verde URBE organizada — %s" % nombre_punto
	else:
		_prompt_lbl.text = "🎪 [E] Organizar la Semana Verde — %s" % nombre_punto


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
	semana_verde_solicitada.emit(self)


func _marcar_completado() -> void:
	_completado = true
	var icon = get_meta("evento_icon", null)
	if icon and is_instance_valid(icon):
		icon.completado = true
		icon.modulate.a = 0.5
