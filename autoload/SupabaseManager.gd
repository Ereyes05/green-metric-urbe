# ============================================================
# SupabaseManager.gd — Singleton Global
# Maneja TODAS las peticiones HTTP hacia Supabase.
# ============================================================
extends Node

const SUPABASE_URL     : String = "https://ikohikbpvtbvsgyumvbr.supabase.co"
const SUPABASE_ANON_KEY: String = "sb_publishable_I7BlsHi98fLy-Yuq8NTtFQ_8tw6r44k"

# ── Señales ──────────────────────────────────────────────────
signal login_exitoso(datos: Dictionary)
# error_code: el campo estable que documenta Supabase (ej. "email_not_confirmed")
# para branchear por código en vez de por el texto de error, que cambia
# entre versiones. "" si el servidor no lo mandó.
signal login_fallido(error: String, error_code: String)
signal registro_exitoso(datos: Dictionary)
signal registro_sin_sesion()
signal registro_fallido(error: String)
signal recuperacion_enviada()
signal recuperacion_fallida(error: String)
signal codigo_verificado()
signal codigo_fallido(error: String)
signal contrasena_actualizada()
signal actualizar_contrasena_fallido(error: String)
signal modulos_cargados(lista: Array)
signal progreso_cargado(lista: Array)
# lista: [{"modulo_id": int, "mision_id": String}, ...] — una fila por
# misión ya registrada en misiones_estudiante para la cuenta logueada.
signal misiones_estudiante_cargadas(lista: Array)
signal solicitud_qr_creada(token: String)
signal solicitud_qr_creada_fallida(token: String)
signal solicitud_qr_estado(token: String, escaneada: bool)
# xp_otorgada: lo que la RPC realmente sumó (0 si ya_registrada).
# ya_registrada: true si esta mision_id ya estaba en misiones_estudiante —
# la llamada contó como intento pero no otorgó XP de nuevo.
# correccion_xp: xp_otorgada MENOS el xp que el caller ya sumó de forma
# optimista al llamar guardar_progreso() (0 en el caso normal, negativo en
# un duplicado). El caller debe sumar esto a su acumulador local en vez de
# fiarse del xp que mostró antes de la respuesta del servidor.
signal progreso_guardado(mision_id: String, xp_otorgada: int, ya_registrada: bool, correccion_xp: int)
# xp_local: lo que hay que restar del acumulador local porque el guardado
# falló del todo (sin respuesta válida del servidor, ni siquiera duplicado).
signal progreso_guardado_fallido(mision_id: String, xp_local: int)
signal ranking_cargado(lista: Array)
signal error_red(mensaje: String)

# ── Estado interno ───────────────────────────────────────────
var jwt_token      : String = ""
var user_id        : String = ""
var nombre_usuario : String = ""
# Token de sesión temporal que devuelve /auth/v1/verify al canjear el
# código de recuperación — deliberadamente separado de jwt_token para no
# pisar una sesión normal si el flujo de recuperación se usa por error
# mientras hay un usuario logueado.
var _recovery_token : String = ""
var _http          : HTTPRequest
var _accion_actual : String     = ""
var _ctx_actual    : Dictionary = {}   # contexto de la petición en vuelo (ej. mision_id)
var _cola          : Array  = []   # Array[Dictionary] peticiones en espera
var _ocupado       : bool   = false

# ── Telemetría de aprendizaje ──────────────────────────────────
# session_id: una por cada vez que se abre el juego (no por misión), para
# poder medir tiempo-en-tarea y secuencia real de eventos por sesión.
const EVENTOS_LOCAL_PATH : String = "user://eventos_aprendizaje.jsonl"
var _session_id : String = ""


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_respuesta_http)
	randomize()
	_session_id = "%d-%04x" % [Time.get_unix_time_from_system(), randi() % 0xFFFF]


