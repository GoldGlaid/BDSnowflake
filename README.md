# Лабораторная работа №1 — Схема «Снежинка»

Трансформация исходных CSV-данных в аналитическую модель данных «снежинка» на PostgreSQL.

## Как запустить

```bash
git clone <url репозитория>
cd BDSnowflake
docker compose up -d
```

При первом запуске Docker автоматически:
1. Поднимет PostgreSQL
2. Загрузит 10 CSV-файлов в staging-таблицу (10 000 строк)
3. Создаст схему снежинка и заполнит все таблицы

Подождать пока всё инициализируется.

## Подключение к БД

| Параметр | Значение |
|----------|----------|
| Host | `localhost` |
| Port | `5433` |
| Database | `snowflake_db` |
| User | `snowflake` |
| Password | `snowflake` |

## Схема данных

Схема «снежинка» с центральной таблицей `fact_sales` и 13 таблицами измерений:

- **fact_sales** — продажи (количество, сумма)
- **dim_customer** → dim_country, dim_pet_type
- **dim_seller** → dim_country
- **dim_product** → dim_product_category, dim_brand, dim_material, dim_pet_category, dim_date
- **dim_store** → dim_city → dim_country
- **dim_supplier** → dim_city → dim_country
- **dim_date** — календарная аналитика (год, месяц, квартал и т.д.)
