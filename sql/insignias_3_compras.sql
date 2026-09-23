-- ============================================================
-- PASO 3 — INSIGNIAS QUE SE CANJEAN CON ECOCREDITS
-- GreenMetric_URBE — insignias
--
-- Panel: https://supabase.com/dashboard/project/ikohikbpvtbvsgyumvbr/sql/new
-- Abrí este archivo, seleccioná TODO (Ctrl+A), copiá (Ctrl+C), pegalo en el
-- editor y dale Run. Al terminar debe decir "Success. No rows returned".
--
-- REQUIERE que insignias_1_migracion.sql ya esté aplicada.
-- ============================================================
--
-- POR QUÉ: la Tabla 14 del Cap. 4 (instrumento a la experta del Depto. de
-- Sustentabilidad) elige, con el 100% de la respuesta, un "Sistema de
-- Eco-puntos acumulables para canjear por insignias digitales de estatus
-- dentro del perfil".
--
-- Hoy los EcoCredits se canjean por ítems de la tienda. Dos de ellos son
-- exactamente eso —estatus, sin efecto mecánico— pero vivían solo como
-- entradas del inventario, no como insignias del perfil:
--
--   estela_hojas      tipo 'avatar'  90 EC   rastro de hojas al caminar
--   titulo_embajador  tipo 'avatar' 150 EC   título junto al nombre
--
-- Con esto, comprarlos otorga además su insignia, y la frase de la Tabla 14
-- pasa a ser literal: se canjean Eco-puntos por una insignia del perfil.
--
-- Los ítems de tipo 'herramienta' y 'bonificacion' NO dan insignia: tienen
-- efecto mecánico (habilitan misiones, dan bonos) y no son estatus.
-- ============================================================


-- ── Distinguir las que se compran de las que se ganan ────────
-- ecolider exige "todas las demás". Sin esta marca, haría falta gastar
-- 240 EC en cosméticos para conseguirla, que no es la idea.
alter table public.catalogo_insignias
  add column if not exists por_compra boolean not null default false;

insert into public.catalogo_insignias
  (insignia_id, nombre, icono, descripcion, orden, por_compra)
values
  ('estela_hojas',     'Estela de Hojas',       '🌱',
   'Canjeaste EcoCredits por el rastro de hojas de tu Eco-Ranger.', 11, true),
  ('titulo_embajador', 'Embajador GreenMetric', '🏆',
   'Canjeaste EcoCredits por el título que acompaña tu nombre en el ranking.', 12, true)
on conflict (insignia_id) do update
  set nombre = excluded.nombre, icono = excluded.icono,
      descripcion = excluded.descripcion, orden = excluded.orden,
      por_compra = excluded.por_compra;


-- ── El motor, ahora también mirando el inventario ────────────
create or replace function public._insignias_merecidas(p_user uuid)
returns table (insignia_id text)
language sql stable security definer set search_path to 'public' as $$
  -- m1..m6: todas las misiones de la categoría (no los quizzes) completadas.
  select 'm' || c.categoria || '_completo'
    from catalogo_misiones c
   where c.tipo in ('mision', 'minijuego')
   group by c.categoria
  having count(*) = count(*) filter (
           where exists (select 1 from misiones_estudiante m
                          where m.user_id = p_user and m.mision_id = c.mision_id))

  union
  -- quiz_perfecto: un quiz con 3 respuestas o más y ninguna incorrecta.
  select 'quiz_perfecto'
    from eventos_aprendizaje e
   where e.user_id = p_user and e.tipo_evento = 'respuesta_quiz'
   group by e.mision_id
  having count(*) >= 3 and count(*) filter (where e.correcto is false) = 0

  union
  -- crisis_resuelta: al menos una crisis respondida bien.
  select 'crisis_resuelta'
   where exists (select 1 from eventos_aprendizaje e
                  where e.user_id = p_user
                    and e.tipo_evento = 'crisis_resuelta' and e.correcto is true)

  union
  -- racha_fuego: tres días calendario seguidos con actividad. La resta entre
  -- la fecha y su número de fila es constante dentro de una racha.
  select 'racha_fuego'
    from (select d, d - (row_number() over (order by d))::int as grupo
            from (select distinct creado_en::date as d
                    from eventos_aprendizaje where user_id = p_user) f) g
   group by grupo
  having count(*) >= 3

  union
  -- Canjeadas con EcoCredits: el item_id de la tienda y el insignia_id son
  -- el mismo texto a propósito, para que no haga falta una tabla puente.
  select i.item_id
    from inventario_estudiante i
    join catalogo_insignias ci on ci.insignia_id = i.item_id and ci.por_compra
   where i.user_id = p_user;
$$;


-- ── evaluar_insignias: ecolider ignora las compradas ─────────
create or replace function public.evaluar_insignias()
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user   uuid := auth.uid();
  v_nuevas text[];
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(hashtext('insignias:' || v_user::text));

  with ganadas as (
    insert into insignias_obtenidas (user_id, insignia_id)
    select v_user, m.insignia_id from _insignias_merecidas(v_user) m
    on conflict (user_id, insignia_id) do nothing
    returning insignia_id
  )
  select coalesce(array_agg(insignia_id), '{}') into v_nuevas from ganadas;

  -- ecolider corona el juego, no la tienda: solo cuenta las que se ganan
  -- jugando (por_compra = false).
  if (select count(*) from insignias_obtenidas i
        join catalogo_insignias c on c.insignia_id = i.insignia_id
       where i.user_id = v_user and not c.por_compra and c.insignia_id <> 'ecolider')
     >= (select count(*) - 1 from catalogo_insignias where not por_compra) then
    insert into insignias_obtenidas (user_id, insignia_id)
    values (v_user, 'ecolider')
    on conflict (user_id, insignia_id) do nothing;
    if found then
      v_nuevas := v_nuevas || 'ecolider';
    end if;
  end if;

  return jsonb_build_object(
    'nuevas', to_jsonb(v_nuevas),
    'todas', coalesce((
      select jsonb_agg(jsonb_build_object(
               'insignia_id', c.insignia_id, 'nombre', c.nombre,
               'icono', c.icono, 'descripcion', c.descripcion,
               'por_compra', c.por_compra,
               'obtenida_en', i.obtenida_en)
             order by c.orden)
        from insignias_obtenidas i
        join catalogo_insignias c on c.insignia_id = i.insignia_id
       where i.user_id = v_user), '[]'::jsonb),
    'catalogo', coalesce((
      select jsonb_agg(jsonb_build_object(
               'insignia_id', insignia_id, 'nombre', nombre,
               'icono', icono, 'descripcion', descripcion,
               'por_compra', por_compra)
             order by orden)
        from catalogo_insignias), '[]'::jsonb));
end;
$$;

revoke execute on function public._insignias_merecidas(uuid) from public, anon, authenticated;
revoke execute on function public.evaluar_insignias()        from public;
grant  execute on function public.evaluar_insignias()        to authenticated;