func _encolar(accion: String, url: String, metodo: int,
			  hdrs: PackedStringArray, body: String = "", ctx: Dictionary = {}) -> void:
	_cola.append({"accion": accion, "url": url, "metodo": metodo,
				  "hdrs": hdrs, "body": body, "ctx": ctx})
	_despachar()


func _despachar() -> void:
	if _ocupado or _cola.is_empty():
		return
	_ocupado = true
	var p : Dictionary = _cola.pop_front()
	_accion_actual = p["accion"]
	_ctx_actual    = p.get("ctx", {})
	_http.request(p["url"], p["hdrs"], p["metodo"], p["body"])


# ── LOGIN ─────────────────────────────────────────────────────
func login(email: String, contrasena: String) -> void:
	var url  := SUPABASE_URL + "/auth/v1/token?grant_type=password"
	var body := JSON.stringify({"email": email, "password": contrasena})
	_encolar("login", url, HTTPClient.METHOD_POST, _headers_anon(), body)


# ── REGISTRO ─────────────────────────────────────────────────
func registrar(email: String, contrasena: String, meta: Dictionary) -> void:
	var url  := SUPABASE_URL + "/auth/v1/signup"
	var body := JSON.stringify({
		"email"   : email,
		"password": contrasena,
		"data"    : meta
	})
	_encolar("registro", url, HTTPClient.METHOD_POST, _headers_anon(), body)


# ── RECUPERAR CONTRASEÑA (3 pasos) ────────────────────────────
# Paso 1: pide el código de 6 dígitos por correo. Supabase responde 200
# aunque el correo no exista — a propósito, no delata qué correos están
# registrados. La UI siempre debe mostrar el mismo mensaje sin importar
# si el correo existe o no.
func recuperar_contrasena(email: String) -> void:
	var url  := SUPABASE_URL + "/auth/v1/recover"
	var body := JSON.stringify({"email": email})
	_encolar("recuperar", url, HTTPClient.METHOD_POST, _headers_anon(), body)


# Paso 2: canjea el código de 6 dígitos por una sesión temporal.
func verificar_codigo_recuperacion(email: String, codigo: String) -> void:
	var url  := SUPABASE_URL + "/auth/v1/verify"
	var body := JSON.stringify({"type": "recovery", "email": email, "token": codigo})
	_encolar("verificar_codigo", url, HTTPClient.METHOD_POST, _headers_anon(), body)


# Paso 3: fija la contraseña nueva con el token de la sesión temporal
# del paso 2 (no con jwt_token — ver comentario en _recovery_token).
func establecer_nueva_contrasena(nueva: String) -> void:
	if _recovery_token.is_empty():
		push_error("SupabaseManager: no hay token de recuperación activo — llamá verificar_codigo_recuperacion() primero.")
		return
	var url  := SUPABASE_URL + "/auth/v1/user"
	var body := JSON.stringify({"password": nueva})
	var hdrs := PackedStringArray([
		"Content-Type: application/json",
		"apikey: "               + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + _recovery_token
	])
	_encolar("nueva_contrasena", url, HTTPClient.METHOD_PUT, hdrs, body)


# ── MÓDULOS ───────────────────────────────────────────────────
func cargar_modulos() -> void:
	var url := SUPABASE_URL + "/rest/v1/modulos_greenmetric?order=orden_desbloqueo.asc&activo=eq.true"
	_encolar("cargar_modulos", url, HTTPClient.METHOD_GET, _headers_anon())


# ── PROGRESO ─────────────────────────────────────────────────
func cargar_progreso() -> void:
	if jwt_token.is_empty():
		push_error("SupabaseManager: Debes hacer login primero.")
		return
	var url := SUPABASE_URL + "/rest/v1/progreso_estudiante?select=*"
	_encolar("cargar_progreso", url, HTTPClient.METHOD_GET, _headers_auth())


