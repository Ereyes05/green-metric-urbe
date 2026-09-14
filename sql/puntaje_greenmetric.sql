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
