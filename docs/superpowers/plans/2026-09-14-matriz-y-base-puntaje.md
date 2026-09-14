# Matriz de cobertura y base de puntaje GreenMetric — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir la matriz de los 51 indicadores GreenMetric (paso 0) y un puntaje por categoría único, calculado en el servidor y usado en todo el juego (proyecto A).

**Architecture:** Supabase guarda catálogos (misiones, sinergias, decisiones), detalles del estudiante y un registro de puntos de calidad; una función calcula el desglose 80/10/5/5 por categoría. En Godot, un autoload nuevo `PuntajeManager` pide ese desglose, lo reparte a HUD, mapa de calor, resultados e informe, y sincroniza los detalles con el servidor. `NivelManager` pasa a contar solo misiones válidas por nivel y distingue "completo" de "superado" (legado).

**Tech Stack:** Godot 4.7 (GDScript), Supabase (Postgres 17, RLS, funciones `SECURITY DEFINER`), Supabase MCP (`apply_migration`, `execute_sql`, `get_advisors`), export web con `scripts/exportar_web.py`.

**Spec:** `docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md` (secciones 5 y 6).

## Global Constraints

- Idioma: código, comentarios, commits y documentos en **español** (estilo del repo: comentarios que explican el porqué).
- Proyecto Supabase: `ikohikbpvtbvsgyumvbr` (greenmetric-urbe). Nunca tocar otro proyecto.
- Toda función SQL nueva: `security definer`, `set search_path to 'public'`, `revoke ... from public, anon` y `grant execute ... to authenticated` salvo que se indique.
- Sin sesión, toda función de estudiante lanza `raise exception 'No autenticado' using errcode = '42501'`.
- Pesos de categoría (guía 2024): `{1: 15, 2: 21, 3: 18, 4: 10, 5: 18, 6: 18}`.
- Topes por categoría: avance 80, comprensión 10, decisiones 5, sinergias 5.
- Pruebas SQL: nunca dejar datos. Usar un bloque `DO $$ ... $$` que termine en `raise exception` con los resultados, o una transacción que termine en `rollback`.
- Cuentas de prueba: principal `fbc255c9-d9f2-4391-8af0-23e885873986`, prueba `aeb07ad1-0aee-4b03-b274-1c9bb0a04bc2`.
- Godot: `C:\Users\edward\OneDrive\Desktop\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe` (en bash: `/c/Users/edward/OneDrive/Desktop/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`). Se abrevia `$GODOT` abajo.
- Pruebas de Godot: escenas en `tests/` que se corren con `$GODOT --headless --path . res://tests/<escena>.tscn` y terminan con `get_tree().quit(0|1)`. **No** usar `--script` (no garantiza autoloads).
- `tests/*` y `docs/*` nunca van al `.pck` (ver `export_presets.cfg` → `exclude_filter`).
- Nunca commitear `.mcp.json` ni archivos de `C:\Users\edward\OneDrive\Desktop\tesis`.
- Commits terminan con `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.
- Rama de trabajo: `nivel-6-educacion-investigacion`. No hacer push ni merge sin que el controlador lo indique.

## Perfil de subagente por tarea

| Tarea | Modelo sugerido | Motivo |
|---|---|---|
| 1 Matriz | sonnet | análisis de contenido y documento |
| 2 Esquema SQL + catálogos | opus | seguridad (RLS, grants) y datos semilla exactos |
| 3 Funciones SQL + pruebas | opus | lógica de puntaje, idempotencia, penalizaciones |
| 4 NivelManager legado | sonnet | lógica pura con prueba |
| 5 SupabaseManager wrappers | sonnet | patrón existente, mecánico |
| 6 PuntajeManager | sonnet | autoload nuevo con fórmula probada |
| 7 Login + detalles al servidor | sonnet | flujo de sesión con timeout |
| 8 Integración de UI | opus | archivo de ~2900 líneas, muchos puntos de contacto |
| 9 Quiz y minijuego | haiku | cambios pequeños y localizados |
| 10 Publicación y documentación | sonnet | export, verificación y docs |

---

### Task 1: Matriz de cobertura de los 51 indicadores

**Files:**
- Create: `docs/matriz_cobertura_greenmetric.md`

**Interfaces:**
- Consumes: texto extraído de la guía oficial 2024 en `C:\Users\edward\AppData\Local\Temp\claude\c--Users-edward-OneDrive-Desktop-green-metric-urbe\df997c54-a510-4304-a892-953a5a296aad\scratchpad\gm2024.txt` (líneas 255–356 = "Table 3 Indicators and categories suggested for use in the 2024 rankings"). Si el archivo no existe, descargar `https://green.rmutk.ac.th/wp-content/uploads/2024/06/UI-GreenMetric-Guideline-2024.pdf` y extraer con `pypdf` escribiendo a archivo con `encoding='utf-8'`.
- Produces: matriz usada por los proyectos B y C (no consume código).

- [ ] **Step 1: Verificar la fuente**

Run: `sed -n 255,356p "<ruta de gm2024.txt>"`
Expected: tabla con SI1–SI11 (total 1500), EC1–EC10 (2100), WS1–WS6 (1800), WR1–WR5 (1000), TR1–TR8 (1800), ED1–ED11 (1800).

- [ ] **Step 2: Inventariar lo que el juego cubre hoy**

Leer y anotar (solo lectura):
- `scenes/mapa/SceneMapaMundo.gd`: `QUIZ_POR_MISION` (preguntas de cada quiz), `ZONA_A_MISION` (qué quiz es de qué categoría), las constantes `DATOS_*` de puntos de misión.
- `scenes/misiones/*.gd`: textos de cada misión (qué enseña).
- `scenes/ui/minijuego_residuos.gd`, `scenes/ui/simulador_decision.gd`, `scenes/ui/crisis_evento.gd`.

Anomalías conocidas a registrar en la sección "Anomalías":
- `mision_residuos` tiene quiz en `QUIZ_POR_MISION` pero la zona del Cafetín abre el minijuego (`_on_dialogo_terminado`), así que el quiz nunca se juega.
- `mision_bloque_g` tiene quiz pero no aparece en `ZONA_A_MISION`.
- `plantar_sur` existe en `scenes/misiones/mision_plantar.gd` pero no en `DATOS_ZONAS_TIERRA`/el mapa (el nivel 1 usa 6 zonas: rectorado, patio, este, corredores, norte, oeste).

- [ ] **Step 3: Escribir la matriz**

Estructura obligatoria del archivo:

```markdown
# Matriz de cobertura UI GreenMetric 2024 — GreenMetric URBE

Fuente: UI GreenMetric Guideline 2024, Table 3 (51 indicadores).
Criterio (decisión D9 del diseño 2026-09-14): los 51 indicadores se aprenden
(quiz o ficha); los que un estudiante puede ver o influir en el campus se juegan.

## Resumen por categoría
| Categoría | Peso | Indicadores | Cubiertos hoy | Minijuego/misión nuevos | Solo quiz/ficha |

## 1. Entorno e Infraestructura (SI) — 15%
| Código | Indicador | Puntos | Tratamiento | Nivel | Cubierto hoy por | Propuesto | Cruces | Accionable |
|---|---|---|---|---|---|---|---|---|
| SI1 | Proporción de área abierta sobre el área total | 200 | quiz | 1 | — | pregunta nueva en quiz de Entorno | — | parcial |
...
(una tabla por categoría, 51 filas en total)

## Anomalías del inventario actual

## Preguntas nuevas necesarias
(lista por categoría: indicador → tema de la pregunta; se redactan en el proyecto C)
```

Reglas de llenado:
- **Tratamiento** ∈ `misión`, `minijuego`, `decisión`, `quiz`, `ficha`. Ninguna fila vacía.
- Los 7 de D10 van como `minijuego`: SI7 (Órdenes de trabajo), SI10 (Campus saludable), SI11 (Censo del Lago URBE), EC8 (Inventario de emisiones), EC2 (Sala de control del Bloque E), WS3 (Compostera del Cafetín), WR2 (Circuito de aguas grises), con los cruces de la sección 8 del spec.
- Transporte: TR1–TR7 como `decisión` (proyecto B, spec sección 7); TR8 como `quiz`.
- "Cubierto hoy por" cita IDs reales del código (ej. `plantar_*`, `led_bloque_*`, `mision_agua`).
- Institucionales (SI6, ED2, ED3, ED9, ED11, EC4, EC5…) → `quiz` o `ficha`, accionable `no`.

- [ ] **Step 4: Verificar la matriz**

Run: `grep -cE "^\| (SI|EC|WS|WR|TR|ED)[0-9]+ \|" docs/matriz_cobertura_greenmetric.md`
Expected: `51`

Run: `grep -E "^\| (SI|EC|WS|WR|TR|ED)[0-9]+ \|" docs/matriz_cobertura_greenmetric.md | awk -F'|' '{gsub(/ /,"",$5); print $5}' | sort | uniq -c`
Expected: solo los valores `misión`, `minijuego`, `decisión`, `quiz`, `ficha`; `minijuego` = 7.

- [ ] **Step 5: Commit**

```bash
git add docs/matriz_cobertura_greenmetric.md
git commit -m "docs: matriz de cobertura de los 51 indicadores GreenMetric 2024

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Esquema SQL — catálogos, detalles y puntos de calidad

**Files:**
- Create: `sql/puntaje_greenmetric.sql` (primera parte: tablas, RLS, semillas)
- Apply: migración `puntaje_greenmetric_esquema` vía MCP `apply_migration`

**Interfaces:**
- Consumes: tabla existente `public.misiones_estudiante(user_id uuid, modulo_id int, mision_id text, ...)`, pk `(user_id, mision_id)`.
- Produces (usado por Task 3): tablas `catalogo_misiones`, `catalogo_sinergias`, `catalogo_decisiones`, `detalles_estudiante`, `puntos_calidad` con las columnas exactas de abajo.

- [ ] **Step 1: Prueba que falla**

Run (MCP `execute_sql`, project `ikohikbpvtbvsgyumvbr`):
```sql
select to_regclass('public.catalogo_misiones') cm, to_regclass('public.catalogo_sinergias') cs,
       to_regclass('public.catalogo_decisiones') cd, to_regclass('public.detalles_estudiante') de,
       to_regclass('public.puntos_calidad') pc;
```
Expected: las cinco columnas en `null`.

- [ ] **Step 2: Escribir el SQL del esquema**

Crear `sql/puntaje_greenmetric.sql` con este encabezado y contenido:

```sql
-- ============================================================
-- puntaje_greenmetric.sql — GreenMetric_URBE
-- Puntaje por categoría único (avance 80 + comprensión 10 + decisiones 5 +
-- sinergias 5), calculado en el servidor. Diseño:
-- docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md
--
-- Antes cada categoría tenía tres números distintos (barra del HUD pisada por
-- un ImpactRating que no se guardaba, mapa de calor con valores fijos,
-- informe con % de misiones). Este archivo es la única fuente de verdad.
--
-- ESPEJO: catalogo_misiones refleja NivelManager.MISIONES_NIVEL y los quizzes
-- de SceneMapaMundo.QUIZ_POR_MISION. Si cambia uno, cambiar el otro.
-- ============================================================

-- ── Catálogos (solo se escriben por migración) ───────────────
create table if not exists public.catalogo_misiones (
  mision_id text primary key,
  categoria int  not null check (categoria between 1 and 6),
  -- 'mision' y 'minijuego' cuentan para Avance; 'quiz' para Comprensión.
  tipo      text not null check (tipo in ('mision', 'quiz', 'minijuego')),
  preguntas int  not null default 0 check (preguntas >= 0)
);