# Estado por misión (no por módulo) de la cuenta logueada — la fuente real
# para repoblar NivelManager al entrar desde una máquina sin save local.
# Ver NivelManager.repoblar_desde_servidor().
func cargar_misiones_estudiante() -> void:
	if jwt_token.is_empty():
		push_error("SupabaseManager: Debes hacer login primero.")
		return
	var url := SUPABASE_URL + "/rest/v1/misiones_estudiante?select=modulo_id,mision_id"
	_encolar("cargar_misiones", url, HTTPClient.METHOD_GET, _headers_auth())


func cargar_ranking() -> void:
	var url := SUPABASE_URL + "/rest/v1/progreso_estudiante?select=user_id,xp_ganada,completado&order=xp_ganada.desc"
	_encolar("cargar_ranking", url, HTTPClient.METHOD_GET, _headers_anon())


# ── SOLICITUDES QR (servicio de limpieza, Nivel 3) ───────────
# El QR que se muestra en zona_reciclaje.gd apunta a una Edge Function
# pública (marcar_escaneado, sin login) que marca esta fila cuando
# alguien la abre desde su teléfono real. crear_solicitud_qr() registra
# el token al mostrar el QR; consultar_solicitud_qr() lo consulta
# periódicamente para detectar el escaneo real. Ver sql/solicitudes_qr.sql
# y supabase/functions/marcar_escaneado/index.ts.
func crear_solicitud_qr(token: String, mision_id: String) -> void:
	if jwt_token.is_empty():
		push_error("SupabaseManager: Debes hacer login primero.")
		return
	var url  := SUPABASE_URL + "/rest/v1/solicitudes_qr"
	var body := JSON.stringify({
		"token"    : token,
		"user_id"  : user_id,
		"mision_id": mision_id
	})
	_encolar("crear_solicitud_qr", url, HTTPClient.METHOD_POST, _headers_auth(), body,
			 {"token": token})


func consultar_solicitud_qr(token: String) -> void:
	if jwt_token.is_empty(): return
	var url := SUPABASE_URL + "/rest/v1/solicitudes_qr?token=eq.%s&select=escaneado" % token.uri_encode()
	_encolar("consultar_solicitud_qr", url, HTTPClient.METHOD_GET, _headers_auth(), "",
			 {"token": token})


func guardar_progreso(modulo_id: int, mision_id: String, puntaje: int, xp: int, completado: bool) -> void:
	if jwt_token.is_empty():
		push_error("SupabaseManager: Debes hacer login primero.")
		return
	# Reemplaza el INSERT/upsert directo contra progreso_estudiante (que no
	# tenía forma de distinguir un guardado real de uno duplicado — ver
	# sql/guardar_progreso_modulo.sql) por la RPC idempotente: la primera
	# vez que ve este mision_id otorga XP e inserta en misiones_estudiante;
	# las repeticiones (los mismos clics dobles que disparan
	# _completar_mision() más de una vez — ver interior_bloque.gd,
	# mision_solar.gd) solo actualizan intentos/% sin volver a sumar XP.
	var url  := SUPABASE_URL + "/rest/v1/rpc/guardar_progreso_modulo"
	var body := JSON.stringify({
		"p_modulo_id"      : modulo_id,
		"p_mision_id"      : mision_id,
		"p_xp_delta"       : xp,
		"p_completitud_pct": puntaje,
		"p_completado"     : completado
	})
	_encolar("guardar_progreso", url, HTTPClient.METHOD_POST, _headers_auth(), body,
			 {"mision_id": mision_id, "xp_local": xp})


