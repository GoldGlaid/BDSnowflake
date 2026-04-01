\echo 'Populating DW dimensions and fact'

-- Helper CTE to trim and normalize NULLs
-- (we keep it inline per-insert to stay in plain SQL)

-- 1) Countries
INSERT INTO dw.dim_country(country_name)
SELECT DISTINCT country_name
FROM (
  SELECT NULLIF(BTRIM(customer_country), '') AS country_name FROM staging.mock_data_raw
  UNION
  SELECT NULLIF(BTRIM(seller_country), '') AS country_name FROM staging.mock_data_raw
  UNION
  SELECT NULLIF(BTRIM(store_country), '') AS country_name FROM staging.mock_data_raw
  UNION
  SELECT NULLIF(BTRIM(supplier_country), '') AS country_name FROM staging.mock_data_raw
) t
WHERE country_name IS NOT NULL
ON CONFLICT DO NOTHING;

-- 2) Cities (stores + suppliers)
INSERT INTO dw.dim_city(city_name, state_name, country_id)
SELECT DISTINCT
  city_name,
  state_name,
  c.country_id
FROM (
  SELECT
    NULLIF(BTRIM(store_city), '') AS city_name,
    NULLIF(BTRIM(store_state), '') AS state_name,
    NULLIF(BTRIM(store_country), '') AS country_name
  FROM staging.mock_data_raw
  UNION
  SELECT
    NULLIF(BTRIM(supplier_city), '') AS city_name,
    NULLIF(BTRIM(NULL), '') AS state_name,
    NULLIF(BTRIM(supplier_country), '') AS country_name
  FROM staging.mock_data_raw
) x
JOIN dw.dim_country c ON c.country_name = x.country_name
WHERE x.city_name IS NOT NULL
ON CONFLICT DO NOTHING;

-- 3) Pet category / type
INSERT INTO dw.dim_pet_category(pet_category_name)
SELECT DISTINCT NULLIF(BTRIM(pet_category), '')
FROM staging.mock_data_raw
WHERE NULLIF(BTRIM(pet_category), '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO dw.dim_pet_type(pet_type_name)
SELECT DISTINCT NULLIF(BTRIM(customer_pet_type), '')
FROM staging.mock_data_raw
WHERE NULLIF(BTRIM(customer_pet_type), '') IS NOT NULL
ON CONFLICT DO NOTHING;

-- 4) Product dictionaries
INSERT INTO dw.dim_product_category(product_category_name)
SELECT DISTINCT NULLIF(BTRIM(product_category), '')
FROM staging.mock_data_raw
WHERE NULLIF(BTRIM(product_category), '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO dw.dim_brand(brand_name)
SELECT DISTINCT NULLIF(BTRIM(product_brand), '')
FROM staging.mock_data_raw
WHERE NULLIF(BTRIM(product_brand), '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO dw.dim_material(material_name)
SELECT DISTINCT NULLIF(BTRIM(product_material), '')
FROM staging.mock_data_raw
WHERE NULLIF(BTRIM(product_material), '') IS NOT NULL
ON CONFLICT DO NOTHING;

-- 5) Date dimension (sale_date, release_date, expiry_date)
INSERT INTO dw.dim_date(date_value, year, month, day, quarter, month_name, day_of_week)
SELECT
  d::date AS date_value,
  EXTRACT(YEAR FROM d::date)::int AS year,
  EXTRACT(MONTH FROM d::date)::int AS month,
  EXTRACT(DAY FROM d::date)::int AS day,
  EXTRACT(QUARTER FROM d::date)::int AS quarter,
  TO_CHAR(d::date, 'Month') AS month_name,
  TO_CHAR(d::date, 'Day') AS day_of_week
FROM (
  SELECT DISTINCT TO_DATE(NULLIF(BTRIM(sale_date), ''), 'MM/DD/YYYY') AS d
  FROM staging.mock_data_raw
  WHERE NULLIF(BTRIM(sale_date), '') IS NOT NULL
  UNION
  SELECT DISTINCT TO_DATE(NULLIF(BTRIM(product_release_date), ''), 'MM/DD/YYYY') AS d
  FROM staging.mock_data_raw
  WHERE NULLIF(BTRIM(product_release_date), '') IS NOT NULL
  UNION
  SELECT DISTINCT TO_DATE(NULLIF(BTRIM(product_expiry_date), ''), 'MM/DD/YYYY') AS d
  FROM staging.mock_data_raw
  WHERE NULLIF(BTRIM(product_expiry_date), '') IS NOT NULL
) u
WHERE d IS NOT NULL
ON CONFLICT DO NOTHING;

-- 6) Customers
INSERT INTO dw.dim_customer(
  business_customer_id, first_name, last_name, age, email, postal_code, country_id, pet_type_id, pet_name, pet_breed
)
SELECT DISTINCT
  NULLIF(BTRIM(r.sale_customer_id), '')::int AS business_customer_id,
  NULLIF(BTRIM(r.customer_first_name), '') AS first_name,
  NULLIF(BTRIM(r.customer_last_name), '') AS last_name,
  NULLIF(BTRIM(r.customer_age), '')::int AS age,
  NULLIF(BTRIM(r.customer_email), '') AS email,
  NULLIF(BTRIM(r.customer_postal_code), '') AS postal_code,
  c.country_id,
  pt.pet_type_id,
  NULLIF(BTRIM(r.customer_pet_name), '') AS pet_name,
  NULLIF(BTRIM(r.customer_pet_breed), '') AS pet_breed
