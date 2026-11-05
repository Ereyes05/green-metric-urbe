# ============================================================
# punto_comite_ambiental.gd — NIVEL 6: Educación e Investigación
# Punto interactivo (Zona Cultural) que abre mision_comite_ambiental.gd
# (reclutamiento de 5 estudiantes con argumentos basados en datos
# reales de lo que el jugador ya logró en Niveles 1-5).
# ============================================================
extends Area2D

@export var mision_id    : String = "comite_ambiental"
@export var nombre_punto : String = "Mesa del Comité Ambiental"

signal comite_solicitado(punto: Area2D)

const AJUSTE := preload("res://scenes/ui/ui_ajuste.gd")
const RADIO_DETEC : float = 55.0
const TOTAL_ESTUDIANTES : int = 5

var _jugador_cerca : bool = false
var _completado    : bool = false

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null


class ComiteIcon extends Node2D:
	var completado  : bool  = false
	var convencidos : int   = 0
	var _t          : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2(0, 12), 16.0, 0.0, PI, 16, Color(0.0, 0.0, 0.0, 0.22), 10.0)
		var glow_a := 0.10 + 0.08 * sin(_t * 2.0)
		draw_circle(Vector2(0, 0), 30.0, Color(0.95, 0.65, 0.15, glow_a))
		# Mesa
		var col_mesa : Color = Color(0.55, 0.38, 0.18) if not completado else Color(0.18, 0.85, 0.35)
		draw_rect(Rect2(-16, 2, 32, 6), col_mesa)
		draw_rect(Rect2(-16, 2, 32, 6), col_mesa.darkened(0.35), false, 1.5)
		# Siluetas de estudiantes alrededor (llenas = convencidos)
		for i in TOTAL_ESTUDIANTES:
			var ang := -PI * 0.75 + (float(i) / float(TOTAL_ESTUDIANTES - 1)) * PI * 1.5
			var px := cos(ang) * 20.0
			var py := sin(ang) * 10.0 - 6.0
			var ganado : bool = i < convencidos
			var col : Color = Color(0.30, 0.85, 0.40) if ganado else Color(0.45, 0.42, 0.50)
			draw_circle(Vector2(px, py), 3.2, col)
			draw_rect(Rect2(px - 2.4, py + 2.5, 4.8, 6.0), col)
		if completado:
			draw_line(Vector2(-6, 3), Vector2(-1, 9), Color.WHITE, 2.2)
			draw_line(Vector2(-1, 9), Vector2(8, -6), Color.WHITE, 2.2)


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("punto_comite_ambiental")
	_crear_collision()
	_crear_visual()
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var nm = _nivel_mgr()
	if nm and nm.mision_completada_q(6, mision_id):
		_marcar_completado()
	elif nm:
		var det : Dictionary = nm.obtener_detalle(mision_id)
		var conv : Array = det.get("convencidos", [])
		_actualizar_contador(conv.size())


func _crear_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIO_DETEC
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _crear_visual() -> void:
	var icon := ComiteIcon.new()
	icon.z_index = 1
	add_child(icon)
	set_meta("comite_icon", icon)


func _actualizar_contador(n: int) -> void:
	var icon = get_meta("comite_icon", null)
	if icon and is_instance_valid(icon):
		icon.convencidos = n


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(320, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.10, 0.06, 0.02, 0.93)
	ps.border_color = Color(0.90, 0.62, 0.15)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.45, 0.28, 0.05, 0.40)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 13)
	_prompt_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.70))
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
		_prompt_lbl.text = "✅ Comité Ambiental formado — %s" % nombre_punto
	else:
		var icon = get_meta("comite_icon", null)
		var n : int = icon.convencidos if icon and is_instance_valid(icon) else 0
		_prompt_lbl.text = "🗣 [E] Reclutar comité (%d/%d) — %s" % [n, TOTAL_ESTUDIANTES, nombre_punto]


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
	comite_solicitado.emit(self)


func _marcar_completado() -> void:
	_completado = true
	var icon = get_meta("comite_icon", null)
	if icon and is_instance_valid(icon):
		icon.completado   = true
		icon.convencidos  = TOTAL_ESTUDIANTES
		icon.modulate.a   = 0.5
