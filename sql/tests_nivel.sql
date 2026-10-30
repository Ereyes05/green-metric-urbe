-- ============================================================
-- tests_nivel.sql — GreenMetric_URBE
-- Test al terminar cada nivel + test final, y el resumen que se le manda
-- al estudiante por correo (supabase/functions/enviar_resumen).
--
-- Lo pidió el jurado de la predefensa: comprobar, al cierre de cada nivel,
-- si al estudiante le quedó el mensaje. Es evaluación formativa del juego,
-- NO un instrumento de la investigación: no suma al puntaje GreenMetric
-- ni a la Comprensión (esa sale de los quizzes de NPC, registrar_quiz).
--
-- Las preguntas salen del banco validado por la Dirección de
-- Sostenibilidad (2026-10-15): el cliente arma el test con
-- QUIZ_POR_MISION. Acá solo se guarda cuántas acertó.
--
-- REGISTRO, NO SCRIPT: copia de la migración aplicada.
-- ============================================================

-- ── Migración: tests_nivel ───────────────────────────────────
create table if not exists public.resultados_test (
  user_id           uuid not null references auth.users(id) on delete cascade,
  test_id           text not null check (test_id ~ '^(nivel_[1-6]|final)$'),
  aciertos          int  not null check (aciertos >= 0),
  total             int  not null check (total between 1 and 12 and aciertos <= total),
  respondido_at     timestamptz not null default now(),
  -- Lo marca la Edge Function al mandar el correo: evita mandarlo dos veces.
  correo_enviado_at timestamptz,
  primary key (user_id, test_id)
);

alter table public.resultados_test enable row level security;

drop policy if exists resultados_test_propios on public.resultados_test;
create policy resultados_test_propios on public.resultados_test
  for select to authenticated using (user_id = auth.uid());

-- Solo cuenta el primer intento, igual que registrar_quiz: repetir el test
-- no cambia lo que ya quedó guardado.
create or replace function public.registrar_test(p_test_id text, p_aciertos int, p_total int)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user  uuid := auth.uid();
  v_filas int;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  if p_test_id is null or p_test_id !~ '^(nivel_[1-6]|final)$' then
    return jsonb_build_object('ok', false, 'error', 'test_inexistente');
  end if;
  if p_total is null or p_total < 1 or p_total > 12
     or p_aciertos is null or p_aciertos < 0 or p_aciertos > p_total then
    return jsonb_build_object('ok', false, 'error', 'aciertos_fuera_de_rango');
  end if;
  insert into resultados_test (user_id, test_id, aciertos, total)
  values (v_user, p_test_id, p_aciertos, p_total)
  on conflict (user_id, test_id) do nothing;
  get diagnostics v_filas = row_count;
  return jsonb_build_object('ok', true, 'registrado', v_filas > 0, 'test_id', p_test_id);
end;
$$;

-- Migración 2 (2026-10-30): tests_nivel_elegibles. ESTADO: PENDIENTE DE APLICAR.
-- El test es "al terminar el nivel": a quien ya había completado niveles
-- antes de que existieran los tests no se le piden. "elegibles" son los
-- niveles completos (catálogo ACTUAL, tipo 'mision', misma regla que
-- ranking_publico) cuya última misión se hizo desde el día en que se
-- publicaron los tests. Los que se completan durante la sesión los agrega
-- el cliente al vuelo.
create or replace function public.obtener_tests()
returns jsonb language sql stable security definer set search_path to 'public' as $$
  with totales as (
    select categoria, count(*) as total
    from catalogo_misiones where tipo = 'mision' group by categoria
  ), hechas as (
    select cm.categoria, count(distinct me.mision_id) as n, max(me.completada_at) as ultima
    from misiones_estudiante me
    join catalogo_misiones cm on cm.mision_id = me.mision_id and cm.tipo = 'mision'
    where me.user_id = auth.uid()
    group by cm.categoria
  )
  select jsonb_build_object(
    'tests', (select coalesce(jsonb_object_agg(test_id, jsonb_build_object(
                'aciertos', aciertos, 'total', total)), '{}'::jsonb)
              from resultados_test where user_id = auth.uid()),
    'elegibles', (select coalesce(jsonb_agg(h.categoria order by h.categoria), '[]'::jsonb)
                  from hechas h join totales t using (categoria)
                  where h.n >= t.total and h.ultima >= timestamptz '2026-10-30 00:00:00-04'))
$$;

-- Todo lo que lleva el correo, en una sola llamada. Solo para service_role
-- (la Edge Function): recibe el user_id, así que un estudiante no puede
-- pedir el resumen de otro.
-- Misiones por nivel: misma regla que ranking_publico (catálogo ACTUAL,
-- tipo 'mision').
create or replace function public.resumen_estudiante(p_user uuid)
returns jsonb language sql stable security definer set search_path to 'public' as $$
  with totales as (
    select categoria, count(*) as total
    from catalogo_misiones where tipo = 'mision' group by categoria
  ), hechas as (
    select cm.categoria, count(distinct me.mision_id) as n
    from misiones_estudiante me
    join catalogo_misiones cm on cm.mision_id = me.mision_id and cm.tipo = 'mision'
    where me.user_id = p_user
    group by cm.categoria
  ), posiciones as (
    select id, rank() over (order by coalesce(xp_total, 0) desc) as puesto
    from estudiantes
  )
  select jsonb_build_object(
    'nombre',    (select nombre from estudiantes where id = p_user),
    'xp',        (select coalesce(xp_total, 0) from estudiantes where id = p_user),
    'puesto',    (select puesto from posiciones where id = p_user),
    'jugadores', (select count(*) from estudiantes),
    'ecocredits', _saldo_ecocredits(p_user),
    'puntaje',   _puntaje_greenmetric(p_user),
    'niveles',   (select coalesce(jsonb_object_agg(t.categoria::text, jsonb_build_object(
                    'hechas', coalesce(h.n, 0), 'total', t.total)), '{}'::jsonb)
                  from totales t left join hechas h using (categoria)),
    'tests',     (select coalesce(jsonb_object_agg(test_id, jsonb_build_object(
                    'aciertos', aciertos, 'total', total)), '{}'::jsonb)
                  from resultados_test where user_id = p_user),
    'insignias', (select coalesce(jsonb_agg(c.icono || ' ' || c.nombre order by c.orden), '[]'::jsonb)
                  from insignias_obtenidas io
                  join catalogo_insignias c on c.insignia_id = io.insignia_id
                  where io.user_id = p_user)
  )
$$;

revoke execute on function public.registrar_test(text, int, int) from public, anon;
revoke execute on function public.obtener_tests()                 from public, anon;
revoke execute on function public.resumen_estudiante(uuid)        from public, anon, authenticated;
grant  execute on function public.registrar_test(text, int, int) to authenticated;
grant  execute on function public.obtener_tests()                 to authenticated;
grant  execute on function public.resumen_estudiante(uuid)        to service_role;

-- Rollback:
-- drop function if exists public.resumen_estudiante(uuid);
-- drop function if exists public.obtener_tests();
-- drop function if exists public.registrar_test(text, int, int);
-- drop table if exists public.resultados_test;