FROM staging.mock_data_raw r
LEFT JOIN dw.dim_country c ON c.country_name = NULLIF(BTRIM(r.customer_country), '')
LEFT JOIN dw.dim_pet_type pt ON pt.pet_type_name = NULLIF(BTRIM(r.customer_pet_type), '')
WHERE NULLIF(BTRIM(r.sale_customer_id), '') IS NOT NULL
ON CONFLICT (business_customer_id) DO NOTHING;

-- 7) Sellers
INSERT INTO dw.dim_seller(
  business_seller_id, first_name, last_name, email, postal_code, country_id
)
SELECT DISTINCT
  NULLIF(BTRIM(r.sale_seller_id), '')::int AS business_seller_id,
  NULLIF(BTRIM(r.seller_first_name), '') AS first_name,
  NULLIF(BTRIM(r.seller_last_name), '') AS last_name,
  NULLIF(BTRIM(r.seller_email), '') AS email,
  NULLIF(BTRIM(r.seller_postal_code), '') AS postal_code,
  c.country_id
FROM staging.mock_data_raw r
LEFT JOIN dw.dim_country c ON c.country_name = NULLIF(BTRIM(r.seller_country), '')
WHERE NULLIF(BTRIM(r.sale_seller_id), '') IS NOT NULL
ON CONFLICT (business_seller_id) DO NOTHING;

-- 8) Stores
INSERT INTO dw.dim_store(store_name, location, phone, email, city_id)
SELECT DISTINCT
  NULLIF(BTRIM(r.store_name), '') AS store_name,
  NULLIF(BTRIM(r.store_location), '') AS location,
  NULLIF(BTRIM(r.store_phone), '') AS phone,
  NULLIF(BTRIM(r.store_email), '') AS email,
  city.city_id
FROM staging.mock_data_raw r
LEFT JOIN dw.dim_country c ON c.country_name = NULLIF(BTRIM(r.store_country), '')
LEFT JOIN dw.dim_city city
  ON city.city_name = NULLIF(BTRIM(r.store_city), '')
 AND city.state_name IS NOT DISTINCT FROM NULLIF(BTRIM(r.store_state), '')
 AND city.country_id = c.country_id
ON CONFLICT DO NOTHING;

-- 9) Suppliers
INSERT INTO dw.dim_supplier(supplier_name, contact_name, email, phone, address, city_id)
SELECT DISTINCT
  NULLIF(BTRIM(r.supplier_name), '') AS supplier_name,
  NULLIF(BTRIM(r.supplier_contact), '') AS contact_name,
  NULLIF(BTRIM(r.supplier_email), '') AS email,
  NULLIF(BTRIM(r.supplier_phone), '') AS phone,
  NULLIF(BTRIM(r.supplier_address), '') AS address,
  city.city_id
