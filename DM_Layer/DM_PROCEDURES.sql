--granting required privileges
GRANT USAGE ON SCHEMA bl_cl TO CURRENT_USER;
GRANT USAGE ON SCHEMA bl_dm TO CURRENT_USER;
GRANT USAGE ON SCHEMA bl_3nf TO CURRENT_USER;

GRANT SELECT ON ALL TABLES IN SCHEMA bl_3nf TO CURRENT_USER;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA bl_dm TO CURRENT_USER;


--checking if all required object are present in BL_DM
CREATE OR REPLACE PROCEDURE bl_cl.sp_check_bl_dm_objects()
LANGUAGE plpgsql
AS $$
DECLARE
  v_missing text := '';
  v_obj text;
  v_tables text[] := ARRAY[
    'bl_dm.dim_dates',
    'bl_dm.dim_customers',
    'bl_dm.dim_employees',
    'bl_dm.dim_stores',
    'bl_dm.dim_products_scd'
  ];
BEGIN
  FOREACH v_obj IN ARRAY v_tables LOOP
    IF to_regclass(v_obj) IS NULL THEN
      v_missing := v_missing || v_obj || E'\n';
    END IF;
  END LOOP;

  IF v_missing <> '' THEN
    RAISE EXCEPTION 'missing required BL_DM objects:%', E'\n' || v_missing;
  END IF;
END;
$$;


--sequences for BL_DM like in 3NF
CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_customer_id  START WITH 1;
CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_employee_id  START WITH 1;
CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_store_id     START WITH 1;
CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_product_id   START WITH 1;
CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_transaction_id START WITH 1;

DO $$
BEGIN
  PERFORM setval(
    'bl_dm.seq_customer_id',
    COALESCE((SELECT MAX(customer_id) FROM bl_dm.dim_customers WHERE customer_id <> -1), 0) + 1,
    false
  );

  PERFORM setval(
    'bl_dm.seq_employee_id',
    COALESCE((SELECT MAX(employee_id) FROM bl_dm.dim_employees WHERE employee_id <> -1), 0) + 1,
    false
  );

  PERFORM setval(
    'bl_dm.seq_store_id',
    COALESCE((SELECT MAX(store_id) FROM bl_dm.dim_stores WHERE store_id <> -1), 0) + 1,
    false
  );

  PERFORM setval(
    'bl_dm.seq_product_id',
    COALESCE((SELECT MAX(product_surr_id) FROM bl_dm.dim_products_scd WHERE product_surr_id <> -1), 0) + 1,
    false
  );

  PERFORM setval(
    'bl_dm.seq_transaction_id',
    COALESCE((SELECT MAX(transaction_surr_id) FROM bl_dm.fct_transactions WHERE transaction_surr_id <> -1), 0) + 1,
    false
  );
END;
$$;


--composite types
DO $$
BEGIN
  -- customers
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 't_dim_customer' AND n.nspname = 'bl_cl'
  ) THEN
    EXECUTE $ct$
      CREATE TYPE bl_cl.t_dim_customer AS (
        customer_src_id        varchar,
        customer_name          varchar,
        customer_gender        varchar,
        customer_age           int,
        customer_phone         varchar,
        customer_email         varchar,
        customer_city_id       bigint,
        customer_city_name     varchar,
        customer_country_id    bigint,
        customer_country_name  varchar,
        customer_region_id     bigint,
        customer_region_name   varchar,
        market_id              varchar,
        market_name            varchar,
        segment_src_id         varchar,
        segment_name           varchar,
        source_system          varchar,
        source_entity          varchar
      );
    $ct$;
  END IF;

  -- employees
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 't_dim_employee' AND n.nspname = 'bl_cl'
  ) THEN
    EXECUTE $ct$
      CREATE TYPE bl_cl.t_dim_employee AS (
        employee_src_id varchar,
        employee_name   varchar,
        employee_role   varchar,
        employee_phone  varchar,
        source_system   varchar,
        source_entity   varchar
      );
    $ct$;
  END IF;

  -- stores
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 't_dim_store' AND n.nspname = 'bl_cl'
  ) THEN
    EXECUTE $ct$
      CREATE TYPE bl_cl.t_dim_store AS (
	  	store_id			  bigint,
        store_src_id          varchar,
        store_type_id         varchar,
        store_city_id         varchar,
        store_country_id      varchar,
        store_region_id       varchar,
        store_name            varchar,
        store_manager         varchar,
        store_type            varchar,
        store_city            varchar,
        store_country         varchar,
        store_region          varchar,
        source_system         varchar,
        source_entity         varchar
      );
    $ct$;
  END IF;

  -- products scd
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 't_dim_product_scd' AND n.nspname = 'bl_cl'
  ) THEN
    EXECUTE $ct$
      CREATE TYPE bl_cl.t_dim_product_scd AS (
        product_src_id      varchar,
        sub_category_id     varchar,
        category_id         varchar,
        brand_id            varchar,
        product_name        varchar,
        sub_category_name   varchar,
        category_name       varchar,
        brand_name          varchar,
        source_system       varchar,
        source_entity       varchar
      );
    $ct$;
  END IF;
