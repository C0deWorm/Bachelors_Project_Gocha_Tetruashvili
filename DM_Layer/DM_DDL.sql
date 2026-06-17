--SCHEMA
CREATE SCHEMA IF NOT EXISTS BL_DM;

--DIM_DATES
CREATE TABLE BL_DM.DIM_DATES (
    	DATE_SURR_ID BIGINT NOT NULL,  
    	EVENT_DT DATE NOT NULL,
		DAY_NUM INT NOT NULL,
		MONTH_NUM INT NOT NULL,
    	YEAR_NUM INT NOT NULL,
    	QUARTER_NUM INT NOT NULL,
    	DAY_OF_WEEK_NUM INT NOT NULL,  
    	TA_INSERT_DT DATE NOT NULL DEFAULT CURRENT_DATE,
    
CONSTRAINT PK_DIM_DATES PRIMARY KEY (DATE_SURR_ID),
CONSTRAINT UQ_DIM_DATES_EVENT_DT UNIQUE (EVENT_DT),
CONSTRAINT CK_DIM_DATES_DAY CHECK (DAY_NUM BETWEEN 1 AND 31),
CONSTRAINT CK_DIM_DATES_MONTH CHECK (MONTH_NUM BETWEEN 1 AND 12),
CONSTRAINT CK_DIM_DATES_QUARTER CHECK (QUARTER_NUM BETWEEN 1 AND 4),
CONSTRAINT CK_DIM_DATES_DAY_OF_WEEK CHECK (DAY_OF_WEEK_NUM BETWEEN 1 AND 7)
);

--DIM_CUSTOMERS
CREATE TABLE IF NOT EXISTS bl_dm.dim_customers (
    customer_id          BIGINT PRIMARY KEY,
    customer_src_id      VARCHAR(255) NOT NULL,
    customer_name        VARCHAR(120) NOT NULL,
    customer_gender      VARCHAR(20)  NOT NULL,
    customer_age         INT          NOT NULL,
    customer_phone       VARCHAR(20)  NOT NULL,
    customer_email       VARCHAR(120) NOT NULL,
    customer_city_id     BIGINT       NOT NULL,
    customer_city_name   VARCHAR(80)  NOT NULL,
    customer_country_id  BIGINT       NOT NULL,
    customer_country_name VARCHAR(80) NOT NULL,
    customer_region_id   BIGINT       NOT NULL,
    customer_region_name VARCHAR(80)  NOT NULL,
    market_id            VARCHAR(30)  NOT NULL,
    market_name          VARCHAR(80)  NOT NULL,
    segment_src_id       VARCHAR(40)  NOT NULL,
    segment_name         VARCHAR(80)  NOT NULL,
    source_system        VARCHAR(50)  NOT NULL,
    source_entity        VARCHAR(100) NOT NULL,
    ta_insert_dt         DATE         NOT NULL,
    ta_update_dt         DATE         NOT NULL,
    CONSTRAINT uq_dim_customers UNIQUE (customer_src_id, source_system)
);


-- DIM_EMPLOYEES
CREATE TABLE IF NOT EXISTS bl_dm.dim_employees (
    employee_id     BIGINT PRIMARY KEY,
    employee_src_id VARCHAR(255) NOT NULL,
    employee_name   VARCHAR(120) NOT NULL,
    employee_role   VARCHAR(60)  NOT NULL,
    employee_phone  VARCHAR(20)  NOT NULL,
    source_system   VARCHAR(50)  NOT NULL,
    source_entity   VARCHAR(100) NOT NULL,
    ta_insert_dt    DATE         NOT NULL,
    ta_update_dt    DATE         NOT NULL,
    CONSTRAINT uq_dim_employees UNIQUE (employee_src_id, source_system)
);


--DIM_STORES
CREATE TABLE IF NOT EXISTS bl_dm.dim_stores (
    store_id        BIGINT PRIMARY KEY,
    store_src_id    VARCHAR(255) NOT NULL,
    store_type_id   VARCHAR(100)  NOT NULL,
    store_city_id   VARCHAR(100)  NOT NULL,
    store_country_id VARCHAR(100) NOT NULL,
    store_region_id VARCHAR(100)  NOT NULL,
    store_name      VARCHAR(120) NOT NULL,
    store_manager   VARCHAR(120) NOT NULL,
    store_type      VARCHAR(100)  NOT NULL,
    store_city      VARCHAR(80)  NOT NULL,
    store_country   VARCHAR(80)  NOT NULL,
    store_region    VARCHAR(80)  NOT NULL,
    source_system   VARCHAR(50)  NOT NULL,
    source_entity   VARCHAR(100) NOT NULL,
    ta_insert_dt    DATE         NOT NULL,
    ta_update_dt    DATE         NOT NULL,
    CONSTRAINT uq_dim_stores UNIQUE (store_src_id, source_system)
);



