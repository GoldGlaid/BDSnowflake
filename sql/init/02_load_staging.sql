\echo 'Loading CSV files into staging.mock_data_raw'

TRUNCATE TABLE staging.mock_data_raw;

\copy staging.mock_data_raw FROM '/data/MOCK_DATA.csv' WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');
\copy staging.mock_data_raw FROM '/data/MOCK_DATA (1).csv' WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');
\copy staging.mock_data_raw FROM '/data/MOCK_DATA (2).csv' WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');
\copy staging.mock_data_raw FROM '/data/MOCK_DATA (3).csv' WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');
\copy staging.mock_data_raw FROM '/data/MOCK_DATA (4).csv' WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');
\copy staging.mock_data_raw FROM '/data/MOCK_DATA (5).csv' WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');
\copy staging.mock_data_raw FROM '/data/MOCK_DATA (6).csv' WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');
\copy staging.mock_data_raw FROM '/data/MOCK_DATA (7).csv' WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');
\copy staging.mock_data_raw FROM '/data/MOCK_DATA (8).csv' WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');
\copy staging.mock_data_raw FROM '/data/MOCK_DATA (9).csv' WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

\echo 'Done loading CSV'

