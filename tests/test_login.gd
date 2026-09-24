# Verifica la pantalla de acceso: la lista de carreras, los dominios de
# correo y el interruptor que oculta la recuperación por correo.
#
# Se revisa el código fuente en vez de instanciar SceneLogin porque la
# escena arranca pidiéndole cosas a Supabase, y una prueba no debe tocar
# producción. Misma técnica que usa test_compila.gd.
#
# Correr: $GODOT --headless --path . res://tests/test_login.tscn
extends Node

const RUTA := "res://scenes/login/SceneLogin.gd"

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_login")
	var src : String = FileAccess.get_file_as_string(RUTA)
	_check(not src.is_empty(), "SceneLogin.gd se puede leer")

	# ── Carreras ────────────────────────────────────────────────
	# Informática es la población del estudio (Cap. 3: "estudiantes de
	# Informática de la URBE") y faltaba en la lista.
	_check(src.contains('"Ingeniería en Informática"'),
		   "la carrera Ingeniería en Informática está en la lista")
	_check(src.contains('"Ingeniería en Computación"'),
		   "Computación sigue estando (son carreras distintas)")
	_check(src.find('"Ingeniería en Informática"') < src.find('"Ingeniería en Computación"'),
		   "Informática aparece antes que Computación")
	_check(src.contains('"Otra"'), "queda la opción Otra para quien no esté")

	# ── Dominios de correo ──────────────────────────────────────
	for d in ["urbe.edu", "gmail.com"]:
		_check(src.contains('"%s"' % d), "se acepta el dominio %s" % d)

	# ── Recuperación por correo, apagada ────────────────────────
	# No sirve poner el botón detrás de un `if` si alguien más adelante lo
	# agrega igual: por eso se comprueban las dos mitades.
	_check(src.contains("const RECUPERACION_POR_CORREO : bool = false"),
		   "la recuperación por correo está apagada")
	_check(src.contains("if RECUPERACION_POR_CORREO:"),
		   "el botón se crea solo cuando el interruptor está encendido")
	_check(src.contains("if btn_olvide:"),
		   "la conexión del botón también está protegida")

	# El código de la recuperación NO se borró: tiene que seguir entero
	# para que volver a encenderla sea cambiar una línea y nada más.
	for f in ["_on_recuperar_pressed", "_resetear_panel_recuperacion",
			  "_panel_rec", "_btn_verificar", "_btn_cambiar"]:
		_check(src.contains(f), "sigue existiendo %s (la pantalla no se borró)" % f)

	var sm := FileAccess.get_file_as_string("res://autoload/SupabaseManager.gd")
	for f in ["recuperar_contrasena", "verificar_codigo_recuperacion",
			  "establecer_nueva_contrasena"]:
		_check(sm.contains("func %s(" % f), "SupabaseManager.%s sigue existiendo" % f)

	# ── Que además COMPILE ──────────────────────────────────────
	# Todo lo de arriba lee texto: pasaría igual con el script roto. Esto
	# lo carga de verdad. Tiene que correr dentro de una escena y no con
	# --script, porque SceneLogin usa autoloads y --script no los levanta.
	var script := load(RUTA)
	_check(script != null, "SceneLogin.gd compila")
	_check(load("res://scenes/login/scene_login.tscn") != null, "la escena de login carga")

	print("test_login: %d fallas" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
