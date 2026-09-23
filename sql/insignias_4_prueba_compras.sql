-- ============================================================
-- PASO 4 — PRUEBA de las insignias que se canjean (no deja datos)
-- GreenMetric_URBE — insignias
--
-- Panel: https://supabase.com/dashboard/project/ikohikbpvtbvsgyumvbr/sql/new
-- Abrí este archivo, seleccioná TODO (Ctrl+A), copiá (Ctrl+C), pegalo en el
-- editor y dale Run.
--
-- Va a terminar en un ERROR que dice PRUEBA_OK: ESO ES LO CORRECTO.
-- La excepción revierte todo lo que la prueba insertó.
--
--   Si ves  ERROR: PRUEBA_OK        -> salió bien, avisame.
--   Si ves  cualquier otro mensaje  -> pasámelo, algo falló.
--
-- REQUIERE insignias_1_migracion.sql y insignias_3_compras.sql aplicadas.
--
-- Nota: no se llama a evaluar_insignias() porque esa función lee auth.uid(),
-- que en el editor SQL es null. Se prueba el motor (_insignias_merecidas) y
-- la aritmética del umbral de ecolider, que es lo que cambió.
-- ============================================================
do $$
declare
  v_user     uuid;
  v_ganables int;
begin
  insert into auth.users (id, instance_id, aud, role, email,
                          encrypted_password, email_confirmed_at,
                          created_at, updated_at)
  values (gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
          'authenticated', 'authenticated',
          'prueba.compras.' || floor(random() * 1e9)::text || '@gmail.com',
          crypt('prueba-compras', gen_salt('bf')), now(), now(), now())
  returning id into v_user;

  -- 1. Comprar un ítem de estatus otorga su insignia.
  insert into inventario_estudiante (user_id, item_id)
  values (v_user, 'titulo_embajador');
  if not exists (select 1 from _insignias_merecidas(v_user)
                  where insignia_id = 'titulo_embajador') then
    raise exception 'Comprar titulo_embajador debería otorgar su insignia';
  end if;

  -- 2. Comprar una HERRAMIENTA no otorga ninguna: tiene efecto mecánico,
  -- no es estatus. Si esto fallara, cualquier compra daría insignia.
  insert into inventario_estudiante (user_id, item_id)
  values (v_user, 'kit_solar');
  if exists (select 1 from _insignias_merecidas(v_user)
              where insignia_id = 'kit_solar') then
    raise exception 'Una herramienta no debería otorgar insignia';
  end if;

  -- 3. Las dos compradas están marcadas como tales.
  if (select count(*) from catalogo_insignias where por_compra) <> 2 then
    raise exception 'Deberían ser exactamente 2 insignias por compra, hay %',
      (select count(*) from catalogo_insignias where por_compra);
  end if;

  -- 4. El umbral de ecolider solo cuenta las que se ganan jugando. Con las
  -- compradas excluidas tiene que seguir habiendo insignias ganables, o
  -- ecolider se volvería imposible (o gratis).
  select count(*) - 1 into v_ganables from catalogo_insignias where not por_compra;
  if v_ganables <= 0 then
    raise exception 'El umbral de ecolider quedó en %, no hay insignias ganables', v_ganables;
  end if;

  -- 5. Y este estudiante, que solo compró, no llega al umbral.
  if (select count(*) from _insignias_merecidas(v_user) m
        join catalogo_insignias c on c.insignia_id = m.insignia_id
       where not c.por_compra) >= v_ganables then
    raise exception 'Comprar cosméticos no debería acercar a ecolider';
  end if;

  raise exception 'PRUEBA_OK';
end;
$$;
