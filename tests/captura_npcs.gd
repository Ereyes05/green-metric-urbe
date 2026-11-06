# Captura del mapa con las burbujas de nombre de todos los NPC visibles,
# para revisar a ojo que el nombre quede centrado. NO es headless:
#   $GODOT --path . --resolution 1280x720 res://tests/captura_npcs.tscn -- <ruta.png> [zoom] [npc]
# zoom: el de la cámara (el juego usa 0.8). npc: nombre del NPC a centrar
# (por defecto, el primero).
extends Node


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	var args := OS.get_cmdline_user_args()
	var ruta : String = args[0] if args.size() > 0 else "user://captura_npcs.png"
	var zoom : float = float(args[1]) if args.size() > 1 else 0.8
	var foco : String = args[2] if args.size() > 2 else ""

	var mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(mapa)
	await get_tree().create_timer(1.5).timeout

	# Ocultar el HUD y los paneles para que solo se vea el mapa.
	for h in mapa.get_children():
		if h is CanvasLayer:
			h.visible = false

	var objetivo : Node2D = null
	for npc in get_tree().get_nodes_in_group("npcs_mapa"):
		npc.bloqueado = false
		npc._burbuja.visible = true
		npc._burbuja.modulate.a = 1.0
		if objetivo == null or npc.nombre_npc == foco:
			objetivo = npc

	var jugador : Node2D = mapa.get_node("Jugador")
	jugador.visible = false
	var cam : Camera2D = jugador.get_node("Camera2D")
	cam.zoom = Vector2(zoom, zoom)
	cam.position_smoothing_enabled = false
	jugador.global_position = objetivo.global_position + Vector2(0, -20)
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ruta)
	print("captura: ", ProjectSettings.globalize_path(ruta))
	get_tree().quit()
