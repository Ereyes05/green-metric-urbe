# Prueba de la Oficina (encargo y tablero) y del Consejo (revisión,
# objeciones con reintento, resultado).
# Correr: $GODOT --headless --path . res://tests/test_panel_consejo_movilidad.tscn
extends Node

const OFICINA := preload("res://scenes/misiones/panel_oficina_movilidad.gd")
const CONSEJO := preload("res://scenes/misiones/panel_consejo_movilidad.gd")
const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")
const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")

const MEJOR := {
	"tr_permisos": "permiso_por_necesidad", "tr_lote": "ciclovia_arborizada",
	"tr_carpool": "puestos_3_ocupantes", "tr_shuttle": "ruta_a_paradas",
	"tr_dia_sin_carros": "jornada_mensual_con_feria", "tr_flota": "carritos_electricos",
	"tr_bici_bloque_e": "techado_con_panel", "tr_bici_cafetin": "techado_con_panel",
}

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _textos(n: Node) -> String:
	var t := ""
	if n is Label:
		t += (n as Label).text + "\n"
	elif n is Button:
		t += (n as Button).text + "\n"
	for c in n.get_children():
		t += _textos(c)
	return t


func _boton(n: Node, texto: String) -> Button:
	if n is Button and (n as Button).text == texto:
		return n as Button
	for c in n.get_children():
		var b := _boton(c, texto)
		if b:
			return b
	return null


func _plan_completo():
	var p = PLAN.new()
	p.encargo_aceptado = true
	for id in MEJOR.keys():
		p.aplicar_valida(id, MEJOR[id])
	return p