create table if not exists public.catalogo_sinergias (
  accion_id        text not null,
  categoria        int  not null check (categoria between 1 and 6),
  puntos           int  not null check (puntos between 1 and 5),
  requisito_mision text,
  primary key (accion_id, categoria)
);

create table if not exists public.catalogo_decisiones (
  decision_id      text not null,
  opcion_id        text not null,
  categoria        int  not null check (categoria between 1 and 6),
  puntos           numeric(4,2) not null default 0 check (puntos between 0 and 5),
  contraproducente boolean not null default false,
  costo            int  not null default 0 check (costo >= 0),
  primary key (decision_id, opcion_id)
);

-- ── Datos del estudiante ─────────────────────────────────────
-- Decisiones con criterio propio (Nivel 5, Nivel 6, minijuegos). Antes vivían
-- solo en el archivo local de NivelManager y se perdían al cambiar de máquina.
create table if not exists public.detalles_estudiante (
  user_id        uuid not null references auth.users(id) on delete cascade,
  clave          text not null check (clave ~ '^[a-z0-9_:.-]{1,80}$'),
  detalle        jsonb not null default '{}'::jsonb,
  actualizado_en timestamptz not null default now(),
  primary key (user_id, clave)
);

-- Registro de puntos de calidad. `ref` único por usuario y categoría: repetir
-- una acción nunca suma dos veces (mismo principio que movimientos_ecocredits).
create table if not exists public.puntos_calidad (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  categoria  int  not null check (categoria between 1 and 6),
  componente text not null check (componente in ('comprension', 'decision', 'sinergia')),
  puntos     numeric(5,2) not null,
  ref        text not null,
  creado_en  timestamptz not null default now(),
  unique (user_id, ref, categoria)
);

create index if not exists puntos_calidad_user_idx on public.puntos_calidad (user_id);

-- ── RLS ──────────────────────────────────────────────────────
alter table public.catalogo_misiones   enable row level security;
alter table public.catalogo_sinergias  enable row level security;
alter table public.catalogo_decisiones enable row level security;
alter table public.detalles_estudiante enable row level security;
alter table public.puntos_calidad      enable row level security;

create policy "Catalogo de misiones visible" on public.catalogo_misiones
  for select to anon, authenticated using (true);
create policy "Catalogo de sinergias visible" on public.catalogo_sinergias
  for select to anon, authenticated using (true);
create policy "Catalogo de decisiones visible" on public.catalogo_decisiones
  for select to anon, authenticated using (true);
create policy "Ver detalles propios" on public.detalles_estudiante
  for select to authenticated using (user_id = (select auth.uid()));
create policy "Ver puntos propios" on public.puntos_calidad
  for select to authenticated using (user_id = (select auth.uid()));

revoke all on public.catalogo_misiones, public.catalogo_sinergias, public.catalogo_decisiones,
              public.detalles_estudiante, public.puntos_calidad from anon, authenticated;
grant select on public.catalogo_misiones, public.catalogo_sinergias, public.catalogo_decisiones
  to anon, authenticated;
grant select on public.detalles_estudiante, public.puntos_calidad to authenticated;

-- ── Semilla: misiones actuales (espejo de NivelManager.MISIONES_NIVEL) ──
insert into public.catalogo_misiones (mision_id, categoria, tipo, preguntas) values
  ('plantar_rectorado', 1, 'mision', 0), ('plantar_patio', 1, 'mision', 0),
  ('plantar_este', 1, 'mision', 0), ('plantar_corredores', 1, 'mision', 0),
  ('plantar_norte', 1, 'mision', 0), ('plantar_oeste', 1, 'mision', 0),
  ('led_bloque_a', 2, 'mision', 0), ('led_bloque_b', 2, 'mision', 0),
  ('led_bloque_c', 2, 'mision', 0), ('led_bloque_d', 2, 'mision', 0),
  ('led_bloque_e', 2, 'mision', 0), ('led_bloque_f', 2, 'mision', 0),
  ('solar_rectorado', 2, 'mision', 0), ('solar_estacionamiento', 2, 'mision', 0),
  ('reciclar_corredor_n', 3, 'mision', 0), ('reciclar_patio_e', 3, 'mision', 0),
  ('reciclar_bloque_e', 3, 'mision', 0), ('reciclar_oeste', 3, 'mision', 0),
  ('reciclar_sur', 3, 'mision', 0), ('reciclar_este', 3, 'mision', 0),
  ('llave_bloque_c', 4, 'mision', 0), ('llave_bloque_a', 4, 'mision', 0),
  ('llave_corredor_n', 4, 'mision', 0), ('llave_patio_e', 4, 'mision', 0),
  ('llave_este', 4, 'mision', 0), ('llave_bloque_b', 4, 'mision', 0),
  ('captacion_biblioteca', 4, 'mision', 0), ('captacion_bloque_c', 4, 'mision', 0),
  ('mov_parqueo', 5, 'mision', 0), ('mov_shuttle', 5, 'mision', 0),
  ('mov_ciclovia', 5, 'mision', 0), ('mov_dia_sin_carros', 5, 'mision', 0),
  ('mov_zev', 5, 'mision', 0), ('mov_carpool', 5, 'mision', 0),
  ('bicicletero_bloque_e', 5, 'mision', 0), ('bicicletero_cafetin', 5, 'mision', 0),
  ('malla_verde', 6, 'mision', 0), ('comite_ambiental', 6, 'mision', 0),
  ('semana_verde', 6, 'mision', 0), ('informe_final', 6, 'mision', 0),
  -- Quizzes jugables (ZONA_A_MISION). mision_residuos y mision_bloque_g no
  -- se juegan hoy (ver matriz de cobertura, "Anomalías").
  ('mision_bloque_f', 1, 'quiz', 3), ('mision_fotocopiado', 1, 'quiz', 3),
  ('mision_bloque_a', 2, 'quiz', 3), ('mision_bloque_b', 2, 'quiz', 3),
  ('mision_bloque_c', 2, 'quiz', 3), ('mision_bloque_d', 2, 'quiz', 3),
  ('mision_bloque_e', 2, 'quiz', 3),
  -- El minijuego de clasificación es la Comprensión de Residuos (10 ítems);
  -- es 'quiz' y no 'minijuego' porque NO es una de las misiones del nivel.
  ('mision_residuos_minijuego', 3, 'quiz', 10),
  ('mision_agua', 4, 'quiz', 3), ('mision_transporte', 5, 'quiz', 3),
  ('mision_rector', 6, 'quiz', 3), ('mision_educacion', 6, 'quiz', 3)
on conflict (mision_id) do nothing;
```

- [ ] **Step 3: Verificar las preguntas contra el código antes de aplicar**

Run:
```bash
python - <<'EOF'
import re
t = open('scenes/mapa/SceneMapaMundo.gd', encoding='utf-8').read()
i = t.index('const QUIZ_POR_MISION'); j = t.index('\n}\n', i); blk = t[i:j]
for m in re.finditer(r'"(mision_\w+)": \[', blk):
    k = m.start(); fin = blk.find('\n\t],', k)
    print(m.group(1), blk[k:fin].count('"pregunta"'))
EOF
grep -n "const TOTAL_RESIDUOS" scenes/ui/minijuego_residuos.gd
```
Expected: cada quiz sembrado tiene 3 preguntas; `TOTAL_RESIDUOS = 10`. Si difiere, corregir la semilla.

- [ ] **Step 4: Aplicar la migración**

MCP `apply_migration` con `name: "puntaje_greenmetric_esquema"` y `query` = el contenido completo de `sql/puntaje_greenmetric.sql` hasta este punto.

- [ ] **Step 5: Verificar esquema, semilla y RLS**

MCP `execute_sql`:
```sql
select categoria, tipo, count(*) n, sum(preguntas) preguntas
from catalogo_misiones group by 1, 2 order by 1, 2;
```
Expected:
| categoria | tipo | n | preguntas |
|---|---|---|---|
| 1 | mision | 6 | 0 |
| 1 | quiz | 2 | 6 |
| 2 | mision | 8 | 0 |
| 2 | quiz | 5 | 15 |
| 3 | mision | 6 | 0 |
| 3 | quiz | 1 | 10 |
| 4 | mision | 8 | 0 |
| 4 | quiz | 1 | 3 |
| 5 | mision | 8 | 0 |
| 5 | quiz | 1 | 3 |
| 6 | mision | 4 | 0 |
| 6 | quiz | 2 | 6 |

```sql
select c.relname, c.relrowsecurity from pg_class c
where c.relname in ('catalogo_misiones','catalogo_sinergias','catalogo_decisiones','detalles_estudiante','puntos_calidad');
```
Expected: 5 filas, `relrowsecurity = true`.

Prueba de aislamiento (termina en excepción, no deja datos):
```sql
do $$
declare v_vistas int;
begin
  insert into detalles_estudiante (user_id, clave, detalle)
  values ('aeb07ad1-0aee-4b03-b274-1c9bb0a04bc2', 'prueba_rls', '{"x":1}');
  perform set_config('request.jwt.claims',
    '{"sub":"fbc255c9-d9f2-4391-8af0-23e885873986","role":"authenticated"}', true);
  set local role authenticated;
  select count(*) into v_vistas from detalles_estudiante where clave = 'prueba_rls';
  raise exception 'RESULTADO filas_de_otro_visibles=%', v_vistas;
end $$;
```
Expected: error `RESULTADO filas_de_otro_visibles=0`. (Si `set local role` no se permite dentro del `DO`, correr las mismas sentencias como script `begin; ... rollback;`.)

- [ ] **Step 6: Commit**

```bash
git add sql/puntaje_greenmetric.sql
git commit -m "puntaje (1/10): esquema de catalogos, detalles y puntos de calidad

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Funciones SQL del puntaje y sus pruebas

**Files:**
- Modify: `sql/puntaje_greenmetric.sql` (agregar al final la sección de funciones)
- Apply: migración `puntaje_greenmetric_funciones`

**Interfaces:**
- Consumes: tablas de Task 2; `misiones_estudiante`.
- Produces (usado por Tasks 5–9), todas devuelven `jsonb`:
  - `puntaje_greenmetric()` → `{"categorias": {"1": {"avance","comprension","decisiones","sinergias","total"}, ..."6"}, "total": num, "quizzes_hechos": [mision_id...]}`
  - `guardar_detalle(p_clave text, p_detalle jsonb)` → `{"ok": bool, "error"?: text}`
  - `obtener_detalles()` → `{clave: detalle, ...}`
  - `registrar_quiz(p_mision_id text, p_aciertos int)` → `{"ok", "registrado": bool, "puntaje": <puntaje>}` o `{"ok": false, "error"}`
  - `registrar_decision(p_decision_id text, p_opcion_id text)` → `{"ok", "contraproducente": bool, "penalizado"?: bool, "puntaje"}` o `{"ok": false, "error"}`
  - `registrar_sinergia(p_accion_id text)` → `{"ok", "nuevo": bool, "categorias": [{"categoria","puntos"}], "puntaje"}` o `{"ok": false, "error"}`

- [ ] **Step 1: Prueba que falla**

MCP `execute_sql`:
```sql
select proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and proname in
 ('puntaje_greenmetric','_puntaje_greenmetric','guardar_detalle','obtener_detalles',
  'registrar_quiz','registrar_decision','registrar_sinergia');
```
Expected: 0 filas.

- [ ] **Step 2: Escribir las funciones**

Agregar a `sql/puntaje_greenmetric.sql`:

