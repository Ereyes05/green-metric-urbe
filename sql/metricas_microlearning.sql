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


-- ════════════════════════════════════════════════════════════
-- SEGUIMIENTO (2026-09-24) — corré esto aparte, después del bloque de
-- arriba. Responde dos preguntas que el primer resultado dejó abiertas.
--
-- Qué salió la primera vez: 14 misiones medidas, 0,8 min de promedio, la
-- más lenta 2,7 min, y 0 de 6 sesiones en el rango de 10 a 15 minutos.
-- O sea que el "14 de 14 por debajo de 15 min" se cumple de forma trivial
-- —nada llega a 3 minutos— y la promesa de la sesión no se cumple.
--
-- Hipótesis a comprobar: (1) las 14 medidas son sobre todo quizzes de NPC,
-- porque varias misiones de campo registran el final pero no el inicio, así
-- que no forman par; (2) la unidad de 10 a 15 minutos de la Tabla 9 no es la
-- misión sino el NIVEL completo.
-- ════════════════════════════════════════════════════════════

-- 1. QUÉ se midió exactamente.
select m.mision_id,
       coalesce(c.tipo, 'fuera del catálogo')       as tipo,
       count(*)                                     as veces,
       round(avg(m.minutos)::numeric, 1)            as min_promedio
  from (select user_id, session_id, mision_id,
               extract(epoch from (
                 max(creado_en) filter (where tipo_evento = 'mision_completada')
               - min(creado_en) filter (where tipo_evento = 'mision_iniciada'))) / 60.0 as minutos
          from eventos_aprendizaje
         group by user_id, session_id, mision_id) m
  left join catalogo_misiones c on c.mision_id = m.mision_id
 where m.minutos is not null and m.minutos > 0
 group by m.mision_id, c.tipo
 order by veces desc, m.mision_id;


-- 2. Cuánto tarda un NIVEL completo, que es la unidad que la Tabla 9
-- probablemente describe. Del primer al último evento del nivel dentro de
-- una misma sesión: esto NO infla como la sesión entera, porque se acota al
-- nivel, pero sigue contando las pausas dentro de él.
select nivel,
       count(*)                                   as veces,
       round(avg(minutos)::numeric, 1)            as min_promedio,
       round(min(minutos)::numeric, 1)            as min_mas_corto,
       round(max(minutos)::numeric, 1)            as min_mas_largo
  from (select user_id, session_id, nivel,
               extract(epoch from (max(creado_en) - min(creado_en))) / 60.0 as minutos
          from eventos_aprendizaje
         group by user_id, session_id, nivel) t
 where minutos > 0
 group by nivel
 order by nivel;


-- ════════════════════════════════════════════════════════════
-- TIEMPO ACTIVO POR NIVEL (2026-09-24) — la medición buena.
--
-- Por qué hace falta. El seguimiento anterior midió del primer al último
-- evento de un nivel, y el Nivel 1 dio 783,9 minutos: trece horas. Nadie
-- jugó trece horas — alguien dejó la pestaña abierta. Esa medida cuenta
-- tiempo TRANSCURRIDO, no tiempo jugando, así que sirve como techo y no
-- como dato.
--
-- Cómo se corrige. Se suman los huecos entre eventos consecutivos, pero
-- ignorando los mayores a 5 minutos: si pasaron más de 5 minutos sin que el
-- estudiante hiciera nada, no estaba jugando. Es la técnica habitual para
-- estimar tiempo activo, y la regla queda declarada en vez de escondida.
--
-- El umbral de 5 minutos es una decisión, no una verdad: está en la
-- constante de abajo para poder probarlo con otro valor y ver si cambia la
-- conclusión. Si con 3 y con 10 minutos da parecido, el resultado es sólido.
-- ════════════════════════════════════════════════════════════
with pasos as (
  select user_id, session_id, nivel, creado_en,
         creado_en - lag(creado_en) over (
           partition by user_id, session_id, nivel order by creado_en) as hueco
    from eventos_aprendizaje
),
activo as (
  select user_id, session_id, nivel,
         sum(extract(epoch from hueco)) filter (
           where hueco <= interval '5 minutes')          -- <<< el umbral
         / 60.0 as minutos
    from pasos
   group by user_id, session_id, nivel
)
select nivel,
       count(*)                                            as recorridos,
       round(avg(minutos)::numeric, 1)                     as min_activo_prom,
       round(min(minutos)::numeric, 1)                     as min_mas_corto,
       round(max(minutos)::numeric, 1)                     as min_mas_largo,
       count(*) filter (where minutos between 10 and 15)   as en_rango_10_15
  from activo
 where minutos is not null and minutos > 0
 group by nivel
 order by nivel;
