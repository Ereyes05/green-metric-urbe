# Nivel 5 nuevo — Plan de Movilidad — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el Nivel 5 (seis escenarios en una caseta + bicicleteros de "Continuar") por un Plan de Movilidad con presupuesto, decisiones repartidas por el campus con regla Mixta, bicicleteros con decisión de tipo, Consejo Universitario con objeciones y cruces a otras categorías.

**Architecture:** Lugares con nombre en `scenes/mapa/lugares_campus.gd`. Contenido en `plan_movilidad_datos.gd` (espejo de `catalogo_decisiones`/`catalogo_sinergias`) y reglas puras en `plan_movilidad.gd` (probadas sin interfaz). Un punto genérico (`punto_movilidad.gd`), tres paneles construidos con `ui_movilidad.gd` sobre `hud_tema.gd`, un nodo de dibujo de cambios del mapa y un controlador (`nivel5_movilidad.gd`) con dependencias inyectadas que SceneMapaMundo crea en lugar de los cuatro scripts viejos. Servidor: solo filas de catálogo nuevas (las funciones de A no cambian).

**Tech Stack:** Godot 4.7 GDScript (CanvasLayer, Area2D, `_draw`), Supabase Postgres (catálogos + funciones SECURITY DEFINER existentes), pruebas como escenas headless.

**Spec:** `docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md` (vinculante). Alto nivel: `docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md` §4, §6, §7, §9.

## Global Constraints

- Godot 4.7: `GODOT="/c/Users/edward/OneDrive/Desktop/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe"`. Pruebas: `timeout 120 "$GODOT" --headless --path . res://tests/<t>.tscn; echo exit=$?` (sin timeout un error de script cuelga el proceso). exit=0 = pasa. Buscar además `SCRIPT ERROR` / `Parse Error` en la salida: un error de script dentro de `_ready` no siempre cambia el código de salida.
- Todo script nuevo se commitea con su `.gd.uid` (Godot lo genera al correr cualquier escena con `--headless --path .`; si no aparece, `"$GODOT" --headless --path . --import`). Los scripts borrados se borran con su `.gd.uid`.
- Sin `class_name` nuevos: `const X := preload("res://...")`.
- Pruebas contra la base de producción (project id `ikohikbpvtbvsgyumvbr`) solo en bloques `DO` que terminan en `raise exception 'PRUEBA_OK'`; cualquier otro error = falla. Nunca dejar datos de prueba.
- Migraciones: SOLO en la Task 3 y SOLO con la herramienta MCP `apply_migration`. La migración `nivel5_plan_movilidad_misiones` (cambio de misiones del catálogo) **NO se aplica en este plan** (spec R10, §10.2): solo se prueba en un bloque `DO`.
- Nada de push, merge, publicación ni re-export web. No tocar `docs/juego/`.
- Interfaz: tokens de `scenes/ui/hud_tema.gd` a través de `scenes/misiones/ui_movilidad.gd`. **Ningún `Color(` literal en los tres paneles** (las pruebas lo verifican). Emoji solo de `HUD_TEMA.EMOJIS_HUD`. El dibujo del mapa (`punto_movilidad.gd` ícono, `cambios_movilidad.gd`) puede usar colores propios como `mapa_campus.gd`.
- Ubicación: nada del Nivel 5 lleva coordenadas propias; todo sale de `lugares_campus.gd` (+ desplazamiento chico).
- Textos para el jugador en español con **tuteo** ("tienes", "elige", "puedes"; decisión del usuario 7): nunca "tenés", "elegí", "podés". Commits en español, terminando con línea en blanco + `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`. `git add` por ruta, nunca `-A`; si falla por `index.lock` (tareas en paralelo), esperar unos segundos y reintentar.
- El contenido de `plan_movilidad_datos.gd` es copia literal de la spec §6–7. Si una tarea detecta diferencia entre spec y código del plan, manda el código del plan y se reporta.
- Tareas en paralelo pueden correr Godot a la vez: si aparece un error de importación/`.godot` no relacionado con la tarea, volver a correr la prueba.
- Pruebas existentes que deben seguir pasando al final de cada tarea que las afecte: `test_compila`, `test_niveles`, `test_rangos`, `test_puntaje`, `test_simulador`, `test_hud_*`, `test_mapa_avance`.

## Rulings de diseño tomados al escribir el plan

- **Paneles no persisten:** los paneles modifican el objeto `plan` en memoria (decisión: tras la respuesta del servidor; Consejo: `plan.presentar`) y avisan con señales; guardar, completar misiones, telemetría y red son del controlador.
- **Oficina no modifica el plan:** emite `encargo_aceptado` y el controlador pone `plan.encargo_aceptado = true`.
- **Registro inyectable:** `panel_decision.registrar : Callable` (el controlador pasa `PuntajeManager.registrar_decision`); sin Callable válido se comporta como `sin_sesion`.
- **Respuesta:** el panel escucha `decision_resuelta` y descarta respuestas que no correspondan a la decisión/opción en espera.
- **Un script de punto** para los 4 tipos, grupo `punto_movilidad`, propiedad `_jugador_cerca` (la usa el selector del más cercano de SceneMapaMundo).
- **Cruces:** se registran después de completar `tr_consejo` (la cola de SupabaseManager es FIFO, así `guardar_progreso` llega antes).
- **Sin re-pago (spec §11.1):** `NivelManager.legado_completo(5)` decide; el controlador emite `mision_completada(id, 0, 0)` y `SceneMapaMundo` interpreta `xp <= 0 and ec <= 0` como "sin pago": no da XP, no llama `acreditar_mision`, no paga el bono de nivel, pero siempre llama `guardar_progreso` (con xp 0).

## Olas (paralelismo)

| Ola | Tareas en paralelo (archivos disjuntos) | Requiere |
|---|---|---|
| 1 | 1, 2, 3, 4, 5 | — |
| 2 | 6, 7 | 6 ← 2 · 7 ← 1, 5 |
| 3 | 8, 9, 10 | 8 y 9 ← 5, 6 · 10 ← 1, 6 |
| 4 | 11 | 3, 4, 7, 8, 9, 10 |
| 5 | 12 | 4, 11 |
| 6 | 13 | 12 |

La Task 3 necesita las herramientas MCP de Supabase (`apply_migration`, `execute_sql`, `get_advisors`).

## Formato común de las pruebas

Cada prueba nueva tiene su `.tscn` con este contenido (cambiando nombre de nodo y ruta):

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/test_XXX.gd" id="1"]

[node name="TestXXX" type="Node"]
script = ExtResource("1")
```

y usa el mismo `_check`:

```gdscript
var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)
```

(En cada task el código de prueba se da completo, incluido este bloque.)

---

### Task 1: Lugares con nombre del campus  *(Ola 1, paralela)*

**Files:**
- Create: `scenes/mapa/lugares_campus.gd`
- Test: `tests/test_lugares_campus.gd`, `tests/test_lugares_campus.tscn`

**Interfaces:**
- Produces (`const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")`):
  - `LUGARES.LUGARES : Dictionary` (String → Vector2), claves: `oficina_movilidad`, `bicicletero_bloque_e`, `bicicletero_cafetin`, `garita_m5`, `estacionamiento_m5`, `lote_este`, `parada_rectorado`, `porton_vehicular`, `zona_mantenimiento`, `rectorado`.
  - `LUGARES.existe(lugar: String) -> bool`
  - `LUGARES.posicion(lugar: String, desplazamiento: Vector2 = Vector2.ZERO) -> Vector2`

- [ ] **Step 1: Write the failing test**

`tests/test_lugares_campus.tscn` (nodo `TestLugaresCampus`, script `res://tests/test_lugares_campus.gd`).

`tests/test_lugares_campus.gd`:
```gdscript
# Prueba del registro de lugares con nombre y chequeo de solapamientos
# contra los puntos que ya existen en el mapa. Volver a correrla cada vez
# que cambie una coordenada (mapa nuevo).
# Correr: $GODOT --headless --path . res://tests/test_lugares_campus.tscn
extends Node

const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")
const MINIMO := 55.0
# Constantes DATOS_* de SceneMapaMundo que no son puntos instanciados en el
# mapa, o que este registro reemplaza (Nivel 5 viejo).
const IGNORADAS := ["DATOS_ZONAS_VERDES", "DATOS_CONTENEDORES",
	"DATOS_OFICINA_MOVILIDAD", "DATOS_PUNTOS_BICICLETERO"]

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _puntos_existentes() -> Array:
	var out := []
	var script : Script = load("res://scenes/mapa/SceneMapaMundo.gd")
	var consts : Dictionary = script.get_script_constant_map()
	for nombre in consts.keys():
		var n := str(nombre)
		if not n.begins_with("DATOS_") or n in IGNORADAS:
			continue
		var arr = consts[nombre]
		if not (arr is Array):
			continue
		for d in arr:
			if d is Dictionary and d.has("pos"):
				out.append({"id": str(d.get("id", d.get("nombre", n))), "pos": d["pos"]})
	var mapa : Node = script.new()
	for d in mapa.DATOS_NPCS:
		out.append({"id": "npc:" + str(d.get("nombre", "")), "pos": d["pos"]})
	mapa.free()
	return out


func _edificios() -> Array:
	var out := []
	var col : Script = load("res://scenes/mapa/colision_tilemap.gd")
	for e in col.get_script_constant_map()["EDIFICIOS"]:
		out.append(Rect2(float(e[0]) - float(e[2]) * 0.5, float(e[1]) - float(e[3]) * 0.5,
			float(e[2]), float(e[3])))
	return out


func _ready() -> void:
	print("test_lugares_campus")
	var claves := ["oficina_movilidad", "bicicletero_bloque_e", "bicicletero_cafetin",
		"garita_m5", "estacionamiento_m5", "lote_este", "parada_rectorado",
		"porton_vehicular", "zona_mantenimiento", "rectorado"]
	for c in claves:
		_check(LUGARES.existe(c), "existe %s" % c)
	_check(LUGARES.LUGARES.size() == claves.size(), "10 lugares")
	_check(not LUGARES.existe("no_existe"), "lugar desconocido no existe")
	_check(LUGARES.posicion("rectorado") == Vector2(720, 560), "posición del Rectorado")
	_check(LUGARES.posicion("rectorado", Vector2(10, -5)) == Vector2(730, 555), "desplazamiento se suma")
	# Heredadas del Nivel 5 viejo (mismas coordenadas que hoy).
	_check(LUGARES.posicion("oficina_movilidad") == Vector2(600, 100), "oficina en su lugar actual")
	_check(LUGARES.posicion("bicicletero_bloque_e") == Vector2(1020, 460), "bicicletero Bloque E actual")
	_check(LUGARES.posicion("bicicletero_cafetin") == Vector2(200, 360), "bicicletero Cafetín actual")

	var existentes := _puntos_existentes()
	_check(existentes.size() >= 40, "se leyeron los puntos existentes (%d)" % existentes.size())
	var edificios := _edificios()
	var nombres : Array = LUGARES.LUGARES.keys()
	for i in nombres.size():
		var nombre : String = nombres[i]
		var p : Vector2 = LUGARES.LUGARES[nombre]
		_check(p.x >= 0 and p.x <= 1408 and p.y >= 0 and p.y <= 768, "%s dentro del mapa" % nombre)
		var peor := INF
		var cual := ""
		for e in existentes:
			var d := p.distance_to(e["pos"])
			if d < peor:
				peor = d
				cual = e["id"]
		_check(peor >= MINIMO, "%s a %.0f px de %s (mínimo %.0f)" % [nombre, peor, cual, MINIMO])
		for j in range(i + 1, nombres.size()):
			var d2 := p.distance_to(LUGARES.LUGARES[nombres[j]])
			_check(d2 >= MINIMO, "%s a %.0f px de %s" % [nombre, d2, nombres[j]])
		var dentro := false
		for r in edificios:
			if (r as Rect2).has_point(p):
				dentro = true
		_check(not dentro, "%s fuera de edificios" % nombre)

	print("test_lugares_campus: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_lugares_campus.tscn; echo exit=$?`
Expected: error de preload (no existe `lugares_campus.gd`), exit≠0.

- [ ] **Step 3: Implement**

`scenes/mapa/lugares_campus.gd`:
```gdscript
# ============================================================
# lugares_campus.gd — registro único de lugares con nombre del campus.
# Todo lo nuevo (Nivel 5 Plan de Movilidad, minijuegos del proyecto C) se
# ubica por LUGAR + un desplazamiento chico, nunca con coordenadas en el
# código de la misión.
#
# PROVISIONAL: coordenadas del mapa actual (1408×768, mapa_campus.gd). El
# mapa se está rediseñando aparte; cuando llegue, reubicar = editar SOLO
# este archivo y volver a correr tests/test_lugares_campus.tscn (chequeo de
# solapamientos contra los puntos existentes).
# Diseño: docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md §3
# ============================================================
extends RefCounted

const LUGARES : Dictionary = {
	# Mismas coordenadas que tenían los puntos del Nivel 5 viejo.
	"oficina_movilidad":    Vector2(600, 100),   # camino norte, frente al Patio
	"bicicletero_bloque_e": Vector2(1020, 460),  # plaza entre Bloque E y Rectorado
	"bicicletero_cafetin":  Vector2(200, 360),   # borde este del M5, camino al Cafetín
	# Nuevos (Plan de Movilidad).
	"garita_m5":            Vector2(60, 330),    # entrada vehicular del M5
	"estacionamiento_m5":   Vector2(110, 240),   # zona norte del M5
	"lote_este":            Vector2(1340, 710),  # lote poco usado detrás de Estudios a Distancia
	"parada_rectorado":     Vector2(1060, 752),  # Av. URBE frente a la esquina del Rectorado
	"porton_vehicular":     Vector2(600, 752),   # portón de la Av. URBE
	"zona_mantenimiento":   Vector2(1190, 715),  # patio de servicios, sureste
	"rectorado":            Vector2(720, 560),   # entrada oeste del Rectorado (Consejo)
}


static func existe(lugar: String) -> bool:
	return LUGARES.has(lugar)


static func posicion(lugar: String, desplazamiento: Vector2 = Vector2.ZERO) -> Vector2:
	if not LUGARES.has(lugar):
		push_error("lugares_campus: lugar desconocido '%s'" % lugar)
		return Vector2.ZERO
	return LUGARES[lugar] + desplazamiento
```

- [ ] **Step 4: Run test to verify it passes**

Run: igual que Step 2. Expected: exit=0, ninguna `FALLA`.

- [ ] **Step 5: Commit**

```bash
git add scenes/mapa/lugares_campus.gd scenes/mapa/lugares_campus.gd.uid tests/test_lugares_campus.gd tests/test_lugares_campus.gd.uid tests/test_lugares_campus.tscn
git commit -m "mapa: lugares con nombre del campus y chequeo de solapamientos

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Datos del Plan de Movilidad  *(Ola 1, paralela)*

**Files:**
- Create: `scenes/misiones/plan_movilidad_datos.gd`
- Test: `tests/test_plan_datos.gd`, `tests/test_plan_datos.tscn`

**Interfaces:**
- Produces (`const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")`):
  - Constantes: `CATEGORIA` (5), `PRESUPUESTO` (100), `DECISION_CONSEJO` ("tr_consejo"), `ENCARGO: String`, `ACEPTACION_TEXTO`, `ACEPTACION_PESO`, `NOMBRE_LUGAR`, `SINERGIAS` (id → `{categoria, puntos, efecto}`), `CONSEJO_OPCIONES` (Array de `{id, aciertos, puntos, nombre}`), `MISIONES` (9 ids), `DECISIONES` (Array de 8 `{id, tipo, lugar, indicador, titulo, contexto, pregunta, opciones}`; opción = `{id, corto, texto, costo:int, puntos:float, contraproducente:bool, aceptacion:String ("" si contraproducente), explicacion, sinergia:String}`), `OBJECIONES` (`"decision:opcion"` → `{texto, argumentos: [{texto, correcto, explicacion}×3]}`).
  - Estáticas: `decision(id) -> Dictionary`, `opcion(decision_id, opcion_id) -> Dictionary`, `ids_decisiones() -> Array`, `mejor_opcion(decision_id) -> String`, `objecion(decision_id, opcion_id) -> Dictionary`, `calificacion(aciertos: int) -> Dictionary`, `texto_sinergia(accion_id) -> String`.

- [ ] **Step 1: Write the failing test**

`tests/test_plan_datos.tscn` (nodo `TestPlanDatos`, script `res://tests/test_plan_datos.gd`).

`tests/test_plan_datos.gd`:
```gdscript
# Prueba de consistencia del contenido del Plan de Movilidad (spec §5–7).
# Correr: $GODOT --headless --path . res://tests/test_plan_datos.tscn
extends Node

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_plan_datos")
	var re := RegEx.new()
	re.compile("^[a-z0-9_]{1,60}$")
	_check(DATOS.DECISIONES.size() == 8, "8 decisiones (6 + 2 bicicleteros)")
	var suma_mejores := 0.0
	var costo_mejor := 0
	var costo_caras := 0
	var costo_baratas := 0
	var mejor_no_es_la_mas_cara := 0
	for d in DATOS.DECISIONES:
		var id : String = d["id"]
		_check(re.search(id) != null, "%s: id válido" % id)
		_check(d["tipo"] in ["decision", "bicicletero"], "%s: tipo válido" % id)
		for campo in ["titulo", "lugar", "indicador", "contexto", "pregunta"]:
			_check(str(d.get(campo, "")) != "", "%s: %s no vacío" % [id, campo])
		_check(DATOS.NOMBRE_LUGAR.has(d["lugar"]), "%s: lugar con nombre legible" % id)
		var ops : Array = d["opciones"]
		_check(ops.size() == 3, "%s: 3 opciones" % id)
		var contras := 0
		var max_costo := -1
		var min_costo := 1000
		var id_mas_cara := ""
		for o in ops:
			var oid : String = o["id"]
			_check(re.search(oid) != null, "%s:%s id válido" % [id, oid])
			for campo in ["texto", "corto", "explicacion"]:
				_check(str(o.get(campo, "")) != "", "%s:%s %s no vacío" % [id, oid, campo])
			if o["contraproducente"]:
				contras += 1
				_check(is_equal_approx(float(o["puntos"]), 0.0), "%s:%s contraproducente vale 0" % [id, oid])
				_check(DATOS.objecion(id, oid).is_empty(), "%s:%s contraproducente sin objeción" % [id, oid])
			else:
				_check(o["aceptacion"] in DATOS.ACEPTACION_PESO, "%s:%s aceptación válida" % [id, oid])
				if int(o["costo"]) > max_costo:
					max_costo = int(o["costo"])
					id_mas_cara = oid
				min_costo = mini(min_costo, int(o["costo"]))
				var obj := DATOS.objecion(id, oid)
				_check(str(obj.get("texto", "")) != "", "%s:%s tiene objeción" % [id, oid])
				var args : Array = obj.get("argumentos", [])
				var correctos := 0
				for a in args:
					if a["correcto"]:
						correctos += 1
					_check(str(a["texto"]) != "" and str(a["explicacion"]) != "", "%s:%s argumento completo" % [id, oid])
				_check(args.size() == 3 and correctos == 1, "%s:%s 3 argumentos, 1 correcto" % [id, oid])
			var s := str(o.get("sinergia", ""))
			if s != "":
				_check(DATOS.SINERGIAS.has(s), "%s:%s sinergia %s existe" % [id, oid, s])
		_check(contras == 1, "%s: exactamente 1 contraproducente" % id)
		var mejor := DATOS.mejor_opcion(id)
		suma_mejores += float(DATOS.opcion(id, mejor)["puntos"])
		costo_mejor += int(DATOS.opcion(id, mejor)["costo"])
		costo_caras += max_costo
		costo_baratas += min_costo
		if mejor != id_mas_cara:
			mejor_no_es_la_mas_cara += 1
	_check(is_equal_approx(suma_mejores, 4.0), "mejores opciones suman 4,00 (%.2f)" % suma_mejores)
	var max_consejo := 0.0
	for c in DATOS.CONSEJO_OPCIONES:
		max_consejo = maxf(max_consejo, float(c["puntos"]))
	_check(is_equal_approx(suma_mejores + max_consejo, 5.0), "mejores + Consejo = 5,00")
	_check(costo_mejor == DATOS.PRESUPUESTO, "plan de mayor puntaje cuesta el presupuesto (%d)" % costo_mejor)
	_check(costo_caras == 162, "opción válida más cara por decisión suma 162 (%d)" % costo_caras)
	_check(costo_baratas == 74 and costo_baratas <= DATOS.PRESUPUESTO, "plan válido más barato = 74 (%d)" % costo_baratas)
	_check(mejor_no_es_la_mas_cara == 4, "en 4 decisiones la mejor no es la más cara (%d)" % mejor_no_es_la_mas_cara)

	_check(DATOS.CONSEJO_OPCIONES.size() == 4, "4 calificaciones del Consejo")
	for n in 4:
		_check(DATOS.calificacion(n)["id"] == "consejo_%d" % n, "calificación con %d aciertos" % n)
	_check(DATOS.calificacion(9)["id"] == "consejo_3" and DATOS.calificacion(-1)["id"] == "consejo_0", "aciertos acotados")
	_check(float(DATOS.calificacion(3)["puntos"]) > float(DATOS.calificacion(2)["puntos"]), "más aciertos, más puntos")

	var esperadas : Array = DATOS.ids_decisiones() + [DATOS.DECISION_CONSEJO]
	_check(DATOS.MISIONES == esperadas, "MISIONES = decisiones + tr_consejo")
	_check(DATOS.SINERGIAS.size() == 4, "4 sinergias")
	for s in DATOS.SINERGIAS.keys():
		_check(re.search(s) != null and int(DATOS.SINERGIAS[s]["categoria"]) in [1, 2, 6], "sinergia %s válida" % s)
		_check(DATOS.texto_sinergia(s).contains(str(DATOS.SINERGIAS[s]["efecto"])), "texto de sinergia %s" % s)
	_check(DATOS.NOMBRE_LUGAR.has("oficina_movilidad") and DATOS.NOMBRE_LUGAR.has("rectorado"), "nombres de Oficina y Rectorado")
	_check(DATOS.opcion("tr_lote", "no_existe").is_empty() and DATOS.decision("x").is_empty(), "consultas inexistentes devuelven {}")
	_check(DATOS.ENCARGO.contains("100"), "el encargo menciona el presupuesto")

	print("test_plan_datos: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_plan_datos.tscn; echo exit=$?` → Expected: error de preload, exit≠0.

- [ ] **Step 3: Implement (parte 1: cabecera, constantes y decisiones)**

