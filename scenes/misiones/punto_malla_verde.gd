# ============================================================
# punto_malla_verde.gd — NIVEL 6: Educación e Investigación
# Punto interactivo en el mapa (oficina del decanato) que abre
# mision_malla_verde.gd (asignación de cursos de sostenibilidad).
# ============================================================
extends Area2D

# Los íconos se redibujan a ~12 Hz, no en cada cuadro (ver redibujo.gd).
const Redibujo := preload("res://scenes/mapa/redibujo.gd")

@export var mision_id    : String = "malla_verde"
@export var nombre_punto : String = "Decanato — Rediseño Curricular"

signal malla_verde_solicitada(punto: Area2D)

const AJUSTE := preload("res://scenes/ui/ui_ajuste.gd")
const RADIO_DETEC : float = 55.0

var _jugador_cerca : bool = false
var _completado    : bool = false

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null


# ── Inner class: icono visual en el mapa ─────────────────────
class MallaIcon extends Node2D:
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
		draw_arc(Vector2(0, 12), 14.0, 0.0, PI, 16, Color(0.0, 0.0, 0.0, 0.22), 10.0)
		var glow_a := 0.10 + 0.08 * sin(_t * 2.2)
		draw_circle(Vector2(0, 0), 28.0, Color(0.55, 0.20, 0.85, glow_a))
		# Libro/malla curricular
		var col_base : Color = Color(0.42, 0.16, 0.68) if not completado else Color(0.18, 0.85, 0.35)
		draw_rect(Rect2(-15, -10, 30, 22), col_base)
		draw_rect(Rect2(-15, -10, 30, 22), col_base.darkened(0.35), false, 2.0)
		draw_line(Vector2(0, -10), Vector2(0, 12), col_base.darkened(0.4), 1.5)
		for i in 3:
			var ly := -4.0 + float(i) * 5.0
			draw_line(Vector2(-11, ly), Vector2(-2, ly), Color(0.90, 0.85, 0.95, 0.75), 1.2)
			draw_line(Vector2(2, ly), Vector2(11, ly), Color(0.90, 0.85, 0.95, 0.75), 1.2)
		if completado:
			draw_line(Vector2(-6, 3), Vector2(-1, 9), Color.WHITE, 2.2)
			draw_line(Vector2(-1, 9), Vector2(8, -6), Color.WHITE, 2.2)
		else:
			# birrete de graduación flotando encima
			var fy := -20.0 + sin(_t * 1.6) * 2.0
			draw_rect(Rect2(-9, fy, 18, 4), Color(0.10, 0.08, 0.10))
			draw_rect(Rect2(-2, fy + 4, 4, 4), Color(0.10, 0.08, 0.10))


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("punto_malla_verde")
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
	var icon := MallaIcon.new()
	icon.z_index = 1
	add_child(icon)
	set_meta("malla_icon", icon)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(320, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.08, 0.03, 0.10, 0.93)
	ps.border_color = Color(0.62, 0.24, 0.90)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.30, 0.05, 0.50, 0.40)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 13)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.90, 0.80, 1.0))
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
		_prompt_lbl.text = "✅ Malla curricular rediseñada — %s" % nombre_punto
	else:
		_prompt_lbl.text = "📚 [E] Rediseñar malla curricular — %s" % nombre_punto


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
	malla_verde_solicitada.emit(self)


func _marcar_completado() -> void:
	_completado = true
	var icon = get_meta("malla_icon", null)
	if icon and is_instance_valid(icon):
		icon.completado = true
		icon.modulate.a = 0.5
