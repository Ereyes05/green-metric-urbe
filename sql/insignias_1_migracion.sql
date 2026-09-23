-- ============================================================
-- PASO 1 — MIGRACIÓN (esta es la que crea todo)
-- GreenMetric_URBE — insignias
--
-- Panel: https://supabase.com/dashboard/project/ikohikbpvtbvsgyumvbr/sql/new
-- Abrí este archivo, seleccioná TODO (Ctrl+A), copiá (Ctrl+C), pegalo en el
-- editor y dale Run. Al terminar debe decir "Success. No rows returned".
-- ============================================================

-- POR QUÉ: el Cap. 4 afirma que hay "un motor de reglas en el backend que
-- dispare diferentes tipos de insignias" (Tabla 6) y que se integraron
-- "guardándolas en su perfil" (Fase III). Hasta ahora vivían en memoria del
-- cliente y se perdían al cerrar el juego. Acá el servidor las DERIVA de lo
-- que ya tiene guardado, así que el estudiante no puede otorgarse ninguna.

-- ── Catálogo (en el servidor, no en el cliente) ──────────────
create table if not exists public.catalogo_insignias (
  insignia_id text primary key,
  nombre      text not null,
  icono       text not null,
  descripcion text not null,
  orden       int  not null default 0
);

insert into public.catalogo_insignias (insignia_id, nombre, icono, descripcion, orden) values
  ('m1_completo',    'Guardián Verde',   '🌿', 'Completaste todas las misiones de Entorno e Infraestructura.', 1),
  ('m2_completo',    'Ahorrista Solar',  '⚡', 'Completaste todas las misiones de Energía y Cambio Climático.', 2),
  ('m3_completo',    'Eco Clasificador', '♻',  'Completaste todas las misiones de Manejo de Residuos.',        3),
  ('m4_completo',    'Gota Vital',       '💧', 'Completaste todas las misiones de Uso del Agua.',              4),
  ('m5_completo',    'Ciclista Campus',  '🚲', 'Completaste todas las misiones de Transporte.',                5),
  ('m6_completo',    'EcoInvestigador',  '📚', 'Completaste todas las misiones de Educación e Investigación.', 6),
  ('quiz_perfecto',  'Puntaje Perfecto', '⭐', 'Respondiste un quiz completo sin fallar ninguna pregunta.',     7),
  ('crisis_resuelta','Héroe de Crisis',  '🚨', 'Resolviste correctamente una crisis ambiental del campus.',    8),
  ('racha_fuego',    'Racha Ardiente',   '🔥', 'Jugaste tres días seguidos.',                                  9),
  ('ecolider',       'EcoLíder URBE',    '🏆', 'Obtuviste todas las demás insignias.',                        10)
on conflict (insignia_id) do update
  set nombre = excluded.nombre, icono = excluded.icono,
      descripcion = excluded.descripcion, orden = excluded.orden;

-- ── Insignias obtenidas ──────────────────────────────────────
-- Nombre propio para no chocar con la `insignias_estudiante` vieja del panel
-- (ver PASO 0). La PK impide otorgar dos veces la misma.
create table if not exists public.insignias_obtenidas (
  user_id     uuid not null references auth.users(id) on delete cascade,
  insignia_id text not null references public.catalogo_insignias(insignia_id),
  obtenida_en timestamptz not null default now(),
  primary key (user_id, insignia_id)
);

create index if not exists insignias_obtenidas_user_idx
  on public.insignias_obtenidas (user_id);

-- ── RLS ──────────────────────────────────────────────────────
alter table public.catalogo_insignias  enable row level security;
alter table public.insignias_obtenidas enable row level security;

drop policy if exists "Catalogo de insignias visible" on public.catalogo_insignias;
create policy "Catalogo de insignias visible" on public.catalogo_insignias
  for select using (true);

drop policy if exists "Ver insignias propias" on public.insignias_obtenidas;
create policy "Ver insignias propias" on public.insignias_obtenidas
  for select using (auth.uid() = user_id);

-- El cliente NUNCA escribe acá: solo la función de abajo, que es la que
-- decide. Sin política de insert/update, RLS ya lo bloquea; se revoca
-- explícito igual, mismo criterio que la tienda.
revoke insert, update, delete on public.insignias_obtenidas from anon, authenticated;
revoke insert, update, delete on public.catalogo_insignias  from anon, authenticated;

-- ── El motor de reglas ───────────────────────────────────────
-- Devuelve el conjunto de insignias que el estudiante SE GANÓ según lo que
-- el servidor ya tiene guardado. No recibe nada del cliente.
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
  having count(*) >= 3;
$$;

-- Evalúa, guarda las nuevas y devuelve TODAS las del estudiante.
-- `nuevas` sirve para que el juego avise solo por las recién ganadas.
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

  -- ecolider depende de las demás, así que se evalúa después de insertarlas.
  if (select count(*) from insignias_obtenidas
       where user_id = v_user and insignia_id <> 'ecolider')
     >= (select count(*) - 1 from catalogo_insignias) then
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
               'obtenida_en', i.obtenida_en)
             order by c.orden)
        from insignias_obtenidas i
        join catalogo_insignias c on c.insignia_id = i.insignia_id
       where i.user_id = v_user), '[]'::jsonb),
    'catalogo', coalesce((
      select jsonb_agg(jsonb_build_object(
               'insignia_id', insignia_id, 'nombre', nombre,
               'icono', icono, 'descripcion', descripcion)
             order by orden)
        from catalogo_insignias), '[]'::jsonb));
end;
$$;

-- ── Permisos ─────────────────────────────────────────────────
revoke execute on function public._insignias_merecidas(uuid) from public, anon, authenticated;
revoke execute on function public.evaluar_insignias()        from public;
grant  execute on function public.evaluar_insignias()        to authenticated;

-- ════════════════════════════════════════════════════════════
-- FIN DEL PASO 1
-- ════════════════════════════════════════════════════════════