`scenes/misiones/plan_movilidad_datos.gd` — primera parte del archivo (la segunda, `OBJECIONES` y funciones, en el Step 4, a continuación en el mismo archivo):
```gdscript
# ============================================================
# plan_movilidad_datos.gd — contenido del Plan de Movilidad (Nivel 5).
# Decisiones, opciones, objeciones del Consejo y sinergias. Solo datos y
# consultas; las reglas están en plan_movilidad.gd.
#
# ESPEJO de public.catalogo_decisiones y public.catalogo_sinergias
# (sql/nivel5_plan_movilidad.sql): id, puntos, contraproducente y costo
# deben coincidir; tests/test_nivel5_movilidad.gd lo verifica leyendo el
# .sql. Si cambia uno, cambiar el otro con una migración nueva.
# Diseño: docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md §5–7
# Cifras de contexto ILUSTRATIVAS (datos mixtos, Tabla 16): validar con la
# Dirección de Sustentabilidad de URBE.
# ============================================================
extends RefCounted

const CATEGORIA := 5
const PRESUPUESTO := 100
const DECISION_CONSEJO := "tr_consejo"

const ENCARGO := "La Dirección de Sustentabilidad y el Rectorado te encargan un Plan de Movilidad para URBE, que vas a presentar ante el Consejo Universitario. Tienes un presupuesto de 100 puntos para seis decisiones repartidas por el campus (en el orden que quieras) y dos bicicleteros (necesitas el kit de la Tienda). Antes de elegir solo vas a ver el costo de cada opción: sus efectos se conocen al confirmar. Una opción contraproducente según GreenMetric resta 1 punto en Decisiones de Transporte, no gasta presupuesto y te deja reintentar. Cuando tengas todo listo, presenta el plan en el Rectorado."

const ACEPTACION_TEXTO : Dictionary = {
	"alta": "Aceptación alta", "media": "Aceptación media", "baja": "Aceptación baja",
}
const ACEPTACION_PESO : Dictionary = {"alta": 1, "media": 2, "baja": 3}

const NOMBRE_LUGAR : Dictionary = {
	"oficina_movilidad": "Oficina de Movilidad (camino norte)",
	"garita_m5": "Garita del Estacionamiento M5",
	"estacionamiento_m5": "Estacionamiento M5",
	"lote_este": "Lote detrás de Estudios a Distancia",
	"parada_rectorado": "Parada de la Av. URBE, frente al Rectorado",
	"porton_vehicular": "Portón vehicular de la Av. URBE",
	"zona_mantenimiento": "Patio de mantenimiento",
	"bicicletero_bloque_e": "Plaza entre el Bloque E y el Rectorado",
	"bicicletero_cafetin": "Borde del M5, camino al Cafetín",
	"rectorado": "Rectorado · Consejo Universitario",
}

const SINERGIAS : Dictionary = {
	"ciclovia_lote":             {"categoria": 1, "puntos": 1, "efecto": "🌿 Entorno +1"},
	"flota_electrica":           {"categoria": 2, "puntos": 1, "efecto": "⚡ Energía +1"},
	"dia_sin_carros_feria":      {"categoria": 6, "puntos": 1, "efecto": "📚 Educación +1"},
	"bicicletero_techado_solar": {"categoria": 2, "puntos": 1, "efecto": "⚡ Energía +1"},
}

const CONSEJO_OPCIONES : Array = [
	{"id": "consejo_0", "aciertos": 0, "puntos": 0.00, "nombre": "Aprobado con condiciones"},
	{"id": "consejo_1", "aciertos": 1, "puntos": 0.30, "nombre": "Aprobado con observaciones"},
	{"id": "consejo_2", "aciertos": 2, "puntos": 0.60, "nombre": "Aprobado"},
	{"id": "consejo_3", "aciertos": 3, "puntos": 1.00, "nombre": "Aprobado sin observaciones"},
]

# ESPEJO de NivelManager.MISIONES_NIVEL[5].
const MISIONES : Array = [
	"tr_permisos", "tr_lote", "tr_carpool", "tr_shuttle", "tr_dia_sin_carros",
	"tr_flota", "tr_bici_bloque_e", "tr_bici_cafetin", "tr_consejo",
]

# Orden = tablero de la Oficina y desempate de objeciones. Las opciones están
# en el orden en que se muestran (la mejor no está siempre en el mismo lugar).
const DECISIONES : Array = [
	{
		"id": "tr_permisos", "tipo": "decision", "lugar": "garita_m5", "indicador": "TR1",
		"titulo": "Permisos de estacionamiento",
		"contexto": "En la garita del Estacionamiento M5 se entregan los permisos anuales. Hoy cualquiera que lo pida recibe uno: hay más carros y motos con permiso que puestos, y en la hora pico de la mañana la cola llega hasta la avenida. GreenMetric (TR1) mide cuántos vehículos entran al campus por cada persona de la comunidad universitaria.",
		"pregunta": "¿Qué política de permisos llevas al plan?",
		"opciones": [
			{"id": "lectoras_de_placas", "corto": "Lectoras de placas",
			 "texto": "Instalar cámaras lectoras de placas y una barrera automática para que la entrada sea más rápida",
			 "costo": 24, "puntos": 0.25, "contraproducente": false, "aceptacion": "alta", "sinergia": "",
			 "explicacion": "Ordena la entrada y da datos reales de cuántos vehículos entran (útiles para reportar TR1), pero no reduce ni un carro: la cola se va, los vehículos se quedan. Mucho gasto para poco efecto en el indicador."},
			{"id": "pintar_mas_puestos", "corto": "Más puestos sobre la grama",
			 "texto": "Acabar con la cola pintando 80 puestos nuevos sobre la franja de grama que rodea el M5",
			 "costo": 14, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Más puestos atraen más carros (TR1 empeora), aumentan el área de estacionamiento en superficie (TR5) y quitan área verde que suma en Entorno. GreenMetric lo cuenta en contra."},
			{"id": "permiso_por_necesidad", "corto": "Permisos por necesidad",
			 "texto": "Dar permiso anual solo a quien vive lejos y sin transporte público, tiene movilidad reducida o comparte el carro; el resto entra con pase diario",
			 "costo": 8, "puntos": 0.60, "contraproducente": false, "aceptacion": "baja", "sinergia": "",
			 "explicacion": "Es una regla, no una obra: cuesta poco y baja directamente los vehículos por persona que mide TR1. Quien pierde su permiso anual se queja, por eso la aceptación es baja: hay que acompañarla con alternativas como la buseta y el carpool."},
		],
	},
	{
		"id": "tr_lote", "tipo": "decision", "lugar": "lote_este", "indicador": "TR5 · TR6",
		"titulo": "El lote poco usado",
		"contexto": "Detrás de Estudios a Distancia hay un lote de tierra y granzón con capacidad para 60 carros que casi nunca pasa de 15. Con lluvia se inunda y en sequía levanta polvo. GreenMetric premia reducir el área de estacionamiento en superficie (TR5) y tener un programa documentado para hacerlo (TR6).",
		"pregunta": "¿Qué haces con el lote?",
		"opciones": [
			{"id": "asfaltar_lote", "corto": "Asfaltar el lote",
			 "texto": "Asfaltarlo y demarcarlo para que por fin se use y descongestione el M5",
			 "costo": 16, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Convierte un lote poco usado en estacionamiento formal: sube el área de estacionamiento en superficie (TR5), va contra el programa de reducción (TR6) y el asfalto calienta y sella el suelo."},
			{"id": "ciclovia_arborizada", "corto": "Ciclovía con árboles",
			 "texto": "Cerrarlo a los carros y convertirlo en un tramo de ciclovía y caminería con árboles nativos de sombra, conectado al portón",
			 "costo": 22, "puntos": 0.60, "contraproducente": false, "aceptacion": "alta", "sinergia": "ciclovia_lote",
			 "explicacion": "Quita área de estacionamiento (TR5), queda como programa de reducción con fecha y metros (TR6) y la sombra hace posible caminar o pedalear con el calor de Maracaibo. Los árboles suman también en Entorno."},
			{"id": "plaza_de_eventos", "corto": "Explanada de eventos",
			 "texto": "Cerrarlo a los carros y dejarlo como explanada de ferias y eventos con piso permeable",
			 "costo": 12, "puntos": 0.35, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "También reduce el área de estacionamiento (TR5), pero sin relación con la movilidad: nadie deja el carro por eso. Y si en cada evento vuelve a ser estacionamiento improvisado, el programa pierde credibilidad (TR6)."},
		],
	},
	{
		"id": "tr_carpool", "tipo": "decision", "lugar": "estacionamiento_m5", "indicador": "TR7",
		"titulo": "Viajes compartidos",
		"contexto": "En el M5 casi todos los carros llegan con una sola persona. Muchos estudiantes viven en las mismas urbanizaciones y salen a la misma hora. Una iniciativa de viajes compartidos cuenta para GreenMetric como iniciativa para disminuir los vehículos privados en el campus (TR7).",
		"pregunta": "¿Qué incentivo propones?",
		"opciones": [
			{"id": "app_carpool", "corto": "App de carpool",
			 "texto": "Pagar una aplicación de viajes compartidos con cuentas URBE y un grupo por urbanización",
			 "costo": 26, "puntos": 0.35, "contraproducente": false, "aceptacion": "alta", "sinergia": "",
			 "explicacion": "Gusta y facilita encontrar compañeros, pero sin un beneficio concreto al llegar pocos cambian el hábito. Cuenta como iniciativa (TR7), con poco efecto para lo que cuesta."},
			{"id": "puestos_3_ocupantes", "corto": "Puestos para carros con 3+",
			 "texto": "Reservar los puestos más cercanos a la entrada peatonal para carros que lleguen con 3 o más personas, verificados en la garita hasta las 9 a. m.",
			 "costo": 6, "puntos": 0.60, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "Un incentivo visible y barato: el mejor puesto se gana compartiendo. Es una iniciativa concreta de TR7. Quien llega solo pierde comodidad, por eso la aceptación no es alta."},
			{"id": "vender_puestos_reservados", "corto": "Vender puestos reservados",
			 "texto": "Vender puestos reservados con nombre a quien pague la cuota más alta; con lo recaudado se paga el mantenimiento del M5",
			 "costo": 0, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Parece gratis, pero premia al que viene solo en carro y le asegura el puesto: incentiva el vehículo privado, lo contrario de lo que mide TR7."},
		],
	},
	{
		"id": "tr_shuttle", "tipo": "decision", "lugar": "parada_rectorado", "indicador": "TR2",
		"titulo": "Servicio de buseta",
		"contexto": "URBE tiene una buseta que hace una sola vuelta por la mañana. Muchos estudiantes llegan en por puesto o autobús hasta la avenida y caminan el resto bajo el sol, o prefieren venir en carro. GreenMetric (TR2) evalúa si el campus ofrece transporte interno y qué tan útil es.",
		"pregunta": "¿Cómo reorganizas la buseta?",
		"opciones": [
			{"id": "bono_gasolina", "corto": "Bono de gasolina",
			 "texto": "Eliminar la buseta, que va medio vacía, y con ese dinero dar un bono de gasolina al personal",
			 "costo": 10, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Elimina el servicio que mide TR2 y además subsidia el carro particular: más vehículos por persona (TR1) y más emisiones."},
			{"id": "ruta_a_paradas", "corto": "Busetas a las paradas",
			 "texto": "Dos busetas en circuito fijo cada 20 minutos entre las paradas de por puesto de la avenida, el Rectorado y los bloques, de 6:30 a. m. a 9 p. m.",
			 "costo": 26, "puntos": 0.60, "contraproducente": false, "aceptacion": "alta", "sinergia": "",
			 "explicacion": "Conecta el campus con el transporte público que la gente ya usa y cubre los tres turnos: es el tipo de servicio que valora TR2. Con frecuencia fija la gente puede contar con él."},
			{"id": "park_and_ride", "corto": "Estacionamiento externo + busetas",
			 "texto": "Alquilar un estacionamiento en un centro comercial cercano y traer a la gente desde ahí en tres busetas",
			 "costo": 34, "puntos": 0.40, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "Saca carros del campus y cuenta como transporte interno (TR2), pero cada persona sigue llegando en carro hasta el centro comercial, y es la opción más cara: el alquiler se paga todos los meses."},
		],
	},
	{
		"id": "tr_dia_sin_carros", "tipo": "decision", "lugar": "porton_vehicular", "indicador": "TR7",
		"titulo": "Día sin carros",
		"contexto": "Varias universidades del ranking cierran su portón vehicular un día al mes. En URBE la idea genera dudas: ¿cómo llega quien vive lejos? El portón de la avenida es el único acceso de carros. Una jornada así cuenta como iniciativa para disminuir los vehículos privados (TR7).",
		"pregunta": "¿Cómo lo organizas?",
		"opciones": [
			{"id": "cierre_semanal", "corto": "Viernes sin carros",
			 "texto": "Cerrar el portón a los carros particulares todos los viernes desde el mes que viene, con busetas de refuerzo contratadas",
			 "costo": 28, "puntos": 0.40, "contraproducente": false, "aceptacion": "baja", "sinergia": "",
			 "explicacion": "En papel saca más carros, pero cada viernes sin alternativas suficientes baja la asistencia y la comunidad presiona para eliminarlo. Una iniciativa que no se sostiene suma menos en TR7 que una mensual bien hecha."},
			{"id": "jornada_mensual_con_feria", "corto": "Jornada mensual con feria",
			 "texto": "Un miércoles al mes con el portón cerrado a carros particulares, busetas de refuerzo y una feria de movilidad con charlas y taller de mecánica de bicis",
			 "costo": 10, "puntos": 0.60, "contraproducente": false, "aceptacion": "media", "sinergia": "dia_sin_carros_feria",
			 "explicacion": "Es periódica, medible (se cuentan los carros que no entraron) y viene con alternativas. La feria y las charlas la convierten en un evento de sostenibilidad, que también suma en Educación."},
			{"id": "motos_por_la_acera", "corto": "Motos por la acera",
			 "texto": "Hacer el día sin carros pero dejar pasar motos y permitir estacionarlas en las aceras cerca de los bloques",
			 "costo": 4, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Los vehículos solo cambian de tipo: las motos también cuentan en TR1, y estacionarlas en las aceras quita espacio a los peatones (TR8, senderos peatonales)."},
		],
	},
	{
		"id": "tr_flota", "tipo": "decision", "lugar": "zona_mantenimiento", "indicador": "TR3 · TR4",
		"titulo": "Flota de mantenimiento",
		"contexto": "La cuadrilla de mantenimiento recorre el campus en dos carritos a gasolina con más de diez años que fallan seguido. GreenMetric evalúa si hay vehículos de cero emisiones en el campus, eléctricos o de pedal (TR3), y cuántos hay por persona (TR4).",
		"pregunta": "¿Qué haces con la flota?",
		"opciones": [
			{"id": "triciclos_de_carga", "corto": "Triciclos de carga",
			 "texto": "Comprar tres triciclos de carga a pedal para los trabajos cortos y dejar un solo carrito a gasolina",
			 "costo": 8, "puntos": 0.40, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "Los triciclos son vehículos de cero emisiones (TR3), baratos y sin combustible, pero con el calor y las distancias largas la cuadrilla sigue usando el carrito a gasolina para casi todo."},
			{"id": "camioneta_diesel", "corto": "Camioneta diésel",
			 "texto": "Reemplazar los dos carritos por una camioneta diésel más grande para hacer todo en un solo viaje",
			 "costo": 20, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Ningún vehículo de cero emisiones (TR3 y TR4 quedan en nada) y un motor diésel que emite más por kilómetro. Resuelve la logística a costa del indicador."},
			{"id": "carritos_electricos", "corto": "Carritos eléctricos",
			 "texto": "Cambiar los dos carritos por carritos eléctricos que se cargan con el techo solar del estacionamiento",
			 "costo": 18, "puntos": 0.60, "contraproducente": false, "aceptacion": "alta", "sinergia": "flota_electrica",
			 "explicacion": "Dos vehículos de cero emisiones nuevos (TR3 y TR4) que además usan energía producida en el campus: menos combustible y menos emisiones. Por eso suma también en Energía."},
		],
	},
	{
		"id": "tr_bici_bloque_e", "tipo": "bicicletero", "lugar": "bicicletero_bloque_e", "indicador": "TR7",
		"titulo": "Bicicletero del Bloque E",
		"contexto": "Entre el Bloque E y el Rectorado pasan cientos de estudiantes, pero no hay dónde dejar una bicicleta segura: quien viene en bici la amarra a una baranda. Un bicicletero forma parte de las iniciativas para disminuir los vehículos privados (TR7).",
		"pregunta": "¿Qué tipo de bicicletero instalas con el kit?",
		"opciones": [
			{"id": "simple_con_candado", "corto": "Simple, sin techo",
			 "texto": "Estructura simple de tubos en U, sin techo, junto a un poste de luz existente",
			 "costo": 2, "puntos": 0.10, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "Cumple y es barato, pero sin sombra, con el sol de Maracaibo, se usa menos: un bicicletero vacío no reduce carros."},
			{"id": "techado_con_panel", "corto": "Techado con panel solar",
			 "texto": "Techado, con un panel solar pequeño que alimenta la luz LED nocturna",
			 "costo": 5, "puntos": 0.20, "contraproducente": false, "aceptacion": "alta", "sinergia": "bicicletero_techado_solar",
			 "explicacion": "Sombra y luz hacen que la gente lo use de verdad (la seguridad percibida decide si alguien viene en bici) y la luz no consume de la red. Suma a TR7 y a Energía."},
			{"id": "sobre_el_sendero", "corto": "Ganchos en el sendero",
			 "texto": "Colgar ganchos en la baranda del pasillo techado peatonal, sin estructura nueva",
			 "costo": 1, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Las bicis ocupan el sendero peatonal techado (TR8) y quedan mal aseguradas: peatones y ciclistas terminan compitiendo por el mismo espacio."},
		],
	},
	{
		"id": "tr_bici_cafetin", "tipo": "bicicletero", "lugar": "bicicletero_cafetin", "indicador": "TR7",
		"titulo": "Bicicletero del Cafetín",
		"contexto": "Al borde del M5, camino al Cafetín, llegan estudiantes y personal desde las urbanizaciones cercanas. Con el sol de la tarde, una bicicleta dejada a la intemperie se recalienta y el asiento se daña. Un bicicletero forma parte de las iniciativas para disminuir los vehículos privados (TR7).",
		"pregunta": "¿Qué tipo de bicicletero instalas con el kit?",
		"opciones": [
			{"id": "sobre_el_sendero", "corto": "Ganchos en el sendero",
			 "texto": "Colgar ganchos en la baranda del pasillo techado peatonal, sin estructura nueva",
			 "costo": 1, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Las bicis ocupan el sendero peatonal techado (TR8) y quedan mal aseguradas: peatones y ciclistas terminan compitiendo por el mismo espacio."},
			{"id": "simple_con_candado", "corto": "Simple, sin techo",
			 "texto": "Estructura simple de tubos en U, sin techo, junto a un poste de luz existente",
			 "costo": 2, "puntos": 0.10, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "Cumple y es barato, pero sin sombra, con el sol de Maracaibo, se usa menos: un bicicletero vacío no reduce carros."},
			{"id": "techado_con_panel", "corto": "Techado con panel solar",
			 "texto": "Techado, con un panel solar pequeño que alimenta la luz LED nocturna",
			 "costo": 5, "puntos": 0.20, "contraproducente": false, "aceptacion": "alta", "sinergia": "bicicletero_techado_solar",
			 "explicacion": "Sombra y luz hacen que la gente lo use de verdad (la seguridad percibida decide si alguien viene en bici) y la luz no consume de la red. Suma a TR7 y a Energía."},
		],
	},
]
```

- [ ] **Step 4: Implement (parte 2: objeciones y consultas, al final del mismo archivo)**

```gdscript
# Una objeción por opción válida, clave "decision:opcion" (spec §7.3).
# Orden de los argumentos = orden en pantalla.
const OBJECIONES : Dictionary = {
	"tr_permisos:permiso_por_necesidad": {
		"texto": "Consejera de Egresados: «Van a quitarle el permiso anual a cientos de personas. Va a haber quejas y hasta retiros.»",
		"argumentos": [
			{"texto": "GreenMetric lo exige, así que no hay nada que discutir.", "correcto": false,
			 "explicacion": "GreenMetric no obliga a nada: es un ranking voluntario. Imponer sin explicar es justo lo que genera rechazo."},
			{"texto": "Nadie pierde el acceso: sigue el pase diario, y la buseta y el carpool del plan dan alternativas a quien deja de tener permiso anual.", "correcto": true,
			 "explicacion": "Una restricción se defiende mostrando las alternativas que la acompañan."},
			{"texto": "Si hay muchas quejas, se vuelve a dar permiso a todos.", "correcto": false,
			 "explicacion": "Deshacer la medida al primer reclamo borra la reducción de vehículos (TR1) y la credibilidad del plan."},
		],
	},
	"tr_permisos:lectoras_de_placas": {
		"texto": "Director de Finanzas: «24 puntos del presupuesto en cámaras… ¿cuántos carros menos entran con eso?»",
		"argumentos": [
			{"texto": "Ninguno por sí solo: el valor está en medir. Con los datos de las placas se fija una meta de reducción y se comprueba si se cumple (TR1).", "correcto": true,
			 "explicacion": "Reconocer el límite y mostrar para qué sirve el dato es un argumento honesto y verificable."},
			{"texto": "Muchos: al entrar más rápido, la gente se anima a no traer el carro.", "correcto": false,
			 "explicacion": "Una entrada más rápida hace más cómodo venir en carro, no menos."},
			{"texto": "Las cámaras dan seguridad, y eso es lo que mide GreenMetric en Transporte.", "correcto": false,
			 "explicacion": "La seguridad importa, pero TR1 mide vehículos por persona, no vigilancia."},
		],
	},
	"tr_lote:ciclovia_arborizada": {
		"texto": "Jefe de Servicios Generales: «¿Y quién riega esos árboles y mantiene la ciclovía? Eso cuesta todos los años.»",
		"argumentos": [
			{"texto": "Los árboles no necesitan mantenimiento.", "correcto": false,
			 "explicacion": "Todo árbol recién plantado necesita riego y cuidado al principio."},
			{"texto": "Si sale caro, se vuelve a abrir el lote para carros.", "correcto": false,
			 "explicacion": "Reabrirlo borra la reducción de área de estacionamiento que suma en TR5 y TR6."},
			{"texto": "Con especies nativas adaptadas al clima de Maracaibo, que después del primer año necesitan poco riego; el mantenimiento entra en la rutina de jardinería que ya existe.", "correcto": true,
			 "explicacion": "Anticipar el costo con una elección técnica responde la objeción."},
		],
	},
	"tr_lote:plaza_de_eventos": {
		"texto": "Coordinadora de Eventos: «El día de la feria la gente va a estacionar ahí igual. ¿Entonces qué redujimos?»",
		"argumentos": [
			{"texto": "Nada, pero queda un espacio bonito para el campus.", "correcto": false,
			 "explicacion": "Si no reduce estacionamiento, no suma en TR5 ni en TR6: el plan pierde su argumento principal."},
			{"texto": "Se ponen bolardos y una regla escrita: el lote no se usa como estacionamiento ni en eventos, y los visitantes llegan en buseta.", "correcto": true,
			 "explicacion": "Un programa de reducción (TR6) necesita reglas que se cumplan también los días especiales."},
			{"texto": "Es solo unas veces al año, no afecta el indicador.", "correcto": false,
			 "explicacion": "Si se permite en cada evento, el área sigue funcionando como estacionamiento y el programa pierde credibilidad."},
		],
	},
	"tr_carpool:puestos_3_ocupantes": {
		"texto": "Representante estudiantil: «Muchos vivimos en zonas donde nadie más viene a URBE. Nos quitan los buenos puestos.»",
		"argumentos": [
			{"texto": "Que se muden más cerca.", "correcto": false,
			 "explicacion": "Una respuesta que desprecia la situación real de la gente hunde la aceptación del plan."},
			{"texto": "Los puestos reservados son pocos, así que en realidad no cambia nada.", "correcto": false,
			 "explicacion": "Si no cambia nada, tampoco reduce carros: el argumento contradice el objetivo."},
			{"texto": "Quien llega solo conserva su puesto en el resto del M5; solo se reservan los más cercanos hasta las 9, y el grupo por urbanización ayuda a encontrar con quién venir.", "correcto": true,
			 "explicacion": "Mostrar que la medida es acotada y que ofrece cómo cumplirla responde la queja."},
		],
	},
	"tr_carpool:app_carpool": {
		"texto": "Director de Finanzas: «La aplicación se paga todos los años. ¿Qué pasa si nadie la usa?»",
		"argumentos": [
			{"texto": "Se va a usar sí o sí, porque es moderna.", "correcto": false,
			 "explicacion": "Que algo sea moderno no garantiza que cambie hábitos."},
			{"texto": "Cada semestre se mide cuántos viajes compartidos registra; si no llega a una meta mínima, ese dinero pasa a puestos preferenciales para carros con 3 o más personas.", "correcto": true,
			 "explicacion": "Una iniciativa con meta y plan B es defendible."},
			{"texto": "Es gratis para los estudiantes, así que no importa.", "correcto": false,
			 "explicacion": "Que sea gratis para quien la usa no cambia que la universidad la paga."},
		],
	},
	"tr_shuttle:ruta_a_paradas": {
		"texto": "Director de Finanzas: «Dos busetas de 6:30 de la mañana a 9 de la noche: chofer, gasoil, repuestos. ¿Lo podemos sostener?»",
		"argumentos": [
			{"texto": "Las busetas se pagan solas porque la gente las va a usar.", "correcto": false,
			 "explicacion": "El pasaje interno no existe o es simbólico: el servicio siempre tiene un costo que hay que financiar."},
			{"texto": "Se puede quitar el turno de la noche, que tiene pocos estudiantes.", "correcto": false,
			 "explicacion": "Dejar sin transporte al turno nocturno, el que más lo necesita por seguridad, rompe la cobertura que valora TR2."},
			{"texto": "Se ajusta la frecuencia con conteos de pasajeros por turno y se financia en parte con el cobro de estacionamiento a visitantes.", "correcto": true,
			 "explicacion": "Datos de uso y una fuente de financiamiento concreta hacen sostenible el servicio."},
		],
	},
	"tr_shuttle:park_and_ride": {
		"texto": "Consejero académico: «Igual le pedimos a la gente que maneje hasta el centro comercial. ¿Eso es sostenible?»",
		"argumentos": [
			{"texto": "Es un paso intermedio: reduce los carros dentro del campus y el estacionamiento que necesitamos; después la ruta puede extenderse a las paradas de transporte público.", "correcto": true,
			 "explicacion": "Reconocer el límite y mostrar el camino siguiente es un argumento sólido."},
			{"texto": "Sí, porque el centro comercial queda cerca.", "correcto": false,
			 "explicacion": "La cercanía no elimina el viaje en carro."},
			{"texto": "El indicador solo cuenta los carros dentro del campus; lo de afuera no importa.", "correcto": false,
			 "explicacion": "Es cierto que TR1 cuenta vehículos del campus, pero defender el plan ignorando las emisiones de afuera lo debilita ante el Consejo."},
		],
	},
	"tr_dia_sin_carros:jornada_mensual_con_feria": {
		"texto": "Decano: «Un miércoles con el portón cerrado: los profesores que vienen de lejos van a faltar a clases.»",
		"argumentos": [
			{"texto": "Ese día se pueden suspender las clases.", "correcto": false,
			 "explicacion": "Suspender clases convierte la iniciativa en un feriado: no enseña a llegar de otra forma."},
			{"texto": "Se anuncia con el calendario del semestre, hay busetas de refuerzo desde las paradas y quien tiene movilidad reducida conserva el acceso.", "correcto": true,
			 "explicacion": "Anticipación, alternativas y excepciones justas responden la preocupación."},
			{"texto": "Que falten: es solo un día al mes.", "correcto": false,
			 "explicacion": "Minimizar el problema no lo resuelve y baja la aceptación del plan."},
		],
	},
	"tr_dia_sin_carros:cierre_semanal": {
		"texto": "Representante estudiantil: «Todos los viernes sin carros, desde el mes que viene. Va a bajar la asistencia.»",
		"argumentos": [
			{"texto": "Quien no venga es porque no le importa el ambiente.", "correcto": false,
			 "explicacion": "Culpar a la comunidad no resuelve cómo llega quien vive lejos."},
			{"texto": "Con las busetas contratadas alcanza para todos.", "correcto": false,
			 "explicacion": "Afirmarlo sin conteos de demanda no convence."},
			{"texto": "Se empieza con una jornada mensual bien organizada y la frecuencia sube solo si los conteos muestran que las alternativas alcanzan.", "correcto": true,
			 "explicacion": "Reconocer el riesgo y proponer una implementación gradual con datos es el mejor argumento."},
		],
	},
	"tr_flota:carritos_electricos": {
		"texto": "Jefe de Mantenimiento: «¿Y si se acaba la batería a mitad de un trabajo? Los viejos al menos se llenan de gasolina.»",
		"argumentos": [
			{"texto": "Las rutas de trabajo se planifican según la autonomía y los carritos se cargan de noche o al mediodía con el techo solar; los trayectos dentro del campus son cortos.", "correcto": true,
			 "explicacion": "Planificar la operación responde el riesgo real."},
			{"texto": "Los carritos eléctricos nunca se descargan.", "correcto": false,
			 "explicacion": "Todo vehículo eléctrico tiene una autonomía limitada."},
			{"texto": "Si fallan, se vuelven a comprar carritos a gasolina.", "correcto": false,
			 "explicacion": "Volver atrás al primer problema anula el cambio que suma en TR3 y TR4."},
		],
	},
	"tr_flota:triciclos_de_carga": {
		"texto": "Jefe de Mantenimiento: «Con este calor nadie va a pedalear un triciclo cargado desde el M5 hasta el Rectorado.»",
		"argumentos": [
			{"texto": "Es buen ejercicio para la cuadrilla.", "correcto": false,
			 "explicacion": "Ignora las condiciones de trabajo: sin una organización realista, los triciclos quedan guardados."},
			{"texto": "Los triciclos se asignan a los trabajos cortos por zona y el carrito a gasolina queda solo para cargas pesadas, con registro de uso.", "correcto": true,
			 "explicacion": "Organizar el uso real es lo que hace que un vehículo de cero emisiones reduzca emisiones."},
			{"texto": "Aunque no se usen, igual cuentan como vehículos de cero emisiones.", "correcto": false,
			 "explicacion": "Tenerlos guardados cuenta en papel, pero no reduce emisiones; el Consejo pregunta por el efecto real."},
		],
	},
	"tr_bici_bloque_e:techado_con_panel": {
		"texto": "Jefe de Seguridad: «Un panel solar en un bicicletero, a la vista de todos. ¿No se lo van a robar?»",
		"argumentos": [
			{"texto": "En URBE nadie roba.", "correcto": false,
			 "explicacion": "Negar el riesgo no convence a quien tiene que cuidar el campus."},
			{"texto": "El panel va fijo sobre el techo con tornillería antirrobo, a la vista de la vigilancia y con la luz encendida toda la noche, que también protege las bicis.", "correcto": true,
			 "explicacion": "Prevención concreta responde la objeción."},
			{"texto": "Si se lo roban, se pone otro.", "correcto": false,
			 "explicacion": "Reponer sin prevenir multiplica el costo."},
		],
	},
	"tr_bici_bloque_e:simple_con_candado": {
		"texto": "Representante estudiantil: «Sin techo, a las dos de la tarde el asiento quema. ¿Quién lo va a usar?»",
		"argumentos": [
			{"texto": "Se ubica bajo la sombra de los árboles del corredor y al final del semestre se revisa cuánto se usa para decidir si se techa.", "correcto": true,
			 "explicacion": "Una mejora barata con evaluación posterior es defendible."},
			{"texto": "Cada uno puede traer una toalla para el asiento.", "correcto": false,
			 "explicacion": "Trasladar el problema al usuario reduce el uso del bicicletero."},
			{"texto": "Lo importante es tenerlo, aunque no se use.", "correcto": false,
			 "explicacion": "Un bicicletero vacío no reduce ningún carro."},
		],
	},
	"tr_bici_cafetin:techado_con_panel": {
		"texto": "Director de Finanzas: «¿Por qué pagar un panel solar para una sola luz?»",
		"argumentos": [
			{"texto": "Porque los paneles solares siempre son más baratos que cualquier otra cosa.", "correcto": false,
			 "explicacion": "No siempre: depende de la instalación; el argumento es falso como regla general."},
			{"texto": "Porque se ve moderno.", "correcto": false,
			 "explicacion": "La imagen no justifica un gasto ante el Consejo."},
			{"texto": "Porque evita cablear desde el edificio: el panel pequeño cuesta menos que la obra eléctrica y la luz no consume de la red.", "correcto": true,
			 "explicacion": "Comparar con la alternativa real (cablear) justifica el costo."},
		],
	},
	"tr_bici_cafetin:simple_con_candado": {
		"texto": "Jefe de Seguridad: «Sin luz ni techo, de noche esto es un bicicletero para ladrones.»",
		"argumentos": [
			{"texto": "De noche casi no hay estudiantes.", "correcto": false,
			 "explicacion": "El turno nocturno existe y es el que más necesita seguridad."},
			{"texto": "Queda junto al poste de luz existente y dentro del recorrido de vigilancia del estacionamiento, y la campaña de movilidad recomienda candado en U.", "correcto": true,
			 "explicacion": "Aprovechar la luz y la vigilancia existentes responde el riesgo sin costo extra."},
			{"texto": "Cada uno es responsable de su bicicleta.", "correcto": false,
			 "explicacion": "Si la gente no se siente segura, no viene en bici y el bicicletero no cumple su función."},
		],
	},
}


static func decision(id: String) -> Dictionary:
	for d in DECISIONES:
		if d["id"] == id:
			return d
	return {}


static func opcion(decision_id: String, opcion_id: String) -> Dictionary:
	for o in decision(decision_id).get("opciones", []):
		if o["id"] == opcion_id:
			return o
	return {}


static func ids_decisiones() -> Array:
	var ids := []
	for d in DECISIONES:
		ids.append(d["id"])
	return ids


# Opción válida con más puntos (sin empates en los datos).
static func mejor_opcion(decision_id: String) -> String:
	var mejor := ""
	var max_puntos := -1.0
	for o in decision(decision_id).get("opciones", []):
		if not o["contraproducente"] and float(o["puntos"]) > max_puntos:
			max_puntos = float(o["puntos"])
			mejor = o["id"]
	return mejor


static func objecion(decision_id: String, opcion_id: String) -> Dictionary:
	return OBJECIONES.get("%s:%s" % [decision_id, opcion_id], {})


static func calificacion(aciertos: int) -> Dictionary:
	var a := clampi(aciertos, 0, 3)
	for c in CONSEJO_OPCIONES:
		if int(c["aciertos"]) == a:
			return c
	return {}


static func texto_sinergia(accion_id: String) -> String:
	var s : Dictionary = SINERGIAS.get(accion_id, {})
	if s.is_empty():
		return ""
	return "✨ Cruce: %s (se suma cuando el Consejo aprueba el plan)" % s["efecto"]
```

