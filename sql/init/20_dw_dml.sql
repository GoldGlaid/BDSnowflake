-- 1) Countries
INSERT INTO dw.dim_country(country_name)
SELECT DISTINCT country_name
FROM (
  SELECT TRIM(customer_country) AS country_name FROM staging.mock_data_raw
  UNION
  SELECT TRIM(seller_country)   AS country_name FROM staging.mock_data_raw
  UNION
  SELECT TRIM(store_country)    AS country_name FROM staging.mock_data_raw
  UNION
  SELECT TRIM(supplier_country) AS country_name FROM staging.mock_data_raw
) t
WHERE country_name IS NOT NULL AND country_name <> ''
ON CONFLICT DO NOTHING;

-- 2) Cities (stores + suppliers)
INSERT INTO dw.dim_city(city_name, state_name, country_id)
SELECT DISTINCT
  city_name,
  state_name,
  c.country_id
FROM (
  SELECT
    TRIM(store_city)    AS city_name,
    TRIM(store_state)   AS state_name,
    TRIM(store_country) AS country_name
  FROM staging.mock_data_raw
  UNION
  SELECT
    TRIM(supplier_city)    AS city_name,
    NULL                   AS state_name,
    TRIM(supplier_country) AS country_name
  FROM staging.mock_data_raw
) x
JOIN dw.dim_country c ON c.country_name = x.country_name
WHERE x.city_name IS NOT NULL AND x.city_name <> ''
ON CONFLICT DO NOTHING;

-- 3) Pet category / type
INSERT INTO dw.dim_pet_category(pet_category_name)
SELECT DISTINCT TRIM(pet_category)
FROM staging.mock_data_raw
WHERE pet_category IS NOT NULL AND TRIM(pet_category) <> ''
ON CONFLICT DO NOTHING;

INSERT INTO dw.dim_pet_type(pet_type_name)
SELECT DISTINCT TRIM(customer_pet_type)
FROM staging.mock_data_raw
WHERE customer_pet_type IS NOT NULL AND TRIM(customer_pet_type) <> ''
ON CONFLICT DO NOTHING;

-- 4) Product dictionaries
INSERT INTO dw.dim_product_category(product_category_name)
SELECT DISTINCT TRIM(product_category)
FROM staging.mock_data_raw
WHERE product_category IS NOT NULL AND TRIM(product_category) <> ''
ON CONFLICT DO NOTHING;

INSERT INTO dw.dim_brand(brand_name)
SELECT DISTINCT TRIM(product_brand)
FROM staging.mock_data_raw
WHERE product_brand IS NOT NULL AND TRIM(product_brand) <> ''
ON CONFLICT DO NOTHING;

INSERT INTO dw.dim_material(material_name)
SELECT DISTINCT TRIM(product_material)
FROM staging.mock_data_raw
WHERE product_material IS NOT NULL AND TRIM(product_material) <> ''
ON CONFLICT DO NOTHING;

-- 5) Date dimension (sale_date, release_date, expiry_date)
INSERT INTO dw.dim_date(date_value, year, month, day, quarter, month_name, day_of_week)
SELECT
  d AS date_value,
  EXTRACT(YEAR FROM d)::int    AS year,
  EXTRACT(MONTH FROM d)::int   AS month,
  EXTRACT(DAY FROM d)::int     AS day,
  EXTRACT(QUARTER FROM d)::int AS quarter,
  TO_CHAR(d, 'Month')          AS month_name,
  TO_CHAR(d, 'Day')            AS day_of_week
FROM (
  SELECT DISTINCT TO_DATE(sale_date, 'MM/DD/YYYY') AS d
  FROM staging.mock_data_raw WHERE sale_date IS NOT NULL AND TRIM(sale_date) <> ''
  UNION
  SELECT DISTINCT TO_DATE(product_release_date, 'MM/DD/YYYY')
  FROM staging.mock_data_raw WHERE product_release_date IS NOT NULL AND TRIM(product_release_date) <> ''
  UNION
  SELECT DISTINCT TO_DATE(product_expiry_date, 'MM/DD/YYYY')
  FROM staging.mock_data_raw WHERE product_expiry_date IS NOT NULL AND TRIM(product_expiry_date) <> ''
) u
WHERE d IS NOT NULL
ON CONFLICT DO NOTHING;

-- 6) Customers
INSERT INTO dw.dim_customer(
  business_customer_id, first_name, last_name, age, email, postal_code, country_id, pet_type_id, pet_name, pet_breed
)
SELECT DISTINCT
  r.sale_customer_id::int AS business_customer_id,
  TRIM(r.customer_first_name) AS first_name,
  TRIM(r.customer_last_name)  AS last_name,
  r.customer_age::int         AS age,
  TRIM(r.customer_email)      AS email,
  r.customer_postal_code      AS postal_code,
  c.country_id,
  pt.pet_type_id,
  TRIM(r.customer_pet_name)  AS pet_name,
  TRIM(r.customer_pet_breed) AS pet_breed
FROM staging.mock_data_raw r
LEFT JOIN dw.dim_country  c  ON c.country_name  = TRIM(r.customer_country)
LEFT JOIN dw.dim_pet_type pt ON pt.pet_type_name = TRIM(r.customer_pet_type)
WHERE r.sale_customer_id IS NOT NULL AND TRIM(r.sale_customer_id) <> ''
ON CONFLICT (business_customer_id) DO NOTHING;

