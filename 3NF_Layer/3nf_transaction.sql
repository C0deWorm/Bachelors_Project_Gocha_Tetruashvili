--here we create 3NF transactions procedure
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_transactions()
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows bigint := 0;
BEGIN
  INSERT INTO bl_3nf.ce_transactions(
      transaction_id,
      transaction_src_id,
      order_date,
      customer_id,
      product_id,
      payment_method_id,
      store_id,
      employee_id,
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
      register_number,
      transaction_status,
      source_system,
      source_entity,
      insert_dt,
      update_dt
  )
  SELECT
      nextval('bl_3nf.seq_transaction_id'),
      s.transaction_src_id,
      NULLIF(s.order_date,'')::date,
      COALESCE(c.customer_id, -1)                 AS customer_id,
      COALESCE(p.product_id, -1)                  AS product_id,
      COALESCE(pm.payment_method_id, -1)          AS payment_method_id,
      COALESCE(st.store_id, -1)                   AS store_id,
      COALESCE(e.employee_id, -1)                 AS employee_id,
      NULLIF(s.sales,'')::numeric(12,2)           AS sales,
      NULLIF(s.quantity,'')::int                  AS quantity,
      NULLIF(s.profit,'')::numeric(12,2)          AS profit,
      NULLIF(s.shipping_cost,'')::numeric(12,2)   AS shipping_cost,
      COALESCE(s.platform,'n.a.')                 AS platform,
      COALESCE(s.browser,'n.a.')                  AS browser,
      COALESCE(s.device,'n.a.')                   AS device,
      COALESCE(s.shipping_provider,'n.a.')        AS shipping_provider,
      COALESCE(s.shipping_mode,'n.a.')            AS shipping_mode,
      COALESCE(s.tracking_number,'n.a.')          AS tracking_number,
      COALESCE(s.delivery_status,'n.a.')          AS delivery_status,
      COALESCE(s.payment_gateway,'n.a.')          AS payment_gateway,
      COALESCE(s.order_priority,'n.a.')           AS order_priority,
      NULLIF(s.register_number,'')::int           AS register_number,
      COALESCE(s.transaction_status,'n.a.')       AS transaction_status,
      s.source_system,
      s.source_entity,
      CURRENT_DATE,
      CURRENT_DATE
  FROM (
    -- ONLINE
    SELECT
      lower(btrim(online_order_id)) AS transaction_src_id,
      order_date,
      lower(btrim(customer_id))     AS customer_src_id,
      lower(btrim(product_id))      AS product_src_id,
      lower(btrim(payment_gateway)) AS payment_method_src_id,
      NULL::varchar                 AS store_src_id,
      NULL::varchar                 AS employee_src_id,
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
      NULL::varchar                 AS register_number,
      NULL::varchar                 AS transaction_status,
      'SA_GLOBAL_SHOP_ONLINE'::varchar  AS source_system,
      'SRC_GLOBAL_SHOP_ONLINE'::varchar AS source_entity
    FROM sa_global_shop_online.src_global_shop_online
    WHERE online_order_id IS NOT NULL AND btrim(online_order_id) <> ''

    UNION ALL

    -- OFFLINE
    SELECT
      lower(btrim(transaction_id))  AS transaction_src_id,
      order_date,
      lower(btrim(customer_id))     AS customer_src_id,
      lower(btrim(product_id))      AS product_src_id,
      lower(btrim(payment_type))    AS payment_method_src_id,
      lower(btrim(store_id))        AS store_src_id,
      lower(btrim(employee_id))     AS employee_src_id,
      sales,
      quantity,
      profit,
      shipping_cost,
      NULL::varchar                 AS platform,
      NULL::varchar                 AS browser,
      NULL::varchar                 AS device,
      NULL::varchar                 AS shipping_provider,
      NULL::varchar                 AS shipping_mode,
      NULL::varchar                 AS tracking_number,
      NULL::varchar                 AS delivery_status,
      payment_type                  AS payment_gateway,
      NULL::varchar                 AS order_priority,
      register_number::varchar      AS register_number,
      transaction_status::varchar   AS transaction_status,
      'SA_GLOBAL_SHOP_OFFLINE'::varchar  AS source_system,
      'SRC_GLOBAL_SHOP_OFFLINE'::varchar AS source_entity
    FROM sa_global_shop_offline.src_global_shop_offline
    WHERE transaction_id IS NOT NULL AND btrim(transaction_id) <> ''
  ) s
  LEFT JOIN bl_3nf.ce_customers c
    ON c.customer_src_id = s.customer_src_id
   AND c.source_system   = s.source_system
   AND c.source_entity   = s.source_entity
  LEFT JOIN bl_3nf.ce_products_scd p
    ON p.product_src_id  = s.product_src_id
   AND p.source_system   = s.source_system
   AND p.source_entity   = s.source_entity
   AND p.is_active       = TRUE
  LEFT JOIN bl_3nf.ce_payment_methods pm
    ON pm.payment_method_src_id = s.payment_method_src_id
   AND pm.source_system         = s.source_system
   AND pm.source_entity         = s.source_entity
  LEFT JOIN bl_3nf.ce_stores st
    ON st.store_src_id   = s.store_src_id
   AND st.source_system  = s.source_system
   AND st.source_entity  = s.source_entity
  LEFT JOIN bl_3nf.ce_employees e
    ON e.employee_src_id = s.employee_src_id
   AND e.source_system   = s.source_system
   AND e.source_entity   = s.source_entity
  WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_transactions t
    WHERE t.transaction_src_id = s.transaction_src_id
      AND t.source_system      = s.source_system
      AND t.source_entity      = s.source_entity
  );

  GET DIAGNOSTICS v_rows = ROW_COUNT;
  CALL bl_cl.sp_write_log('load_ce_transactions', v_rows, 'OK', NULL);

EXCEPTION WHEN OTHERS THEN
  CALL bl_cl.sp_write_log('load_ce_transactions', 0, 'ERROR', SQLERRM);
  RAISE;
END;
$$;

--run procedure
CALL bl_cl.load_ce_transactions()

--check log
SELECT *
FROM bl_cl.mta_etl_logs
WHERE procedure_name = 'load_ce_transactions'
ORDER BY log_dttm DESC;

--transactions select
SELECT count(*)
FROM bl_3nf.ce_transactions
where transaction_src_id = 'o-1'

--customer select 
SELECT *
FROM bl_3nf.ce_customers
WHERE customer_id = ''

--check for duplicates
SELECT
    transaction_src_id,
    source_system,
    source_entity,
    COUNT(*) AS cnt
FROM bl_3nf.ce_transactions
GROUP BY
    transaction_src_id,
    source_system,
    source_entity
HAVING COUNT(*) > 1;

