# ============================================================
# jugador.gd — URBE Rangers: Eco-Quest
# ============================================================
extends CharacterBody2D

const VELOCIDAD     : float  = 120.0
const GRUPO_JUGADOR : String = "jugador"
const TRAIL_MAX     : int    = 10
const TRAIL_DELTA   : float  = 0.055

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

var _moviéndose    : bool          = false
var _dir_actual    : String        = "abajo"
var npc_cercano    : Node          = null
var _trail         : Array[Vector2] = []
var _trail_timer   : float         = 0.0

# Señal para que el mapa pueda reaccionar (zoom, efectos)
signal interaccion_iniciada()


func _ready() -> void:
	add_to_group(GRUPO_JUGADOR)
	if sprite:
		sprite.play("idle_abajo")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.scale = Vector2(1.5, 1.5)


func _physics_process(delta: float) -> void:
	var dlg          = get_tree().get_first_node_in_group("ui_dialogo")
	var quiz         = get_tree().get_first_node_in_group("ui_quiz")
	var mision_ui    = get_tree().get_first_node_in_group("ui_mision_inicio")
	var minijuego_ui = get_tree().get_first_node_in_group("ui_minijuego")
	var tutorial_ui  = get_tree().get_first_node_in_group("ui_tutorial")
	var crisis_ui    = get_tree().get_first_node_in_group("ui_crisis")
	var interior_ui  = get_tree().get_first_node_in_group("interior_bloque")
	var tienda_ui    = get_tree().get_first_node_in_group("ui_tienda")

	if (dlg and dlg.visible) or (quiz and quiz.visible) \
			or (mision_ui and mision_ui.visible) \
			or (minijuego_ui and minijuego_ui.visible) \
			or (tutorial_ui and tutorial_ui.visible) \
			or (crisis_ui and crisis_ui.visible) \
			or (interior_ui and interior_ui.visible) \
			or (tienda_ui and tienda_ui.visible):
		velocity = Vector2.ZERO
		_animar("idle_" + _dir_actual)
		move_and_slide()
		# Trail se disuelve al parar
		if not _trail.is_empty():
			_trail.pop_front()
			queue_redraw()
		return

	# Botón interactuar táctil
	var touch_nodo = get_tree().get_first_node_in_group("touch_controls")
	if touch_nodo and touch_nodo.visible and touch_nodo.interact_fired:
		touch_nodo.interact_fired = false
		if npc_cercano != null:
			interaccion_iniciada.emit()
			npc_cercano.iniciar_dialogo()

	var dir := _leer_input()
	if dir.length() > 0:
		dir         = dir.normalized()
		_moviéndose = true
		_dir_actual = _calcular_direccion(dir)
		velocity    = dir * VELOCIDAD
		_animar("walk_" + _dir_actual)

		# Trail de pasos
		_trail_timer += delta
		if _trail_timer >= TRAIL_DELTA:
			_trail_timer = 0.0
			_trail.append(global_position)
			if _trail.size() > TRAIL_MAX:
				_trail.pop_front()
			queue_redraw()
	else:
		_moviéndose = false
		velocity    = Vector2.ZERO
		_animar("idle_" + _dir_actual)
		# Trail se disuelve gradualmente
		if not _trail.is_empty():
			_trail.pop_front()
			queue_redraw()

	move_and_slide()


func _draw() -> void:
	# Sombra elíptica bajo el personaje
	draw_arc(Vector2(0, 10), 11.0, 0.0, PI, 14, Color(0, 0, 0, 0.22), 8.0)

	if _trail.is_empty(): return
	var n : int = _trail.size()
	# "Estela de hojas" de la Tienda del Conocimiento: hojas visibles y
	# giradas en vez de los círculos tenues que tiene todo el mundo.
	var hojas : bool = EconomiaManager.tiene_item("estela_hojas")
	for i in n:
		var local_p : Vector2 = to_local(_trail[i])
		var t       : float   = float(i + 1) / float(n)
		if hojas:
			_dibujar_hoja(local_p, 3.5 + t * 3.0, float(i) * 1.7, t * 0.85)
		else:
			var alpha : float = t * 0.30
			var r     : float = 2.5 + t * 2.0
			draw_circle(local_p, r, Color(0.30, 0.92, 0.42, alpha))


func _dibujar_hoja(centro: Vector2, largo: float, angulo: float, alpha: float) -> void:
	var eje   := Vector2(cos(angulo), sin(angulo))
	var perp  := Vector2(-eje.y, eje.x)
	var punta := centro + eje * largo
	var base  := centro - eje * largo
	var ancho := largo * 0.55
	draw_colored_polygon(PackedVector2Array([
		base, centro + perp * ancho, punta, centro - perp * ancho,
	]), Color(0.22, 0.72, 0.28, alpha))
	draw_line(base, punta, Color(0.12, 0.42, 0.16, alpha), 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interactuar"):
		return

	var mision_ui    = get_tree().get_first_node_in_group("ui_mision_inicio")
	var dlg          = get_tree().get_first_node_in_group("ui_dialogo")
	var quiz         = get_tree().get_first_node_in_group("ui_quiz")
	var minijuego_ui = get_tree().get_first_node_in_group("ui_minijuego")
	var tutorial_ui2 = get_tree().get_first_node_in_group("ui_tutorial")
	var crisis_ui2   = get_tree().get_first_node_in_group("ui_crisis")
	var tienda_ui2   = get_tree().get_first_node_in_group("ui_tienda")
	if (mision_ui and mision_ui.visible) or (dlg and dlg.visible) \
			or (quiz and quiz.visible) or (minijuego_ui and minijuego_ui.visible) \
			or (crisis_ui2 and crisis_ui2.visible) or (tienda_ui2 and tienda_ui2.visible):
		return
	# Tutorial maneja [E] internamente, no lo consumimos aquí
	if tutorial_ui2 and tutorial_ui2.visible:
		return

	if npc_cercano != null:
		interaccion_iniciada.emit()
		npc_cercano.iniciar_dialogo()


func _leer_input() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("mover_derecha"):   dir.x =  1.0
	if Input.is_action_pressed("mover_izquierda"): dir.x = -1.0
	if Input.is_action_pressed("mover_abajo"):     dir.y =  1.0
	if Input.is_action_pressed("mover_arriba"):    dir.y = -1.0

	# Joystick táctil (móvil): sobreescribe solo si hay input táctil
	var touch = get_tree().get_first_node_in_group("touch_controls")
	if touch and touch.visible and touch.joy_dir.length() > 0.0:
		dir = touch.joy_dir

	return dir


func _calcular_direccion(dir: Vector2) -> String:
	if abs(dir.x) >= abs(dir.y):
		return "derecha" if dir.x > 0 else "izquierda"
	else:
		return "abajo" if dir.y > 0 else "arriba"


func _animar(nombre: String) -> void:
	if sprite and sprite.animation != nombre:
		sprite.play(nombre)