# ── EVENTOS DE APRENDIZAJE ───────────────────────────────────
# Registro de PROCESO (no solo el resultado final): cada elección, acierto,
# fallo e intento, con timestamp — la base para poder argumentar aprendizaje
# ("¿mejoró con los intentos?") y empoderamiento ("¿qué eligió cuando tuvo
# opciones reales?"), no solo que "completó" contenido.
#
# `correcto` e `intento_num` son Variant a propósito: quedan en null cuando
# no aplican (ej. "mision_iniciada"), en vez de forzar un 0/false falso.
func registrar_evento(nivel: int, mision_id: String, tipo_evento: String,
					   detalle: Dictionary = {}, correcto = null, intento_num = null) -> void:
	var evento := {
		"session_id"  : _session_id,
		"nivel"       : nivel,
		"mision_id"   : mision_id,
		"tipo_evento" : tipo_evento,
		"correcto"    : correcto,
		"intento_num" : intento_num,
		"detalle"     : detalle,
		"creado_en_local": Time.get_datetime_string_from_system(true),
	}
	_registrar_evento_local(evento)
	if jwt_token.is_empty():
		return   # sin sesión iniciada: se queda solo en el log local
	var url  := SUPABASE_URL + "/rest/v1/eventos_aprendizaje"
	var body := JSON.stringify({
		"user_id"     : user_id,
		"session_id"  : _session_id,
		"nivel"       : nivel,
		"mision_id"   : mision_id,
		"tipo_evento" : tipo_evento,
		"correcto"    : correcto,
		"intento_num" : intento_num,
		"detalle"     : detalle,
	})
	_encolar("registrar_evento", url, HTTPClient.METHOD_POST, _headers_auth(), body)


# Espejo local: si Supabase no responde (sin internet, backend caído), el
# dato de investigación no se pierde — queda en disco, exportable a mano.
func _registrar_evento_local(evento: Dictionary) -> void:
	var f : FileAccess
	if FileAccess.file_exists(EVENTOS_LOCAL_PATH):
		f = FileAccess.open(EVENTOS_LOCAL_PATH, FileAccess.READ_WRITE)
		if f: f.seek_end()
	else:
		f = FileAccess.open(EVENTOS_LOCAL_PATH, FileAccess.WRITE)
	if not f: return
	f.store_line(JSON.stringify(evento))
	f.close()


# ── MANEJADOR CENTRAL ─────────────────────────────────────────
func _on_respuesta_http(result: int, code: int, hdrs: PackedStringArray, body: PackedByteArray) -> void:
	var accion := _accion_actual
	var ctx    := _ctx_actual
	_accion_actual = ""
	_ctx_actual    = {}
	_ocupado       = false

	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("error_red", "Sin conexión. Código: " + str(result))
		if accion == "guardar_progreso":
			emit_signal("progreso_guardado_fallido", str(ctx.get("mision_id", "")), int(ctx.get("xp_local", 0)))
		_despachar()
		return

	var texto := body.get_string_from_utf8()
	var datos  = JSON.parse_string(texto)

	match accion:
		"login"           : _procesar_login(code, datos)
		"registro"        : _procesar_registro(code, datos, texto, hdrs)
		"recuperar"       : _procesar_recuperar(code, datos)
		"verificar_codigo": _procesar_verificar_codigo(code, datos)
		"nueva_contrasena": _procesar_nueva_contrasena(code, datos)
		"cargar_modulos"  : _procesar_modulos(code, datos)
		"cargar_progreso" : _procesar_progreso(code, datos)
		"cargar_misiones" : _procesar_misiones_estudiante(code, datos)
		"crear_solicitud_qr"     : _procesar_crear_solicitud_qr(code, ctx)
		"consultar_solicitud_qr" : _procesar_consultar_solicitud_qr(code, datos, ctx)
		"guardar_progreso": _procesar_guardar(code, datos, ctx)
		"cargar_ranking"  : _procesar_ranking(code, datos)
		"registrar_evento": _procesar_evento(code)

	_despachar()   # lanza la siguiente petición en cola si la hay


