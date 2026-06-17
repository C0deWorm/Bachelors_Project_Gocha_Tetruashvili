
CREATE SCHEMA IF NOT EXISTS bl_cl;

--granting all privileges to schema
GRANT USAGE ON SCHEMA bl_cl TO CURRENT_USER;
GRANT USAGE ON SCHEMA bl_3nf TO CURRENT_USER;
GRANT USAGE ON SCHEMA sa_global_shop_online TO CURRENT_USER;
GRANT USAGE ON SCHEMA sa_global_shop_offline TO CURRENT_USER;

GRANT SELECT ON ALL TABLES IN SCHEMA sa_global_shop_online TO CURRENT_USER;
GRANT SELECT ON ALL TABLES IN SCHEMA sa_global_shop_offline TO CURRENT_USER;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA bl_3nf TO CURRENT_USER;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA bl_3nf TO CURRENT_USER;


--here function fill check that all necessary BL_3NF objects are present
CREATE OR REPLACE PROCEDURE bl_cl.sp_check_bl_3nf_objects()
LANGUAGE plpgsql
AS $$
DECLARE
  v_missing text := '';
  v_obj text;
  v_tables text[] := ARRAY[
    'bl_3nf.ce_regions',
    'bl_3nf.ce_countries',
    'bl_3nf.ce_cities',
    'bl_3nf.ce_markets',
    'bl_3nf.ce_segments',
    'bl_3nf.ce_product_categories',
    'bl_3nf.ce_product_subcategories',
    'bl_3nf.ce_product_brands',
    'bl_3nf.ce_payment_methods',
    'bl_3nf.ce_store_types',
    'bl_3nf.ce_stores',
    'bl_3nf.ce_employees',
    'bl_3nf.ce_customers',
    'bl_3nf.ce_products_scd'
  ];
  v_seqs text[] := ARRAY[
    'bl_3nf.seq_region_id',
    'bl_3nf.seq_country_id',
    'bl_3nf.seq_city_id',
    'bl_3nf.seq_market_id',
    'bl_3nf.seq_segment_id',
    'bl_3nf.seq_category_id',
    'bl_3nf.seq_sub_category_id',
    'bl_3nf.seq_brand_id',
    'bl_3nf.seq_payment_method_id',
    'bl_3nf.seq_store_type_id',
    'bl_3nf.seq_store_id',
    'bl_3nf.seq_employee_id',
    'bl_3nf.seq_customer_id',
    'bl_3nf.seq_product_id'
  ];
BEGIN
  FOREACH v_obj IN ARRAY v_tables LOOP
    IF to_regclass(v_obj) IS NULL THEN
      v_missing := v_missing || v_obj || E'\n';
    END IF;
  END LOOP;

  FOREACH v_obj IN ARRAY v_seqs LOOP
    IF to_regclass(v_obj) IS NULL THEN
      v_missing := v_missing || v_obj || E'\n';
    END IF;
  END LOOP;

  IF v_missing <> '' THEN
    RAISE EXCEPTION 'Missing required BL_3NF objects:%', E'\n' || v_missing;
  END IF;
END;
$$;


--creating logging table
CREATE TABLE IF NOT EXISTS bl_cl.mta_etl_logs
(
  log_id         bigserial 	 PRIMARY KEY,
  log_dttm       timestamp 	 NOT NULL DEFAULT now(),
  procedure_name text        NOT NULL,
  rows_affected  bigint      NOT NULL DEFAULT 0,
  status         text        NOT NULL,
  message        text        NULL,
  error_text     text        NULL
);