- [ ] **Step 5: Run test to verify it passes**

Run: igual que Step 2. Expected: exit=0, ninguna `FALLA`.

- [ ] **Step 6: Commit**

```bash
git add scenes/misiones/plan_movilidad_datos.gd scenes/misiones/plan_movilidad_datos.gd.uid tests/test_plan_datos.gd tests/test_plan_datos.gd.uid tests/test_plan_datos.tscn
git commit -m "nivel 5: contenido del Plan de Movilidad (decisiones, objeciones, sinergias)

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Servidor — catálogos del Plan de Movilidad  *(Ola 1, paralela)*

**Files:**
- Create: `sql/nivel5_plan_movilidad.sql`

**Interfaces:**
- Produces (en la base, migración `nivel5_plan_movilidad_catalogos`): 28 filas en `catalogo_decisiones` (categoría 5) y 4 en `catalogo_sinergias` (spec §10.1). Sin funciones nuevas.
- Produces (archivo, NO aplicada): sección de la migración `nivel5_plan_movilidad_misiones` (spec §10.2).
- Consumed by: Task 11 (la prueba del controlador lee este `.sql` y lo compara con `plan_movilidad_datos.gd`; el formato de cada fila debe quedar exactamente como abajo: `('tr_x', 'opcion', 5, 0.60, false, 8)`).

- [ ] **Step 1: Escribir el registro**

`sql/nivel5_plan_movilidad.sql`:
```sql
-- ============================================================
-- nivel5_plan_movilidad.sql — GreenMetric_URBE
-- Nivel 5 nuevo: Plan de Movilidad. Diseño:
-- docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md §10
--
-- REGISTRO, NO SCRIPT: copia de las migraciones para leer y revisar.
-- No usa funciones nuevas: registrar_decision / registrar_sinergia /
-- guardar_detalle / puntaje_greenmetric (sql/puntaje_greenmetric.sql).
--
-- ESPEJO: catalogo_decisiones y catalogo_sinergias reflejan
-- scenes/misiones/plan_movilidad_datos.gd (tests/test_nivel5_movilidad.gd
-- compara este archivo con los datos). catalogo_misiones categoría 5
-- refleja NivelManager.MISIONES_NIVEL[5].
-- ============================================================

-- ── Migración 1: nivel5_plan_movilidad_catalogos ─────────────
-- ESTADO: APLICADA. Solo agrega filas: el juego publicado no las usa.
-- Mejor opción de cada decisión: 6 × 0.60 + 2 × 0.20 + Consejo 1.00 = 5.00.
-- Plan de mayor puntaje = 100 de costo (el presupuesto del cliente).
insert into public.catalogo_decisiones (decision_id, opcion_id, categoria, puntos, contraproducente, costo) values
  ('tr_permisos', 'permiso_por_necesidad', 5, 0.60, false, 8),
  ('tr_permisos', 'lectoras_de_placas', 5, 0.25, false, 24),
  ('tr_permisos', 'pintar_mas_puestos', 5, 0.00, true, 14),
  ('tr_lote', 'ciclovia_arborizada', 5, 0.60, false, 22),
  ('tr_lote', 'plaza_de_eventos', 5, 0.35, false, 12),
  ('tr_lote', 'asfaltar_lote', 5, 0.00, true, 16),
  ('tr_carpool', 'puestos_3_ocupantes', 5, 0.60, false, 6),
  ('tr_carpool', 'app_carpool', 5, 0.35, false, 26),
  ('tr_carpool', 'vender_puestos_reservados', 5, 0.00, true, 0),
  ('tr_shuttle', 'ruta_a_paradas', 5, 0.60, false, 26),
  ('tr_shuttle', 'park_and_ride', 5, 0.40, false, 34),
  ('tr_shuttle', 'bono_gasolina', 5, 0.00, true, 10),
  ('tr_dia_sin_carros', 'jornada_mensual_con_feria', 5, 0.60, false, 10),
  ('tr_dia_sin_carros', 'cierre_semanal', 5, 0.40, false, 28),
  ('tr_dia_sin_carros', 'motos_por_la_acera', 5, 0.00, true, 4),
  ('tr_flota', 'carritos_electricos', 5, 0.60, false, 18),
  ('tr_flota', 'triciclos_de_carga', 5, 0.40, false, 8),
  ('tr_flota', 'camioneta_diesel', 5, 0.00, true, 20),
  ('tr_bici_bloque_e', 'techado_con_panel', 5, 0.20, false, 5),
  ('tr_bici_bloque_e', 'simple_con_candado', 5, 0.10, false, 2),
  ('tr_bici_bloque_e', 'sobre_el_sendero', 5, 0.00, true, 1),
  ('tr_bici_cafetin', 'techado_con_panel', 5, 0.20, false, 5),
  ('tr_bici_cafetin', 'simple_con_candado', 5, 0.10, false, 2),
  ('tr_bici_cafetin', 'sobre_el_sendero', 5, 0.00, true, 1),
  ('tr_consejo', 'consejo_3', 5, 1.00, false, 0),
  ('tr_consejo', 'consejo_2', 5, 0.60, false, 0),
  ('tr_consejo', 'consejo_1', 5, 0.30, false, 0),
  ('tr_consejo', 'consejo_0', 5, 0.00, false, 0)
on conflict (decision_id, opcion_id) do nothing;

-- Cruces: se registran al aprobar el Consejo (spec R5), por eso el requisito
-- es tr_consejo. bicicletero_techado_solar se gana una sola vez aunque se
-- elija en los dos bicicleteros.
insert into public.catalogo_sinergias (accion_id, categoria, puntos, requisito_mision) values
  ('ciclovia_lote', 1, 1, 'tr_consejo'),
  ('flota_electrica', 2, 1, 'tr_consejo'),
  ('dia_sin_carros_feria', 6, 1, 'tr_consejo'),
  ('bicicletero_techado_solar', 2, 1, 'tr_consejo')
on conflict (accion_id, categoria) do nothing;

-- ── Migración 2: nivel5_plan_movilidad_misiones ──────────────
-- ESTADO: NO APLICADA. Se aplica junto con la publicación del cliente nuevo
-- (spec R10 y §10.2): aplicada antes, el juego publicado (que guarda mov_*)
-- mostraría el Avance de Transporte en 0. Las filas viejas de
-- misiones_estudiante no se tocan (sostienen MISIONES_LEGADO del cliente).
delete from public.catalogo_misiones
 where mision_id in ('mov_parqueo', 'mov_shuttle', 'mov_ciclovia', 'mov_dia_sin_carros',
                     'mov_zev', 'mov_carpool', 'bicicletero_bloque_e', 'bicicletero_cafetin');
insert into public.catalogo_misiones (mision_id, categoria, tipo, preguntas) values
  ('tr_permisos', 5, 'mision', 0), ('tr_lote', 5, 'mision', 0),
  ('tr_carpool', 5, 'mision', 0), ('tr_shuttle', 5, 'mision', 0),
  ('tr_dia_sin_carros', 5, 'mision', 0), ('tr_flota', 5, 'mision', 0),
  ('tr_bici_bloque_e', 5, 'mision', 0), ('tr_bici_cafetin', 5, 'mision', 0),
  ('tr_consejo', 5, 'mision', 0)
on conflict (mision_id) do nothing;
```

- [ ] **Step 2: Aplicar SOLO la migración 1**

Con `apply_migration` (project `ikohikbpvtbvsgyumvbr`), name `nivel5_plan_movilidad_catalogos`, query = los dos `insert` de la sección "Migración 1" (copiados tal cual). **No** incluir la sección "Migración 2".

- [ ] **Step 3: Probar la migración 1 sin dejar datos**

Con `execute_sql`; debe terminar con el error `PRUEBA_OK` (cualquier otro = falla):
```sql
do $$
declare
  u uuid := gen_random_uuid();
  r jsonb;
  v numeric;
  n int;
begin
  -- Catálogo: mejores válidas suman 5; 1 contraproducente por decisión (0 en el Consejo).
  select sum(m) into v from (
    select max(puntos) m from catalogo_decisiones
     where categoria = 5 and not contraproducente group by decision_id) x;
  if v <> 5.00 then raise exception 'FALLA suma de mejores = %', v; end if;
  select count(*) into n from (
    select decision_id from catalogo_decisiones where categoria = 5 group by decision_id
    having count(*) filter (where contraproducente) <> case when decision_id = 'tr_consejo' then 0 else 1 end) x;
  if n <> 0 then raise exception 'FALLA contraproducentes por decisión (% decisiones mal)', n; end if;
  select sum(d.costo) into n from catalogo_decisiones d
   where d.categoria = 5 and d.decision_id <> 'tr_consejo' and not d.contraproducente
     and d.puntos = (select max(d2.puntos) from catalogo_decisiones d2
                      where d2.decision_id = d.decision_id and not d2.contraproducente);
  if n <> 100 then raise exception 'FALLA costo del mejor plan = %', n; end if;

  insert into auth.users (id, email) values (u, 'n5_' || u || '@prueba.local');
  insert into estudiantes (id, nombre, cedula) values (u, 'Prueba Nivel Cinco', 'V-PRUEBA-N5')
  on conflict (id) do nothing;
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);

  -- Regla Mixta.
  r := registrar_decision('tr_carpool', 'vender_puestos_reservados');
  if not (r->>'ok')::boolean or not (r->>'contraproducente')::boolean or not (r->>'penalizado')::boolean then
    raise exception 'FALLA contraproducente: %', r; end if;
  r := registrar_decision('tr_carpool', 'puestos_3_ocupantes');
  if (r->>'contraproducente')::boolean then raise exception 'FALLA válida: %', r; end if;
  if (r->'puntaje'->'categorias'->'5'->>'decisiones')::numeric <> 0 then
    raise exception 'FALLA tope en 0 (0.60 - 1): %', r->'puntaje'->'categorias'->'5'; end if;
  r := registrar_decision('tr_lote', 'ciclovia_arborizada');
  r := registrar_decision('tr_consejo', 'consejo_3');
  if (r->'puntaje'->'categorias'->'5'->>'decisiones')::numeric <> 1.20 then
    raise exception 'FALLA 0.60 + 0.60 + 1.00 - 1: %', r->'puntaje'->'categorias'->'5'; end if;
  r := registrar_decision('tr_consejo', 'consejo_1');
  if (r->'puntaje'->'categorias'->'5'->>'decisiones')::numeric <> 0.50 then
    raise exception 'FALLA reemplazo de la calificación: %', r->'puntaje'->'categorias'->'5'; end if;

  -- Cruces: exigen tr_consejo.
  r := registrar_sinergia('ciclovia_lote');
  if (r->>'ok')::boolean or r->>'error' <> 'requisito_incumplido' then
    raise exception 'FALLA requisito: %', r; end if;
  insert into misiones_estudiante (user_id, modulo_id, mision_id, xp_otorgada) values (u, 5, 'tr_consejo', 0);
  r := registrar_sinergia('ciclovia_lote');
  if not (r->>'nuevo')::boolean or (r->'puntaje'->'categorias'->'1'->>'sinergias')::numeric <> 1 then
    raise exception 'FALLA sinergia Entorno: %', r; end if;
  r := registrar_sinergia('bicicletero_techado_solar');
  r := registrar_sinergia('flota_electrica');
  if (r->'puntaje'->'categorias'->'2'->>'sinergias')::numeric <> 2 then
    raise exception 'FALLA sinergias Energía: %', r; end if;
  r := registrar_sinergia('dia_sin_carros_feria');
  if (r->'puntaje'->'categorias'->'6'->>'sinergias')::numeric <> 1 then
    raise exception 'FALLA sinergia Educación: %', r; end if;
  r := registrar_sinergia('flota_electrica');
  if (r->>'nuevo')::boolean then raise exception 'FALLA repetir sinergia sumó'; end if;
  raise exception 'PRUEBA_OK';
end $$;
```
Si un `insert` en `auth.users` o `estudiantes` falla por columnas obligatorias, completar solo esas columnas con valores de prueba (mismo criterio que la prueba de `ranking_publico`); no cambiar las aserciones.

- [ ] **Step 4: Probar la migración 2 SIN aplicarla**

Con `execute_sql`; debe terminar en `PRUEBA_OK`. Las sentencias de la migración 2 corren dentro del bloque y se deshacen con la excepción:
```sql
do $$
declare
  u uuid := gen_random_uuid();
  r jsonb;
  n int;
begin
  delete from public.catalogo_misiones
   where mision_id in ('mov_parqueo', 'mov_shuttle', 'mov_ciclovia', 'mov_dia_sin_carros',
                       'mov_zev', 'mov_carpool', 'bicicletero_bloque_e', 'bicicletero_cafetin');
  insert into public.catalogo_misiones (mision_id, categoria, tipo, preguntas) values
    ('tr_permisos', 5, 'mision', 0), ('tr_lote', 5, 'mision', 0),
    ('tr_carpool', 5, 'mision', 0), ('tr_shuttle', 5, 'mision', 0),
    ('tr_dia_sin_carros', 5, 'mision', 0), ('tr_flota', 5, 'mision', 0),
    ('tr_bici_bloque_e', 5, 'mision', 0), ('tr_bici_cafetin', 5, 'mision', 0),
    ('tr_consejo', 5, 'mision', 0)
  on conflict (mision_id) do nothing;
  select count(*) into n from catalogo_misiones where categoria = 5 and tipo in ('mision', 'minijuego');
  if n <> 9 then raise exception 'FALLA misiones del Nivel 5 = %', n; end if;

  insert into auth.users (id, email) values (u, 'n5m_' || u || '@prueba.local');
  insert into estudiantes (id, nombre, cedula) values (u, 'Prueba Nivel Cinco', 'V-PRUEBA-N5M')
  on conflict (id) do nothing;
  insert into misiones_estudiante (user_id, modulo_id, mision_id, xp_otorgada)
  select u, 5, m, 0 from unnest(array['mov_parqueo', 'mov_shuttle', 'mov_ciclovia', 'mov_dia_sin_carros',
                                      'mov_zev', 'mov_carpool', 'bicicletero_bloque_e',
                                      'bicicletero_cafetin', 'tr_permisos']) m;
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  r := puntaje_greenmetric();
  -- Solo tr_permisos cuenta: 80 × 1/9 = 8.89.
  if (r->'categorias'->'5'->>'avance')::numeric <> 8.89 then
    raise exception 'FALLA avance con IDs viejos: %', r->'categorias'->'5'; end if;
  raise exception 'PRUEBA_OK';
end $$;
```

- [ ] **Step 5: Advisors**

Correr `get_advisors` (type `security`) y confirmar que no hay avisos nuevos respecto de los ya documentados (los 6 `authenticated_security_definer_function_executable` del puntaje y los preexistentes). Anotar el resultado en el informe.

- [ ] **Step 6: Commit**

```bash
git add sql/nivel5_plan_movilidad.sql
git commit -m "sql: catálogos del Plan de Movilidad (decisiones y cruces del Nivel 5)

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: NivelManager — misiones del Nivel 5 nuevo y legado  *(Ola 1, paralela)*

**Files:**
- Modify: `autoload/NivelManager.gd` (`TOTAL_MISIONES` ~31, `MISIONES_NIVEL` ~45, `MISIONES_LEGADO` ~59)
- Test: `tests/test_niveles.gd`

**Interfaces:**
- Produces: `NivelManager.MISIONES_NIVEL[5]` = `["tr_permisos", "tr_lote", "tr_carpool", "tr_shuttle", "tr_dia_sin_carros", "tr_flota", "tr_bici_bloque_e", "tr_bici_cafetin", "tr_consejo"]`; `TOTAL_MISIONES[5] = 9`; `MISIONES_LEGADO[5]` = los 8 IDs viejos; niveles 1–4 y 6 sin cambios.
- Produces: `NivelManager.legado_completo(n: int) -> bool` — verdadero si `misiones_legado[n]` difiere de `misiones_nivel[n]` y todas las del legado están hechas (spec §11.1). Consumido por Tasks 11 y 12.

- [ ] **Step 1: Write the failing test**

En `tests/test_niveles.gd`, justo antes de `nm.free()` / `print("test_niveles: ...` del final, agregar:
```gdscript
	# Nivel 5 nuevo (Plan de Movilidad) con legado del Nivel 5 viejo.
	nm.free()
	nm = _nm_con({})
	var nuevos := ["tr_permisos", "tr_lote", "tr_carpool", "tr_shuttle", "tr_dia_sin_carros",
		"tr_flota", "tr_bici_bloque_e", "tr_bici_cafetin", "tr_consejo"]
	var viejos := ["mov_parqueo", "mov_shuttle", "mov_ciclovia", "mov_dia_sin_carros",
		"mov_zev", "mov_carpool", "bicicletero_bloque_e", "bicicletero_cafetin"]
	_check(nm.MISIONES_NIVEL[5] == nuevos, "Nivel 5 = las 9 misiones del Plan de Movilidad")
	_check(nm.TOTAL_MISIONES[5] == 9, "TOTAL_MISIONES[5] = 9")
	_check(nm.MISIONES_LEGADO[5] == viejos, "legado del Nivel 5 = los 8 IDs viejos")
	for n in [1, 2, 3, 4, 6]:
		_check(nm.MISIONES_LEGADO[n] == nm.MISIONES_NIVEL[n], "legado del nivel %d sin cambios" % n)
	var hasta4 := {}
	for n in range(1, 5):
		var d := {}
		for id in nm.MISIONES_NIVEL[n]:
			d[id] = true
		hasta4[str(n)] = d
	var con_viejo := hasta4.duplicate(true)
	var v5 := {}
	for id in viejos:
		v5[id] = true
	con_viejo["5"] = v5
	nm.free()
	nm = _nm_con(con_viejo)
	_check(not nm.nivel_completo(5), "Nivel 5 viejo completo: el nuevo queda reabierto")
	_check(nm.nivel_superado(5) and nm.nivel_desbloqueado(6), "Nivel 5 viejo completo: el 6 sigue desbloqueado")
	_check(is_equal_approx(nm.pct_nivel(5), 0.0), "avance del Nivel 5 nuevo en 0 con IDs viejos")
	var con_nuevo := hasta4.duplicate(true)
	var n5 := {}
	for id in nuevos:
		n5[id] = true
	con_nuevo["5"] = n5
	nm.free()
	nm = _nm_con(con_nuevo)
	_check(nm.nivel_completo(5) and nm.nivel_desbloqueado(6), "las 9 nuevas completan el Nivel 5")
	_check(not nm.legado_completo(5), "sin las viejas: legado incompleto (se paga XP/EC)")

	# Sin re-pago (spec §11.1): legado_completo.
	nm.free()
	nm = _nm_con(con_viejo)
	_check(nm.legado_completo(5), "Nivel 5 viejo completo: legado_completo(5)")
	_check(not nm.legado_completo(1) and not nm.legado_completo(4), "niveles con legado igual al actual: nunca legado_completo")
	var a_medias := hasta4.duplicate(true)
	a_medias["5"] = {"mov_parqueo": true, "mov_shuttle": true}
	nm.free()
	nm = _nm_con(a_medias)
	_check(not nm.legado_completo(5), "Nivel 5 viejo a medias: se paga normal")
	nm.free()
	nm = _nm_con({})
	_check(not nm.legado_completo(5), "jugador nuevo: se paga normal")
```
(El `nm.free()` final que ya existe libera este último `nm`.)

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_niveles.tscn; echo exit=$?` → Expected: FALLA en las líneas nuevas del Nivel 5, exit=1.

- [ ] **Step 3: Implement**

En `autoload/NivelManager.gd`, reemplazar la línea
```gdscript
	5: 8,   # 6 decisiones de movilidad + 2 bicicleteros
```
por
```gdscript
	5: 9,   # Plan de Movilidad: 6 decisiones + 2 bicicleteros + Consejo
```
Reemplazar
```gdscript
	5: ["mov_parqueo", "mov_shuttle", "mov_ciclovia", "mov_dia_sin_carros",
		"mov_zev", "mov_carpool", "bicicletero_bloque_e", "bicicletero_cafetin"],
	6: ["malla_verde", "comite_ambiental", "semana_verde", "informe_final"],
}
```
(la de `MISIONES_NIVEL`) por
```gdscript
	# Plan de Movilidad (sql/nivel5_plan_movilidad.sql). ESPEJO también de
	# scenes/misiones/plan_movilidad_datos.gd MISIONES.
	5: ["tr_permisos", "tr_lote", "tr_carpool", "tr_shuttle", "tr_dia_sin_carros",
		"tr_flota", "tr_bici_bloque_e", "tr_bici_cafetin", "tr_consejo"],
	6: ["malla_verde", "comite_ambiental", "semana_verde", "informe_final"],
}
```
Reemplazar
```gdscript
# Conjunto con el que cada nivel se consideraba completo ANTES de cambiarle
# las misiones. Quien ya lo había superado no pierde el desbloqueo del
# siguiente nivel aunque el nivel se reabra. Hoy es igual a MISIONES_NIVEL;
# el Nivel 5 nuevo y los minijuegos lo harán distinto.
const MISIONES_LEGADO : Dictionary = MISIONES_NIVEL
```
por
```gdscript
# Conjunto con el que cada nivel se consideraba completo ANTES de cambiarle
# las misiones. Quien ya lo había superado no pierde el desbloqueo del
# siguiente nivel aunque el nivel se reabra. El Nivel 5 cambió al Plan de
# Movilidad (2026-09-17): su legado son los 8 IDs del Nivel 5 viejo. Los
# minijuegos del proyecto C harán lo mismo con sus niveles.
const MISIONES_LEGADO : Dictionary = {
	1: ["plantar_rectorado", "plantar_patio", "plantar_este",
		"plantar_corredores", "plantar_norte", "plantar_oeste"],
	2: ["led_bloque_a", "led_bloque_b", "led_bloque_c", "led_bloque_d",
		"led_bloque_e", "led_bloque_f", "solar_rectorado", "solar_estacionamiento"],
	3: ["reciclar_corredor_n", "reciclar_patio_e", "reciclar_bloque_e",
		"reciclar_oeste", "reciclar_sur", "reciclar_este"],
	4: ["llave_bloque_c", "llave_bloque_a", "llave_corredor_n", "llave_patio_e",
		"llave_este", "llave_bloque_b", "captacion_biblioteca", "captacion_bloque_c"],
	5: ["mov_parqueo", "mov_shuttle", "mov_ciclovia", "mov_dia_sin_carros",
		"mov_zev", "mov_carpool", "bicicletero_bloque_e", "bicicletero_cafetin"],
	6: ["malla_verde", "comite_ambiental", "semana_verde", "informe_final"],
}
```
Debajo de `func nivel_superado(n: int) -> bool:` (después de su `return`), agregar:
```gdscript

# El nivel cambió de misiones y el jugador había completado el conjunto
# VIEJO. Decisión del usuario (spec Nivel 5 §11.1): a esos jugadores las
# misiones nuevas no les vuelven a pagar XP ni EcoCredits (ni el bono de
# nivel); igual cuentan para el Avance y para completar el nivel. Con legado
# igual al actual (niveles sin cambios) siempre es false.
func legado_completo(n: int) -> bool:
	var legado : Array = misiones_legado.get(n, [])
	if legado.is_empty() or legado == misiones_nivel.get(n, []):
		return false
	return _contar_hechas(n, legado) >= legado.size()
```

- [ ] **Step 4: Run tests**

Run: `test_niveles.tscn`, `test_rangos.tscn`, `test_puntaje.tscn`, `test_compila.tscn` → todas exit=0.

- [ ] **Step 5: Commit**

```bash
git add autoload/NivelManager.gd tests/test_niveles.gd
git commit -m "niveles: Nivel 5 pasa a las 9 misiones del Plan de Movilidad con legado y sin re-pago

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: Piezas de interfaz del Nivel 5  *(Ola 1, paralela)*

**Files:**
- Create: `scenes/misiones/ui_movilidad.gd`
- Test: `tests/test_ui_movilidad.gd`, `tests/test_ui_movilidad.tscn`

**Interfaces:**
- Produces (`const UI := preload("res://scenes/misiones/ui_movilidad.gd")`), todas estáticas:
  - `UI.ACENTO` (= `HUD_TEMA.VIOLETA`)
  - `UI.panel_modal(capa: CanvasLayer, ancho: float) -> VBoxContainer` (agrega `Fondo` + `Centro/Panel/Contenido`)
  - `UI.texto(t: String, tam := 13, color := TEMA.TEXTO, peso := 400) -> Label` (con autowrap)
  - `UI.boton(t: String, color := ACENTO, alto := 40) -> Button`
  - `UI.pintar_boton(b: Button, color: Color, resaltado: bool) -> void`
  - `UI.separador() -> HSeparator`
  - `UI.barra(fraccion: float) -> ProgressBar` (0..100)
  - `UI.limpiar(contenedor: Node) -> void`
  - `UI.puntos(p: float) -> String` ("+0,60", "-1,00") · `UI.decimal(p: float) -> String` ("4,35")

- [ ] **Step 1: Write the failing test**

`tests/test_ui_movilidad.tscn` (nodo `TestUiMovilidad`, script `res://tests/test_ui_movilidad.gd`).

`tests/test_ui_movilidad.gd`:
```gdscript
# Prueba de las piezas de interfaz del Nivel 5 (tokens de hud_tema).
# Correr: $GODOT --headless --path . res://tests/test_ui_movilidad.tscn
extends Node

const UI := preload("res://scenes/misiones/ui_movilidad.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_ui_movilidad")
	var capa := CanvasLayer.new()
	add_child(capa)
	var vb := UI.panel_modal(capa, 640)
	_check(vb is VBoxContainer and is_equal_approx(vb.custom_minimum_size.x, 640.0), "panel modal con ancho mínimo")
	_check(capa.get_node_or_null("Fondo") != null and capa.get_node_or_null("Centro/Panel/Contenido") == vb, "estructura Fondo + Centro/Panel/Contenido")
	var caja := (capa.get_node("Centro/Panel") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	_check(caja != null and caja.border_color == TEMA.VIOLETA, "panel con borde de Transporte")

	var b := UI.boton("Hola")
	_check(b.get_theme_stylebox("normal") is StyleBoxFlat and b.focus_mode == Control.FOCUS_NONE, "botón con estilo del tema")
	_check(b.get_theme_font_size("font_size") == 13, "botón con tamaño 13")
	UI.pintar_boton(b, TEMA.VERDE, true)
	_check((b.get_theme_stylebox("normal") as StyleBoxFlat).border_color == TEMA.VERDE, "resaltado usa el color")
	UI.pintar_boton(b, TEMA.VERDE, false)
	_check((b.get_theme_stylebox("normal") as StyleBoxFlat).border_color == TEMA.VACIO, "normal usa borde apagado")
	b.free()

	var l := UI.texto("x")
	_check(l.autowrap_mode != TextServer.AUTOWRAP_OFF and l.text == "x", "texto con autowrap")
	l.free()
	var barra := UI.barra(0.25)
	_check(is_equal_approx(barra.value, 25.0) and not barra.show_percentage, "barra al 25 %")
	barra.free()
	UI.separador().free()

	_check(UI.puntos(0.6) == "+0,60", "puntos positivos")
	_check(UI.puntos(-1.0) == "-1,00", "puntos negativos")
	_check(UI.decimal(4.35) == "4,35", "decimal con coma")

	for i in 3:
		vb.add_child(Label.new())
	UI.limpiar(vb)
	_check(vb.get_child_count() == 0, "limpiar vacía el contenedor")

	print("test_ui_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_ui_movilidad.tscn; echo exit=$?` → Expected: error de preload, exit≠0.

