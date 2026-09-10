library(dplyr)
library(stringr)
library(stringi)
library(lubridate)
library(tibble)

downloads_path <- "C:/Users/olive/OneDrive/Documents/Downloads"

players_data <- read.csv("https://raw.githubusercontent.com/olliefarrelly/Sport-Project/main/DATA/raw/players_data-2025_2026.csv",
                         stringsAsFactors = FALSE)

big5 <- read.csv(file.path(downloads_path, "big5_market_values.csv"),
                 stringsAsFactors = FALSE)

dim(players_data)
dim(big5)




## expanded season totals

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
    PK = sum(PK, na.rm = TRUE),
    PKatt = sum(PKatt, na.rm = TRUE),
    Int = sum(Int, na.rm = TRUE),
    TklW = sum(TklW, na.rm = TRUE),
    Fls = sum(Fls, na.rm = TRUE),
    Fld = sum(Fld, na.rm = TRUE),
    Crs = sum(Crs, na.rm = TRUE),
    Off = sum(Off, na.rm = TRUE),
    OG = sum(OG, na.rm = TRUE),
    GA = sum(GA, na.rm = TRUE),
    Saves = sum(Saves, na.rm = TRUE),
    SoTA = sum(SoTA, na.rm = TRUE),
    CS = sum(CS, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    G_PK = Gls - PK,                     # non-penalty goals
    Save_pct = if_else(SoTA > 0, round(Saves / SoTA * 100, 1), NA_real_)  # recomputed properly
  )

dim(season_totals)
head(season_totals, 3)

season_totals |> filter(Player == "Aaron Ramsdale") |> select(Saves, SoTA, Save_pct) # check to see if seems valid




current_club <- players_data |>
  group_by(Player, Born) |>
  slice_max(Min, n = 1, with_ties = FALSE) |>
  ungroup()

players_final <- current_club |>
  select(Player, Born, Nation, Pos, Squad, Comp, Age) |>
  left_join(season_totals, by = c("Player", "Born"))

dim(players_final)
head(players_final, 3)





players_final <- players_final |>
  mutate(Player_clean = stri_trans_general(Player, "Latin-ASCII")) |>
  left_join(name_fixes, by = c("Player" = "fbref_name")) |>
  mutate(match_name = coalesce(tm_name, Player_clean))

big5_clean <- big5 |>
  mutate(
    birth_year = year(as.Date(date_of_birth)),
    name_clean = stri_trans_general(name, "Latin-ASCII")
  )

dim(players_final)





matched_final <- players_final |>
  inner_join(big5_clean, by = c("match_name" = "name_clean", "Born" = "birth_year"))

nrow(matched_final)


matched_final |> count(Player, Born) |> filter(n > 1)


matched_final <- matched_final |>
  filter(!(Player == "Vitinha" & Born == 2000 & club == "Paris Saint-Germain"))

nrow(matched_final)






matched_final <- matched_final |>
  mutate(
    nineties = Min / 90,
    Gls_90 = if_else(nineties > 0, round(Gls / nineties, 2), NA_real_),
    Ast_90 = if_else(nineties > 0, round(Ast / nineties, 2), NA_real_),
    Sh_90 = if_else(nineties > 0, round(Sh / nineties, 2), NA_real_),
    SoT_90 = if_else(nineties > 0, round(SoT / nineties, 2), NA_real_),
    Int_90 = if_else(nineties > 0, round(Int / nineties, 2), NA_real_),
    TklW_90 = if_else(nineties > 0, round(TklW / nineties, 2), NA_real_),
    Crs_90 = if_else(nineties > 0, round(Crs / nineties, 2), NA_real_),
    GA_90 = if_else(nineties > 0, round(GA / nineties, 2), NA_real_)
  )

dim(matched_final)
head(matched_final |> select(Player, Min, Gls, Gls_90, Ast, Ast_90), 5)



matched_final <- matched_final |>
  mutate(low_sample = Min < 450)

table(matched_final$low_sample)



write.csv(matched_final, file.path(downloads_path, "player_ratings_master.csv"), row.names = FALSE)

matched_final |> count(sub_position, sort = TRUE)
