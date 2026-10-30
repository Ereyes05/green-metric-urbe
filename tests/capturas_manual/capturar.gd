# Capturas del manual de usuarios (docs/manual_usuarios.md).
# Abre el juego real, lo deja en un estado de ejemplo y guarda UNA captura.
# NO es headless (necesita dibujar):
#   $GODOT --path . --resolution 1280x720 res://tests/capturas_manual/capturar.tscn -- <id> <ruta.png>
# Los ids están en CAPTURAS. Los números del HUD son datos de ejemplo.
extends Node

const TESTS := preload("res://scenes/misiones/tests_nivel.gd")

const CAPTURAS := [
	"login", "registro", "tutorial_1", "tutorial_2", "hud", "dialogo", "quiz",
	"quiz_fallo", "mision_campo", "decision", "crisis", "reporte", "simulador",
	"tienda", "ranking", "avance", "test", "test_resultado", "insignia", "npc_bloqueado", "guia_1", "guia_4", "guia_6",
]

const RANKING_DEMO := [
	{"nombre": "María G.", "xp_total": 2310, "niveles_completos": 6, "titulo": "Embajador GreenMetric", "es_yo": false},
	{"nombre": "Luis P.", "xp_total": 1580, "niveles_completos": 5, "titulo": null, "es_yo": false},
	{"nombre": "Eco-Ranger", "xp_total": 1240, "niveles_completos": 4, "titulo": null, "es_yo": true},
	{"nombre": "Ana R.", "xp_total": 860, "niveles_completos": 3, "titulo": null, "es_yo": false},
	{"nombre": "José M.", "xp_total": 410, "niveles_completos": 1, "titulo": null, "es_yo": false},
]

var _mapa : Node = null


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	var args := OS.get_cmdline_user_args()
	var id : String = args[0]
	var ruta : String = args[1]
	if id in ["login", "registro"]:
		await _login(id)
	else:
		await _abrir_mapa()
		await _preparar(id)
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var err := get_viewport().get_texture().get_image().save_png(ruta)
	print("captura %s -> %s (%d)" % [id, ruta, err])
	get_tree().quit(0 if err == OK else 1)


func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _login(id: String) -> void:
	var login = load("res://scenes/login/scene_login.tscn").instantiate()
	add_child(login)
	await _esperar(2.5)
	if id == "registro":
		login._cambiar_panel("registro")
		await _esperar(1.0)


# Estudiante de ejemplo: niveles 1 a 4 completos, Nivel 5 recién abierto.
func _estado_demo() -> void:
	var nm = NivelManager
	nm._misiones = {}
	for n in [1, 2, 3, 4]:
		var hechas := {}
		for m in nm.MISIONES_NIVEL[n]:
			hechas[m] = true
		nm._misiones[str(n)] = hechas
	nm.nivel_actual = 5


func _puntaje_demo() -> Dictionary:
	var cats := {}
	var valores := {1: [80, 8, 3, 2], 2: [80, 10, 4, 1], 3: [80, 6, 2, 1],
					4: [80, 7, 0, 0], 5: [0, 3, 0, 0], 6: [0, 0, 0, 0]}
	var total := 0.0
	var pesos := {1: 15, 2: 21, 3: 18, 4: 10, 5: 18, 6: 18}
	for n in valores:
		var v : Array = valores[n]
		var t : float = v[0] + v[1] + v[2] + v[3]
		cats[str(n)] = {"avance": v[0], "comprension": v[1], "decisiones": v[2],
						"sinergias": v[3], "total": t}
		total += t * pesos[n] / 100.0
	return {"categorias": cats, "total": snappedf(total, 0.01), "quizzes_hechos": []}


func _abrir_mapa() -> void:
	_estado_demo()
	# Sin sesión el mapa guarda la posición del personaje en este archivo
	# (solo pasa al desarrollar). Se borra para que todas las capturas
	# arranquen en el punto de entrada del campus.
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://posicion_jugador.dat"))
	_mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(_mapa)
	await _esperar(3.0)
	SupabaseManager.puntaje_recibido.emit(_puntaje_demo())
	SupabaseManager.billetera_cargada.emit({"saldo": 185, "inventario": []})
	_mapa._xp_total = 1240
	_mapa._actualizar_hud()
	await _esperar(0.8)


func _hijo_con_script(ruta: String) -> Node:
	for c in _mapa.get_children():
		var s = c.get_script()
		if s and s.resource_path == ruta:
			return c
	return null