func _ready() -> void:
	print("test_panel_consejo_movilidad")
	# ── Oficina ─────────────────────────────────────────────
	var plan = PLAN.new()
	var of : CanvasLayer = OFICINA.new()
	add_child(of)
	var aceptados := [0]
	of.encargo_aceptado.connect(func(): aceptados[0] += 1)
	of.abrir(plan)
	_check(of.visible and _textos(of).contains(DATOS.ENCARGO), "primera visita: encargo")
	var b_aceptar := _boton(of, "Aceptar el encargo")
	_check(b_aceptar != null, "botón Aceptar el encargo")
	b_aceptar.pressed.emit()
	_check(aceptados[0] == 1 and not plan.encargo_aceptado, "avisa y no modifica el plan")
	plan.encargo_aceptado = true
	plan.aplicar_valida("tr_lote", "ciclovia_arborizada")
	of.abrir(plan)
	var t := _textos(of)
	_check(t.contains("quedan 78"), "tablero: presupuesto")
	_check(t.contains("Ciclovía con árboles · costo 22"), "tablero: decisión resuelta")
	_check(t.contains("Pendiente · Garita del Estacionamiento M5"), "tablero: decisión pendiente con su lugar")
	_check(t.contains("faltan 7 decisiones"), "tablero: estado del Consejo")
	# I4: singular cuando falta exactamente una ("falta 1 decisión", no
	# "faltan 1 decisiones"). tr_lote ya estaba resuelta arriba; resolvemos
	# 6 más y dejamos tr_bici_cafetin pendiente.
	for id in ["tr_permisos", "tr_carpool", "tr_shuttle", "tr_dia_sin_carros", "tr_flota", "tr_bici_bloque_e"]:
		plan.aplicar_valida(id, MEJOR[id])
	of.abrir(plan)
	var t2 := _textos(of)
	_check(t2.contains("falta 1 decisión") and not t2.contains("faltan 1"), "tablero: singular cuando falta una decisión (I4)")
	of.cerrar()
	_check(not of.visible, "Oficina se cierra")

	# ── Consejo ─────────────────────────────────────────────
	var p2 = _plan_completo()
	var co : CanvasLayer = CONSEJO.new()
	add_child(co)
	var cambios := []
	co.cambio_solicitado.connect(func(id): cambios.append(id))
	var args := []
	co.argumento_elegido.connect(func(d, o, i, c, n): args.append([d, o, i, c, n]))
	var presentados := [0]
	co.plan_presentado.connect(func(): presentados[0] += 1)
	co.abrir(p2)
	_check(co.fase == "revision" and _textos(co).contains("Cambios disponibles: 2"), "revisión con 2 cambios")
	var presentar := _boton(co, "Presentar al Consejo")
	_check(presentar != null and not presentar.disabled, "se puede presentar")
	_boton(co, "Cambiar").pressed.emit()
	_check(cambios == ["tr_permisos"] and not co.visible, "Cambiar pide la decisión y oculta el Consejo")

	co.abrir(p2)
	co._iniciar_objeciones()
	_check(co.fase == "objeciones", "fase de objeciones")
	var ids := []
	for o in co._objeciones:
		ids.append(o["decision"])
	_check(ids == ["tr_permisos", "tr_carpool", "tr_dia_sin_carros"], "objeciones sobre los puntos débiles")
	var obj : Dictionary = co._objeciones[0]
	var mal := -1
	var bien := -1
	for i in obj["argumentos"].size():
		if obj["argumentos"][i]["correcto"]:
			bien = i
		elif mal == -1:
			mal = i
	co._on_argumento(mal)
	_check(not co._resuelta and mal in co._descartados, "incorrecto: se descarta y sigue la objeción")
	_check(_textos(co).contains("No convence"), "incorrecto: explica por qué")
	co._on_argumento(mal)
	_check(args.size() == 1, "un argumento descartado no se vuelve a elegir")
	co._on_argumento(bien)
	_check(co._resuelta and args.size() == 2 and args[1][3] == true and args[1][4] == 2, "correcto en el segundo intento")
	_check(_boton(co, "Siguiente objeción") != null, "botón Siguiente objeción")
	co._on_siguiente()
	for k in 2:
		var ob : Dictionary = co._objeciones[co._idx]
		for i in ob["argumentos"].size():
			if ob["argumentos"][i]["correcto"]:
				co._on_argumento(i)
				break
		co._on_siguiente()
	_check(co.fase == "resultado" and presentados[0] == 1, "resultado tras 3 objeciones")
	_check(p2.presentado() and int(p2.consejo["aciertos"]) == 2 and p2.consejo["calificacion"] == "consejo_2", "2 aciertos al primer intento")
	var r0 : Dictionary = p2.consejo["objeciones"][0]
	_check(r0["primer_argumento"] == mal and r0["correcto_primer_intento"] == false and r0["intentos"] == 2, "resultado de la primera objeción")
	var tr := _textos(co)
	_check(tr.contains("Aprobado") and tr.contains("4,60 de 5"), "resultado con calificación")
	# I1: recién presentado, todavía no llegó NINGUNA respuesta del registro
	# (ni éxito ni falla) — debe verse un aviso neutral, sin el botón de
	# reintento todavía (antes se mostraba el aviso naranja de "no
	# registrada" de una, aunque el pedido siguiera en camino).
	_check(tr.contains("Registrando la calificación") and not tr.contains("todavía no quedó registrada")
		and _boton(co, "Reintentar registro") == null, "esperando la primera respuesta: aviso neutral, sin reintento")

	# Llega la respuesta y falló (o no hay sesión): recién ahí el aviso
	# naranja y el botón de reintento.
	co.marcar_registro_resuelto()
	var tr2 := _textos(co)
	_check(tr2.contains("todavía no quedó registrada") and tr2.contains("Reintentar registro"), "respuesta fallida: aviso naranja y reintento")

	var reintentos := [0]
	co.reintentar_registro.connect(func(): reintentos[0] += 1)
	_boton(co, "Reintentar registro").pressed.emit()
	_check(reintentos[0] == 1, "reintento de registro manual")
	_check(_textos(co).contains("Registrando la calificación") and _boton(co, "Reintentar registro") == null,
		"reintento: vuelve al aviso neutral sin botón mientras espera de nuevo")

	p2.consejo["registrado"] = true
	co.marcar_registro_resuelto()
	_check(co.fase == "resultado" and _boton(co, "Reintentar registro") == null, "registrado: sin botón de reintento")
	var tr3 := _textos(co)
	_check(tr3.contains("Entorno +1"), "muestra las sinergias")
	# M4: vocabulario unificado a "Sinergia" (antes decía "Cruce ganado").
	_check(tr3.contains("Sinergia ganada") and not tr3.contains("Cruce"), "sinergias con la palabra 'Sinergia', no 'Cruce'")
	co.cerrar()

	var p3 = _plan_completo()
	p3.cambios_en_consejo = 2
	co.abrir(p3)
	_check(_boton(co, "Cambiar").disabled, "sin cambios disponibles: Cambiar deshabilitado")
	co.cerrar()

	for ruta in ["res://scenes/misiones/panel_oficina_movilidad.gd", "res://scenes/misiones/panel_consejo_movilidad.gd"]:
		_check(not FileAccess.get_file_as_string(ruta).contains("Color("), "sin colores literales: %s" % ruta)

	print("test_panel_consejo_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
