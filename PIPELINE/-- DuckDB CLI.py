-- DuckDB CLI
-- $ duckdb transfermarkt-datasets.duckdb

SHOW TABLES;

SELECT player_id, name, position, market_value_in_eur
FROM players
WHERE position = 'Attack'
ORDER BY market_value_in_eur DESC
LIMIT 10;

-- player_id | name            | position | market_value_in_eur
-- 418560    | Erling Haaland  | Attack   | 200000000
-- 342229    | Kylian Mbappé   | Attack   | 180000000
-- 371998    | Vinicius Junior | Attack   | 180000000
-- 433177    | Bukayo Saka     | Attack   | 130000000
-- ...