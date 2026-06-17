--Enabling FDW for database
CREATE EXTENSION IF NOT EXISTS file_fdw;

--Create schema for dataset
CREATE SCHEMA IF NOT EXISTS SA_GLOBAL_SHOP_OFFLINE;

--Create FDW server
CREATE SERVER IF NOT EXISTS GLOBAL_SHOP_OFFLINE
FOREIGN DATA WRAPPER file_fdw;

--Creating and INSERTING data from a GLOBAL_SHOP_OFFLINE dataset to EXTERNAL TABLE
CREATE FOREIGN TABLE IF NOT EXISTS SA_GLOBAL_SHOP_OFFLINE.EXT_GLOBAL_SHOP_OFFLINE (
	transaction_id			VARCHAR(255),
	order_date				VARCHAR(255),
	customer_id				VARCHAR(255),
	region					VARCHAR(255),
	market					VARCHAR(255),
	segment					VARCHAR(255),
	product_id				VARCHAR(255),
	product_name			VARCHAR(255),
	category				VARCHAR(255),
	sub_category			VARCHAR(255),
	brand					VARCHAR(255),
	sales					VARCHAR(255),
	quantity				VARCHAR(255),
	profit					VARCHAR(255),
	shipping_cost			VARCHAR(255),
	employee_id				VARCHAR(255),
	payment_type			VARCHAR(255),
	register_number			VARCHAR(255),
	transaction_status		VARCHAR(255),
	source_system			VARCHAR(255),
	customer_name			VARCHAR(255),
	city					VARCHAR(255),
	country					VARCHAR(255),
	customer_phone			VARCHAR(255),
	customer_email			VARCHAR(255),
	customer_age			VARCHAR(255),
	customer_gender			VARCHAR(255),
	store_city_country		VARCHAR(255),
	store_id				VARCHAR(255),
	store_name				VARCHAR(255),
	store_type				VARCHAR(255),
	store_manager			VARCHAR(255),
	store_city				VARCHAR(255),
	employee_name			VARCHAR(255),
	employee_role			VARCHAR(255),
	employee_phone			VARCHAR(255)
)
SERVER GLOBAL_SHOP_OFFLINE
OPTIONS (
    FILENAME 'C:/Program Files/PostgreSQL/18/data/datasets/global_shop_offline.csv',
    FORMAT 'csv',
	HEADER 'TRUE'
);

--Creating SOURCE TABLE
CREATE TABLE IF NOT EXISTS SA_GLOBAL_SHOP_OFFLINE.SRC_GLOBAL_SHOP_OFFLINE (
	transaction_id			VARCHAR(255),
	order_date				VARCHAR(255),
	customer_id				VARCHAR(255),
	region					VARCHAR(255),
	market					VARCHAR(255),
	segment					VARCHAR(255),
	product_id				VARCHAR(255),
	product_name			VARCHAR(255),
	category				VARCHAR(255),
	sub_category			VARCHAR(255),
	brand					VARCHAR(255),
	sales					VARCHAR(255),
	quantity				VARCHAR(255),
	profit					VARCHAR(255),
	shipping_cost			VARCHAR(255),
	employee_id				VARCHAR(255),
	payment_type			VARCHAR(255),
	register_number			VARCHAR(255),
	transaction_status		VARCHAR(255),
	source_system			VARCHAR(255),
	customer_name			VARCHAR(255),
	city					VARCHAR(255),
	country					VARCHAR(255),
	customer_phone			VARCHAR(255),
	customer_email			VARCHAR(255),
	customer_age			VARCHAR(255),
	customer_gender			VARCHAR(255),
	store_city_country		VARCHAR(255),
	store_id				VARCHAR(255),
	store_name				VARCHAR(255),
	store_type				VARCHAR(255),
	store_manager			VARCHAR(255),
	store_city				VARCHAR(255),
	employee_name			VARCHAR(255),
	employee_role			VARCHAR(255),
	employee_phone			VARCHAR(255),
	CONSTRAINT uq_src_global_shop_offline UNIQUE (transaction_id)
);


SELECT * 
FROM SA_GLOBAL_SHOP_OFFLINE.EXT_GLOBAL_SHOP_OFFLINE;

SELECT * 
FROM SA_GLOBAL_SHOP_OFFLINE.SRC_GLOBAL_SHOP_OFFLINE;