- [ ] **Step 3: Implement**

`scenes/misiones/ui_movilidad.gd`:
```gdscript
# ============================================================
# ui_movilidad.gd — piezas de interfaz del Nivel 5 (Plan de Movilidad),
# construidas SOLO con los tokens de hud_tema.gd: panel centrado, textos,
# botones, barra y formato de números. Los tres paneles del nivel las usan
# para verse como el HUD plano; cambiar de estilo = cambiar hud_tema.gd.
# ============================================================
extends RefCounted

const TEMA := preload("res://scenes/ui/hud_tema.gd")

const ACENTO := TEMA.VIOLETA   # color de Transporte en el HUD


# Fondo oscuro + panel centrado que se ajusta a su contenido. Devuelve el
# VBoxContainer donde va el contenido.
static func panel_modal(capa: CanvasLayer, ancho: float) -> VBoxContainer:
	var fondo := ColorRect.new()
	fondo.name = "Fondo"
	fondo.color = Color(TEMA.POPOVER_BG, 0.6)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)
	var centro := CenterContainer.new()
	centro.name = "Centro"
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", TEMA.panel(ACENTO))
	centro.add_child(panel)
	var vb := VBoxContainer.new()
	vb.name = "Contenido"
	vb.custom_minimum_size = Vector2(ancho, 0)
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	return vb


static func texto(t: String, tam: int = 13, color: Color = TEMA.TEXTO, peso: int = 400) -> Label:
	var l := TEMA.label(t, tam, color, peso)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func boton(t: String, color: Color = ACENTO, alto: int = 40) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, alto)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", TEMA.rubik(600))
	b.add_theme_font_size_override("font_size", 13)
	pintar_boton(b, color, false)
	return b


# resaltado = elegido (fondo teñido y borde del color); normal = caja oscura.
static func pintar_boton(b: Button, color: Color, resaltado: bool) -> void:
	var fondo := Color(color, 0.28) if resaltado else TEMA.POPOVER_BG
	var borde := color if resaltado else TEMA.VACIO
	b.add_theme_stylebox_override("normal", TEMA.caja(fondo, borde, 2, 10, 12, 8))
	var hover := TEMA.caja(Color(color, 0.18), color, 2, 10, 12, 8)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled",
		TEMA.caja(fondo, color if resaltado else TEMA.PASO_PENDIENTE, 2, 10, 12, 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for clave in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(clave, TEMA.TEXTO)
	b.add_theme_color_override("font_disabled_color", TEMA.TEXTO if resaltado else TEMA.APAGADO)


static func separador() -> HSeparator:
	var s := HSeparator.new()
	var linea := StyleBoxLine.new()
	linea.color = TEMA.SEPARADOR
	linea.thickness = 1
	s.add_theme_stylebox_override("separator", linea)
	return s


static func barra(fraccion: float) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0.0
	pb.max_value = 100.0
	pb.value = clampf(fraccion, 0.0, 1.0) * 100.0
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 10)
	pb.add_theme_stylebox_override("background", TEMA.caja(TEMA.TRACK, TEMA.TRACK, 0, 5))
	pb.add_theme_stylebox_override("fill", TEMA.caja(TEMA.DORADO, TEMA.DORADO, 0, 5))
	return pb


static func limpiar(contenedor: Node) -> void:
	for c in contenedor.get_children():
		contenedor.remove_child(c)
		c.queue_free()


static func puntos(p: float) -> String:
	return ("%+.2f" % p).replace(".", ",")


static func decimal(p: float) -> String:
	return ("%.2f" % p).replace(".", ",")
```

- [ ] **Step 4: Run test to verify it passes**

Run: igual que Step 2 → exit=0.

- [ ] **Step 5: Commit**

```bash
git add scenes/misiones/ui_movilidad.gd scenes/misiones/ui_movilidad.gd.uid tests/test_ui_movilidad.gd tests/test_ui_movilidad.gd.uid tests/test_ui_movilidad.tscn
git commit -m "nivel 5: piezas de interfaz con los tokens del HUD plano

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: Lógica del plan  *(Ola 2, paralela con 7; requiere Task 2)*

**Files:**
- Create: `scenes/misiones/plan_movilidad.gd`
- Test: `tests/test_plan_movilidad.gd`, `tests/test_plan_movilidad.tscn`

**Interfaces:**
- Consumes: `DATOS` (Task 2).
- Produces (`const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")`, instancia con `PLAN.new()`):
  - `const VERSION := 1`, `const MAX_CAMBIOS_CONSEJO := 2`
  - Estado: `encargo_aceptado: bool`, `decisiones: Dictionary` (id → `{opcion, costo, contraproducentes: Array, cambios}`), `cambios_en_consejo: int`, `consejo: Dictionary` (`{}` hasta presentar; forma en spec §9).
  - `cargar(d: Dictionary)`, `a_detalle() -> Dictionary`, `vacio() -> bool`
  - `opcion_actual(id) -> String`, `resuelta(id) -> bool`, `costo_comprometido(excepto := "") -> int`, `restante(excepto := "") -> int`
  - `alcanza(id, opcion) -> bool`, `faltante(id, opcion) -> int`, `descartada(id, opcion) -> bool`
  - `registrar_contraproducente(id, opcion)`, `aplicar_valida(id, opcion, en_consejo := false) -> bool`
  - `todas_resueltas()`, `presentado()`, `puede_presentar()`, `puede_cambiar_en_consejo()` `-> bool`
  - `penalizaciones(id) -> int`, `debilidad(id) -> int`, `objeciones() -> Array` (`{decision, opcion, texto, argumentos}`)
  - `puntos_opciones() -> float`, `calificacion_estimada() -> float`, `sinergias() -> Array`
  - `presentar(resultados: Array)` (cada resultado `{decision, opcion, primer_argumento, correcto_primer_intento, intentos}`)

- [ ] **Step 1: Write the failing test**

`tests/test_plan_movilidad.tscn` (nodo `TestPlanMovilidad`, script `res://tests/test_plan_movilidad.gd`).

`tests/test_plan_movilidad.gd`:
```gdscript
# Prueba de las reglas del Plan de Movilidad sin interfaz: presupuesto,
# descartes, cambios, objeciones, calificación, sinergias y serialización.
# Correr: $GODOT --headless --path . res://tests/test_plan_movilidad.tscn
extends Node

const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")

const MEJOR := {
	"tr_permisos": "permiso_por_necesidad", "tr_lote": "ciclovia_arborizada",
	"tr_carpool": "puestos_3_ocupantes", "tr_shuttle": "ruta_a_paradas",
	"tr_dia_sin_carros": "jornada_mensual_con_feria", "tr_flota": "carritos_electricos",
	"tr_bici_bloque_e": "techado_con_panel", "tr_bici_cafetin": "techado_con_panel",
}
const BARATO := {
	"tr_permisos": "permiso_por_necesidad", "tr_lote": "plaza_de_eventos",
	"tr_carpool": "puestos_3_ocupantes", "tr_shuttle": "ruta_a_paradas",
	"tr_dia_sin_carros": "jornada_mensual_con_feria", "tr_flota": "triciclos_de_carga",
	"tr_bici_bloque_e": "simple_con_candado", "tr_bici_cafetin": "simple_con_candado",
}

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _con(elecciones: Dictionary):
	var p = PLAN.new()
	p.encargo_aceptado = true
	for id in elecciones.keys():
		p.aplicar_valida(id, elecciones[id])
	return p


func _ids(objeciones: Array) -> Array:
	var out := []
	for o in objeciones:
		out.append(o["decision"])
	return out


func _ready() -> void:
	print("test_plan_movilidad")
	var p = PLAN.new()
	_check(p.vacio() and p.restante() == 100 and not p.resuelta("tr_lote"), "plan nuevo vacío con 100")
	_check(not p.aplicar_valida("tr_lote", "asfaltar_lote"), "contraproducente no se aplica como válida")
	_check(not p.aplicar_valida("tr_lote", "no_existe"), "opción inexistente rechazada")
	_check(p.aplicar_valida("tr_shuttle", "park_and_ride") and p.restante() == 66, "válida gasta su costo")
	_check(p.aplicar_valida("tr_dia_sin_carros", "cierre_semanal"), "segunda válida")
	_check(p.aplicar_valida("tr_lote", "ciclovia_arborizada") and p.restante() == 16, "quedan 16")
	_check(not p.alcanza("tr_flota", "carritos_electricos") and p.faltante("tr_flota", "carritos_electricos") == 2, "faltan 2")
	_check(p.alcanza("tr_flota", "triciclos_de_carga") and p.faltante("tr_flota", "triciclos_de_carga") == 0, "triciclos alcanzan")
	_check(not p.aplicar_valida("tr_flota", "carritos_electricos"), "sin presupuesto no se aplica")
	_check(p.restante("tr_shuttle") == 50, "restante liberando la opción actual")
	_check(p.aplicar_valida("tr_shuttle", "ruta_a_paradas") and p.restante() == 24, "cambio libera el costo anterior")
	_check(int(p.decisiones["tr_shuttle"]["cambios"]) == 1, "cambio contado")
	_check(p.aplicar_valida("tr_shuttle", "ruta_a_paradas") and int(p.decisiones["tr_shuttle"]["cambios"]) == 1, "misma opción no cuenta cambio")
	_check(p.alcanza("tr_shuttle", "ruta_a_paradas"), "la opción actual siempre alcanza")

	p.registrar_contraproducente("tr_flota", "camioneta_diesel")
	p.registrar_contraproducente("tr_flota", "camioneta_diesel")
	_check(p.descartada("tr_flota", "camioneta_diesel") and p.penalizaciones("tr_flota") == 1, "descarte único")
	_check(not p.resuelta("tr_flota") and p.restante() == 24, "contraproducente no gasta ni resuelve")
	_check(not p.vacio(), "con decisiones ya no está vacío")

	var m = _con(MEJOR)
	_check(m.todas_resueltas() and m.restante() == 0, "plan de 5,00 cuesta 100 exacto")
	_check(is_equal_approx(m.puntos_opciones(), 4.0), "mejores opciones = 4,00")
	_check(m.puede_presentar(), "puede presentar")
	var obj : Array = m.objeciones()
	_check(_ids(obj) == ["tr_permisos", "tr_carpool", "tr_dia_sin_carros"], "objeciones del plan de 5,00: %s" % str(_ids(obj)))
	_check(obj.size() == 3 and obj[0]["argumentos"].size() == 3 and str(obj[0]["texto"]) != "" and obj[0]["opcion"] == "permiso_por_necesidad", "objeción completa")
	_check(m.sinergias() == ["ciclovia_lote", "dia_sin_carros_feria", "flota_electrica", "bicicletero_techado_solar"], "cruces del plan de 5,00")

	var b = _con(BARATO)
	_check(b.costo_comprometido() == 74, "plan barato cuesta 74")
	_check(b.debilidad("tr_lote") == 4 and b.debilidad("tr_carpool") == 2 and b.debilidad("tr_permisos") == 3, "debilidades")
	_check(_ids(b.objeciones()) == ["tr_lote", "tr_flota", "tr_bici_bloque_e"], "objeciones del plan barato: %s" % str(_ids(b.objeciones())))
	b.registrar_contraproducente("tr_permisos", "pintar_mas_puestos")
	_check(_ids(b.objeciones()) == ["tr_permisos", "tr_lote", "tr_flota"], "contraproducente probada sube la debilidad")
	_check(is_equal_approx(b.calificacion_estimada(), 2.35), "3,35 - 1 = 2,35 (%.2f)" % b.calificacion_estimada())
	_check(b.sinergias() == ["dia_sin_carros_feria"], "cruces del plan barato")

	_check(b.puede_cambiar_en_consejo(), "puede cambiar en el Consejo")
	_check(b.aplicar_valida("tr_lote", "ciclovia_arborizada", true), "primer cambio en el Consejo")
	_check(b.aplicar_valida("tr_flota", "carritos_electricos", true), "segundo cambio en el Consejo")
	_check(b.cambios_en_consejo == 2 and not b.puede_cambiar_en_consejo(), "máximo 2 cambios")
	_check(not b.aplicar_valida("tr_bici_bloque_e", "techado_con_panel", true), "tercer cambio rechazado")

	var res := [
		{"decision": "tr_permisos", "opcion": "permiso_por_necesidad", "primer_argumento": 1, "correcto_primer_intento": true, "intentos": 1},
		{"decision": "tr_lote", "opcion": "ciclovia_arborizada", "primer_argumento": 0, "correcto_primer_intento": false, "intentos": 2},
		{"decision": "tr_flota", "opcion": "carritos_electricos", "primer_argumento": 0, "correcto_primer_intento": true, "intentos": 1},
	]
	b.presentar(res)
	_check(b.presentado() and not b.puede_presentar(), "presentado")
	_check(int(b.consejo["aciertos"]) == 2 and b.consejo["calificacion"] == "consejo_2", "calificación consejo_2")
	_check(b.consejo["registrado"] == false, "todavía sin registrar")
	_check(is_equal_approx(b.calificacion_estimada(), 3.4), "3,80 + 0,60 - 1 = 3,40 (%.2f)" % b.calificacion_estimada())
	_check(b.consejo["sinergias"] == ["ciclovia_lote", "dia_sin_carros_feria", "flota_electrica"], "cruces congelados al presentar")
	_check(not b.aplicar_valida("tr_bici_cafetin", "techado_con_panel"), "plan presentado: cerrado")
	_check(not b.puede_cambiar_en_consejo(), "sin cambios tras presentar")

	var det : Dictionary = b.a_detalle()
	_check(det["version"] == 1 and det["presupuesto"]["total"] == 100 and det["presupuesto"]["comprometido"] == 94, "detalle con presupuesto")
	var txt := JSON.stringify(det)
	_check(txt.length() < 8192, "detalle < 8 KB (%d)" % txt.length())
	var c = PLAN.new()
	c.cargar(JSON.parse_string(txt))
	_check(c.presentado() and c.opcion_actual("tr_flota") == "carritos_electricos" and c.costo_comprometido() == 94, "ida y vuelta")
	_check(c.descartada("tr_permisos", "pintar_mas_puestos") and c.cambios_en_consejo == 2 and c.encargo_aceptado, "ida y vuelta conserva descartes y cambios")

	var roto = PLAN.new()
	roto.cargar({"encargo_aceptado": true, "consejo": "roto", "decisiones": {
		"tr_lote": {"opcion": "asfaltar_lote", "costo": 0},
		"inventada": {"opcion": "x"},
		"tr_flota": "no es un diccionario",
		"tr_carpool": {"opcion": "app_carpool", "costo": 1},
	}})
	_check(not roto.resuelta("tr_lote"), "contraproducente guardada como elegida se ignora")
	_check(not roto.decisiones.has("inventada") and not roto.decisiones.has("tr_flota"), "entradas inválidas ignoradas")
	_check(roto.costo_comprometido() == 26, "el costo sale de los datos, no del JSON")
	_check(roto.consejo.is_empty(), "consejo corrupto se ignora")
	var vacio = PLAN.new()
	vacio.cargar({})
	_check(vacio.vacio(), "detalle vacío = plan vacío")

	print("test_plan_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_plan_movilidad.tscn; echo exit=$?` → Expected: error de preload, exit≠0.

- [ ] **Step 3: Implement**

`scenes/misiones/plan_movilidad.gd`:
```gdscript
# ============================================================
# plan_movilidad.gd — estado y reglas del Plan de Movilidad (Nivel 5).
# Lógica pura, sin autoloads ni nodos (tests/test_plan_movilidad.gd). Se
# guarda en detalles_estudiante con la clave "plan_movilidad" (forma exacta:
# a_detalle(); spec §9).
# El presupuesto lo calcula el cliente (no es moneda: limitación documentada
# en la spec §18); cada opción la valida registrar_decision en el servidor.
# ============================================================
extends RefCounted

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")

const VERSION := 1
const MAX_CAMBIOS_CONSEJO := 2

var encargo_aceptado : bool = false
# decision_id -> {"opcion": String, "costo": int, "contraproducentes": Array, "cambios": int}
var decisiones : Dictionary = {}
var cambios_en_consejo : int = 0
# {} hasta presentar; ver presentar().
var consejo : Dictionary = {}


# Tolerante a datos viejos o corruptos: ignora decisiones/opciones que no
# existen, trata una contraproducente guardada como elegida como vacía y
# toma los costos de DATOS, no del JSON.
func cargar(d: Dictionary) -> void:
	encargo_aceptado = bool(d.get("encargo_aceptado", false))
	decisiones = {}
	var decs = d.get("decisiones", {})
	if decs is Dictionary:
		for id in decs.keys():
			var e = decs[id]
			if not (e is Dictionary) or DATOS.decision(str(id)).is_empty():
				continue
			var contras : Array = []
			var guardadas = e.get("contraproducentes", [])
			if guardadas is Array:
				for x in guardadas:
					if not DATOS.opcion(str(id), str(x)).is_empty() and not (str(x) in contras):
						contras.append(str(x))
			var op := str(e.get("opcion", ""))
			var dato_op := DATOS.opcion(str(id), op)
			if dato_op.is_empty() or bool(dato_op["contraproducente"]):
				op = ""
			decisiones[str(id)] = {
				"opcion": op,
				"costo": int(dato_op["costo"]) if op != "" else 0,
				"contraproducentes": contras,
				"cambios": int(e.get("cambios", 0)),
			}
	cambios_en_consejo = int(d.get("cambios_en_consejo", 0))
	var con = d.get("consejo", {})
	consejo = con.duplicate(true) if con is Dictionary else {}


func a_detalle() -> Dictionary:
	return {
		"version": VERSION,
		"encargo_aceptado": encargo_aceptado,
		"presupuesto": {"total": DATOS.PRESUPUESTO, "comprometido": costo_comprometido()},
		"decisiones": decisiones.duplicate(true),
		"cambios_en_consejo": cambios_en_consejo,
		"consejo": consejo.duplicate(true),
	}


func vacio() -> bool:
	return not encargo_aceptado and decisiones.is_empty()


func opcion_actual(decision_id: String) -> String:
	return str(decisiones.get(decision_id, {}).get("opcion", ""))


func resuelta(decision_id: String) -> bool:
	return opcion_actual(decision_id) != ""


func costo_comprometido(excepto: String = "") -> int:
	var total := 0
	for id in decisiones.keys():
		if id != excepto:
			total += int(decisiones[id].get("costo", 0))
	return total


func restante(excepto: String = "") -> int:
	return DATOS.PRESUPUESTO - costo_comprometido(excepto)


# La opción actual siempre alcanza; otra, si su costo entra liberando el de
# la opción actual de esa decisión.
func alcanza(decision_id: String, opcion_id: String) -> bool:
	var o := DATOS.opcion(decision_id, opcion_id)
	if o.is_empty():
		return false
	if opcion_actual(decision_id) == opcion_id:
		return true
	return int(o["costo"]) <= restante(decision_id)


func faltante(decision_id: String, opcion_id: String) -> int:
	var o := DATOS.opcion(decision_id, opcion_id)
	if o.is_empty() or alcanza(decision_id, opcion_id):
		return 0
	return int(o["costo"]) - restante(decision_id)


func descartada(decision_id: String, opcion_id: String) -> bool:
	return opcion_id in decisiones.get(decision_id, {}).get("contraproducentes", [])


func _entrada(decision_id: String) -> Dictionary:
	if not decisiones.has(decision_id):
		decisiones[decision_id] = {"opcion": "", "costo": 0, "contraproducentes": [], "cambios": 0}
	return decisiones[decision_id]


func registrar_contraproducente(decision_id: String, opcion_id: String) -> void:
	if DATOS.opcion(decision_id, opcion_id).is_empty():
		return
	var e := _entrada(decision_id)
	if not (opcion_id in e["contraproducentes"]):
		e["contraproducentes"].append(opcion_id)


# Aplica una opción válida ya confirmada por el servidor. false si no se
# aplica: inexistente, contraproducente, sin presupuesto, plan presentado o,
# en el Consejo, sin cambios disponibles.
func aplicar_valida(decision_id: String, opcion_id: String, en_consejo: bool = false) -> bool:
	var o := DATOS.opcion(decision_id, opcion_id)
	if o.is_empty() or bool(o["contraproducente"]) or presentado():
		return false
	var anterior := opcion_actual(decision_id)
	if anterior == opcion_id:
		return true
	if not alcanza(decision_id, opcion_id):
		return false
	if en_consejo and not puede_cambiar_en_consejo():
		return false
	var e := _entrada(decision_id)
	e["opcion"] = opcion_id
	e["costo"] = int(o["costo"])
	if anterior != "":
		e["cambios"] = int(e["cambios"]) + 1
		if en_consejo:
			cambios_en_consejo += 1
	return true


func todas_resueltas() -> bool:
	for id in DATOS.ids_decisiones():
		if not resuelta(id):
			return false
	return true


func presentado() -> bool:
	return bool(consejo.get("presentado", false))


func puede_presentar() -> bool:
	return encargo_aceptado and todas_resueltas() and not presentado()


func puede_cambiar_en_consejo() -> bool:
	return not presentado() and cambios_en_consejo < MAX_CAMBIOS_CONSEJO


func penalizaciones(decision_id: String) -> int:
	return mini(3, decisiones.get(decision_id, {}).get("contraproducentes", []).size())


# Spec §7.2: aceptación (baja 3, media 2, alta 1) + 2 si no es la mejor
# opción + contraproducentes probadas (máx. 3).
func debilidad(decision_id: String) -> int:
	var op := opcion_actual(decision_id)
	if op == "":
		return 0
	var o := DATOS.opcion(decision_id, op)
	var d := int(DATOS.ACEPTACION_PESO.get(o["aceptacion"], 1))
	if op != DATOS.mejor_opcion(decision_id):
		d += 2
	return d + penalizaciones(decision_id)


# Las 3 decisiones más débiles; empate = orden de DATOS.DECISIONES.
func objeciones() -> Array:
	var ids := DATOS.ids_decisiones()
	var orden := []
	for i in ids.size():
		if resuelta(ids[i]):
			orden.append({"id": ids[i], "d": debilidad(ids[i]), "i": i})
	orden.sort_custom(func(a, b): return a["d"] > b["d"] or (a["d"] == b["d"] and a["i"] < b["i"]))
	var out := []
	for e in orden:
		if out.size() == 3:
			break
		var op := opcion_actual(e["id"])
		var obj := DATOS.objecion(e["id"], op)
		if obj.is_empty():
			continue
		out.append({"decision": e["id"], "opcion": op, "texto": obj["texto"], "argumentos": obj["argumentos"]})
	return out


func puntos_opciones() -> float:
	var total := 0.0
	for id in decisiones.keys():
		var op := opcion_actual(id)
		if op != "":
			total += float(DATOS.opcion(id, op)["puntos"])
	return total


# Estimación local del componente Decisiones de Transporte (0–5), con la
# misma fórmula del servidor. El número oficial es el de puntaje_greenmetric.
func calificacion_estimada() -> float:
	var total := puntos_opciones()
	if presentado():
		total += float(DATOS.calificacion(int(consejo.get("aciertos", 0)))["puntos"])
	for id in decisiones.keys():
		total -= penalizaciones(id)
	return clampf(total, 0.0, 5.0)


func sinergias() -> Array:
	var out := []
	for id in DATOS.ids_decisiones():
		var op := opcion_actual(id)
		if op == "":
			continue
		var s := str(DATOS.opcion(id, op).get("sinergia", ""))
		if s != "" and not (s in out):
			out.append(s)
	return out


func presentar(resultados: Array) -> void:
	var aciertos := 0
	for r in resultados:
		if r is Dictionary and bool(r.get("correcto_primer_intento", false)):
			aciertos += 1
	aciertos = mini(aciertos, 3)
	consejo = {
		"presentado": true,
		"aciertos": aciertos,
		"calificacion": DATOS.calificacion(aciertos)["id"],
		"objeciones": resultados.duplicate(true),
		"sinergias": sinergias(),
		"registrado": false,
	}
```

- [ ] **Step 4: Run test to verify it passes**

Run: igual que Step 2 → exit=0, ninguna `FALLA`.

- [ ] **Step 5: Commit**

```bash
git add scenes/misiones/plan_movilidad.gd scenes/misiones/plan_movilidad.gd.uid tests/test_plan_movilidad.gd tests/test_plan_movilidad.gd.uid tests/test_plan_movilidad.tscn
git commit -m "nivel 5: reglas del Plan de Movilidad (presupuesto, objeciones, calificación)

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 7: Punto del Plan de Movilidad en el mapa  *(Ola 2, paralela con 6; requiere Tasks 1 y 5)*

**Files:**
- Create: `scenes/misiones/punto_movilidad.gd`
- Test: `tests/test_punto_movilidad.gd`, `tests/test_punto_movilidad.tscn`

**Interfaces:**
- Consumes: `LUGARES.posicion` (Task 1), `hud_tema.gd`.
- Produces (`const PUNTO := preload("res://scenes/misiones/punto_movilidad.gd")`, `Area2D`):
  - Propiedades a fijar ANTES de `add_child`: `mision_id: String`, `tipo: String` (`oficina|decision|bicicletero|consejo`), `lugar: String`, `desplazamiento: Vector2`, `nombre_punto: String`.
  - `estado: String` (`bloqueado|pendiente|resuelto`), `set_estado(nuevo)`, `texto_prompt() -> String`, `intentar_interactuar()`, `_jugador_cerca: bool`.
  - `signal interaccion_solicitada(punto: Area2D)` (no se emite si está `bloqueado` o lejos).
  - Grupo `punto_movilidad`; radio de detección 55.

- [ ] **Step 1: Write the failing test**

`tests/test_punto_movilidad.tscn` (nodo `TestPuntoMovilidad`, script `res://tests/test_punto_movilidad.gd`).

