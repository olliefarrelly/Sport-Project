library(DBI)
library(duckdb)



con <- dbConnect(
  duckdb(),
  file.choose()
)


dbListTables(con)



dbListFields(con, "players")
dbListFields(con, "competitions")



query <- "
SELECT
    p.name,
    p.current_club_name AS club,
    c.name AS league,
    p.position,
    p.sub_position,
    p.date_of_birth,
    p.country_of_citizenship AS nationality,
    p.market_value_in_eur
FROM players p
JOIN competitions c
    ON p.current_club_domestic_competition_id = c.competition_id
WHERE c.competition_id IN ('GB1','ES1','L1','IT1','FR1')
  AND p.market_value_in_eur IS NOT NULL
ORDER BY p.market_value_in_eur DESC
"

big5 <- dbGetQuery(con, query)
head(big5, 20)






dbGetQuery(con, "
SELECT position, sub_position, COUNT(*) AS n
FROM players
GROUP BY position, sub_position
ORDER BY position, n DESC
")


unique(big5$sub_position)
sum(is.na(big5$sub_position))
unique(big5$league)



downloads_path <- file.path(path.expand("~"), "Downloads")
downloads_path

write.csv(big5, file.path(downloads_path, "big5_market_values.csv"), row.names = FALSE)


file.exists(file.path(downloads_path, "big5_market_values.csv"))
file.path(downloads_path, "big5_market_values.csv")
