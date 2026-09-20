# ============================================================
# npc.gd — URBE Rangers: Eco-Quest
# NPC con visual procedural moderno, burbuja animada,
# glow pulsante cuando el jugador se acerca.
# ============================================================
extends Area2D

@export var nombre_npc : String            = "NPC"
@export var mision_id  : String            = ""
@export var dialogos   : PackedStringArray = PackedStringArray(["Hola."])
@export var color      : Color             = Color(0.5, 0.5, 0.5)
@export var tipo_npc   : String            = "prof_h"


var _burbuja      : Control  = null
var _jugador_cerca: bool     = false
var _tween_bounce : Tween    = null
var _char_visual  : NpcChar  = null


# Brillo que aparece cuando el jugador se acerca. Se dibuja una vez con la
# transparencia máxima y NpcChar lo hace latir con modulate.a.
class GlowNpc extends Node2D:
	const ALFA_MAX : float = 0.14   # 0.09 + 0.05, el pico del latido original
	var col : Color = Color.WHITE

	func _draw() -> void:
		draw_circle(Vector2(0, -18), 20.0, Color(col.r, col.g, col.b, ALFA_MAX))


# ════════════════════════════════════════════════════════════
# INNER CLASS — personaje procedural con tipos:
# rector | prof_h | prof_m | est_h | est_m
# Escala 1.0 → más pequeños que el avatar (1.5×).
# ════════════════════════════════════════════════════════════
class NpcChar extends Node2D:
	var col     : Color  = Color(0.5, 0.5, 0.5)
	var tipo    : String = "prof_h"
	var glow_on : bool   = false:
		set(v):
			glow_on = v
			if _glow: _glow.visible = v
	var _t      : float  = 0.0
	var _glow   : GlowNpc = null

	# Rendimiento (medido 2026-09-14): antes _process() llamaba queue_redraw()
	# en cada frame y el personaje entero (cara, ojos, pelo con arcos, cuerpo)
	# se volvía a dibujar 60 veces por segundo solo para un balanceo de ±0,6 px
	# y el latido del brillo. Los 12 NPCs eran ~30-39% del tiempo de frame.
	#
	# Ahora el personaje se dibuja UNA vez y se animan cosas que no obligan a
	# redibujar: la posición (balanceo) y la transparencia del brillo, que va
	# en un nodo hijo aparte. Única diferencia visual: la sombra de los pies
	# acompaña el balanceo de 0,6 px (imperceptible).
	func _ready() -> void:
		_glow = GlowNpc.new()
		_glow.col = col
		_glow.show_behind_parent = true   # detrás del cuerpo, como antes
		_glow.visible = glow_on
		add_child(_glow)

	func _process(delta: float) -> void:
		_t += delta
		position.y = sin(_t * 1.6) * 0.6
		if glow_on:
			_glow.modulate.a = (0.09 + 0.05 * sin(_t * 2.5)) / GlowNpc.ALFA_MAX

	func _draw() -> void:
		var bob := 0.0   # el balanceo lo hace position.y en _process()

		draw_arc(Vector2(0, 1.5), 7.0, 0.0, PI, 14, Color(0, 0, 0, 0.24), 5.0)

		match tipo:
			"rector" : _draw_rector(bob)
			"prof_m" : _draw_prof_m(bob)
			"prof_h" : _draw_prof_h(bob)
			"est_h"  : _draw_est_h(bob)
			"est_m"  : _draw_est_m(bob)
			_        : _draw_prof_h(bob)

	# ── Helpers ───────────────────────────────────────────────
	func _sk() -> Color:
		return Color(0.83, 0.71, 0.59)

	func _hr() -> Color:
		var h := Color(col.r * 0.27, col.g * 0.21, col.b * 0.19).clamp()
		if h.get_luminance() < 0.025:
			h = Color(0.13, 0.09, 0.06)
		return h

	# Cabeza + ojos + cejas + boca; long_hair = pelo que cae a los lados
	func _draw_face(bob: float, hair_col: Color, long_hair: bool) -> void:
		var sk := _sk()
		var hp := Vector2(0, bob - 30)
		draw_circle(hp, 7.5, sk)
		draw_arc(hp, 7.5, 0.0, TAU, 20, sk.darkened(0.13), 1.0)
		if long_hair:
			draw_arc(hp, 7.5, PI * 0.55, PI * 2.45, 18, hair_col, 8.0)
			draw_rect(Rect2(-9.5, bob - 34, 2.5, 11.0), hair_col)
			draw_rect(Rect2(7.0,  bob - 34, 2.5, 11.0), hair_col)
		else:
			draw_arc(hp + Vector2(0, -1.5), 7.5, PI * 0.76, PI * 2.24, 16, hair_col, 8.5)
		var el := hp + Vector2(-2.4, -0.8)
		var er := hp + Vector2( 2.4, -0.8)
		draw_circle(el, 1.6, Color(0.95, 0.95, 0.95))
		draw_circle(er, 1.6, Color(0.95, 0.95, 0.95))
		draw_circle(el + Vector2(0.3,  0.2),  0.9,  Color(0.10, 0.07, 0.04))
		draw_circle(er + Vector2(0.3,  0.2),  0.9,  Color(0.10, 0.07, 0.04))
		draw_circle(el + Vector2(0.7, -0.35), 0.35, Color(1, 1, 1, 0.85))
		draw_circle(er + Vector2(0.7, -0.35), 0.35, Color(1, 1, 1, 0.85))
		draw_line(hp + Vector2(-4.5, -5.0), hp + Vector2(-1.2, -4.5), hair_col, 1.2)
		draw_line(hp + Vector2( 1.2, -4.5), hp + Vector2( 4.5, -5.0), hair_col, 1.2)
		draw_line(hp + Vector2(-2.0,  4.5), hp + Vector2( 2.0,  4.5),
				  Color(0.60, 0.46, 0.36, 0.88), 1.1)

	# ── Tipos ─────────────────────────────────────────────────
	func _draw_rector(bob: float) -> void:
		var sk   := _sk()
		var suit := Color(0.10, 0.10, 0.16)
		draw_rect(Rect2(-6, bob - 1, 5, 4), Color(0.08, 0.06, 0.04))
		draw_rect(Rect2(1,  bob - 1, 5, 4), Color(0.08, 0.06, 0.04))
		draw_rect(Rect2(-5, bob - 12, 10, 11), suit.lightened(0.07))
		draw_line(Vector2(0, bob - 12), Vector2(0, bob - 1), suit, 0.8)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-7, bob - 23), Vector2(7, bob - 23),
			Vector2(6,  bob - 12), Vector2(-6, bob - 12)
		]), suit)
		draw_rect(Rect2(-2, bob - 23, 4, 6), Color(0.93, 0.93, 0.93))
		draw_colored_polygon(PackedVector2Array([
			Vector2(-1, bob - 22), Vector2(1, bob - 22), Vector2(0.5, bob - 13)
		]), col.darkened(0.12))
		draw_colored_polygon(PackedVector2Array([
			Vector2(-7, bob - 23), Vector2(-1.5, bob - 18), Vector2(-6, bob - 13)
		]), suit.lightened(0.20))
		draw_colored_polygon(PackedVector2Array([
			Vector2(7,  bob - 23), Vector2(1.5, bob - 18), Vector2(6, bob - 13)
		]), suit.lightened(0.20))
		draw_circle(Vector2(-3.5, bob - 17), 2.5, Color(0.90, 0.80, 0.15))
		draw_rect(Rect2(-2, bob - 26, 4, 4), sk)
		_draw_face(bob, Color(0.68, 0.68, 0.73), false)

	func _draw_prof_h(bob: float) -> void:
		var sk     := _sk()
		var pants  := Color(col.r * 0.22, col.g * 0.22, col.b * 0.30 + 0.04).clamp()
		var jacket := col.darkened(0.18)
		draw_rect(Rect2(-6, bob - 1, 5, 4), Color(0.10, 0.08, 0.05))
		draw_rect(Rect2(1,  bob - 1, 5, 4), Color(0.10, 0.08, 0.05))
		draw_rect(Rect2(-5, bob - 12, 10, 11), pants)
		draw_line(Vector2(0, bob - 12), Vector2(0, bob - 1), pants.darkened(0.18), 0.7)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-7, bob - 23), Vector2(7, bob - 23),
			Vector2(6,  bob - 12), Vector2(-6, bob - 12)
		]), jacket)
		draw_rect(Rect2(-2, bob - 23, 4, 6), Color(0.93, 0.93, 0.93))
		draw_colored_polygon(PackedVector2Array([
			Vector2(-7, bob - 23), Vector2(-1.5, bob - 18), Vector2(-6, bob - 13)
		]), jacket.lightened(0.16))
		draw_colored_polygon(PackedVector2Array([
			Vector2(7,  bob - 23), Vector2(1.5, bob - 18), Vector2(6, bob - 13)
		]), jacket.lightened(0.16))
		draw_rect(Rect2(-5.5, bob - 19, 4.0, 3.0), Color(0.90, 0.90, 0.90, 0.92))
		draw_rect(Rect2(-5.5, bob - 19, 4.0, 3.0), col.lightened(0.28), false, 0.8)
		draw_rect(Rect2(-2, bob - 26, 4, 4), sk)
		_draw_face(bob, _hr(), false)

	func _draw_prof_m(bob: float) -> void:
		var sk     := _sk()
		var pants  := Color(col.r * 0.22, col.g * 0.22, col.b * 0.30 + 0.04).clamp()
		var blouse := col
		draw_rect(Rect2(-5, bob - 1, 4, 4), Color(0.52, 0.28, 0.26))
		draw_rect(Rect2(1,  bob - 1, 4, 4), Color(0.52, 0.28, 0.26))
		draw_rect(Rect2(-5, bob - 12, 10, 11), pants)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-6, bob - 23), Vector2(6, bob - 23),
			Vector2(6,  bob - 12), Vector2(-6, bob - 12)
		]), blouse.darkened(0.14))
		draw_rect(Rect2(-2, bob - 23, 4, 5), blouse.lightened(0.16))
		draw_rect(Rect2(-5.5, bob - 19, 4.0, 3.0), Color(0.90, 0.90, 0.90, 0.92))
		draw_rect(Rect2(-5.5, bob - 19, 4.0, 3.0), col.lightened(0.28), false, 0.8)
		draw_rect(Rect2(-2, bob - 26, 4, 4), sk)
		_draw_face(bob, _hr(), true)

	func _draw_est_h(bob: float) -> void:
		var sk     := _sk()
		var jeans  := Color(0.17, 0.24, 0.44)
		var tshirt := col.lightened(0.08)
		draw_rect(Rect2(-6, bob - 1, 5, 4), Color(0.84, 0.84, 0.87))
		draw_rect(Rect2(1,  bob - 1, 5, 4), Color(0.84, 0.84, 0.87))
		draw_rect(Rect2(-7, bob,     6, 1), Color(0.74, 0.74, 0.77))
		draw_rect(Rect2(1,  bob,     6, 1), Color(0.74, 0.74, 0.77))
		draw_rect(Rect2(-5, bob - 12, 10, 11), jeans)
		draw_line(Vector2(0, bob - 12), Vector2(0, bob - 1), jeans.darkened(0.16), 0.7)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-7, bob - 22), Vector2(7, bob - 22),
			Vector2(6,  bob - 12), Vector2(-6, bob - 12)
		]), tshirt)
		draw_rect(Rect2(6, bob - 21, 5, 9), col.darkened(0.28))
		draw_rect(Rect2(6, bob - 21, 5, 9), Color(0, 0, 0, 0.18), false, 0.7)
		draw_rect(Rect2(-2, bob - 26, 4, 5), sk)
		_draw_face(bob, _hr(), false)

	func _draw_est_m(bob: float) -> void:
		var sk      := _sk()
		var bottoms := Color(col.r * 0.34, col.g * 0.30, col.b * 0.46 + 0.08).clamp()
		var top     := col.lightened(0.10)
		draw_rect(Rect2(-5, bob - 1, 4, 4), Color(0.48, 0.26, 0.66))
		draw_rect(Rect2(1,  bob - 1, 4, 4), Color(0.48, 0.26, 0.66))
		draw_rect(Rect2(-4, bob - 12, 8, 11), bottoms)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-6, bob - 22), Vector2(6, bob - 22),
			Vector2(5,  bob - 12), Vector2(-5, bob - 12)
		]), top)
		draw_rect(Rect2(5, bob - 21, 5, 9), col.darkened(0.28))
		draw_rect(Rect2(5, bob - 21, 5, 9), Color(0, 0, 0, 0.18), false, 0.7)
		draw_rect(Rect2(-2, bob - 26, 4, 5), sk)
		_draw_face(bob, _hr(), true)