`tests/test_punto_movilidad.gd`:
```gdscript
# Prueba del punto genérico del Plan de Movilidad: ubicación por lugar,
# estados, texto del cartel e interacción.
# Correr: $GODOT --headless --path . res://tests/test_punto_movilidad.tscn
extends Node

const PUNTO := preload("res://scenes/misiones/punto_movilidad.gd")
const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _nuevo(tipo: String, lugar: String, nombre: String) -> Area2D:
	var p : Area2D = PUNTO.new()
	p.mision_id = "tr_lote"
	p.tipo = tipo
	p.lugar = lugar
	p.nombre_punto = nombre
	return p


func _ready() -> void:
	print("test_punto_movilidad")
	var p := _nuevo("decision", "lote_este", "El lote poco usado")
	p.desplazamiento = Vector2(4, -6)
	add_child(p)
	_check(p.position == LUGARES.posicion("lote_este", Vector2(4, -6)), "ubicado por lugar + desplazamiento")
	_check(p.is_in_group("punto_movilidad"), "grupo punto_movilidad")
	var forma : CollisionShape2D = null
	for c in p.get_children():
		if c is CollisionShape2D:
			forma = c
	_check(forma != null and is_equal_approx((forma.shape as CircleShape2D).radius, 55.0), "radio 55")

	var n := [0]
	p.interaccion_solicitada.connect(func(_x): n[0] += 1)
	p.set_estado("pendiente")
	_check(p.texto_prompt().contains("Decidir") and p.texto_prompt().contains("El lote poco usado"), "cartel pendiente")
	p.intentar_interactuar()
	_check(n[0] == 0, "lejos no interactúa")
	p._jugador_cerca = true
	p.intentar_interactuar()
	_check(n[0] == 1, "cerca interactúa")
	p.set_estado("bloqueado")
	p.intentar_interactuar()
	_check(n[0] == 1 and p.texto_prompt().begins_with("🔒"), "bloqueado no interactúa y lo explica")
	p.set_estado("resuelto")
	_check(p.texto_prompt().contains("Revisar"), "cartel resuelto")
	_check(p._prompt_lbl.text == p.texto_prompt(), "el cartel muestra el texto del estado")
	var caja := p._prompt.get_theme_stylebox("panel") as StyleBoxFlat
	_check(caja != null and caja.border_color == TEMA.VIOLETA and caja.bg_color == TEMA.PANEL_BG, "cartel con tokens del HUD")

	for caso in [["oficina", "Oficina"], ["consejo", "Consejo"], ["bicicletero", "bicicletero"]]:
		var q := _nuevo(caso[0], "rectorado", "X")
		add_child(q)
		q.set_estado("pendiente")
		_check(q.texto_prompt().contains(caso[1]), "cartel de %s" % caso[0])
		q.queue_free()
	var c := _nuevo("consejo", "rectorado", "Consejo")
	add_child(c)
	c.set_estado("bloqueado")
	_check(c.texto_prompt().contains("8 decisiones"), "Consejo bloqueado explica el requisito")
	await get_tree().process_frame
	await get_tree().process_frame

	print("test_punto_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_punto_movilidad.tscn; echo exit=$?` → Expected: error de preload, exit≠0.

- [ ] **Step 3: Implement**

`scenes/misiones/punto_movilidad.gd`:
```gdscript
# ============================================================
# punto_movilidad.gd — NIVEL 5: punto del Plan de Movilidad en el mapa.
# Un solo script para la Oficina, las 6 decisiones, los 2 bicicleteros y el
# Consejo. Se ubica por LUGAR (scenes/mapa/lugares_campus.gd) +
# desplazamiento: nunca con coordenadas propias. El controlador
# (nivel5_movilidad.gd) le fija el estado y escucha interaccion_solicitada.
# ============================================================
extends Area2D

const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

signal interaccion_solicitada(punto: Area2D)

const RADIO_DETEC : float = 55.0

@export var mision_id : String = ""
@export var tipo : String = "decision"        # oficina | decision | bicicletero | consejo
@export var lugar : String = ""
@export var desplazamiento : Vector2 = Vector2.ZERO
@export var nombre_punto : String = ""

var estado : String = "pendiente"              # bloqueado | pendiente | resuelto
var _jugador_cerca : bool = false
var _icono : Icono = null
var _prompt_capa : CanvasLayer = null
var _prompt : PanelContainer = null
var _prompt_lbl : Label = null


# Ícono dibujado (mismo estilo procedural que mapa_campus.gd). Solo el
# estado "pendiente" redibuja cada frame, por rendimiento en la web.
class Icono extends Node2D:
	var tipo : String = "decision"
	var estado : String = "pendiente"
	var acento : Color = Color.WHITE
	var verde : Color = Color.WHITE
	var apagado : Color = Color.WHITE
	var _t : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var col : Color = apagado if estado == "bloqueado" else acento
		if estado == "pendiente":
			draw_circle(Vector2.ZERO, 26.0, Color(col, 0.14 + 0.08 * sin(_t * 2.2)))
		draw_circle(Vector2(0, 14), 12.0, Color(0, 0, 0, 0.22))
		match tipo:
			"oficina":
				draw_rect(Rect2(-14, -6, 28, 20), col.darkened(0.45))
				draw_rect(Rect2(-14, -6, 28, 20), col, false, 2.0)
				draw_colored_polygon(PackedVector2Array([Vector2(-18, -6), Vector2(18, -6), Vector2(0, -20)]), col)
			"consejo":
				draw_colored_polygon(PackedVector2Array([Vector2(-18, -8), Vector2(18, -8), Vector2(0, -20)]), col)
				for x in [-12.0, -2.0, 8.0]:
					draw_rect(Rect2(x, -6, 4, 18), col.lightened(0.2))
				draw_rect(Rect2(-18, 12, 36, 4), col.darkened(0.3))
			"bicicletero":
				draw_rect(Rect2(-16, -16, 32, 4), col)
				for x in [-9.0, 0.0, 9.0]:
					draw_arc(Vector2(x, 8), 5.0, PI, TAU, 10, col.lightened(0.3), 2.0)
			_:
				draw_line(Vector2(0, 14), Vector2(0, -8), col.darkened(0.2), 3.0)
				draw_rect(Rect2(-14, -22, 28, 14), col.darkened(0.45))
				draw_rect(Rect2(-14, -22, 28, 14), col, false, 2.0)
		if estado == "resuelto":
			draw_line(Vector2(8, -2), Vector2(12, 3), verde, 2.5)
			draw_line(Vector2(12, 3), Vector2(20, -8), verde, 2.5)


func _ready() -> void:
	add_to_group("punto_movilidad")
	position = LUGARES.posicion(lugar, desplazamiento)
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RADIO_DETEC
	forma.shape = circulo
	add_child(forma)
	_icono = Icono.new()
	_icono.tipo = tipo
	_icono.acento = TEMA.VIOLETA
	_icono.verde = TEMA.VERDE
	_icono.apagado = TEMA.APAGADO
	_icono.z_index = 1
	add_child(_icono)
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	set_estado(estado)


func _crear_prompt() -> void:
	_prompt_capa = CanvasLayer.new()
	_prompt_capa.layer = 12
	add_child(_prompt_capa)
	_prompt = PanelContainer.new()
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_theme_stylebox_override("panel", TEMA.caja(TEMA.PANEL_BG, TEMA.VIOLETA, 2, 10, 12, 6))
	_prompt_capa.add_child(_prompt)
	_prompt_lbl = TEMA.label("", 13, TEMA.TEXTO, 600)
	_prompt.add_child(_prompt_lbl)


func set_estado(nuevo: String) -> void:
	estado = nuevo
	if _prompt_lbl:
		_prompt_lbl.text = texto_prompt()
	if _icono:
		_icono.estado = nuevo
		_icono.set_process(nuevo == "pendiente")
		_icono.queue_redraw()


func texto_prompt() -> String:
	if estado == "bloqueado":
		if tipo == "consejo":
			return "🔒 El Consejo recibe el plan con las 8 decisiones listas"
		return "🔒 Primero pasa por la Oficina de Movilidad"
	var pendiente := estado == "pendiente"
	match tipo:
		"oficina":
			return "E · Oficina de Movilidad" if pendiente else "E · Ver el Plan de Movilidad"
		"consejo":
			return "E · Presentar el plan al Consejo" if pendiente else "E · Ver resultado del Consejo"
		"bicicletero":
			return ("E · Instalar bicicletero — %s" if pendiente else "E · Revisar bicicletero — %s") % nombre_punto
	return ("E · Decidir — %s" if pendiente else "E · Revisar decisión — %s") % nombre_punto


func _process(_delta: float) -> void:
	if _prompt == null or not _prompt.visible:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var origen := cam.get_screen_center_position() - vp * 0.5 / cam.zoom
	var pantalla := (global_position + Vector2(0, -44) - origen) * cam.zoom
	_prompt.reset_size()
	_prompt.position = pantalla - Vector2(_prompt.size.x * 0.5, _prompt.size.y)


func _al_entrar(body: Node) -> void:
	if not body.is_in_group("jugador"):
		return
	_jugador_cerca = true
	_prompt_lbl.text = texto_prompt()
	_prompt.visible = true


func _al_salir(body: Node) -> void:
	if not body.is_in_group("jugador"):
		return
	_jugador_cerca = false
	_prompt.visible = false


func intentar_interactuar() -> void:
	if not _jugador_cerca or estado == "bloqueado":
		return
	_prompt.visible = false
	interaccion_solicitada.emit(self)
```

- [ ] **Step 4: Run test to verify it passes**

Run: igual que Step 2 → exit=0, sin `SCRIPT ERROR`.

- [ ] **Step 5: Commit**

```bash
git add scenes/misiones/punto_movilidad.gd scenes/misiones/punto_movilidad.gd.uid tests/test_punto_movilidad.gd tests/test_punto_movilidad.gd.uid tests/test_punto_movilidad.tscn
git commit -m "nivel 5: punto genérico del Plan de Movilidad ubicado por lugar

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 8: Panel de decisión (regla Mixta)  *(Ola 3, paralela con 9 y 10; requiere Tasks 5 y 6)*

**Files:**
- Create: `scenes/misiones/panel_decision_movilidad.gd`
- Test: `tests/test_panel_decision_movilidad.gd`, `tests/test_panel_decision_movilidad.tscn`

**Interfaces:**
- Consumes: `PLAN` (Task 6), `DATOS` (Task 2), `UI` (Task 5).
- Produces (`CanvasLayer`, capa 20):
  - `var plan` (instancia de `plan_movilidad.gd`), `var registrar : Callable` (`(decision_id, opcion_id) -> void`)
  - `var decision_id: String`, `var estado: String` (`cerrado|eligiendo|esperando|revelado_contra|revelado_valida|solo_lectura`), `var modo_consejo: bool`
  - `abrir(id: String, en_consejo := false)`, `cerrar()` (no cierra en `esperando`), `recibir_respuesta(decision_id, opcion_id, respuesta: Dictionary)` (se conecta a `PuntajeManager.decision_resuelta`)
  - `signal decision_registrada(decision_id: String, opcion_id: String, contraproducente: bool, penalizado: bool, ms_hasta_elegir: int)`, `signal cerrado()`
  - Internos usados por pruebas: `_on_opcion(i)`, `_on_accion()`, `_botones`, `_detalles`, `_estado_lbl`, `_accion`, `_cerrar`.

- [ ] **Step 1: Write the failing test**

`tests/test_panel_decision_movilidad.tscn` (nodo `TestPanelDecisionMovilidad`, script `res://tests/test_panel_decision_movilidad.gd`).

`tests/test_panel_decision_movilidad.gd`:
```gdscript
# Prueba del panel de decisión: costo antes de confirmar, regla Mixta,
# error de red sin reintento automático, presupuesto y solo lectura.
# Correr: $GODOT --headless --path . res://tests/test_panel_decision_movilidad.tscn
extends Node

const PANEL := preload("res://scenes/misiones/panel_decision_movilidad.gd")
const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")
const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _idx(decision_id: String, opcion_id: String) -> int:
	var ops : Array = DATOS.decision(decision_id)["opciones"]
	for i in ops.size():
		if ops[i]["id"] == opcion_id:
			return i
	return -1


func _ready() -> void:
	print("test_panel_decision_movilidad")
	var plan = PLAN.new()
	plan.encargo_aceptado = true
	var panel : CanvasLayer = PANEL.new()
	add_child(panel)
	panel.plan = plan
	var llamadas := []
	panel.registrar = func(d, o): llamadas.append([d, o])
	var senales := []
	panel.decision_registrada.connect(func(d, o, c, p, _ms): senales.append([d, o, c, p]))
	var cerrados := [0]
	panel.cerrado.connect(func(): cerrados[0] += 1)

	var i_app := _idx("tr_carpool", "app_carpool")
	var i_3 := _idx("tr_carpool", "puestos_3_ocupantes")
	var i_contra := _idx("tr_carpool", "vender_puestos_reservados")

	panel.abrir("tr_carpool")
	_check(panel.visible and panel.estado == "eligiendo", "abre eligiendo")
	var solo_costo := true
	for det in panel._detalles:
		if det.text.contains("Transporte") or det.text.contains("Aceptación") or not det.text.contains("Costo"):
			solo_costo = false
	_check(solo_costo, "antes de confirmar: solo el costo")
	_check(panel._accion.disabled, "confirmar deshabilitado sin elección")
	panel._on_opcion(i_contra)
	_check(not panel._accion.disabled and panel._detalles[i_contra].text.begins_with("Costo"), "elegir no revela")
	panel._on_accion()
	_check(panel.estado == "esperando" and llamadas == [["tr_carpool", "vender_puestos_reservados"]], "confirmar registra una vez")
	_check(panel._cerrar.disabled and panel._botones[i_app].disabled, "esperando: nada clicable")
	panel.cerrar()
	_check(panel.visible, "no se cierra mientras espera")
	panel.recibir_respuesta("tr_lote", "asfaltar_lote", {"ok": true, "contraproducente": true, "penalizado": true})
	_check(panel.estado == "esperando", "ignora respuestas de otra decisión")

	panel.recibir_respuesta("tr_carpool", "vender_puestos_reservados", {"ok": true, "contraproducente": true, "penalizado": true})
	_check(panel.estado == "revelado_contra", "contraproducente revelada")
	_check(plan.descartada("tr_carpool", "vender_puestos_reservados") and plan.restante() == 100, "descartada y presupuesto intacto")
	_check(panel._detalles[i_contra].text.contains("Contraproducente"), "revela la elegida")
	_check(not panel._detalles[i_3].text.contains("Transporte"), "no revela las otras")
	_check(panel._estado_lbl.text.contains("-1"), "informa la penalización")
	_check(senales.back() == ["tr_carpool", "vender_puestos_reservados", true, true], "señal de contraproducente")
	panel._on_accion()
	_check(panel.estado == "eligiendo" and panel._botones[i_contra].disabled and panel._detalles[i_contra].text.contains("Descartada"), "reintento con la contraproducente descartada")

	panel._on_opcion(i_3)
	panel._on_accion()
	panel.recibir_respuesta("tr_carpool", "puestos_3_ocupantes", {"ok": false, "error": "red"})
	_check(panel.estado == "eligiendo" and not plan.resuelta("tr_carpool"), "error de red: no aplica")
	_check(llamadas.size() == 2, "error de red: no reintenta solo")
	_check(panel._estado_lbl.text.contains("No se pudo"), "error de red: lo explica")

	panel._on_accion()
	_check(llamadas.size() == 3, "el estudiante reconfirma")
	panel.recibir_respuesta("tr_carpool", "puestos_3_ocupantes", {"ok": true, "contraproducente": false})
	_check(panel.estado == "revelado_valida" and plan.opcion_actual("tr_carpool") == "puestos_3_ocupantes" and plan.restante() == 94, "válida aplicada")
	_check(panel._detalles[i_3].text.contains("Transporte +0,60") and panel._detalles[i_app].text.contains("Aceptación alta") and panel._detalles[i_contra].text.contains("Contraproducente"), "revela las tres")
	_check(senales.back() == ["tr_carpool", "puestos_3_ocupantes", false, false], "señal de válida")
	panel._on_accion()
	_check(not panel.visible and cerrados[0] == 1, "Listo cierra")

	panel.abrir("tr_carpool")
	_check(panel._detalles[i_app].text.contains("Transporte") and panel._accion.disabled and panel._accion.text == "Cambiar decisión", "reabrir: ya revelado, sin confirmar lo mismo")
	panel.cerrar()

	plan.aplicar_valida("tr_shuttle", "park_and_ride")
	plan.aplicar_valida("tr_dia_sin_carros", "cierre_semanal")
	plan.aplicar_valida("tr_lote", "ciclovia_arborizada")
	_check(plan.restante() == 10, "quedan 10")
	var i_el := _idx("tr_flota", "carritos_electricos")
	var i_tri := _idx("tr_flota", "triciclos_de_carga")
	var i_die := _idx("tr_flota", "camioneta_diesel")
	panel.abrir("tr_flota")
	_check(panel._botones[i_el].disabled and panel._detalles[i_el].text.contains("faltan 8"), "sin presupuesto: deshabilitada con faltante")
	_check(panel._botones[i_die].disabled and panel._detalles[i_die].text.contains("faltan 10"), "la contraproducente también respeta el presupuesto")
	_check(not panel._botones[i_tri].disabled, "la que alcanza queda habilitada")

	panel.registrar = Callable()
	panel._on_opcion(i_tri)
	panel._on_accion()
	_check(panel.estado == "revelado_valida" and plan.opcion_actual("tr_flota") == "triciclos_de_carga", "sin sesión: aplica en local")
	panel.cerrar()

	plan.presentar([])
	panel.abrir("tr_flota")
	var deshabilitados := true
	for b in panel._botones:
		if not b.disabled:
			deshabilitados = false
	_check(panel.estado == "solo_lectura" and deshabilitados and panel._accion.text == "Listo", "plan presentado: solo lectura")
	panel.cerrar()

	var src := FileAccess.get_file_as_string("res://scenes/misiones/panel_decision_movilidad.gd")
	_check(not src.contains("Color("), "sin colores literales: solo tokens del tema")

	print("test_panel_decision_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_panel_decision_movilidad.tscn; echo exit=$?` → Expected: error de preload, exit≠0.

- [ ] **Step 3: Implement**

`scenes/misiones/panel_decision_movilidad.gd`:
```gdscript
# ============================================================
# panel_decision_movilidad.gd — NIVEL 5: panel de una decisión del Plan de
# Movilidad (también los bicicleteros). Regla Mixta (spec §8): antes de
# confirmar solo se ve el costo; la contraproducente resta 1, no gasta y
# permite reintentar; la válida revela las tres opciones.
# Mismo patrón de interacción que simulador_decision.gd. Estilo: solo
# tokens de hud_tema.gd vía ui_movilidad.gd.
# Modifica el plan en memoria; guardar, misiones y telemetría son del
# controlador (nivel5_movilidad.gd), que escucha decision_registrada.
# ============================================================
extends CanvasLayer

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const UI := preload("res://scenes/misiones/ui_movilidad.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

signal decision_registrada(decision_id: String, opcion_id: String, contraproducente: bool, penalizado: bool, ms_hasta_elegir: int)
signal cerrado()

var plan = null                           # plan_movilidad.gd
# (decision_id, opcion_id) -> void. La respuesta llega por recibir_respuesta().
var registrar : Callable = Callable()

var decision_id : String = ""
var estado : String = "cerrado"
var modo_consejo : bool = false
var _sel : String = ""
var _t_abierto : int = 0

var _titulo : Label = null
var _lugar : Label = null
var _presupuesto : Label = null
var _contexto : Label = null
var _pregunta : Label = null
var _botones : Array = []
var _detalles : Array = []
var _estado_lbl : Label = null
var _accion : Button = null
var _cerrar : Button = null


func _ready() -> void:
	layer = 20
	_construir()
	visible = false


func abrir(id: String, en_consejo: bool = false) -> void:
	var d := DATOS.decision(id)
	if d.is_empty() or plan == null:
		return
	decision_id = id
	modo_consejo = en_consejo
	_sel = plan.opcion_actual(id)
	_t_abierto = Time.get_ticks_msec()
	_titulo.text = d["titulo"]
	_lugar.text = "%s · %s" % [DATOS.NOMBRE_LUGAR.get(d["lugar"], ""), d["indicador"]]
	_contexto.text = d["contexto"]
	_pregunta.text = d["pregunta"]
	if plan.presentado() or (en_consejo and not plan.puede_cambiar_en_consejo()):
		estado = "solo_lectura"
	else:
		estado = "eligiendo"
	_estado_lbl.text = ""
	_pintar()
	visible = true


func cerrar() -> void:
	if estado == "esperando":
		return
	estado = "cerrado"
	visible = false
	cerrado.emit()


func _on_opcion(i: int) -> void:
	if estado != "eligiendo":
		return
	var ops : Array = DATOS.decision(decision_id)["opciones"]
	_sel = ops[i]["id"]
	_pintar()


func _on_accion() -> void:
	match estado:
		"eligiendo":
			_confirmar()
		"revelado_contra":
			estado = "eligiendo"
			_sel = plan.opcion_actual(decision_id)
			_estado_lbl.text = ""
			_pintar()
		"revelado_valida", "solo_lectura":
			cerrar()


func _confirmar() -> void:
	var actual : String = plan.opcion_actual(decision_id)
	if _sel == "" or _sel == actual or not plan.alcanza(decision_id, _sel) or plan.descartada(decision_id, _sel):
		return
	estado = "esperando"
	_estado_lbl.text = "Registrando tu decisión…"
	_estado_lbl.add_theme_color_override("font_color", TEMA.TEXTO_3)
	_pintar()
	if registrar.is_valid():
		registrar.call(decision_id, _sel)
	else:
		recibir_respuesta(decision_id, _sel, {"ok": false, "error": "sin_sesion"})


# Conectado a PuntajeManager.decision_resuelta. NUNCA reintenta solo: ante un
# error vuelve a "eligiendo" y el estudiante confirma de nuevo (un reintento
# automático de una contraproducente sumaría otra penalización).
func recibir_respuesta(id: String, opcion_id: String, respuesta: Dictionary) -> void:
	if estado != "esperando" or id != decision_id or opcion_id != _sel:
		return
	var o := DATOS.opcion(decision_id, opcion_id)
	var ok := bool(respuesta.get("ok", false))
	var sin_sesion := str(respuesta.get("error", "")) == "sin_sesion"
	if not ok and not sin_sesion:
		estado = "eligiendo"
		_estado_lbl.text = "No se pudo registrar la decisión (sin conexión o error del servidor). No se aplicó nada: vuelve a confirmar cuando tengas conexión."
		_estado_lbl.add_theme_color_override("font_color", TEMA.NARANJA)
		_pintar()
		return
	var contra : bool = bool(respuesta.get("contraproducente", false)) if ok else bool(o["contraproducente"])
	var penalizado : bool = ok and bool(respuesta.get("penalizado", false))
	var ms : int = Time.get_ticks_msec() - _t_abierto
	if contra:
		plan.registrar_contraproducente(decision_id, opcion_id)
		estado = "revelado_contra"
		if penalizado:
			_estado_lbl.text = "Opción contraproducente: -1 en Decisiones de Transporte. El presupuesto no se gastó; puedes reintentar."
		elif sin_sesion:
			_estado_lbl.text = "Opción contraproducente (sin sesión: no se registró penalización). El presupuesto no se gastó; puedes reintentar."
		else:
			_estado_lbl.text = "Opción contraproducente. Ya tenías el máximo de 3 penalizaciones en esta decisión. El presupuesto no se gastó; puedes reintentar."
		_estado_lbl.add_theme_color_override("font_color", TEMA.VIDAS)
	else:
		plan.aplicar_valida(decision_id, opcion_id, modo_consejo)
		estado = "revelado_valida"
		_estado_lbl.text = "Decisión registrada. Así quedan las tres opciones:"
		_estado_lbl.add_theme_color_override("font_color", TEMA.VERDE)
	_pintar()
	decision_registrada.emit(decision_id, opcion_id, contra, penalizado, ms)


func _consecuencias(o: Dictionary) -> String:
	var partes := PackedStringArray()
	if o["contraproducente"]:
		partes.append("Contraproducente según GreenMetric")
	else:
		partes.append("Transporte %s" % UI.puntos(float(o["puntos"])))
		partes.append(str(DATOS.ACEPTACION_TEXTO.get(o["aceptacion"], "")))
	partes.append("Costo %d" % int(o["costo"]))
	var texto := " · ".join(partes) + "\n" + str(o["explicacion"])
	var s := str(o.get("sinergia", ""))
	if s != "":
		texto += "\n" + DATOS.texto_sinergia(s)
	return texto


func _pintar() -> void:
	var ops : Array = DATOS.decision(decision_id)["opciones"]
	var ya_resuelta : bool = plan.resuelta(decision_id)
	var revelar_todo : bool = ya_resuelta or estado == "revelado_valida" or estado == "solo_lectura"
	_presupuesto.text = "Presupuesto disponible: %d de %d" % [plan.restante(), DATOS.PRESUPUESTO]
	for i in ops.size():
		var o : Dictionary = ops[i]
		var b : Button = _botones[i]
		var det : Label = _detalles[i]
		b.text = o["texto"]
		var elegida : bool = o["id"] == _sel
		UI.pintar_boton(b, UI.ACENTO, elegida)
		var bloqueo := ""
		if plan.descartada(decision_id, o["id"]):
			bloqueo = "Descartada: es contraproducente."
		elif not plan.alcanza(decision_id, o["id"]):
			bloqueo = "No alcanza el presupuesto (faltan %d)." % plan.faltante(decision_id, o["id"])
		b.disabled = estado != "eligiendo" or bloqueo != ""
		var revelada : bool = revelar_todo or (estado == "revelado_contra" and elegida)
		det.text = _consecuencias(o) if revelada else "Costo: %d" % int(o["costo"])
		if bloqueo != "" and estado == "eligiendo":
			det.text += "  ·  " + bloqueo
		var color := TEMA.TEXTO_3
		if revelada:
			color = TEMA.VIDAS if o["contraproducente"] else TEMA.TEXTO_2
		det.add_theme_color_override("font_color", color)
	match estado:
		"eligiendo":
			_accion.text = "Cambiar decisión" if ya_resuelta else "Confirmar decisión"
			_accion.disabled = _sel == "" or _sel == plan.opcion_actual(decision_id)
		"esperando":
			_accion.text = "Registrando…"
			_accion.disabled = true
		"revelado_contra":
			_accion.text = "Reintentar"
			_accion.disabled = false
		_:
			_accion.text = "Listo"
			_accion.disabled = false
	_cerrar.disabled = estado == "esperando"


func _construir() -> void:
	var vb := UI.panel_modal(self, 700)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	vb.add_child(cab)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	cab.add_child(col)
	col.add_child(UI.texto("🚲 Plan de Movilidad", 11, TEMA.VIOLETA, 600))
	_titulo = UI.texto("", 17, TEMA.TEXTO, 700)
	col.add_child(_titulo)
	_lugar = UI.texto("", 11, TEMA.TEXTO_3)
	col.add_child(_lugar)
	_cerrar = UI.boton("Cerrar", TEMA.VACIO, 30)
	_cerrar.custom_minimum_size = Vector2(80, 30)
	_cerrar.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cerrar.pressed.connect(cerrar)
	cab.add_child(_cerrar)
	_presupuesto = UI.texto("", 12, TEMA.DORADO, 600)
	vb.add_child(_presupuesto)
	_contexto = UI.texto("", 12, TEMA.TEXTO_2)
	vb.add_child(_contexto)
	vb.add_child(UI.separador())
	_pregunta = UI.texto("", 13, TEMA.TEXTO, 600)
	vb.add_child(_pregunta)
	_botones.clear()
	_detalles.clear()
	for i in 3:
		var b := UI.boton("")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_opcion.bind(i))
		vb.add_child(b)
		_botones.append(b)
		var det := UI.texto("", 11, TEMA.TEXTO_3)
		vb.add_child(det)
		_detalles.append(det)
	_estado_lbl = UI.texto("", 12, TEMA.TEXTO_3, 600)
	vb.add_child(_estado_lbl)
	_accion = UI.boton("Confirmar decisión", TEMA.VERDE, 42)
	_accion.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_accion.pressed.connect(_on_accion)
	vb.add_child(_accion)
```

- [ ] **Step 4: Run test to verify it passes**

Run: igual que Step 2 → exit=0, sin `SCRIPT ERROR`.

- [ ] **Step 5: Commit**

```bash
git add scenes/misiones/panel_decision_movilidad.gd scenes/misiones/panel_decision_movilidad.gd.uid tests/test_panel_decision_movilidad.gd tests/test_panel_decision_movilidad.gd.uid tests/test_panel_decision_movilidad.tscn
git commit -m "nivel 5: panel de decisión con regla Mixta y presupuesto

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 9: Paneles de la Oficina y del Consejo  *(Ola 3, paralela con 8 y 10; requiere Tasks 5 y 6)*

**Files:**
- Create: `scenes/misiones/panel_oficina_movilidad.gd`, `scenes/misiones/panel_consejo_movilidad.gd`
- Test: `tests/test_panel_consejo_movilidad.gd`, `tests/test_panel_consejo_movilidad.tscn`

**Interfaces:**
- Consumes: `PLAN` (Task 6), `DATOS` (Task 2), `UI` (Task 5).
- Produces — Oficina (`CanvasLayer`, capa 20): `abrir(plan)`, `cerrar()`, `_on_aceptar()`; `signal encargo_aceptado()`, `signal cerrado()`. No modifica el plan.
- Produces — Consejo (`CanvasLayer`, capa 20): `var fase` (`cerrado|revision|objeciones|resultado`), `abrir(plan)` (resultado si ya está presentado), `cerrar()`, `_iniciar_objeciones()`, `_on_argumento(i)`, `_on_siguiente()`, `_objeciones: Array`, `_idx: int`, `_resuelta: bool`, `_descartados: Array`; `signal cambio_solicitado(decision_id: String)` (oculta el panel antes de emitir), `signal argumento_elegido(decision_id: String, opcion_id: String, indice: int, correcto: bool, intento: int)`, `signal plan_presentado()` (ya llamó a `plan.presentar`), `signal reintentar_registro()`, `signal cerrado()`.

- [ ] **Step 1: Write the failing test**

`tests/test_panel_consejo_movilidad.tscn` (nodo `TestPanelConsejoMovilidad`, script `res://tests/test_panel_consejo_movilidad.gd`).

