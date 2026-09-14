-- ============================================================
-- tienda_ecocredits.sql — GreenMetric_URBE
-- HU-012 "Gestionar EcoCredits en la tienda" (Cap. 4 de la tesis).
-- Aplicada el 2026-09-14 con apply_migration (Supabase MCP).
--
-- Hasta acá los EcoCredits vivían solo en memoria (EconomiaManager) y
-- volvían a 50 cada vez que se abría el juego, así que no había forma de
-- tener una tienda. Diseño aprobado por el usuario:
--
-- - Registro de movimientos en vez de un saldo suelto: el saldo es la suma
--   de los movimientos. Cada ganancia y cada gasto queda con su motivo, lo
--   que además deja evidencia de "toma de decisiones" para la variable de
--   empoderamiento de la tesis.
-- - El cliente NO puede escribir estas tablas: todo pasa por las funciones
--   de abajo, que validan precio, saldo y no-recompra del lado del servidor.
-- - Cada movimiento tiene un `ref` único por usuario, lo que hace a todas
--   las operaciones idempotentes (reintentar no cobra ni paga dos veces).
-- ============================================================

-- ── Catálogo ─────────────────────────────────────────────────
create table if not exists public.catalogo_tienda (
  item_id        text primary key,
  nombre         text not null,
  descripcion    text not null,
  icono          text not null default '',
  tipo           text not null check (tipo in ('herramienta', 'bonificacion', 'avatar')),
  modulo_id      int,
  precio         int  not null check (precio > 0),
  -- Tipo de misión que exige esta herramienta ('solar', 'captacion',
  -- 'bicicletero'); null = ítem opcional.
  requerido_para text,
  orden          int  not null default 0,
  activo         boolean not null default true
);

-- ── Movimientos (el saldo es la suma de delta) ───────────────
create table if not exists public.movimientos_ecocredits (
  id        bigint generated always as identity primary key,
  user_id   uuid not null references auth.users(id) on delete cascade,
  delta     int  not null check (delta <> 0),
  motivo    text not null,
  ref       text not null,
  creado_en timestamptz not null default now(),
  unique (user_id, ref)
);
create index if not exists idx_mov_ec_user on public.movimientos_ecocredits (user_id);

-- ── Inventario (la PK impide recomprar) ──────────────────────
create table if not exists public.inventario_estudiante (
  user_id     uuid not null references auth.users(id) on delete cascade,
  item_id     text not null references public.catalogo_tienda(item_id),
  comprado_en timestamptz not null default now(),
  primary key (user_id, item_id)
);

-- ── RLS y privilegios ────────────────────────────────────────
alter table public.catalogo_tienda        enable row level security;
alter table public.movimientos_ecocredits enable row level security;
alter table public.inventario_estudiante  enable row level security;

create policy "Catalogo visible" on public.catalogo_tienda
  for select using (activo);
create policy "Ver movimientos propios" on public.movimientos_ecocredits
  for select using (auth.uid() = user_id);
create policy "Ver inventario propio" on public.inventario_estudiante
  for select using (auth.uid() = user_id);

-- Supabase da por defecto todos los privilegios a anon/authenticated sobre
-- las tablas de public. Sin políticas de escritura RLS ya lo bloquea, pero
-- se revoca explícito: saldo e inventario cambian SOLO vía las funciones.
revoke all on public.catalogo_tienda        from anon, authenticated;
revoke all on public.movimientos_ecocredits from anon, authenticated;
revoke all on public.inventario_estudiante  from anon, authenticated;
grant select on public.catalogo_tienda        to anon, authenticated;
grant select on public.movimientos_ecocredits to authenticated;
grant select on public.inventario_estudiante  to authenticated;

-- ── Funciones internas (no invocables desde el cliente) ──────
-- EC por misión de campo según el módulo. Espejo de
-- NivelManager.EC_POR_MISION: si cambia uno, hay que cambiar el otro.
create or replace function public._ec_por_modulo(p_modulo_id int)
returns int language sql immutable as $$
  select case p_modulo_id
    when 1 then 15 when 2 then 20 when 3 then 12
    when 4 then 12 when 5 then 12 when 6 then 20 else 0 end
$$;

create or replace function public._saldo_ecocredits(p_user uuid)
returns int language sql stable as $$
  select coalesce(sum(delta), 0)::int
  from public.movimientos_ecocredits where user_id = p_user
$$;

-- Bono inicial de 50 EC (lo que el juego daba siempre). Idempotente.
create or replace function public._asegurar_bono_inicial(p_user uuid)
returns void language sql as $$
  insert into public.movimientos_ecocredits (user_id, delta, motivo, ref)
  values (p_user, 50, 'bono_inicial', 'bono_inicial')
  on conflict (user_id, ref) do nothing
