-- ============================================================
-- eventos_aprendizaje.sql — GreenMetric_URBE
-- Ejecutar UNA VEZ en el SQL Editor del proyecto de Supabase
-- (https://supabase.com/dashboard/project/<tu-proyecto>/sql/new).
--
-- Registro de PROCESO de aprendizaje (cada elección, acierto, fallo
-- e intento, con timestamp) — complementa a progreso_estudiante, que
-- solo guarda el resultado final por módulo. Ver commit
-- "telemetría de aprendizaje" en autoload/SupabaseManager.gd para
-- el código que escribe en esta tabla (SupabaseManager.registrar_evento).
--
-- Para analizar los datos como investigador: consulta esta tabla desde
-- el SQL Editor o la API de Supabase con tu propia sesión de owner del
-- proyecto (el service_role key, no el anon key) — eso ignora las
-- políticas RLS de abajo, que solo restringen al cliente del juego.
-- ============================================================

create table eventos_aprendizaje (
  id           bigint generated always as identity primary key,
  user_id      uuid references auth.users(id),
  session_id   text not null,        -- una por cada vez que se abre el juego
  nivel        int  not null,
  mision_id    text not null,
  -- Sin CHECK a propósito: la lista crece y no vale la pena migrar la
  -- tabla cada vez. Valores en uso al 2026-09-11:
  --   'mision_iniciada'    — el estudiante abre una misión
  --   'mision_completada'  — la termina
  --   'respuesta_quiz'     — responde una pregunta (correcto + intento_num
  --                          + segundos que tardó + racha)
  --   'tiempo_agotado'     — se le venció el tiempo de una pregunta
  --                          (distinto de responder mal)
  --   'opcion_elegida'     — elige una opción en un simulador de decisión
  --   'opcion_quitada'     — deshace una elección
  --   'crisis_resuelta'    — responde a un evento de crisis ambiental
  --   'servicio_solicitado'— llama al servicio de limpieza por QR
  --                          (detalle.via: escaneado | omitido | timeout)
  tipo_evento  text not null,
  correcto     boolean,              -- null si no aplica (ej. mision_iniciada)
  intento_num  int,                  -- 1er intento, 2do, etc. (para medir aprendizaje por repetición)
  detalle      jsonb,                -- texto de la opción elegida, costo, alcance, etc.
  creado_en    timestamptz not null default now()
);

-- Para que cada estudiante solo pueda insertar/leer sus propios eventos
-- desde el juego (cliente anon + su propio JWT).
alter table eventos_aprendizaje enable row level security;

create policy "insertar_propios_eventos" on eventos_aprendizaje
  for insert with check (auth.uid() = user_id);

create policy "leer_propios_eventos" on eventos_aprendizaje
  for select using (auth.uid() = user_id);

-- Las políticas RLS dicen QUIÉN puede hacer qué, pero no otorgan el
-- privilegio de base. En este proyecto el privilegio ya existe (verificado
-- el 2026-09-14 en information_schema: son los privilegios por defecto que
-- Supabase da a las tablas de public), así que esta línea hoy es redundante.
-- Se deja explícita porque no siempre se hereda — a misiones_estudiante le
-- faltaba el 2026-09-02 — y porque es idempotente: correrla de nuevo no
-- rompe nada.
grant select, insert on public.eventos_aprendizaje to authenticated;

-- índice para consultas típicas de análisis ("evolución de X por usuario/misión")
create index idx_eventos_user_mision on eventos_aprendizaje (user_id, mision_id, creado_en);