```sql
-- ── Cálculo (interno, no expuesto) ───────────────────────────
create or replace function public._puntaje_greenmetric(p_user uuid)
returns jsonb language sql stable security definer set search_path to 'public' as $$
  with cats(categoria, peso) as (
    values (1, 15), (2, 21), (3, 18), (4, 10), (5, 18), (6, 18)
  ),
  av as (
    select c.categoria,
           count(*)           filter (where c.tipo in ('mision', 'minijuego')) as total,
           count(m.mision_id) filter (where c.tipo in ('mision', 'minijuego')) as hechas,
           coalesce(sum(c.preguntas) filter (where c.tipo = 'quiz'), 0)       as preguntas
      from catalogo_misiones c
      left join misiones_estudiante m
        on m.mision_id = c.mision_id and m.user_id = p_user
     group by c.categoria
  ),
  pq as (
    select categoria,
           coalesce(sum(puntos) filter (where componente = 'comprension'), 0) as aciertos,
           coalesce(sum(puntos) filter (where componente = 'decision'), 0)    as dec,
           coalesce(sum(puntos) filter (where componente = 'sinergia'), 0)    as sin
      from puntos_calidad where user_id = p_user
     group by categoria
  ),
  calc as (
    select k.categoria, k.peso,
           case when coalesce(a.total, 0) = 0 then 0
                else round(80.0 * a.hechas / a.total, 2) end                          as avance,
           case when coalesce(a.preguntas, 0) = 0 then 0
                else round(10.0 * least(coalesce(q.aciertos, 0), a.preguntas) / a.preguntas, 2) end as comprension,
           round(greatest(0, least(5, coalesce(q.dec, 0))), 2)                        as decisiones,
           round(greatest(0, least(5, coalesce(q.sin, 0))), 2)                        as sinergias
      from cats k
      left join av a using (categoria)
      left join pq q using (categoria)
  )
  select jsonb_build_object(
    'categorias', jsonb_object_agg(categoria::text, jsonb_build_object(
        'avance', avance, 'comprension', comprension,
        'decisiones', decisiones, 'sinergias', sinergias,
        'total', avance + comprension + decisiones + sinergias)),
    'total', round(sum((avance + comprension + decisiones + sinergias) * peso / 100.0), 2),
    'quizzes_hechos', coalesce((
        select jsonb_agg(substr(ref, 6)) from puntos_calidad
         where user_id = p_user and componente = 'comprension'), '[]'::jsonb))
  from calc;
$$;

-- ── Público ──────────────────────────────────────────────────
create or replace function public.puntaje_greenmetric()
returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  return _puntaje_greenmetric(v_user);
end;
$$;

create or replace function public.guardar_detalle(p_clave text, p_detalle jsonb)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  if p_clave is null or p_clave !~ '^[a-z0-9_:.-]{1,80}$' then
    return jsonb_build_object('ok', false, 'error', 'clave_invalida');
  end if;
  if p_detalle is null or jsonb_typeof(p_detalle) <> 'object' then
    return jsonb_build_object('ok', false, 'error', 'detalle_invalido');
  end if;
  if pg_column_size(p_detalle) > 8192 then
    return jsonb_build_object('ok', false, 'error', 'detalle_muy_grande');
  end if;
  insert into detalles_estudiante (user_id, clave, detalle, actualizado_en)
  values (v_user, p_clave, p_detalle, now())
  on conflict (user_id, clave)
  do update set detalle = excluded.detalle, actualizado_en = now();
  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.obtener_detalles()
returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  return coalesce((select jsonb_object_agg(clave, detalle)
                     from detalles_estudiante where user_id = v_user), '{}'::jsonb);
end;
$$;

-- Primer intento: si el quiz ya estaba registrado no cambia nada, así
-- repetirlo no sube la Comprensión.
create or replace function public.registrar_quiz(p_mision_id text, p_aciertos int)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user  uuid := auth.uid();
  v_cat   int;
  v_preg  int;
  v_filas int;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  select categoria, preguntas into v_cat, v_preg
    from catalogo_misiones where mision_id = p_mision_id and tipo = 'quiz';
  if v_cat is null then
    return jsonb_build_object('ok', false, 'error', 'quiz_inexistente');
  end if;
  if p_aciertos is null or p_aciertos < 0 or p_aciertos > v_preg then
    return jsonb_build_object('ok', false, 'error', 'aciertos_fuera_de_rango');
  end if;
  insert into puntos_calidad (user_id, categoria, componente, puntos, ref)
  values (v_user, v_cat, 'comprension', p_aciertos, 'quiz:' || p_mision_id)
  on conflict (user_id, ref, categoria) do nothing;
  get diagnostics v_filas = row_count;
  return jsonb_build_object('ok', true, 'registrado', v_filas > 0,
                            'puntaje', _puntaje_greenmetric(v_user));
end;
$$;

-- Regla Mixta (Tabla 15 del Cap. 4): la opción contraproducente penaliza −1
-- (máximo 3 veces por decisión) y el cliente ofrece reintento; una opción
-- válida reemplaza los puntos anteriores de esa decisión.
create or replace function public.registrar_decision(p_decision_id text, p_opcion_id text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user   uuid := auth.uid();
  v_cat    int;
  v_puntos numeric;
  v_contra boolean;
  v_prefijo text;
  v_n      int;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  select categoria, puntos, contraproducente into v_cat, v_puntos, v_contra
    from catalogo_decisiones where decision_id = p_decision_id and opcion_id = p_opcion_id;
  if v_cat is null then
    return jsonb_build_object('ok', false, 'error', 'opcion_inexistente');
  end if;
  perform pg_advisory_xact_lock(hashtext('calidad:' || v_user::text));
  if v_contra then
    v_prefijo := 'penal:' || p_decision_id || ':';
    select count(*) into v_n from puntos_calidad
     where user_id = v_user and left(ref, length(v_prefijo)) = v_prefijo;
    if v_n < 3 then
      insert into puntos_calidad (user_id, categoria, componente, puntos, ref)
      values (v_user, v_cat, 'decision', -1, v_prefijo || (v_n + 1));
    end if;
    return jsonb_build_object('ok', true, 'contraproducente', true, 'penalizado', v_n < 3,
                              'puntaje', _puntaje_greenmetric(v_user));
  end if;
  insert into puntos_calidad (user_id, categoria, componente, puntos, ref)
  values (v_user, v_cat, 'decision', v_puntos, 'decision:' || p_decision_id)
  on conflict (user_id, ref, categoria)
  do update set puntos = excluded.puntos, creado_en = now();
  return jsonb_build_object('ok', true, 'contraproducente', false,
                            'puntaje', _puntaje_greenmetric(v_user));
end;
$$;

create or replace function public.registrar_sinergia(p_accion_id text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user  uuid := auth.uid();
  v_filas int;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  if not exists (select 1 from catalogo_sinergias where accion_id = p_accion_id) then
    return jsonb_build_object('ok', false, 'error', 'sinergia_inexistente');
  end if;
  if exists (
    select 1 from catalogo_sinergias s
     where s.accion_id = p_accion_id and s.requisito_mision is not null
       and not exists (select 1 from misiones_estudiante m
                        where m.user_id = v_user and m.mision_id = s.requisito_mision)
  ) then
    return jsonb_build_object('ok', false, 'error', 'requisito_incumplido');
  end if;
  insert into puntos_calidad (user_id, categoria, componente, puntos, ref)
  select v_user, categoria, 'sinergia', puntos, 'sinergia:' || p_accion_id
    from catalogo_sinergias where accion_id = p_accion_id
  on conflict (user_id, ref, categoria) do nothing;
  get diagnostics v_filas = row_count;
  return jsonb_build_object(
    'ok', true, 'nuevo', v_filas > 0,
    'categorias', (select jsonb_agg(jsonb_build_object('categoria', categoria, 'puntos', puntos))
                     from catalogo_sinergias where accion_id = p_accion_id),
    'puntaje', _puntaje_greenmetric(v_user));
end;
$$;

revoke execute on function public._puntaje_greenmetric(uuid) from public, anon, authenticated;
revoke execute on function public.puntaje_greenmetric()               from public, anon;
revoke execute on function public.guardar_detalle(text, jsonb)        from public, anon;
revoke execute on function public.obtener_detalles()                  from public, anon;
revoke execute on function public.registrar_quiz(text, int)           from public, anon;
revoke execute on function public.registrar_decision(text, text)      from public, anon;
revoke execute on function public.registrar_sinergia(text)            from public, anon;
grant  execute on function public.puntaje_greenmetric()               to authenticated;
grant  execute on function public.guardar_detalle(text, jsonb)        to authenticated;
grant  execute on function public.obtener_detalles()                  to authenticated;
grant  execute on function public.registrar_quiz(text, int)           to authenticated;
grant  execute on function public.registrar_decision(text, text)      to authenticated;
grant  execute on function public.registrar_sinergia(text)            to authenticated;
```

- [ ] **Step 3: Aplicar**

MCP `apply_migration` `name: "puntaje_greenmetric_funciones"` con la sección de funciones.

- [ ] **Step 4: Pruebas del servidor (una por consulta, todas terminan en excepción)**

Cada bloque simula sesión con `perform set_config('request.jwt.claims', '{"sub":"aeb07ad1-0aee-4b03-b274-1c9bb0a04bc2","role":"authenticated"}', true);` y termina con `raise exception 'RESULTADO ...'`.

4a. Sin sesión (sin `set_config`): `perform puntaje_greenmetric();` dentro de `begin ... exception when sqlstate '42501' then raise exception 'RESULTADO 42501_ok'; end;` — repetir para las 6 funciones públicas.
Expected: `RESULTADO 42501_ok` en las 6.

4b. Quiz, primer intento:
```sql
do $$
declare r1 jsonb; r2 jsonb; r3 jsonb; r4 jsonb;
begin
  perform set_config('request.jwt.claims','{"sub":"aeb07ad1-0aee-4b03-b274-1c9bb0a04bc2","role":"authenticated"}', true);
  r1 := registrar_quiz('mision_agua', 2);
  r2 := registrar_quiz('mision_agua', 3);
  r3 := registrar_quiz('mision_agua', 4);
  r4 := registrar_quiz('no_existe', 1);
  raise exception 'RESULTADO r1.registrado=% r2.registrado=% comp_agua=% r3=% r4=%',
    r1->>'registrado', r2->>'registrado',
    r2->'puntaje'->'categorias'->'4'->>'comprension', r3->>'error', r4->>'error';
end $$;
```
Expected: `r1.registrado=true r2.registrado=false comp_agua=6.67 r3=aciertos_fuera_de_rango r4=quiz_inexistente` (2/3 × 10 = 6.67; si la cuenta de prueba ya tiene quizzes de Agua, comprensión refleja el primero).