$$;

-- ── obtener_billetera: saldo, inventario y mejoras de zona ───
-- Las mejoras de zona se devuelven porque su nivel NO se guarda en otro
-- lado: si el EC gastado persiste pero el nivel de la zona no, el
-- estudiante perdería lo pagado al volver a entrar. El cliente reconstruye
-- el nivel de cada zona a partir de estos refs.
create or replace function public.obtener_billetera()
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  perform _asegurar_bono_inicial(v_user);
  return jsonb_build_object(
    'saldo', _saldo_ecocredits(v_user),
    'inventario', coalesce((select jsonb_agg(item_id order by comprado_en)
                              from inventario_estudiante where user_id = v_user), '[]'::jsonb),
    'refs_zonas', coalesce((select jsonb_agg(ref order by creado_en)
                              from movimientos_ecocredits
                             where user_id = v_user and motivo in ('mejora_zona', 'adopcion_zona')),
                           '[]'::jsonb)
  );
end;
$$;

-- ── acreditar_mision: paga una misión de campo UNA sola vez ──
-- Solo paga misiones que el servidor ya tiene registradas como completadas
-- (las registra guardar_progreso_modulo), con el monto que decide el
-- servidor. El cliente no elige cuánto cobra.
create or replace function public.acreditar_mision(p_mision_id text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user   uuid := auth.uid();
  v_modulo int;
  v_ec     int;
  v_nuevo  boolean := false;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;

  select modulo_id into v_modulo from misiones_estudiante
   where user_id = v_user and mision_id = trim(p_mision_id);
  if v_modulo is null then
    return jsonb_build_object('ok', false, 'error', 'mision_no_registrada',
                              'saldo', _saldo_ecocredits(v_user));
  end if;

  v_ec := _ec_por_modulo(v_modulo);
  if v_ec <= 0 then
    return jsonb_build_object('ok', false, 'error', 'modulo_sin_recompensa',
                              'saldo', _saldo_ecocredits(v_user));
  end if;

  perform _asegurar_bono_inicial(v_user);
  -- Termo reutilizable: +10% de EcoCredits por misión.
  if exists (select 1 from inventario_estudiante
              where user_id = v_user and item_id = 'termo_reutilizable') then
    v_ec := round(v_ec * 1.10);
  end if;

  insert into movimientos_ecocredits (user_id, delta, motivo, ref)
  values (v_user, v_ec, 'mision', 'mision:' || trim(p_mision_id))
  on conflict (user_id, ref) do nothing;
  get diagnostics v_nuevo = row_count;

  return jsonb_build_object('ok', true,
                            'acreditado', case when v_nuevo then v_ec else 0 end,
                            'saldo', _saldo_ecocredits(v_user));
end;
$$;

-- ── sumar_ecocredits: fuentes que no son misiones de campo ───
-- Minijuego, decisiones del simulador, adopción de zonas y papeleras.
-- Confiadas al cliente (mismo modelo que el XP, ver ESTADO_PROYECTO.md
-- sección 6), pero acotadas: motivo de una lista cerrada, monto máximo por
-- evento, e idempotentes por ref.
create or replace function public.sumar_ecocredits(p_delta int, p_motivo text, p_ref text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user  uuid := auth.uid();
  v_nuevo boolean := false;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  if p_motivo is null or p_motivo not in ('minijuego', 'decision', 'adopcion_zona', 'contenedor') then
    return jsonb_build_object('ok', false, 'error', 'motivo_invalido', 'saldo', _saldo_ecocredits(v_user));
  end if;
  if p_delta is null or p_delta < 1 or p_delta > 50 then
    return jsonb_build_object('ok', false, 'error', 'monto_invalido', 'saldo', _saldo_ecocredits(v_user));
  end if;
  if p_ref is null or trim(p_ref) = '' then
    return jsonb_build_object('ok', false, 'error', 'ref_requerida', 'saldo', _saldo_ecocredits(v_user));
  end if;

  perform _asegurar_bono_inicial(v_user);
  insert into movimientos_ecocredits (user_id, delta, motivo, ref)
  values (v_user, p_delta, p_motivo, p_motivo || ':' || trim(p_ref))
  on conflict (user_id, ref) do nothing;
  get diagnostics v_nuevo = row_count;

  return jsonb_build_object('ok', true,
                            'acreditado', case when v_nuevo then p_delta else 0 end,
                            'saldo', _saldo_ecocredits(v_user));
end;
$$;

-- ── gastar_ecocredits: recuperar energía y mejorar zonas ─────
create or replace function public.gastar_ecocredits(p_monto int, p_motivo text, p_ref text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user  uuid := auth.uid();
  v_saldo int;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  if p_motivo is null or p_motivo not in ('energia', 'mejora_zona') then
    return jsonb_build_object('ok', false, 'error', 'motivo_invalido', 'saldo', _saldo_ecocredits(v_user));
  end if;
  if p_monto is null or p_monto < 1 or p_monto > 500 then
    return jsonb_build_object('ok', false, 'error', 'monto_invalido', 'saldo', _saldo_ecocredits(v_user));
  end if;
  if p_ref is null or trim(p_ref) = '' then
    return jsonb_build_object('ok', false, 'error', 'ref_requerida', 'saldo', _saldo_ecocredits(v_user));
  end if;

  -- Serializa las operaciones de saldo de este estudiante: dos gastos
  -- simultáneos no pueden dejar el saldo negativo.
  perform pg_advisory_xact_lock(hashtext('billetera:' || v_user::text));
  perform _asegurar_bono_inicial(v_user);
  v_saldo := _saldo_ecocredits(v_user);
  if v_saldo < p_monto then
    return jsonb_build_object('ok', false, 'error', 'saldo_insuficiente', 'saldo', v_saldo);
  end if;

  insert into movimientos_ecocredits (user_id, delta, motivo, ref)
  values (v_user, -p_monto, p_motivo, p_motivo || ':' || trim(p_ref))
  on conflict (user_id, ref) do nothing;

  return jsonb_build_object('ok', true, 'saldo', _saldo_ecocredits(v_user));
end;
$$;

-- ── comprar_item: la compra de HU-012 ────────────────────────
-- Criterios de aceptación de la tesis, validados acá y no en el cliente:
-- saldo nunca negativo, precio fijo (sale del catálogo, no del cliente),
-- no se recompra lo ya adquirido.
create or replace function public.comprar_item(p_item_id text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user   uuid := auth.uid();
  v_precio int;
  v_saldo  int;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(hashtext('billetera:' || v_user::text));
  perform _asegurar_bono_inicial(v_user);
  v_saldo := _saldo_ecocredits(v_user);

  select precio into v_precio from catalogo_tienda where item_id = p_item_id and activo;
  if v_precio is null then
    return jsonb_build_object('ok', false, 'error', 'item_inexistente', 'saldo', v_saldo);
  end if;
  if exists (select 1 from inventario_estudiante where user_id = v_user and item_id = p_item_id) then
    return jsonb_build_object('ok', false, 'error', 'ya_comprado', 'saldo', v_saldo);
  end if;
  if v_saldo < v_precio then
    return jsonb_build_object('ok', false, 'error', 'saldo_insuficiente',
                              'saldo', v_saldo, 'precio', v_precio);
  end if;

  insert into inventario_estudiante (user_id, item_id) values (v_user, p_item_id);
  insert into movimientos_ecocredits (user_id, delta, motivo, ref)
  values (v_user, -v_precio, 'compra', 'compra:' || p_item_id);

  return jsonb_build_object('ok', true, 'item_id', p_item_id, 'saldo', _saldo_ecocredits(v_user));
end;
$$;

-- ── titulos_ranking: quién tiene el título, para el ranking ──
-- Pública (el ranking se carga sin sesión). Solo expone user_id y el
-- nombre del título, nada del saldo ni del resto del inventario.
create or replace function public.titulos_ranking()
returns jsonb language sql stable security definer set search_path to 'public' as $$
  select coalesce(jsonb_agg(jsonb_build_object('user_id', i.user_id, 'titulo', c.nombre)), '[]'::jsonb)
  from inventario_estudiante i
  join catalogo_tienda c on c.item_id = i.item_id
  where c.item_id = 'titulo_embajador'
$$;

-- ── Permisos de ejecución ────────────────────────────────────
revoke execute on function public._ec_por_modulo(int)            from public, anon, authenticated;
revoke execute on function public._saldo_ecocredits(uuid)         from public, anon, authenticated;
revoke execute on function public._asegurar_bono_inicial(uuid)    from public, anon, authenticated;
revoke execute on function public.obtener_billetera()             from public, anon;
revoke execute on function public.acreditar_mision(text)          from public, anon;
revoke execute on function public.sumar_ecocredits(int, text, text) from public, anon;
revoke execute on function public.gastar_ecocredits(int, text, text) from public, anon;
revoke execute on function public.comprar_item(text)              from public, anon;
grant  execute on function public.obtener_billetera()             to authenticated;
grant  execute on function public.acreditar_mision(text)          to authenticated;
grant  execute on function public.sumar_ecocredits(int, text, text) to authenticated;
grant  execute on function public.gastar_ecocredits(int, text, text) to authenticated;
grant  execute on function public.comprar_item(text)              to authenticated;
grant  execute on function public.titulos_ranking()               to anon, authenticated;

-- ── Catálogo inicial (aprobado por el usuario el 2026-09-14) ─
-- Precio de cada herramienta obligatoria < EC que dan las misiones del
-- mismo nivel que NO la necesitan, para que nadie quede trabado:
--   kit_solar      100 < 6 LED       x 20 = 120
--   kit_captacion   60 < 6 llaves    x 12 =  72
--   kit_bicicletero 60 < 6 decisiones x 12 = 72
insert into public.catalogo_tienda
  (item_id, nombre, descripcion, icono, tipo, modulo_id, precio, requerido_para, orden)
values
  ('kit_solar', 'Kit de instalación solar',
   'Herramientas para montar paneles solares. Necesario para las misiones de paneles solares del Nivel 2.',
   '☀', 'herramienta', 2, 100, 'solar', 1),
  ('kit_captacion', 'Kit de captación pluvial',
   'Tanques y canaletas para recoger agua de lluvia. Necesario para las misiones de captación del Nivel 4.',
   '💧', 'herramienta', 4, 60, 'captacion', 2),
  ('kit_bicicletero', 'Kit de bicicletero',
   'Estructura y candados para instalar bicicleteros. Necesario para las misiones de bicicleteros del Nivel 5.',
   '🚲', 'herramienta', 5, 60, 'bicicletero', 3),
  ('termo_reutilizable', 'Termo reutilizable',
   'Menos plástico de un solo uso: +10% de EcoCredits en cada misión.',
   '🌿', 'bonificacion', null, 80, null, 4),
  ('credencial_voluntario', 'Credencial de voluntario',
   'Tu compromiso cuenta más: +10% de experiencia en cada misión.',
   '⭐', 'bonificacion', null, 120, null, 5),
  ('estela_hojas', 'Estela de hojas',
   'Tu Eco-Ranger deja un rastro de hojas al caminar.',
   '🌱', 'avatar', null, 90, null, 6),
  ('titulo_embajador', 'Embajador GreenMetric',
   'Título que aparece junto a tu nombre en el ranking.',
   '🏆', 'avatar', null, 150, null, 7)
on conflict (item_id) do nothing;

-- ── EcoCredits retroactivos (aprobado por el usuario) ────────
-- Bono inicial para todas las cuentas, y el EC de cada misión de campo que
-- ya figura completada. Los EC ganados antes por minijuego, decisiones o
-- papeleras no se pueden reconstruir: nunca se guardaron en el servidor.
-- Usa los mismos refs que usarán las funciones, así que no hay doble pago.
insert into public.movimientos_ecocredits (user_id, delta, motivo, ref)
select u.id, 50, 'bono_inicial', 'bono_inicial' from auth.users u
on conflict (user_id, ref) do nothing;

insert into public.movimientos_ecocredits (user_id, delta, motivo, ref)
select m.user_id, public._ec_por_modulo(m.modulo_id), 'mision', 'mision:' || m.mision_id
from public.misiones_estudiante m
where public._ec_por_modulo(m.modulo_id) > 0
on conflict (user_id, ref) do nothing;

-- ── Segunda migración: tienda_ecocredits_search_path ─────────
-- Aviso del linter de Supabase (function_search_path_mutable): las
-- funciones internas de la tienda no fijaban search_path. Solo las invocan
-- funciones SECURITY DEFINER que sí lo fijan y el cliente no puede
-- ejecutarlas, pero se fija igual por higiene.
alter function public._ec_por_modulo(int)         set search_path to 'public';
alter function public._saldo_ecocredits(uuid)      set search_path to 'public';
alter function public._asegurar_bono_inicial(uuid) set search_path to 'public';

-- ── Tercera migración: tienda_ecocredits_fuentes_faltantes ───
-- Al adaptar el cliente aparecieron fuentes de EC que no estaban en las
-- listas cerradas de motivos, y que el servidor habría rechazado:
--   ganancias: bonus por completar un nivel (XP_NIVEL_BONUS / 5, máx. 50),
--              regar una planta (+8), quizzes (XP / 5)
--   gastos:    el evento de la misión Semana Verde (hasta 264 EC)
create or replace function public.sumar_ecocredits(p_delta int, p_motivo text, p_ref text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user  uuid := auth.uid();
  v_nuevo boolean := false;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  if p_motivo is null or p_motivo not in
     ('minijuego', 'decision', 'adopcion_zona', 'contenedor', 'nivel', 'riego', 'quiz') then
    return jsonb_build_object('ok', false, 'error', 'motivo_invalido', 'saldo', _saldo_ecocredits(v_user));
  end if;
  if p_delta is null or p_delta < 1 or p_delta > 50 then
    return jsonb_build_object('ok', false, 'error', 'monto_invalido', 'saldo', _saldo_ecocredits(v_user));
  end if;
  if p_ref is null or trim(p_ref) = '' then
    return jsonb_build_object('ok', false, 'error', 'ref_requerida', 'saldo', _saldo_ecocredits(v_user));
  end if;

  perform _asegurar_bono_inicial(v_user);
  insert into movimientos_ecocredits (user_id, delta, motivo, ref)
  values (v_user, p_delta, p_motivo, p_motivo || ':' || trim(p_ref))
  on conflict (user_id, ref) do nothing;
  get diagnostics v_nuevo = row_count;

  return jsonb_build_object('ok', true,
                            'acreditado', case when v_nuevo then p_delta else 0 end,
                            'saldo', _saldo_ecocredits(v_user));
end;
$$;

create or replace function public.gastar_ecocredits(p_monto int, p_motivo text, p_ref text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare
  v_user  uuid := auth.uid();
  v_saldo int;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;
  if p_motivo is null or p_motivo not in ('energia', 'mejora_zona', 'semana_verde') then
    return jsonb_build_object('ok', false, 'error', 'motivo_invalido', 'saldo', _saldo_ecocredits(v_user));
  end if;
  if p_monto is null or p_monto < 1 or p_monto > 500 then
    return jsonb_build_object('ok', false, 'error', 'monto_invalido', 'saldo', _saldo_ecocredits(v_user));
  end if;
  if p_ref is null or trim(p_ref) = '' then
    return jsonb_build_object('ok', false, 'error', 'ref_requerida', 'saldo', _saldo_ecocredits(v_user));
  end if;

  perform pg_advisory_xact_lock(hashtext('billetera:' || v_user::text));
  perform _asegurar_bono_inicial(v_user);
  v_saldo := _saldo_ecocredits(v_user);
  if v_saldo < p_monto then
    return jsonb_build_object('ok', false, 'error', 'saldo_insuficiente', 'saldo', v_saldo);
  end if;

  insert into movimientos_ecocredits (user_id, delta, motivo, ref)
  values (v_user, -p_monto, p_motivo, p_motivo || ':' || trim(p_ref))
  on conflict (user_id, ref) do nothing;

  return jsonb_build_object('ok', true, 'saldo', _saldo_ecocredits(v_user));
end;
$$;

-- Retroactivo del bonus por nivel completado (aprobado junto con el resto
-- del retroactivo: "calcularlos del progreso"). Un nivel cuenta como
-- completo si el estudiante tiene todas sus misiones de campo registradas.
-- Los montos son XP_NIVEL_BONUS / 5 de NivelManager; la cantidad de
-- misiones es TOTAL_MISIONES. Verificado el 2026-09-14 que todas las filas
-- de misiones_estudiante son misiones de campo, así que contar filas es
-- correcto. El ref 'nivel:N' coincide con el que usa el cliente.
insert into public.movimientos_ecocredits (user_id, delta, motivo, ref)
select m.user_id,
       case m.modulo_id when 1 then 30 when 2 then 50 when 3 then 36
                        when 4 then 36 when 5 then 36 when 6 then 40 end,
       'nivel', 'nivel:' || m.modulo_id
from public.misiones_estudiante m
group by m.user_id, m.modulo_id
having count(*) >= case m.modulo_id when 1 then 6 when 2 then 8 when 3 then 6
                                     when 4 then 8 when 5 then 8 when 6 then 4 end
on conflict (user_id, ref) do nothing;

-- ── Cuarta migración: tienda_descripciones_sin_repetir ───────
-- La tienda ya muestra "Necesaria para ..." en una nota aparte (a partir de
-- requerido_para); la misma frase dentro de la descripción quedaba repetida.
update public.catalogo_tienda set descripcion = 'Herramientas para montar paneles solares en los techos del campus.'
 where item_id = 'kit_solar';
update public.catalogo_tienda set descripcion = 'Tanques y canaletas para recoger y aprovechar el agua de lluvia.'
 where item_id = 'kit_captacion';
update public.catalogo_tienda set descripcion = 'Estructura y candados para instalar bicicleteros seguros.'
 where item_id = 'kit_bicicletero';
