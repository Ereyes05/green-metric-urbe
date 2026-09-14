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