`tests/test_panel_consejo_movilidad.gd`:
```gdscript
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
	_check(tr.contains("Aprobado") and tr.contains("4,60 de 5") and tr.contains("Reintentar registro"), "resultado con calificación y reintento de registro")

	var reintentos := [0]
	co.reintentar_registro.connect(func(): reintentos[0] += 1)
	_boton(co, "Reintentar registro").pressed.emit()
	_check(reintentos[0] == 1, "reintento de registro manual")
	p2.consejo["registrado"] = true
	co.abrir(p2)
	_check(co.fase == "resultado" and _boton(co, "Reintentar registro") == null, "registrado: sin botón de reintento")
	_check(_textos(co).contains("Entorno +1"), "muestra los cruces")
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_panel_consejo_movilidad.tscn; echo exit=$?` → Expected: error de preload, exit≠0.

- [ ] **Step 3: Implement la Oficina**

`scenes/misiones/panel_oficina_movilidad.gd`:
```gdscript
# ============================================================
# panel_oficina_movilidad.gd — NIVEL 5: Oficina de Movilidad.
# Primera visita: el encargo (Plan de Movilidad para el Consejo, 100 de
# presupuesto). Después: tablero con presupuesto y estado de cada decisión.
# No modifica el plan: avisa con señales y el controlador guarda.
# ============================================================
extends CanvasLayer

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const UI := preload("res://scenes/misiones/ui_movilidad.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

signal encargo_aceptado()
signal cerrado()

var plan = null
var _vb : VBoxContainer = null


func _ready() -> void:
	layer = 20
	_vb = UI.panel_modal(self, 620)
	visible = false


func abrir(p) -> void:
	plan = p
	_reconstruir()
	visible = true


func cerrar() -> void:
	visible = false
	cerrado.emit()


func _on_aceptar() -> void:
	encargo_aceptado.emit()


func _reconstruir() -> void:
	UI.limpiar(_vb)
	_vb.add_child(UI.texto("🚲 Oficina de Movilidad Sostenible", 11, TEMA.VIOLETA, 600))
	if not plan.encargo_aceptado:
		_vb.add_child(UI.texto("El encargo", 17, TEMA.TEXTO, 700))
		_vb.add_child(UI.texto(DATOS.ENCARGO, 13, TEMA.TEXTO_2))
		var aceptar := UI.boton("Aceptar el encargo", TEMA.VERDE, 42)
		aceptar.alignment = HORIZONTAL_ALIGNMENT_CENTER
		aceptar.pressed.connect(_on_aceptar)
		_vb.add_child(aceptar)
	else:
		_vb.add_child(UI.texto("Tu Plan de Movilidad", 17, TEMA.TEXTO, 700))
		var comprometido : int = plan.costo_comprometido()
		_vb.add_child(UI.texto("Presupuesto: %d de %d comprometido · quedan %d" % [
			comprometido, DATOS.PRESUPUESTO, DATOS.PRESUPUESTO - comprometido], 13, TEMA.DORADO, 600))
		_vb.add_child(UI.barra(float(comprometido) / float(DATOS.PRESUPUESTO)))
		_vb.add_child(UI.separador())
		for d in DATOS.DECISIONES:
			_vb.add_child(_fila(d))
		_vb.add_child(UI.separador())
		_vb.add_child(_fila_consejo())
	var cerrar_btn := UI.boton("Cerrar", TEMA.VACIO, 34)
	cerrar_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	cerrar_btn.pressed.connect(cerrar)
	_vb.add_child(cerrar_btn)


func _fila(d: Dictionary) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var nombre := TEMA.label(d["titulo"], 12, TEMA.TEXTO, 600)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(nombre)
	var op : String = plan.opcion_actual(d["id"])
	var estado : Label
	if op == "":
		estado = TEMA.label("Pendiente · %s" % DATOS.NOMBRE_LUGAR.get(d["lugar"], ""), 12, TEMA.TEXTO_3)
	else:
		var o := DATOS.opcion(d["id"], op)
		estado = TEMA.label("%s · costo %d" % [o["corto"], int(o["costo"])], 12, TEMA.VERDE)
	fila.add_child(estado)
	return fila


func _fila_consejo() -> Control:
	var texto := ""
	var color := TEMA.TEXTO_3
	if plan.presentado():
		texto = "Consejo Universitario: %s" % DATOS.calificacion(int(plan.consejo.get("aciertos", 0)))["nombre"]
		color = TEMA.VERDE
	elif plan.todas_resueltas():
		texto = "Plan completo: preséntalo en el Rectorado"
		color = TEMA.DORADO
	else:
		var faltan := 0
		for id in DATOS.ids_decisiones():
			if not plan.resuelta(id):
				faltan += 1
		texto = "Consejo Universitario: faltan %d decisiones" % faltan
	return UI.texto(texto, 12, color, 600)
```

- [ ] **Step 4: Implement el Consejo**

`scenes/misiones/panel_consejo_movilidad.gd`:
```gdscript
# ============================================================
# panel_consejo_movilidad.gd — NIVEL 5: Consejo Universitario (Rectorado).
# Revisión del plan (hasta 2 cambios), 3 objeciones sobre los puntos
# débiles reales (plan.objeciones(), spec §7.2) con reintento en la misma
# objeción, y resultado (spec §7.5). Llama a plan.presentar(); guardar,
# misión, registro y cruces son del controlador (señal plan_presentado).
# ============================================================
extends CanvasLayer

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")
const UI := preload("res://scenes/misiones/ui_movilidad.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

signal cambio_solicitado(decision_id: String)
signal argumento_elegido(decision_id: String, opcion_id: String, indice: int, correcto: bool, intento: int)
signal plan_presentado()
signal reintentar_registro()
signal cerrado()

var plan = null
var fase : String = "cerrado"          # revision | objeciones | resultado
var _vb : VBoxContainer = null
var _objeciones : Array = []
var _idx : int = 0
var _resultados : Array = []
var _intentos : int = 0
var _descartados : Array = []
var _resuelta : bool = false
var _elegido : int = -1
var _feedback : String = ""
var _feedback_ok : bool = false


func _ready() -> void:
	layer = 20
	_vb = UI.panel_modal(self, 680)
	visible = false


func abrir(p) -> void:
	plan = p
	fase = "resultado" if plan.presentado() else "revision"
	_reconstruir()
	visible = true


func cerrar() -> void:
	visible = false
	cerrado.emit()


func _reconstruir() -> void:
	UI.limpiar(_vb)
	_vb.add_child(UI.texto("🏆 Consejo Universitario · Plan de Movilidad", 11, TEMA.VIOLETA, 600))
	match fase:
		"revision":
			_pintar_revision()
		"objeciones":
			_pintar_objecion()
		"resultado":
			_pintar_resultado()


func _pintar_revision() -> void:
	_vb.add_child(UI.texto("Revisión antes de presentar", 17, TEMA.TEXTO, 700))
	var disponibles : int = PLAN.MAX_CAMBIOS_CONSEJO - int(plan.cambios_en_consejo)
	_vb.add_child(UI.texto("Puedes cambiar hasta %d decisiones si el presupuesto alcanza. Cambios disponibles: %d. Quedan %d de presupuesto." % [
		PLAN.MAX_CAMBIOS_CONSEJO, disponibles, plan.restante()], 12, TEMA.TEXTO_2))
	for d in DATOS.DECISIONES:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		var o := DATOS.opcion(d["id"], plan.opcion_actual(d["id"]))
		var nombre := TEMA.label("%s: %s" % [d["titulo"], o.get("corto", "Pendiente")], 12, TEMA.TEXTO, 600)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nombre)
		fila.add_child(TEMA.label("%s · costo %d" % [
			DATOS.ACEPTACION_TEXTO.get(o.get("aceptacion", ""), ""), int(o.get("costo", 0))], 11, TEMA.TEXTO_3))
		var cambiar := UI.boton("Cambiar", UI.ACENTO, 28)
		cambiar.custom_minimum_size = Vector2(84, 28)
		cambiar.alignment = HORIZONTAL_ALIGNMENT_CENTER
		cambiar.disabled = not plan.puede_cambiar_en_consejo()
		cambiar.pressed.connect(_on_cambiar.bind(str(d["id"])))
		fila.add_child(cambiar)
		_vb.add_child(fila)
	var presentar := UI.boton("Presentar al Consejo", TEMA.VERDE, 42)
	presentar.alignment = HORIZONTAL_ALIGNMENT_CENTER
	presentar.disabled = not plan.puede_presentar()
	presentar.pressed.connect(_iniciar_objeciones)
	_vb.add_child(presentar)
	var despues := UI.boton("Ahora no", TEMA.VACIO, 34)
	despues.alignment = HORIZONTAL_ALIGNMENT_CENTER
	despues.pressed.connect(cerrar)
	_vb.add_child(despues)


func _on_cambiar(decision_id: String) -> void:
	visible = false
	cambio_solicitado.emit(decision_id)


func _iniciar_objeciones() -> void:
	if not plan.puede_presentar():
		return
	_objeciones = plan.objeciones()
	_idx = 0
	_resultados = []
	_nueva_objecion()
	if _objeciones.is_empty():
		_terminar()
		return
	fase = "objeciones"
	_reconstruir()


func _nueva_objecion() -> void:
	_intentos = 0
	_descartados = []
	_resuelta = false
	_elegido = -1
	_feedback = ""
	_feedback_ok = false


func _pintar_objecion() -> void:
	var obj : Dictionary = _objeciones[_idx]
	var d := DATOS.decision(obj["decision"])
	_vb.add_child(UI.texto("Objeción %d de %d · %s" % [_idx + 1, _objeciones.size(), d["titulo"]], 12, TEMA.TEXTO_3, 600))
	_vb.add_child(UI.texto(obj["texto"], 15, TEMA.TEXTO, 600))
	_vb.add_child(UI.texto("Elige el argumento con el que respondes:", 12, TEMA.TEXTO_2))
	var args : Array = obj["argumentos"]
	for i in args.size():
		var b := UI.boton(str(args[i]["texto"]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UI.pintar_boton(b, TEMA.VERDE if i == _elegido else UI.ACENTO, i == _elegido)
		b.disabled = _resuelta or i in _descartados
		b.pressed.connect(_on_argumento.bind(i))
		_vb.add_child(b)
	if _feedback != "":
		_vb.add_child(UI.texto(_feedback, 12, TEMA.VERDE if _feedback_ok else TEMA.NARANJA))
	if _resuelta:
		var ultimo := _idx + 1 >= _objeciones.size()
		var sig := UI.boton("Ver resultado" if ultimo else "Siguiente objeción", TEMA.VERDE, 42)
		sig.alignment = HORIZONTAL_ALIGNMENT_CENTER
		sig.pressed.connect(_on_siguiente)
		_vb.add_child(sig)


func _on_argumento(i: int) -> void:
	if fase != "objeciones" or _resuelta or i in _descartados:
		return
	var obj : Dictionary = _objeciones[_idx]
	var arg : Dictionary = obj["argumentos"][i]
	var correcto := bool(arg["correcto"])
	_intentos += 1
	if _intentos == 1:
		_resultados.append({"decision": obj["decision"], "opcion": obj["opcion"],
			"primer_argumento": i, "correcto_primer_intento": correcto, "intentos": 1})
	else:
		_resultados[_idx]["intentos"] = _intentos
	_feedback = ("Convence: " if correcto else "No convence: ") + str(arg["explicacion"])
	_feedback_ok = correcto
	if correcto:
		_resuelta = true
		_elegido = i
	else:
		_descartados.append(i)
	argumento_elegido.emit(str(obj["decision"]), str(obj["opcion"]), i, correcto, _intentos)
	_reconstruir()


func _on_siguiente() -> void:
	if fase != "objeciones" or not _resuelta:
		return
	_idx += 1
	if _idx >= _objeciones.size():
		_terminar()
		return
	_nueva_objecion()
	_reconstruir()


func _terminar() -> void:
	plan.presentar(_resultados)
	fase = "resultado"
	plan_presentado.emit()
	_reconstruir()


func _pintar_resultado() -> void:
	var c : Dictionary = plan.consejo
	var aciertos := int(c.get("aciertos", 0))
	_vb.add_child(UI.texto(str(DATOS.calificacion(aciertos)["nombre"]), 20, TEMA.VERDE, 700))
	_vb.add_child(UI.texto("Argumentos convincentes al primer intento: %d de 3" % aciertos, 13, TEMA.TEXTO_2))
	_vb.add_child(UI.texto("Calificación estimada del plan (Decisiones de Transporte): %s de 5. El número oficial es el del panel GreenMetric." % UI.decimal(plan.calificacion_estimada()), 13, TEMA.DORADO, 600))
	for r in c.get("objeciones", []):
		var d := DATOS.decision(str(r.get("decision", "")))
		var titulo := str(d.get("titulo", ""))
		var linea := ("%s: convenciste al primer intento" % titulo) if bool(r.get("correcto_primer_intento", false)) \
			else ("%s: lo resolviste en %d intentos" % [titulo, int(r.get("intentos", 1))])
		_vb.add_child(UI.texto(linea, 12, TEMA.TEXTO_2))
	var sins : Array = c.get("sinergias", [])
	if not sins.is_empty():
		_vb.add_child(UI.separador())
		for s in sins:
			_vb.add_child(UI.texto("✨ Cruce ganado: %s" % DATOS.SINERGIAS.get(s, {}).get("efecto", ""), 12, TEMA.VERDE))
	if not bool(c.get("registrado", false)):
		_vb.add_child(UI.texto("La calificación todavía no quedó registrada en el servidor (sin conexión o sin sesión).", 12, TEMA.NARANJA))
		var reintentar := UI.boton("Reintentar registro", TEMA.NARANJA, 34)
		reintentar.alignment = HORIZONTAL_ALIGNMENT_CENTER
		reintentar.pressed.connect(func(): reintentar_registro.emit())
		_vb.add_child(reintentar)
	var cerrar_btn := UI.boton("Cerrar", TEMA.VACIO, 34)
	cerrar_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	cerrar_btn.pressed.connect(cerrar)
	_vb.add_child(cerrar_btn)
```

- [ ] **Step 5: Run test to verify it passes**

Run: igual que Step 2 → exit=0, sin `SCRIPT ERROR`.

- [ ] **Step 6: Commit**

```bash
git add scenes/misiones/panel_oficina_movilidad.gd scenes/misiones/panel_oficina_movilidad.gd.uid scenes/misiones/panel_consejo_movilidad.gd scenes/misiones/panel_consejo_movilidad.gd.uid tests/test_panel_consejo_movilidad.gd tests/test_panel_consejo_movilidad.gd.uid tests/test_panel_consejo_movilidad.tscn
git commit -m "nivel 5: Oficina de Movilidad y Consejo Universitario con objeciones

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 10: Cambios visibles en el mapa  *(Ola 3, paralela con 8 y 9; requiere Tasks 1 y 6)*

**Files:**
- Create: `scenes/mapa/cambios_movilidad.gd`
- Test: `tests/test_cambios_movilidad.gd`, `tests/test_cambios_movilidad.tscn`

**Interfaces:**
- Consumes: `LUGARES` (Task 1), `DATOS` (Task 2), instancias de `PLAN` (Task 6), `hud_tema.gd`.
- Produces (`const CAMBIOS := preload("res://scenes/mapa/cambios_movilidad.gd")`, `Node2D`):
  - `actualizar(plan)` (redibuja), `elementos() -> Array` de `{elemento: String, lugar: String}`, `autos_en_m5() -> int`
  - `CAMBIOS.DESPLAZAMIENTO : Dictionary` (elemento → Vector2), `CAMBIOS.AUTOS_BASE` (8), `CAMBIOS.REDUCCION_AUTOS`

- [ ] **Step 1: Write the failing test**

`tests/test_cambios_movilidad.tscn` (nodo `TestCambiosMovilidad`, script `res://tests/test_cambios_movilidad.gd`).

`tests/test_cambios_movilidad.gd`:
```gdscript
# Prueba de los cambios visibles del Plan de Movilidad (spec §12): qué se
# dibuja y dónde, sin comparar píxeles.
# Correr: $GODOT --headless --path . res://tests/test_cambios_movilidad.tscn
extends Node

const CAMBIOS := preload("res://scenes/mapa/cambios_movilidad.gd")
const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")
const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")

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


func _nombres(elementos: Array) -> Array:
	var out := []
	for e in elementos:
		out.append(e["elemento"])
	return out


func _lugares_validos(c: Node2D) -> void:
	for e in c.elementos():
		_check(LUGARES.existe(e["lugar"]) and CAMBIOS.DESPLAZAMIENTO.has(e["elemento"]),
			"%s en %s con desplazamiento" % [e["elemento"], e["lugar"]])


func _ready() -> void:
	print("test_cambios_movilidad")
	var c : Node2D = CAMBIOS.new()
	add_child(c)
	var e := _nombres(c.elementos())
	_check(e.has("lote_vacio") and e.has("autos_m5") and e.size() == 2, "sin plan: lote vacío y autos")
	_check(c.autos_en_m5() == 8, "sin plan: 8 autos")
	_lugares_validos(c)

	var p = PLAN.new()
	for id in MEJOR.keys():
		p.aplicar_valida(id, MEJOR[id])
	c.actualizar(p)
	e = _nombres(c.elementos())
	for n in ["ciclovia", "senal_carpool", "cartel_permisos", "buseta", "cartel_dia_sin_carros", "carrito_electrico"]:
		_check(e.has(n), "plan de 5,00 dibuja %s" % n)
	_check(e.count("bicicletero_techado") == 2 and not e.has("lote_vacio"), "dos bicicleteros techados, lote transformado")
	_check(c.autos_en_m5() == 1, "8 - 3 - 2 - 2 = 1 auto")
	_lugares_validos(c)

	var q = PLAN.new()
	for par in [["tr_permisos", "lectoras_de_placas"], ["tr_carpool", "app_carpool"], ["tr_shuttle", "park_and_ride"],
			["tr_lote", "plaza_de_eventos"], ["tr_bici_bloque_e", "simple_con_candado"], ["tr_bici_cafetin", "simple_con_candado"]]:
		_check(q.aplicar_valida(par[0], par[1]), "aplica %s" % par[1])
	c.actualizar(q)
	e = _nombres(c.elementos())
	_check(e.has("barrera_placas") and e.has("cartel_app_carpool") and e.has("buseta") and e.has("plaza"), "otras válidas dibujan lo suyo")
	_check(e.count("bicicletero_simple") == 2, "dos bicicleteros simples")
	_check(c.autos_en_m5() == 5, "8 - 1 - 2 = 5 autos")
	_lugares_validos(c)

	var r = PLAN.new()
	r.aplicar_valida("tr_dia_sin_carros", "cierre_semanal")
	r.aplicar_valida("tr_flota", "triciclos_de_carga")
	c.actualizar(r)
	e = _nombres(c.elementos())
	_check(e.has("cartel_viernes_sin_carros") and e.has("triciclos") and not e.has("buseta"), "viernes sin carros y triciclos")
	_lugares_validos(c)

	await get_tree().process_frame
	await get_tree().process_frame
	_check(is_instance_valid(c), "dibuja dos frames sin detenerse")

	print("test_cambios_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_cambios_movilidad.tscn; echo exit=$?` → Expected: error de preload, exit≠0.

- [ ] **Step 3: Implement**

`scenes/mapa/cambios_movilidad.gd`:
```gdscript
# ============================================================
# cambios_movilidad.gd — NIVEL 5: lo que el Plan de Movilidad cambia en el
# mapa (spec §12), dibujado con _draw en el mismo estilo procedural que
# mapa_campus.gd. Todo anclado a lugares con nombre (lugares_campus.gd) +
# DESPLAZAMIENTO, para no tapar los puntos. Se redibuja solo al cambiar el
# plan. La lista de elementos (elementos()) se prueba sin dibujar.
# ============================================================
extends Node2D

const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")
const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

const AUTOS_BASE := 8
const REDUCCION_AUTOS : Dictionary = {
	"permiso_por_necesidad": 3, "puestos_3_ocupantes": 2, "app_carpool": 1,
	"ruta_a_paradas": 2, "park_and_ride": 2,
}
# Dónde se dibuja cada elemento respecto de su lugar. Ajustar con el mapa nuevo.
const DESPLAZAMIENTO : Dictionary = {
	"autos_m5": Vector2(-40, -62),
	"senal_carpool": Vector2(48, -30),
	"cartel_app_carpool": Vector2(48, -30),
	"cartel_permisos": Vector2(0, -52),
	"barrera_placas": Vector2(0, -52),
	"lote_vacio": Vector2(0, 0),
	"ciclovia": Vector2(0, 0),
	"plaza": Vector2(0, 0),
	"buseta": Vector2(-70, -18),
	"cartel_dia_sin_carros": Vector2(70, -30),
	"cartel_viernes_sin_carros": Vector2(70, -30),
	"carrito_electrico": Vector2(0, -50),
	"triciclos": Vector2(0, -50),
	"bicicletero_techado": Vector2(-46, 4),
	"bicicletero_simple": Vector2(-46, 4),
}
const ELEMENTO_POR_OPCION : Dictionary = {
	"ciclovia_arborizada": "ciclovia", "plaza_de_eventos": "plaza",
	"puestos_3_ocupantes": "senal_carpool", "app_carpool": "cartel_app_carpool",
	"permiso_por_necesidad": "cartel_permisos", "lectoras_de_placas": "barrera_placas",
	"ruta_a_paradas": "buseta", "park_and_ride": "buseta",
	"jornada_mensual_con_feria": "cartel_dia_sin_carros", "cierre_semanal": "cartel_viernes_sin_carros",
	"carritos_electricos": "carrito_electrico", "triciclos_de_carga": "triciclos",
	"techado_con_panel": "bicicletero_techado", "simple_con_candado": "bicicletero_simple",
}

var _elecciones : Dictionary = {}   # decision_id -> opcion_id


func actualizar(plan) -> void:
	_elecciones = {}
	for id in DATOS.ids_decisiones():
		var op : String = plan.opcion_actual(id)
		if op != "":
			_elecciones[id] = op
	queue_redraw()


func autos_en_m5() -> int:
	var n := AUTOS_BASE
	for op in _elecciones.values():
		n -= int(REDUCCION_AUTOS.get(op, 0))
	return maxi(1, n)


func elementos() -> Array:
	var out : Array = [{"elemento": "autos_m5", "lugar": "estacionamiento_m5"}]
	if not _elecciones.has("tr_lote"):
		out.append({"elemento": "lote_vacio", "lugar": "lote_este"})
	for id in DATOS.ids_decisiones():
		if not _elecciones.has(id):
			continue
		var elemento := str(ELEMENTO_POR_OPCION.get(_elecciones[id], ""))
		if elemento != "":
			out.append({"elemento": elemento, "lugar": DATOS.decision(id)["lugar"]})
	return out


func _draw() -> void:
	var fuente := TEMA.rubik(700)
	for e in elementos():
		var pos := LUGARES.posicion(e["lugar"], DESPLAZAMIENTO.get(e["elemento"], Vector2.ZERO))
		match e["elemento"]:
			"autos_m5": _autos(pos)
			"lote_vacio": _lote(pos, false)
			"plaza": _lote(pos, true)
			"ciclovia": _ciclovia(pos)
			"senal_carpool": _cartel(pos, "3+", TEMA.VERDE, fuente)
			"cartel_app_carpool": _cartel(pos, "CARPOOL", TEMA.CIAN, fuente)
			"cartel_permisos": _cartel(pos, "PERMISOS", TEMA.DORADO, fuente)
			"barrera_placas": _barrera(pos)
			"buseta": _buseta(pos)
			"cartel_dia_sin_carros": _cartel(pos, "DÍA SIN CARROS", TEMA.VIOLETA, fuente)
			"cartel_viernes_sin_carros": _cartel(pos, "VIERNES SIN CARROS", TEMA.VIOLETA, fuente)
			"carrito_electrico": _carrito(pos)
			"triciclos": _triciclos(pos)
			"bicicletero_techado": _bicicletero(pos, true)
			"bicicletero_simple": _bicicletero(pos, false)


func _autos(pos: Vector2) -> void:
	var colores := [Color(0.78, 0.22, 0.20), Color(0.20, 0.42, 0.78), Color(0.85, 0.85, 0.82), Color(0.25, 0.25, 0.28)]
	for i in autos_en_m5():
		var x := pos.x + float(i % 4) * 20.0
		var y := pos.y + float(floori(i / 4.0)) * 14.0
		draw_rect(Rect2(x, y, 16, 9), colores[i % colores.size()])
		draw_rect(Rect2(x + 4, y + 2, 8, 5), Color(0.55, 0.75, 0.90, 0.8))


func _lote(pos: Vector2, plaza: bool) -> void:
	var r := Rect2(pos - Vector2(56, 30), Vector2(112, 60))
	if plaza:
		draw_rect(r, Color(0.72, 0.66, 0.55))
		for esquina in [Vector2(-56, -30), Vector2(56, -30), Vector2(-56, 30), Vector2(56, 30)]:
			draw_circle(pos + esquina, 3.0, Color(0.30, 0.30, 0.32))
	else:
		draw_rect(r, Color(0.55, 0.47, 0.36))
		for i in range(1, 5):
			var x := r.position.x + float(i) * 22.4
			draw_line(Vector2(x, r.position.y + 4), Vector2(x, r.end.y - 4), Color(1, 1, 1, 0.25), 1.0)
	draw_rect(r, Color(0, 0, 0, 0.35), false, 1.5)


func _ciclovia(pos: Vector2) -> void:
	var r := Rect2(pos - Vector2(56, 30), Vector2(112, 60))
	draw_rect(r, Color(0.36, 0.62, 0.30))
	draw_rect(Rect2(r.position.x, pos.y - 7, r.size.x, 14), Color(0.30, 0.32, 0.36))
	var x := r.position.x + 4.0
	while x < r.end.x - 8.0:
		draw_line(Vector2(x, pos.y), Vector2(x + 8.0, pos.y), TEMA.VERDE, 2.0)
		x += 16.0
	for dx in [-40.0, 0.0, 40.0]:
		draw_circle(pos + Vector2(dx, -19), 9.0, Color(0.14, 0.38, 0.14))
		draw_circle(pos + Vector2(dx, 19), 9.0, Color(0.14, 0.38, 0.14))


func _cartel(pos: Vector2, texto: String, color: Color, fuente: Font) -> void:
	var tam := 9
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 10.0
	draw_line(pos + Vector2(0, 6), pos + Vector2(0, 22), Color(0.45, 0.45, 0.48), 2.0)
	var r := Rect2(pos.x - ancho * 0.5, pos.y - 8, ancho, 14)
	draw_rect(r, TEMA.PANEL_BG)
	draw_rect(r, color, false, 1.5)
	draw_string(fuente, Vector2(r.position.x + 5, pos.y + 3), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)


func _barrera(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 20, pos.y - 6, 8, 14), Color(0.35, 0.35, 0.38))
	draw_line(pos + Vector2(-12, -2), pos + Vector2(24, -2), Color(0.92, 0.25, 0.22), 3.0)
	draw_line(pos + Vector2(0, -2), pos + Vector2(8, -2), Color.WHITE, 3.0)
	draw_rect(Rect2(pos.x - 22, pos.y - 16, 10, 7), Color(0.15, 0.15, 0.18))
	draw_circle(pos + Vector2(-17, -12.5), 2.0, TEMA.CIAN)


func _buseta(pos: Vector2) -> void:
	var r := Rect2(pos - Vector2(24, 9), Vector2(48, 18))
	draw_rect(r, TEMA.VIOLETA)
	for i in 4:
		draw_rect(Rect2(r.position.x + 4 + i * 10, r.position.y + 3, 8, 6), Color(0.80, 0.92, 1.0))
	draw_circle(pos + Vector2(-14, 9), 4.0, Color(0.1, 0.1, 0.1))
	draw_circle(pos + Vector2(14, 9), 4.0, Color(0.1, 0.1, 0.1))
	draw_line(pos + Vector2(34, 10), pos + Vector2(34, -14), Color(0.45, 0.45, 0.48), 2.0)
	draw_rect(Rect2(pos.x + 28, pos.y - 20, 12, 8), TEMA.DORADO)


func _carrito(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 14, pos.y - 6, 28, 12), Color(0.90, 0.92, 0.94))
	draw_rect(Rect2(pos.x - 14, pos.y - 12, 16, 6), Color(0.70, 0.74, 0.78))
	draw_circle(pos + Vector2(-9, 7), 3.5, Color(0.1, 0.1, 0.1))
	draw_circle(pos + Vector2(9, 7), 3.5, Color(0.1, 0.1, 0.1))
	draw_polyline(PackedVector2Array([pos + Vector2(6, -5), pos + Vector2(2, 0), pos + Vector2(6, 0), pos + Vector2(2, 5)]), TEMA.DORADO, 2.0)


func _triciclos(pos: Vector2) -> void:
	for k in 3:
		var p := pos + Vector2(-22 + k * 22, 0)
		draw_arc(p + Vector2(-5, 4), 3.5, 0.0, TAU, 10, Color(0.1, 0.1, 0.1), 1.5)
		draw_arc(p + Vector2(5, 4), 3.5, 0.0, TAU, 10, Color(0.1, 0.1, 0.1), 1.5)
		draw_rect(Rect2(p.x - 7, p.y - 6, 10, 7), TEMA.NARANJA)
		draw_line(p + Vector2(3, -2), p + Vector2(7, -8), Color(0.3, 0.3, 0.3), 1.5)


func _bicicletero(pos: Vector2, techado: bool) -> void:
	for k in 3:
		draw_arc(pos + Vector2(-10 + k * 10, 4), 4.5, PI, TAU, 8, Color(0.62, 0.64, 0.68), 2.0)
	if techado:
		draw_rect(Rect2(pos.x - 18, pos.y - 12, 36, 4), Color(0.40, 0.42, 0.45))
		draw_rect(Rect2(pos.x - 8, pos.y - 17, 16, 5), Color(0.15, 0.30, 0.62))
		draw_circle(pos + Vector2(16, -6), 2.5, TEMA.DORADO)
```

