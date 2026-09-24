-- ============================================================
-- metricas_microlearning.sql — GreenMetric_URBE
--
-- Mide la Tabla 9 del Cap. 4 con los datos que el sistema ya guarda.
-- Es SOLO LECTURA: no crea ni modifica nada.
--
-- CÓMO USARLA
--   1. Abrí https://supabase.com/dashboard/project/ikohikbpvtbvsgyumvbr/sql/new
--   2. Seleccioná TODO este archivo (Ctrl+A), copiá, pegá y Run.
--   3. Pasame la tabla que salga.
-- ============================================================
--
-- QUÉ PROMETE LA TABLA 9: *"el rango ideal de interacción continua por sesión
-- debe situarse entre los 10 y los 15 minutos"* y *"Las lecciones teóricas y
-- los minijuegos asociados no deben requerir más de 15 minutos de
-- concentración ininterrumpida para completarse"*.
--
-- QUÉ SE PUEDE MEDIR DE VERDAD. Son dos cosas distintas y conviene no
-- confundirlas:
--
--   A) DURACIÓN DE CADA MISIÓN — de 'mision_iniciada' a 'mision_completada'.
--      Es la medición FIABLE y es la que corresponde a la segunda frase, que
--      es la afirmación concreta ("no deben requerir más de 15 minutos para
--      completarse"). Esta es la que hay que reportar.
--
--   B) DURACIÓN DE CADA SESIÓN — del primer al último evento de un session_id.
--      **Este número infla.** Si el estudiante deja la pestaña abierta y se va
--      a almorzar, la sesión "dura" tres horas sin que haya jugado. Sirve como
--      contexto, no como prueba de nada. Se incluye igual, con esa advertencia,
--      porque conviene mirarlo antes de citarlo.
--
-- OJO CON LA MUESTRA: al 2026-09-20 había 143 eventos de 2 estudiantes, y uno
-- era el desarrollador probando. Si los números salen de pocos casos, se
-- reportan como casos, no como promedios: con n chico un promedio engaña.
-- El bloque 4 dice de cuántos casos sale cada número, justamente para eso.
-- ============================================================

with misiones as (
  -- Una fila por intento de misión dentro de una sesión.
  select user_id, session_id, mision_id, nivel,
         min(creado_en) filter (where tipo_evento = 'mision_iniciada')   as inicio,
         max(creado_en) filter (where tipo_evento = 'mision_completada') as fin
    from eventos_aprendizaje
   group by user_id, session_id, mision_id, nivel
),
completadas as (
  select *, extract(epoch from (fin - inicio)) / 60.0 as minutos
    from misiones
   where inicio is not null and fin is not null and fin > inicio
),
sesiones as (
  select session_id, user_id,
         extract(epoch from (max(creado_en) - min(creado_en))) / 60.0 as minutos,
         count(*) as eventos
    from eventos_aprendizaje
   group by session_id, user_id
)

-- ── A) Lo que de verdad prueba la Tabla 9 ────────────────────
select 'A. duración de misiones' as bloque,
       'misiones completadas medidas' as dato,
       count(*)::text as valor
  from completadas
union all
select 'A. duración de misiones', 'minutos: la más rápida',
       coalesce(round(min(minutos)::numeric, 1)::text, 'sin datos') from completadas
union all
select 'A. duración de misiones', 'minutos: promedio',
       coalesce(round(avg(minutos)::numeric, 1)::text, 'sin datos') from completadas
union all
select 'A. duración de misiones', 'minutos: la más lenta',
       coalesce(round(max(minutos)::numeric, 1)::text, 'sin datos') from completadas
union all
select 'A. duración de misiones', '>>> cuántas tardaron 15 min o menos',
       count(*) filter (where minutos <= 15) || ' de ' || count(*) from completadas

-- ── B) Contexto, no prueba (ver advertencia del encabezado) ──
union all
select 'B. sesiones (infla)', 'sesiones registradas', count(*)::text from sesiones
union all
select 'B. sesiones (infla)', 'minutos: promedio',
       coalesce(round(avg(minutos)::numeric, 1)::text, 'sin datos') from sesiones
union all
select 'B. sesiones (infla)', 'cuántas entre 10 y 15 min',
       count(*) filter (where minutos between 10 and 15) || ' de ' || count(*) from sesiones

-- ── C) Detalle por nivel, para ver si alguno se va de rango ──
union all
select 'C. minutos por nivel', 'nivel ' || nivel::text,
       round(avg(minutos)::numeric, 1)::text || ' min (n=' || count(*) || ')'
  from completadas
 group by nivel

-- ── D) De cuántos casos sale todo esto ───────────────────────
union all
select 'D. tamaño de la muestra', 'estudiantes distintos',
       count(distinct user_id)::text from completadas
union all
select 'D. tamaño de la muestra', 'sesiones distintas',
       count(distinct session_id)::text from completadas

 order by 1, 2;
