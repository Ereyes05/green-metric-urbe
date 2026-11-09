# ============================================================
# punto_informe_final.gd — NIVEL 6: Educación e Investigación
# Punto interactivo (Rectorado, oficinas) que abre
# mision_informe_final.gd (ED7 — informe de sostenibilidad,
# cierre narrativo del juego). Requiere las otras 3 misiones de
# Nivel 6 completas: el informe sintetiza lo que ya se hizo, no
# tiene sentido antes de eso.
# ============================================================
extends Area2D

# Los íconos se redibujan a ~12 Hz, no en cada cuadro (ver redibujo.gd).
const Redibujo := preload("res://scenes/mapa/redibujo.gd")

@export var mision_id    : String = "informe_final"
@export var nombre_punto : String = "Decanato — Informe de Sostenibilidad"

const AJUSTE := preload("res://scenes/ui/ui_ajuste.gd")
const PREREQUISITOS : Array[String] = ["malla_verde", "comite_ambiental", "semana_verde"]

signal informe_solicitado(punto: Area2D)

const RADIO_DETEC : float = 55.0

var _jugador_cerca : bool = false
var _completado    : bool = false

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null


class InformeIcon extends Node2D:
	var completado : bool  = false
	var listo       : bool  = false
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
		var col_glow : Color = Color(0.90, 0.75, 0.15, glow_a) if listo else Color(0.35, 0.32, 0.40, glow_a)
		draw_circle(Vector2(0, 0), 28.0, col_glow)
		# Documento
		var col_doc : Color = Color(0.95, 0.92, 0.80) if not completado else Color(0.55, 0.95, 0.60)
		if not listo and not completado: col_doc = Color(0.45, 0.42, 0.48)
		draw_rect(Rect2(-11, -14, 22, 28), col_doc)
		draw_rect(Rect2(-11, -14, 22, 28), col_doc.darkened(0.3), false, 1.5)
		for i in 4:
			var ly := -8.0 + float(i) * 5.0
			draw_line(Vector2(-7, ly), Vector2(7, ly), col_doc.darkened(0.35), 1.2)
		if completado:
			draw_line(Vector2(-5, 2), Vector2(-1, 7), Color(0.10, 0.35, 0.15), 2.0)
			draw_line(Vector2(-1, 7), Vector2(6, -4), Color(0.10, 0.35, 0.15), 2.0)


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("punto_informe_final")
	_crear_collision()
	_crear_visual()
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var nm = _nivel_mgr()
	if nm and nm.mision_completada_q(6, mision_id):
		_marcar_completado()
	else:
		_actualizar_listo()


func _crear_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIO_DETEC
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _crear_visual() -> void:
	var icon := InformeIcon.new()
	icon.z_index = 1
	add_child(icon)
	set_meta("informe_icon", icon)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(340, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.10, 0.09, 0.03, 0.93)
	ps.border_color = Color(0.90, 0.75, 0.15)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.45, 0.38, 0.05, 0.40)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 12)
	_prompt_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
	_prompt_panel.add_child(_prompt_lbl)


func _process(_delta: float) -> void:
	if _jugador_cerca:
		_actualizar_prompt_texto()
	if not _prompt_panel.visible: return
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var gp := global_position + Vector2(-170, -90)
	var vp_size   := get_viewport().get_visible_rect().size
	var cam_zoom  := cam.zoom
	var cam_off   := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (gp - cam_off) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	AJUSTE.colocar_aviso(_prompt_panel, _prompt_lbl, screen_pos)


func _pendientes() -> Array[String]:
	var nm = _nivel_mgr()
	var faltan : Array[String] = []
	for pid in PREREQUISITOS:
		if not (nm and nm.mision_completada_q(6, pid)):
			faltan.append(pid)
	return faltan


func _actualizar_listo() -> void:
	var icon = get_meta("informe_icon", null)
	if icon and is_instance_valid(icon):
		icon.listo = _pendientes().is_empty()


func _actualizar_prompt_texto() -> void:
	if _completado:
		_prompt_lbl.text = "✅ Informe de Sostenibilidad publicado — %s" % nombre_punto
		return
	_actualizar_listo()
	var faltan := _pendientes()
	if faltan.is_empty():
		_prompt_lbl.text = "📄 [E] Publicar el informe de sostenibilidad — %s" % nombre_punto
	else:
		_prompt_lbl.text = "🔒 Faltan %d misión(es) de Nivel 6 para poder publicar el informe" % faltan.size()


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
	if not _pendientes().is_empty(): return
	_prompt_panel.visible = false
	informe_solicitado.emit(self)


func _marcar_completado() -> void:
	_completado = true
	var icon = get_meta("informe_icon", null)
	if icon and is_instance_valid(icon):
		icon.completado = true
		icon.listo      = true
		icon.modulate.a = 0.5