- [ ] **Step 4: Run test to verify it passes**

Run: igual que Step 2 → exit=0, sin `SCRIPT ERROR`.

- [ ] **Step 5: Commit**

```bash
git add scenes/mapa/cambios_movilidad.gd scenes/mapa/cambios_movilidad.gd.uid tests/test_cambios_movilidad.gd tests/test_cambios_movilidad.gd.uid tests/test_cambios_movilidad.tscn
git commit -m "mapa: cambios visibles del Plan de Movilidad anclados a lugares

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 11: Controlador del Nivel 5  *(Ola 4; requiere Tasks 3, 4, 7, 8, 9, 10)*

**Files:**
- Create: `scenes/misiones/nivel5_movilidad.gd`
- Test: `tests/test_nivel5_movilidad.gd`, `tests/test_nivel5_movilidad.tscn`

**Interfaces:**
- Consumes: todo lo anterior; `NivelManager` (`legado_completo` de la Task 4, `nivel_desbloqueado`, `mision_completada_q`, `completar_mision`, `guardar_detalle`, `obtener_detalle`, `XP_POR_MISION`, `EC_POR_MISION`), `PuntajeManager` (`registrar_decision`, `registrar_sinergia`, `signal decision_resuelta`), `SupabaseManager.registrar_evento`.
- Produces (`const NIVEL5_MOVILIDAD := preload("res://scenes/misiones/nivel5_movilidad.gd")`, `Node`):
  - `configurar(mapa: Node, nivel_mgr: Node, puntaje_mgr: Node, supa: Node)` — llamar después de `add_child(controlador)`.
  - `activar()` — idempotente; crea los 10 puntos y el nodo de cambios si el Nivel 5 está desbloqueado.
  - `hay_panel_abierto() -> bool`
  - `var verificar_herramienta : Callable` — `(tipo: String, punto: Node) -> bool`
  - `signal mision_completada(mision_id: String, xp: int, ec: int)` — `xp = 0, ec = 0` cuando `NivelManager.legado_completo(5)` (sin re-pago, spec §11.1); si no, `XP_POR_MISION[5]` y `EC_POR_MISION[5]`.
  - Para pruebas: `plan`, `panel_decision`, `panel_oficina`, `panel_consejo`, `_puntos` (claves `"oficina"`, cada decision_id, `"tr_consejo"`), `_on_interaccion(punto)`.
- Consumed by: Task 12.

- [ ] **Step 1: Write the failing test**

`tests/test_nivel5_movilidad.tscn` (nodo `TestNivel5Movilidad`, script `res://tests/test_nivel5_movilidad.gd`).

`tests/test_nivel5_movilidad.gd`:
```gdscript
# Prueba del controlador del Nivel 5 sin red: puntos por lugar, encargo,
# regla Mixta, kit, Consejo, misiones, detalle, telemetría, restauración
# tardía y espejo con sql/nivel5_plan_movilidad.sql.
# Correr: $GODOT --headless --path . res://tests/test_nivel5_movilidad.tscn
extends Node

const CTRL := preload("res://scenes/misiones/nivel5_movilidad.gd")
const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")


class FakePuntaje extends Node:
	signal decision_resuelta(decision_id: String, opcion_id: String, respuesta: Dictionary)
	var decisiones : Array = []
	var sinergias : Array = []

	func registrar_decision(decision_id: String, opcion_id: String) -> void:
		decisiones.append([decision_id, opcion_id])

	func registrar_sinergia(accion_id: String) -> void:
		sinergias.append(accion_id)


class FakeSupa extends Node:
	var eventos : Array = []

	func registrar_evento(nivel: int, mision_id: String, tipo: String, detalle: Dictionary = {}, correcto = null, intento = null) -> void:
		eventos.append({"nivel": nivel, "mision_id": mision_id, "tipo": tipo, "detalle": detalle, "correcto": correcto, "intento": intento})


var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _idx(decision_id: String, opcion_id: String) -> int:
	var ops : Array = DATOS.decision(decision_id)["opciones"]
	for i in ops.size():
		if ops[i]["id"] == opcion_id:
			return i
	return -1


func _eventos(sm: FakeSupa, tipo: String) -> Array:
	return sm.eventos.filter(func(e): return e["tipo"] == tipo)


# Abre la decisión desde su punto, elige, confirma, responde como el
# servidor y cierra el panel.
func _decidir(ctrl: Node, pm: FakePuntaje, decision_id: String, opcion_id: String, respuesta: Dictionary) -> void:
	ctrl._on_interaccion(ctrl._puntos[decision_id])
	ctrl.panel_decision._on_opcion(_idx(decision_id, opcion_id))
	ctrl.panel_decision._on_accion()
	pm.decision_resuelta.emit(decision_id, opcion_id, respuesta)
	ctrl.panel_decision.cerrar()


func _verificar_espejo_sql() -> void:
	var sql := FileAccess.get_file_as_string("res://sql/nivel5_plan_movilidad.sql")
	_check(sql != "", "existe sql/nivel5_plan_movilidad.sql")
	var re := RegEx.new()
	re.compile("\\('(tr_[a-z0-9_]+)',\\s*'([a-z0-9_]+)',\\s*5,\\s*([0-9.]+),\\s*(true|false),\\s*([0-9]+)\\)")
	var filas := {}
	for m in re.search_all(sql):
		filas["%s:%s" % [m.get_string(1), m.get_string(2)]] = m
	var esperadas := 0
	for d in DATOS.DECISIONES:
		for o in d["opciones"]:
			esperadas += 1
			var m = filas.get("%s:%s" % [d["id"], o["id"]])
			_check(m != null, "SQL tiene %s:%s" % [d["id"], o["id"]])
			if m == null:
				continue
			_check(is_equal_approx(float(m.get_string(3)), float(o["puntos"]))
				and (m.get_string(4) == "true") == bool(o["contraproducente"])
				and int(m.get_string(5)) == int(o["costo"]), "SQL coincide en %s:%s" % [d["id"], o["id"]])
	for c in DATOS.CONSEJO_OPCIONES:
		esperadas += 1
		var m = filas.get("tr_consejo:%s" % c["id"])
		_check(m != null and is_equal_approx(float(m.get_string(3)), float(c["puntos"])) and m.get_string(4) == "false",
			"SQL coincide en tr_consejo:%s" % c["id"])
	_check(filas.size() == esperadas, "SQL sin filas de decisión extra (%d de %d)" % [filas.size(), esperadas])
	var re_s := RegEx.new()
	re_s.compile("\\('([a-z0-9_]+)',\\s*([1-6]),\\s*([0-9]+),\\s*'tr_consejo'\\)")
	var sins := {}
	for m in re_s.search_all(sql):
		sins[m.get_string(1)] = m
	for s in DATOS.SINERGIAS.keys():
		var m = sins.get(s)
		_check(m != null and int(m.get_string(2)) == int(DATOS.SINERGIAS[s]["categoria"])
			and int(m.get_string(3)) == int(DATOS.SINERGIAS[s]["puntos"]), "SQL coincide en sinergia %s" % s)
	_check(sins.size() == DATOS.SINERGIAS.size(), "SQL sin sinergias extra")


func _ready() -> void:
	print("test_nivel5_movilidad")
	var nm : Node = load("res://autoload/NivelManager.gd").new()
	for n in range(1, 5):
		var d := {}
		for id in nm.MISIONES_NIVEL[n]:
			d[id] = true
		nm._misiones[str(n)] = d
	var pm := FakePuntaje.new()
	var sm := FakeSupa.new()
	add_child(pm)
	add_child(sm)
	var mapa := Node2D.new()
	add_child(mapa)
	var ctrl : Node = CTRL.new()
	add_child(ctrl)
	ctrl.configurar(mapa, nm, pm, sm)
	var completadas := []
	var pagos := []
	ctrl.mision_completada.connect(func(id, xp, ec):
		completadas.append(id)
		pagos.append([xp, ec]))
	ctrl.activar()
	ctrl.activar()

	# ── Puntos y lugares ───────────────────────────────────
	_check(DATOS.MISIONES == nm.MISIONES_NIVEL[5], "espejo DATOS.MISIONES = NivelManager.MISIONES_NIVEL[5]")
	for d in DATOS.DECISIONES:
		_check(LUGARES.existe(d["lugar"]), "lugar de %s existe" % d["id"])
	_check(get_tree().get_nodes_in_group("punto_movilidad").size() == 10, "10 puntos (activar es idempotente)")
	_check(ctrl._puntos["tr_lote"].position == LUGARES.posicion("lote_este"), "tr_lote en lote_este")
	_check(ctrl._puntos["tr_consejo"].position == LUGARES.posicion("rectorado"), "Consejo en el Rectorado")
	_check(ctrl._puntos["oficina"].estado == "pendiente" and ctrl._puntos["tr_lote"].estado == "bloqueado"
		and ctrl._puntos["tr_consejo"].estado == "bloqueado", "estados antes del encargo")
	var hay_cambios := false
	for c in mapa.get_children():
		if c.has_method("elementos"):
			hay_cambios = true
	_check(hay_cambios, "nodo de cambios del mapa creado")

	ctrl._on_interaccion(ctrl._puntos["tr_lote"])
	_check(not ctrl.hay_panel_abierto(), "sin encargo no se abre la decisión")

	# ── Encargo ────────────────────────────────────────────
	ctrl._on_interaccion(ctrl._puntos["oficina"])
	_check(ctrl.panel_oficina.visible and ctrl.hay_panel_abierto(), "la Oficina abre el encargo")
	ctrl.panel_oficina._on_aceptar()
	_check(ctrl.plan.encargo_aceptado, "encargo aceptado")
	_check(bool(nm.obtener_detalle("plan_movilidad").get("encargo_aceptado", false)), "encargo guardado en el detalle")
	_check(_eventos(sm, "encargo_aceptado").size() == 1, "evento encargo_aceptado")
	ctrl.panel_oficina.cerrar()
	_check(ctrl._puntos["tr_lote"].estado == "pendiente", "decisiones pendientes tras el encargo")

	# ── Regla Mixta ────────────────────────────────────────
	_decidir(ctrl, pm, "tr_carpool", "vender_puestos_reservados", {"ok": true, "contraproducente": true, "penalizado": true})
	_check(not nm.mision_completada_q(5, "tr_carpool") and completadas.is_empty(), "contraproducente no completa la misión")
	_check(ctrl.plan.descartada("tr_carpool", "vender_puestos_reservados") and ctrl.plan.restante() == 100, "descartada y sin gasto")
	var ev : Array = _eventos(sm, "decision_tomada")
	_check(ev.size() == 1 and ev[0]["correcto"] == false and ev[0]["detalle"]["contraproducente"] == true, "telemetría de contraproducente")
	_check(nm.obtener_detalle("plan_movilidad")["decisiones"]["tr_carpool"]["contraproducentes"] == ["vender_puestos_reservados"], "descarte guardado")
	_check(pm.decisiones.back() == ["tr_carpool", "vender_puestos_reservados"], "registró la decisión en el servidor")

	_decidir(ctrl, pm, "tr_carpool", "app_carpool", {"ok": true, "contraproducente": false})
	_check(nm.mision_completada_q(5, "tr_carpool") and completadas == ["tr_carpool"], "válida completa la misión")
	_check(pagos == [[35, 12]], "jugador sin el Nivel 5 viejo: paga XP y EC")
	_check(ctrl._puntos["tr_carpool"].estado == "resuelto", "punto resuelto")
	ev = _eventos(sm, "decision_tomada")
	_check(ev.size() == 2 and ev[1]["correcto"] == true and int(ev[1]["detalle"]["costo"]) == 26
		and int(ev[1]["detalle"]["presupuesto_restante"]) == 74, "telemetría de válida")
	_decidir(ctrl, pm, "tr_carpool", "puestos_3_ocupantes", {"ok": true, "contraproducente": false})
	_check(completadas == ["tr_carpool"], "cambiar de opción no vuelve a pagar")
	_check(ctrl.plan.opcion_actual("tr_carpool") == "puestos_3_ocupantes", "cambio aplicado")

	# ── Kit del bicicletero ────────────────────────────────
	ctrl.verificar_herramienta = func(_tipo, _punto): return false
	ctrl._on_interaccion(ctrl._puntos["tr_bici_cafetin"])
	_check(not ctrl.hay_panel_abierto(), "sin kit no se abre el bicicletero")
	ctrl.verificar_herramienta = func(_tipo, _punto): return true

	# ── Resto del plan ─────────────────────────────────────
	_check(ctrl._puntos["tr_consejo"].estado == "bloqueado", "Consejo bloqueado con decisiones pendientes")
	var mejores := {
		"tr_permisos": "permiso_por_necesidad", "tr_lote": "ciclovia_arborizada",
		"tr_shuttle": "ruta_a_paradas", "tr_dia_sin_carros": "jornada_mensual_con_feria",
		"tr_flota": "carritos_electricos", "tr_bici_bloque_e": "techado_con_panel",
		"tr_bici_cafetin": "techado_con_panel",
	}
	for id in mejores.keys():
		_decidir(ctrl, pm, id, mejores[id], {"ok": true, "contraproducente": false})
	_check(ctrl.plan.todas_resueltas() and ctrl.plan.restante() == 0, "plan completo con 100 de presupuesto")
	_check(completadas.size() == 8, "8 misiones de decisión (%d)" % completadas.size())
	_check(ctrl._puntos["tr_consejo"].estado == "pendiente", "Consejo disponible")

	# ── Consejo ────────────────────────────────────────────
	ctrl._on_interaccion(ctrl._puntos["tr_consejo"])
	_check(ctrl.panel_consejo.visible and ctrl.panel_consejo.fase == "revision", "Consejo abre la revisión")
	ctrl.panel_consejo._iniciar_objeciones()
	for k in 3:
		var obj : Dictionary = ctrl.panel_consejo._objeciones[ctrl.panel_consejo._idx]
		var args : Array = obj["argumentos"]
		for i in args.size():
			if args[i]["correcto"]:
				ctrl.panel_consejo._on_argumento(i)
				break
		ctrl.panel_consejo._on_siguiente()
	_check(ctrl.plan.presentado() and ctrl.plan.consejo["calificacion"] == "consejo_3", "presentado con 3 aciertos")
	_check(nm.mision_completada_q(5, "tr_consejo") and completadas.size() == 9, "tr_consejo completa")
	_check(pagos.size() == 9 and pagos.back() == [35, 12], "el Consejo también paga normal")
	_check(pm.decisiones.back() == ["tr_consejo", "consejo_3"], "calificación registrada")
	_check(pm.sinergias == ["ciclovia_lote", "dia_sin_carros_feria", "flota_electrica", "bicicletero_techado_solar"], "cruces del plan registrados")
	_check(nm.nivel_completo(5), "Nivel 5 completo con las 9 misiones")
	_check(_eventos(sm, "argumento_consejo").size() == 3 and _eventos(sm, "plan_presentado").size() == 1, "telemetría del Consejo")
	_check(not bool(ctrl.plan.consejo["registrado"]), "sin respuesta todavía: no registrado")
	pm.decision_resuelta.emit("tr_consejo", "consejo_3", {"ok": true, "contraproducente": false})
	_check(bool(nm.obtener_detalle("plan_movilidad")["consejo"]["registrado"]), "registro confirmado y guardado")
	_check(ctrl._puntos["tr_consejo"].estado == "resuelto", "Consejo resuelto")
	ctrl.panel_consejo.cerrar()
	var det_txt := JSON.stringify(nm.obtener_detalle("plan_movilidad"))
	_check(det_txt.length() < 8192, "detalle < 8 KB (%d)" % det_txt.length())

	ctrl._on_interaccion(ctrl._puntos["tr_lote"])
	_check(ctrl.panel_decision.estado == "solo_lectura", "plan presentado: decisión de solo lectura")
	ctrl.panel_decision.cerrar()

	var antes : int = pm.sinergias.size()
	ctrl._on_interaccion(ctrl._puntos["tr_consejo"])
	_check(ctrl.panel_consejo.fase == "resultado" and pm.sinergias.size() == antes + 4, "resultado y cruces reenviados")
	ctrl.panel_consejo.cerrar()

	# ── Restauración tardía ────────────────────────────────
	var nm2 : Node = load("res://autoload/NivelManager.gd").new()
	nm2._misiones = nm._misiones.duplicate(true)
	var mapa2 := Node2D.new()
	add_child(mapa2)
	var ctrl2 : Node = CTRL.new()
	add_child(ctrl2)
	ctrl2.configurar(mapa2, nm2, pm, sm)
	ctrl2.activar()
	_check(ctrl2.plan.vacio(), "sin detalle todavía: plan vacío")
	nm2.aplicar_detalle_servidor("plan_movilidad", nm.obtener_detalle("plan_movilidad"))
	ctrl2._on_interaccion(ctrl2._puntos["oficina"])
	_check(ctrl2.plan.presentado() and ctrl2._puntos["tr_consejo"].estado == "resuelto", "el plan se recarga en la primera interacción")
	ctrl2.panel_oficina.cerrar()

	# ── Sin re-pago a quien completó el Nivel 5 viejo ───────
	var nm3 : Node = load("res://autoload/NivelManager.gd").new()
	nm3._misiones = nm._misiones.duplicate(true)
	var viejo5 := {}
	for id in nm3.MISIONES_LEGADO[5]:
		viejo5[id] = true
	nm3._misiones["5"] = viejo5
	var mapa3 := Node2D.new()
	add_child(mapa3)
	var ctrl3 : Node = CTRL.new()
	add_child(ctrl3)
	var pm3 := FakePuntaje.new()
	add_child(pm3)
	ctrl3.configurar(mapa3, nm3, pm3, sm)
	ctrl3.activar()
	var pagos3 := []
	ctrl3.mision_completada.connect(func(id, xp, ec): pagos3.append([id, xp, ec]))
	ctrl3._on_interaccion(ctrl3._puntos["oficina"])
	ctrl3.panel_oficina._on_aceptar()
	ctrl3.panel_oficina.cerrar()
	_decidir(ctrl3, pm3, "tr_lote", "ciclovia_arborizada", {"ok": true, "contraproducente": false})
	_check(pagos3 == [["tr_lote", 0, 0]], "Nivel 5 viejo completo: la misión se completa sin XP ni EC")
	_check(nm3.mision_completada_q(5, "tr_lote") and nm3.nivel_desbloqueado(6), "igual cuenta como completa y el 6 sigue abierto")
	_check(pm3.decisiones.back() == ["tr_lote", "ciclovia_arborizada"], "igual registra la decisión (puntaje)")

	_verificar_espejo_sql()

	nm.free()
	nm2.free()
	nm3.free()
	print("test_nivel5_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_nivel5_movilidad.tscn; echo exit=$?` → Expected: error de preload, exit≠0.

- [ ] **Step 3: Implement**

`scenes/misiones/nivel5_movilidad.gd`:
```gdscript
# ============================================================
# nivel5_movilidad.gd — NIVEL 5: controlador del Plan de Movilidad.
# Reemplaza a oficina_movilidad.gd, mision_movilidad.gd,
# punto_bicicletero.gd y mision_bicicletero.gd.
# Tiene el plan, crea los 10 puntos (por lugar) y el nodo de cambios del
# mapa, abre los paneles, guarda el detalle "plan_movilidad", completa
# misiones (una vez), registra decisiones/cruces/telemetría y emite
# mision_completada para que SceneMapaMundo dé XP/EC y guarde el progreso.
# Dependencias inyectadas (configurar) para probarlo sin red.
# Diseño: docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md
# ============================================================
extends Node

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const PLAN := preload("res://scenes/misiones/plan_movilidad.gd")
const PUNTO := preload("res://scenes/misiones/punto_movilidad.gd")
const PANEL_DECISION := preload("res://scenes/misiones/panel_decision_movilidad.gd")
const PANEL_OFICINA := preload("res://scenes/misiones/panel_oficina_movilidad.gd")
const PANEL_CONSEJO := preload("res://scenes/misiones/panel_consejo_movilidad.gd")
const CAMBIOS := preload("res://scenes/mapa/cambios_movilidad.gd")

const NIVEL := 5
const CLAVE_DETALLE := "plan_movilidad"

signal mision_completada(mision_id: String, xp: int, ec: int)

var plan = PLAN.new()
# (tipo: String, punto: Node) -> bool. SceneMapaMundo pasa _verificar_herramienta.
var verificar_herramienta : Callable = Callable()

var panel_decision = null
var panel_oficina = null
var panel_consejo = null

var _mapa : Node = null
var _nm : Node = null
var _pm : Node = null
var _sm : Node = null
var _puntos : Dictionary = {}          # "oficina" | decision_id | "tr_consejo" -> punto
var _cambios = null
var _volver_a_consejo : bool = false


func configurar(mapa: Node, nivel_mgr: Node, puntaje_mgr: Node, supa: Node) -> void:
	_mapa = mapa
	_nm = nivel_mgr
	_pm = puntaje_mgr
	_sm = supa
	plan.cargar(_nm.obtener_detalle(CLAVE_DETALLE))

	panel_decision = PANEL_DECISION.new()
	add_child(panel_decision)
	panel_decision.plan = plan
	panel_decision.registrar = Callable(_pm, "registrar_decision")
	panel_decision.decision_registrada.connect(_on_decision_registrada)
	panel_decision.cerrado.connect(_on_panel_decision_cerrado)

	panel_oficina = PANEL_OFICINA.new()
	add_child(panel_oficina)
	panel_oficina.encargo_aceptado.connect(_on_encargo_aceptado)

	panel_consejo = PANEL_CONSEJO.new()
	add_child(panel_consejo)
	panel_consejo.cambio_solicitado.connect(_on_cambio_solicitado)
	panel_consejo.argumento_elegido.connect(_on_argumento_elegido)
	panel_consejo.plan_presentado.connect(_on_plan_presentado)
	panel_consejo.reintentar_registro.connect(_registrar_calificacion)

	_pm.decision_resuelta.connect(panel_decision.recibir_respuesta)
	_pm.decision_resuelta.connect(_on_decision_resuelta)


func activar() -> void:
	if not _puntos.is_empty() or _mapa == null or not _nm.nivel_desbloqueado(NIVEL):
		return
	_cambios = CAMBIOS.new()
	_mapa.add_child(_cambios)
	_crear_punto("oficina", "oficina", "oficina_movilidad", "Oficina de Movilidad")
	for d in DATOS.DECISIONES:
		_crear_punto(d["id"], d["tipo"], d["lugar"], d["titulo"])
	_crear_punto(DATOS.DECISION_CONSEJO, "consejo", "rectorado", "Consejo Universitario")
	_refrescar()


func hay_panel_abierto() -> bool:
	for p in [panel_decision, panel_oficina, panel_consejo]:
		if p != null and p.visible:
			return true
	return false


func _crear_punto(clave: String, tipo: String, lugar: String, nombre: String) -> void:
	var p = PUNTO.new()
	p.mision_id = "" if tipo == "oficina" else clave
	p.tipo = tipo
	p.lugar = lugar
	p.nombre_punto = nombre
	p.z_index = 1
	_mapa.add_child(p)
	p.interaccion_solicitada.connect(_on_interaccion)
	_puntos[clave] = p


func _refrescar() -> void:
	if _puntos.is_empty():
		return
	_puntos["oficina"].set_estado("resuelto" if plan.encargo_aceptado else "pendiente")
	for id in DATOS.ids_decisiones():
		var e := "bloqueado"
		if plan.encargo_aceptado:
			e = "resuelto" if plan.resuelta(id) else "pendiente"
		_puntos[id].set_estado(e)
	var ec := "bloqueado"
	if plan.presentado():
		ec = "resuelto"
	elif plan.encargo_aceptado and plan.todas_resueltas():
		ec = "pendiente"
	_puntos[DATOS.DECISION_CONSEJO].set_estado(ec)
	if _cambios:
		_cambios.actualizar(plan)


func _on_interaccion(punto) -> void:
	if hay_panel_abierto():
		return
	# Restauración tardía: el detalle pudo llegar del servidor después de
	# crear el controlador (timeout del login).
	if plan.vacio():
		plan.cargar(_nm.obtener_detalle(CLAVE_DETALLE))
		_refrescar()
	var tipo := str(punto.get("tipo"))
	match tipo:
		"oficina":
			panel_oficina.abrir(plan)
		"consejo":
			if plan.presentado():
				_reenviar_sinergias()
			elif not (plan.encargo_aceptado and plan.todas_resueltas()):
				return
			panel_consejo.abrir(plan)
		_:
			var id := str(punto.get("mision_id"))
			if not plan.encargo_aceptado:
				return
			if not plan.resuelta(id):
				if tipo == "bicicletero" and verificar_herramienta.is_valid() \
						and not verificar_herramienta.call("bicicletero", punto):
					return
				_evento(id, "mision_iniciada", {})
			panel_decision.abrir(id)


func _on_encargo_aceptado() -> void:
	plan.encargo_aceptado = true
	_guardar()
	_evento(CLAVE_DETALLE, "encargo_aceptado", {})
	panel_oficina.abrir(plan)
	_refrescar()


func _on_decision_registrada(decision_id: String, opcion_id: String, contraproducente: bool, _penalizado: bool, ms: int) -> void:
	var o := DATOS.opcion(decision_id, opcion_id)
	_evento(decision_id, "decision_tomada", {
		"decision_id": decision_id, "opcion_id": opcion_id,
		"contraproducente": contraproducente, "costo": int(o.get("costo", 0)),
		"presupuesto_restante": plan.restante(), "ms_hasta_elegir": ms,
	}, not contraproducente)
	_guardar()
	if not contraproducente and not _nm.mision_completada_q(NIVEL, decision_id):
		_completar(decision_id)
	_refrescar()


func _on_panel_decision_cerrado() -> void:
	if _volver_a_consejo:
		_volver_a_consejo = false
		panel_consejo.abrir(plan)


func _on_cambio_solicitado(decision_id: String) -> void:
	_volver_a_consejo = true
	panel_consejo.visible = false
	panel_decision.abrir(decision_id, true)


func _on_argumento_elegido(decision_id: String, opcion_id: String, indice: int, correcto: bool, intento: int) -> void:
	_evento(DATOS.DECISION_CONSEJO, "argumento_consejo",
		{"decision_id": decision_id, "opcion_id": opcion_id, "argumento": indice}, correcto, intento)


func _on_plan_presentado() -> void:
	_guardar()
	_evento(DATOS.DECISION_CONSEJO, "plan_presentado", {
		"aciertos": int(plan.consejo.get("aciertos", 0)),
		"calificacion": str(plan.consejo.get("calificacion", "")),
		"presupuesto_restante": plan.restante(),
		"sinergias": plan.consejo.get("sinergias", []),
	})
	if not _nm.mision_completada_q(NIVEL, DATOS.DECISION_CONSEJO):
		_completar(DATOS.DECISION_CONSEJO)
	_registrar_calificacion()
	# Después de _completar: guardar_progreso(tr_consejo) ya está en la cola
	# FIFO de SupabaseManager y el servidor exige esa misión como requisito.
	_reenviar_sinergias()
	_refrescar()


# Registro de la calificación del Consejo. Se llama al presentar y solo a
# pedido del estudiante ("Reintentar registro"): nunca en automático.
func _registrar_calificacion() -> void:
	var cal := str(plan.consejo.get("calificacion", ""))
	if cal != "":
		_pm.registrar_decision(DATOS.DECISION_CONSEJO, cal)


# Idempotente en el servidor (una sinergia se gana una sola vez).
func _reenviar_sinergias() -> void:
	for s in plan.consejo.get("sinergias", []):
		_pm.registrar_sinergia(str(s))


func _on_decision_resuelta(decision_id: String, _opcion_id: String, respuesta: Dictionary) -> void:
	if decision_id != DATOS.DECISION_CONSEJO or not plan.presentado():
		return
	if bool(respuesta.get("ok", false)):
		plan.consejo["registrado"] = true
		_guardar()
		if panel_consejo.visible:
			panel_consejo.abrir(plan)


# Sin re-pago (spec §11.1): quien completó el Nivel 5 viejo recibe 0 y 0;
# SceneMapaMundo interpreta eso como "no dar XP ni EC" pero igual guarda el
# progreso (Avance de Transporte y requisito de los cruces).
func _completar(mision_id: String) -> void:
	var sin_pago : bool = _nm.legado_completo(NIVEL)
	_nm.completar_mision(NIVEL, mision_id)
	var xp : int = 0 if sin_pago else int(_nm.XP_POR_MISION.get(NIVEL, 35))
	var ec : int = 0 if sin_pago else int(_nm.EC_POR_MISION.get(NIVEL, 12))
	mision_completada.emit(mision_id, xp, ec)


func _guardar() -> void:
	_nm.guardar_detalle(CLAVE_DETALLE, plan.a_detalle())


func _evento(mision_id: String, tipo: String, detalle: Dictionary, correcto = null, intento = null) -> void:
	if _sm != null and _sm.has_method("registrar_evento"):
		_sm.registrar_evento(NIVEL, mision_id, tipo, detalle, correcto, intento)
```