func _procesar_login(code: int, datos: Variant) -> void:
	if code == 200 and datos is Dictionary and datos.has("access_token"):
		jwt_token = datos.get("access_token", "")
		var user : Dictionary = datos.get("user", {})
		user_id        = user.get("id", "")
		var meta : Dictionary = user.get("user_metadata", {})
		nombre_usuario = str(meta.get("nombre", meta.get("name", user.get("email", "Eco-Ranger"))))
		emit_signal("login_exitoso", user)
	else:
		var msg : String = "Credenciales incorrectas."
		var error_code : String = ""
		if datos is Dictionary:
			error_code = str(datos.get("error_code", ""))
			msg = datos.get("error_description",
					datos.get("msg", datos.get("error_code", msg)))
		emit_signal("login_fallido", msg, error_code)


func _procesar_registro(code: int, datos: Variant, cuerpo_crudo: String, headers: PackedStringArray) -> void:
	var tiene_sesion : bool = datos is Dictionary and datos.has("access_token") \
		and not str(datos.get("access_token", "")).is_empty()

	if code in [200, 201] and tiene_sesion:
		var usuario = datos.get("user", {})
		user_id   = usuario.get("id", "")
		jwt_token = datos.get("access_token", "")
		emit_signal("registro_exitoso", usuario)
	elif code in [200, 201]:
		# La cuenta SÍ se creó (200/201) pero no vino sesión — con o sin
		# "user" legible en el cuerpo. En vez de adivinar el estado desde
		# acá, quien llama (SceneLogin) intenta un login automático con
		# las credenciales que ya tiene en memoria y actúa según ESA
		# respuesta — ver registro_sin_sesion().
		if not (datos is Dictionary):
			# Instrumentación: el caso "no parsea" sigue sin diagnosticarse
			# del todo (reproduce el síntoma del 1-sep-2026 21:39). El login
			# automático ya resuelve la UX, pero esto queda para cerrar la
			# causa: ¿qué manda el servidor exactamente acá?
			print("SupabaseManager: signup 200 con cuerpo no parseable — bytes=%d cuerpo=%s headers=%s"
				% [cuerpo_crudo.to_utf8_buffer().size(), cuerpo_crudo, headers])
		emit_signal("registro_sin_sesion")
	else:
		var msg : String = "No se pudo crear la cuenta."
		if datos is Dictionary:
			msg = datos.get("error_description", datos.get("msg", datos.get("message", msg)))
		# La base rechaza dominios de correo no permitidos y Supabase lo
		# reporta como "Database error ..." — un mensaje inútil para el
		# estudiante. El formulario ya valida el dominio antes de llamar
		# aquí (ver SceneLogin._validar_email), así que si esto se dispara
		# es porque alguien se saltó esa validación (llamada directa a la
		# API, por ejemplo) — mismo mensaje claro de todas formas.
		if msg.contains("Database error"):
			msg = "No pudimos crear la cuenta con ese correo. Revisá que sea @urbe.edu o un correo personal válido."
		emit_signal("registro_fallido", msg)


func _procesar_verificar_codigo(code: int, datos: Variant) -> void:
	if code == 200 and datos is Dictionary and datos.has("access_token"):
		_recovery_token = datos.get("access_token", "")
		emit_signal("codigo_verificado")
	else:
		var msg : String = "Código incorrecto o vencido."
		if datos is Dictionary:
			msg = datos.get("error_description", datos.get("msg", msg))
		emit_signal("codigo_fallido", msg)


func _procesar_nueva_contrasena(code: int, datos: Variant) -> void:
	if code in [200, 201]:
		_recovery_token = ""
		emit_signal("contrasena_actualizada")
	else:
		var msg : String = "No se pudo actualizar la contraseña."
		if datos is Dictionary:
			msg = datos.get("error_description", datos.get("msg", msg))
		emit_signal("actualizar_contrasena_fallido", msg)


func _procesar_recuperar(code: int, datos: Variant) -> void:
	# Supabase devuelve 200 con body vacío {} al enviar el correo correctamente
	if code == 200:
		emit_signal("recuperacion_enviada")
	else:
		var msg : String = "No se pudo enviar el correo."
		if datos is Dictionary:
			msg = datos.get("error_description", datos.get("msg", msg))
		emit_signal("recuperacion_fallida", msg)