4c. Decisiones (catálogo temporal dentro del bloque):
```sql
do $$
declare r jsonb; i int;
begin
  insert into catalogo_decisiones values
    ('prueba_d', 'buena', 5, 3, false, 10), ('prueba_d', 'media', 5, 1, false, 5),
    ('prueba_d', 'mala', 5, 0, true, 0);
  perform set_config('request.jwt.claims','{"sub":"aeb07ad1-0aee-4b03-b274-1c9bb0a04bc2","role":"authenticated"}', true);
  r := registrar_decision('prueba_d', 'buena');
  raise notice 'buena dec=%', r->'puntaje'->'categorias'->'5'->>'decisiones';
  r := registrar_decision('prueba_d', 'media');
  raise notice 'media dec=%', r->'puntaje'->'categorias'->'5'->>'decisiones';
  for i in 1..4 loop
    r := registrar_decision('prueba_d', 'mala');
  end loop;
  raise exception 'RESULTADO contra=% penalizado_4a=% dec_final=% penal_filas=% inexistente=%',
    r->>'contraproducente', r->>'penalizado',
    r->'puntaje'->'categorias'->'5'->>'decisiones',
    (select count(*) from puntos_calidad where user_id = 'aeb07ad1-0aee-4b03-b274-1c9bb0a04bc2' and ref like 'penal:prueba_d:%'),
    registrar_decision('prueba_d', 'nada')->>'error';
end $$;
```
Expected: `contra=true penalizado_4a=false dec_final=0.00 penal_filas=3 inexistente=opcion_inexistente` (1 − 3 = −2 → tope 0). Las notices muestran `buena dec=3.00` y `media dec=1.00`.

4d. Sinergias:
```sql
do $$
declare r1 jsonb; r2 jsonb; r3 jsonb; r4 jsonb;
begin
  insert into catalogo_sinergias values
    ('prueba_s', 4, 1, null), ('prueba_s', 1, 1, null),
    ('prueba_req', 4, 1, 'mision_que_no_hizo');
  perform set_config('request.jwt.claims','{"sub":"aeb07ad1-0aee-4b03-b274-1c9bb0a04bc2","role":"authenticated"}', true);
  r1 := registrar_sinergia('prueba_s');
  r2 := registrar_sinergia('prueba_s');
  r3 := registrar_sinergia('prueba_req');
  r4 := registrar_sinergia('nada');
  raise exception 'RESULTADO nuevo1=% nuevo2=% sin_agua=% sin_entorno=% req=% inex=%',
    r1->>'nuevo', r2->>'nuevo',
    r2->'puntaje'->'categorias'->'4'->>'sinergias', r2->'puntaje'->'categorias'->'1'->>'sinergias',
    r3->>'error', r4->>'error';
end $$;
```
Expected: `nuevo1=true nuevo2=false sin_agua=1.00 sin_entorno=1.00 req=requisito_incumplido inex=sinergia_inexistente`.

4e. Topes y avance con la cuenta principal (lectura, no escribe):
```sql
do $$
declare r jsonb;
begin
  perform set_config('request.jwt.claims','{"sub":"fbc255c9-d9f2-4391-8af0-23e885873986","role":"authenticated"}', true);
  r := puntaje_greenmetric();
  raise exception 'RESULTADO %', r;
end $$;
```
Expected: categorías 1–5 con `avance = 80.00` (la cuenta tiene todas las misiones actuales de 1–5), categoría 6 `avance = 0.00`, ningún componente fuera de sus topes, `total` = Σ total×peso/100.

4f. Detalles:
```sql
do $$
declare a jsonb; b jsonb; c jsonb; d jsonb; e jsonb;
begin
  perform set_config('request.jwt.claims','{"sub":"aeb07ad1-0aee-4b03-b274-1c9bb0a04bc2","role":"authenticated"}', true);
  a := guardar_detalle('prueba_det', '{"x":1}');
  b := guardar_detalle('prueba_det', '{"x":2}');
  c := guardar_detalle('Clave Mala', '{}');
  d := guardar_detalle('prueba_arr', '[1,2]');
  e := guardar_detalle('prueba_grande', jsonb_build_object('t', repeat('a', 9000)));
  raise exception 'RESULTADO a=% b=% leido=% c=% d=% e=%', a->>'ok', b->>'ok',
    obtener_detalles()->'prueba_det'->>'x', c->>'error', d->>'error', e->>'error';
end $$;
```
Expected: `a=true b=true leido=2 c=clave_invalida d=detalle_invalido e=detalle_muy_grande`.

4g. Confirmar que no quedaron datos:
```sql
select (select count(*) from puntos_calidad) pc, (select count(*) from detalles_estudiante) de,
       (select count(*) from catalogo_decisiones) cd, (select count(*) from catalogo_sinergias) cs;
```
Expected: `0, 0, 0, 0`.

- [ ] **Step 5: Advisors**

MCP `get_advisors` tipo `security`. Expected: ninguna alerta nueva que mencione las tablas o funciones de este archivo (en especial `function_search_path_mutable` y `rls_disabled_in_public`).

- [ ] **Step 6: Commit**