--DIM_PRODUCTS_SCD
CREATE TABLE IF NOT EXISTS bl_dm.dim_products_scd (
    product_surr_id   BIGINT       NOT NULL,
    product_src_id    VARCHAR(255) NOT NULL,
    sub_category_id   VARCHAR(80)  NOT NULL,
    category_id       VARCHAR(80)  NOT NULL,
    brand_id          VARCHAR(80)  NOT NULL,
    product_name      VARCHAR(255) NOT NULL,
    sub_category_name VARCHAR(80)  NOT NULL,
    category_name     VARCHAR(80)  NOT NULL,
    brand_name        VARCHAR(80)  NOT NULL,
    source_system     VARCHAR(50)  NOT NULL,
    source_entity     VARCHAR(100) NOT NULL,
    start_dt          TIMESTAMP    NOT NULL,
    end_dt            timestamp    NOT NULL,
    is_active         VARCHAR(1)   NOT NULL,
    ta_insert_dt      DATE         NOT NULL,
    ta_update_dt      DATE         NOT NULL,

-- Composite PK because SCD2
    CONSTRAINT pk_dim_products_scd 
        PRIMARY KEY (product_surr_id, start_dt),

-- Business key uniqueness per version
    CONSTRAINT uq_dim_products_scd
        UNIQUE (product_src_id, source_system, source_entity, start_dt),

	CONSTRAINT uq_dim_products_scd_surr UNIQUE (product_surr_id),
	
-- SCD2 logic constraint
    CONSTRAINT ck_dim_products_scd_dates CHECK (
        (is_active = 'Y' AND end_dt = timestamp '9999-12-31 00:00:00')
        OR
        (is_active = 'N' AND end_dt >= start_dt AND end_dt < timestamp '9999-12-31 00:00:00')
    ),

    CONSTRAINT ck_dim_products_scd_is_active CHECK (is_active IN ('Y','N'))
);


--FCT_TRANSACTIONS 
CREATE TABLE IF NOT EXISTS bl_dm.fct_transactions (
    transaction_surr_id      BIGINT        NOT NULL,
    transaction_src_id  VARCHAR(155)  NOT NULL,
    event_dt            DATE          NOT NULL,
    product_surr_id     BIGINT        NOT NULL,
    employee_id         BIGINT        NOT NULL,
    customer_id         BIGINT        NOT NULL,
    store_id            BIGINT        NOT NULL,
    sales               DECIMAL(12,2) NOT NULL,
    profit              DECIMAL(12,2) NOT NULL,
    quantity            INT           NOT NULL,
    shipping_cost       DECIMAL(12,2) NOT NULL,
    unit_price          DECIMAL(12,2) NOT NULL,
    register_number     INT           NOT NULL,
    platform            VARCHAR(50)   NOT NULL,
    browser             VARCHAR(50)   NOT NULL,
    device              VARCHAR(50)   NOT NULL,
    shipping_provider   VARCHAR(60)   NOT NULL,
    shipping_mode       VARCHAR(30)   NOT NULL,
    shipping_number     VARCHAR(80)   NOT NULL,
    delivery_status     VARCHAR(30)   NOT NULL,
    order_priority      VARCHAR(20)   NOT NULL,
    transaction_status  VARCHAR(30)   NOT NULL,
    source_system       VARCHAR(50)   NOT NULL,
    source_entity       VARCHAR(100)  NOT NULL,
    ta_insert_dt        DATE          NOT NULL,
    ta_update_dt        DATE          NOT NULL,
    CONSTRAINT pk_fct_transactions PRIMARY KEY (transaction_surr_id, event_dt),
    CONSTRAINT uq_fct_transactions UNIQUE (transaction_src_id, source_system, event_dt),
    CONSTRAINT fk_dates_fct      FOREIGN KEY (event_dt)        REFERENCES bl_dm.dim_dates(event_dt),
    CONSTRAINT fk_products_fct   FOREIGN KEY (product_surr_id) REFERENCES bl_dm.dim_products_scd(product_surr_id),
    CONSTRAINT fk_employees_fct  FOREIGN KEY (employee_id)     REFERENCES bl_dm.dim_employees(employee_id),
    CONSTRAINT fk_customers_fct  FOREIGN KEY (customer_id)     REFERENCES bl_dm.dim_customers(customer_id),
    CONSTRAINT fk_stores_fct     FOREIGN KEY (store_id)        REFERENCES bl_dm.dim_stores(store_id)
)
PARTITION BY RANGE (event_dt);