END;
$$;


--default row insert(multiple defaults are inserted in one procedure)
CREATE OR REPLACE PROCEDURE bl_cl.sp_insert_dm_default_rows()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows bigint := 0;
  v_rc   bigint := 0;
BEGIN
  INSERT INTO bl_dm.dim_dates (
      date_surr_id,
      event_dt,
      day_num,
      month_num,
      year_num,
      quarter_num,
      day_of_week_num,
      ta_insert_dt
  )
  VALUES (
      -1,
      DATE '1900-01-01',
      1,
      1,
      1900,
      1,
      1,
      CURRENT_DATE
  )
  ON CONFLICT (event_dt) DO NOTHING;

  GET DIAGNOSTICS v_rc = ROW_COUNT;
  v_rows := v_rows + v_rc;

  INSERT INTO bl_dm.dim_dates (
      date_surr_id,
      event_dt,
      day_num,
      month_num,
      year_num,
      quarter_num,
      day_of_week_num,
      ta_insert_dt
  )
  SELECT
      TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'), '99999999'),
      d,
      EXTRACT(DAY FROM d)::INT,
      EXTRACT(MONTH FROM d)::INT,
      EXTRACT(YEAR FROM d)::INT,
      EXTRACT(QUARTER FROM d)::INT,
      EXTRACT(ISODOW FROM d)::INT,
      CURRENT_DATE
  FROM generate_series('2024-01-01'::DATE, '2028-12-31'::DATE, INTERVAL '1 day') AS gs(d)
  ON CONFLICT (event_dt) DO NOTHING;

  GET DIAGNOSTICS v_rc = ROW_COUNT;
  v_rows := v_rows + v_rc;

  INSERT INTO bl_dm.dim_customers (
    customer_id,
    customer_src_id,
    customer_name,
    customer_gender,
    customer_age,
    customer_phone,
    customer_email,
    customer_city_id,
    customer_city_name,
    customer_country_id,
    customer_country_name,
    customer_region_id,
    customer_region_name,
    market_id,
    market_name,
    segment_src_id,
    segment_name,
    source_system,
    source_entity,
    ta_insert_dt,
    ta_update_dt
  )
  SELECT
    -1,
    'n.a.',
    'n.a.',
    'n.a.',
    -1,
    'n.a.',
    'n.a.',
    -1,
    'n.a.',
    -1,
    'n.a.',
    -1,
    'n.a.',
    'n.a.',
    'n.a.',
    'n.a.',
    'n.a.',
    'MANUAL',
    'MANUAL',
    DATE '1900-01-01',
    DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_dm.dim_customers WHERE customer_id = -1);

  GET DIAGNOSTICS v_rc = ROW_COUNT;
  v_rows := v_rows + v_rc;

  INSERT INTO bl_dm.dim_employees (
    employee_id, employee_src_id, employee_name, employee_role, employee_phone,
    source_system, source_entity, ta_insert_dt, ta_update_dt
  )
  SELECT
    -1, 'n.a.', 'n.a.', 'n.a.', 'n.a.',
    'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_dm.dim_employees WHERE employee_id = -1);

  GET DIAGNOSTICS v_rc = ROW_COUNT;
  v_rows := v_rows + v_rc;

  INSERT INTO bl_dm.dim_stores (
    store_id, store_src_id,
    store_type_id, store_city_id, store_country_id, store_region_id,
    store_name, store_manager, store_type, store_city, store_country, store_region,
    source_system, source_entity, ta_insert_dt, ta_update_dt
  )
  SELECT
    -1, 'n.a.',
    'n.a.', 'n.a.', 'n.a.', 'n.a.',
    'n.a.', 'n.a.', 'n.a.', 'n.a.', 'n.a.', 'n.a.',
    'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_dm.dim_stores WHERE store_id = -1);

  GET DIAGNOSTICS v_rc = ROW_COUNT;
  v_rows := v_rows + v_rc;

  INSERT INTO bl_dm.dim_products_scd (
    product_surr_id, product_src_id,
    sub_category_id, category_id, brand_id,
    product_name, sub_category_name, category_name, brand_name,
    source_system, source_entity,
    start_dt, end_dt, is_active,
    ta_insert_dt, ta_update_dt
  )
  SELECT
    -1, 'n.a.',
    'n.a.', 'n.a.', 'n.a.',
    'n.a.', 'n.a.', 'n.a.', 'n.a.',
    'MANUAL', 'MANUAL',
    DATE '1900-01-01', DATE '9999-12-31', 'Y',
    DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (
    SELECT 1 FROM bl_dm.dim_products_scd
    WHERE product_surr_id = -1 AND start_dt = DATE '1900-01-01'
  );

  GET DIAGNOSTICS v_rc = ROW_COUNT;
  v_rows := v_rows + v_rc;

  CALL bl_cl.sp_write_log('sp_insert_dm_default_rows', v_rows, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('sp_insert_dm_default_rows', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--dates insert
CREATE OR REPLACE PROCEDURE bl_cl.load_dim_dates_dm(
    p_start_dt date DEFAULT DATE '2024-01-01',
    p_end_dt   date DEFAULT DATE '2028-12-31'
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN

  INSERT INTO bl_dm.dim_dates (
      date_surr_id,
      event_dt,
      day_num,
      month_num,
      year_num,
      quarter_num,
      day_of_week_num,
      ta_insert_dt
  )
  SELECT
      TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'), '99999999') AS date_surr_id,
      d                                             AS event_dt,
      EXTRACT(DAY FROM d)::int                      AS day_num,
      EXTRACT(MONTH FROM d)::int                    AS month_num,
      EXTRACT(YEAR FROM d)::int                     AS year_num,
      EXTRACT(QUARTER FROM d)::int                  AS quarter_num,
      EXTRACT(ISODOW FROM d)::int                   AS day_of_week_num,
      CURRENT_DATE                                  AS ta_insert_dt
  FROM generate_series(p_start_dt, p_end_dt, interval '1 day') AS gs(d)
  ON CONFLICT (event_dt) DO NOTHING;

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;

  CALL bl_cl.sp_write_log('load_dim_dates_dm', v_rows_main, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_dim_dates_dm', 0, 'ERROR', SQLERRM);
  RAISE;

END;
$$;

--customers insert
CREATE OR REPLACE PROCEDURE bl_cl.load_dim_customers()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      c.customer_src_id,
      COALESCE(c.customer_name,   'n.a.') AS customer_name,
      COALESCE(c.customer_gender, 'n.a.') AS customer_gender,
      COALESCE(c.customer_age,    -1)     AS customer_age,
      COALESCE(c.customer_phone,  'n.a.') AS customer_phone,
      COALESCE(c.customer_email,  'n.a.') AS customer_email,
      COALESCE(ci.city_id,   -1)          AS customer_city_id,
      COALESCE(ci.city_name, 'n.a.')      AS customer_city_name,
      COALESCE(co.country_id,   -1)       AS customer_country_id,
      COALESCE(co.country_name, 'n.a.')   AS customer_country_name,
      COALESCE(re.region_id,   -1)        AS customer_region_id,
      COALESCE(re.region_name, 'n.a.')    AS customer_region_name,
      COALESCE(m.market_id::text, 'n.a.')  AS market_id,
      COALESCE(m.market_name, 'n.a.')      AS market_name,
      COALESCE(s.segment_id::text, 'n.a.') AS segment_src_id,
      COALESCE(s.segment_name, 'n.a.')     AS segment_name,
      c.source_system,
      c.source_entity
    FROM bl_3nf.ce_customers c
    LEFT JOIN bl_3nf.ce_cities    ci ON ci.city_id = c.city_id
    LEFT JOIN bl_3nf.ce_countries co ON co.country_id = ci.country_id
    LEFT JOIN bl_3nf.ce_regions   re ON re.region_id = co.region_id
    LEFT JOIN bl_3nf.ce_markets   m  ON m.market_id = c.market_id
    LEFT JOIN bl_3nf.ce_segments  s  ON s.segment_id = c.segment_id
    WHERE c.customer_src_id IS NOT NULL
      AND c.customer_src_id <> 'n.a.'
  ),
  ins AS (
    INSERT INTO bl_dm.dim_customers (
      customer_id,
      customer_src_id,
      customer_name,
      customer_gender,
      customer_age,
      customer_phone,
      customer_email,
      customer_city_id,
      customer_city_name,
      customer_country_id,
      customer_country_name,
      customer_region_id,
      customer_region_name,
      market_id,
      market_name,
      segment_src_id,
      segment_name,
      source_system,
      source_entity,
      ta_insert_dt,
      ta_update_dt
    )
    SELECT
      nextval('bl_dm.seq_customer_id'),
      s.customer_src_id,
      s.customer_name,
      s.customer_gender,
      s.customer_age,
      s.customer_phone,
      s.customer_email,
      s.customer_city_id,
      s.customer_city_name,
      s.customer_country_id,
      s.customer_country_name,
      s.customer_region_id,
      s.customer_region_name,
      s.market_id,
      s.market_name,
      s.segment_src_id,
      s.segment_name,
      s.source_system,
      s.source_entity,
      CURRENT_DATE,
      CURRENT_DATE
    FROM src s
    ON CONFLICT (customer_src_id, source_system)
    DO UPDATE
    SET
      customer_name         = EXCLUDED.customer_name,
      customer_gender       = EXCLUDED.customer_gender,
      customer_age          = EXCLUDED.customer_age,
      customer_phone        = EXCLUDED.customer_phone,
      customer_email        = EXCLUDED.customer_email,
      customer_city_id      = EXCLUDED.customer_city_id,
      customer_city_name    = EXCLUDED.customer_city_name,
      customer_country_id   = EXCLUDED.customer_country_id,
      customer_country_name = EXCLUDED.customer_country_name,
      customer_region_id    = EXCLUDED.customer_region_id,
      customer_region_name  = EXCLUDED.customer_region_name,
      market_id             = EXCLUDED.market_id,
      market_name           = EXCLUDED.market_name,
      segment_src_id        = EXCLUDED.segment_src_id,
      segment_name          = EXCLUDED.segment_name,
      source_entity         = EXCLUDED.source_entity,
      ta_update_dt          = CURRENT_DATE
    WHERE
      bl_dm.dim_customers.customer_name         IS DISTINCT FROM EXCLUDED.customer_name OR
      bl_dm.dim_customers.customer_gender       IS DISTINCT FROM EXCLUDED.customer_gender OR
      bl_dm.dim_customers.customer_age          IS DISTINCT FROM EXCLUDED.customer_age OR
      bl_dm.dim_customers.customer_phone        IS DISTINCT FROM EXCLUDED.customer_phone OR
      bl_dm.dim_customers.customer_email        IS DISTINCT FROM EXCLUDED.customer_email OR
      bl_dm.dim_customers.customer_city_id      IS DISTINCT FROM EXCLUDED.customer_city_id OR
      bl_dm.dim_customers.customer_city_name    IS DISTINCT FROM EXCLUDED.customer_city_name OR
      bl_dm.dim_customers.customer_country_id   IS DISTINCT FROM EXCLUDED.customer_country_id OR
      bl_dm.dim_customers.customer_country_name IS DISTINCT FROM EXCLUDED.customer_country_name OR
      bl_dm.dim_customers.customer_region_id    IS DISTINCT FROM EXCLUDED.customer_region_id OR
      bl_dm.dim_customers.customer_region_name  IS DISTINCT FROM EXCLUDED.customer_region_name OR
      bl_dm.dim_customers.market_id             IS DISTINCT FROM EXCLUDED.market_id OR
      bl_dm.dim_customers.market_name           IS DISTINCT FROM EXCLUDED.market_name OR
      bl_dm.dim_customers.segment_src_id        IS DISTINCT FROM EXCLUDED.segment_src_id OR
      bl_dm.dim_customers.segment_name          IS DISTINCT FROM EXCLUDED.segment_name OR
      bl_dm.dim_customers.source_entity         IS DISTINCT FROM EXCLUDED.source_entity
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_rows
  FROM ins;

  CALL bl_cl.sp_write_log('load_dim_customers', v_rows, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_dim_customers', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;


--employees insert
CREATE OR REPLACE PROCEDURE bl_cl.load_dim_employees()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      e.employee_src_id,
      COALESCE(e.employee_name,  'n.a.') AS employee_name,
      COALESCE(e.employee_role,  'n.a.') AS employee_role,
      COALESCE(e.employee_phone, 'n.a.') AS employee_phone,
      e.source_system,
      e.source_entity
    FROM bl_3nf.ce_employees e
    WHERE e.employee_src_id IS NOT NULL
      AND e.employee_src_id <> 'n.a.'
  ),
  ins AS (
    INSERT INTO bl_dm.dim_employees (
      employee_id,
      employee_src_id,
      employee_name,
      employee_role,
      employee_phone,
      source_system,
      source_entity,
      ta_insert_dt,
      ta_update_dt
    )
    SELECT
      nextval('bl_dm.seq_employee_id'),
      s.employee_src_id,
      s.employee_name,
      s.employee_role,
      s.employee_phone,
      s.source_system,
      s.source_entity,
      CURRENT_DATE,
      CURRENT_DATE
    FROM src s
    ON CONFLICT (employee_src_id, source_system)
    DO UPDATE
    SET
      employee_name  = EXCLUDED.employee_name,
      employee_role  = EXCLUDED.employee_role,
      employee_phone = EXCLUDED.employee_phone,
      source_entity  = EXCLUDED.source_entity,
      ta_update_dt   = CURRENT_DATE
    WHERE
      bl_dm.dim_employees.employee_name  IS DISTINCT FROM EXCLUDED.employee_name OR
      bl_dm.dim_employees.employee_role  IS DISTINCT FROM EXCLUDED.employee_role OR
      bl_dm.dim_employees.employee_phone IS DISTINCT FROM EXCLUDED.employee_phone OR
      bl_dm.dim_employees.source_entity  IS DISTINCT FROM EXCLUDED.source_entity
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_rows
  FROM ins;

  CALL bl_cl.sp_write_log('load_dim_employees', v_rows, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_dim_employees', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;


--stores insert
CREATE OR REPLACE PROCEDURE bl_cl.load_dim_stores()
LANGUAGE plpgsql
AS $$
DECLARE
  cur refcursor;
  v_sql text;
  r bl_cl.t_dim_store;
  v_rows bigint := 0;
  v_step bigint := 0;
BEGIN
  v_sql := $q$
    SELECT
      st.store_id,
      st.store_src_id,
      st.store_name,
      st.store_manager,
      COALESCE(t.store_type_id, -1) AS store_type_id,
      COALESCE(t.store_type, 'n.a.') AS store_type,
      COALESCE(ci.city_id, -1) AS store_city_id,
      COALESCE(ci.city_name, 'n.a.') AS store_city,
      COALESCE(co.country_id, -1) AS store_country_id,
      COALESCE(co.country_name, 'n.a.') AS store_country,
      COALESCE(re.region_id, -1) AS store_region_id,
      COALESCE(re.region_name, 'n.a.') AS store_region,
      st.source_system,
      st.source_entity
    FROM bl_3nf.ce_stores st
    LEFT JOIN bl_3nf.ce_store_types t ON t.store_type_id = st.store_type_id
    LEFT JOIN bl_3nf.ce_cities ci     ON ci.city_id = st.city_id
    LEFT JOIN bl_3nf.ce_countries co  ON co.country_id = ci.country_id
    LEFT JOIN bl_3nf.ce_regions re    ON re.region_id = co.region_id
    WHERE st.store_id <> -1
  $q$;

  OPEN cur FOR EXECUTE v_sql;

  LOOP
    FETCH cur INTO r;
    EXIT WHEN NOT FOUND;

    INSERT INTO bl_dm.dim_stores (
      store_id, store_src_id, store_name, store_manager,
      store_type_id, store_type,
      store_city_id, store_city,
      store_country_id, store_country,
      store_region_id, store_region,
      source_system, source_entity,
      ta_insert_dt, ta_update_dt
    )
    VALUES (
      r.store_id, r.store_src_id, r.store_name, r.store_manager,
      r.store_type_id, r.store_type,
      r.store_city_id, r.store_city,
      r.store_country_id, r.store_country,
      r.store_region_id, r.store_region,
      r.source_system, r.source_entity,
      CURRENT_DATE, CURRENT_DATE
    )
    ON CONFLICT (store_src_id, source_system)
    DO UPDATE
    SET
      store_name       = EXCLUDED.store_name,
      store_manager    = EXCLUDED.store_manager,
      store_type_id    = EXCLUDED.store_type_id,
      store_type       = EXCLUDED.store_type,
      store_city_id    = EXCLUDED.store_city_id,
      store_city       = EXCLUDED.store_city,
      store_country_id = EXCLUDED.store_country_id,
      store_country    = EXCLUDED.store_country,
      store_region_id  = EXCLUDED.store_region_id,
      store_region     = EXCLUDED.store_region,
      source_entity    = EXCLUDED.source_entity,
      ta_update_dt     = CURRENT_DATE
    WHERE
      bl_dm.dim_stores.store_name       IS DISTINCT FROM EXCLUDED.store_name OR
      bl_dm.dim_stores.store_manager    IS DISTINCT FROM EXCLUDED.store_manager OR
      bl_dm.dim_stores.store_type_id    IS DISTINCT FROM EXCLUDED.store_type_id OR
      bl_dm.dim_stores.store_type       IS DISTINCT FROM EXCLUDED.store_type OR
      bl_dm.dim_stores.store_city_id    IS DISTINCT FROM EXCLUDED.store_city_id OR
      bl_dm.dim_stores.store_city       IS DISTINCT FROM EXCLUDED.store_city OR
      bl_dm.dim_stores.store_country_id IS DISTINCT FROM EXCLUDED.store_country_id OR
      bl_dm.dim_stores.store_country    IS DISTINCT FROM EXCLUDED.store_country OR
      bl_dm.dim_stores.store_region_id  IS DISTINCT FROM EXCLUDED.store_region_id OR
      bl_dm.dim_stores.store_region     IS DISTINCT FROM EXCLUDED.store_region OR
      bl_dm.dim_stores.source_entity    IS DISTINCT FROM EXCLUDED.source_entity;

    GET DIAGNOSTICS v_step = ROW_COUNT;
    v_rows := v_rows + v_step;
  END LOOP;

  CLOSE cur;

  CALL bl_cl.sp_write_log('load_dim_stores', v_rows, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_dim_stores', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;


--products_scd insert
CREATE OR REPLACE PROCEDURE bl_cl.load_dim_products_scd(p_run_dt date DEFAULT CURRENT_DATE)
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      s.product_src_id,
      COALESCE(sc.sub_category_id::text, 'n.a.') AS sub_category_id,
      COALESCE(pc.category_id::text, 'n.a.')     AS category_id,
      COALESCE(b.brand_id::text, 'n.a.')         AS brand_id,
      COALESCE(s.product_name, 'n.a.')           AS product_name,
      COALESCE(sc.sub_category_name, 'n.a.')     AS sub_category_name,
      COALESCE(pc.category_name, 'n.a.')         AS category_name,
      COALESCE(b.brand_name, 'n.a.')             AS brand_name,
      s.source_system,
      s.source_entity,
      s.start_dt::timestamp                      AS start_dt,
      CASE
        WHEN s.is_active THEN timestamp '9999-12-31 00:00:00'
        ELSE COALESCE(s.end_dt::timestamp, timestamp '9999-12-31 00:00:00')
      END                                        AS end_dt,
      CASE WHEN s.is_active THEN 'Y' ELSE 'N' END AS is_active
    FROM bl_3nf.ce_products_scd s
    LEFT JOIN bl_3nf.ce_product_subcategories sc
      ON sc.sub_category_id = s.sub_category_id
     AND sc.source_system   = s.source_system
     AND sc.source_entity   = s.source_entity
    LEFT JOIN bl_3nf.ce_product_categories pc
      ON pc.category_id     = sc.category_id
     AND pc.source_system   = sc.source_system
     AND pc.source_entity   = sc.source_entity
    LEFT JOIN bl_3nf.ce_product_brands b
      ON b.brand_id         = s.brand_id
     AND b.source_system    = s.source_system
     AND b.source_entity    = s.source_entity
    WHERE s.product_id <> -1
      AND s.product_src_id IS NOT NULL
      AND s.product_src_id <> 'n.a.'
  ),
  prep AS (
    SELECT
      COALESCE(dv.product_surr_id, nextval('bl_dm.seq_product_id')) AS product_surr_id,
      s.product_src_id,
      s.sub_category_id,
      s.category_id,
      s.brand_id,
      s.product_name,
      s.sub_category_name,
      s.category_name,
      s.brand_name,
      s.source_system,
      s.source_entity,
      s.start_dt,
      s.end_dt,
      s.is_active
    FROM src s
    LEFT JOIN bl_dm.dim_products_scd dv
      ON dv.product_src_id = s.product_src_id
     AND dv.source_system  = s.source_system
     AND dv.source_entity  = s.source_entity
     AND dv.start_dt       = s.start_dt
  ),
  upserted AS (
    INSERT INTO bl_dm.dim_products_scd (
      product_surr_id,
      product_src_id,
      sub_category_id,
      category_id,
      brand_id,
      product_name,
      sub_category_name,
      category_name,
      brand_name,
      source_system,
      source_entity,
      start_dt,
      end_dt,
      is_active,
      ta_insert_dt,
      ta_update_dt
    )
    SELECT
      product_surr_id,
      product_src_id,
      sub_category_id,
      category_id,
      brand_id,
      product_name,
      sub_category_name,
      category_name,
      brand_name,
      source_system,
      source_entity,
      start_dt,
      end_dt,
      is_active,
      CURRENT_DATE,
      CURRENT_DATE
    FROM prep
    ON CONFLICT (product_src_id, source_system, source_entity, start_dt)
    DO UPDATE
    SET
      sub_category_id   = EXCLUDED.sub_category_id,
      category_id       = EXCLUDED.category_id,
      brand_id          = EXCLUDED.brand_id,
      product_name      = EXCLUDED.product_name,
      sub_category_name = EXCLUDED.sub_category_name,
      category_name     = EXCLUDED.category_name,
      brand_name        = EXCLUDED.brand_name,
      end_dt            = EXCLUDED.end_dt,
      is_active         = EXCLUDED.is_active,
      ta_update_dt      = CURRENT_DATE
    WHERE
      bl_dm.dim_products_scd.sub_category_id   IS DISTINCT FROM EXCLUDED.sub_category_id OR
      bl_dm.dim_products_scd.category_id       IS DISTINCT FROM EXCLUDED.category_id OR
      bl_dm.dim_products_scd.brand_id          IS DISTINCT FROM EXCLUDED.brand_id OR
      bl_dm.dim_products_scd.product_name      IS DISTINCT FROM EXCLUDED.product_name OR
      bl_dm.dim_products_scd.sub_category_name IS DISTINCT FROM EXCLUDED.sub_category_name OR
      bl_dm.dim_products_scd.category_name     IS DISTINCT FROM EXCLUDED.category_name OR
      bl_dm.dim_products_scd.brand_name        IS DISTINCT FROM EXCLUDED.brand_name OR
      bl_dm.dim_products_scd.end_dt            IS DISTINCT FROM EXCLUDED.end_dt OR
      bl_dm.dim_products_scd.is_active         IS DISTINCT FROM EXCLUDED.is_active
    RETURNING product_src_id, source_system, source_entity, start_dt, is_active
  ),
  closed_duplicates AS (
    UPDATE bl_dm.dim_products_scd d
    SET
      is_active    = 'N',
      end_dt       = u.start_dt - interval '1 microsecond',
      ta_update_dt = CURRENT_DATE
    FROM upserted u
    WHERE u.is_active = 'Y'
      AND d.product_src_id = u.product_src_id
      AND d.source_system  = u.source_system
      AND d.source_entity  = u.source_entity
      AND d.is_active      = 'Y'
      AND d.start_dt      <> u.start_dt
      AND d.end_dt         = timestamp '9999-12-31 00:00:00'
    RETURNING 1
  )
  SELECT
    (SELECT COUNT(*) FROM upserted) +
    (SELECT COUNT(*) FROM closed_duplicates)
  INTO v_rows;

  CALL bl_cl.sp_write_log('load_dim_products_scd', v_rows, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_dim_products_scd', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--procedure to load all INSERT procedures
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_dm_all()
LANGUAGE plpgsql
AS $$
DECLARE
  v_run_dt date := CURRENT_DATE;
BEGIN
  CALL bl_cl.sp_check_bl_dm_objects();
  CALL bl_cl.sp_insert_dm_default_rows();
  CALL bl_cl.load_dim_dates_dm();
  CALL bl_cl.load_dim_customers();
  CALL bl_cl.load_dim_employees();
  CALL bl_cl.load_dim_stores();
  CALL bl_cl.load_dim_products_scd();
  CALL bl_cl.sp_write_log('sp_load_dm_all', 0, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('sp_load_dm_all', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;


--run main procedure
CALL bl_cl.sp_load_dm_all();


--here we check log
SELECT *
FROM bl_cl.mta_etl_logs
ORDER BY log_dttm DESC;


--SCD 3NF select
SELECT *
FROM bl_3nf.ce_products_scd
WHERE product_src_id in (
'2252',
'2139',
'3199',
'608',
'993',
'917',
'9999999'
) AND
source_system like '%OFFLINE%';


--SCD DM select
SELECT *
FROM bl_dm.dim_products_scd
WHERE product_src_id in (
'2252',
'2139',
'3199',
'608',
'993',
'917',
'9999999'
) AND
source_system like '%OFFLINE%';


--after truncating i copy dataset back again
TRUNCATE TABLE sa_global_shop_offline.src_global_shop_offline;

COPY sa_global_shop_offline.src_global_shop_offline
FROM 'C:\Program Files\PostgreSQL\18\data\datasets\global_shop_offline.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

--let's run 3NF procedure to load SCD
CALL bl_cl.load_ce_products_scd();

--and now rerun main procedure from DIM SCD
CALL bl_cl.sp_load_dm_all();