```bash
git add sql/puntaje_greenmetric.sql
git commit -m "puntaje (2/10): funciones del puntaje GreenMetric, detalles y calidad

Probadas en el servidor: primer intento de quiz, penalizacion con tope,
sinergias con requisito, detalles invalidos y 42501 sin sesion.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: NivelManager — misiones válidas y niveles superados por legado

**Files:**
- Modify: `autoload/NivelManager.gd` (constantes cerca de la línea 29; `nivel_desbloqueado`, `nivel_completo`, `pct_nivel` cerca de las líneas 122–146)
- Create: `tests/test_niveles.gd`, `tests/test_niveles.tscn`
- Modify: `export_presets.cfg` (agregar `tests/*` al `exclude_filter`)

**Interfaces:**
- Consumes: nada nuevo.
- Produces:
  - `const MISIONES_NIVEL : Dictionary` (`{int: Array[String]}`) y `const MISIONES_LEGADO : Dictionary`.
  - `var misiones_nivel : Dictionary` y `var misiones_legado : Dictionary` (copias de las constantes, reemplazables en pruebas).
  - `func nivel_completo(n: int) -> bool`, `func pct_nivel(n: int) -> float` (cuentan solo IDs de `misiones_nivel[n]`).
  - `func nivel_superado(n: int) -> bool`, `func nivel_desbloqueado(n: int) -> bool`.
  - Patrón de prueba de escena reutilizado por Tasks 6 y 8.

- [ ] **Step 1: Escribir la prueba que falla**

`tests/test_niveles.tscn`:
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/test_niveles.gd" id="1"]

[node name="TestNiveles" type="Node"]
script = ExtResource("1")
```

`tests/test_niveles.gd`:
```gdscript
# Prueba de NivelManager: misiones válidas por nivel y desbloqueo por legado.
# Correr: $GODOT --headless --path . res://tests/test_niveles.tscn
extends Node

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _nm_con(misiones: Dictionary) -> Node:
	var nm : Node = load("res://autoload/NivelManager.gd").new()
	nm._misiones = misiones
	return nm


func _ready() -> void:
	print("test_niveles")
	var nm : Node = _nm_con({})

	# Espejo: TOTAL_MISIONES coincide con las listas.
	for n in range(1, 7):
		_check(nm.TOTAL_MISIONES[n] == nm.MISIONES_NIVEL[n].size(),
			"TOTAL_MISIONES[%d] == MISIONES_NIVEL[%d].size()" % [n, n])

	# IDs que no pertenecen al nivel no cuentan.
	var basura := {}
	for i in 10:
		basura["no_es_del_nivel_%d" % i] = true
	nm = _nm_con({"1": basura})
	_check(not nm.nivel_completo(1), "IDs ajenos no completan el nivel 1")
	_check(is_equal_approx(nm.pct_nivel(1), 0.0), "IDs ajenos dan 0% en nivel 1")

	# Nivel completo con sus IDs válidos.
	var n1 := {}
	for id in nm.MISIONES_NIVEL[1]:
		n1[id] = true
	nm = _nm_con({"1": n1})
	_check(nm.nivel_completo(1), "nivel 1 completo con sus 6 IDs")
	_check(nm.nivel_desbloqueado(2), "nivel 2 desbloqueado")

	# Legado: el nivel cambió (IDs nuevos) pero ya se había superado.
	nm = _nm_con({"5": {"viejo_a": true, "viejo_b": true}})
	nm.misiones_nivel[5] = ["nuevo_a", "nuevo_b", "nuevo_c"]
	nm.misiones_legado[5] = ["viejo_a", "viejo_b"]
	for n in range(1, 5):
		var d := {}
		for id in nm.MISIONES_NIVEL[n]:
			d[id] = true
		nm._misiones[str(n)] = d
	_check(not nm.nivel_completo(5), "nivel 5 reabierto: no está completo")
	_check(nm.nivel_superado(5), "nivel 5 superado por legado")
	_check(nm.nivel_desbloqueado(6), "nivel 6 sigue desbloqueado por legado")
	_check(is_equal_approx(nm.pct_nivel(5), 0.0), "avance del nivel 5 nuevo en 0%")

	# Legado incompleto no desbloquea.
	nm._misiones["5"] = {"viejo_a": true}
	_check(not nm.nivel_superado(5), "legado incompleto no supera el nivel")
	_check(not nm.nivel_desbloqueado(6), "legado incompleto no desbloquea el 6")

	print("test_niveles: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `$GODOT --headless --path . res://tests/test_niveles.tscn; echo "exit=$?"`
Expected: errores de `MISIONES_NIVEL`/`nivel_superado` inexistentes y `exit=1` (o distinto de 0).

- [ ] **Step 3: Implementar en `autoload/NivelManager.gd`**

Debajo de `TOTAL_MISIONES`:
```gdscript
# IDs válidos de cada nivel. nivel_completo()/pct_nivel() cuentan SOLO estos:
# antes contaban cualquier misión guardada del nivel, así que al reemplazar
# misiones (Nivel 5 nuevo, minijuegos) las viejas seguirían contando.
# ESPEJO de public.catalogo_misiones (sql/puntaje_greenmetric.sql): si cambia
# uno, cambiar el otro, y también TOTAL_MISIONES.
const MISIONES_NIVEL : Dictionary = {
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

# Conjunto con el que cada nivel se consideraba completo ANTES de cambiarle
# las misiones. Quien ya lo había superado no pierde el desbloqueo del
# siguiente nivel aunque el nivel se reabra. Hoy es igual a MISIONES_NIVEL;
# el Nivel 5 nuevo y los minijuegos lo harán distinto.
const MISIONES_LEGADO : Dictionary = MISIONES_NIVEL

# Copias editables (las pruebas las reemplazan; el juego no las toca).
var misiones_nivel  : Dictionary = MISIONES_NIVEL.duplicate(true)
var misiones_legado : Dictionary = MISIONES_LEGADO.duplicate(true)
```

Reemplazar `nivel_desbloqueado`, `nivel_completo` y `pct_nivel` por:
```gdscript
func nivel_desbloqueado(n: int) -> bool:
	if n == 1: return true
	return nivel_superado(n - 1)

# Completo = todas las misiones ACTUALES del nivel. Se usa para nivel_actual
# y la celebración de "nivel completado".
func nivel_completo(n: int) -> bool:
	var ids : Array = misiones_nivel.get(n, [])
	if ids.is_empty(): return false
	return _contar_hechas(n, ids) >= ids.size()

# Superado = completo, o completo con el conjunto anterior (legado). Se usa
# SOLO para desbloquear el nivel siguiente.
func nivel_superado(n: int) -> bool:
	if nivel_completo(n): return true
	var legado : Array = misiones_legado.get(n, [])
	return not legado.is_empty() and _contar_hechas(n, legado) >= legado.size()

func pct_nivel(n: int) -> float:
	var ids : Array = misiones_nivel.get(n, [])
	if ids.is_empty(): return 0.0
	return float(_contar_hechas(n, ids)) / float(ids.size())

func _contar_hechas(n: int, ids: Array) -> int:
	var s := str(n)
	if not _misiones.has(s): return 0
	var hechas := 0
	var del_nivel : Dictionary = _misiones[s]
	for id in ids:
		if del_nivel.get(id, false):
			hechas += 1
	return hechas
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `$GODOT --headless --path . res://tests/test_niveles.tscn; echo "exit=$?"`
Expected: todas las líneas `ok`, `test_niveles: 0 fallos`, `exit=0`.

- [ ] **Step 5: Excluir `tests/` del export**

En `export_presets.cfg` cambiar:
`exclude_filter="*.json, *.md, docs/*, sql/*, supabase/*, .claude/*, .vscode/*"`
por
`exclude_filter="*.json, *.md, docs/*, sql/*, supabase/*, tests/*, .claude/*, .vscode/*"`

Run: `grep -n "exclude_filter" export_presets.cfg`
Expected: contiene `tests/*`.

- [ ] **Step 6: Commit**

```bash
git add autoload/NivelManager.gd tests/test_niveles.gd tests/test_niveles.tscn export_presets.cfg
git commit -m "puntaje (3/10): niveles cuentan solo misiones validas y respetan el legado

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: SupabaseManager — llamadas y señales del puntaje

**Files:**
- Modify: `autoload/SupabaseManager.gd` (señales cerca de la línea 50; funciones junto a `comprar_item`/`cargar_titulos_ranking`; ramas en `_on_respuesta_http` líneas ~420–455; procesadores junto a `_procesar_titulos`)

**Interfaces:**
- Consumes: funciones SQL de Task 3.
- Produces:
  - `signal puntaje_recibido(datos: Dictionary)` — el JSON de `puntaje_greenmetric()`.
  - `signal calidad_respuesta(respuesta: Dictionary, ctx: Dictionary)` — respuesta de `registrar_quiz|registrar_decision|registrar_sinergia`; `ctx.tipo ∈ {"quiz","decision","sinergia"}`; ante fallo de red/HTTP `respuesta = {"ok": false, "error": "red"|"http_<code>"}`.
  - `signal detalles_recibidos(detalles: Dictionary)` — `{clave: detalle}`; ante fallo emite `{}` con `push_warning`.
  - `func obtener_puntaje() -> void`
  - `func registrar_quiz(mision_id: String, aciertos: int) -> void`
  - `func registrar_decision(decision_id: String, opcion_id: String) -> void`
  - `func registrar_sinergia(accion_id: String) -> void`
  - `func guardar_detalle(clave: String, detalle: Dictionary) -> void`
  - `func obtener_detalles() -> void`

- [ ] **Step 1: Prueba que falla**

Crear `tests/test_compila.tscn` (misma estructura que `test_niveles.tscn`, script `res://tests/test_compila.gd`) y `tests/test_compila.gd`:
```gdscript
# Verifica que los scripts tocados por el proyecto A compilan y exponen su API.
# Correr: $GODOT --headless --path . res://tests/test_compila.tscn
extends Node

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_compila")
	var sm = get_node_or_null("/root/SupabaseManager")
	_check(sm != null, "SupabaseManager cargado como autoload")
	if sm:
		for f in ["obtener_puntaje", "registrar_quiz", "registrar_decision",
				  "registrar_sinergia", "guardar_detalle", "obtener_detalles"]:
			_check(sm.has_method(f), "SupabaseManager.%s existe" % f)
		for s in ["puntaje_recibido", "calidad_respuesta", "detalles_recibidos"]:
			_check(sm.has_signal(s), "SupabaseManager señal %s existe" % s)
	print("test_compila: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

Run: `$GODOT --headless --path . res://tests/test_compila.tscn; echo "exit=$?"`
Expected: `FALLA` en los métodos y señales nuevos, `exit=1`.

- [ ] **Step 2: Implementar**

Señales (después de `titulos_ranking_cargados`):
```gdscript
# ── Puntaje GreenMetric (ver sql/puntaje_greenmetric.sql) ────
# datos: {"categorias": {"1": {"avance","comprension","decisiones","sinergias","total"}, ...},
#         "total": float, "quizzes_hechos": [mision_id...]}
signal puntaje_recibido(datos: Dictionary)
# Respuesta de registrar_quiz/decision/sinergia. ctx.tipo: "quiz"|"decision"|"sinergia".
signal calidad_respuesta(respuesta: Dictionary, ctx: Dictionary)
# detalles: {clave: detalle}. {} si falló (el llamador tiene su propio timeout).
signal detalles_recibidos(detalles: Dictionary)
```

Funciones (después de `cargar_titulos_ranking`):
```gdscript
func obtener_puntaje() -> void:
	_rpc("puntaje", "puntaje_greenmetric", {})


func registrar_quiz(mision_id: String, aciertos: int) -> void:
	_rpc("calidad", "registrar_quiz", {"p_mision_id": mision_id, "p_aciertos": aciertos},
		 {"tipo": "quiz", "mision_id": mision_id})


func registrar_decision(decision_id: String, opcion_id: String) -> void:
	_rpc("calidad", "registrar_decision", {"p_decision_id": decision_id, "p_opcion_id": opcion_id},
		 {"tipo": "decision", "decision_id": decision_id, "opcion_id": opcion_id})


func registrar_sinergia(accion_id: String) -> void:
	_rpc("calidad", "registrar_sinergia", {"p_accion_id": accion_id},
		 {"tipo": "sinergia", "accion_id": accion_id})


func guardar_detalle(clave: String, detalle: Dictionary) -> void:
	_rpc("detalle", "guardar_detalle", {"p_clave": clave, "p_detalle": detalle}, {"clave": clave})


func obtener_detalles() -> void:
	_rpc("detalles", "obtener_detalles", {})
```

En `_on_respuesta_http`, rama de fallo de red, agregar después de la rama `comprar`:
```gdscript
		elif accion == "calidad":
			emit_signal("calidad_respuesta", {"ok": false, "error": "red"}, ctx)
		elif accion == "detalles":
			emit_signal("detalles_recibidos", {})
```

En el `match accion:` agregar:
```gdscript
		"puntaje"         : _procesar_puntaje(code, datos)
		"calidad"         : _procesar_calidad(code, datos, ctx)
		"detalle"         : _procesar_detalle(code, datos, ctx)
		"detalles"        : _procesar_detalles(code, datos)
```

Procesadores (después de `_procesar_titulos`):
```gdscript
func _procesar_puntaje(code: int, datos: Variant) -> void:
	if code == 200 and datos is Dictionary:
		emit_signal("puntaje_recibido", datos)
	else:
		push_error("SupabaseManager: falló puntaje_greenmetric (HTTP %d): %s"
			% [code, str(datos).substr(0, 200)])


func _procesar_calidad(code: int, datos: Variant, ctx: Dictionary) -> void:
	if code == 200 and datos is Dictionary:
		emit_signal("calidad_respuesta", datos, ctx)
	else:
		push_error("SupabaseManager: falló registro de calidad %s (HTTP %d): %s"
			% [str(ctx), code, str(datos).substr(0, 200)])
		emit_signal("calidad_respuesta", {"ok": false, "error": "http_%d" % code}, ctx)


# Un detalle que no se guardó no se pierde: queda en el archivo local de
# NivelManager y se vuelve a subir al iniciar sesión (ver PuntajeManager).
func _procesar_detalle(code: int, datos: Variant, ctx: Dictionary) -> void:
	if code != 200 or not (datos is Dictionary) or not bool(datos.get("ok", false)):
		push_warning("SupabaseManager: no se guardó el detalle '%s' (HTTP %d): %s"
			% [str(ctx.get("clave", "")), code, str(datos).substr(0, 200)])


func _procesar_detalles(code: int, datos: Variant) -> void:
	if code == 200 and datos is Dictionary:
		emit_signal("detalles_recibidos", datos)
	else:
		push_warning("SupabaseManager: falló obtener_detalles (HTTP %d)" % code)
		emit_signal("detalles_recibidos", {})
```

- [ ] **Step 3: Correr y verificar que pasa**

Run: `$GODOT --headless --path . res://tests/test_compila.tscn; echo "exit=$?"` y `$GODOT --headless --path . res://tests/test_niveles.tscn; echo "exit=$?"`
Expected: `0 fallos` y `exit=0` en ambas; sin `SCRIPT ERROR` ni `Parse Error` en la salida.

- [ ] **Step 4: Commit**

```bash
git add autoload/SupabaseManager.gd tests/test_compila.gd tests/test_compila.tscn
git commit -m "puntaje (4/10): llamadas y senales del puntaje en SupabaseManager

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: PuntajeManager — autoload y fórmula local

**Files:**
- Create: `autoload/puntaje_formula.gd`, `autoload/PuntajeManager.gd`
- Create: `tests/test_puntaje.gd`, `tests/test_puntaje.tscn`
- Modify: `project.godot` (`[autoload]`, después de `NivelManager`)
- Modify: `tests/test_compila.gd` (verificar el autoload)

**Interfaces:**
- Consumes: señales/funciones de Task 5; `NivelManager.pct_nivel(n)`, `NivelManager.mision_nivel_completada(nivel, mision_id)`, `NivelManager.ICONOS_NIVEL`; `SupabaseManager.progreso_guardado(mision_id, xp, ya, corr)`, `SupabaseManager.jwt_token`.
- Produces:
  - `puntaje_formula.gd` (sin autoloads, `extends RefCounted`): `const PESOS`, `const TOPES := {"avance": 80.0, "comprension": 10.0, "decisiones": 5.0, "sinergias": 5.0}`, `static func normalizar(datos: Dictionary) -> Dictionary`, `static func total_ponderado(categorias: Dictionary) -> float`, `static func con_avance(categoria: Dictionary, pct_misiones: float) -> Dictionary`.
  - Autoload `PuntajeManager`:
    - `signal puntaje_actualizado(categorias: Dictionary, total: float)` — `categorias` con claves `int` 1–6, cada valor `{"avance","comprension","decisiones","sinergias","total"}` en float.
    - `signal sinergia_obtenida(accion_id: String, categorias: Array)` — `[{"categoria": int, "puntos": int}]`.
    - `signal decision_resuelta(decision_id: String, opcion_id: String, respuesta: Dictionary)`.
    - `var categorias : Dictionary`, `var total : float`, `var cargado : bool`.
    - `func iniciar_sesion() -> void`
    - `func valor(cat: int) -> float` (0–100) y `func fraccion(cat: int) -> float` (0–1).
    - `func quiz_hecho(mision_id: String) -> bool`
    - `func registrar_quiz(mision_id: String, aciertos: int) -> void`
    - `func registrar_decision(decision_id: String, opcion_id: String) -> void`
    - `func registrar_sinergia(accion_id: String) -> void`
    - `func restaurar_detalles(detalles_servidor: Dictionary) -> void` (usado por Task 7)

- [ ] **Step 1: Prueba que falla**

`tests/test_puntaje.tscn` con script `res://tests/test_puntaje.gd`:
```gdscript
# Prueba de puntaje_formula.gd (espejo local del cálculo del servidor).
# Correr: $GODOT --headless --path . res://tests/test_puntaje.tscn
extends Node

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_puntaje")
	var F = load("res://autoload/puntaje_formula.gd")

	var datos := {"categorias": {
		"1": {"avance": 80, "comprension": 6.67, "decisiones": 0, "sinergias": 1, "total": 87.67},
		"2": {"avance": 80, "comprension": 10, "decisiones": 0, "sinergias": 0, "total": 90},
		"3": {"avance": 80, "comprension": 0, "decisiones": 0, "sinergias": 0, "total": 80},
		"4": {"avance": 80, "comprension": 0, "decisiones": 0, "sinergias": 0, "total": 80},
		"5": {"avance": 80, "comprension": 0, "decisiones": 0, "sinergias": 0, "total": 80},
		"6": {"avance": 0, "comprension": 0, "decisiones": 0, "sinergias": 0, "total": 0},
	}, "total": 69.35}
	var cats : Dictionary = F.normalizar(datos)
	_check(cats.has(1) and not cats.has("1"), "normalizar usa claves int")
	_check(cats[1]["total"] is float, "normalizar convierte a float")
	_check(cats.size() == 6, "normalizar devuelve las 6 categorías")
	var esperado := (87.67 * 15 + 90 * 21 + 80 * 18 + 80 * 10 + 80 * 18 + 0 * 18) / 100.0
	_check(is_equal_approx(F.total_ponderado(cats), esperado), "total ponderado con pesos de la guía")

	var vacio : Dictionary = F.normalizar({})
	_check(vacio.size() == 6 and is_equal_approx(vacio[3]["total"], 0.0), "sin datos: 6 categorías en 0")

	var con : Dictionary = F.con_avance(cats[6], 0.5)
	_check(is_equal_approx(con["avance"], 40.0), "con_avance: 50% de misiones = 40")
	_check(is_equal_approx(con["total"], 40.0), "con_avance recalcula el total")
	var tope : Dictionary = F.con_avance({"avance": 0, "comprension": 12, "decisiones": 9, "sinergias": -1}, 1.5)
	_check(is_equal_approx(tope["total"], 80.0 + 10.0 + 5.0 + 0.0), "con_avance respeta topes")

	print("test_puntaje: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
```

Run: `$GODOT --headless --path . res://tests/test_puntaje.tscn; echo "exit=$?"`
Expected: error al cargar `puntaje_formula.gd`, `exit` distinto de 0.

- [ ] **Step 2: Implementar `autoload/puntaje_formula.gd`**

```gdscript
# ============================================================
# puntaje_formula.gd — espejo local del cálculo de
# public._puntaje_greenmetric (sql/puntaje_greenmetric.sql).
# Solo se usa para mostrar el avance al instante mientras llega la
# respuesta del servidor, que es la fuente de verdad.
# Sin referencias a autoloads, para poder probarlo solo.
# ============================================================
extends RefCounted

const PESOS : Dictionary = {1: 15, 2: 21, 3: 18, 4: 10, 5: 18, 6: 18}
const TOPES : Dictionary = {"avance": 80.0, "comprension": 10.0, "decisiones": 5.0, "sinergias": 5.0}


static func _vacia() -> Dictionary:
	return {"avance": 0.0, "comprension": 0.0, "decisiones": 0.0, "sinergias": 0.0, "total": 0.0}


# {"categorias": {"1": {...}}} (JSON del servidor) -> {1: {... floats}, ... 6}
static func normalizar(datos: Dictionary) -> Dictionary:
	var fuente : Dictionary = datos.get("categorias", {})
	var out : Dictionary = {}
	for cat in PESOS.keys():
		var c : Dictionary = fuente.get(str(cat), {})
		var fila := _vacia()
		for k in TOPES.keys():
			fila[k] = float(c.get(k, 0.0))
		fila["total"] = float(c.get("total", 0.0))
		out[cat] = fila
	return out


static func total_ponderado(categorias: Dictionary) -> float:
	var suma := 0.0
	for cat in PESOS.keys():
		suma += float(categorias.get(cat, _vacia()).get("total", 0.0)) * float(PESOS[cat])
	return suma / 100.0


# Copia de la categoría con el avance recalculado desde el % de misiones
# local, con los mismos topes que el servidor.
static func con_avance(categoria: Dictionary, pct_misiones: float) -> Dictionary:
	var fila := _vacia()
	for k in TOPES.keys():
		fila[k] = clampf(float(categoria.get(k, 0.0)), 0.0, TOPES[k])
	fila["avance"] = clampf(pct_misiones, 0.0, 1.0) * TOPES["avance"]
	fila["total"] = fila["avance"] + fila["comprension"] + fila["decisiones"] + fila["sinergias"]
	return fila
```

- [ ] **Step 3: Correr la prueba de fórmula**

Run: `$GODOT --headless --path . res://tests/test_puntaje.tscn; echo "exit=$?"`
Expected: `test_puntaje: 0 fallos`, `exit=0`.

- [ ] **Step 4: Implementar `autoload/PuntajeManager.gd`**

```gdscript
# ============================================================
# PuntajeManager.gd — puntaje GreenMetric por categoría (0–100).
# Un solo número por categoría para todo el juego: HUD, mapa de calor,
# resultados e informe. Lo calcula el servidor (puntaje_greenmetric);
# acá se muestra el avance al instante y se alinea con cada respuesta.
# Diseño: docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md
#
# También sincroniza los "detalles" de NivelManager (decisiones con criterio
# propio) con el servidor: antes vivían solo en el archivo local.
# ============================================================
extends Node

const FORMULA := preload("res://autoload/puntaje_formula.gd")

signal puntaje_actualizado(categorias: Dictionary, total: float)
signal sinergia_obtenida(accion_id: String, categorias: Array)
signal decision_resuelta(decision_id: String, opcion_id: String, respuesta: Dictionary)

var categorias : Dictionary = FORMULA.normalizar({})
var total      : float      = 0.0
var cargado    : bool       = false

var _quizzes_hechos : Array = []
# Peticiones de puntaje en vuelo: se pide de nuevo solo cuando no hay otra
# esperando, para no encolar una por misión en ráfagas.
var _pidiendo : bool = false


func _ready() -> void:
	SupabaseManager.puntaje_recibido.connect(_on_puntaje_recibido)
	SupabaseManager.calidad_respuesta.connect(_on_calidad_respuesta)
	SupabaseManager.progreso_guardado.connect(_on_progreso_guardado)
	NivelManager.mision_nivel_completada.connect(_on_mision_completada)
	NivelManager.detalle_guardado.connect(_on_detalle_guardado)


func _hay_sesion() -> bool:
	return not SupabaseManager.jwt_token.is_empty()


# Lo llama SceneLogin al entrar: descarta lo de la cuenta anterior.
func iniciar_sesion() -> void:
	categorias = FORMULA.normalizar({})
	total = 0.0
	cargado = false
	_quizzes_hechos = []
	_pidiendo = false
	_recalcular_avance_local()
	if _hay_sesion():
		_pedir_puntaje()


func valor(cat: int) -> float:
	return float(categorias.get(cat, {}).get("total", 0.0))


func fraccion(cat: int) -> float:
	return clampf(valor(cat) / 100.0, 0.0, 1.0)


func quiz_hecho(mision_id: String) -> bool:
	return mision_id in _quizzes_hechos


func registrar_quiz(mision_id: String, aciertos: int) -> void:
	if _hay_sesion():
		SupabaseManager.registrar_quiz(mision_id, aciertos)


func registrar_decision(decision_id: String, opcion_id: String) -> void:
	if _hay_sesion():
		SupabaseManager.registrar_decision(decision_id, opcion_id)
	else:
		decision_resuelta.emit(decision_id, opcion_id, {"ok": false, "error": "sin_sesion"})


func registrar_sinergia(accion_id: String) -> void:
	if _hay_sesion():
		SupabaseManager.registrar_sinergia(accion_id)


# Une los detalles del servidor con los locales. El servidor gana en las
# claves que tiene; las que solo existen localmente (decisiones tomadas
# antes de que existiera detalles_estudiante, o guardados que fallaron) se
# suben una vez.
func restaurar_detalles(detalles_servidor: Dictionary) -> void:
	var locales : Dictionary = NivelManager.detalles_todos()
	for clave in locales.keys():
		if not detalles_servidor.has(clave) and _hay_sesion():
			SupabaseManager.guardar_detalle(str(clave), locales[clave])
	for clave in detalles_servidor.keys():
		if detalles_servidor[clave] is Dictionary:
			NivelManager.aplicar_detalle_servidor(str(clave), detalles_servidor[clave])


# ── Interno ───────────────────────────────────────────────────
func _pedir_puntaje() -> void:
	if _pidiendo: return
	_pidiendo = true
	SupabaseManager.obtener_puntaje()


func _aplicar(datos: Dictionary) -> void:
	categorias = FORMULA.normalizar(datos)
	total = float(datos.get("total", FORMULA.total_ponderado(categorias)))
	var hechos = datos.get("quizzes_hechos", [])
	if hechos is Array:
		_quizzes_hechos = hechos.duplicate()
	cargado = true
	puntaje_actualizado.emit(categorias, total)


func _recalcular_avance_local() -> void:
	for cat in FORMULA.PESOS.keys():
		categorias[cat] = FORMULA.con_avance(categorias[cat], NivelManager.pct_nivel(cat))
	total = FORMULA.total_ponderado(categorias)
	puntaje_actualizado.emit(categorias, total)


func _on_puntaje_recibido(datos: Dictionary) -> void:
	_pidiendo = false
	_aplicar(datos)


func _on_calidad_respuesta(respuesta: Dictionary, ctx: Dictionary) -> void:
	var tipo := str(ctx.get("tipo", ""))
	if respuesta.get("puntaje") is Dictionary:
		_aplicar(respuesta["puntaje"])
	if tipo == "sinergia" and bool(respuesta.get("nuevo", false)):
		var cats = respuesta.get("categorias", [])
		var lista : Array = cats if cats is Array else []
		sinergia_obtenida.emit(str(ctx.get("accion_id", "")), lista)
		# Telemetría (spec 6.5). nivel 0: una sinergia no es de un solo nivel.
		SupabaseManager.registrar_evento(0, str(ctx.get("accion_id", "")), "sinergia_obtenida",
			{"accion_id": str(ctx.get("accion_id", "")), "categorias": lista})
	elif tipo == "decision":
		decision_resuelta.emit(str(ctx.get("decision_id", "")), str(ctx.get("opcion_id", "")), respuesta)


# Muestra el avance ya; el servidor lo confirma cuando el guardado llega.
func _on_mision_completada(_nivel: int, _mision_id: String) -> void:
	_recalcular_avance_local()


func _on_progreso_guardado(_mision_id: String, _xp: int, _ya: bool, _corr: int) -> void:
	if _hay_sesion():
		_pedir_puntaje()


func _on_detalle_guardado(clave: String, detalle: Dictionary) -> void:
	if _hay_sesion():
		SupabaseManager.guardar_detalle(clave, detalle)
```

- [ ] **Step 5: Ganchos de detalles en `autoload/NivelManager.gd`**

Agregar la señal junto a las otras:
```gdscript
# Un detalle cambió localmente; PuntajeManager lo sube al servidor.
signal detalle_guardado(clave: String, detalle: Dictionary)
```
Reemplazar `guardar_detalle` y agregar dos funciones:
```gdscript
func guardar_detalle(mision_id: String, detalle: Dictionary) -> void:
	_detalles[mision_id] = detalle
	_guardar()
	detalle_guardado.emit(mision_id, detalle)

func detalles_todos() -> Dictionary:
	return _detalles.duplicate(true)

# Aplica un detalle que vino del servidor SIN volver a subirlo.
func aplicar_detalle_servidor(clave: String, detalle: Dictionary) -> void:
	_detalles[clave] = detalle
	_guardar()
```

- [ ] **Step 6: Registrar el autoload**

En `project.godot`, sección `[autoload]`, después de `NivelManager=...`:
```
PuntajeManager="*res://autoload/PuntajeManager.gd"
```

- [ ] **Step 7: Ampliar `tests/test_compila.gd`**

Antes del `print("test_compila: ...")`:
```gdscript
	var pm = get_node_or_null("/root/PuntajeManager")
	_check(pm != null, "PuntajeManager cargado como autoload")
	if pm:
		for f in ["iniciar_sesion", "valor", "fraccion", "quiz_hecho", "registrar_quiz",
				  "registrar_decision", "registrar_sinergia", "restaurar_detalles"]:
			_check(pm.has_method(f), "PuntajeManager.%s existe" % f)
		_check(pm.categorias.size() == 6, "PuntajeManager arranca con 6 categorías")
		_check(is_equal_approx(pm.valor(3), 0.0), "sin sesión el valor es 0")
	var nm = get_node_or_null("/root/NivelManager")
	_check(nm != null and nm.has_signal("detalle_guardado"), "NivelManager emite detalle_guardado")
```

- [ ] **Step 8: Correr las tres pruebas**

Run:
```bash
for t in test_puntaje test_niveles test_compila; do $GODOT --headless --path . res://tests/$t.tscn; echo "$t exit=$?"; done
```
Expected: `0 fallos` y `exit=0` en las tres.

- [ ] **Step 9: Commit**

```bash
git add autoload/puntaje_formula.gd autoload/PuntajeManager.gd autoload/NivelManager.gd project.godot tests/
git commit -m "puntaje (5/10): autoload PuntajeManager y formula local probada

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 7: Login — puntaje y detalles al entrar

**Files:**
- Modify: `scenes/login/SceneLogin.gd` (`_preparar_progreso_y_entrar`, ~línea 793; agregar `_esperar_detalles_con_timeout`)

**Interfaces:**
- Consumes: `SupabaseManager.obtener_detalles()`, `SupabaseManager.detalles_recibidos(detalles)`, `PuntajeManager.iniciar_sesion()`, `PuntajeManager.restaurar_detalles(detalles)`.
- Produces: al cambiar a `scene_mapa_mundo.tscn`, `NivelManager` tiene los detalles del servidor y `PuntajeManager` ya pidió el puntaje.

- [ ] **Step 1: Implementar**

Después del bloque de la billetera (antes de `var tw := create_tween()`):
```gdscript
	# Detalles (decisiones con criterio propio) y puntaje GreenMetric. Los
	# detalles se esperan con límite: el informe final los necesita y antes
	# vivían solo en esta computadora. El puntaje no se espera: el HUD se
	# actualiza solo cuando llega (PuntajeManager.puntaje_actualizado).
	var detalles = await _esperar_detalles_con_timeout()
	if detalles is Dictionary:
		PuntajeManager.restaurar_detalles(detalles)
	print("SceneLogin: detalles %s" % (
		"%d del servidor" % detalles.size() if detalles is Dictionary else "NO cargados a tiempo"))
	PuntajeManager.iniciar_sesion()
```

Nueva función (junto a `_esperar_billetera_con_timeout`), mismo patrón de Dictionary por referencia que `_cargar_misiones_con_timeout`:
```gdscript
# Devuelve {clave: detalle} o null si no llegó en 6 s.
func _esperar_detalles_con_timeout() -> Variant:
	var estado := {"resuelto": false, "resultado": null}
	var on_ok := func(d: Dictionary):
		estado["resuelto"]  = true
		estado["resultado"] = d
	SupabaseManager.detalles_recibidos.connect(on_ok, CONNECT_ONE_SHOT)
	SupabaseManager.obtener_detalles()
	var limite := Time.get_ticks_msec() + 6000
	while not estado["resuelto"] and Time.get_ticks_msec() < limite:
		await get_tree().process_frame
	if SupabaseManager.detalles_recibidos.is_connected(on_ok):
		SupabaseManager.detalles_recibidos.disconnect(on_ok)
	return estado["resultado"]
```

Nota: si el servidor falla, `detalles_recibidos` emite `{}` y `restaurar_detalles({})` sube los locales, lo cual es correcto (el servidor no tiene ninguno).

- [ ] **Step 2: Compilar**

Run: `$GODOT --headless --path . res://tests/test_compila.tscn; echo "exit=$?"`
Expected: `exit=0`, sin `SCRIPT ERROR`/`Parse Error`.

Run (escena de login carga sin errores): `$GODOT --headless --path . --quit-after 180 2>&1 | grep -E "SCRIPT ERROR|Parse Error" ; echo "grep_exit=$?"`
Expected: `grep_exit=1` (ninguna coincidencia).

- [ ] **Step 3: Commit**

```bash
git add scenes/login/SceneLogin.gd
git commit -m "puntaje (6/10): al iniciar sesion se restauran detalles y se pide el puntaje

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 8: Integración de UI — un solo número en todo el juego

**Files:**
- Modify: `scenes/mapa/SceneMapaMundo.gd` (líneas de referencia: 468, 495–514, 1012–1020, 1052–1060, 1565–1573, 1793–1815, 1843–1850, 1877–1900, 2128–2137, 2684–2890, 2700–2731)
- Modify: `scenes/mapa/mapa_campus.gd` (líneas 86–93)
- Modify: `autoload/EconomiaManager.gd` (líneas 11, 58–67, 325–345, 354–357)
- Modify: `scenes/ui/simulador_decision.gd` (~línea 189)
- Modify: `scenes/misiones/mision_movilidad.gd` (`_seleccionar` ~línea 230 y `_confirmar` ~línea 256)
- Modify: `scenes/misiones/mision_informe_final.gd` (líneas 15–17 y 109–114)
- Modify: `tests/test_compila.gd`

**Interfaces:**
- Consumes: `PuntajeManager.valor(cat)`, `PuntajeManager.fraccion(cat)`, `PuntajeManager.total`, señales `puntaje_actualizado` y `sinergia_obtenida`; `NivelManager.nivel_completo(n)`, `NivelManager.ICONOS_NIVEL`; `SceneMapaMundo._mostrar_notificacion_zona(icono: String, texto: String, color: Color)`.
- Produces: `SceneMapaMundo._refrescar_progreso()` (única vía para actualizar barras, índices del HUD y mapa de calor).

- [ ] **Step 1: Prueba que falla**

En `tests/test_compila.gd`, antes del `print` final:
```gdscript
	var em = get_node_or_null("/root/EconomiaManager")
	_check(em != null and not ("impacto" in em), "EconomiaManager ya no tiene ImpactRating")
	_check(em != null and not em.has_method("actualizar_impacto"), "actualizar_impacto eliminado")
	for ruta in ["res://scenes/mapa/SceneMapaMundo.gd", "res://scenes/mapa/mapa_campus.gd",
				 "res://scenes/ui/simulador_decision.gd", "res://scenes/misiones/mision_movilidad.gd",
				 "res://scenes/misiones/mision_informe_final.gd", "res://scenes/ui/resultados_greenmetric.gd"]:
		var s : Script = load(ruta)
		_check(s != null and s.can_instantiate(), "compila: %s" % ruta)
	var mapa : Script = load("res://scenes/mapa/SceneMapaMundo.gd")
	_check(mapa != null and mapa.get_script_method_list().any(func(m): return m["name"] == "_refrescar_progreso"),
		"SceneMapaMundo._refrescar_progreso existe")
```

Run: `$GODOT --headless --path . res://tests/test_compila.tscn; echo "exit=$?"`
Expected: `FALLA` en ImpactRating y `_refrescar_progreso`, `exit=1`.

- [ ] **Step 2: `SceneMapaMundo.gd` — función única de refresco**

Agregar junto a `_actualizar_sidebar()`:
```gdscript
# Única vía para actualizar barras de categoría, índices del HUD y mapa de
# calor. Todos leen PuntajeManager (avance 80 + comprensión 10 + decisiones 5
# + sinergias 5). Antes cada pantalla tenía su propio número (ImpactRating
# sin guardar, valores fijos del mapa de calor, % de misiones).
func _refrescar_progreso(_cats: Dictionary = {}, _total: float = 0.0) -> void:
	for mod_id in _progreso_modulos.keys():
		_progreso_modulos[mod_id] = PuntajeManager.fraccion(mod_id)
		if mapa_campus and mapa_campus.has_method("actualizar_modulo"):
			mapa_campus.actualizar_modulo(mod_id, _progreso_modulos[mod_id])
	_actualizar_sidebar()
	_actualizar_indicador_verde()
	_actualizar_indicador_agua()
	_actualizar_indicador_edu()


func _on_sinergia_obtenida(_accion_id: String, cats: Array) -> void:
	var nm = _nivel_mgr()
	var partes : PackedStringArray = []
	for c in cats:
		if c is Dictionary:
			var icono : String = nm.ICONOS_NIVEL[int(c.get("categoria", 0))] if nm else "•"
			partes.append("%s +%d" % [icono, int(c.get("puntos", 0))])
	_mostrar_notificacion_zona("✨", "Sinergia: " + "  ".join(partes), Color(0.75, 0.95, 1.0))
```

- [ ] **Step 3: `SceneMapaMundo.gd` — sembrado inicial y conexiones**

Reemplazar el sembrado de `_progreso_modulos` en `_ready` (líneas ~498–501):
```gdscript
	var nm_inicial = _nivel_mgr()
	if nm_inicial:
		for mod_id in _progreso_modulos.keys():
			_progreso_modulos[mod_id] = nm_inicial.pct_nivel(mod_id)
```
por:
```gdscript
	for mod_id in _progreso_modulos.keys():
		_progreso_modulos[mod_id] = PuntajeManager.fraccion(mod_id)
	PuntajeManager.puntaje_actualizado.connect(_refrescar_progreso)
	PuntajeManager.sinergia_obtenida.connect(_on_sinergia_obtenida)
```
y reemplazar las tres llamadas `_actualizar_indicador_verde()`, `_actualizar_indicador_agua()`, `_actualizar_indicador_edu()` que siguen a `_actualizar_hud()` por `_refrescar_progreso()`.

- [ ] **Step 4: `SceneMapaMundo.gd` — índices del HUD**

En `_actualizar_indicador_verde`, `_actualizar_indicador_agua` y `_actualizar_indicador_edu`, reemplazar
`var nm = _nivel_mgr()` / `if not nm: return` / `var pct : float = nm.pct_nivel(N)`
por `var pct : float = PuntajeManager.fraccion(N)` (N = 1, 4 y 6 respectivamente).

- [ ] **Step 5: `SceneMapaMundo.gd` — quitar los números sueltos**

Aplicar cada reemplazo (buscar por el texto, las líneas son orientativas):

1. Minijuego (~1016–1020): borrar las líneas desde `# Actualizar progreso M3 en sidebar` hasta `_actualizar_sidebar()` inclusive (`var pct`, `var prev`, `_progreso_modulos[3] = ...`).
2. NPC/quiz viejo (~1053–1060): borrar `mapa_campus.actualizar_modulo(mod_id, nuevo)` con su `if`, y `_progreso_modulos[mod_id] = nuevo` + `_actualizar_sidebar()`. Mantener `ZONA_A_MISION[zona_key]["progreso"] = nuevo` (lo usa la persistencia vieja de ese flujo).
3. Mejora de zona (~1570–1573): borrar `var nuevo ... prog_bon ...`, `_progreso_modulos[mod_id] = nuevo`, `_actualizar_sidebar()` (y `var mod_id` si queda sin uso).
4. `_on_crisis_resulta` (~1793): dejar solo
```gdscript
func _on_crisis_resulta(modulo_id: int, exito: bool) -> void:
	if exito:
		_aplicar_xp(25, "crisis_%d" % modulo_id)
		EconomiaManager.otorgar_insignia("crisis_resuelta")
	_timer_crisis = randf_range(_CRISIS_MIN, _CRISIS_MAX)
```
5. `_on_decision_tomada` (~1806): dejar solo
```gdscript
func _on_decision_tomada(_modulo_id: int, delta: float) -> void:
	if delta > 0.0:
		EconomiaManager.ganar_creditos(15, "decision")
```
6. `_on_zona_verde_adoptada` (~1845): borrar `var delta`, `var nuevo`, `_progreso_modulos[modulo_id] = nuevo`, `_actualizar_sidebar()` y el bloque `mapa_campus.actualizar_modulo`.
7. `_on_contenedor_vaciado` (~2133–2137): borrar desde `# Contribuye al progreso M3` hasta `_actualizar_sidebar()` inclusive.
8. Callbacks de misión de campo (~2691, 2739, 2753, 2767, 2781, 2796, 2811, 2825, 2839, 2854, 2869, 2884): en cada uno reemplazar el par
`_progreso_modulos[N] = pct` + `_actualizar_sidebar()` por `_refrescar_progreso()`, y borrar las llamadas `_actualizar_indicador_verde()`/`_agua()`/`_edu()` que queden inmediatamente después (ya las hace `_refrescar_progreso`). Mantener `var pct` porque `guardar_progreso(..., int(pct * 100), ...)` lo sigue usando.

- [ ] **Step 6: `SceneMapaMundo.gd` — resultados**

Reemplazar el cuerpo de `_verificar_misiones_completadas` (~1892):
```gdscript
func _verificar_misiones_completadas() -> void:
	var nm = _nivel_mgr()
	if not nm: return
	for mod_id in range(1, 7):
		if not nm.nivel_completo(mod_id):
			return
	if not _crises_desbloqueadas:
		_crises_desbloqueadas = true
		_timer_crisis = _CRISIS_MIN
	await get_tree().create_timer(1.5).timeout
	_abrir_resultados()
```

Run: `grep -n "_progreso_modulos\[" scenes/mapa/SceneMapaMundo.gd`
Expected: solo las dos asignaciones de `PuntajeManager.fraccion` (en `_ready` y `_refrescar_progreso`) y la lectura de `_actualizar_sidebar`.

- [ ] **Step 7: `mapa_campus.gd`**

Reemplazar el diccionario `impacto` (líneas 86–93) por:
```gdscript
# Se alimenta desde SceneMapaMundo._refrescar_progreso (PuntajeManager).
# Antes arrancaba con valores inventados (0.35, 0.40...).
var impacto : Dictionary = {
	1: 0.0, 2: 0.0, 3: 0.0,
	4: 0.0, 5: 0.0, 6: 0.0
}
```

- [ ] **Step 8: `EconomiaManager.gd`**

- Borrar `signal impacto_cambiado(...)`, el bloque `var impacto` con su comentario, y las funciones `actualizar_impacto`, `get_color_impacto`, `impacto_global` (sección `# ── ImpactRating`).
- En `on_modulo_completado` borrar la línea `actualizar_impacto(modulo_id, 0.15)`.

Run: `grep -rn "impacto_cambiado\|actualizar_impacto\|get_color_impacto\|impacto_global\|EconomiaManager.impacto" --include=*.gd .`
Expected: solo las referencias de los dos archivos del paso siguiente (antes de corregirlos), y ninguna después.

- [ ] **Step 9: `simulador_decision.gd` y `mision_movilidad.gd`**

`simulador_decision.gd` (~189):
```gdscript
	var pct : float = clampf(
		PuntajeManager.fraccion(int(_esc_actual["modulo"])) + delta, 0.0, 1.0)
```
`mision_movilidad.gd`, en `_seleccionar`:
```gdscript
	var pct : float = clampf(PuntajeManager.fraccion(5) + delta, 0.0, 1.0)
```
y en `_confirmar` borrar `EconomiaManager.actualizar_impacto(5, delta)` (este archivo se reemplaza entero en el proyecto B).

- [ ] **Step 10: `mision_informe_final.gd`**

Reemplazar el comentario y `const PESOS` (líneas 15–17) por:
```gdscript
# El puntaje sale de PuntajeManager (servidor), el mismo número que muestran
# el HUD y la pantalla de resultados.
```
y el cálculo (líneas ~109–114):
```gdscript
	_subtitulo("📊 Puntaje GreenMetric del campus")
	var score : float = PuntajeManager.total
	_score_lbl.text = "%.1f / 100" % score
```
(el resto — `var pos := 8` y los umbrales — queda igual).

- [ ] **Step 11: Pruebas**

Run:
```bash
for t in test_puntaje test_niveles test_compila; do $GODOT --headless --path . res://tests/$t.tscn; echo "$t exit=$?"; done
$GODOT --headless --path . --quit-after 180 2>&1 | grep -E "SCRIPT ERROR|Parse Error"; echo "grep_exit=$?"
```
Expected: tres `exit=0` y `grep_exit=1`.

- [ ] **Step 12: Commit**

```bash
git add scenes/mapa/SceneMapaMundo.gd scenes/mapa/mapa_campus.gd autoload/EconomiaManager.gd scenes/ui/simulador_decision.gd scenes/misiones/mision_movilidad.gd scenes/misiones/mision_informe_final.gd tests/test_compila.gd
git commit -m "puntaje (7/10): HUD, mapa de calor, resultados e informe usan un solo numero

Se elimina el ImpactRating que no se guardaba y los valores fijos del mapa
de calor. Aviso visible al ganar una sinergia.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 9: Quizzes y minijuego registran la Comprensión

**Files:**
- Modify: `scenes/ui/quiz_npc.gd` (`iniciar` ~350, `_responder` ~425, `_tiempo_se_acabo` ~510, `_finalizar` ~536)
- Modify: `scenes/ui/minijuego_residuos.gd` (`_terminar` ~164)

**Interfaces:**
- Consumes: `PuntajeManager.registrar_quiz(mision_id: String, aciertos: int)`, `PuntajeManager.quiz_hecho(mision_id: String) -> bool`.
- Produces: `respuesta_quiz` y `tiempo_agotado` con `detalle.intento_quiz` = 1 (primer intento) o 2 (repetición). **`intento_num` NO se toca**: ya guarda el número de pregunta (`_indice + 1`) y cambiarlo rompería la telemetría existente.

- [ ] **Step 1: `quiz_npc.gd`**

Agregar la variable junto a `_racha`:
```gdscript
var _aciertos  : int = 0
# 1 = primer intento (cuenta para la Comprensión), 2 = repetición.
var _intento   : int = 1
```
En `iniciar`, después de `_racha = 0`:
```gdscript
	_aciertos  = 0
	_intento   = 2 if PuntajeManager.quiz_hecho(mision_id) else 1
```
En `_responder`, dentro de `if acerto:` agregar `_aciertos += 1` como primera línea.
En `_responder`, dentro del diccionario `detalle` de `registrar_evento(_nivel, _mision_id, "respuesta_quiz", {...}, acerto, _indice + 1)`, agregar la clave `"intento_quiz": _intento,` después de `"xp_ganado"`. En `_tiempo_se_acabo`, cambiar el detalle `{"pregunta": str(q.get("pregunta", ""))}` por `{"pregunta": str(q.get("pregunta", "")), "intento_quiz": _intento}`. Los argumentos `acerto`/`false` y `_indice + 1` quedan igual.
En `_finalizar`, antes del primer `registrar_evento`:
```gdscript
	# El servidor guarda solo el primer intento (registrar_quiz); repetir el
	# quiz se juega igual pero no cambia la Comprensión.
	PuntajeManager.registrar_quiz(_mision_id, _aciertos)
```

- [ ] **Step 2: `minijuego_residuos.gd`**

En `_terminar`, después de `_activo = false`:
```gdscript
	# Es la Comprensión de Residuos (catalogo_misiones: tipo quiz, 10 ítems).
	PuntajeManager.registrar_quiz("mision_residuos_minijuego", _aciertos)
```

- [ ] **Step 3: Compilar**

En `tests/test_compila.gd` agregar a la lista de rutas del Task 8: `"res://scenes/ui/quiz_npc.gd"`, `"res://scenes/ui/minijuego_residuos.gd"`.

Run: `$GODOT --headless --path . res://tests/test_compila.tscn; echo "exit=$?"`
Expected: `exit=0`.

- [ ] **Step 4: Commit**

```bash
git add scenes/ui/quiz_npc.gd scenes/ui/minijuego_residuos.gd tests/test_compila.gd
git commit -m "puntaje (8/10): quizzes y minijuego de residuos registran la comprension

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 10: Verificación en juego, documentación y publicación

**Files:**
- Modify: `docs/ESTADO_PROYECTO.md` (secciones 3, 4, 8 y fecha)
- Modify: `docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md` (estado)
- Regenerate: `docs/juego/*` con `python scripts/exportar_web.py`

**Interfaces:**
- Consumes: todo lo anterior.
- Produces: build web publicable y documentación al día.

- [ ] **Step 1: Verificación de escritorio con la cuenta de prueba**

Correr el juego (`$GODOT --path .`), iniciar sesión con la cuenta de prueba (el controlador pide las credenciales al usuario si no las tiene; **si no hay credenciales, saltar a Step 2 y dejarlo anotado**). Verificar:
- Consola: `SceneLogin: detalles N del servidor`.
- Barra del HUD de cada categoría = `PuntajeManager.valor(cat)`; mismo valor en el mapa de calor y en resultados.
- Hacer un quiz dos veces: la Comprensión cambia solo la primera (consultar `select ref, puntos from puntos_calidad where user_id = 'aeb07ad1-0aee-4b03-b274-1c9bb0a04bc2'`).
- Tomar captura del HUD.

- [ ] **Step 2: Documentación**

`docs/ESTADO_PROYECTO.md`:
- Fecha: "Última actualización: 2026-09-14 (puntaje GreenMetric unificado — ver secciones 3, 4 y 8)".
- Sección 3: agregar `PuntajeManager` (qué hace) y que `EconomiaManager` ya no tiene ImpactRating.
- Sección 4: subsección "Puntaje GreenMetric (proyecto A)" con el modelo 80/10/5/5, tablas, funciones, la regla del primer intento, la regla Mixta y el espejo `catalogo_misiones` ↔ `NivelManager.MISIONES_NIVEL`.
- Sección 8: marcar resuelto "decisiones del Nivel 6 solo locales"; agregar pendientes B y C con enlace al spec, y "cuentas con niveles completos ven 80% hasta ganar calidad".

Spec: cambiar **Estado** a "Paso 0 y proyecto A implementados (2026-09-14); B y C pendientes".

- [ ] **Step 3: Export web**

Run: `python scripts/exportar_web.py`
Expected: termina sin error de `verificar_secretos()` y actualiza `docs/juego/index.html` con un nuevo `index.pck?v=<hash>`.

Run: `$GODOT --headless --path . --quit-after 60 2>&1 | grep -E "SCRIPT ERROR|Parse Error"; echo "grep_exit=$?"`
Expected: `grep_exit=1`.

- [ ] **Step 4: Commit**

```bash
git add docs/ESTADO_PROYECTO.md docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md docs/juego
git commit -m "puntaje (9/10): documentacion y build web del puntaje unificado

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

- [ ] **Step 5: Publicar (solo con OK del controlador)**

```bash
git push origin nivel-6-educacion-investigacion
git checkout main && git merge --ff-only nivel-6-educacion-investigacion && git push origin main
git checkout nivel-6-educacion-investigacion
```
Luego verificar que GitHub Pages sirva el nuevo `index.pck?v=<hash>` en `https://ereyes05.github.io/green-metric-urbe/juego/`.