# ════════════════════════════════════════════════════════════
# READY
# ════════════════════════════════════════════════════════════
func _ready() -> void:
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	_ocultar_sprite_placeholder()
	_crear_char_visual()
	_crear_burbuja()


func _ocultar_sprite_placeholder() -> void:
	var vis : Node = get_node_or_null("Visual")
	if vis:
		vis.visible = false


func _crear_char_visual() -> void:
	_char_visual       = NpcChar.new()
	_char_visual.col   = color
	_char_visual.tipo  = tipo_npc
	_char_visual.scale = Vector2(1.0, 1.0)
	add_child(_char_visual)


# ════════════════════════════════════════════════════════════
# BURBUJA DE NOMBRE
# ════════════════════════════════════════════════════════════
func _crear_burbuja() -> void:
	_burbuja = Control.new()
	_burbuja.custom_minimum_size = Vector2(0, 40)
	_burbuja.visible = false
	add_child(_burbuja)

	# Panel de la burbuja
	var fondo := Panel.new()
	fondo.name = "Fondo"
	var sb := StyleBoxFlat.new()
	sb.bg_color     = color.darkened(0.35)
	sb.bg_color.a   = 0.92
	sb.border_color = color.lightened(0.20)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color  = Color(0, 0, 0, 0.45)
	sb.shadow_size   = 5
	sb.shadow_offset = Vector2(0, 2)
	sb.content_margin_left   = 8
	sb.content_margin_right  = 8
	sb.content_margin_top    = 4
	sb.content_margin_bottom = 4
	fondo.add_theme_stylebox_override("panel", sb)
	_burbuja.add_child(fondo)

	# Etiqueta del nombre
	var nombre_lbl := Label.new()
	nombre_lbl.name = "Nombre"
	nombre_lbl.text = nombre_npc
	nombre_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre_lbl.add_theme_font_size_override("font_size", 11)
	nombre_lbl.add_theme_color_override("font_color", Color.WHITE)
	fondo.add_child(nombre_lbl)

	await get_tree().process_frame
	if not is_instance_valid(nombre_lbl): return

	var ancho : float = max(nombre_lbl.size.x + 18.0, 60.0)
	var alto  : float = 26.0

	# NpcChar escala 1.0: cabeza en y=-30, radio=7.5, tope≈-37.5 → borde inferior a -44
	fondo.position = Vector2(-ancho * 0.5, -alto - 44.0)
	fondo.size     = Vector2(ancho, alto)

	# Punto indicador pulsante bajo la burbuja
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.position            = Vector2(ancho * 0.5 - 4.0, alto - 1.0)
	var ds := StyleBoxFlat.new()
	ds.bg_color = color.lightened(0.28)
	ds.set_corner_radius_all(4)
	dot.add_theme_stylebox_override("panel", ds)
	fondo.add_child(dot)
	var tw_dot := dot.create_tween().set_loops()
	tw_dot.tween_property(dot, "modulate:a", 0.22, 0.55)
	tw_dot.tween_property(dot, "modulate:a", 1.0,  0.55)

	_iniciar_bounce()


