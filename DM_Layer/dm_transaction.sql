--here we create DM transactions procedure, which will load transactions made in last three months
CREATE OR REPLACE PROCEDURE bl_cl.load_fct_transactions_dm(
    p_refresh_months int DEFAULT 3
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_min_month  date;
    v_max_month  date;
    v_refresh_start date;

    v_m           date;
    v_next_month  date;

    v_part_name   text;
    v_stage_name  text;

    v_rows_total  bigint := 0;
    v_rows_month  bigint := 0;
BEGIN


    SELECT
        date_trunc('month', MIN(order_date))::date,
        date_trunc('month', MAX(order_date))::date
    INTO v_min_month, v_max_month
    FROM bl_3nf.ce_transactions;

    IF v_min_month IS NULL THEN
        CALL bl_cl.sp_write_log('load_fct_transactions_dm',0,'OK',NULL);
        RETURN;
    END IF;


    v_refresh_start :=
        date_trunc('month', CURRENT_DATE)::date
        - ((GREATEST(p_refresh_months,1)-1) * interval '1 month');

    v_m := v_min_month;

    WHILE v_m <= v_max_month LOOP

        v_next_month := (v_m + interval '1 month')::date;
        v_part_name  := format('fct_transactions_%s', to_char(v_m,'YYYYMM'));
        v_stage_name := format('%s_stage_%s', v_part_name, to_char(current_date,'YYYYMMDD'));


        IF to_regclass('bl_dm.' || v_part_name) IS NOT NULL
           AND v_m < v_refresh_start THEN

            v_m := v_next_month;
            CONTINUE;

        END IF;


        EXECUTE format('DROP TABLE IF EXISTS bl_dm.%I;', v_stage_name);

        EXECUTE format(
            'CREATE TABLE bl_dm.%I (LIKE bl_dm.fct_transactions INCLUDING DEFAULTS INCLUDING CONSTRAINTS);',
            v_stage_name
        );

        EXECUTE format(
          'ALTER TABLE bl_dm.%I ADD CONSTRAINT %I CHECK (event_dt >= DATE %L AND event_dt < DATE %L);',
          v_stage_name,
          v_stage_name || '_chk_event_dt',
          v_m::text,
          v_next_month::text
        );


        EXECUTE format($sql$

          INSERT INTO bl_dm.%I
          SELECT
              t.transaction_id,
              t.transaction_src_id,
              t.order_date,

              COALESCE(dp_dt.product_surr_id, dp_act.product_surr_id, -1),
              COALESCE(de.employee_id,-1),
              COALESCE(dc.customer_id,-1),
              COALESCE(ds.store_id,-1),

              COALESCE(t.sales,0)::numeric(12,2),
              COALESCE(t.profit,0)::numeric(12,2),
              COALESCE(t.quantity,0)::int,
              COALESCE(t.shipping_cost,0)::numeric(12,2),

              CASE
                 WHEN COALESCE(t.quantity,0)=0 THEN 0
                 ELSE round((t.sales/NULLIF(t.quantity,0))::numeric,2)
              END,

              COALESCE(t.register_number,-1),
              COALESCE(NULLIF(t.platform,''),'n.a.'),
              COALESCE(NULLIF(t.browser,''),'n.a.'),
              COALESCE(NULLIF(t.device,''),'n.a.'),
              COALESCE(NULLIF(t.shipping_provider,''),'n.a.'),
              COALESCE(NULLIF(t.shipping_mode,''),'n.a.'),
              COALESCE(NULLIF(t.tracking_number,''),'n.a.'),
              COALESCE(NULLIF(t.delivery_status,''),'n.a.'),
              COALESCE(NULLIF(t.order_priority,''),'n.a.'),
              COALESCE(NULLIF(t.transaction_status,''),'n.a.'),

              t.source_system,
              t.source_entity,
              CURRENT_DATE,
              CURRENT_DATE

          FROM bl_3nf.ce_transactions t

          LEFT JOIN bl_3nf.ce_customers c3
                 ON c3.customer_id = t.customer_id
          LEFT JOIN bl_dm.dim_customers dc
                 ON dc.customer_src_id = c3.customer_src_id
                AND dc.source_system = c3.source_system

          LEFT JOIN bl_3nf.ce_employees e3
                 ON e3.employee_id = t.employee_id
          LEFT JOIN bl_dm.dim_employees de
                 ON de.employee_src_id = e3.employee_src_id
                AND de.source_system = e3.source_system

          LEFT JOIN bl_3nf.ce_stores s3
                 ON s3.store_id = t.store_id
          LEFT JOIN bl_dm.dim_stores ds
                 ON ds.store_src_id = s3.store_src_id
                AND ds.source_system = s3.source_system

          LEFT JOIN bl_3nf.ce_products_scd p3_dt
                 ON p3_dt.product_id = t.product_id
                AND p3_dt.source_system = t.source_system
                AND p3_dt.source_entity = t.source_entity
                AND t.order_date BETWEEN p3_dt.start_dt AND p3_dt.end_dt

          LEFT JOIN bl_3nf.ce_products_scd p3_act
                 ON p3_act.product_id = t.product_id
                AND p3_act.source_system = t.source_system
                AND p3_act.source_entity = t.source_entity
                AND p3_act.is_active = TRUE

          LEFT JOIN bl_dm.dim_products_scd dp_dt
                 ON dp_dt.product_src_id =
                    COALESCE(p3_dt.product_src_id,p3_act.product_src_id)
                AND dp_dt.source_system =
                    COALESCE(p3_dt.source_system,p3_act.source_system)
                AND dp_dt.source_entity =
                    COALESCE(p3_dt.source_entity,p3_act.source_entity)
                AND t.order_date BETWEEN dp_dt.start_dt AND dp_dt.end_dt

          LEFT JOIN bl_dm.dim_products_scd dp_act
                 ON dp_act.product_src_id =
                    COALESCE(p3_dt.product_src_id,p3_act.product_src_id)
                AND dp_act.source_system =
                    COALESCE(p3_dt.source_system,p3_act.source_system)
                AND dp_act.source_entity =
                    COALESCE(p3_dt.source_entity,p3_act.source_entity)
                AND dp_act.is_active = 'Y'

          WHERE t.order_date >= DATE %L
            AND t.order_date <  DATE %L

        $sql$, v_stage_name, v_m::text, v_next_month::text);

        GET DIAGNOSTICS v_rows_month = ROW_COUNT;
        v_rows_total := v_rows_total + COALESCE(v_rows_month,0);


        IF to_regclass('bl_dm.' || v_part_name) IS NOT NULL THEN

            EXECUTE format(
                'ALTER TABLE bl_dm.fct_transactions DETACH PARTITION bl_dm.%I;',
                v_part_name
            );

            EXECUTE format(
                'DROP TABLE bl_dm.%I;',
                v_part_name
            );

        END IF;


        EXECUTE format(
            'ALTER TABLE bl_dm.fct_transactions ATTACH PARTITION bl_dm.%I
             FOR VALUES FROM (%L) TO (%L);',
            v_stage_name,
            v_m::text,
            v_next_month::text
        );

        EXECUTE format(
            'ALTER TABLE bl_dm.%I RENAME TO %I;',
            v_stage_name,
            v_part_name
        );

        v_m := v_next_month;

    END LOOP;

    CALL bl_cl.sp_write_log('load_fct_transactions_dm',v_rows_total,'OK',NULL);

EXCEPTION WHEN OTHERS THEN
    CALL bl_cl.sp_write_log('load_fct_transactions_dm',0,'ERROR',SQLERRM);
    RAISE;
END;
$$;

--calling procedure
CALL bl_cl.load_fct_transactions_dm()

--check transactions that were loaded
SELECT count(*)
FROM bl_dm.fct_transactions

--check log
SELECT *
FROM bl_cl.mta_etl_logs 
WHERE procedure_name = 'load_fct_transactions_dm'
ORDER BY log_dttm DESC;

--customer select
SELECT * 
FROM bl_dm.dim_customers
WHERE customer_id = 729

--product select
SELECT *
FROM bl_dm.dim_products_scd
WHERE product_surr_id = 4155