FROM staging.mock_data_raw r
LEFT JOIN dw.dim_country c ON c.country_name = NULLIF(BTRIM(r.supplier_country), '')
LEFT JOIN dw.dim_city city
  ON city.city_name = NULLIF(BTRIM(r.supplier_city), '')
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
  NULLIF(BTRIM(r.sale_product_id), '')::int AS business_product_id,
  NULLIF(BTRIM(r.product_name), '') AS product_name,
  pc.product_category_id,
  b.brand_id,
  m.material_id,
  pet.pet_category_id,
  NULLIF(BTRIM(r.product_weight), '')::numeric AS product_weight,
  NULLIF(BTRIM(r.product_color), '') AS product_color,
  NULLIF(BTRIM(r.product_size), '') AS product_size,
  NULLIF(r.product_description, '') AS product_description,
  NULLIF(BTRIM(r.product_rating), '')::numeric AS product_rating,
  NULLIF(BTRIM(r.product_reviews), '')::int AS product_reviews,
  rd.date_id AS release_date_id,
  ed.date_id AS expiry_date_id
FROM staging.mock_data_raw r
LEFT JOIN dw.dim_product_category pc ON pc.product_category_name = NULLIF(BTRIM(r.product_category), '')
LEFT JOIN dw.dim_brand b ON b.brand_name = NULLIF(BTRIM(r.product_brand), '')
LEFT JOIN dw.dim_material m ON m.material_name = NULLIF(BTRIM(r.product_material), '')
LEFT JOIN dw.dim_pet_category pet ON pet.pet_category_name = NULLIF(BTRIM(r.pet_category), '')
LEFT JOIN dw.dim_date rd ON rd.date_value = TO_DATE(NULLIF(BTRIM(r.product_release_date), ''), 'MM/DD/YYYY')
LEFT JOIN dw.dim_date ed ON ed.date_value = TO_DATE(NULLIF(BTRIM(r.product_expiry_date), ''), 'MM/DD/YYYY')
WHERE NULLIF(BTRIM(r.sale_product_id), '') IS NOT NULL
ON CONFLICT (business_product_id) DO NOTHING;

-- 11) Fact sales
INSERT INTO dw.fact_sales(
  sale_date_id, customer_id, seller_id, product_id, store_id, supplier_id, sale_quantity, sale_total_price
)
SELECT
  d.date_id AS sale_date_id,
  c.customer_id,
  s.seller_id,
  p.product_id,
  st.store_id,
  sup.supplier_id,
  NULLIF(BTRIM(r.sale_quantity), '')::int AS sale_quantity,
  NULLIF(BTRIM(r.sale_total_price), '')::numeric AS sale_total_price
FROM staging.mock_data_raw r
JOIN dw.dim_date d
  ON d.date_value = TO_DATE(NULLIF(BTRIM(r.sale_date), ''), 'MM/DD/YYYY')
JOIN dw.dim_customer c
  ON c.business_customer_id = NULLIF(BTRIM(r.sale_customer_id), '')::int
JOIN dw.dim_seller s
  ON s.business_seller_id = NULLIF(BTRIM(r.sale_seller_id), '')::int
JOIN dw.dim_product p
  ON p.business_product_id = NULLIF(BTRIM(r.sale_product_id), '')::int
JOIN dw.dim_store st
  ON st.store_name IS NOT DISTINCT FROM NULLIF(BTRIM(r.store_name), '')
 AND st.location IS NOT DISTINCT FROM NULLIF(BTRIM(r.store_location), '')
 AND st.phone IS NOT DISTINCT FROM NULLIF(BTRIM(r.store_phone), '')
 AND st.email IS NOT DISTINCT FROM NULLIF(BTRIM(r.store_email), '')
JOIN dw.dim_supplier sup
  ON sup.supplier_name IS NOT DISTINCT FROM NULLIF(BTRIM(r.supplier_name), '')
 AND sup.email IS NOT DISTINCT FROM NULLIF(BTRIM(r.supplier_email), '')
 AND sup.phone IS NOT DISTINCT FROM NULLIF(BTRIM(r.supplier_phone), '');

\echo 'Done populating DW'

