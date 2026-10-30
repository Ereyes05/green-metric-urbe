-- ============================================================
-- crisis_penalizacion.sql — GreenMetric_URBE
-- HU-008 (Tabla 26 del Cap. 4): fallar una crisis ambiental resta 1 punto
-- al módulo afectado, sin bajar de 0; resolver la siguiente crisis de ese
-- módulo lo devuelve. Es la "penalización inmediata" de la Tabla 15.
--
-- La penalización no se acumula: como máximo 1 punto por módulo, mientras
-- quede una crisis sin resolver. Así el puntaje sigue acotado entre 0 y 100.
--
-- ESPEJO: autoload/puntaje_formula.gd (campo "crisis").
--
-- ESTADO: APLICADA en producción el 2026-10-30.
-- ============================================================

create table if not exists public.crisis_pendientes (
  user_id   uuid not null references auth.users(id) on delete cascade,
  categoria int  not null check (categoria between 1 and 6),
  creado_en timestamptz not null default now(),
  primary key (user_id, categoria)
);

alter table public.crisis_pendientes enable row level security;
create policy "Crisis pendientes propias" on public.crisis_pendientes
  for select using (auth.uid() = user_id);
revoke insert, update, delete on public.crisis_pendientes from anon, authenticated;

-- Única vía de escritura: el cliente informa el resultado, el servidor decide.
create or replace function public.registrar_crisis(p_categoria int, p_resuelta boolean)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  if p_categoria is null or p_categoria not between 1 and 6 then
    return jsonb_build_object('ok', false, 'error', 'categoria_invalida');
  end if;
  if p_resuelta then
    delete from crisis_pendientes where user_id = v_user and categoria = p_categoria;
  else
    insert into crisis_pendientes (user_id, categoria) values (v_user, p_categoria)
    on conflict (user_id, categoria) do nothing;
  end if;
  return jsonb_build_object('ok', true, 'puntaje', _puntaje_greenmetric(v_user));
end;
$$;

revoke execute on function public.registrar_crisis(int, boolean) from public, anon;
grant  execute on function public.registrar_crisis(int, boolean) to authenticated;

-- Mismo cálculo que en puntaje_greenmetric.sql, más la penalización.
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
           round(greatest(0, least(5, coalesce(q.sin, 0))), 2)                        as sinergias,
           case when exists (select 1 from crisis_pendientes p
                              where p.user_id = p_user and p.categoria = k.categoria)
                then 1 else 0 end                                                     as crisis
      from cats k
      left join av a using (categoria)
      left join pq q using (categoria)
  ),
  tot as (
    select *, greatest(0, avance + comprension + decisiones + sinergias - crisis) as total
      from calc
  )
  select jsonb_build_object(
    'categorias', jsonb_object_agg(categoria::text, jsonb_build_object(
        'avance', avance, 'comprension', comprension,
        'decisiones', decisiones, 'sinergias', sinergias,
        'crisis', crisis, 'total', total)),
    'total', round(sum(total * peso / 100.0), 2),
    'quizzes_hechos', coalesce((
        select jsonb_agg(substr(ref, 6)) from puntos_calidad
         where user_id = p_user and componente = 'comprension'), '[]'::jsonb))
  from tot;
$$;

revoke execute on function public._puntaje_greenmetric(uuid) from public, anon, authenticated;
