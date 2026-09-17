-- ============================================================
-- nivel5_plan_movilidad.sql — GreenMetric_URBE
-- Nivel 5 nuevo: Plan de Movilidad. Diseño:
-- docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md §10
--
-- REGISTRO, NO SCRIPT: copia de las migraciones para leer y revisar.
-- No usa funciones nuevas: registrar_decision / registrar_sinergia /
-- guardar_detalle / puntaje_greenmetric (sql/puntaje_greenmetric.sql).
--
-- ESPEJO: catalogo_decisiones y catalogo_sinergias reflejan
-- scenes/misiones/plan_movilidad_datos.gd (tests/test_nivel5_movilidad.gd
-- compara este archivo con los datos). catalogo_misiones categoría 5
-- refleja NivelManager.MISIONES_NIVEL[5].
-- ============================================================

-- ── Migración 1: nivel5_plan_movilidad_catalogos ─────────────
-- ESTADO: APLICADA. Solo agrega filas: el juego publicado no las usa.
-- Mejor opción de cada decisión: 6 × 0.60 + 2 × 0.20 + Consejo 1.00 = 5.00.
-- Plan de mayor puntaje = 100 de costo (el presupuesto del cliente).
insert into public.catalogo_decisiones (decision_id, opcion_id, categoria, puntos, contraproducente, costo) values
  ('tr_permisos', 'permiso_por_necesidad', 5, 0.60, false, 8),
  ('tr_permisos', 'lectoras_de_placas', 5, 0.25, false, 24),
  ('tr_permisos', 'pintar_mas_puestos', 5, 0.00, true, 14),
  ('tr_lote', 'ciclovia_arborizada', 5, 0.60, false, 22),
  ('tr_lote', 'plaza_de_eventos', 5, 0.35, false, 12),
  ('tr_lote', 'asfaltar_lote', 5, 0.00, true, 16),
  ('tr_carpool', 'puestos_3_ocupantes', 5, 0.60, false, 6),
  ('tr_carpool', 'app_carpool', 5, 0.35, false, 26),
  ('tr_carpool', 'vender_puestos_reservados', 5, 0.00, true, 0),
  ('tr_shuttle', 'ruta_a_paradas', 5, 0.60, false, 26),
  ('tr_shuttle', 'park_and_ride', 5, 0.40, false, 34),
  ('tr_shuttle', 'bono_gasolina', 5, 0.00, true, 10),
  ('tr_dia_sin_carros', 'jornada_mensual_con_feria', 5, 0.60, false, 10),
  ('tr_dia_sin_carros', 'cierre_semanal', 5, 0.40, false, 28),
  ('tr_dia_sin_carros', 'motos_por_la_acera', 5, 0.00, true, 4),
  ('tr_flota', 'carritos_electricos', 5, 0.60, false, 18),
  ('tr_flota', 'triciclos_de_carga', 5, 0.40, false, 8),
  ('tr_flota', 'camioneta_diesel', 5, 0.00, true, 20),
  ('tr_bici_bloque_e', 'techado_con_panel', 5, 0.20, false, 5),
  ('tr_bici_bloque_e', 'simple_con_candado', 5, 0.10, false, 2),
  ('tr_bici_bloque_e', 'sobre_el_sendero', 5, 0.00, true, 1),
  ('tr_bici_cafetin', 'techado_con_panel', 5, 0.20, false, 5),
  ('tr_bici_cafetin', 'simple_con_candado', 5, 0.10, false, 2),
  ('tr_bici_cafetin', 'sobre_el_sendero', 5, 0.00, true, 1),
  ('tr_consejo', 'consejo_3', 5, 1.00, false, 0),
  ('tr_consejo', 'consejo_2', 5, 0.60, false, 0),
  ('tr_consejo', 'consejo_1', 5, 0.30, false, 0),
  ('tr_consejo', 'consejo_0', 5, 0.00, false, 0)
on conflict (decision_id, opcion_id) do nothing;

-- Cruces: se registran al aprobar el Consejo (spec R5), por eso el requisito
-- es tr_consejo. bicicletero_techado_solar se gana una sola vez aunque se
-- elija en los dos bicicleteros.
insert into public.catalogo_sinergias (accion_id, categoria, puntos, requisito_mision) values
  ('ciclovia_lote', 1, 1, 'tr_consejo'),
  ('flota_electrica', 2, 1, 'tr_consejo'),
  ('dia_sin_carros_feria', 6, 1, 'tr_consejo'),
  ('bicicletero_techado_solar', 2, 1, 'tr_consejo')
on conflict (accion_id, categoria) do nothing;

-- ── Migración 2: nivel5_plan_movilidad_misiones ──────────────
-- ESTADO: NO APLICADA. Se aplica junto con la publicación del cliente nuevo
-- (spec R10 y §10.2): aplicada antes, el juego publicado (que guarda mov_*)
-- mostraría el Avance de Transporte en 0. Las filas viejas de
-- misiones_estudiante no se tocan (sostienen MISIONES_LEGADO del cliente).
delete from public.catalogo_misiones
 where mision_id in ('mov_parqueo', 'mov_shuttle', 'mov_ciclovia', 'mov_dia_sin_carros',
                     'mov_zev', 'mov_carpool', 'bicicletero_bloque_e', 'bicicletero_cafetin');
insert into public.catalogo_misiones (mision_id, categoria, tipo, preguntas) values
  ('tr_permisos', 5, 'mision', 0), ('tr_lote', 5, 'mision', 0),
  ('tr_carpool', 5, 'mision', 0), ('tr_shuttle', 5, 'mision', 0),
  ('tr_dia_sin_carros', 5, 'mision', 0), ('tr_flota', 5, 'mision', 0),
  ('tr_bici_bloque_e', 5, 'mision', 0), ('tr_bici_cafetin', 5, 'mision', 0),
  ('tr_consejo', 5, 'mision', 0)
on conflict (mision_id) do nothing;
