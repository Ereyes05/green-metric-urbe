# HUD plano 2b + rangos por nivel + ranking — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el HUD del mapa por el HUD plano de la especificación 2b, con rangos que se ganan completando niveles y un ranking que funcione (nombre + inicial, "(Tú)" correcto).

**Architecture:** Lógica pura de rangos en `autoload/rangos.gd` (sin autoloads, testeable). Ranking servido por una función pública de Supabase (`ranking_publico`) que nunca expone cédula, correo ni user_id. El HUD se parte en componentes chicos en `scenes/ui/hud_*.gd`, todos con estilo tomado de un único tema (`scenes/ui/hud_tema.gd`); `SceneMapaMundo.gd` solo los crea y les pasa datos.

**Tech Stack:** Godot 4.7 GDScript (StyleBoxFlat, FontVariation, tweens), Supabase Postgres (SECURITY DEFINER), pruebas como escenas headless.

**Spec:** `docs/diseno/hud_plano_2b.md` (decisiones + especificación 2b). Contexto: `docs/ESTADO_PROYECTO.md` §8 "PRÓXIMO AL RETOMAR".

## Global Constraints

- Godot 4.7. Godot: `GODOT="/c/Users/edward/OneDrive/Desktop/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe"`. Correr pruebas con `timeout 120 "$GODOT" --headless --path . res://tests/<t>.tscn` (sin timeout un error de script cuelga el proceso). Código de salida 0 = pasa.
- Todo script nuevo se commitea junto con su `.gd.uid` (Godot lo genera al correr cualquier escena con `--headless --path .`; si no aparece, correr `"$GODOT" --headless --path . --import`). Fuentes nuevas se commitean con su `.import`.
- Sin `class_name` nuevos: referenciar scripts con `const X := preload("res://...")` (patrón de `autoload/puntaje_formula.gd`).
- El ranking NUNCA devuelve cédula, correo ni user_id. "(Tú)" se decide en el servidor con `auth.uid()`.
- Las pruebas contra la base de producción van en bloques `DO` que terminan en `raise exception` para no dejar datos.
- Nada de push, merge ni publicación web sin OK del usuario. No re-exportar `docs/juego` en este plan.
- Resolución de diseño 1280×720; safe area 16 px; `project.godot` NO se toca (stretch aspect queda en `expand`, los paneles se anclan).
- Tokens de color/fuente/radio viven SOLO en `scenes/ui/hud_tema.gd` (copiados verbatim de la spec 2b: fondo panel #101C26 al 86 %, track #000 al 50 %, texto #EAF2EE/#C9D8D3/#9FB3AE/#7E938E, acentos #62D06A #3FBEDC #E8BE55 #E5893E #9B77DF #4FD1B0 #E8556B; radios panel 12 · caja 8 · botón 10 · chip 6; bordes 2 px paneles/botones, 1 px cajas).
- Rangos: Semilla (0 niveles), Brote (1), Árbol (2), Estratega (3), Investigador (4 y 5), EcoLíder (los 6).
- Textos de UI en español rioplatense neutro como el resto del juego; commits en español, terminando con `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.

## Rulings de diseño tomados al escribir el plan

- **Barra "hacia el siguiente rango":** los rangos ya no dependen del XP, así que la barra muestra el avance de misiones del/los nivel(es) que faltan para el siguiente rango (con 4 o 5 niveles completos, EcoLíder pide el 5 y el 6). Texto izq. «Hacia Estratega», der. «1578 XP». Con EcoLíder: «Rango máximo» y barra llena.
- **Nombre + inicial:** primer nombre + inicial del primer apellido. `estudiantes.nombre` guarda 3–4 palabras: con 4+ palabras el apellido es la 3.ª, con 2–3 es la 2.ª. Vacío o con "@" → "Eco-Ranger".
- **Banner de zona:** queda visible mientras el jugador está en la zona (la pista «E · interactuar» debe verse); se anima al entrar (0,18 s) y al salir (0,25 s). La notificación central al entrar a una zona se elimina (duplicaba el banner).
- **Capas:** el HUD sigue en el CanvasLayer existente (layer 5) con el aviso en el mismo canvas; no se crean CanvasLayer 1/2.
- **Emoji de rango:** «⭐» (ya está en el recorte de NotoColorEmoji).
- **Celebración:** la de "¡NIVEL SUBIDO!" por XP se elimina; al subir de rango se muestra un aviso central «⭐ Nuevo rango: <nombre>».

---

### Task 1: Rangos por nivel completado

**Files:**
- Create: `autoload/rangos.gd`
- Test: `tests/test_rangos.gd`, `tests/test_rangos.tscn`

**Interfaces:**
- Produces (`const RANGOS := preload("res://autoload/rangos.gd")`):
  - `RANGOS.NOMBRES : Array[String]` = `["Semilla", "Brote", "Árbol", "Estratega", "Investigador", "EcoLíder"]`
  - `RANGOS.indice(niveles_completos: int) -> int` (0..5)
  - `RANGOS.nombre(niveles_completos: int) -> String`
  - `RANGOS.siguiente(niveles_completos: int) -> String` ("" si es EcoLíder)
  - `RANGOS.niveles_superados(nm: Object) -> int` (cuenta `nm.nivel_superado(n)` para n=1..6)
  - `RANGOS.fraccion_siguiente(nm: Object) -> float` (0..1)

- [ ] **Step 1: Write the failing test**

`tests/test_rangos.tscn`:
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/test_rangos.gd" id="1"]

[node name="TestRangos" type="Node"]
script = ExtResource("1")
```

`tests/test_rangos.gd`:
```gdscript
# Prueba de rangos: uno por nivel completado.
# Correr: $GODOT --headless --path . res://tests/test_rangos.tscn
extends Node

const RANGOS := preload("res://autoload/rangos.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


# NivelManager real con los niveles 1..hasta completos y `parcial` misiones
# hechas del nivel siguiente.
func _nm_con(hasta: int, parcial: int = 0) -> Node:
	var nm : Node = load("res://autoload/NivelManager.gd").new()
	var mis : Dictionary = {}
	for n in range(1, hasta + 1):
		var d := {}
		for id in nm.MISIONES_NIVEL[n]:
			d[id] = true
		mis[str(n)] = d
	if hasta < 6 and parcial > 0:
		var d2 := {}
		var ids : Array = nm.MISIONES_NIVEL[hasta + 1]
		for i in mini(parcial, ids.size()):
			d2[ids[i]] = true
		mis[str(hasta + 1)] = d2
	nm._misiones = mis
	return nm


func _ready() -> void:
	print("test_rangos")
	var esperados := ["Semilla", "Brote", "Árbol", "Estratega", "Investigador", "Investigador", "EcoLíder"]
	for c in range(0, 7):
		_check(RANGOS.nombre(c) == esperados[c], "%d niveles -> %s" % [c, esperados[c]])
	_check(RANGOS.indice(-3) == 0, "negativo se trata como 0")
	_check(RANGOS.indice(9) == 5, "más de 6 es EcoLíder")
	_check(RANGOS.siguiente(0) == "Brote", "desde Semilla sigue Brote")
	_check(RANGOS.siguiente(4) == "EcoLíder", "desde Investigador (4) sigue EcoLíder")
	_check(RANGOS.siguiente(5) == "EcoLíder", "desde Investigador (5) sigue EcoLíder")
	_check(RANGOS.siguiente(6) == "", "EcoLíder no tiene siguiente")

	var nm := _nm_con(0)
	_check(RANGOS.niveles_superados(nm) == 0, "sin misiones: 0 niveles")
	_check(is_equal_approx(RANGOS.fraccion_siguiente(nm), 0.0), "sin misiones: 0 hacia Brote")
	nm.free()

	nm = _nm_con(2)
	_check(RANGOS.niveles_superados(nm) == 2, "niveles 1-2 completos: 2")
	_check(RANGOS.nombre(RANGOS.niveles_superados(nm)) == "Árbol", "niveles 1-2 -> Árbol")
	nm.free()

	var total3 : int = load("res://autoload/NivelManager.gd").MISIONES_NIVEL[3].size()
	nm = _nm_con(2, 3)
	_check(is_equal_approx(RANGOS.fraccion_siguiente(nm), 3.0 / total3), "hacia Estratega = avance del nivel 3")
	nm.free()

	# Con 4 completos, EcoLíder pide el 5 y el 6: mitad del camino si el 5 está completo.
	nm = _nm_con(5)
	_check(RANGOS.niveles_superados(nm) == 5, "niveles 1-5 completos: 5")
	_check(is_equal_approx(RANGOS.fraccion_siguiente(nm), 0.5), "5 completos: 50% hacia EcoLíder")
	nm.free()

	nm = _nm_con(6)
	_check(RANGOS.niveles_superados(nm) == 6, "todo completo: 6")
	_check(is_equal_approx(RANGOS.fraccion_siguiente(nm), 1.0), "EcoLíder: barra llena")
	nm.free()

	print("test_rangos: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_rangos.tscn; echo exit=$?`
Expected: error de carga de `res://autoload/rangos.gd` y exit distinto de 0.

- [ ] **Step 3: Write minimal implementation**

`autoload/rangos.gd`:
```gdscript
# ============================================================
# rangos.gd — rango del jugador: uno por nivel completado.
# Antes el rango salía del XP (Semilla 0 … EcoLíder 12000), pero el
# juego entero da ~2.800 XP y nadie pasaba de Árbol. Ahora cada nivel
# completado sube un rango; con 6 niveles y 6 rangos, Investigador
# cubre 4 y 5 niveles, y EcoLíder exige los 6.
# Espejo en el servidor: public.ranking_publico (sql/ranking_publico.sql).
# Sin referencias a autoloads, para poder probarlo solo.
# ============================================================
extends RefCounted

const NOMBRES : Array[String] = ["Semilla", "Brote", "Árbol", "Estratega", "Investigador", "EcoLíder"]


static func indice(niveles_completos: int) -> int:
	if niveles_completos >= 6:
		return 5
	return clampi(niveles_completos, 0, 4)


static func nombre(niveles_completos: int) -> String:
	return NOMBRES[indice(niveles_completos)]


static func siguiente(niveles_completos: int) -> String:
	var i := indice(niveles_completos)
	return "" if i == NOMBRES.size() - 1 else NOMBRES[i + 1]


# nm: NivelManager (o cualquier objeto con nivel_superado(n)).
static func niveles_superados(nm: Object) -> int:
	var c := 0
	for n in range(1, 7):
		if nm.nivel_superado(n):
			c += 1
	return c


# Niveles cuyo avance llena la barra hacia el siguiente rango.
static func _niveles_para_siguiente(c: int) -> Array[int]:
	if c >= 6:
		return []
	if c >= 4:
		return [5, 6]
	return [c + 1]


static func fraccion_siguiente(nm: Object) -> float:
	var niveles := _niveles_para_siguiente(niveles_superados(nm))
	if niveles.is_empty():
		return 1.0
	var suma := 0.0
	for n in niveles:
		suma += 1.0 if nm.nivel_superado(n) else clampf(nm.pct_nivel(n), 0.0, 1.0)
	return suma / niveles.size()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_rangos.tscn; echo exit=$?`
Expected: `test_rangos: 0 fallos`, exit=0. Correr también `test_niveles.tscn` (exit=0).

- [ ] **Step 5: Commit**

```bash
git add autoload/rangos.gd autoload/rangos.gd.uid tests/test_rangos.gd tests/test_rangos.gd.uid tests/test_rangos.tscn
git commit -m "rangos: uno por nivel completado en vez de por XP"
```

---

### Task 2: Ranking público (Supabase + cliente)

**Files:**
- Create: `sql/ranking_publico.sql`
- Modify: `autoload/SupabaseManager.gd` (señales ~44, `cargar_ranking` ~289, `_emitir_fallo` ~193, `_procesar_ranking` ~686)
- Modify: `scenes/ui/leaderboard.gd` (reescritura de la carga y de las filas)
- Modify: `tests/test_compila.gd`

**Interfaces:**
- Consumes: `RANGOS.nombre(niveles_completos)` (Task 1).
- Produces:
  - RPC `public.ranking_publico() returns jsonb` → array (máx. 50, orden xp desc) de `{"nombre": String, "xp_total": int, "niveles_completos": int, "titulo": String|null, "es_yo": bool}`.
  - `SupabaseManager.ranking_cargado(lista: Array)` (misma firma, filas con el formato de arriba) y nueva `SupabaseManager.ranking_fallido()`.

Contexto: hoy `cargar_ranking` lee `progreso_estudiante` (tabla vieja) con la clave anónima; la RLS solo deja ver filas propias, así que la lista sale vacía. Además `leaderboard.gd` compara nombres para "(Tú)" y los nombres son `user_id.left(8)`, nunca coinciden. El XP real está en `estudiantes.xp_total`; las misiones en `misiones_estudiante(user_id, modulo_id, mision_id, xp_otorgada, completada_at)`; el catálogo en `catalogo_misiones(mision_id, categoria, tipo)` con `tipo='mision'` para misiones de campo; el título en `inventario_estudiante` + `catalogo_tienda` (`item_id='titulo_embajador'`, ver `titulos_ranking` en `sql/tienda_ecocredits.sql`). Project id Supabase: `ikohikbpvtbvsgyumvbr`.

- [ ] **Step 1: Escribir la función y su registro**

`sql/ranking_publico.sql` (registro de la migración `ranking_publico`; aplicarlo con la herramienta MCP `apply_migration`, name `ranking_publico`):
```sql
-- ============================================================
-- ranking_publico — tabla de clasificación sin datos sensibles.
-- Registro de la migración aplicada en Supabase (no re-ejecutar a mano).
--
-- Devuelve nombre + inicial del apellido, XP, niveles completos (para el
-- rango: ver autoload/rangos.gd) y el título de la tienda. NUNCA cédula,
-- correo ni user_id: "es_yo" se calcula acá con auth.uid(), así el cliente
-- no necesita ids ajenos para marcar "(Tú)".
-- Nivel completo = todas las misiones tipo 'mision' de esa categoría en
-- misiones_estudiante (mismo criterio que NivelManager.nivel_completo).
-- ============================================================
create or replace function public.ranking_publico()
returns jsonb language sql stable security definer set search_path to 'public' as $$
  with totales as (
    select categoria, count(*) as total
    from catalogo_misiones where tipo = 'mision'
    group by categoria
  ), hechas as (
    select me.user_id, cm.categoria, count(distinct me.mision_id) as n
    from misiones_estudiante me
    join catalogo_misiones cm on cm.mision_id = me.mision_id and cm.tipo = 'mision'
    group by me.user_id, cm.categoria
  ), completos as (
    select h.user_id, count(*) filter (where h.n >= t.total) as niveles
    from hechas h join totales t using (categoria)
    group by h.user_id
  ), top as (
    select e.id, coalesce(e.xp_total, 0) as xp, coalesce(c.niveles, 0) as niveles,
           regexp_split_to_array(trim(coalesce(e.nombre, '')), '\s+') as p
    from estudiantes e
    left join completos c on c.user_id = e.id
    order by xp desc, niveles desc
    limit 50
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'nombre', case
              when t.p[1] = '' or array_to_string(t.p, ' ') ~ '@' then 'Eco-Ranger'
              when array_length(t.p, 1) = 1 then initcap(t.p[1])
              else initcap(t.p[1]) || ' '
                   || upper(left(t.p[case when array_length(t.p, 1) >= 4 then 3 else 2 end], 1)) || '.'
            end,
           'xp_total', t.xp,
           'niveles_completos', t.niveles,
           'titulo', (select c.nombre from inventario_estudiante i
                      join catalogo_tienda c on c.item_id = i.item_id
                      where i.user_id = t.id and c.item_id = 'titulo_embajador' limit 1),
           'es_yo', coalesce(t.id = auth.uid(), false)
         ) order by t.xp desc, t.niveles desc), '[]'::jsonb)
  from top t
$$;

revoke execute on function public.ranking_publico() from public;
grant  execute on function public.ranking_publico() to anon, authenticated;
```

- [ ] **Step 2: Aplicar y probar en la base (sin dejar datos)**

Aplicar con `apply_migration`. Luego correr con `execute_sql` este bloque; debe terminar con el error `PRUEBA_OK` (cualquier otro error = falla):
```sql
do $$
declare
  u1 uuid := gen_random_uuid();
  u2 uuid := gen_random_uuid();
  r jsonb; f1 jsonb; f2 jsonb;
begin
  insert into auth.users (id, email) values (u1, 'rk1_' || u1 || '@prueba.local'), (u2, 'rk2_' || u2 || '@prueba.local');
  insert into estudiantes (id, nombre, cedula, xp_total) values
    (u1, 'Ana María Pérez Gómez', 'V-PRUEBA-1', 99001),
    (u2, 'Luis Soto',             'V-PRUEBA-2', 99000)
  on conflict (id) do update set nombre = excluded.nombre, cedula = excluded.cedula, xp_total = excluded.xp_total;
  insert into misiones_estudiante (user_id, modulo_id, mision_id, xp_otorgada)
    select u1, 1, mision_id, 0 from catalogo_misiones where categoria = 1 and tipo = 'mision';

  perform set_config('request.jwt.claims', json_build_object('sub', u1, 'role', 'authenticated')::text, true);
  r := public.ranking_publico();
  select e into f1 from jsonb_array_elements(r) e where e->>'nombre' = 'Ana P.';
  select e into f2 from jsonb_array_elements(r) e where e->>'nombre' = 'Luis S.';
  if f1 is null or f2 is null then raise exception 'FALLA nombres: %', r; end if;
  if (f1->>'niveles_completos')::int <> 1 then raise exception 'FALLA niveles u1: %', f1; end if;
  if (f2->>'niveles_completos')::int <> 0 then raise exception 'FALLA niveles u2: %', f2; end if;
  if not (f1->>'es_yo')::boolean or (f2->>'es_yo')::boolean then raise exception 'FALLA es_yo: % %', f1, f2; end if;
  if r::text ~ 'V-PRUEBA' or r::text ~ '@prueba' or r::text ~ u1::text then
    raise exception 'FALLA expone datos sensibles';
  end if;
  if (r->0->>'xp_total')::int < (r->1->>'xp_total')::int then raise exception 'FALLA orden'; end if;
  raise exception 'PRUEBA_OK';
end $$;
```
Si el insert en `auth.users` o `estudiantes` falla por columnas obligatorias, completar solo esas columnas con valores de prueba (no cambiar las aserciones). Correr `get_advisors` (security) y confirmar que no hay avisos nuevos sobre `ranking_publico`.

- [ ] **Step 3: Write the failing client test**

En `tests/test_compila.gd`, dentro del `if sm:` agregar:
```gdscript
		_check(sm.has_signal("ranking_fallido"), "SupabaseManager señal ranking_fallido existe")
		var src : String = FileAccess.get_file_as_string("res://autoload/SupabaseManager.gd")
		_check(src.contains("rpc/ranking_publico"), "cargar_ranking usa la RPC ranking_publico")
		_check(not src.contains("progreso_estudiante?select=user_id,xp_ganada"), "ya no lee progreso_estudiante para el ranking")
		var lb : String = FileAccess.get_file_as_string("res://scenes/ui/leaderboard.gd")
		_check(not lb.contains("qjuiwnwqkfmmfsdacpgd"), "leaderboard sin credenciales del proyecto viejo")
		_check(lb.contains("es_yo"), "leaderboard marca (Tú) con es_yo del servidor")
```
Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_compila.tscn; echo exit=$?` → Expected: FALLA en esas líneas, exit=1.

- [ ] **Step 4: Implementar en SupabaseManager**

Debajo de `signal ranking_cargado(lista: Array)`:
```gdscript
# La carga del ranking falló (red o HTTP). Sin esto la tabla quedaba en
# "Cargando..." para siempre.
signal ranking_fallido()
```
Reemplazar `cargar_ranking()`:
```gdscript
# RPC pública (sql/ranking_publico.sql): nombre + inicial, XP, niveles
# completos, título y es_yo. Con sesión se manda el JWT para que el
# servidor pueda marcar la fila propia.
func cargar_ranking() -> void:
	var headers := _headers_anon() if jwt_token.is_empty() else _headers_auth()
	_encolar("cargar_ranking", SUPABASE_URL + "/rest/v1/rpc/ranking_publico",
			 HTTPClient.METHOD_POST, headers, "{}")
```
En `_emitir_fallo`, agregar al final de la cadena:
```gdscript
	elif accion == "cargar_ranking":
		emit_signal("ranking_fallido")
```
Reemplazar `_procesar_ranking`:
```gdscript
func _procesar_ranking(code: int, datos: Variant) -> void:
	if code == 200 and datos is Array:
		emit_signal("ranking_cargado", datos)
	else:
		emit_signal("ranking_fallido")
		emit_signal("error_red", "No se pudo cargar el ranking.")
```

- [ ] **Step 5: Reescribir la carga en leaderboard.gd**

Borrar: `SUPABASE_URL`, `SUPABASE_KEY`, `NIVELES_NOMBRE`, `NIVELES_XP`, `_http`, `_titulos`, `_ultima_lista`, `_on_titulos_cargados`, `_on_request_completed`, `_xp_a_nivel`. Agregar arriba `const RANGOS := preload("res://autoload/rangos.gd")`. Actualizar el comentario de cabecera a "Consulta la RPC ranking_publico vía SupabaseManager. Muestra top-50 por XP con puesto, nombre, rango y XP."

```gdscript
func _ready() -> void:
	layer = 15
	_crear_ui()
	hide()
	# Conexiones permanentes: con CONNECT_ONE_SHOT, un fallo dejaba la
	# conexión colgada y el siguiente intento fallaba al reconectar.
	SupabaseManager.ranking_cargado.connect(_on_ranking_cargado)
	SupabaseManager.ranking_fallido.connect(_on_ranking_fallido)


func _cargar_ranking() -> void:
	if _cargando: return
	_cargando = true
	_estado_lbl.text    = "Cargando ranking..."
	_estado_lbl.visible = true
	_rows_vbox.visible  = false
	SupabaseManager.cargar_ranking()


func _on_ranking_cargado(lista: Array) -> void:
	_cargando = false
	if lista.is_empty():
		_estado_lbl.text = "Todavía no hay jugadores en el ranking."
		return
	_poblar_filas(lista)


func _on_ranking_fallido() -> void:
	_cargando = false
	_estado_lbl.text    = "No se pudo cargar el ranking. Probá con ↻ Actualizar."
	_estado_lbl.visible = true
```
En `_poblar_filas`, reemplazar el cálculo de cada fila por:
```gdscript
		var entrada : Dictionary = data[i] if data[i] is Dictionary else {}
		var xp      : int        = int(entrada.get("xp_total", 0))
		var nombre  : String     = str(entrada.get("nombre", "Eco-Ranger"))
		var nivel   : String     = RANGOS.nombre(int(entrada.get("niveles_completos", 0)))
		var es_yo   : bool       = bool(entrada.get("es_yo", false))
```
y el título por:
```gdscript
		var titulo_v = entrada.get("titulo")
		var titulo : String = "" if titulo_v == null else str(titulo_v)
```
(borrar la línea `var nombre_jugador ...`). En `_crear_ui`, el encabezado de columna `"Nivel"` pasa a `"Rango"`. La fila propia mantiene el fondo verde aunque esté en el top 3: cambiar las tres líneas `if i == 0 ... elif i == 2` para que solo apliquen cuando `not es_yo`.

- [ ] **Step 6: Run tests**

Run: `test_compila.tscn`, `test_rangos.tscn`, `test_puntaje.tscn`, `test_niveles.tscn` → todos exit=0. `grep -rn "titulos_ranking_cargados" scenes` no debe devolver nada (la señal y `cargar_titulos_ranking` quedan en SupabaseManager sin usarse; no borrarlas).

- [ ] **Step 7: Commit**

```bash
git add sql/ranking_publico.sql autoload/SupabaseManager.gd scenes/ui/leaderboard.gd tests/test_compila.gd
git commit -m "ranking: RPC ranking_publico con nombre + inicial y (Tú) desde el servidor"
```

---

### Task 3: Tema del HUD, fuente Rubik y barra reutilizable

**Files:**
- Create: `assets/fonts/Rubik-VariableFont_wght.ttf` (+ `.import`), `assets/fonts/OFL-Rubik.txt`
- Create: `scenes/ui/hud_tema.gd`, `scenes/ui/hud_barra.gd`
- Test: `tests/test_hud_tema.gd`, `tests/test_hud_tema.tscn`

**Interfaces:**
- Produces (`const TEMA := preload("res://scenes/ui/hud_tema.gd")`):
  - Colores: `TEMA.PANEL_BG, TRACK, TEXTO, TEXTO_2, TEXTO_3, APAGADO, VERDE, CIAN, DORADO, NARANJA, VIOLETA, TEAL, VIDAS, VACIO, PASO_PENDIENTE, LEYENDA, POPOVER_BG, SEPARADOR`
  - `TEMA.CATEGORIAS : Array` índice 1..6 → `{"icono": String, "nombre": String, "color": Color}` (índice 0 = `{}`)
  - `TEMA.caja(bg: Color, borde: Color, ancho_borde: int, radio: int, pad_h: int = 0, pad_v: int = 0) -> StyleBoxFlat`
  - `TEMA.panel(color_borde: Color) -> StyleBoxFlat` (fondo panel, borde 2, radio 12, padding 12/10/12/12)
  - `TEMA.rubik(peso: int = 400, tabular: bool = false) -> Font`
  - `TEMA.pixel() -> Font`
  - `TEMA.label(texto: String, tam: int, color: Color, peso: int = 400, pixel: bool = false, tabular: bool = false) -> Label` (mouse_filter IGNORE)
  - `TEMA.EMOJIS_HUD : Array[String]` — todos los emoji que usa el HUD
- Produces (`const BARRA := preload("res://scenes/ui/hud_barra.gd")`): `BARRA.new()` es un `Panel`; `configurar(color: Color, alto: int) -> void`, `set_fraccion(f: float, animar: bool = true) -> void`, var `fraccion: float`.

- [ ] **Step 1: Descargar Rubik (OFL)**

```bash
curl -fL -o "assets/fonts/Rubik-VariableFont_wght.ttf" "https://github.com/google/fonts/raw/main/ofl/rubik/Rubik%5Bwght%5D.ttf"
curl -fL -o "assets/fonts/OFL-Rubik.txt" "https://github.com/google/fonts/raw/main/ofl/rubik/OFL.txt"
ls -l assets/fonts/Rubik-VariableFont_wght.ttf   # debe pesar > 100 KB
timeout 300 "$GODOT" --headless --path . --import
```
Expected: aparece `assets/fonts/Rubik-VariableFont_wght.ttf.import`.

- [ ] **Step 2: Write the failing test**

`tests/test_hud_tema.tscn` (mismo formato que `test_rangos.tscn`, node name `TestHudTema`, script `res://tests/test_hud_tema.gd`).

`tests/test_hud_tema.gd`:
```gdscript
# Prueba del tema del HUD: fuentes, emoji y estilos.
# Correr: $GODOT --headless --path . res://tests/test_hud_tema.tscn
extends Node

const TEMA  := preload("res://scenes/ui/hud_tema.gd")
const BARRA := preload("res://scenes/ui/hud_barra.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_hud_tema")
	_check(TEMA.PANEL_BG.is_equal_approx(Color(16 / 255.0, 28 / 255.0, 38 / 255.0, 0.86)), "fondo panel #101C26 al 86%")
	_check(TEMA.VERDE.to_html(false) == "62d06a", "verde #62D06A")
	_check(TEMA.CATEGORIAS.size() == 7, "6 categorías + índice 0 vacío")
	_check(TEMA.CATEGORIAS[5]["color"].to_html(false) == "9b77df", "Transporte violeta")

	var p : StyleBoxFlat = TEMA.panel(TEMA.CIAN)
	_check(p.border_width_left == 2 and p.corner_radius_top_left == 12, "panel: borde 2, radio 12")
	_check(is_equal_approx(p.content_margin_left, 12.0) and is_equal_approx(p.content_margin_top, 10.0), "panel: padding 10/12")

	var r : Font = TEMA.rubik(600)
	_check(r != null, "Rubik carga")
	_check(r.has_char("Á".unicode_at(0)) and r.has_char("í".unicode_at(0)), "Rubik tiene acentos")
	_check(TEMA.rubik(600) == r, "Rubik por peso se cachea")
	_check(TEMA.pixel() != null, "Press Start 2P carga")

	# Cada emoji del HUD tiene que existir en alguna fuente de la cadena
	# (si no, en la web sale un cuadradito).
	for e in TEMA.EMOJIS_HUD:
		var cp : int = e.unicode_at(0)
		var ok := r.has_char(cp)
		for fb in r.fallbacks:
			ok = ok or fb.has_char(cp)
		_check(ok, "emoji %s (U+%X) disponible" % [e, cp])

	var l : Label = TEMA.label("Hola", 11, TEMA.TEXTO, 600)
	_check(l.get_theme_font_size("font_size") == 11, "label tamaño 11")
	_check(l.mouse_filter == Control.MOUSE_FILTER_IGNORE, "label no bloquea el mouse")

	var b = BARRA.new()
	b.configurar(TEMA.CIAN, 10)
	b.set_fraccion(1.7, false)
	_check(is_equal_approx(b.fraccion, 1.0), "barra recorta a 1.0")
	b.set_fraccion(0.45, false)
	_check(is_equal_approx(b.get_child(0).anchor_right, 0.45), "barra: anchor_right = fracción")
	b.free()
	l.free()

	print("test_hud_tema: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

Run: `timeout 120 "$GODOT" --headless --path . res://tests/test_hud_tema.tscn; echo exit=$?` → Expected: error de carga, exit≠0.

- [ ] **Step 3: Implementar el tema**

`scenes/ui/hud_tema.gd`:
```gdscript
# ============================================================
# hud_tema.gd — único lugar con colores, fuentes y radios del HUD
# (especificación 2b, docs/diseno/hud_plano_2b.md). Cambiar de estilo
# = cambiar este archivo, no los paneles.
# ============================================================
extends RefCounted

const RUTA_RUBIK := "res://assets/fonts/Rubik-VariableFont_wght.ttf"
const RUTA_PIXEL := "res://assets/fonts/PressStart2P-Regular.ttf"
const RUTA_EMOJI := "res://assets/fonts/NotoColorEmoji-subset.ttf"

const PANEL_BG       := Color(0.0627, 0.1098, 0.1490, 0.86)  # #101C26 86 %
const TRACK          := Color(0.0, 0.0, 0.0, 0.5)
const TEXTO          := Color("#EAF2EE")
const TEXTO_2        := Color("#C9D8D3")
const TEXTO_3        := Color("#9FB3AE")
const APAGADO        := Color("#7E938E")
const VERDE          := Color("#62D06A")
const CIAN           := Color("#3FBEDC")
const DORADO         := Color("#E8BE55")
const NARANJA        := Color("#E5893E")
const VIOLETA        := Color("#9B77DF")
const TEAL           := Color("#4FD1B0")
const VIDAS          := Color("#E8556B")
const VACIO          := Color("#3A4550")
const PASO_PENDIENTE := Color("#24323C")
const LEYENDA        := Color("#8FA0A8")
const POPOVER_BG     := Color(0.0392, 0.0706, 0.0980, 0.97)  # rgba(10,18,25,.97)
const SEPARADOR      := Color(1.0, 1.0, 1.0, 0.10)

const CATEGORIAS : Array = [
	{},
	{"icono": "🌿", "nombre": "Entorno",    "color": Color("#62D06A")},
	{"icono": "⚡", "nombre": "Energía",    "color": Color("#E8BE55")},
	{"icono": "♻", "nombre": "Residuos",   "color": Color("#E5893E")},
	{"icono": "💧", "nombre": "Agua",       "color": Color("#3FBEDC")},
	{"icono": "🚲", "nombre": "Transporte", "color": Color("#9B77DF")},
	{"icono": "📚", "nombre": "Educación",  "color": Color("#4FD1B0")},
]

const EMOJIS_HUD : Array[String] = [
	"🌿", "⚡", "♻", "💧", "🚲", "📚", "⭐", "💰", "🌡", "📊", "🏆", "🔬", "🛒", "✨", "🔒", "♥",
]

static var _rubik_cache : Dictionary = {}
static var _pixel : Font = null


static func caja(bg: Color, borde: Color, ancho_borde: int, radio: int, pad_h: int = 0, pad_v: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = borde
	s.set_border_width_all(ancho_borde)
	s.set_corner_radius_all(radio)
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	s.anti_aliasing = true
	return s


static func panel(color_borde: Color) -> StyleBoxFlat:
	var s := caja(PANEL_BG, color_borde, 2, 12, 12, 12)
	s.content_margin_top = 10
	return s


static func _emoji() -> Font:
	return load(RUTA_EMOJI) as Font if ResourceLoader.exists(RUTA_EMOJI) else null


static func rubik(peso: int = 400, tabular: bool = false) -> Font:
	var clave := "%d_%s" % [peso, tabular]
	if _rubik_cache.has(clave):
		return _rubik_cache[clave]
	var ts := TextServerManager.get_primary_interface()
	var fv := FontVariation.new()
	fv.base_font = load(RUTA_RUBIK)
	fv.variation_opentype = {ts.name_to_tag("wght"): peso}
	if tabular:
		fv.opentype_features = {ts.name_to_tag("tnum"): 1}
	var emoji := _emoji()
	# Fallback: la fuente de emoji y, detrás, la fuente por defecto (que es
	# la que hoy dibuja ♥ y otros símbolos).
	var fbs : Array[Font] = []
	if emoji:
		fbs.append(emoji)
	if ThemeDB.fallback_font:
		fbs.append(ThemeDB.fallback_font)
	fv.fallbacks = fbs
	_rubik_cache[clave] = fv
	return fv


static func pixel() -> Font:
	if _pixel == null:
		_pixel = load(RUTA_PIXEL) as Font
	return _pixel


static func label(texto: String, tam: int, color: Color, peso: int = 400, es_pixel: bool = false, tabular: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", pixel() if es_pixel else rubik(peso, tabular))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l
```
Nota: si Godot rechaza `Color("#…")` en un `const`, reemplazar cada uno por `Color(r, g, b)` con los mismos hex divididos por 255 (el test verifica los valores).
Nota: si la prueba de emoji falla para algún carácter, no agregarlo al HUD: reemplazarlo en `EMOJIS_HUD` y en su uso por otro que sí esté (no regenerar el recorte en este plan) y anotarlo en el informe.

`scenes/ui/hud_barra.gd`:
```gdscript
# Barra de progreso plana: track negro al 50 % + relleno redondeado.
# El relleno se anima con anchor_right (tween 0,3 s ease_out), sin redibujar
# por frame.
extends Panel

const TEMA := preload("res://scenes/ui/hud_tema.gd")

var fraccion : float = 0.0
var _fill : Panel = null
var _tween : Tween = null


func configurar(color: Color, alto: int) -> void:
	custom_minimum_size.y = alto
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", TEMA.caja(TEMA.TRACK, Color.TRANSPARENT, 0, alto / 2))
	_fill = Panel.new()
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill.add_theme_stylebox_override("panel", TEMA.caja(color, Color.TRANSPARENT, 0, alto / 2))
	_fill.anchor_top = 0.0
	_fill.anchor_bottom = 1.0
	_fill.anchor_left = 0.0
	_fill.anchor_right = 0.0
	add_child(_fill)


func set_fraccion(f: float, animar: bool = true) -> void:
	fraccion = clampf(f, 0.0, 1.0)
	if _fill == null:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	if animar and is_inside_tree():
		_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_tween.tween_property(_fill, "anchor_right", fraccion, 0.3)
	else:
		_fill.anchor_right = fraccion
```

- [ ] **Step 4: Run tests**

Run: `test_hud_tema.tscn` → `0 fallos`, exit=0; `test_compila.tscn` → exit=0.

- [ ] **Step 5: Commit**

```bash
git add assets/fonts/Rubik-VariableFont_wght.ttf assets/fonts/Rubik-VariableFont_wght.ttf.import assets/fonts/OFL-Rubik.txt scenes/ui/hud_tema.gd scenes/ui/hud_tema.gd.uid scenes/ui/hud_barra.gd scenes/ui/hud_barra.gd.uid tests/test_hud_tema.gd tests/test_hud_tema.gd.uid tests/test_hud_tema.tscn
git commit -m "hud: tema plano 2b, fuente Rubik y barra reutilizable"
```

---

### Task 4: Ficha del jugador y panel GreenMetric

**Files:**
- Create: `scenes/ui/hud_ficha_jugador.gd`, `scenes/ui/hud_panel_greenmetric.gd`
- Test: `tests/test_hud_paneles.gd`, `tests/test_hud_paneles.tscn`

**Interfaces:**
- Consumes: `TEMA.*`, `BARRA` (Task 3); `RANGOS.nombre/siguiente` (Task 1).
- Produces:
  - `hud_ficha_jugador.gd` (`PanelContainer`, pos 16,16, ancho 268):
    - `set_energia(actual: int, maximo: int) -> void`
    - `set_nivel_misiones(nivel: int, hechos: Array) -> void` (hechos: 6 bool, nivel 1..6)
    - `set_rango(niveles_completos: int, fraccion: float, xp: int) -> void`
    - `set_creditos(ec: int) -> void`
    - `set_indices(fracciones: Dictionary) -> void` (claves int 1, 4, 6 → 0..1)
    - vars públicas para pruebas: `nivel_lbl, rango_lbl, creditos_lbl, hacia_lbl, xp_lbl: Label`, `corazones: Array[Label]`, `pasos: Array[Panel]`, `barra_xp`, `indices: Dictionary` (cat → `{"barra", "pct": Label}`)
  - `hud_panel_greenmetric.gd` (`PanelContainer` anclado arriba-derecha, ancho 268):
    - `actualizar(categorias: Dictionary, total: float) -> void` (formato de `PuntajeManager.categorias`: `{int: {"avance","comprension","decisiones","sinergias","total"}}`)
    - `texto_falta(datos: Dictionary) -> String`
    - vars para pruebas: `total_lbl: Label`, `barra_total`, `filas: Dictionary` (cat → `{"pct": Label, "tramos": Array[Panel]}`), `popover: PanelContainer`
    - `mostrar_popover(cat: int) -> void`, `ocultar_popover() -> void`

- [ ] **Step 1: Write the failing test**

`tests/test_hud_paneles.tscn` (node `TestHudPaneles`, script `res://tests/test_hud_paneles.gd`).

`tests/test_hud_paneles.gd`:
```gdscript
# Prueba de la ficha del jugador y del panel GreenMetric con datos fijos.
# Correr: $GODOT --headless --path . res://tests/test_hud_paneles.tscn
extends Node

const FICHA := preload("res://scenes/ui/hud_ficha_jugador.gd")
const PANEL_GM := preload("res://scenes/ui/hud_panel_greenmetric.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_hud_paneles")
	var f = FICHA.new()
	add_child(f)
	f.set_energia(2, 3)
	_check(f.corazones.size() == 3, "3 corazones")
	_check(f.corazones[2].get_theme_color("font_color").is_equal_approx(Color("#3A4550")), "corazón vacío gris")
	f.set_nivel_misiones(6, [true, true, true, true, false, false])
	_check(f.nivel_lbl.text == "Nivel 6/6 · Educación", "nivel de misiones: %s" % f.nivel_lbl.text)
	_check(f.pasos.size() == 6, "6 pasos")
	f.set_rango(2, 0.45, 1578)
	_check(f.rango_lbl.text == "Árbol", "rango Árbol con 2 niveles")
	_check(f.hacia_lbl.text == "Hacia Estratega", "texto hacia: %s" % f.hacia_lbl.text)
	_check(f.xp_lbl.text == "1578 XP", "xp: %s" % f.xp_lbl.text)
	f.set_rango(6, 1.0, 2800)
	_check(f.hacia_lbl.text == "Rango máximo", "EcoLíder: rango máximo")
	f.set_creditos(319)
	_check(f.creditos_lbl.text == "💰 319 EC", "créditos")
	f.set_indices({1: 0.62, 4: 0.3, 6: 1.0})
	_check(f.indices[1]["pct"].text == "62%", "índice verde 62%")
	_check(f.indices[6]["pct"].text == "100%", "índice educación 100%")

	var gm = PANEL_GM.new()
	add_child(gm)
	var cats := {}
	for c in range(1, 7):
		cats[c] = {"avance": 0.0, "comprension": 0.0, "decisiones": 0.0, "sinergias": 0.0, "total": 0.0}
	cats[1] = {"avance": 40.0, "comprension": 10.0, "decisiones": 5.0, "sinergias": 0.0, "total": 55.0}
	gm.actualizar(cats, 66.4)
	_check(gm.total_lbl.text == "66", "total campus redondeado: %s" % gm.total_lbl.text)
	_check(gm.filas[1]["pct"].text == "55%", "Entorno 55%")
	var tramos : Array = gm.filas[1]["tramos"]
	_check(tramos.size() == 4, "4 tramos")
	_check(is_equal_approx(tramos[0].size_flags_stretch_ratio, 80.0) and is_equal_approx(tramos[3].size_flags_stretch_ratio, 5.0), "stretch 80/10/5/5")
	_check(is_equal_approx(tramos[0].get_child(0).anchor_right, 0.5), "tramo misiones a 50%")
	_check(is_equal_approx(tramos[1].get_child(0).anchor_right, 1.0), "tramo quiz lleno")
	_check(gm.texto_falta(cats[1]) == "Falta: completar las misiones del nivel", "falta: %s" % gm.texto_falta(cats[1]))
	_check(gm.texto_falta({"avance": 80.0, "comprension": 10.0, "decisiones": 5.0, "sinergias": 5.0}) == "¡Categoría completa!", "completa")
	gm.mostrar_popover(1)
	_check(gm.popover.visible, "popover visible al pasar el mouse")
	gm.ocultar_popover()
	_check(not gm.popover.visible, "popover se oculta")

	print("test_hud_paneles: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```
Run → Expected: error de carga, exit≠0.

- [ ] **Step 2: Implementar la ficha**

`scenes/ui/hud_ficha_jugador.gd`:
```gdscript
# ============================================================
# hud_ficha_jugador.gd — ficha arriba a la izquierda (spec 2b §1):
# nombre y vidas, nivel de misiones con 6 pasos, rango + EcoCredits,
# barra hacia el siguiente rango e índices del campus DENTRO del panel.
# Solo muestra lo que le pasan; no lee autoloads.
# ============================================================
extends PanelContainer

const TEMA   := preload("res://scenes/ui/hud_tema.gd")
const BARRA  := preload("res://scenes/ui/hud_barra.gd")
const RANGOS := preload("res://autoload/rangos.gd")

const INDICES : Array = [
	{"cat": 1, "icono": "🌿", "nombre": "Verde"},
	{"cat": 4, "icono": "💧", "nombre": "Agua"},
	{"cat": 6, "icono": "📚", "nombre": "Educación"},
]

var corazones    : Array[Label] = []
var pasos        : Array[Panel] = []
var nivel_lbl    : Label
var rango_lbl    : Label
var creditos_lbl : Label
var hacia_lbl    : Label
var xp_lbl       : Label
var barra_xp
var indices      : Dictionary = {}


func _init() -> void:
	position = Vector2(16, 16)
	custom_minimum_size = Vector2(268, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", TEMA.panel(TEMA.VERDE))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)

	# Fila 1: nombre + vidas
	var f1 := _hbox(6)
	f1.add_child(TEMA.label("🌿", 14, TEMA.TEXTO))
	var nom := TEMA.label("Eco-Ranger", 11, TEMA.TEXTO, 400, true)
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f1.add_child(nom)
	var vidas := _hbox(2)
	for i in 3:
		var c := TEMA.label("♥", 12, TEMA.VIDAS)
		corazones.append(c)
		vidas.add_child(c)
	f1.add_child(vidas)
	vb.add_child(f1)

	# Fila 2: nivel de misiones
	var caja := PanelContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_theme_stylebox_override("panel", TEMA.caja(Color(TEMA.TEAL, 0.12), Color(TEMA.TEAL, 0.45), 1, 8, 8, 5))
	var f2 := _hbox(8)
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 0)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.add_child(TEMA.label("NIVEL DE MISIONES", 9, TEMA.APAGADO))
	nivel_lbl = TEMA.label("Nivel 1/6 · Entorno", 12, TEMA.TEXTO, 600)
	textos.add_child(nivel_lbl)
	f2.add_child(textos)
	var hp := _hbox(2)
	hp.alignment = BoxContainer.ALIGNMENT_END
	hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in 6:
		var p := Panel.new()
		p.custom_minimum_size = Vector2(4, 12)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_theme_stylebox_override("panel", TEMA.caja(TEMA.PASO_PENDIENTE, Color.TRANSPARENT, 0, 1))
		pasos.append(p)
		hp.add_child(p)
	f2.add_child(hp)
	caja.add_child(f2)
	vb.add_child(caja)

	# Fila 3: rango + EcoCredits
	var f3 := _hbox(4)
	f3.add_child(TEMA.label("⭐", 12, TEMA.DORADO))
	f3.add_child(TEMA.label("RANGO", 9, TEMA.APAGADO))
	rango_lbl = TEMA.label("Semilla", 12, TEMA.DORADO, 600)
	rango_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f3.add_child(rango_lbl)
	creditos_lbl = TEMA.label("💰 0 EC", 13, TEMA.DORADO, 600, false, true)
	f3.add_child(creditos_lbl)
	vb.add_child(f3)

	# Barra hacia el siguiente rango
	var bloque_xp := VBoxContainer.new()
	bloque_xp.add_theme_constant_override("separation", 4)
	bloque_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_xp = BARRA.new()
	barra_xp.configurar(TEMA.CIAN, 10)
	bloque_xp.add_child(barra_xp)
	var fx := _hbox(4)
	hacia_lbl = TEMA.label("Hacia Brote", 10, TEMA.TEXTO_3)
	hacia_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fx.add_child(hacia_lbl)
	xp_lbl = TEMA.label("0 XP", 10, TEMA.TEXTO_3, 400, false, true)
	fx.add_child(xp_lbl)
	bloque_xp.add_child(fx)
	vb.add_child(bloque_xp)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = TEMA.SEPARADOR
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(sep)

	# Índices del campus
	var bloque_ind := VBoxContainer.new()
	bloque_ind.add_theme_constant_override("separation", 6)
	bloque_ind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloque_ind.add_child(TEMA.label("ÍNDICES DEL CAMPUS", 10, TEMA.APAGADO))
	for d in INDICES:
		var cat : int = d["cat"]
		var fila := _hbox(6)
		fila.custom_minimum_size.y = 14
		var ic := TEMA.label(d["icono"], 14, TEMA.TEXTO)
		ic.custom_minimum_size.x = 18
		fila.add_child(ic)
		var nl := TEMA.label(d["nombre"], 11, TEMA.TEXTO_2)
		nl.custom_minimum_size.x = 64
		fila.add_child(nl)
		var b = BARRA.new()
		b.configurar(TEMA.CATEGORIAS[cat]["color"], 6)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(b)
		var pct := TEMA.label("0%", 11, TEMA.TEXTO, 600, false, true)
		pct.custom_minimum_size.x = 32
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(pct)
		bloque_ind.add_child(fila)
		indices[cat] = {"barra": b, "pct": pct}
	vb.add_child(bloque_ind)


func _hbox(sep: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


func set_energia(actual: int, maximo: int) -> void:
	for i in corazones.size():
		corazones[i].visible = i < maximo
		corazones[i].add_theme_color_override("font_color", TEMA.VIDAS if i < actual else TEMA.VACIO)


func set_nivel_misiones(nivel: int, hechos: Array) -> void:
	var n := clampi(nivel, 1, 6)
	nivel_lbl.text = "Nivel %d/6 · %s" % [n, TEMA.CATEGORIAS[n]["nombre"]]
	for i in pasos.size():
		var hecho : bool = i < hechos.size() and bool(hechos[i])
		pasos[i].add_theme_stylebox_override("panel",
			TEMA.caja(TEMA.TEAL if hecho else TEMA.PASO_PENDIENTE, Color.TRANSPARENT, 0, 1))


func set_rango(niveles_completos: int, fraccion: float, xp: int) -> void:
	rango_lbl.text = RANGOS.nombre(niveles_completos)
	var sig := RANGOS.siguiente(niveles_completos)
	hacia_lbl.text = "Rango máximo" if sig == "" else "Hacia " + sig
	barra_xp.set_fraccion(1.0 if sig == "" else fraccion)
	xp_lbl.text = "%d XP" % xp


func set_creditos(ec: int) -> void:
	creditos_lbl.text = "💰 %d EC" % ec


func set_indices(fracciones: Dictionary) -> void:
	for cat in indices.keys():
		var f := clampf(float(fracciones.get(cat, 0.0)), 0.0, 1.0)
		indices[cat]["barra"].set_fraccion(f)
		indices[cat]["pct"].text = "%d%%" % roundi(f * 100.0)
```

- [ ] **Step 3: Implementar el panel GreenMetric**

`scenes/ui/hud_panel_greenmetric.gd`:
```gdscript
# ============================================================
# hud_panel_greenmetric.gd — panel arriba a la derecha (spec 2b §2):
# puntaje del campus (0–100), una fila por categoría con barra partida
# 80/10/5/5 (misiones · quiz · decisiones · sinergias) y un popover con
# el desglose al pasar el mouse.
# ============================================================
extends PanelContainer

const TEMA  := preload("res://scenes/ui/hud_tema.gd")
const BARRA := preload("res://scenes/ui/hud_barra.gd")

const COMPONENTES : Array = [
	{"clave": "avance",      "nombre": "Misiones",   "tope": 80.0, "alpha": 1.00, "corto": "Misión 80"},
	{"clave": "comprension", "nombre": "Quiz",       "tope": 10.0, "alpha": 0.78, "corto": "Quiz 10"},
	{"clave": "decisiones",  "nombre": "Decisiones", "tope": 5.0,  "alpha": 0.58, "corto": "Decis. 5"},
	{"clave": "sinergias",   "nombre": "Sinergias",  "tope": 5.0,  "alpha": 0.40, "corto": "Sinerg. 5"},
]
const FALTA : Dictionary = {
	"avance":      "completar las misiones del nivel",
	"comprension": "responder el quiz al primer intento",
	"decisiones":  "tomar buenas decisiones del nivel",
	"sinergias":   "acciones de otros niveles que suman acá",
}

var total_lbl  : Label
var barra_total
var filas      : Dictionary = {}
var popover    : PanelContainer
var _pop_vb    : VBoxContainer
var _datos     : Dictionary = {}


func _init() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -284
	offset_right = -16
	offset_top = 16
	custom_minimum_size = Vector2(268, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", TEMA.panel(TEMA.CIAN))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)

	var tit := _hbox(6)
	var t := TEMA.label("GreenMetric", 10, TEMA.CIAN, 400, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.add_child(t)
	tit.add_child(TEMA.label("0–100", 10, TEMA.APAGADO))
	vb.add_child(tit)

	var caja := PanelContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_theme_stylebox_override("panel", TEMA.caja(Color(TEMA.CIAN, 0.12), Color(TEMA.CIAN, 0.45), 1, 8, 9, 7))
	var hc := _hbox(10)
	total_lbl = TEMA.label("0", 16, TEMA.TEXTO, 400, true)
	total_lbl.custom_minimum_size.x = 52
	hc.add_child(total_lbl)
	barra_total = BARRA.new()
	barra_total.configurar(TEMA.CIAN, 8)
	barra_total.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra_total.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hc.add_child(barra_total)
	caja.add_child(hc)
	vb.add_child(caja)

	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 0)
	lista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for cat in range(1, 7):
		lista.add_child(_crear_fila(cat))
	vb.add_child(lista)

	var ley := VBoxContainer.new()
	ley.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ley.add_theme_constant_override("separation", 7)
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = TEMA.SEPARADOR
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ley.add_child(sep)
	var chips := _hbox(8)
	for comp in COMPONENTES:
		var h := _hbox(3)
		var chip := Panel.new()
		chip.custom_minimum_size = Vector2(7, 7)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", TEMA.caja(Color(TEMA.LEYENDA, comp["alpha"]), Color.TRANSPARENT, 0, 2))
		h.add_child(chip)
		h.add_child(TEMA.label(comp["corto"], 9, TEMA.TEXTO_3))
		chips.add_child(h)
	ley.add_child(chips)
	vb.add_child(ley)

	popover = PanelContainer.new()
	popover.top_level = true
	popover.visible = false
	popover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.custom_minimum_size = Vector2(186, 0)
	var ps := TEMA.caja(TEMA.POPOVER_BG, TEMA.CIAN, 2, 10, 10, 9)
	popover.add_theme_stylebox_override("panel", ps)
	_pop_vb = VBoxContainer.new()
	_pop_vb.add_theme_constant_override("separation", 4)
	_pop_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.add_child(_pop_vb)
	add_child(popover)


func _hbox(sep: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


func _crear_fila(cat: int) -> Control:
	var info : Dictionary = TEMA.CATEGORIAS[cat]
	var col : Color = info["color"]
	var fila := VBoxContainer.new()
	fila.custom_minimum_size.y = 34
	fila.add_theme_constant_override("separation", 3)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.mouse_filter = Control.MOUSE_FILTER_STOP
	fila.mouse_entered.connect(mostrar_popover.bind(cat))
	fila.mouse_exited.connect(ocultar_popover)

	var lab := _hbox(6)
	lab.custom_minimum_size.y = 17
	var ic := TEMA.label(info["icono"], 14, TEMA.TEXTO)
	ic.custom_minimum_size.x = 14
	lab.add_child(ic)
	var nom := TEMA.label(info["nombre"], 12, TEMA.TEXTO)
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.add_child(nom)
	var pct := TEMA.label("0%", 11, TEMA.TEXTO_2, 600, false, true)
	lab.add_child(pct)
	fila.add_child(lab)

	var mg := MarginContainer.new()
	mg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mg.add_theme_constant_override("margin_left", 20)
	var hb := _hbox(2)
	hb.custom_minimum_size.y = 7
	var tramos : Array[Panel] = []
	for i in COMPONENTES.size():
		var comp : Dictionary = COMPONENTES[i]
		var tramo := Panel.new()
		tramo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tramo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tramo.size_flags_stretch_ratio = comp["tope"]
		var st := TEMA.caja(TEMA.TRACK, Color.TRANSPARENT, 0, 0)
		var sf := TEMA.caja(Color(col, comp["alpha"]), Color.TRANSPARENT, 0, 0)
		if i == 0:
			for s in [st, sf]:
				s.corner_radius_top_left = 3
				s.corner_radius_bottom_left = 3
		if i == COMPONENTES.size() - 1:
			for s in [st, sf]:
				s.corner_radius_top_right = 3
				s.corner_radius_bottom_right = 3
		tramo.add_theme_stylebox_override("panel", st)
		var fill := Panel.new()
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.add_theme_stylebox_override("panel", sf)
		fill.anchor_bottom = 1.0
		fill.anchor_right = 0.0
		tramo.add_child(fill)
		tramos.append(tramo)
		hb.add_child(tramo)
	mg.add_child(hb)
	fila.add_child(mg)
	filas[cat] = {"pct": pct, "tramos": tramos, "nodo": fila}
	return fila


func actualizar(categorias: Dictionary, total: float) -> void:
	_datos = categorias
	total_lbl.text = str(roundi(total))
	barra_total.set_fraccion(total / 100.0)
	for cat in filas.keys():
		var d : Dictionary = categorias.get(cat, {})
		filas[cat]["pct"].text = "%d%%" % roundi(float(d.get("total", 0.0)))
		var tramos : Array = filas[cat]["tramos"]
		for i in COMPONENTES.size():
			var comp : Dictionary = COMPONENTES[i]
			var f := clampf(float(d.get(comp["clave"], 0.0)) / comp["tope"], 0.0, 1.0)
			tramos[i].get_child(0).anchor_right = f


func texto_falta(datos: Dictionary) -> String:
	var peor := ""
	var hueco := 0.0
	for comp in COMPONENTES:
		var h : float = comp["tope"] - float(datos.get(comp["clave"], 0.0))
		if h > hueco + 0.001:
			hueco = h
			peor = comp["clave"]
	return "¡Categoría completa!" if peor == "" else "Falta: " + FALTA[peor]


func mostrar_popover(cat: int) -> void:
	for c in _pop_vb.get_children():
		c.queue_free()
	var info : Dictionary = TEMA.CATEGORIAS[cat]
	var d : Dictionary = _datos.get(cat, {})
	_pop_vb.add_child(TEMA.label("%s %s · %d/100" % [info["icono"], info["nombre"], roundi(float(d.get("total", 0.0)))], 11, TEMA.TEXTO, 600))
	for comp in COMPONENTES:
		var h := _hbox(6)
		var chip := Panel.new()
		chip.custom_minimum_size = Vector2(8, 8)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", TEMA.caja(Color(info["color"], comp["alpha"]), Color.TRANSPARENT, 0, 2))
		h.add_child(chip)
		var n := TEMA.label(comp["nombre"], 10, TEMA.TEXTO_2)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		h.add_child(TEMA.label("%d/%d" % [roundi(float(d.get(comp["clave"], 0.0))), int(comp["tope"])], 10, TEMA.TEXTO, 400, false, true))
		_pop_vb.add_child(h)
	var falta := TEMA.label(texto_falta(d), 10, TEMA.DORADO)
	falta.autowrap_mode = TextServer.AUTOWRAP_WORD
	falta.custom_minimum_size.x = 164
	_pop_vb.add_child(falta)
	popover.reset_size()
	var fila : Control = filas[cat]["nodo"]
	if is_inside_tree():
		popover.global_position = Vector2(global_position.x - 186 - 10, fila.global_position.y - 6)
	popover.visible = true


func ocultar_popover() -> void:
	popover.visible = false
```

- [ ] **Step 4: Run tests**

Run: `test_hud_paneles.tscn` → `0 fallos`, exit=0; `test_hud_tema.tscn` y `test_rangos.tscn` → exit=0.

- [ ] **Step 5: Commit**

```bash
git add scenes/ui/hud_ficha_jugador.gd scenes/ui/hud_ficha_jugador.gd.uid scenes/ui/hud_panel_greenmetric.gd scenes/ui/hud_panel_greenmetric.gd.uid tests/test_hud_paneles.gd tests/test_hud_paneles.gd.uid tests/test_hud_paneles.tscn
git commit -m "hud: ficha del jugador y panel GreenMetric planos"
```

---

### Task 5: Barra de acciones, banner de zona y aviso central

**Files:**
- Create: `scenes/ui/hud_acciones.gd`, `scenes/ui/hud_banner_zona.gd`, `scenes/ui/hud_aviso.gd`
- Test: `tests/test_hud_controles.gd`, `tests/test_hud_controles.tscn`

**Interfaces:**
- Consumes: `TEMA.*` (Task 3).
- Produces:
  - `hud_acciones.gd` (`HBoxContainer` abajo-izquierda): `signal accion(indice: int)` (0 calor, 1 reporte, 2 ranking, 3 simulador, 4 tienda); `tecla(keycode: int) -> bool` (KEY_1..KEY_5 → emite y devuelve true); var `botones: Array[Button]`.
  - `hud_banner_zona.gd` (`PanelContainer` abajo-centro): `mostrar(icono: String, titulo: String, subtitulo: String, color: Color) -> void`, `ocultar() -> void`; vars `titulo_lbl, subtitulo_lbl: Label`, `activo: bool`.
  - `hud_aviso.gd` (`PanelContainer` arriba-centro): `avisar(texto: String, bloqueo: bool = false, deltas: Array = []) -> void` (deltas: `[{"texto": String, "color": Color}]`); cola máx. 2 pendientes; vars `texto_lbl: Label`, `cola: Array`, `mostrando: bool`.

- [ ] **Step 1: Write the failing test**

`tests/test_hud_controles.tscn` (node `TestHudControles`, script `res://tests/test_hud_controles.gd`).

`tests/test_hud_controles.gd`:
```gdscript
# Prueba de la barra de acciones, el banner de zona y el aviso central.
# Correr: $GODOT --headless --path . res://tests/test_hud_controles.tscn
extends Node

const ACCIONES := preload("res://scenes/ui/hud_acciones.gd")
const BANNER   := preload("res://scenes/ui/hud_banner_zona.gd")
const AVISO    := preload("res://scenes/ui/hud_aviso.gd")

var _fallos := 0
var _recibidas : Array = []


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_hud_controles")
	var a = ACCIONES.new()
	add_child(a)
	a.accion.connect(func(i): _recibidas.append(i))
	_check(a.botones.size() == 5, "5 botones")
	_check(a.botones[0].custom_minimum_size == Vector2(56, 59), "botón 56×59")
	_check(a.tecla(KEY_3), "tecla 3 se maneja")
	_check(not a.tecla(KEY_7), "tecla 7 no se maneja")
	a.botones[4].pressed.emit()
	_check(_recibidas == [2, 4], "acciones emitidas: %s" % [_recibidas])

	var b = BANNER.new()
	add_child(b)
	_check(not b.visible, "banner oculto al inicio")
	b.mostrar("🌿", "Plaza Central", "Nivel 1 · Entorno", Color("#62D06A"))
	_check(b.visible and b.activo, "banner visible al entrar")
	_check(b.titulo_lbl.text == "Plaza Central", "banner título")
	b.ocultar()
	_check(not b.activo, "banner inactivo al salir")

	var v = AVISO.new()
	add_child(v)
	v.avisar("a")
	v.avisar("b")
	v.avisar("c")
	v.avisar("d")
	_check(v.mostrando and v.texto_lbl.text == "a", "muestra el primero")
	_check(v.cola.size() == 2, "cola máx. 2")
	_check(v.cola[0]["texto"] == "c" and v.cola[1]["texto"] == "d", "descarta el más viejo pendiente")
	v.avisar("x", true)
	_check(v.cola[1]["bloqueo"] == true, "aviso de bloqueo encolado")

	print("test_hud_controles: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```
Run → Expected: error de carga, exit≠0.

- [ ] **Step 2: Implementar las acciones**

`scenes/ui/hud_acciones.gd`:
```gdscript
# ============================================================
# hud_acciones.gd — 5 botones abajo a la izquierda (spec 2b §3), con
# atajo de teclado 1–5. Emite `accion(indice)`; quien lo crea decide
# qué abrir.
# ============================================================
extends HBoxContainer

const TEMA := preload("res://scenes/ui/hud_tema.gd")

signal accion(indice: int)

const DEFS : Array = [
	{"emoji": "🌡", "label": "Calor",   "tip": "Mapa de calor energético", "color": Color("#E5893E")},
	{"emoji": "📊", "label": "Reporte", "tip": "Reporte GreenMetric",      "color": Color("#3FBEDC")},
	{"emoji": "🏆", "label": "Ranking", "tip": "Tabla de clasificación",   "color": Color("#E8BE55")},
	{"emoji": "🔬", "label": "Simular", "tip": "Simulador de decisiones",  "color": Color("#9B77DF")},
	{"emoji": "🛒", "label": "Tienda",  "tip": "Tienda del Conocimiento",  "color": Color("#62D06A")},
]
const TECLAS : Array = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]

var botones : Array[Button] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = 16
	offset_right = 320
	offset_top = -75
	offset_bottom = -16
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in DEFS.size():
		botones.append(_crear_boton(i, DEFS[i]))


func _crear_boton(i: int, d: Dictionary) -> Button:
	var col : Color = d["color"]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(56, 59)
	btn.tooltip_text = "%s  [%d]" % [d["tip"], i + 1]
	btn.pivot_offset = Vector2(28, 29.5)
	btn.add_theme_stylebox_override("normal", TEMA.caja(TEMA.PANEL_BG, col, 2, 10))
	btn.add_theme_stylebox_override("hover", TEMA.caja(Color(col, 0.18), col, 2, 10))
	btn.add_theme_stylebox_override("pressed", TEMA.caja(Color(col, 0.18), col, 2, 10))
	var foco := TEMA.caja(Color.TRANSPARENT, TEMA.TEXTO, 2, 10)
	foco.draw_center = false
	btn.add_theme_stylebox_override("focus", foco)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 3)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for l in [TEMA.label(d["emoji"], 19, TEMA.TEXTO), TEMA.label(d["label"], 9, TEMA.TEXTO, 600), TEMA.label(str(i + 1), 8, TEMA.TEXTO_3)]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(l)
	btn.add_child(vb)

	btn.button_down.connect(func(): _escalar(btn, 0.96))
	btn.button_up.connect(func(): _escalar(btn, 1.0))
	btn.pressed.connect(func(): accion.emit(i))
	add_child(btn)
	return btn


func _escalar(btn: Button, s: float) -> void:
	if btn.is_inside_tree():
		btn.create_tween().tween_property(btn, "scale", Vector2(s, s), 0.08)


func tecla(keycode: int) -> bool:
	var i := TECLAS.find(keycode)
	if i < 0:
		return false
	accion.emit(i)
	return true
```

- [ ] **Step 3: Implementar el banner**

`scenes/ui/hud_banner_zona.gd`:
```gdscript
# ============================================================
# hud_banner_zona.gd — banner de zona abajo al centro (spec 2b §4).
# Queda visible mientras el jugador está en la zona (la pista
# «E · interactuar» tiene que verse); entra en 0,18 s y sale en 0,25 s.
# ============================================================
extends PanelContainer

const TEMA := preload("res://scenes/ui/hud_tema.gd")

const TOP := -67.0
const BOTTOM := -16.0

var titulo_lbl    : Label
var subtitulo_lbl : Label
var activo        : bool = false
var _icono_lbl    : Label
var _tween        : Tween = null


func _init() -> void:
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -210
	offset_right = 210
	offset_top = TOP
	offset_bottom = BOTTOM
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	add_theme_stylebox_override("panel", TEMA.caja(TEMA.PANEL_BG, TEMA.VERDE, 2, 12, 12, 6))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icono_lbl = TEMA.label("🌍", 20, TEMA.TEXTO)
	hb.add_child(_icono_lbl)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulo_lbl = TEMA.label("", 11, TEMA.TEXTO, 400, true)
	titulo_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titulo_lbl.clip_text = true
	vb.add_child(titulo_lbl)
	subtitulo_lbl = TEMA.label("", 11, TEMA.VERDE)
	vb.add_child(subtitulo_lbl)
	hb.add_child(vb)
	var hint := TEMA.label("E · interactuar", 10, TEMA.APAGADO)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(hint)
	add_child(hb)


func mostrar(icono: String, titulo: String, subtitulo: String, color: Color) -> void:
	activo = true
	_icono_lbl.text = icono
	titulo_lbl.text = titulo
	subtitulo_lbl.text = subtitulo
	subtitulo_lbl.add_theme_color_override("font_color", color)
	add_theme_stylebox_override("panel", TEMA.caja(TEMA.PANEL_BG, color, 2, 12, 12, 6))
	visible = true
	_matar_tween()
	if not is_inside_tree():
		return
	modulate.a = 0.0
	offset_top = TOP + 12
	offset_bottom = BOTTOM + 12
	_tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_tween.tween_property(self, "offset_top", TOP, 0.18)
	_tween.tween_property(self, "offset_bottom", BOTTOM, 0.18)


func ocultar() -> void:
	activo = false
	_matar_tween()
	if not is_inside_tree():
		visible = false
		return
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	_tween.tween_callback(func(): if not activo: visible = false)


func _matar_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	offset_top = TOP
	offset_bottom = BOTTOM
	modulate.a = 1.0
```

- [ ] **Step 4: Implementar el aviso**

`scenes/ui/hud_aviso.gd`:
```gdscript
# ============================================================
# hud_aviso.gd — aviso central arriba (spec 2b §5). Un aviso a la vez:
# entra 0,15 s, se ve 2 s, sale 0,2 s. Hasta 2 pendientes; si llega un
# tercero se descarta el pendiente más viejo (antes cada aviso pisaba al
# anterior y los de sinergia se perdían).
# ============================================================
extends PanelContainer

const TEMA := preload("res://scenes/ui/hud_tema.gd")
const MAX_COLA := 2
const TOP := 20.0

var texto_lbl : Label
var cola      : Array = []
var mostrando : bool = false
var _deltas   : HBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_top = TOP
	custom_minimum_size = Vector2(0, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	visible = false
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto_lbl = TEMA.label("", 13, TEMA.TEXTO, 600)
	texto_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(texto_lbl)
	_deltas = HBoxContainer.new()
	_deltas.add_theme_constant_override("separation", 8)
	_deltas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_deltas)
	add_child(hb)


func avisar(texto: String, bloqueo: bool = false, deltas: Array = []) -> void:
	var item := {"texto": texto, "bloqueo": bloqueo, "deltas": deltas}
	if not mostrando:
		_mostrar(item)
		return
	if cola.size() >= MAX_COLA:
		cola.pop_front()
	cola.append(item)


func _mostrar(item: Dictionary) -> void:
	mostrando = true
	texto_lbl.text = item["texto"]
	for c in _deltas.get_children():
		c.queue_free()
	for d in item["deltas"]:
		_deltas.add_child(TEMA.label(str(d.get("texto", "")), 13, d.get("color", TEMA.TEXTO), 600))
	add_theme_stylebox_override("panel",
		TEMA.caja(TEMA.PANEL_BG, TEMA.VIDAS if item["bloqueo"] else TEMA.DORADO, 2, 10, 14, 8))
	visible = true
	offset_left = 0
	offset_right = 0
	reset_size()
	if not is_inside_tree():
		return
	modulate.a = 0.0
	offset_top = TOP + 4
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	tw.tween_property(self, "offset_top", TOP, 0.15)
	tw.chain().tween_interval(2.0)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(_siguiente)


func _siguiente() -> void:
	mostrando = false
	visible = false
	if not cola.is_empty():
		_mostrar(cola.pop_front())
```

- [ ] **Step 5: Run tests**

Run: `test_hud_controles.tscn` → `0 fallos`, exit=0; `test_hud_paneles.tscn` → exit=0.

- [ ] **Step 6: Commit**

```bash
git add scenes/ui/hud_acciones.gd scenes/ui/hud_acciones.gd.uid scenes/ui/hud_banner_zona.gd scenes/ui/hud_banner_zona.gd.uid scenes/ui/hud_aviso.gd scenes/ui/hud_aviso.gd.uid tests/test_hud_controles.gd tests/test_hud_controles.gd.uid tests/test_hud_controles.tscn
git commit -m "hud: acciones con teclas 1-5, banner de zona y aviso con cola"
```

---

### Task 6: Integrar el HUD nuevo en SceneMapaMundo

**Files:**
- Modify: `scenes/mapa/SceneMapaMundo.gd` (ver líneas abajo; números aproximados, buscar por nombre)
- Modify: `tests/test_compila.gd`

**Interfaces:**
- Consumes: todo lo de las Tasks 1, 3, 4, 5. `PuntajeManager.categorias`, `PuntajeManager.total`, `PuntajeManager.fraccion(cat)`, `EconomiaManager.ecocredits`, `EconomiaManager.energia_actual`, `EconomiaManager.MAX_ENERGIA`, `NivelManager.nivel_actual`, `nivel_superado(n)`.
- Produces: HUD nuevo funcionando en el juego; ya no existen `NIVELES`, `_construir_sidebar`, `_actualizar_sidebar`, `_actualizar_indicador_verde/agua/edu`, `_crear_btn_mapa_calor`.

- [ ] **Step 1: Write the failing test**

En `tests/test_compila.gd` agregar (fuera del `if sm:`):
```gdscript
	var mapa : String = FileAccess.get_file_as_string("res://scenes/mapa/SceneMapaMundo.gd")
	_check(not mapa.contains("const NIVELES"), "SceneMapaMundo ya no tiene rangos por XP")
	_check(not mapa.contains("func _construir_sidebar"), "sidebar viejo eliminado")
	_check(not mapa.contains("func _actualizar_indicador_verde"), "índices viejos eliminados")
	_check(mapa.contains("hud_ficha_jugador.gd") and mapa.contains("hud_panel_greenmetric.gd")
		and mapa.contains("hud_acciones.gd") and mapa.contains("hud_banner_zona.gd")
		and mapa.contains("hud_aviso.gd"), "SceneMapaMundo usa los componentes del HUD")
	var escena = load("res://scenes/mapa/SceneMapaMundo.gd")
	_check(escena != null and escena.can_instantiate(), "SceneMapaMundo compila")
```
Run `test_compila.tscn` → Expected: FALLA en las primeras 4, exit=1.

- [ ] **Step 2: Constantes y variables**

- Borrar `const NIVELES : Array = [...]` (~línea 52) y su comentario de sección.
- Junto a los otros `preload` agregar:
```gdscript
const RANGOS         := preload("res://autoload/rangos.gd")
const HUD_TEMA       := preload("res://scenes/ui/hud_tema.gd")
const HUD_FICHA      := preload("res://scenes/ui/hud_ficha_jugador.gd")
const HUD_GREENMETRIC:= preload("res://scenes/ui/hud_panel_greenmetric.gd")
const HUD_ACCIONES   := preload("res://scenes/ui/hud_acciones.gd")
const HUD_BANNER     := preload("res://scenes/ui/hud_banner_zona.gd")
const HUD_AVISO      := preload("res://scenes/ui/hud_aviso.gd")
```
- Borrar las vars `_hud_nombre_lbl, _hud_nivel_lbl, _hud_barra_bg, _hud_barra_fill, _hud_xp_lbl, _zona_panel, _zona_icono_lbl, _zona_nombre_lbl, _zona_hint_lbl, _hud_verde_fill, _hud_verde_lbl, _hud_agua_fill, _hud_agua_lbl, _hud_edu_fill, _hud_edu_lbl, _sidebar_fills, _sidebar_pcts, _notif_zona_lbl, _hud_creditos_lbl, _hud_energia_lbl` y agregar:
```gdscript
var _hud_ficha    = null   # hud_ficha_jugador.gd
var _hud_gm       = null   # hud_panel_greenmetric.gd
var _hud_acciones = null   # hud_acciones.gd
var _hud_banner   = null   # hud_banner_zona.gd
var _hud_aviso    = null   # hud_aviso.gd
```
`SIDEBAR_MODULOS` se conserva solo si algo más lo usa (grep); si solo lo usaban el sidebar y `_on_zona_activada`, borrarlo y usar `HUD_TEMA.CATEGORIAS`.

- [ ] **Step 3: Construcción**

Reemplazar el cuerpo de `_construir_hud()` desde `var panel_top` hasta el final del bloque de índices (se conserva `_celebracion_lbl` tal cual) por:
```gdscript
	_hud_ficha = HUD_FICHA.new()
	_hud_canvas.add_child(_hud_ficha)
	_hud_gm = HUD_GREENMETRIC.new()
	_hud_canvas.add_child(_hud_gm)
	_hud_acciones = HUD_ACCIONES.new()
	_hud_acciones.accion.connect(_on_hud_accion)
	_hud_canvas.add_child(_hud_acciones)
	_hud_banner = HUD_BANNER.new()
	_hud_canvas.add_child(_hud_banner)
	_hud_aviso = HUD_AVISO.new()
	_hud_canvas.add_child(_hud_aviso)
```
En `_ready()` quitar la llamada a `_construir_sidebar()` y la de `_construir_notificacion_zona()` (si existe); borrar esas funciones, `_actualizar_sidebar`, `_actualizar_indicador_verde/agua/edu` y `_crear_btn_mapa_calor` (y su llamada en `_init_sistemas_eva`). En `_init_sistemas_eva` borrar la creación de `_hud_creditos_lbl` y `_hud_energia_lbl`.

Reemplazo de los botones:
```gdscript
# Barra de acciones del HUD (botones o teclas 1–5).
func _on_hud_accion(indice: int) -> void:
	match indice:
		0:
			if mapa_campus and mapa_campus.has_method("toggle_mapa_calor"):
				mapa_campus.toggle_mapa_calor()
			_sfx("zona")
		1: _abrir_resultados()
		2: _leaderboard_ui.mostrar()
		3: _abrir_simulador()
		4: _abrir_tienda()
```

- [ ] **Step 4: Actualización de datos**

`_actualizar_hud()` completo:
```gdscript
func _actualizar_hud() -> void:
	var nm = _nivel_mgr()
	var completos : int = RANGOS.niveles_superados(nm) if nm else 0
	_nivel_actual = RANGOS.indice(completos)
	if not _hud_ficha:
		return
	var hechos : Array = []
	for n in range(1, 7):
		hechos.append(nm.nivel_superado(n) if nm else false)
	_hud_ficha.set_nivel_misiones(nm.nivel_actual if nm else 1, hechos)
	_hud_ficha.set_rango(completos, RANGOS.fraccion_siguiente(nm) if nm else 0.0, _xp_total)
```
En `_aplicar_xp`: borrar `var nivel_antes := _nivel_actual` y el bloque `if _nivel_actual > nivel_antes: _mostrar_celebracion(...)`.

En `_on_nivel_greenmetric_completado(nivel)`, al principio:
```gdscript
	var rango_antes := _nivel_actual
	_actualizar_hud()
	if _nivel_actual > rango_antes and _hud_aviso:
		_hud_aviso.avisar("⭐ Nuevo rango: %s" % RANGOS.NOMBRES[_nivel_actual])
```
En `_mostrar_celebracion`, el texto pasa a `_celebracion_lbl.text = nombre_nivel` (quien llama ya arma el texto completo; hoy salía "¡NIVEL SUBIDO!" encima de "NIVEL 3 ¡COMPLETADO!").

`_refrescar_progreso` pasa a:
```gdscript
func _refrescar_progreso(_cats: Dictionary = {}, _total: float = 0.0) -> void:
	for mod_id in _progreso_modulos.keys():
		_progreso_modulos[mod_id] = PuntajeManager.fraccion(mod_id)
		if mapa_campus and mapa_campus.has_method("actualizar_modulo"):
			mapa_campus.actualizar_modulo(mod_id, _progreso_modulos[mod_id])
	if _hud_gm:
		_hud_gm.actualizar(PuntajeManager.categorias, PuntajeManager.total)
	if _hud_ficha:
		_hud_ficha.set_indices({1: PuntajeManager.fraccion(1), 4: PuntajeManager.fraccion(4), 6: PuntajeManager.fraccion(6)})
	_actualizar_hud()
```
Economía:
```gdscript
func _actualizar_hud_economia() -> void:
	if _hud_ficha:
		_hud_ficha.set_creditos(EconomiaManager.ecocredits)
		_hud_ficha.set_energia(EconomiaManager.energia_actual, EconomiaManager.MAX_ENERGIA)


func _on_creditos_cambiados(total: int) -> void:
	if _hud_ficha:
		_hud_ficha.set_creditos(total)


func _on_energia_cambiada(actual: int, maximo: int) -> void:
	if _hud_ficha:
		_hud_ficha.set_energia(actual, maximo)
```
Zona:
```gdscript
func _on_zona_activada(zona_key: String, modulo_id: int, nombre_modulo: String, _color: Color) -> void:
	_zona_activa   = zona_key
	_modulo_activo = modulo_id
	_nombre_activo = nombre_modulo
	var icono : String = ZONA_ICONOS.get(modulo_id, "🌍")
	var col : Color = _color
	var sub : String = ""
	if modulo_id >= 1 and modulo_id <= 6:
		col = HUD_TEMA.CATEGORIAS[modulo_id]["color"]
		sub = "Nivel %d · %s" % [modulo_id, HUD_TEMA.CATEGORIAS[modulo_id]["nombre"]]
	_hud_banner.mostrar(icono, nombre_modulo, sub, col)
	# Pista contextual: primera zona visitada
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_zona",
			"📍 Presiona [E] para aceptar la misión de esta zona del campus.")

func _on_zona_salida() -> void:
	_hud_banner.ocultar()
	_zona_activa        = ""
	_modulo_activo      = -1
	_nombre_activo      = ""
```
Aviso: el cuerpo de `_mostrar_notificacion_zona(icono, nombre, col)` pasa a (se conserva la firma; tiene ~12 llamadas):
```gdscript
func _mostrar_notificacion_zona(icono: String, nombre: String, _col: Color) -> void:
	if _hud_aviso:
		_hud_aviso.avisar("%s  %s" % [icono, nombre])
```
Revisar cada llamada: si el texto es un bloqueo (contiene "🔒", "bloque" o "requiere"), cambiarla por `_hud_aviso.avisar(texto, true)`. En `_on_sinergia_obtenida`, armar `deltas` con el color de cada categoría:
```gdscript
func _on_sinergia_obtenida(_accion_id: String, cats: Array) -> void:
	var deltas : Array = []
	for c in cats:
		if c is Dictionary:
			var cat : int = int(c.get("categoria", 0))
			# Una categoría fuera de rango desde el servidor no debe romper el aviso.
			if cat >= 1 and cat <= 6:
				deltas.append({"texto": "%s +%d" % [HUD_TEMA.CATEGORIAS[cat]["icono"], int(c.get("puntos", 0))],
							   "color": HUD_TEMA.CATEGORIAS[cat]["color"]})
	if _hud_aviso:
		_hud_aviso.avisar("✨ Sinergia", false, deltas)
```

- [ ] **Step 5: Teclas 1–5**

En `_input`, mover el filtro `if event.keycode != KEY_E: return` para que quede DESPUÉS de los chequeos de menú de pausa, diálogo/quiz/misión/minijuego, interior de bloque y reciclaje, y justo antes de ese filtro insertar:
```gdscript
	# Atajos de la barra de acciones (1–5), solo sin otra UI abierta.
	if _hud_acciones and _hud_acciones.tecla(event.keycode):
		get_viewport().set_input_as_handled()
		return
```
(El bloque "E cierra la escena de edificio" y lo que sigue quedan después del filtro de KEY_E, sin cambios.)

- [ ] **Step 6: Verificar**

- `grep -n "_hud_nombre_lbl\|_hud_nivel_lbl\|_hud_barra\|_hud_xp_lbl\|_hud_verde\|_hud_agua\|_hud_edu\|_zona_panel\|_zona_icono_lbl\|_zona_nombre_lbl\|_zona_hint_lbl\|_notif_zona_lbl\|_hud_creditos_lbl\|_hud_energia_lbl\|_sidebar_\|NIVELES\[" scenes/mapa/SceneMapaMundo.gd` → sin resultados.
- Correr las 7 pruebas: `test_compila`, `test_puntaje`, `test_niveles`, `test_rangos`, `test_hud_tema`, `test_hud_paneles`, `test_hud_controles` → todas exit=0.
- Abrir el juego sin headless unos segundos para detectar errores de script en el arranque del mapa: `timeout 40 "$GODOT" --path . res://scenes/mapa/SceneMapaMundo.tscn 2>&1 | grep -i "error\|script" | head -20` (buscar la ruta real de la escena con `ls scenes/mapa/*.tscn`). Sin sesión puede haber avisos de red; no debe haber `SCRIPT ERROR`.

- [ ] **Step 7: Commit**

```bash
git add scenes/mapa/SceneMapaMundo.gd tests/test_compila.gd
git commit -m "hud: SceneMapaMundo usa el HUD plano 2b, rangos por nivel y aviso con cola"
```

---

### Task 7: Captura de verificación y documentación

**Files:**
- Create: `tests/captura_hud.gd`, `tests/captura_hud.tscn`
- Modify: `docs/ESTADO_PROYECTO.md` (§3 arquitectura cliente, §4 backend, §8 pendientes, §9 brecha 4)
- Modify: `docs/diseno/hud_plano_2b.md` (estado "Implementado" + rulings de este plan)

**Interfaces:**
- Consumes: todos los componentes del HUD.

- [ ] **Step 1: Escena de captura**

`tests/captura_hud.tscn` (node `CapturaHud`, script `res://tests/captura_hud.gd`).

`tests/captura_hud.gd`:
```gdscript
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
	f.set_indices({1: 0.62, 4: 0.48, 6: 0.35})

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
```

- [ ] **Step 2: Tomar la captura y revisarla**

Run: `timeout 60 "$GODOT" --path . --resolution 1280x720 res://tests/captura_hud.tscn -- "<scratchpad>/captura_hud.png"` (el controlador pasa la ruta del scratchpad). Abrir el PNG con la herramienta Read y verificar contra la spec 2b:
- ficha arriba-izq. dentro de la safe area, índices DENTRO del panel, nada recortado;
- panel GreenMetric arriba-der., 6 filas con barras partidas visibles y popover a su izquierda sin salirse de la pantalla;
- 5 botones abajo-izq. con emoji, nombre y número;
- banner centrado abajo sin tapar los botones; aviso centrado arriba;
- acentos (Á, í, ó) y todos los emoji se ven (no cuadraditos).
Corregir lo que no cumpla en el componente correspondiente (commit aparte `hud: ajustes tras captura`), volver a correr las pruebas y la captura. Describir el resultado en el informe.

- [ ] **Step 3: Documentación**

- `docs/diseno/hud_plano_2b.md`: cambiar "**Pendiente de implementar**" por "**Implementado 2026-09-16** (plan `docs/superpowers/plans/2026-09-16-hud-plano-rangos-ranking.md`); falta prueba en el juego con cuenta real y re-export web." y agregar una sección "Desvíos respecto de la spec" con los 6 rulings de la cabecera de este plan.
- `docs/ESTADO_PROYECTO.md`:
  - §3: listar `autoload/rangos.gd` y los componentes `scenes/ui/hud_*.gd` (una línea cada uno) y cómo correr las pruebas nuevas + `captura_hud`.
  - §4: subsección corta "Ranking público" con qué devuelve `ranking_publico` y qué NO expone.
  - §8: marcar "PRÓXIMO AL RETOMAR: HUD plano + rangos + ranking" como hecho (fecha 2026-09-16), dejando pendiente: prueba del usuario con su cuenta, re-export `python scripts/exportar_web.py`, merge/publicación con OK.
  - §9 brecha 4 (estilo): nota de que el HUD ya es plano y que la tesis debe reflejarlo.

- [ ] **Step 4: Commit**

```bash
git add tests/captura_hud.gd tests/captura_hud.gd.uid tests/captura_hud.tscn docs/ESTADO_PROYECTO.md docs/diseno/hud_plano_2b.md
git commit -m "docs: HUD plano 2b implementado; captura de verificación"
```
