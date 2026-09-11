# ============================================================
# NivelManager.gd — URBE Rangers: Eco-Quest
# Autoload global que gestiona el sistema de niveles basado
# en los 6 módulos de UI GreenMetric.
# Nivel 1 = Infraestructura y Entorno
# Nivel 2 = Energía y Cambio Climático
# ============================================================
extends Node

signal nivel_completado(nivel: int)
signal mision_nivel_completada(nivel: int, mision_id: String)

# ── Configuración por nivel ──────────────────────────────────
const NOMBRES_NIVEL : Array[String] = [
	"",
	"Infraestructura y Entorno",
	"Energía y Cambio Climático",
	"Manejo de Residuos",
	"Uso del Agua",
	"Transporte Sostenible",
	"Educación e Investigación",
]

const ICONOS_NIVEL : Array[String] = [
	"", "🌿", "⚡", "♻", "💧", "🚲", "📚"
]

# Cuántas misiones de campo tiene cada nivel
const TOTAL_MISIONES : Dictionary = {
	1: 6,   # 3 zonas click (plaza) + 3 zonas drag (áreas verdes)
	2: 8,   # 6 LED + 2 paneles solares
	3: 6,   # 6 puntos de donación y reciclaje
	4: 8,   # 6 llaves abiertas + 2 captación de agua de lluvia
	5: 8,   # 6 decisiones de movilidad + 2 bicicleteros
	6: 4,   # malla_verde + comite_ambiental + semana_verde + informe_final
}

const XP_POR_MISION : Dictionary  = {1: 40, 2: 50, 3: 35, 4: 35, 5: 35, 6: 70}
const EC_POR_MISION : Dictionary  = {1: 15, 2: 20, 3: 12, 4: 12, 5: 12, 6: 20}
const XP_NIVEL_BONUS : Dictionary = {1: 150, 2: 250, 3: 180, 4: 180, 5: 180, 6: 200}

const SAVE_PATH_TPL : String = "user://nivel_progreso_%s.json"

# ── Estado ───────────────────────────────────────────────────
var nivel_actual : int = 1
# {nivel_str: {mision_id: bool}}
var _misiones : Dictionary = {}
# {mision_id: Dictionary} — qué eligió el jugador en misiones con decisiones
# propias (Nivel 6: Malla Verde, Comité, Semana Verde), para citarlas
# textualmente en el informe final. No confundir con _misiones (solo bool).
var _detalles : Dictionary = {}

# uid de Supabase de la cuenta activa. El save es POR CUENTA (ver
# iniciar_sesion) — antes era un único archivo global
# (user://nivel_progreso.json) cargado sin importar quién iniciara sesión,
# así que una cuenta nueva en una máquina con progreso previo arrancaba
# viendo todo como completado. Vacío significa "todavía sin cuenta
# vinculada" (pantalla de login) — _cargar()/_guardar() no tocan disco
# en ese estado.
var _uid_activo : String = ""

# Resultado de la carga inicial, consultable UNA vez por quien construya el
# HUD ("ok" | "recuperado" | "nuevo_corrupto") — antes, si el JSON se
# corrompía (cierre abrupto a mitad de escritura, disco lleno), _cargar()
# fallaba en silencio y el jugador perdía todo el progreso sin aviso.
# No es señal: se consulta con obtener_estado_carga() después de
# iniciar_sesion().
var _estado_carga : String = "ok"


func _ready() -> void:
	add_to_group("nivel_manager")
	# Ya no se autocarga acá: este autoload existe antes de que haya
	# sesión (arranca con la pantalla de login). Ver iniciar_sesion().


# ── API pública ───────────────────────────────────────────────

# Ata el guardado local a la cuenta que acaba de loguear/registrarse y
# carga (o crea) su archivo. Llamar SIEMPRE al entrar a la partida —
# tanto en el primer login del proceso como al volver a "Salir al
# Login" y entrar con otra cuenta sin reiniciar el juego — para no
# arrastrar en memoria el estado de la cuenta anterior.
func iniciar_sesion(uid: String) -> void:
	_uid_activo  = uid
	nivel_actual = 1
	_misiones    = {}
	_detalles    = {}
	_estado_carga = "ok"
	_cargar()


# Mezcla (unión, nunca reemplaza) lo que el servidor reporta en
# misiones_estudiante hacia el estado local — la fuente de verdad real
# cuando el archivo local no existe (máquina nueva) o quedó atrás. Cada
# fila es {"modulo_id": int, "mision_id": String}.
#
# A propósito NO emite mision_nivel_completada/nivel_completado (no es
# "completar" nada, es reconstruir algo ya ganado — emitir esas señales
# acá dispararía popups de misión y celebraciones de nivel fantasma en
# cada login) ni vuelve a llamar guardar_progreso (la RPC lo tolera por
# ser idempotente, pero es tráfico de red que no hace falta).
func repoblar_desde_servidor(filas: Array) -> void:
	for fila in filas:
		if not (fila is Dictionary): continue
		var modulo_id_raw = fila.get("modulo_id")
		var mision_id := str(fila.get("mision_id", ""))
		if modulo_id_raw == null or mision_id.is_empty(): continue
		var s := str(int(modulo_id_raw))
		if not _misiones.has(s):
			_misiones[s] = {}
		(_misiones[s] as Dictionary)[mision_id] = true
	# Recalcula nivel_actual como el primer nivel, en orden, que todavía
	# no está completo — mismo criterio que usa completar_mision().
	var n := 1
	while n < 6 and nivel_completo(n):
		n += 1
	nivel_actual = n
	_guardar()


func nivel_desbloqueado(n: int) -> bool:
	if n == 1: return true
	return nivel_completo(n - 1)

