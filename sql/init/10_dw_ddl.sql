DROP TABLE IF EXISTS dw.fact_sales;
DROP TABLE IF EXISTS dw.dim_product;
DROP TABLE IF EXISTS dw.dim_supplier;
DROP TABLE IF EXISTS dw.dim_store;
DROP TABLE IF EXISTS dw.dim_seller;
DROP TABLE IF EXISTS dw.dim_customer;
DROP TABLE IF EXISTS dw.dim_date;
DROP TABLE IF EXISTS dw.dim_material;
DROP TABLE IF EXISTS dw.dim_brand;
DROP TABLE IF EXISTS dw.dim_product_category;
DROP TABLE IF EXISTS dw.dim_pet_type;
DROP TABLE IF EXISTS dw.dim_pet_category;
DROP TABLE IF EXISTS dw.dim_city;
DROP TABLE IF EXISTS dw.dim_country;

CREATE TABLE dw.dim_country (
  country_id    bigserial PRIMARY KEY,
  country_name  text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_city (
  city_id     bigserial PRIMARY KEY,
  city_name   text NOT NULL,
  state_name  text NULL,
  country_id  bigint NOT NULL REFERENCES dw.dim_country(country_id),
  UNIQUE (city_name, state_name, country_id)
);

CREATE TABLE dw.dim_pet_category (
  pet_category_id    bigserial PRIMARY KEY,
  pet_category_name  text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_pet_type (
  pet_type_id    bigserial PRIMARY KEY,
  pet_type_name  text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_product_category (
  product_category_id    bigserial PRIMARY KEY,
  product_category_name  text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_brand (
  brand_id    bigserial PRIMARY KEY,
  brand_name  text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_material (
  material_id    bigserial PRIMARY KEY,
  material_name  text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_date (
  date_id      bigserial PRIMARY KEY,
  date_value   date NOT NULL UNIQUE,
  year         int NOT NULL,
  month        int NOT NULL,
  day          int NOT NULL,
  quarter      int NOT NULL,
  month_name   text NOT NULL,
  day_of_week  text NOT NULL
);

CREATE TABLE dw.dim_customer (
  customer_id           bigserial PRIMARY KEY,
  business_customer_id  int NOT NULL UNIQUE,
  first_name            text,
  last_name             text,
  age                   int,
  email                 text,
  postal_code           text,
  country_id            bigint REFERENCES dw.dim_country(country_id),
  pet_type_id           bigint REFERENCES dw.dim_pet_type(pet_type_id),
  pet_name              text,
  pet_breed             text
);

CREATE TABLE dw.dim_seller (
  seller_id           bigserial PRIMARY KEY,
  business_seller_id  int NOT NULL UNIQUE,
  first_name          text,
  last_name           text,
  email               text,
  postal_code         text,
  country_id          bigint REFERENCES dw.dim_country(country_id)
);

CREATE TABLE dw.dim_store (
  store_id     bigserial PRIMARY KEY,
  store_name   text,
  location     text,
  phone        text,
  email        text,
  city_id      bigint REFERENCES dw.dim_city(city_id),
  UNIQUE (store_name, location, phone, email)
);

CREATE TABLE dw.dim_supplier (
  supplier_id    bigserial PRIMARY KEY,
  supplier_name  text,
  contact_name   text,
  email          text,
  phone          text,
  address        text,
  city_id        bigint REFERENCES dw.dim_city(city_id),
  UNIQUE (supplier_name, email, phone)
);

CREATE TABLE dw.dim_product (
  product_id           bigserial PRIMARY KEY,
  business_product_id  int NOT NULL UNIQUE,
  product_name         text,
  product_category_id  bigint REFERENCES dw.dim_product_category(product_category_id),
  brand_id             bigint REFERENCES dw.dim_brand(brand_id),
  material_id          bigint REFERENCES dw.dim_material(material_id),
  pet_category_id      bigint REFERENCES dw.dim_pet_category(pet_category_id),
  product_weight       numeric,
  product_color        text,
  product_size         text,
  product_description  text,
  product_rating       numeric,
  product_reviews      int,
  release_date_id      bigint REFERENCES dw.dim_date(date_id),
  expiry_date_id       bigint REFERENCES dw.dim_date(date_id)
);

CREATE TABLE dw.fact_sales (
  fact_sale_id     bigserial PRIMARY KEY,
  sale_date_id     bigint NOT NULL REFERENCES dw.dim_date(date_id),
  customer_id      bigint NOT NULL REFERENCES dw.dim_customer(customer_id),
  seller_id        bigint NOT NULL REFERENCES dw.dim_seller(seller_id),
  product_id       bigint NOT NULL REFERENCES dw.dim_product(product_id),
  store_id         bigint NOT NULL REFERENCES dw.dim_store(store_id),
  supplier_id      bigint NOT NULL REFERENCES dw.dim_supplier(supplier_id),
  sale_quantity    int,
  sale_total_price numeric
);

