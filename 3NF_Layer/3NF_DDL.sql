--Creating SCHEMA

CREATE SCHEMA IF NOT EXISTS BL_3NF;

--Creating sequences
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_region_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_country_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_city_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_market_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_segment_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_category_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_sub_category_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_brand_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_payment_method_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_store_type_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_store_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_employee_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_customer_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_product_id	START WITH 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_transaction_id	START WITH 1;

--Creating TABLES

--Geographic hierarchy
CREATE TABLE IF NOT EXISTS BL_3NF.CE_REGIONS (
	region_id      BIGINT PRIMARY KEY,
	region_src_id  VARCHAR(100),
	region_name    VARCHAR(80),
	source_system  VARCHAR(50),
	source_entity  VARCHAR(100),
	insert_dt      DATE,
	update_dt      DATE
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_COUNTRIES (
	country_id     BIGINT PRIMARY KEY,
	country_src_id VARCHAR(100),
	country_name   VARCHAR(80),
	region_id      BIGINT NOT NULL REFERENCES BL_3NF.CE_REGIONS(region_id),
	source_system  VARCHAR(50),
	source_entity  VARCHAR(100),
	insert_dt      DATE,
	update_dt      DATE
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_CITIES (
	city_id        BIGINT PRIMARY KEY,
	city_src_id    VARCHAR(255),
	city_name      VARCHAR(80),
	country_id     BIGINT NOT NULL REFERENCES BL_3NF.CE_COUNTRIES(country_id),
	source_system  VARCHAR(50),
	source_entity  VARCHAR(100),
	insert_dt      DATE,
	update_dt      DATE
);


--Customers related TABLES
CREATE TABLE IF NOT EXISTS BL_3NF.CE_MARKETS (
	market_id      BIGINT PRIMARY KEY,
	market_src_id  VARCHAR(100),
	market_name    VARCHAR(80),
	source_system  VARCHAR(50),
	source_entity  VARCHAR(100),
	insert_dt      DATE,
	update_dt      DATE
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_SEGMENTS (
	segment_id     BIGINT PRIMARY KEY,
	segment_src_id VARCHAR(100),
	segment_name   VARCHAR(80),
	source_system  VARCHAR(50),
	source_entity  VARCHAR(100),
	insert_dt      DATE,
	update_dt      DATE
);

--Creating products TABLE related TABLES
CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCT_CATEGORIES (
	category_id     BIGINT PRIMARY KEY,
	category_src_id VARCHAR(100),
	category_name   VARCHAR(80),
	source_system   VARCHAR(50),
	source_entity   VARCHAR(100),
	insert_dt       DATE,
	update_dt       DATE
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCT_SUBCATEGORIES (
	sub_category_id     BIGINT PRIMARY KEY,
	sub_category_src_id VARCHAR(100),
	sub_category_name   VARCHAR(80),
	category_id         BIGINT NOT NULL REFERENCES BL_3NF.CE_PRODUCT_CATEGORIES(category_id),
	source_system       VARCHAR(50),
	source_entity       VARCHAR(100),
	insert_dt           DATE,
	update_dt           DATE
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCT_BRANDS (
	brand_id      BIGINT PRIMARY KEY,
	brand_src_id  VARCHAR(255),
	brand_name    VARCHAR(255),
	source_system VARCHAR(50),
	source_entity VARCHAR(100),
	insert_dt     DATE,
	update_dt     DATE
);

--Creating product SCD2 TABLE
--Here I didm't make product_id as PK, or make PK per se, because PRODUCT table cannot be physically connected to FACTS TRANSACTION TABLE
CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCTS_SCD (
	product_id      BIGINT NOT NULL,
	product_src_id  VARCHAR(255) NOT NULL,
	product_name    VARCHAR(255),
	sub_category_id BIGINT NOT NULL REFERENCES BL_3NF.CE_PRODUCT_SUBCATEGORIES(sub_category_id),
	brand_id        BIGINT NOT NULL REFERENCES BL_3NF.CE_PRODUCT_BRANDS(brand_id),
	start_dt        TIMESTAMP NOT NULL,
	end_dt          TIMESTAMP NOT NULL,
	insert_dt       TIMESTAMP,
	source_system   VARCHAR(50),
	source_entity   VARCHAR(100),
	is_active       BOOLEAN NOT NULL,
	CONSTRAINT PK_CE_PRODUCTS_SCD PRIMARY KEY (product_id, start_dt)
);

--Creating payment methods TABLE
CREATE TABLE IF NOT EXISTS BL_3NF.CE_PAYMENT_METHODS (
	payment_method_id     BIGINT PRIMARY KEY,
	payment_method_src_id VARCHAR(100),
	payment_method_name   VARCHAR(50),
	source_system         VARCHAR(50),
	source_entity         VARCHAR(100),
	insert_dt             DATE,
	update_dt             DATE
);

--Creating STORES TABLE related TABLE first and than STORES TABLE
CREATE TABLE IF NOT EXISTS BL_3NF.CE_STORE_TYPES (
	store_type_id      BIGINT PRIMARY KEY,
	store_type_src_id  VARCHAR(100),
	store_type         VARCHAR(40),
	source_system      VARCHAR(50),
	source_entity      VARCHAR(100),
	insert_dt          DATE,
	update_dt          DATE
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_STORES (
	store_id      BIGINT PRIMARY KEY,
	store_src_id  VARCHAR(255),
	store_name    VARCHAR(120),
	store_type_id BIGINT NOT NULL REFERENCES BL_3NF.CE_STORE_TYPES(store_type_id),
	store_manager VARCHAR(120),
	city_id       BIGINT NOT NULL REFERENCES BL_3NF.CE_CITIES(city_id),
	source_system VARCHAR(50),
	source_entity VARCHAR(100),
	insert_dt     DATE,
	update_dt     DATE
);

--Creating employees TABLE(I did it here because first we had to create store TABLE first)
CREATE TABLE IF NOT EXISTS BL_3NF.CE_EMPLOYEES (
	employee_id      BIGINT PRIMARY KEY,
	employee_src_id  VARCHAR(255),
	employee_name    VARCHAR(120),
	employee_role    VARCHAR(80),
	employee_phone   VARCHAR(20),
	source_system    VARCHAR(50),
	source_entity    VARCHAR(100),
	insert_dt        DATE,
	update_dt        DATE
);

--Creating customers TABLE(also created late because we had to create geographycal and customer related TABLES first)
CREATE TABLE IF NOT EXISTS BL_3NF.CE_CUSTOMERS (
	customer_id      BIGINT PRIMARY KEY,
	customer_src_id  VARCHAR(255),
	customer_name    VARCHAR(120),
	customer_gender  VARCHAR(20),
	customer_age     INT,
	customer_phone   VARCHAR(20),
	customer_email   VARCHAR(120),
	city_id          BIGINT NOT NULL REFERENCES BL_3NF.CE_CITIES(city_id),
	market_id        BIGINT NOT NULL REFERENCES BL_3NF.CE_MARKETS(market_id),
	segment_id       BIGINT NOT NULL REFERENCES BL_3NF.CE_SEGMENTS(segment_id),
	source_system    VARCHAR(50),
	source_entity    VARCHAR(100),
	insert_dt        DATE,
	update_dt        DATE
);

--Creating FACT TABLE(transactions)
CREATE TABLE IF NOT EXISTS BL_3NF.CE_TRANSACTIONS (
	transaction_id	  BIGINT PRIMARY KEY,
	transaction_src_id  VARCHAR(255),
	order_date          DATE,
	customer_id         BIGINT NOT NULL REFERENCES BL_3NF.CE_CUSTOMERS(customer_id),
	product_id          BIGINT NOT NULL, --This connects products to transactions logically, so there is no physical dependancy
	payment_method_id   BIGINT NOT NULL REFERENCES BL_3NF.CE_PAYMENT_METHODS(payment_method_id),
	store_id            BIGINT NOT NULL REFERENCES BL_3NF.CE_STORES(store_id),
	employee_id         BIGINT NOT NULL REFERENCES BL_3NF.CE_EMPLOYEES(employee_id),
	sales               DECIMAL(12,2),
	quantity            INT,
	profit              DECIMAL(12,2),
	shipping_cost       DECIMAL(12,2),
	platform            VARCHAR(50),
	browser             VARCHAR(50),
	device              VARCHAR(50),
	shipping_provider   VARCHAR(80),
	shipping_mode       VARCHAR(30),
	tracking_number     VARCHAR(50),
	delivery_status     VARCHAR(30),
	payment_gateway     VARCHAR(30),
	order_priority      VARCHAR(20),
	register_number     INT,
	transaction_status  VARCHAR(30),
	source_system       VARCHAR(50),
	source_entity       VARCHAR(100),
	insert_dt           DATE,
	update_dt           DATE
);
