# ============================================================
# WindowManager.gd — URBE Rangers: Eco-Quest
# Autoload global. F11 = pantalla completa / ventana.
# Usa _input (no _unhandled_input) para garantizar la captura
# del evento aunque otro nodo lo haya procesado primero.
# ============================================================
extends Node


const FUENTE_EMOJI : String = "res://assets/fonts/NotoColorEmoji-subset.ttf"


func _ready() -> void:
	set_process(false)   # solo corre mientras el contador de FPS esté visible
	_registrar_fuente_emoji()

	# En el navegador la "ventana" es el canvas: maximizar no aporta nada y
	# puede pelearse con la política de tamaño del canvas del export.
	if OS.has_feature("web"):
		return

	# Forzar ventana maximizada al arrancar si no está ya en fullscreen
	var modo := DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


# En escritorio, Godot completa los glifos que le faltan con las fuentes del
# sistema operativo — por eso los emoji del HUD (🌿 💧 ⚡ ♻ 🚲 📚) se ven bien
# al correr el juego desde el editor. En el export web NO hay fuentes del
# sistema, así que esos mismos emoji salen como cuadraditos vacíos.
#
# La solución es empaquetar una fuente de emoji. En vez de reemplazar la
# fuente por defecto del juego (que obligaría a revisar el layout de toda la
# UI), se la agrega como fallback: Godot la usa solo para los glifos que la
# fuente base no tiene, y todo el texto normal queda igual que siempre.
#
# La fuente es Noto Color Emoji recortada SOLO a los 121 emoji que usa el
# juego: 10.6 MB → 192 KB. Si se agregan emoji nuevos a la UI y aparecen
# como cuadraditos, hay que volver a generar el recorte (ver
# docs/ESTADO_PROYECTO.md, sección 10).
func _registrar_fuente_emoji() -> void:
	if not ResourceLoader.exists(FUENTE_EMOJI):
		push_warning("WindowManager: falta la fuente de emoji en %s — " % FUENTE_EMOJI
			+ "los iconos se verán como cuadraditos en el export web.")
		return
	var emoji := load(FUENTE_EMOJI) as Font
	var base  := ThemeDB.fallback_font
	if emoji == null or base == null:
		return
	var fallbacks := base.fallbacks
	if emoji in fallbacks:
		return
	fallbacks.append(emoji)
	base.fallbacks = fallbacks


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey): return
	if not event.pressed or event.echo: return

	if event.keycode == KEY_F3:
		get_viewport().set_input_as_handled()
		_toggle_fps()

	elif event.keycode == KEY_F11:
		get_viewport().set_input_as_handled()
		_toggle_fullscreen()

	elif (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) \
			and event.alt_pressed:
		get_viewport().set_input_as_handled()
		_toggle_fullscreen()


# ── Contador de FPS (F3) ─────────────────────────────────────
# Existe para poder diagnosticar rendimiento con un número en vez de "se
# siente lento", sobre todo en el export web, donde todo corre en un solo
# hilo y no hay forma de abrir el profiler del editor.
var _fps_capa : CanvasLayer = null
var _fps_lbl  : Label       = null


func _toggle_fps() -> void:
	if _fps_capa == null:
		_crear_fps()
	_fps_capa.visible = not _fps_capa.visible
	set_process(_fps_capa.visible)


func _crear_fps() -> void:
	_fps_capa = CanvasLayer.new()
	_fps_capa.layer = 128        # por encima de todo, incluido el modal del QR
	add_child(_fps_capa)

	_fps_lbl = Label.new()
	_fps_lbl.position = Vector2(8, 8)
	_fps_lbl.add_theme_font_size_override("font_size", 13)
	_fps_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	_fps_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_fps_lbl.add_theme_constant_override("outline_size", 4)
	_fps_capa.add_child(_fps_lbl)


func _process(_delta: float) -> void:
	if _fps_lbl == null: return
	_fps_lbl.text = "%d FPS   %s" % [
		Engine.get_frames_per_second(),
		"web" if OS.has_feature("web") else "escritorio",
	]


func _toggle_fullscreen() -> void:
	var modo := DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func esta_en_fullscreen() -> bool:
	var modo := DisplayServer.window_get_mode()
	return modo == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
