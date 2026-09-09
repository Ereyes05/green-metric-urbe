-- ============================================================
-- solicitudes_qr.sql — GreenMetric_URBE
-- Ejecutar en el SQL Editor del proyecto de Supabase.
--
-- Soporte de la mecánica "escaneá el QR para llamar al servicio de
-- limpieza" (zona_reciclaje.gd, Nivel 3). El cliente crea una fila con
-- un token random al mostrar el QR; una Edge Function pública
-- (marcar_escaneado, ver supabase/functions/marcar_escaneado/index.ts)
-- la marca escaneado=true cuando alguien abre el link del QR desde su
-- teléfono, SIN estar logueado en el juego. El cliente detecta el
-- cambio consultando esta tabla cada 1-2 segundos.
--
-- La Edge Function usa la service_role key (bypassa RLS) para poder
-- escribir sin sesión — por eso no hace falta ninguna policy de
-- UPDATE para anon/authenticated: nadie más que la Edge Function
-- puede marcar el escaneo.
-- ============================================================

create table if not exists public.solicitudes_qr (
  token        text primary key,
  user_id      uuid    not null references auth.users(id) on delete cascade,
  mision_id    text    not null,
  escaneado    boolean not null default false,
  creado_en    timestamptz not null default now(),
  escaneado_en timestamptz
);

alter table public.solicitudes_qr enable row level security;

-- El estudiante crea su propia solicitud al mostrar el QR.
drop policy if exists "Crear solicitud propia" on public.solicitudes_qr;
create policy "Crear solicitud propia" on public.solicitudes_qr
  for insert with check ((select auth.uid()) = user_id);

-- El estudiante consulta su propia solicitud mientras espera el escaneo.
drop policy if exists "Ver solicitud propia" on public.solicitudes_qr;
create policy "Ver solicitud propia" on public.solicitudes_qr
  for select using ((select auth.uid()) = user_id);

-- Sin esto, authenticated no tiene select/insert de verdad aunque la
-- policy exista — misma lección de misiones_estudiante (2026-09-02):
-- una tabla creada por SQL crudo no hereda privilegios por defecto.
grant select, insert on public.solicitudes_qr to authenticated;

-- Nadie (ni authenticated ni anon) puede actualizar o borrar desde el
-- cliente — ninguna policy de update/delete, y sin grant tampoco.
-- Solo la Edge Function con la service_role key puede marcar el
-- escaneo real.

create index if not exists idx_solicitudes_qr_user
  on public.solicitudes_qr (user_id);
