-- ============================================================
-- PASO 2 — PRUEBA (no deja datos)
-- GreenMetric_URBE — insignias
--
-- Panel: https://supabase.com/dashboard/project/ikohikbpvtbvsgyumvbr/sql/new
-- Abrí este archivo, seleccioná TODO (Ctrl+A), copiá (Ctrl+C), pegalo en el
-- editor y dale Run. Va a terminar en un ERROR que dice PRUEBA_OK: ESO ES LO CORRECTO.
-- ============================================================

-- Crea un estudiante inventado, comprueba que las reglas funcionen y al
-- final lanza una excepción a propósito. La excepción revierte TODO lo que
-- la prueba insertó, así que no queda basura en la base.
--
--   Si ves  ERROR: PRUEBA_OK        -> salió bien, avisame.
--   Si ves  cualquier otro mensaje  -> pasámelo, algo falló.

do $$
declare
  v_user uuid;
  v_n    int;
begin
  insert into auth.users (id, instance_id, aud, role, email,
                          encrypted_password, email_confirmed_at,
                          created_at, updated_at)
  values (gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
          'authenticated', 'authenticated',
          'prueba.insignias.' || floor(random() * 1e9)::text || '@gmail.com',
          crypt('prueba-insignias', gen_salt('bf')), now(), now(), now())
  returning id into v_user;

  -- Sin nada hecho: ninguna insignia.
  select count(*) into v_n from _insignias_merecidas(v_user);
  if v_n <> 0 then
    raise exception 'Un estudiante sin actividad no debería tener insignias, tiene %', v_n;
  end if;

  -- Un quiz con 3 respuestas correctas -> quiz_perfecto.
  insert into eventos_aprendizaje (user_id, session_id, nivel, mision_id, tipo_evento, correcto)
  select v_user, 'ses-prueba', 6, 'mision_rector', 'respuesta_quiz', true
    from generate_series(1, 3);
  if not exists (select 1 from _insignias_merecidas(v_user) where insignia_id = 'quiz_perfecto') then
    raise exception 'Tres respuestas correctas deberían dar quiz_perfecto';
  end if;

  -- Una respuesta incorrecta en el MISMO quiz lo descalifica.
  insert into eventos_aprendizaje (user_id, session_id, nivel, mision_id, tipo_evento, correcto)
  values (v_user, 'ses-prueba', 6, 'mision_rector', 'respuesta_quiz', false);
  if exists (select 1 from _insignias_merecidas(v_user) where insignia_id = 'quiz_perfecto') then
    raise exception 'Un quiz con una respuesta incorrecta no debería dar quiz_perfecto';
  end if;

  -- Tres días seguidos -> racha_fuego. (Dos no alcanzan.)
  insert into eventos_aprendizaje (user_id, session_id, nivel, mision_id, tipo_evento, creado_en)
  values (v_user, 's1', 1, 'x', 'mision_iniciada', now() - interval '2 days'),
         (v_user, 's2', 1, 'x', 'mision_iniciada', now() - interval '1 day');
  if not exists (select 1 from _insignias_merecidas(v_user) where insignia_id = 'racha_fuego') then
    raise exception 'Tres días seguidos deberían dar racha_fuego';
  end if;

  raise exception 'PRUEBA_OK';
end;
$$;
