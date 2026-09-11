# ============================================================
# llave_agua.gd — NIVEL 4: Uso del Agua
# Llave abierta interactiva en el mapa: gotea y desperdicia agua
# hasta que el jugador la cierra. Misión de reacción rápida,
# análoga a contenedor_basura.gd pero cuenta para NivelManager.
# ============================================================
extends Area2D

@export var mision_id    : String = "llave_1"
@export var nombre_llave : String = "Llave del Baño"

signal llave_cerrada(mision_id: String, xp: int, ec: int)

const RADIO_DETEC  : float = 48.0
const TASA_FUGA     : float = 0.0032   # 0→100% en ~5 min
const TIEMPO_CIERRE : float = 0.8      # duración de la animación de cierre

var _jugador_cerca : bool  = false
var _completada    : bool  = false
var _cerrando      : bool  = false
var nivel_fuga      : float = 0.0      # 0.0 .. 1.0 — cuánto lleva goteando

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null
var _visual_node   : Node2D      = null


# ── Visual de la llave ────────────────────────────────────────
class FaucetVisual extends Node2D:
	var fuga       : float = 0.0
	var completada : bool  = false
	var cerrando   : bool  = false
	var _t         : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		_draw_soporte()
		_draw_grifo()
		if completada:
			_draw_cerrada()
		else:
			_draw_goteo()
			_draw_charco()

	func _draw_soporte() -> void:
		# Placa de pared
		draw_rect(Rect2(-9, -22, 18, 8), Color(0.55, 0.56, 0.60))
		draw_rect(Rect2(-9, -22, 18, 8), Color(0.25, 0.25, 0.28), false, 1.0)

	func _draw_grifo() -> void:
		# Tubo vertical + caño
		draw_rect(Rect2(-2.5, -16, 5, 10), Color(0.68, 0.70, 0.74))
		draw_rect(Rect2(-2.5, -8, 14, 4), Color(0.68, 0.70, 0.74))
		# Manija — gira cuando se está cerrando
		var ang : float = 0.0
		if cerrando:
			ang = _t * 14.0   # giro rápido mientras se cierra
		var mp := Vector2(cos(ang), sin(ang)) * 5.0 + Vector2(0, -19)
		draw_line(Vector2(0, -19), mp, Color(0.85, 0.20, 0.15), 2.5)
		draw_circle(Vector2(0, -19), 2.0, Color(0.85, 0.20, 0.15))

	func _draw_goteo() -> void:
		# Gota cayendo del caño en bucle
		var ciclo : float = fmod(_t * 1.6, 1.0)
		var drop_y : float = -4.0 + ciclo * 18.0
		var alfa   : float = 1.0 - ciclo
		draw_circle(Vector2(11.5, drop_y), 1.6, Color(0.30, 0.65, 0.95, alfa))

	func _draw_charco() -> void:
		if fuga <= 0.02: return
		var r : float = 4.0 + fuga * 12.0
		var col : Color = Color(0.25, 0.60, 0.92, 0.35 + fuga * 0.35)
		if fuga >= 0.8:
			col = Color(0.90, 0.25, 0.20, 0.45 + fuga * 0.3)   # alerta roja: mucha agua perdida
		draw_circle(Vector2(11.5, 14), r * 0.5, col)
		draw_arc(Vector2(11.5, 14), r, 0.0, TAU, 20, col.lightened(0.2), 1.0)

	func _draw_cerrada() -> void:
		draw_circle(Vector2(0, 2), 9.0, Color(0.18, 0.85, 0.30, 0.85))
		draw_line(Vector2(-4, 2), Vector2(-1, 6), Color.WHITE, 2.2)
		draw_line(Vector2(-1, 6), Vector2(5, -3), Color.WHITE, 2.2)


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("llave_agua")
	nivel_fuga = randf_range(0.15, 0.45)
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
	_visual_node = FaucetVisual.new()
	_visual_node.z_index = 1
	add_child(_visual_node)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(280, 44)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.03, 0.07, 0.10, 0.93)
	ps.border_color = Color(0.20, 0.60, 0.92)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.05, 0.30, 0.50, 0.35)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 12)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.95))
	_prompt_panel.add_child(_prompt_lbl)


func _process(delta: float) -> void:
	if not _completada and not _cerrando:
		nivel_fuga = minf(nivel_fuga + TASA_FUGA * delta, 1.0)
		if is_instance_valid(_visual_node):
			(_visual_node as FaucetVisual).fuga = nivel_fuga

	if _jugador_cerca:
		_actualizar_prompt_texto()

	if not _prompt_panel.visible: return
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var gp := global_position + Vector2(-140, -80)
	var vp_size   := get_viewport().get_visible_rect().size
	var cam_zoom  := cam.zoom
	var cam_off   := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (gp - cam_off) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_prompt_panel.position = screen_pos


func _actualizar_prompt_texto() -> void:
	if _completada:
		_prompt_lbl.text = "✅ Llave cerrada — %s" % nombre_llave
	elif _cerrando:
		_prompt_lbl.text = "🔧 Cerrando llave..."
	else:
		# Litros perdidos: cifra ilustrativa de diseño, no una medición real.
		var litros : int = int(nivel_fuga * 30.0)
		_prompt_lbl.text = "💧 [E] Cerrar llave — %s (~%dL perdidos)" % [nombre_llave, litros]


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
	if not _jugador_cerca or _completada or _cerrando: return
	_iniciar_cierre()


func _iniciar_cierre() -> void:
	_cerrando = true
	_actualizar_prompt_texto()
	if is_instance_valid(_visual_node):
		(_visual_node as FaucetVisual).cerrando = true
	get_tree().create_timer(TIEMPO_CIERRE).timeout.connect(_completar_mision, CONNECT_ONE_SHOT)


func _completar_mision() -> void:
	_cerrando   = false
	_completada = true
	nivel_fuga  = 0.0
	if is_instance_valid(_visual_node):
		(_visual_node as FaucetVisual).cerrando   = false
		(_visual_node as FaucetVisual).completada = true
		(_visual_node as FaucetVisual).fuga       = 0.0
		_visual_node.modulate.a = 0.5
	_actualizar_prompt_texto()

	SupabaseManager.registrar_evento(4, mision_id, "mision_completada",
		{"nombre": nombre_llave})
	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(4, mision_id)
	var xp : int = int(nm.XP_POR_MISION.get(4, 35)) if nm else 35
	var ec : int = int(nm.EC_POR_MISION.get(4, 12)) if nm else 12
	llave_cerrada.emit(mision_id, xp, ec)


func _marcar_completado() -> void:
	_completada = true
	if is_instance_valid(_visual_node):
		(_visual_node as FaucetVisual).completada = true
		(_visual_node as FaucetVisual).fuga       = 0.0
		_visual_node.modulate.a = 0.5