--procedure to write logs
CREATE OR REPLACE PROCEDURE bl_cl.sp_write_log(
    p_procedure_name text,
    p_rows_affected  bigint,
    p_status         text,
    p_error_text     text
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO bl_cl.mta_etl_logs
    (procedure_name, rows_affected, status, message, error_text)
  VALUES
    (
      p_procedure_name,
      COALESCE(p_rows_affected, 0),
      COALESCE(p_status, 'OK'),
      CASE WHEN COALESCE(p_status,'OK') = 'OK' THEN 'Successful load' ELSE 'Load failed' END,
      p_error_text
    );
END;
$$;

--function that returns TABLE, which is last 50 entries in LOG TABLE
CREATE OR REPLACE FUNCTION bl_cl.fn_etl_recent_runs(p_limit int DEFAULT 50)
RETURNS TABLE(
  log_id bigint,
  log_dttm timestamptz,
  procedure_name text,
  rows_affected bigint,
  status text,
  message text,
  error_text text
)
LANGUAGE sql
AS $$
  SELECT
    l.log_id,
    l.log_dttm,
    l.procedure_name,
    l.rows_affected,
    l.status,
    l.message,
    l.error_text
  FROM bl_cl.mta_etl_logs l
  ORDER BY l.log_id DESC
  LIMIT GREATEST(p_limit, 1);
$$;


--default rows loading procedure
CREATE OR REPLACE PROCEDURE bl_cl.sp_init_default_rows()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows  bigint := 0;
  v_total bigint := 0;
BEGIN
  INSERT INTO bl_3nf.ce_regions
    (region_id, region_src_id, region_name, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_regions WHERE region_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_countries
    (country_id, country_src_id, country_name, region_id, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', -1, 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_countries WHERE country_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_cities
    (city_id, city_src_id, city_name, country_id, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', -1, 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_cities WHERE city_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_markets
    (market_id, market_src_id, market_name, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_markets WHERE market_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_segments
    (segment_id, segment_src_id, segment_name, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_segments WHERE segment_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_product_categories
    (category_id, category_src_id, category_name, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_product_categories WHERE category_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_product_subcategories
    (sub_category_id, sub_category_src_id, sub_category_name, category_id, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', -1, 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_product_subcategories WHERE sub_category_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_product_brands
    (brand_id, brand_src_id, brand_name, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_product_brands WHERE brand_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_payment_methods
    (payment_method_id, payment_method_src_id, payment_method_name, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_payment_methods WHERE payment_method_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_store_types
    (store_type_id, store_type_src_id, store_type, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_store_types WHERE store_type_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_stores
    (store_id, store_src_id, store_name, store_type_id, store_manager, city_id,
     source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', -1, 'n. a.', -1,
         'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_stores WHERE store_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_employees
    (employee_id, employee_src_id, employee_name, employee_role, employee_phone,
     source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', 'n. a.', 'n. a.',
         'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_employees WHERE employee_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_customers
    (customer_id, customer_src_id, customer_name, customer_gender, customer_age, customer_phone, customer_email,
     city_id, market_id, segment_id, source_system, source_entity, insert_dt, update_dt)
  SELECT -1, 'n. a.', 'n. a.', 'n. a.', -1, 'n. a.', 'n. a.',
         -1, -1, -1, 'MANUAL', 'MANUAL', DATE '1900-01-01', DATE '1900-01-01'
  WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_customers WHERE customer_id = -1);
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  INSERT INTO bl_3nf.ce_products_scd
    (product_id, product_src_id, product_name, sub_category_id, brand_id,
     start_dt, end_dt, insert_dt, source_system, source_entity, is_active)
  SELECT -1, 'n. a.', 'n. a.', -1, -1,
         DATE '1900-01-01', DATE '9999-12-31', DATE '1900-01-01',
         'MANUAL', 'MANUAL', TRUE
  WHERE NOT EXISTS (
    SELECT 1 FROM bl_3nf.ce_products_scd
    WHERE product_id = -1 AND start_dt = DATE '1900-01-01'
  );
  GET DIAGNOSTICS v_rows = ROW_COUNT; v_total := v_total + v_rows;

  CALL bl_cl.sp_write_log('sp_init_default_rows', v_total, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('sp_init_default_rows', v_total, 'ERROR', SQLERRM);
  RAISE;
END;
$$;


--loading data from ext to src.
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_src_global_shop_online()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows bigint := 0;
BEGIN
  WITH upserted AS (
    INSERT INTO sa_global_shop_online.src_global_shop_online (
      online_order_id,
      order_date,
      customer_id,
      region,
      market,
      segment,
      product_id,
      product_name,
      category,
      sub_category,
      brand,
      sales,
      quantity,
      profit,
      shipping_cost,
      platform,
      browser,
      device,
      shipping_provider,
      shipping_mode,
      tracking_number,
      delivery_status,
      payment_gateway,
      order_priority,
      source_system,
      customer_name,
      city,
      country,
      customer_phone,
      customer_email,
      customer_age,
      customer_gender
    )
    SELECT
      e.online_order_id,
      e.order_date,
      e.customer_id,
      e.region,
      e.market,
      e.segment,
      e.product_id,
      e.product_name,
      e.category,
      e.sub_category,
      e.brand,
      e.sales,
      e.quantity,
      e.profit,
      e.shipping_cost,
      e.platform,
      e.browser,
      e.device,
      e.shipping_provider,
      e.shipping_mode,
      e.tracking_number,
      e.delivery_status,
      e.payment_gateway,
      e.order_priority,
      e.source_system,
      e.customer_name,
      e.city,
      e.country,
      e.customer_phone,
      e.customer_email,
      e.customer_age,
      e.customer_gender
    FROM sa_global_shop_online.ext_global_shop_online e
    ON CONFLICT (online_order_id)
    DO UPDATE
    SET
      order_date         = EXCLUDED.order_date,
      customer_id        = EXCLUDED.customer_id,
      region             = EXCLUDED.region,
      market             = EXCLUDED.market,
      segment            = EXCLUDED.segment,
      product_id         = EXCLUDED.product_id,
      product_name       = EXCLUDED.product_name,
      category           = EXCLUDED.category,
      sub_category       = EXCLUDED.sub_category,
      brand              = EXCLUDED.brand,
      sales              = EXCLUDED.sales,
      quantity           = EXCLUDED.quantity,
      profit             = EXCLUDED.profit,
      shipping_cost      = EXCLUDED.shipping_cost,
      platform           = EXCLUDED.platform,
      browser            = EXCLUDED.browser,
      device             = EXCLUDED.device,
      shipping_provider  = EXCLUDED.shipping_provider,
      shipping_mode      = EXCLUDED.shipping_mode,
      tracking_number    = EXCLUDED.tracking_number,
      delivery_status    = EXCLUDED.delivery_status,
      payment_gateway    = EXCLUDED.payment_gateway,
      order_priority     = EXCLUDED.order_priority,
      source_system      = EXCLUDED.source_system,
      customer_name      = EXCLUDED.customer_name,
      city               = EXCLUDED.city,
      country            = EXCLUDED.country,
      customer_phone     = EXCLUDED.customer_phone,
      customer_email     = EXCLUDED.customer_email,
      customer_age       = EXCLUDED.customer_age,
      customer_gender    = EXCLUDED.customer_gender
    WHERE
      sa_global_shop_online.src_global_shop_online.order_date        IS DISTINCT FROM EXCLUDED.order_date OR
      sa_global_shop_online.src_global_shop_online.customer_id       IS DISTINCT FROM EXCLUDED.customer_id OR
      sa_global_shop_online.src_global_shop_online.region            IS DISTINCT FROM EXCLUDED.region OR
      sa_global_shop_online.src_global_shop_online.market            IS DISTINCT FROM EXCLUDED.market OR
      sa_global_shop_online.src_global_shop_online.segment           IS DISTINCT FROM EXCLUDED.segment OR
      sa_global_shop_online.src_global_shop_online.product_id        IS DISTINCT FROM EXCLUDED.product_id OR
      sa_global_shop_online.src_global_shop_online.product_name      IS DISTINCT FROM EXCLUDED.product_name OR
      sa_global_shop_online.src_global_shop_online.category          IS DISTINCT FROM EXCLUDED.category OR
      sa_global_shop_online.src_global_shop_online.sub_category      IS DISTINCT FROM EXCLUDED.sub_category OR
      sa_global_shop_online.src_global_shop_online.brand             IS DISTINCT FROM EXCLUDED.brand OR
      sa_global_shop_online.src_global_shop_online.sales             IS DISTINCT FROM EXCLUDED.sales OR
      sa_global_shop_online.src_global_shop_online.quantity          IS DISTINCT FROM EXCLUDED.quantity OR
      sa_global_shop_online.src_global_shop_online.profit            IS DISTINCT FROM EXCLUDED.profit OR
      sa_global_shop_online.src_global_shop_online.shipping_cost     IS DISTINCT FROM EXCLUDED.shipping_cost OR
      sa_global_shop_online.src_global_shop_online.platform          IS DISTINCT FROM EXCLUDED.platform OR
      sa_global_shop_online.src_global_shop_online.browser           IS DISTINCT FROM EXCLUDED.browser OR
      sa_global_shop_online.src_global_shop_online.device            IS DISTINCT FROM EXCLUDED.device OR
      sa_global_shop_online.src_global_shop_online.shipping_provider IS DISTINCT FROM EXCLUDED.shipping_provider OR
      sa_global_shop_online.src_global_shop_online.shipping_mode     IS DISTINCT FROM EXCLUDED.shipping_mode OR
      sa_global_shop_online.src_global_shop_online.tracking_number   IS DISTINCT FROM EXCLUDED.tracking_number OR
      sa_global_shop_online.src_global_shop_online.delivery_status   IS DISTINCT FROM EXCLUDED.delivery_status OR
      sa_global_shop_online.src_global_shop_online.payment_gateway   IS DISTINCT FROM EXCLUDED.payment_gateway OR
      sa_global_shop_online.src_global_shop_online.order_priority    IS DISTINCT FROM EXCLUDED.order_priority OR
      sa_global_shop_online.src_global_shop_online.source_system     IS DISTINCT FROM EXCLUDED.source_system OR
      sa_global_shop_online.src_global_shop_online.customer_name     IS DISTINCT FROM EXCLUDED.customer_name OR
      sa_global_shop_online.src_global_shop_online.city              IS DISTINCT FROM EXCLUDED.city OR
      sa_global_shop_online.src_global_shop_online.country           IS DISTINCT FROM EXCLUDED.country OR
      sa_global_shop_online.src_global_shop_online.customer_phone    IS DISTINCT FROM EXCLUDED.customer_phone OR
      sa_global_shop_online.src_global_shop_online.customer_email    IS DISTINCT FROM EXCLUDED.customer_email OR
      sa_global_shop_online.src_global_shop_online.customer_age      IS DISTINCT FROM EXCLUDED.customer_age OR
      sa_global_shop_online.src_global_shop_online.customer_gender   IS DISTINCT FROM EXCLUDED.customer_gender
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_rows
  FROM upserted;

  CALL bl_cl.sp_write_log('sp_load_src_global_shop_online', v_rows, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('sp_load_src_global_shop_online', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

-- OFFLINE: wrap your existing INSERT as procedure
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_src_global_shop_offline()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows bigint := 0;
BEGIN
  WITH upserted AS (
    INSERT INTO sa_global_shop_offline.src_global_shop_offline (
      transaction_id,
      order_date,
      customer_id,
      region,
      market,
      segment,
      product_id,
      product_name,
      category,
      sub_category,
      brand,
      sales,
      quantity,
      profit,
      shipping_cost,
      employee_id,
      payment_type,
      register_number,
      transaction_status,
      source_system,
      customer_name,
      city,
      country,
      customer_phone,
      customer_email,
      customer_age,
      customer_gender,
      store_city_country,
      store_id,
      store_name,
      store_type,
      store_manager,
      store_city,
      employee_name,
      employee_role,
      employee_phone
    )
    SELECT
      e.transaction_id,
      e.order_date,
      e.customer_id,
      e.region,
      e.market,
      e.segment,
      e.product_id,
      e.product_name,
      e.category,
      e.sub_category,
      e.brand,
      e.sales,
      e.quantity,
      e.profit,
      e.shipping_cost,
      e.employee_id,
      e.payment_type,
      e.register_number,
      e.transaction_status,
      e.source_system,
      e.customer_name,
      e.city,
      e.country,
      e.customer_phone,
      e.customer_email,
      e.customer_age,
      e.customer_gender,
      e.store_city_country,
      e.store_id,
      e.store_name,
      e.store_type,
      e.store_manager,
      e.store_city,
      e.employee_name,
      e.employee_role,
      e.employee_phone
    FROM sa_global_shop_offline.ext_global_shop_offline e
    ON CONFLICT (transaction_id)
    DO UPDATE
    SET
      order_date        = EXCLUDED.order_date,
      customer_id       = EXCLUDED.customer_id,
      region            = EXCLUDED.region,
      market            = EXCLUDED.market,
      segment           = EXCLUDED.segment,
      product_id        = EXCLUDED.product_id,
      product_name      = EXCLUDED.product_name,
      category          = EXCLUDED.category,
      sub_category      = EXCLUDED.sub_category,
      brand             = EXCLUDED.brand,
      sales             = EXCLUDED.sales,
      quantity          = EXCLUDED.quantity,
      profit            = EXCLUDED.profit,
      shipping_cost     = EXCLUDED.shipping_cost,
      employee_id       = EXCLUDED.employee_id,
      payment_type      = EXCLUDED.payment_type,
      register_number   = EXCLUDED.register_number,
      transaction_status= EXCLUDED.transaction_status,
      source_system     = EXCLUDED.source_system,
      customer_name     = EXCLUDED.customer_name,
      city              = EXCLUDED.city,
      country           = EXCLUDED.country,
      customer_phone    = EXCLUDED.customer_phone,
      customer_email    = EXCLUDED.customer_email,
      customer_age      = EXCLUDED.customer_age,
      customer_gender   = EXCLUDED.customer_gender,
      store_city_country= EXCLUDED.store_city_country,
      store_id          = EXCLUDED.store_id,
      store_name        = EXCLUDED.store_name,
      store_type        = EXCLUDED.store_type,
      store_manager     = EXCLUDED.store_manager,
      store_city        = EXCLUDED.store_city,
      employee_name     = EXCLUDED.employee_name,
      employee_role     = EXCLUDED.employee_role,
      employee_phone    = EXCLUDED.employee_phone
    WHERE
      sa_global_shop_offline.src_global_shop_offline.order_date         IS DISTINCT FROM EXCLUDED.order_date OR
      sa_global_shop_offline.src_global_shop_offline.customer_id        IS DISTINCT FROM EXCLUDED.customer_id OR
      sa_global_shop_offline.src_global_shop_offline.region             IS DISTINCT FROM EXCLUDED.region OR
      sa_global_shop_offline.src_global_shop_offline.market             IS DISTINCT FROM EXCLUDED.market OR
      sa_global_shop_offline.src_global_shop_offline.segment            IS DISTINCT FROM EXCLUDED.segment OR
      sa_global_shop_offline.src_global_shop_offline.product_id         IS DISTINCT FROM EXCLUDED.product_id OR
      sa_global_shop_offline.src_global_shop_offline.product_name       IS DISTINCT FROM EXCLUDED.product_name OR
      sa_global_shop_offline.src_global_shop_offline.category           IS DISTINCT FROM EXCLUDED.category OR
      sa_global_shop_offline.src_global_shop_offline.sub_category       IS DISTINCT FROM EXCLUDED.sub_category OR
      sa_global_shop_offline.src_global_shop_offline.brand              IS DISTINCT FROM EXCLUDED.brand OR
      sa_global_shop_offline.src_global_shop_offline.sales              IS DISTINCT FROM EXCLUDED.sales OR
      sa_global_shop_offline.src_global_shop_offline.quantity           IS DISTINCT FROM EXCLUDED.quantity OR
      sa_global_shop_offline.src_global_shop_offline.profit             IS DISTINCT FROM EXCLUDED.profit OR
      sa_global_shop_offline.src_global_shop_offline.shipping_cost      IS DISTINCT FROM EXCLUDED.shipping_cost OR
      sa_global_shop_offline.src_global_shop_offline.employee_id        IS DISTINCT FROM EXCLUDED.employee_id OR
      sa_global_shop_offline.src_global_shop_offline.payment_type       IS DISTINCT FROM EXCLUDED.payment_type OR
      sa_global_shop_offline.src_global_shop_offline.register_number    IS DISTINCT FROM EXCLUDED.register_number OR
      sa_global_shop_offline.src_global_shop_offline.transaction_status IS DISTINCT FROM EXCLUDED.transaction_status OR
      sa_global_shop_offline.src_global_shop_offline.source_system      IS DISTINCT FROM EXCLUDED.source_system OR
      sa_global_shop_offline.src_global_shop_offline.customer_name      IS DISTINCT FROM EXCLUDED.customer_name OR
      sa_global_shop_offline.src_global_shop_offline.city               IS DISTINCT FROM EXCLUDED.city OR
      sa_global_shop_offline.src_global_shop_offline.country            IS DISTINCT FROM EXCLUDED.country OR
      sa_global_shop_offline.src_global_shop_offline.customer_phone     IS DISTINCT FROM EXCLUDED.customer_phone OR
      sa_global_shop_offline.src_global_shop_offline.customer_email     IS DISTINCT FROM EXCLUDED.customer_email OR
      sa_global_shop_offline.src_global_shop_offline.customer_age       IS DISTINCT FROM EXCLUDED.customer_age OR
      sa_global_shop_offline.src_global_shop_offline.customer_gender    IS DISTINCT FROM EXCLUDED.customer_gender OR
      sa_global_shop_offline.src_global_shop_offline.store_city_country IS DISTINCT FROM EXCLUDED.store_city_country OR
      sa_global_shop_offline.src_global_shop_offline.store_id           IS DISTINCT FROM EXCLUDED.store_id OR
      sa_global_shop_offline.src_global_shop_offline.store_name         IS DISTINCT FROM EXCLUDED.store_name OR
      sa_global_shop_offline.src_global_shop_offline.store_type         IS DISTINCT FROM EXCLUDED.store_type OR
      sa_global_shop_offline.src_global_shop_offline.store_manager      IS DISTINCT FROM EXCLUDED.store_manager OR
      sa_global_shop_offline.src_global_shop_offline.store_city         IS DISTINCT FROM EXCLUDED.store_city OR
      sa_global_shop_offline.src_global_shop_offline.employee_name      IS DISTINCT FROM EXCLUDED.employee_name OR
      sa_global_shop_offline.src_global_shop_offline.employee_role      IS DISTINCT FROM EXCLUDED.employee_role OR
      sa_global_shop_offline.src_global_shop_offline.employee_phone     IS DISTINCT FROM EXCLUDED.employee_phone
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_rows
  FROM upserted;

  CALL bl_cl.sp_write_log('sp_load_src_global_shop_offline', v_rows, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('sp_load_src_global_shop_offline', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;


--below, each procedure is going to be loading procedure for TABLES

--CE_REGIONS
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_regions()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(region))               AS region_src_id,
      initcap(lower(btrim(region)))      AS region_name,
      'SA_GLOBAL_SHOP_ONLINE'::varchar   AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar  AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE region IS NOT NULL AND btrim(region) <> ''

    UNION

    SELECT
      lower(btrim(region))               AS region_src_id,
      initcap(lower(btrim(region)))      AS region_name,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar  AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE region IS NOT NULL AND btrim(region) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (region_src_id, source_system, source_entity)
      region_src_id, region_name, source_system, source_entity
    FROM src
    ORDER BY region_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_regions
    (region_id, region_src_id, region_name, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_region_id'),
    s.region_src_id,
    s.region_name,
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  WHERE s.region_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_regions r
      WHERE r.region_src_id = s.region_src_id
        AND r.source_system  = s.source_system
        AND r.source_entity  = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_regions', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_regions', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_COUNTRIES
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_countries()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(country))               AS country_src_id,
      initcap(lower(btrim(country)))      AS country_name,
      lower(btrim(region))                AS region_src_id,
      'SA_GLOBAL_SHOP_ONLINE'::varchar    AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar   AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE country IS NOT NULL AND btrim(country) <> ''
      AND region  IS NOT NULL AND btrim(region)  <> ''

    UNION

    SELECT
      lower(btrim(store_city_country))                 AS country_src_id,
      initcap(lower(btrim(store_city_country)))        AS country_name,
      lower(btrim(region))                             AS region_src_id,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar                AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar               AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE store_city_country IS NOT NULL AND btrim(store_city_country) <> ''
      AND region IS NOT NULL AND btrim(region) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (country_src_id, source_system, source_entity)
      country_src_id, country_name, region_src_id, source_system, source_entity
    FROM src
    ORDER BY country_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_countries
    (country_id, country_src_id, country_name, region_id, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_country_id'),
    s.country_src_id,
    s.country_name,
    COALESCE(r.region_id, -1),
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  LEFT JOIN bl_3nf.ce_regions r
    ON r.region_src_id = s.region_src_id
   AND r.source_system  = s.source_system
   AND r.source_entity  = s.source_entity
  WHERE s.country_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_countries c
      WHERE c.country_src_id = s.country_src_id
        AND c.source_system  = s.source_system
        AND c.source_entity  = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_countries', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_countries', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_CITIES
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_cities()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(city))                  AS city_name_raw,
      lower(btrim(country))               AS country_src_id,
      lower(btrim(city)) || '|' || lower(btrim(country)) AS city_src_id,
      'SA_GLOBAL_SHOP_ONLINE'::varchar    AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar   AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE city IS NOT NULL AND btrim(city) <> ''
      AND country IS NOT NULL AND btrim(country) <> ''

    UNION

    SELECT
      lower(btrim(store_city))            AS city_name_raw,
      lower(btrim(store_city_country))    AS country_src_id,
      lower(btrim(store_city)) || '|' || lower(btrim(store_city_country)) AS city_src_id,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar   AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar  AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE store_city IS NOT NULL AND btrim(store_city) <> ''
      AND store_city_country IS NOT NULL AND btrim(store_city_country) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (city_src_id, source_system, source_entity)
      city_src_id,
      initcap(city_name_raw) AS city_name,
      country_src_id,
      source_system,
      source_entity
    FROM src
    ORDER BY city_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_cities
    (city_id, city_src_id, city_name, country_id, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_city_id'),
    s.city_src_id,
    s.city_name,
    COALESCE(c.country_id, -1),
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  LEFT JOIN bl_3nf.ce_countries c
    ON c.country_src_id = s.country_src_id
   AND c.source_system  = s.source_system
   AND c.source_entity  = s.source_entity
  WHERE s.city_src_id <> 'n. a.|n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_cities x
      WHERE x.city_src_id   = s.city_src_id
        AND x.source_system = s.source_system
        AND x.source_entity = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_cities', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_cities', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_MARKETS
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_markets()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(market))               AS market_src_id,
      initcap(lower(btrim(market)))      AS market_name,
      'SA_GLOBAL_SHOP_ONLINE'::varchar   AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar  AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE market IS NOT NULL AND btrim(market) <> ''

    UNION

    SELECT
      lower(btrim(market))               AS market_src_id,
      initcap(lower(btrim(market)))      AS market_name,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar  AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE market IS NOT NULL AND btrim(market) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (market_src_id, source_system, source_entity)
      market_src_id, market_name, source_system, source_entity
    FROM src
    ORDER BY market_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_markets
    (market_id, market_src_id, market_name, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_market_id'),
    s.market_src_id,
    s.market_name,
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  WHERE s.market_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_markets m
      WHERE m.market_src_id = s.market_src_id
        AND m.source_system  = s.source_system
        AND m.source_entity  = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_markets', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_markets', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_SEGMENTS
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_segments()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(segment))              AS segment_src_id,
      initcap(lower(btrim(segment)))     AS segment_name,
      'SA_GLOBAL_SHOP_ONLINE'::varchar   AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar  AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE segment IS NOT NULL AND btrim(segment) <> ''

    UNION

    SELECT
      lower(btrim(segment))              AS segment_src_id,
      initcap(lower(btrim(segment)))     AS segment_name,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar  AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE segment IS NOT NULL AND btrim(segment) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (segment_src_id, source_system, source_entity)
      segment_src_id, segment_name, source_system, source_entity
    FROM src
    ORDER BY segment_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_segments
    (segment_id, segment_src_id, segment_name, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_segment_id'),
    s.segment_src_id,
    s.segment_name,
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  WHERE s.segment_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_segments t
      WHERE t.segment_src_id = s.segment_src_id
        AND t.source_system  = s.source_system
        AND t.source_entity  = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_segments', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_segments', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_PRODUCT_CATEGORIES
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_product_categories()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(category))             AS category_src_id,
      initcap(lower(btrim(category)))    AS category_name,
      'SA_GLOBAL_SHOP_ONLINE'::varchar   AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar  AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE category IS NOT NULL AND btrim(category) <> ''

    UNION

    SELECT
      lower(btrim(category))             AS category_src_id,
      initcap(lower(btrim(category)))    AS category_name,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar  AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE category IS NOT NULL AND btrim(category) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (category_src_id, source_system, source_entity)
      category_src_id, category_name, source_system, source_entity
    FROM src
    ORDER BY category_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_product_categories
    (category_id, category_src_id, category_name, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_category_id'),
    s.category_src_id,
    s.category_name,
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  WHERE s.category_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_product_categories c
      WHERE c.category_src_id = s.category_src_id
        AND c.source_system   = s.source_system
        AND c.source_entity   = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_product_categories', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_product_categories', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_PRODUCT_SUBCATEGORIES
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_product_subcategories()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(sub_category)) || '|' || lower(btrim(category)) AS sub_category_src_id,
      lower(btrim(sub_category))                                 AS sub_category_name_raw,
      lower(btrim(category))                                     AS category_src_id,
      'SA_GLOBAL_SHOP_ONLINE'::varchar                           AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar                          AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE sub_category IS NOT NULL AND btrim(sub_category) <> ''
      AND category     IS NOT NULL AND btrim(category)     <> ''

    UNION

    SELECT
      lower(btrim(sub_category)) || '|' || lower(btrim(category)) AS sub_category_src_id,
      lower(btrim(sub_category))                                 AS sub_category_name_raw,
      lower(btrim(category))                                     AS category_src_id,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar                          AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar                         AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE sub_category IS NOT NULL AND btrim(sub_category) <> ''
      AND category     IS NOT NULL AND btrim(category)     <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (sub_category_src_id, source_system, source_entity)
      sub_category_src_id,
      initcap(sub_category_name_raw) AS sub_category_name,
      category_src_id,
      source_system,
      source_entity
    FROM src
    ORDER BY sub_category_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_product_subcategories
    (sub_category_id, sub_category_src_id, sub_category_name, category_id, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_sub_category_id'),
    s.sub_category_src_id,
    s.sub_category_name,
    COALESCE(pc.category_id, -1),
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  LEFT JOIN bl_3nf.ce_product_categories pc
    ON pc.category_src_id = s.category_src_id
   AND pc.source_system   = s.source_system
   AND pc.source_entity   = s.source_entity
  WHERE s.sub_category_src_id <> 'n. a.|n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_product_subcategories x
      WHERE x.sub_category_src_id = s.sub_category_src_id
        AND x.source_system       = s.source_system
        AND x.source_entity       = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_product_subcategories', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_product_subcategories', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_PRODUCT_BRANDS
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_product_brands()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(brand))               AS brand_src_id,
      initcap(lower(btrim(brand)))      AS brand_name,
      'SA_GLOBAL_SHOP_ONLINE'::varchar  AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE brand IS NOT NULL AND btrim(brand) <> ''

    UNION

    SELECT
      lower(btrim(brand))               AS brand_src_id,
      initcap(lower(btrim(brand)))      AS brand_name,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE brand IS NOT NULL AND btrim(brand) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (brand_src_id, source_system, source_entity)
      brand_src_id, brand_name, source_system, source_entity
    FROM src
    ORDER BY brand_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_product_brands
    (brand_id, brand_src_id, brand_name, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_brand_id'),
    s.brand_src_id,
    s.brand_name,
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  WHERE s.brand_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_product_brands b
      WHERE b.brand_src_id  = s.brand_src_id
        AND b.source_system = s.source_system
        AND b.source_entity = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_product_brands', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_product_brands', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_PAYMENT_METHODS
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_payment_methods()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(payment_gateway))            AS payment_method_src_id,
      initcap(lower(btrim(payment_gateway)))   AS payment_method_name,
      'SA_GLOBAL_SHOP_ONLINE'::varchar         AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar        AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE payment_gateway IS NOT NULL AND btrim(payment_gateway) <> ''

    UNION

    SELECT
      lower(btrim(payment_type))               AS payment_method_src_id,
      initcap(lower(btrim(payment_type)))      AS payment_method_name,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar        AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar       AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE payment_type IS NOT NULL AND btrim(payment_type) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (payment_method_src_id, source_system, source_entity)
      payment_method_src_id, payment_method_name, source_system, source_entity
    FROM src
    ORDER BY payment_method_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_payment_methods
    (payment_method_id, payment_method_src_id, payment_method_name, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_payment_method_id'),
    s.payment_method_src_id,
    s.payment_method_name,
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  WHERE s.payment_method_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_payment_methods pm
      WHERE pm.payment_method_src_id = s.payment_method_src_id
        AND pm.source_system         = s.source_system
        AND pm.source_entity         = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_payment_methods', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_payment_methods', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_STORE_TYPES
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_store_types()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(store_type))           AS store_type_src_id,
      initcap(lower(btrim(store_type)))  AS store_type,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar  AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE store_type IS NOT NULL AND btrim(store_type) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (store_type_src_id, source_system, source_entity)
      store_type_src_id, store_type, source_system, source_entity
    FROM src
    ORDER BY store_type_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_store_types
    (store_type_id, store_type_src_id, store_type, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_store_type_id'),
    s.store_type_src_id,
    s.store_type,
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  WHERE s.store_type_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_store_types st
      WHERE st.store_type_src_id = s.store_type_src_id
        AND st.source_system     = s.source_system
        AND st.source_entity     = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_store_types', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_store_types', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_STORES
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_stores()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(store_id))             AS store_src_id,
      COALESCE(NULLIF(btrim(store_name),''),'n. a.') AS store_name,
      lower(btrim(store_type))           AS store_type_src_id,
      COALESCE(NULLIF(btrim(store_manager),''),'n. a.') AS store_manager,
      lower(btrim(store_city)) || '|' || lower(btrim(store_city_country)) AS city_src_id,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar  AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE store_id IS NOT NULL AND btrim(store_id) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (store_src_id, source_system, source_entity)
      store_src_id, store_name, store_type_src_id, store_manager, city_src_id, source_system, source_entity
    FROM src
    ORDER BY store_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_stores
    (store_id, store_src_id, store_name, store_type_id, store_manager, city_id,
     source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_store_id'),
    s.store_src_id,
    s.store_name,
    COALESCE(st.store_type_id, -1),
    s.store_manager,
    COALESCE(ci.city_id, -1),
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  LEFT JOIN bl_3nf.ce_store_types st
    ON st.store_type_src_id = s.store_type_src_id
   AND st.source_system     = s.source_system
   AND st.source_entity     = s.source_entity
  LEFT JOIN bl_3nf.ce_cities ci
    ON ci.city_src_id   = s.city_src_id
   AND ci.source_system = s.source_system
   AND ci.source_entity = s.source_entity
  WHERE s.store_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_stores x
      WHERE x.store_src_id  = s.store_src_id
        AND x.source_system = s.source_system
        AND x.source_entity = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_stores', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_stores', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_EMPLOYEES
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_employees()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(employee_id)) AS employee_src_id,
      COALESCE(NULLIF(btrim(employee_name),''),  'n. a.') AS employee_name,
      COALESCE(NULLIF(btrim(employee_role),''),  'n. a.') AS employee_role,
      COALESCE(NULLIF(btrim(employee_phone),''), 'n. a.') AS employee_phone,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar  AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE employee_id IS NOT NULL AND btrim(employee_id) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (employee_src_id, source_system, source_entity)
      employee_src_id,
      employee_name,
      employee_role,
      employee_phone,
      source_system,
      source_entity
    FROM src
    ORDER BY employee_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_employees
    (employee_id, employee_src_id, employee_name, employee_role, employee_phone,
     source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_employee_id'),
    s.employee_src_id,
    s.employee_name,
    s.employee_role,
    s.employee_phone,
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  WHERE s.employee_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_employees e
      WHERE e.employee_src_id = s.employee_src_id
        AND e.source_system   = s.source_system
        AND e.source_entity   = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_employees', v_rows_main, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_employees', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_CUSTOMERS
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_customers()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_main bigint := 0;
BEGIN
  WITH src AS (
    SELECT
      lower(btrim(customer_id))               AS customer_src_id,
      COALESCE(NULLIF(btrim(customer_name),''),'n. a.')   AS customer_name,
      COALESCE(NULLIF(btrim(customer_gender),''),'n. a.') AS customer_gender,
      NULLIF(customer_age,'')::int            AS customer_age,
      COALESCE(NULLIF(btrim(customer_phone),''),'n. a.')  AS customer_phone,
      COALESCE(NULLIF(btrim(customer_email),''),'n. a.')  AS customer_email,
      lower(btrim(city)) || '|' || lower(btrim(country))  AS city_src_id,
      lower(btrim(market))                    AS market_src_id,
      lower(btrim(segment))                   AS segment_src_id,
      'SA_GLOBAL_SHOP_ONLINE'::varchar        AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar       AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE customer_id IS NOT NULL AND btrim(customer_id) <> ''

    UNION

    SELECT
      lower(btrim(customer_id))               AS customer_src_id,
      COALESCE(NULLIF(btrim(customer_name),''),'n. a.')   AS customer_name,
      COALESCE(NULLIF(btrim(customer_gender),''),'n. a.') AS customer_gender,
      NULLIF(customer_age,'')::int            AS customer_age,
      COALESCE(NULLIF(btrim(customer_phone),''),'n. a.')  AS customer_phone,
      COALESCE(NULLIF(btrim(customer_email),''),'n. a.')  AS customer_email,
      lower(btrim(store_city)) || '|' || lower(btrim(store_city_country)) AS city_src_id,
      lower(btrim(market))                    AS market_src_id,
      lower(btrim(segment))                   AS segment_src_id,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar       AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar      AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE customer_id IS NOT NULL AND btrim(customer_id) <> ''
  ),
  src_distinct AS (
    SELECT DISTINCT ON (customer_src_id, source_system, source_entity)
      customer_src_id, customer_name, customer_gender, customer_age, customer_phone, customer_email,
      city_src_id, market_src_id, segment_src_id, source_system, source_entity
    FROM src
    ORDER BY customer_src_id, source_system, source_entity
  )
  INSERT INTO bl_3nf.ce_customers
    (customer_id, customer_src_id, customer_name, customer_gender, customer_age, customer_phone, customer_email,
     city_id, market_id, segment_id, source_system, source_entity, insert_dt, update_dt)
  SELECT
    nextval('bl_3nf.seq_customer_id'),
    s.customer_src_id,
    s.customer_name,
    s.customer_gender,
    s.customer_age,
    s.customer_phone,
    s.customer_email,
    COALESCE(ci.city_id, -1),
    COALESCE(m.market_id, -1),
    COALESCE(se.segment_id, -1),
    s.source_system,
    s.source_entity,
    CURRENT_DATE,
    CURRENT_DATE
  FROM src_distinct s
  LEFT JOIN bl_3nf.ce_cities ci
    ON ci.city_src_id   = s.city_src_id
   AND ci.source_system = s.source_system
   AND ci.source_entity = s.source_entity
  LEFT JOIN bl_3nf.ce_markets m
    ON m.market_src_id  = s.market_src_id
   AND m.source_system  = s.source_system
   AND m.source_entity  = s.source_entity
  LEFT JOIN bl_3nf.ce_segments se
    ON se.segment_src_id = s.segment_src_id
   AND se.source_system  = s.source_system
   AND se.source_entity  = s.source_entity
  WHERE s.customer_src_id <> 'n. a.'
    AND NOT EXISTS (
      SELECT 1
      FROM bl_3nf.ce_customers c
      WHERE c.customer_src_id = s.customer_src_id
        AND c.source_system   = s.source_system
        AND c.source_entity   = s.source_entity
    );

  GET DIAGNOSTICS v_rows_main = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_customers', v_rows_main, 'OK', NULL);
EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_customers', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--CE_PRODUCTS_SCD
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_products_scd(p_run_dttm timestamptz DEFAULT now())
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_closed bigint := 0;
  v_rows_newver bigint := 0;
  v_rows_newbk  bigint := 0;
  v_rows_total  bigint := 0;
BEGIN
WITH src AS (
  SELECT
    lower(btrim(product_id)) AS product_src_id,
    COALESCE(NULLIF(btrim(product_name),''),'n. a.') AS product_name,
    lower(btrim(sub_category)) || '|' || lower(btrim(category)) AS sub_category_src_id,
    lower(btrim(brand)) AS brand_src_id,
    'SA_GLOBAL_SHOP_ONLINE'::varchar  AS source_system,
    'SRC_GLOBAL_SHOP_ONLINE'::varchar AS source_entity
  FROM sa_global_shop_online.src_global_shop_online
  WHERE product_id IS NOT NULL AND btrim(product_id) <> ''

  UNION ALL

  SELECT
    lower(btrim(product_id)) AS product_src_id,
    COALESCE(NULLIF(btrim(product_name),''),'n. a.') AS product_name,
    lower(btrim(sub_category)) || '|' || lower(btrim(category)) AS sub_category_src_id,
    lower(btrim(brand)) AS brand_src_id,
    'SA_GLOBAL_SHOP_OFFLINE'::varchar  AS source_system,
    'SRC_GLOBAL_SHOP_OFFLINE'::varchar AS source_entity
  FROM sa_global_shop_offline.src_global_shop_offline
  WHERE product_id IS NOT NULL AND btrim(product_id) <> ''
),
src_distinct AS (
  SELECT
    product_src_id,
    mode() WITHIN GROUP (ORDER BY product_name)        AS product_name,
    mode() WITHIN GROUP (ORDER BY sub_category_src_id) AS sub_category_src_id,
    mode() WITHIN GROUP (ORDER BY brand_src_id)        AS brand_src_id,
    source_system,
    source_entity
  FROM src
  WHERE product_src_id <> 'n. a.'
  GROUP BY product_src_id, source_system, source_entity
),
src_resolved AS (
  SELECT
    s.product_src_id,
    s.product_name,
    COALESCE(sc.sub_category_id, -1) AS sub_category_id,
    COALESCE(b.brand_id, -1)         AS brand_id,
    s.source_system,
    s.source_entity
  FROM src_distinct s
  LEFT JOIN bl_3nf.ce_product_subcategories sc
    ON sc.sub_category_src_id = s.sub_category_src_id
   AND sc.source_system       = s.source_system
   AND sc.source_entity       = s.source_entity
  LEFT JOIN bl_3nf.ce_product_brands b
    ON b.brand_src_id   = s.brand_src_id
   AND b.source_system  = s.source_system
   AND b.source_entity  = s.source_entity
),
tgt_active AS (
  SELECT DISTINCT ON (product_src_id, source_system, source_entity)
    *
  FROM bl_3nf.ce_products_scd
  WHERE is_active = TRUE
  ORDER BY product_src_id, source_system, source_entity, start_dt DESC
),
to_change_raw AS (
  SELECT
    t.product_id,
    s.product_src_id,
    s.product_name,
    s.sub_category_id,
    s.brand_id,
    s.source_system,
    s.source_entity
  FROM src_resolved s
  JOIN tgt_active t
    ON t.product_src_id = s.product_src_id
   AND t.source_system  = s.source_system
   AND t.source_entity  = s.source_entity
  WHERE
    t.product_name       IS DISTINCT FROM s.product_name
    OR t.sub_category_id IS DISTINCT FROM s.sub_category_id
    OR t.brand_id        IS DISTINCT FROM s.brand_id
),
to_change AS (
  SELECT DISTINCT ON (product_id, source_system, source_entity)
    product_id, product_src_id, product_name, sub_category_id, brand_id, source_system, source_entity
  FROM to_change_raw
  ORDER BY product_id, source_system, source_entity
),
closed AS (
  UPDATE bl_3nf.ce_products_scd t
     SET end_dt   = p_run_dttm - interval '1 second',
         is_active = FALSE
    FROM to_change c
   WHERE t.product_id    = c.product_id
     AND t.source_system = c.source_system
     AND t.source_entity = c.source_entity
     AND t.is_active     = TRUE
  RETURNING 1
),
newver AS (
  INSERT INTO bl_3nf.ce_products_scd
    (product_id, product_src_id, product_name, sub_category_id, brand_id,
     start_dt, end_dt, insert_dt, source_system, source_entity, is_active)
  SELECT
    c.product_id,
    c.product_src_id,
    c.product_name,
    c.sub_category_id,
    c.brand_id,
    p_run_dttm,
    TIMESTAMP '9999-12-31 23:59:59',
    now(),
    c.source_system,
    c.source_entity,
    TRUE
  FROM to_change c
--if already inserted for same product_id at same start_dt, skip
  ON CONFLICT (product_id, start_dt) DO NOTHING
  RETURNING 1
),
to_newbk AS (
  SELECT s.*
  FROM src_resolved s
  LEFT JOIN bl_3nf.ce_products_scd t
    ON t.product_src_id = s.product_src_id
   AND t.source_system  = s.source_system
   AND t.source_entity  = s.source_entity
  WHERE t.product_id IS NULL
),
newbk AS (
  INSERT INTO bl_3nf.ce_products_scd
    (product_id, product_src_id, product_name, sub_category_id, brand_id,
     start_dt, end_dt, insert_dt, source_system, source_entity, is_active)
  SELECT
    nextval('bl_3nf.seq_product_id'),
    n.product_src_id,
    n.product_name,
    n.sub_category_id,
    n.brand_id,
    p_run_dttm,
    TIMESTAMP '9999-12-31 23:59:59',
    now(),
    n.source_system,
    n.source_entity,
    TRUE
  FROM to_newbk n
  ON CONFLICT (product_id, start_dt) DO NOTHING
  RETURNING 1
)
SELECT
  (SELECT COUNT(*) FROM closed),
  (SELECT COUNT(*) FROM newver),
  (SELECT COUNT(*) FROM newbk)
INTO v_rows_closed, v_rows_newver, v_rows_newbk;

v_rows_total := COALESCE(v_rows_closed,0) + COALESCE(v_rows_newver,0) + COALESCE(v_rows_newbk,0);
CALL bl_cl.sp_write_log('load_ce_products_scd', v_rows_total, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_products_scd', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;


--this procedeure will run all other loading procedures we created
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_3nf_all()
LANGUAGE plpgsql
AS $$
DECLARE
  r record;
BEGIN
  CALL bl_cl.sp_check_bl_3nf_objects();

  FOR r IN
    SELECT *
    FROM (VALUES
      ('load_ce_regions'::text),
      ('load_ce_countries'::text),
      ('load_ce_cities'::text),
      ('load_ce_markets'::text),
      ('load_ce_segments'::text),
      ('load_ce_product_categories'::text),
      ('load_ce_product_subcategories'::text),
      ('load_ce_product_brands'::text),
      ('load_ce_payment_methods'::text),
      ('load_ce_store_types'::text),
      ('load_ce_stores'::text),
      ('load_ce_employees'::text),
      ('load_ce_customers'::text),
      ('load_ce_products_scd'::text)
    ) v(proc_name)
  LOOP
    EXECUTE format('CALL bl_cl.%I()', r.proc_name);
  END LOOP;

  CALL bl_cl.sp_write_log('sp_load_3nf_all', 0, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('sp_load_3nf_all', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;


--single ETL run
CREATE OR REPLACE PROCEDURE bl_cl.sp_run_daily_etl()
LANGUAGE plpgsql
AS $$
BEGIN

  CALL bl_cl.sp_load_src_global_shop_online();
  
  CALL bl_cl.sp_load_src_global_shop_offline();

  CALL bl_cl.sp_load_3nf_all();

  CALL bl_cl.sp_write_log('sp_run_daily_etl', 0, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN

  CALL bl_cl.sp_write_log('sp_run_daily_etl', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

 
--check if inserting default rows runs
BEGIN;
CALL bl_cl.sp_init_default_rows();
COMMIT;
--ROLLBACK; (if error)

--single ETL run
BEGIN;
CALL bl_cl.sp_run_daily_etl();
COMMIT;
--ROLLBACK; (if error)

--here we check logs
SELECT * FROM bl_cl.fn_etl_recent_runs(50);

--SCD select
SELECT product_id, product_src_id, product_name, sub_category_id, brand_id,
start_dt, end_dt, is_active, source_system, source_entity, insert_dt
FROM bl_3nf.ce_products_scd
WHERE product_src_id IN ('2252','2139','3199','608','993','917','9999999') AND
source_system LIKE '%OFFLINE%'
ORDER BY product_src_id, start_dt;

select * from bl_3nf.ce_products_scd;