func _procesar_modulos(code: int, datos: Variant) -> void:
	if code == 200 and datos is Array:
		emit_signal("modulos_cargados", datos)
	else:
		emit_signal("error_red", "No se pudieron cargar los módulos.")


func _procesar_progreso(code: int, datos: Variant) -> void:
	if code == 200 and datos is Array:
		emit_signal("progreso_cargado", datos)
	else:
		emit_signal("error_red", "No se pudo cargar el progreso.")


func _procesar_misiones_estudiante(code: int, datos: Variant) -> void:
	if code == 200 and datos is Array:
		emit_signal("misiones_estudiante_cargadas", datos)
	else:
		emit_signal("error_red", "No se pudo cargar el progreso por misión.")


func _procesar_crear_solicitud_qr(code: int, ctx: Dictionary) -> void:
	var token := str(ctx.get("token", ""))
	if code in [200, 201]:
		emit_signal("solicitud_qr_creada", token)
	else:
		emit_signal("solicitud_qr_creada_fallida", token)


func _procesar_consultar_solicitud_qr(code: int, datos: Variant, ctx: Dictionary) -> void:
	var token := str(ctx.get("token", ""))
	if code == 200 and datos is Array and datos.size() > 0:
		var fila : Dictionary = datos[0]
		emit_signal("solicitud_qr_estado", token, bool(fila.get("escaneado", false)))
	else:
		emit_signal("solicitud_qr_estado", token, false)


func _procesar_guardar(code: int, datos: Variant, ctx: Dictionary) -> void:
	var mision_id := str(ctx.get("mision_id", ""))
	var xp_local  := int(ctx.get("xp_local", 0))
	if code in [200, 201] and datos is Dictionary:
		var xp_otorgada  : int  = int(datos.get("xp_otorgada", 0))
		var ya_registrada: bool = bool(datos.get("ya_registrada", false))
		emit_signal("progreso_guardado", mision_id, xp_otorgada, ya_registrada, xp_otorgada - xp_local)
	else:
		# La RPC devuelve códigos de error propios (42501/22023/23503) que no
		# necesitamos distinguir del lado del cliente todavía: en todos los
		# casos el XP que _aplicar_xp() ya sumó de forma optimista hay que
		# revertirlo, porque el servidor no lo otorgó.
		emit_signal("error_red", "No se pudo guardar el progreso.")
		emit_signal("progreso_guardado_fallido", mision_id, xp_local)


func _procesar_evento(code: int) -> void:
	# Silencioso a propósito: el evento ya quedó en el log local pase lo
	# que pase con la red, así que un fallo remoto no debe interrumpir
	# ni alertar al jugador — solo queda en consola para depurar.
	if not (code in [200, 201]):
		print("SupabaseManager: no se pudo sincronizar un evento de aprendizaje (código %d), queda en el log local." % code)


func _procesar_ranking(code: int, datos: Variant) -> void:
	if code == 200 and datos is Array:
		# Agrupa xp por user_id del lado del cliente
		var totales : Dictionary = {}
		for fila in datos:
			if fila is not Dictionary: continue
			var uid : String = str(fila.get("user_id", ""))
			var xp  : int    = int(fila.get("xp_ganada", 0))
			totales[uid] = int(totales.get(uid, 0)) + xp
		# Convierte a array ordenado
		var lista : Array = []
		for uid in totales.keys():
			lista.append({"user_id": uid, "xp_total": totales[uid],
						  "nombre": uid.left(8) + "…"})
		lista.sort_custom(func(a, b): return int(a["xp_total"]) > int(b["xp_total"]))
		emit_signal("ranking_cargado", lista)
	else:
		emit_signal("error_red", "No se pudo cargar el ranking.")


# ── Headers ───────────────────────────────────────────────────
func _headers_anon() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY
	])

func _headers_auth() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"apikey: "               + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + jwt_token,
		"Prefer: return=representation"
	])
