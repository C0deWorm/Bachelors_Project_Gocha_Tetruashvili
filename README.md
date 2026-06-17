#  Data Warehouse და Power BI რეპორტი

## პროექტის აღწერა

პროექტი შექმნილია გლობალური მაღაზიის dataset - ზე დაფუძნებულ სრულ Data Warehouse გადაწყვეტას.

მონაცემები იტვირთება ორი წყაროდან (ონლაინ და ოფლაინ გაყიდვები), შემდეგ გადის ETL პროცესს PostgreSQL-ში, ტრანსფორმირდება 3NF ბიზნეს ფენაში, გადადის Dimensional Model (Star Schema) ფენაში და საბოლოოდ ვიზუალიზდება Power BI-ში.

პროექტი შეეხება შემდეგ თემებს:

* ETL პროცესები
* Incremental Load
* Slowly Changing Dimension Type 2
* ფაქტების ცხრილის partitioning
* მონაცემთა ხარისხის კონტროლს
* ბიზნეს ანალიტიკას Power BI-ში

---

## არქიტექტურა

წყაროების ფენა

* SA_GLOBAL_SHOP_ONLINE
* SA_GLOBAL_SHOP_OFFLINE

↓

ბიზნეს ფენა (3NF)

* BL_3NF

↓

განზომილებიანი მოდელი

* BL_DM

↓

Power BI Dashboard

---

## პროექტის სტრუქტურა

```text
.
├── etl_datasets/
├── etl_scripts/
├── powerbi/
└── docs/
```

---

## გაშვების თანმიმდევრობა

SQL ფაილები უნდა გაეშვას შემდეგი თანმიმდევრობით:

1. GLOBAL_SHOP_ONLINE_SCRIPT.sql
2. GLOBAL_SHOP_OFFLINE_SCRIPT.sql
3. 3NF_DDL.sql
4. 3NF_PROCEDURES.sql
5. 3nf_transactions.sql
6. DM_DDL.sql
7. DM_PROCEDURES.sql
8. dm_transaction.sql


---

## Incremental Load-ის დემონსტრაცია

პროექტში გამოყენებულია მონაცემთა ორი ვერსია.

### Initial Load

იტვირთება:

* global_shop_online_v2.csv
* global_shop_offline_v2.csv

ეშვება სრულყოფილად ETL პროცესები.

### Incremental Load

წყაროები იცვლება:

* global_shop_online.csv
* global_shop_offline.csv

ETL პროცესი ეშვება ახლიდან.

პროცედურები ამატებს ახალ ჩანაწერებს, აახლებს შეცვლილ მონაცემებს და არ უშვებს დუბლიკატების ხელახლა ჩატვირთვას.

---

## ძირითადი ფუნქციონალი

* ონლაინ და ოფლაინ წყაროების ინტეგრაცია
* 3NF ბიზნეს ფენა
* Star Schema მონაცემთა მოდელი
* Incremental ETL
* SCD Type 2 პროდუქტებისთვის
* ფაქტების ცხრილის partitioning
* მონაცემთა ხარისხის კონტროლი
* ETL ლოგირება და მონიტორინგი
* Power BI ანალიტიკა

---


## გამოყენებული ტექნოლოგიები

* PostgreSQL
* SQL / PLpgSQL
* Power BI Desktop
* Data Warehouse Architecture
* ETL პროცესები

---

## ავტორი

გოჩა თეთრუაშვილი
