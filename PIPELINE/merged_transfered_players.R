library(dplyr)

# Step 1: figure out "current" club = the stint with the most minutes played
# (mid-season transfers usually mean the most recent club has fewer/more minutes,
# but "most minutes" is often a safer proxy for "primary club" than "last row")


players_data <- read.csv("https://raw.githubusercontent.com/olliefarrelly/Sport-Project/main/DATA/raw/players_data-2025_2026.csv",
                         stringsAsFactors = FALSE)
dim(players_data)
head(players_data, 3)


n_distinct(players_data$Player)
nrow(distinct(players_data, Player, Born))



players_data |>
  count(Player, Born) |>
  filter(n > 1) |>
  nrow()




# Step 1: "current" club = stint with most minutes played
current_club <- players_data |>
  group_by(Player, Born) |>
  slice_max(Min, n = 1, with_ties = FALSE) |>
  ungroup()

# Step 2: season totals across all clubs
season_totals <- players_data |>
  group_by(Player, Born) |>
  summarise(
    MP = sum(MP, na.rm = TRUE),
    Min = sum(Min, na.rm = TRUE),
    Gls = sum(Gls, na.rm = TRUE),
    Ast = sum(Ast, na.rm = TRUE),
    Sh  = sum(Sh, na.rm = TRUE),
    SoT = sum(SoT, na.rm = TRUE),
    CrdY = sum(CrdY, na.rm = TRUE),
    CrdR = sum(CrdR, na.rm = TRUE),
    .groups = "drop"
  )

# Step 3: attach "current club" label to season totals
players_final <- current_club |>
  select(Player, Born, Nation, Pos, Squad, Comp, Age) |>
  left_join(season_totals, by = c("Player", "Born"))




dim(players_final)
head(players_final, 5)

# spot check Himad Abdelli specifically — his totals should now be:
# MP = 21, Min = 1081, Gls = 2, Ast = 0 (summed across both clubs)
players_final |> filter(Player == "Himad Abdelli")