-- 7) Sellers
INSERT INTO dw.dim_seller(
  business_seller_id, first_name, last_name, email, postal_code, country_id
)
SELECT DISTINCT
  r.sale_seller_id::int      AS business_seller_id,
  TRIM(r.seller_first_name)  AS first_name,
  TRIM(r.seller_last_name)   AS last_name,
  TRIM(r.seller_email)       AS email,
  r.seller_postal_code       AS postal_code,
  c.country_id
FROM staging.mock_data_raw r
LEFT JOIN dw.dim_country c ON c.country_name = TRIM(r.seller_country)
WHERE r.sale_seller_id IS NOT NULL AND TRIM(r.sale_seller_id) <> ''
ON CONFLICT (business_seller_id) DO NOTHING;

-- 8) Stores
INSERT INTO dw.dim_store(store_name, location, phone, email, city_id)
SELECT DISTINCT
  TRIM(r.store_name)     AS store_name,
  TRIM(r.store_location) AS location,
  TRIM(r.store_phone)    AS phone,
  TRIM(r.store_email)    AS email,
  city.city_id
FROM staging.mock_data_raw r
LEFT JOIN dw.dim_country c ON c.country_name = TRIM(r.store_country)
LEFT JOIN dw.dim_city city
  ON city.city_name  = TRIM(r.store_city)
 AND city.state_name = TRIM(r.store_state)
 AND city.country_id = c.country_id
ON CONFLICT DO NOTHING;

-- 9) Suppliers
INSERT INTO dw.dim_supplier(supplier_name, contact_name, email, phone, address, city_id)
SELECT DISTINCT
  TRIM(r.supplier_name)    AS supplier_name,
  TRIM(r.supplier_contact) AS contact_name,
  TRIM(r.supplier_email)   AS email,
  TRIM(r.supplier_phone)   AS phone,
  TRIM(r.supplier_address) AS address,
  city.city_id
FROM staging.mock_data_raw r
LEFT JOIN dw.dim_country c ON c.country_name = TRIM(r.supplier_country)
LEFT JOIN dw.dim_city city
  ON city.city_name  = TRIM(r.supplier_city)
 AND city.country_id = c.country_id
ON CONFLICT DO NOTHING;

-- 10) Products
INSERT INTO dw.dim_product(
  business_product_id,
  product_name,
  product_category_id,
  brand_id,
  material_id,
  pet_category_id,
  product_weight,
  product_color,
  product_size,
  product_description,
  product_rating,
  product_reviews,
  release_date_id,
  expiry_date_id
)
SELECT DISTINCT
  r.sale_product_id::int       AS business_product_id,
  TRIM(r.product_name)         AS product_name,
  pc.product_category_id,
  b.brand_id,
  m.material_id,
  pet.pet_category_id,
  r.product_weight::numeric    AS product_weight,
  TRIM(r.product_color)        AS product_color,
  TRIM(r.product_size)         AS product_size,
  r.product_description        AS product_description,
  r.product_rating::numeric    AS product_rating,
  r.product_reviews::int       AS product_reviews,
  rd.date_id                   AS release_date_id,
  ed.date_id                   AS expiry_date_id
FROM staging.mock_data_raw r
LEFT JOIN dw.dim_product_category pc ON pc.product_category_name = TRIM(r.product_category)
LEFT JOIN dw.dim_brand b             ON b.brand_name             = TRIM(r.product_brand)
LEFT JOIN dw.dim_material m          ON m.material_name          = TRIM(r.product_material)
LEFT JOIN dw.dim_pet_category pet    ON pet.pet_category_name    = TRIM(r.pet_category)
LEFT JOIN dw.dim_date rd ON rd.date_value = TO_DATE(r.product_release_date, 'MM/DD/YYYY')
LEFT JOIN dw.dim_date ed ON ed.date_value = TO_DATE(r.product_expiry_date,  'MM/DD/YYYY')
WHERE r.sale_product_id IS NOT NULL AND TRIM(r.sale_product_id) <> ''
ON CONFLICT (business_product_id) DO NOTHING;

-- 11) Fact sales
INSERT INTO dw.fact_sales(
  sale_date_id, customer_id, seller_id, product_id, store_id, supplier_id, sale_quantity, sale_total_price
)
SELECT
  d.date_id        AS sale_date_id,
  c.customer_id,
  s.seller_id,
  p.product_id,
  st.store_id,
  sup.supplier_id,
  r.sale_quantity::int        AS sale_quantity,
  r.sale_total_price::numeric AS sale_total_price
FROM staging.mock_data_raw r
JOIN dw.dim_date d
  ON d.date_value = TO_DATE(r.sale_date, 'MM/DD/YYYY')
JOIN dw.dim_customer c
  ON c.business_customer_id = r.sale_customer_id::int
JOIN dw.dim_seller s
  ON s.business_seller_id = r.sale_seller_id::int
JOIN dw.dim_product p
  ON p.business_product_id = r.sale_product_id::int
JOIN dw.dim_store st
  ON st.store_name = TRIM(r.store_name)
 AND st.location   = TRIM(r.store_location)
 AND st.phone      = TRIM(r.store_phone)
 AND st.email      = TRIM(r.store_email)
JOIN dw.dim_supplier sup
  ON sup.supplier_name = TRIM(r.supplier_name)
 AND sup.email         = TRIM(r.supplier_email)
 AND sup.phone         = TRIM(r.supplier_phone);