func _iniciar_bounce() -> void:
	if not is_instance_valid(_burbuja): return
	if _tween_bounce: _tween_bounce.kill()
	_tween_bounce = create_tween().set_loops()
	_tween_bounce.tween_property(_burbuja, "position:y", -6.0, 0.42).set_ease(Tween.EASE_IN_OUT)
	_tween_bounce.tween_property(_burbuja, "position:y", -2.0, 0.42).set_ease(Tween.EASE_IN_OUT)


# ════════════════════════════════════════════════════════════
# EVENTOS DE COLISIÓN
# ════════════════════════════════════════════════════════════
func _al_entrar(body: Node) -> void:
	if body.is_in_group("jugador"):
		body.npc_cercano = self
		_jugador_cerca   = true

		if is_instance_valid(_char_visual):
			_char_visual.glow_on = true

		# Pista contextual: primera vez que el jugador se acerca a un NPC
		var hb = get_tree().get_first_node_in_group("hint_bubble")
		if hb:
			hb.push("primer_npc", "💬 ¡Presiona [E] para hablar con el NPC!")

		if is_instance_valid(_burbuja):
			_burbuja.modulate.a = 0.0
			_burbuja.visible    = true
			var tw := create_tween()
			tw.tween_property(_burbuja, "modulate:a", 1.0, 0.22)
			tw.parallel().tween_property(_burbuja, "scale",
										 Vector2(1.0, 1.0), 0.22).from(Vector2(0.5, 0.5))


func _al_salir(body: Node) -> void:
	if body.is_in_group("jugador") and body.npc_cercano == self:
		body.npc_cercano = null
		_jugador_cerca   = false

		if is_instance_valid(_char_visual):
			_char_visual.glow_on = false

		if is_instance_valid(_burbuja):
			var tw := create_tween()
			tw.tween_property(_burbuja, "modulate:a", 0.0, 0.18)
			tw.tween_callback(func(): _burbuja.visible = false)


func iniciar_dialogo() -> void:
	if is_instance_valid(_burbuja):
		_burbuja.visible = false
	var ui = get_tree().get_first_node_in_group("ui_dialogo")
	if ui:
		ui.iniciar(nombre_npc, dialogos, mision_id, color)