func nivel_completo(n: int) -> bool:
	var s := str(n)
	var total : int = TOTAL_MISIONES.get(n, 0)
	if total == 0: return false
	if not _misiones.has(s): return false
	var completadas := 0
	for v in (_misiones[s] as Dictionary).values():
		if v: completadas += 1
	return completadas >= total

func pct_nivel(n: int) -> float:
	var s := str(n)
	var total : int = TOTAL_MISIONES.get(n, 0)
	if total == 0: return 0.0
	if not _misiones.has(s): return 0.0
	var completadas := 0
	for v in (_misiones[s] as Dictionary).values():
		if v: completadas += 1
	return float(completadas) / float(total)

func mision_completada_q(nivel: int, mision_id: String) -> bool:
	var s := str(nivel)
	if not _misiones.has(s): return false
	return (_misiones[s] as Dictionary).get(mision_id, false)

func guardar_detalle(mision_id: String, detalle: Dictionary) -> void:
	_detalles[mision_id] = detalle
	_guardar()

func obtener_detalle(mision_id: String) -> Dictionary:
	return _detalles.get(mision_id, {})

func completar_mision(nivel: int, mision_id: String) -> void:
	if mision_completada_q(nivel, mision_id): return
	var s := str(nivel)
	if not _misiones.has(s):
		_misiones[s] = {}
	(_misiones[s] as Dictionary)[mision_id] = true
	_guardar()
	mision_nivel_completada.emit(nivel, mision_id)
	if nivel_completo(nivel):
		nivel_completado.emit(nivel)
		if nivel == nivel_actual and nivel < 6:
			nivel_actual = nivel + 1
			_guardar()

# ── Persistencia ─────────────────────────────────────────────

func obtener_estado_carga() -> String:
	return _estado_carga


# Ruta de un archivo de estado local ligado a la cuenta activa, para
# cosas como "ya vio el tutorial" o "ya vio esta pista". Son preferencias
# POR ESTUDIANTE, no por computadora: en una sala de computación
# compartida, un archivo global hace que solo el primer estudiante que se
# siente vea el tutorial y todos los demás entren sin ninguna explicación
# (es el mismo bug que tenía el progreso antes del guardado por cuenta).
func ruta_usuario(nombre: String) -> String:
	if _uid_activo.is_empty():
		# Sin sesión — pasa al correr la escena del mapa directo desde el
		# editor. En uso real siempre hay login antes de llegar acá, así
		# que este caso es solo comodidad de desarrollo: se usa el archivo
		# global de siempre.
		return "user://%s.dat" % nombre
	return "user://%s_%s.dat" % [nombre, _uid_activo]


func _ruta_save() -> String:
	if _uid_activo.is_empty(): return ""
	return SAVE_PATH_TPL % _uid_activo

func _ruta_backup() -> String:
	var s := _ruta_save()
	return "" if s.is_empty() else (s + ".bak")


# Intenta cargar y aplicar el JSON de `path`. Devuelve false ante cualquier
# fallo (archivo ausente, vacío, JSON inválido, forma inesperada) sin tocar
# el estado en memoria — así una lectura fallida del save principal no dañe
# nada antes de poder intentar con el backup.
func _intentar_cargar_desde(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return false
	var txt := f.get_as_text()
	f.close()
	if txt.is_empty(): return false
	var json := JSON.new()
	if json.parse(txt) != OK: return false
	var data = json.get_data()
	if not (data is Dictionary): return false
	nivel_actual = int(data.get("nivel_actual", 1))
	var mis = data.get("misiones", {})
	if mis is Dictionary: _misiones = mis
	var det = data.get("detalles", {})
	if det is Dictionary: _detalles = det
	return true


func _cargar() -> void:
	var save_path := _ruta_save()
	if save_path.is_empty(): return   # sin cuenta vinculada todavía
	var backup_path := _ruta_backup()
	if _intentar_cargar_desde(save_path):
		_estado_carga = "ok"
		return
	if not FileAccess.file_exists(save_path):
		_estado_carga = "ok"   # partida nueva de verdad, no es un fallo
		return
	# El save existía pero no se pudo leer/parsear — intenta el respaldo
	# antes de resignarse a perder el progreso.
	if _intentar_cargar_desde(backup_path):
		_estado_carga = "recuperado"
		push_warning("NivelManager: %s corrupto, progreso recuperado desde backup." % save_path)
		return
	_estado_carga = "nuevo_corrupto"
	push_warning("NivelManager: %s y su backup están corruptos, se reinicia el progreso." % save_path)


func _guardar() -> void:
	var save_path := _ruta_save()
	if save_path.is_empty(): return   # sin cuenta vinculada todavía
	var backup_path := _ruta_backup()
	# Antes de sobrescribir, respalda el save actual (solo si es válido) para
	# poder recuperarlo si ESTA escritura se corrompe a mitad de camino.
	if FileAccess.file_exists(save_path):
		var actual := FileAccess.open(save_path, FileAccess.READ)
		if actual:
			var txt_actual := actual.get_as_text()
			actual.close()
			if not txt_actual.is_empty():
				var chk := JSON.new()
				if chk.parse(txt_actual) == OK:
					var bak := FileAccess.open(backup_path, FileAccess.WRITE)
					if bak:
						bak.store_string(txt_actual)
						bak.close()
	var data := {"nivel_actual": nivel_actual, "misiones": _misiones, "detalles": _detalles}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if not f: return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

# ── Debug ─────────────────────────────────────────────────────
func reset_progreso() -> void:
	nivel_actual = 1
	_misiones = {}
	_detalles = {}
	_estado_carga = "ok"
	_guardar()
	var backup_path := _ruta_backup()
	if not backup_path.is_empty() and FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