- [ ] **Step 4: Run test to verify it passes**

Run: igual que Step 2 → exit=0, sin `SCRIPT ERROR`. Correr también `test_plan_movilidad`, `test_panel_decision_movilidad`, `test_panel_consejo_movilidad`, `test_cambios_movilidad`, `test_punto_movilidad` → exit=0.

- [ ] **Step 5: Commit**

```bash
git add scenes/misiones/nivel5_movilidad.gd scenes/misiones/nivel5_movilidad.gd.uid tests/test_nivel5_movilidad.gd tests/test_nivel5_movilidad.gd.uid tests/test_nivel5_movilidad.tscn
git commit -m "nivel 5: controlador del Plan de Movilidad (puntos, paneles, misiones y cruces)

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 12: Integración en SceneMapaMundo y borrado del Nivel 5 viejo  *(Ola 5; requiere Tasks 4 y 11)*

**Files:**
- Modify: `scenes/mapa/SceneMapaMundo.gd`
- Modify: `tests/test_compila.gd`
- Delete: `scenes/misiones/mision_movilidad.gd`, `scenes/misiones/oficina_movilidad.gd`, `scenes/misiones/mision_bicicletero.gd`, `scenes/misiones/punto_bicicletero.gd` (y sus `.gd.uid`)

**Interfaces:**
- Consumes: `NIVEL5_MOVILIDAD` (Task 11): `configurar`, `activar`, `hay_panel_abierto`, `verificar_herramienta`, `mision_completada` (0/0 = sin pago); `NivelManager.legado_completo` (Task 4).

- [ ] **Step 1: Write the failing test**

En `tests/test_compila.gd`, en la lista del `for ruta in [...]`, reemplazar `"res://scenes/misiones/mision_movilidad.gd"` por `"res://scenes/misiones/nivel5_movilidad.gd"`. Antes de `var escena = load("res://scenes/mapa/SceneMapaMundo.gd")` agregar:
```gdscript
	# Nivel 5 nuevo (Plan de Movilidad): el mapa usa el controlador y los
	# scripts viejos ya no existen.
	_check(mapa_src.contains("nivel5_movilidad.gd") and mapa_src.contains("_nivel5.activar()")
		and mapa_src.contains("\"punto_movilidad\""), "SceneMapaMundo usa el Plan de Movilidad")
	for viejo in ["oficina_movilidad.gd", "mision_movilidad.gd", "punto_bicicletero.gd", "mision_bicicletero.gd",
				  "_spawn_oficina_movilidad", "_spawn_puntos_bicicletero", "DATOS_PUNTOS_BICICLETERO"]:
		_check(not mapa_src.contains(viejo), "SceneMapaMundo sin %s" % viejo)
	for ruta_vieja in ["mision_movilidad.gd", "oficina_movilidad.gd", "mision_bicicletero.gd", "punto_bicicletero.gd"]:
		_check(not FileAccess.file_exists("res://scenes/misiones/" + ruta_vieja), "borrado %s" % ruta_vieja)
	# Sin re-pago a quien completó el Nivel 5 viejo (spec §11.1).
	var i_mov := mapa_src.find("func _on_movilidad_completado")
	var cuerpo_mov := mapa_src.substr(i_mov, 1400)
	_check(i_mov != -1 and cuerpo_mov.contains("var pagar := xp > 0 or ec > 0")
		and cuerpo_mov.find("if pagar:") < cuerpo_mov.find("EconomiaManager.acreditar_mision")
		and cuerpo_mov.contains("SupabaseManager.guardar_progreso(5, mision_id"), "movilidad: sin pago no acredita pero guarda progreso")
	var i_niv := mapa_src.find("func _on_nivel_greenmetric_completado")
	var cuerpo_niv := mapa_src.substr(i_niv, 1600)
	_check(i_niv != -1 and cuerpo_niv.contains("nm.legado_completo(nivel)")
		and cuerpo_niv.find("legado_completo(nivel)") < cuerpo_niv.find("EconomiaManager.ganar_creditos(bonus_ec"), "bono de nivel omitido con legado completo")
```

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_compila.tscn; echo exit=$?` → Expected: FALLA en esas líneas, exit=1.

- [ ] **Step 2: Constantes y variables**

En `scenes/mapa/SceneMapaMundo.gd`, reemplazar
```gdscript
const OFICINA_MOVILIDAD_ESCENA  := preload("res://scenes/misiones/oficina_movilidad.gd")
const MISION_MOVILIDAD_ESCENA   := preload("res://scenes/misiones/mision_movilidad.gd")
const PUNTO_BICICLETERO_ESCENA  := preload("res://scenes/misiones/punto_bicicletero.gd")
const MISION_BICICLETERO_ESCENA := preload("res://scenes/misiones/mision_bicicletero.gd")
```
por
```gdscript
const NIVEL5_MOVILIDAD          := preload("res://scenes/misiones/nivel5_movilidad.gd")
```
Reemplazar
```gdscript
var _movilidad_ui     : CanvasLayer = null
var _bicicletero_ui   : CanvasLayer = null
```
por
```gdscript
var _nivel5           = null   # nivel5_movilidad.gd (Plan de Movilidad)
```

- [ ] **Step 3: Modales, tecla E y grupos**

Reemplazar
```gdscript
	if _movilidad_ui and _movilidad_ui.visible: return true
	if _bicicletero_ui and _bicicletero_ui.visible: return true
```
por
```gdscript
	if _nivel5 and _nivel5.hay_panel_abierto(): return true
```
Reemplazar
```gdscript
	# ── Misiones de todos los niveles: elige la MÁS CERCANA, no la
```
por
```gdscript
	# Con un panel del Plan de Movilidad abierto, la E no abre otra cosa.
	if _nivel5 and _nivel5.hay_panel_abierto():
		return
	# ── Misiones de todos los niveles: elige la MÁS CERCANA, no la
```
Reemplazar
```gdscript
		"llave_agua", "punto_captacion", "oficina_movilidad", "punto_bicicletero",
```
por
```gdscript
		"llave_agua", "punto_captacion", "punto_movilidad",
```

- [ ] **Step 4: Datos de posiciones viejas**

Reemplazar
```gdscript
const DATOS_OFICINA_MOVILIDAD : Array = [
	{"id": "oficina_movilidad", "nombre": "Oficina de Movilidad Sostenible", "pos": Vector2(600, 100)},
]

const DATOS_PUNTOS_BICICLETERO : Array = [
	{"id": "bicicletero_bloque_e", "nombre": "Bicicletero — Bloque E", "indice_mision": 0,
	 "pos": Vector2(1020, 460)},
	{"id": "bicicletero_cafetin",   "nombre": "Bicicletero — Cafetín",   "indice_mision": 1,
	 "pos": Vector2(200, 360)},
]
```
por
```gdscript
# Nivel 5 (Plan de Movilidad): sus puntos se ubican por lugar con nombre en
# scenes/mapa/lugares_campus.gd (lo crea nivel5_movilidad.gd).
```

- [ ] **Step 5: Creación y spawns**

En `_init_misiones_nivel`, reemplazar
```gdscript
	_movilidad_ui = MISION_MOVILIDAD_ESCENA.new()
	add_child(_movilidad_ui)
	_movilidad_ui.mision_movilidad_completada.connect(_on_movilidad_completado)

	_bicicletero_ui = MISION_BICICLETERO_ESCENA.new()
	add_child(_bicicletero_ui)
	_bicicletero_ui.mision_bicicletero_completada.connect(_on_bicicletero_completado)
```
por
```gdscript
	# Nivel 5: Plan de Movilidad (puntos por lugar, paneles, cambios del mapa).
	_nivel5 = NIVEL5_MOVILIDAD.new()
	add_child(_nivel5)
	_nivel5.configurar(self, NivelManager, PuntajeManager, SupabaseManager)
	_nivel5.verificar_herramienta = _verificar_herramienta
	_nivel5.mision_completada.connect(_on_movilidad_completado)
```
Reemplazar
```gdscript
	_spawn_oficina_movilidad()
	_spawn_puntos_bicicletero()
	_spawn_punto_malla_verde()
```
por
```gdscript
	_nivel5.activar()
	_spawn_punto_malla_verde()
```
En `_on_nivel_greenmetric_completado`, reemplazar
```gdscript
	elif sig_nivel == 5 and nm and nm.nivel_desbloqueado(5):
		_spawn_oficina_movilidad()
		_spawn_puntos_bicicletero()
```
por
```gdscript
	elif sig_nivel == 5 and nm and nm.nivel_desbloqueado(5):
		if _nivel5:
			_nivel5.activar()
```

- [ ] **Step 6: Borrar funciones viejas**

Borrar completas (desde su `func` hasta la línea en blanco antes de la función siguiente): `_spawn_oficina_movilidad`, `_spawn_puntos_bicicletero`, `_on_movilidad_solicitada`, `_on_bicicletero_solicitado`, `_on_bicicletero_completado`. Reemplazar la función `_on_movilidad_completado` completa por:
```gdscript
func _on_movilidad_completado(mision_id: String, xp: int, ec: int) -> void:
	# xp = 0 y ec = 0: el jugador ya había completado el Nivel 5 viejo y no
	# cobra de nuevo (spec Nivel 5 §11.1). Sin acreditar_mision el servidor
	# nunca paga EC; guardar_progreso con xp 0 registra la misión sin XP.
	var pagar := xp > 0 or ec > 0
	if pagar:
		xp = EconomiaManager.aplicar_bono_xp(xp)   # Credencial de voluntario (+10%)
		_aplicar_xp(xp, mision_id)
		EconomiaManager.acreditar_mision(mision_id, ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(5) if nm else 0.0
	_refrescar_progreso()
	SupabaseManager.guardar_progreso(5, mision_id, int(pct * 100), xp, nm.nivel_completo(5) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("🚲 Plan de Movilidad: misión %s | +%d XP | +%d EC%s" % [mision_id, xp, ec, "" if pagar else " (ya cobrado con el Nivel 5 viejo)"])
```
En `_on_nivel_greenmetric_completado`, reemplazar
```gdscript
	var bonus_ec : int = int(nm.XP_NIVEL_BONUS.get(nivel, 150)) / 5 if nm else 30
	EconomiaManager.ganar_creditos(bonus_ec, "nivel", str(nivel))
```
por
```gdscript
	# Sin re-pago del bono a quien ya había completado el nivel con sus
	# misiones viejas (spec Nivel 5 §11.1). Niveles sin cambios: siempre paga.
	if not (nm and nm.legado_completo(nivel)):
		var bonus_ec : int = int(nm.XP_NIVEL_BONUS.get(nivel, 150)) / 5 if nm else 30
		EconomiaManager.ganar_creditos(bonus_ec, "nivel", str(nivel))
```
Verificar: `grep -n "_movilidad_ui\|_bicicletero_ui\|MISION_MOVILIDAD\|OFICINA_MOVILIDAD\|PUNTO_BICICLETERO\|MISION_BICICLETERO\|_on_bicicletero\|_on_movilidad_solicitada" scenes/mapa/SceneMapaMundo.gd` → sin resultados.

- [ ] **Step 7: Borrar los scripts viejos**

```bash
git rm scenes/misiones/mision_movilidad.gd scenes/misiones/mision_movilidad.gd.uid scenes/misiones/oficina_movilidad.gd scenes/misiones/oficina_movilidad.gd.uid scenes/misiones/mision_bicicletero.gd scenes/misiones/mision_bicicletero.gd.uid scenes/misiones/punto_bicicletero.gd scenes/misiones/punto_bicicletero.gd.uid
grep -rn "mision_movilidad\.gd\|oficina_movilidad\.gd\|mision_bicicletero\.gd\|punto_bicicletero\.gd" --include=*.gd --include=*.tscn --include=*.godot . | grep -v "^./docs/"
```
El `grep` no debe devolver nada (solo pueden quedar menciones en `docs/`).

- [ ] **Step 8: Run tests**

Run, cada una con exit=0 y sin `SCRIPT ERROR`: `test_compila`, `test_niveles`, `test_rangos`, `test_puntaje`, `test_simulador`, `test_hud_controles`, `test_hud_paneles`, `test_hud_rango_aviso`, `test_hud_tema`, `test_mapa_avance`, `test_lugares_campus` (ya sin `DATOS_OFICINA_MOVILIDAD`/`DATOS_PUNTOS_BICICLETERO`), `test_plan_datos`, `test_plan_movilidad`, `test_punto_movilidad`, `test_panel_decision_movilidad`, `test_panel_consejo_movilidad`, `test_cambios_movilidad`, `test_nivel5_movilidad`, `test_ui_movilidad`.

Además, humo del mapa: `timeout 60 "$GODOT" --headless --path . res://scenes/mapa/scene_mapa_mundo.tscn --quit-after 120 2>&1 | grep -i "SCRIPT ERROR\|Parse Error\|Invalid"` → sin resultados.

- [ ] **Step 9: Commit**

```bash
git add scenes/mapa/SceneMapaMundo.gd tests/test_compila.gd
git commit -m "mapa: Nivel 5 usa el Plan de Movilidad sin re-pago; se eliminan los escenarios y bicicleteros viejos

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```
(Los borrados ya quedaron en el índice con `git rm`.)

---

### Task 13: Documentación y checklist de prueba del usuario  *(Ola 6; requiere Task 12)*

**Files:**
- Modify: `docs/matriz_cobertura_greenmetric.md` (filas TR1–TR7)
- Modify: `docs/ESTADO_PROYECTO.md` (§3, §4, §8)
- Modify: `docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md` (línea "Estado")
- Modify: `docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md` (línea "Estado")

- [ ] **Step 1: Matriz de cobertura**

En `docs/matriz_cobertura_greenmetric.md`, reemplazar las filas TR1–TR7 (dejar TR8 como está) por:
```markdown
| TR1 | Número total de vehículos (carros y motos) dividido entre la población total del campus | 200 | decisión | 5 | `tr_permisos` (Plan de Movilidad, garita del M5: permisos por necesidad · lectoras de placas · más puestos, contraproducente) | — (proyecto B implementado) | — | sí |
| TR2 | Servicios de transporte interno (shuttle) | 300 | decisión | 5 | `tr_shuttle` (parada de la Av. URBE: busetas a las paradas · estacionamiento externo · bono de gasolina, contraproducente) | — (proyecto B implementado) | — | sí |
| TR3 | Disponibilidad de Vehículos de Cero Emisiones (ZEV) en el campus | 200 | decisión | 5 | `tr_flota` (patio de mantenimiento: carritos eléctricos · triciclos de carga · camioneta diésel, contraproducente) | — (proyecto B implementado) | flota eléctrica → Energía (`flota_electrica`) | sí |
| TR4 | Número total de Vehículos de Cero Emisiones (ZEV) dividido entre la población total del campus | 200 | decisión | 5 | `tr_flota` (mismo escenario que TR3) | — (proyecto B implementado) | flota eléctrica → Energía (`flota_electrica`) | sí |
| TR5 | Proporción del área de estacionamiento en superficie sobre el área total del campus | 200 | decisión | 5 | `tr_lote` (lote detrás de Estudios a Distancia: ciclovía con árboles · explanada de eventos · asfaltar, contraproducente) | — (proyecto B implementado) | ciclovía → Entorno (`ciclovia_lote`) | sí |
| TR6 | Programa para limitar o disminuir el área de estacionamiento en el campus en los últimos 3 años (2021-2023) | 200 | decisión | 5 | `tr_lote` | — (proyecto B implementado) | ciclovía → Entorno (`ciclovia_lote`) | sí |
| TR7 | Número de iniciativas para disminuir los vehículos privados en el campus | 200 | decisión | 5 | `tr_carpool`, `tr_dia_sin_carros`, `tr_bici_bloque_e`, `tr_bici_cafetin` (bicicleteros con kit y decisión de tipo); objeciones del Consejo en `tr_consejo` | — (proyecto B implementado) | día sin carros con feria → Educación (`dia_sin_carros_feria`); bicicletero techado con panel → Energía (`bicicletero_techado_solar`) | sí |
```
Si la tabla-resumen por categoría o el texto de la sección de Transporte mencionan `mov_*` o "8 misiones", actualizarlos a las 9 misiones `tr_*` sin tocar otras categorías.

- [ ] **Step 2: ESTADO_PROYECTO.md**

- §3 (arquitectura del cliente): agregar un bloque "Nivel 5 — Plan de Movilidad" con una línea por archivo: `scenes/mapa/lugares_campus.gd` (lugares con nombre, provisional hasta el mapa nuevo), `scenes/mapa/cambios_movilidad.gd`, `scenes/misiones/plan_movilidad_datos.gd` (contenido; espejo del SQL), `plan_movilidad.gd` (reglas puras), `punto_movilidad.gd`, `ui_movilidad.gd`, `panel_decision_movilidad.gd`, `panel_oficina_movilidad.gd`, `panel_consejo_movilidad.gd`, `nivel5_movilidad.gd` (controlador); y las pruebas nuevas con el comando para correrlas.
- §4 (backend): subsección "Plan de Movilidad" — catálogos de decisiones (28 filas) y sinergias (4, requisito `tr_consejo`) aplicados; migración `nivel5_plan_movilidad_misiones` **pendiente de aplicar al publicar** (sql/nivel5_plan_movilidad.sql); detalle `plan_movilidad` en `detalles_estudiante`.
- §8 (pendientes): marcar "Proyecto B — Nivel 5 nuevo" como implementado con la fecha del día (`date +%F`), y dejar pendiente, en este orden y con OK del usuario: (1) aplicar la migración 2, (2) re-export `python scripts/exportar_web.py`, (3) prueba con cuenta real (checklist del Step 4), (4) merge/publicación; y agregar la tarea de seguimiento "unificar a tuteo los textos con voseo existentes" (spec §17).

- [ ] **Step 3: Estados de las specs**

- En `docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md`, la línea `- **Estado:** ...` pasa a: `- **Estado:** Paso 0 y proyecto A implementados (2026-09-14); proyecto B implementado en el cliente (<fecha del día>; migración de misiones y prueba con cuenta real pendientes, ver docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md); C pendiente.`
- En `docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md`, la línea `- **Estado:** ...` pasa a: `- **Estado:** Implementado en el cliente y catálogos aplicados (<fecha del día>); pendientes: migración 2 al publicar, re-export web y prueba con cuenta real.`

(`<fecha del día>` = salida de `date +%F`.)

- [ ] **Step 4: Checklist de prueba del usuario (va en el informe final, no en un archivo)**

Incluir en el informe al usuario, para después de aplicar la migración 2 y re-exportar:
1. Con una cuenta que tenga el Nivel 4 completo aparecen 10 puntos del Nivel 5; con una que tenía el Nivel 5 viejo completo, el Nivel 6 sigue abierto.
2. Oficina → encargo → decisiones desbloqueadas.
3. Una contraproducente: -1 en el panel GreenMetric (Decisiones de Transporte), presupuesto intacto, opción descartada.
4. Bicicletero sin kit: aviso y Tienda; con kit: decisión de tipo.
5. Consejo: 3 objeciones; un argumento incorrecto permite reintentar.
6. Tras presentar: avisos "✨ Sinergia" en Entorno/Energía/Educación según el plan; mismo número de Transporte en HUD, mapa de avance, resultados e informe.
7. Con una cuenta que tenía el Nivel 5 viejo completo: las misiones `tr_*` y el nivel no suben XP ni EcoCredits, pero el Avance de Transporte sí sube; con una cuenta nueva sí suben.
8. Supabase: `detalles_estudiante` con clave `plan_movilidad`; `puntos_calidad` con `decision:tr_*`, `penal:tr_*:1`, `sinergia:*`; `eventos_aprendizaje` con `decision_tomada`, `argumento_consejo`, `plan_presentado`.

- [ ] **Step 5: Commit**

```bash
git add docs/matriz_cobertura_greenmetric.md docs/ESTADO_PROYECTO.md docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md
git commit -m "docs: Nivel 5 Plan de Movilidad implementado; matriz y estado al día

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Self-review contra la spec

**Cobertura (sección de la spec → tarea):**

| Spec | Tarea(s) |
|---|---|
| §2 R1 reparto 5 puntos · R2 presupuesto | 2 (datos + prueba de sumas), 3 (misma verificación en SQL) |
| §2 R3 revelado · R4 descartes | 8 |
| §2 R5 cruces al Consejo | 3 (requisito `tr_consejo`), 11 (orden completar → registrar → sinergias) |
| §2 R6 plan cerrado · R8 reintento de argumento | 6, 8 (`solo_lectura`), 9 |
| §2 R7 objeciones por debilidad | 6 (ejemplos §7.2 probados), 9 |
| §2 R9 misión una vez | 11 |
| §2 R10 dos migraciones | 3 (aplica 1, prueba 2 sin aplicar), 13 (pendiente al publicar) |
| §2 R11 lugar del Consejo · §3 lugares | 1 |
| §2 R12 emoji | Global Constraints; textos de 2, 7, 8, 9 usan solo 🚲 🔒 🏆 ✨ 🌿 ⚡ 📚 |
| §2 R13 / §11.1 sin re-pago | 4 (`legado_completo` + pruebas: completo, a medias, nuevo, niveles sin cambio), 11 (0/0 vs 35/12, probado), 12 (`_on_movilidad_completado`, bono de nivel; verificado en `test_compila`) |
| §2 R14 tuteo | 2, 7, 8, 9 (textos revisados); seguimiento del voseo existente en 13 |
| §4 flujo | 7 (bloqueos), 9 (Oficina/Consejo), 11 |
| §6 decisiones · §7.3 objeciones | 2 (copia literal) |
| §7.1 revisión con 2 cambios | 6 (`aplicar_valida(..., true)`), 9 (`Cambiar`), 11 (volver al Consejo) |
| §7.5 calificación y registro | 2 (`CONSEJO_OPCIONES`), 9 (resultado, reintento manual), 11 |
| §8 regla Mixta, respuestas, sin reintento automático | 8 |
| §9 persistencia y restauración tardía | 6 (forma y tolerancia), 11 (guardar, recarga) |
| §10 servidor y espejo | 3, 11 (`_verificar_espejo_sql`, espejo de misiones) |
| §11 misiones y legado | 4 |
| §12 cambios del mapa | 10 |
| §13 interfaz (tema, E bloqueada, controlador) | 5, 7, 8, 9, 11, 12 |
| §14 telemetría | 11 |
| §15 casos borde | 8 (red, espera, presupuesto, sin sesión), 11 (kit, encargo, Consejo bloqueado, reenviar cruces, restauración) |
| §16 criterios | pruebas de cada tarea + checklist Task 13 |

**Placeholders:** ninguno en código ni SQL. Únicos valores a completar al ejecutar: la fecha del día en la Task 13 (con `date +%F`).

**Consistencia de nombres verificada:**
- IDs de decisión/opción/sinergia idénticos en spec §5–§10, `plan_movilidad_datos.gd`, `sql/nivel5_plan_movilidad.sql` y las pruebas.
- `LUGARES.posicion`/`existe` (T1) = usos en T7, T10, T11; claves de lugar = `DATOS.DECISIONES[*].lugar` + `oficina_movilidad`/`rectorado`.
- `plan_movilidad.gd` API (T6) = usos en T8 (`opcion_actual`, `alcanza`, `faltante`, `descartada`, `registrar_contraproducente`, `aplicar_valida`, `presentado`, `puede_cambiar_en_consejo`, `restante`, `resuelta`), T9 (`costo_comprometido`, `todas_resueltas`, `puede_presentar`, `objeciones`, `presentar`, `calificacion_estimada`, `cambios_en_consejo`, `consejo`), T10 (`opcion_actual`), T11 (`cargar`, `a_detalle`, `vacio`, `encargo_aceptado`, `sinergias` vía `consejo.sinergias`).
- Señales de paneles (T8, T9) = conexiones en T11 con la misma cantidad de argumentos.
- `NivelManager.MISIONES_NIVEL[5]` (T4) = `DATOS.MISIONES` (T2), verificado en T11.
- `NivelManager.legado_completo` (T4) = usos en T11 (`_completar`) y T12 (`_on_nivel_greenmetric_completado`); contrato 0/0 = sin pago igual en T11 y T12.
- Estados del punto `bloqueado|pendiente|resuelto` y grupo `punto_movilidad` = T7, T11, T12.

**Riesgos de ejecución anotados:** Godot corriendo en paralelo en olas 1 y 3 (reintentar si falla la importación); la Task 3 necesita MCP de Supabase; la migración 2 queda deliberadamente sin aplicar.

