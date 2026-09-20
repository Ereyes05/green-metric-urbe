# Arma el HUD con los datos del mockup 2a y guarda una captura 1280×720.
# NO es headless (necesita dibujar):
#   $GODOT --path . --resolution 1280x720 res://tests/captura_hud.tscn -- <ruta.png>
extends Node

const FICHA    := preload("res://scenes/ui/hud_ficha_jugador.gd")
const PANEL_GM := preload("res://scenes/ui/hud_panel_greenmetric.gd")
const ACCIONES := preload("res://scenes/ui/hud_acciones.gd")
const BANNER   := preload("res://scenes/ui/hud_banner_zona.gd")
const AVISO    := preload("res://scenes/ui/hud_aviso.gd")


func _ready() -> void:
	# project.godot trae window/size/mode=2 (maximizado); forzar ventana
	# 1280x720 acá para que la captura respete la resolución de diseño sin
	# tocar ese archivo.
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	var ruta : String = args[0] if args.size() > 0 else "user://captura_hud.png"
	var fondo := ColorRect.new()
	fondo.color = Color(0.20, 0.33, 0.22)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var capa := CanvasLayer.new()
	add_child(capa)
	capa.add_child(fondo)

	var f = FICHA.new()
	capa.add_child(f)
	f.set_energia(3, 3)
	f.set_nivel_misiones(6, [true, true, true, true, true, false])
	f.set_rango(2, 0.45, 1578)
	f.set_creditos(319)

	var gm = PANEL_GM.new()
	capa.add_child(gm)
	var cats := {
		1: {"avance": 64.0, "comprension": 8.0, "decisiones": 3.0, "sinergias": 2.0, "total": 77.0},
		2: {"avance": 56.0, "comprension": 10.0, "decisiones": 4.0, "sinergias": 1.0, "total": 71.0},
		3: {"avance": 48.0, "comprension": 6.0, "decisiones": 2.0, "sinergias": 0.0, "total": 56.0},
		4: {"avance": 40.0, "comprension": 7.0, "decisiones": 5.0, "sinergias": 3.0, "total": 55.0},
		5: {"avance": 72.0, "comprension": 9.0, "decisiones": 1.0, "sinergias": 0.0, "total": 82.0},
		6: {"avance": 32.0, "comprension": 4.0, "decisiones": 0.0, "sinergias": 0.0, "total": 36.0},
	}
	gm.actualizar(cats, 66.0)

	capa.add_child(ACCIONES.new())
	var b = BANNER.new()
	capa.add_child(b)
	b.mostrar("🌿", "Plaza Central", "Nivel 1 · Entorno", Color("#62D06A"))
	var v = AVISO.new()
	capa.add_child(v)
	v.avisar("✨ Sinergia", false, [{"texto": "🌿 +2", "color": Color("#62D06A")}, {"texto": "💧 +1", "color": Color("#3FBEDC")}])

	await get_tree().create_timer(0.3).timeout
	gm.mostrar_popover(1)
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(ruta)
	print("captura_hud: ", ruta, " err=", err)
	get_tree().quit(0 if err == OK else 1)
