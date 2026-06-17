--Enabling FDW for database
CREATE EXTENSION IF NOT EXISTS file_fdw;

--Create schema for dataset
CREATE SCHEMA IF NOT EXISTS SA_GLOBAL_SHOP_ONLINE;

--Create FDW server
CREATE SERVER IF NOT EXISTS GLOBAL_SHOP_ONLINE
FOREIGN DATA WRAPPER file_fdw;

--Creating and INSERTING data from a GLOBAL_SHOP_ONLINE dataset to EXTERNAL TABLE
CREATE FOREIGN TABLE IF NOT EXISTS SA_GLOBAL_SHOP_ONLINE.EXT_GLOBAL_SHOP_ONLINE (
    online_order_id		VARCHAR(255),
	order_date			VARCHAR(255),
	customer_id			VARCHAR(255),
	region				VARCHAR(255),
	market				VARCHAR(255),
	segment				VARCHAR(255),
	product_id			VARCHAR(255),
	product_name		VARCHAR(255),
	category			VARCHAR(255),
	sub_category		VARCHAR(255),
	brand				VARCHAR(255),
	sales				VARCHAR(255),
	quantity			VARCHAR(255),
	profit				VARCHAR(255),
	shipping_cost		VARCHAR(255),
	platform			VARCHAR(255),
	browser				VARCHAR(255),
	device				VARCHAR(255),
	shipping_provider	VARCHAR(255),
	shipping_mode		VARCHAR(255),
	tracking_number		VARCHAR(255),
	delivery_status		VARCHAR(255),
	payment_gateway		VARCHAR(255),
	order_priority		VARCHAR(255),
	source_system		VARCHAR(255),
	customer_name		VARCHAR(255),
	city				VARCHAR(255),
	country				VARCHAR(255),
	customer_phone		VARCHAR(255),
	customer_email		VARCHAR(255),
	customer_age		VARCHAR(255),
	customer_gender		VARCHAR(255)
)
SERVER GLOBAL_SHOP_ONLINE
OPTIONS (
    FILENAME 'C:/Program Files/PostgreSQL/18/data/datasets/global_shop_online.csv',
    FORMAT 'csv',
	HEADER 'TRUE'
);

--Creating SOURCE TABLE
CREATE TABLE IF NOT EXISTS SA_GLOBAL_SHOP_ONLINE.SRC_GLOBAL_SHOP_ONLINE (
    online_order_id		VARCHAR(255),
	order_date			VARCHAR(255),
	customer_id			VARCHAR(255),
	region				VARCHAR(255),
	market				VARCHAR(255),
	segment				VARCHAR(255),
	product_id			VARCHAR(255),
	product_name		VARCHAR(255),
	category			VARCHAR(255),
	sub_category		VARCHAR(255),
	brand				VARCHAR(255),
	sales				VARCHAR(255),
	quantity			VARCHAR(255),
	profit				VARCHAR(255),
	shipping_cost		VARCHAR(255),
	platform			VARCHAR(255),
	browser				VARCHAR(255),
	device				VARCHAR(255),
	shipping_provider	VARCHAR(255),
	shipping_mode		VARCHAR(255),
	tracking_number		VARCHAR(255),
	delivery_status		VARCHAR(255),
	payment_gateway		VARCHAR(255),
	order_priority		VARCHAR(255),
	source_system		VARCHAR(255),
	customer_name		VARCHAR(255),
	city				VARCHAR(255),
	country				VARCHAR(255),
	customer_phone		VARCHAR(255),
	customer_email		VARCHAR(255),
	customer_age		VARCHAR(255),
	customer_gender		VARCHAR(255),
	CONSTRAINT uq_src_global_shop_online UNIQUE (online_order_id)
);



SELECT * 
FROM SA_GLOBAL_SHOP_ONLINE.SRC_GLOBAL_SHOP_ONLINE;

SELECT * 
FROM SA_GLOBAL_SHOP_ONLINE.EXT_GLOBAL_SHOP_ONLINE;