func _preparar(id: String) -> void:
	match id:
		"hud":
			pass
		"tutorial_1", "tutorial_2":
			_mapa._tutorial_ui.iniciar()
			if id == "tutorial_2":
				_mapa._tutorial_ui._paso_actual = 1
				_mapa._tutorial_ui._mostrar_paso()
			# El texto se escribe letra por letra.
			await _esperar(10.0)
		"dialogo":
			var d : Dictionary = _mapa.DATOS_NPCS[0]
			var retrato = load(d["sprite"]) if d.has("sprite") else null
			_mapa._dialogo_ui.iniciar(d["nombre"], d["dialogos"], d["mision_id"], d["color"], retrato)
			await _esperar(2.0)
		"quiz", "quiz_fallo":
			_mapa._quiz_ui.iniciar(_mapa.QUIZ_POR_MISION["mision_agua"], "Lic. Torres", 4, "mision_agua")
			await _esperar(1.2)
			if id == "quiz_fallo":
				_mapa._quiz_ui._responder(0)
				await _esperar(0.3)
		"mision_campo":
			var zona = _hijo_con_script("res://scenes/misiones/zona_tierra.gd")
			_mapa._plantar_ui.iniciar(0, zona, "click")
			await _esperar(1.5)
		"decision":
			_mapa._nivel5.plan.encargo_aceptado = true
			_mapa._nivel5.panel_decision.abrir("tr_permisos")
			await _esperar(1.0)
		"crisis":
			_mapa._crisis_ui.iniciar_aleatoria()
			await _esperar(2.0)
		"reporte":
			_mapa._abrir_resultados()
			await _esperar(1.0)
		"simulador":
			_mapa._abrir_simulador()
			await _esperar(1.0)
		"tienda":
			# La tienda pide sesión; el catálogo se carga sin ella (anon).
			SupabaseManager.jwt_token = "demo"
			_mapa._abrir_tienda()
			await _esperar(4.0)
		"ranking":
			_mapa._leaderboard_ui.mostrar()
			await _esperar(4.0)
			# Nombres de ejemplo: el manual no muestra a estudiantes reales.
			SupabaseManager.ranking_cargado.emit(RANKING_DEMO)
			await _esperar(0.5)
		"avance":
			_mapa._hud_avance.mostrar()
			await _esperar(1.0)
		"test":
			var rng := RandomNumberGenerator.new()
			rng.seed = 3
			_mapa._test_activo = "nivel_4"
			_mapa._quiz_ui.iniciar(TESTS.preguntas("nivel_4", _mapa.QUIZ_POR_MISION, rng),
				"Nivel 4", 4, "test_nivel_4", true)
			await _esperar(1.2)
		"test_resultado":
			_mapa._hud_aviso.avisar("📋 Nivel 4: 3 de 3 correctas")
			await _esperar(0.8)
		"quiz_largo":
			# La pregunta con la opción más larga del banco (no va al manual).
			var q : Dictionary = {}
			for p in _mapa.QUIZ_POR_MISION["mision_bloque_g"]:
				if str(p["pregunta"]).begins_with("¿Qué certifica"):
					q = p
			_mapa._quiz_ui.iniciar([q], "Nivel 1", 1, "test_nivel_1", true)
			await _esperar(1.2)
		"npc_bloqueado":
			# Cuenta nueva: el Prof. González (Nivel 2) todavía no atiende.
			NivelManager._misiones = {}
			NivelManager.nivel_actual = 1
			_mapa._actualizar_hud()
			var npc : Node = null
			for n in get_tree().get_nodes_in_group("npcs_mapa"):
				if n.mision_id == "mision_bloque_a":
					npc = n
			_mapa.jugador.global_position = npc.global_position + Vector2(28, 6)
			await _esperar(1.0)
			npc.iniciar_dialogo()
			await _esperar(0.6)
		"guia_1", "guia_4", "guia_6":
			_mapa._guia.abrir()
			_mapa._guia._mostrar_pagina(int(id.trim_prefix("guia_")) - 1, 0)
			await _esperar(0.8)
		"informe":
			_mapa._informe_ui.iniciar(null)
			await _esperar(1.5)
		"insignia":
			_mapa._on_insignia_obtenida("m4_completo", "Gota Vital", "💧")
			await _esperar(0.8)
