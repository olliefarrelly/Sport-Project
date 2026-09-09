library(stringr)
library(dplyr)

sum(players_final$Player %in% big5$name)
nrow(players_final)


matched <- players_final |>
  inner_join(big5, by = c("Player" = "name"))

dim(matched)


matched |> count(Player) |> filter(n > 1) |> arrange(desc(n))


big5 |> filter(name == "David López") #looking into double entries (two David Lopez)



library(dplyr)
library(lubridate)

big5_clean <- big5 |>
  mutate(birth_year = year(as.Date(date_of_birth)))

matched <- players_final |>
  inner_join(big5_clean, by = c("Player" = "name", "Born" = "birth_year"))

dim(matched)



matched |> count(Player, Born) |> filter(n > 1)

    # cleaning player with same name and birth year
matched |> filter(Player == "Vitinha", Born == 2000) |> select(Player, Squad, Comp, club, league, market_value_in_eur)


matched <- matched |>
  filter(!(Player == "Vitinha" & Born == 2000 & club == "Paris Saint-Germain"))



matched |> count(Player, Born) |> filter(n > 1)
nrow(matched)



unmatched <- players_final |>
  anti_join(big5_clean, by = c("Player" = "name", "Born" = "birth_year"))

nrow(unmatched)

unmatched |> 
  arrange(desc(Min)) |> 
  head(20) |> 
  select(Player, Squad, Min, Gls, Ast)




library(stringi)

players_final <- players_final |>
  mutate(Player_clean = stri_trans_general(Player, "Latin-ASCII"))

big5_clean <- big5_clean |>
  mutate(name_clean = stri_trans_general(name, "Latin-ASCII"))

matched_v2 <- players_final |>
  inner_join(big5_clean, by = c("Player_clean" = "name_clean", "Born" = "birth_year"))

nrow(matched_v2)



matched_v2 |> count(Player_clean, Born) |> filter(n > 1)

matched_v2 <- matched_v2 |>
  filter(!(Player_clean == "Vitinha" & Born == 2000 & club == "Paris Saint-Germain"))


unmatched_v2 <- players_final |>
  anti_join(big5_clean, by = c("Player_clean" = "name_clean", "Born" = "birth_year"))

nrow(unmatched_v2)

unmatched_v2 |> 
  arrange(desc(Min)) |> 
  head(20) |> 
  select(Player, Squad, Min, Gls, Ast)



big5_clean |> filter(str_detect(name, "Petrovic|Petrović"))
big5_clean |> filter(str_detect(name, "Paz"))
big5_clean |> filter(str_detect(name, "Hojbjerg|Højbjerg"))


remaining_names <- c("Michel Ndary Adopo", "Jonny Castro", "Senne Lammens", 
                     "Mikael Ellertsson", "Gabriel Magalhães", "Adrián de la Fuente",
                     "Obite N'Dicka", "Joel Fujita", "Yehor Yarmoliuk", 
                     "Urko González", "Viktor Tsyhankov", "Leo Skiri Østigård",
                     "Cucho", "Djené", "Carmona")

for (n in remaining_names) {
  last_word <- word(n, -1)  # grabs the last word as a rough surname guess
  cat("---", n, "---\n")
  print(big5_clean |> filter(str_detect(name, fixed(last_word, ignore_case = TRUE))) |> 
          select(name, club, birth_year))
}



name_fixes <- tibble::tribble(
  ~fbref_name, ~tm_name,
  "Michel Ndary Adopo", "Michel Adopo",
  "Mikael Ellertsson", "Mikael Egill Ellertsson",
  "Joel Fujita", "Joel Chima Fujita",
  "Urko González", "Urko González de Zárate",
  "Leo Skiri Østigård", "Leo Østigård",
  "Cucho", "Cucho Hernández",
  "Djené", "Dakonam Djené",
  "Carmona", "José Ángel Carmona"
)



big5_clean |> filter(str_detect(name, "Gabriel")) |> filter(club == "Arsenal FC")
big5_clean |> filter(str_detect(name, "Ndicka|N'Dicka"))
big5_clean |> filter(str_detect(name, "Tsygankov|Tsyhankov|Tsygancov"))
big5_clean |> filter(str_detect(name, "Yarmoliuk|Yarmolyuk"))
big5_clean |> filter(str_detect(name, "Jonathan Castro|Jony Castro|Jonny Castro"))
big5_clean |> filter(str_detect(name, "Adrián") & club == "Levante UD")



big5_clean |> filter(str_detect(name, "Castro") & club == "Deportivo Alavés")


name_fixes <- tibble::tribble(
  ~fbref_name, ~tm_name,
  "Michel Ndary Adopo", "Michel Adopo",
  "Mikael Ellertsson", "Mikael Egill Ellertsson",
  "Joel Fujita", "Joel Chima Fujita",
  "Urko González", "Urko González de Zárate",
  "Leo Skiri Østigård", "Leo Østigård",
  "Cucho", "Cucho Hernández",
  "Djené", "Dakonam Djené",
  "Carmona", "José Ángel Carmona",
  "Gabriel Magalhães", "Gabriel",
  "Obite N'Dicka", "Evan Ndicka",
  "Viktor Tsyhankov", "Viktor Tsygankov",
  "Yehor Yarmoliuk", "Yegor Yarmolyuk",
  "Adrián de la Fuente", "Adrián Dela",
  "Đorđe Petrović", "Djordje Petrovic",
  "Nicolás Paz", "Nico Paz",
  "Pierre Højbjerg", "Pierre-Emile Højbjerg"
)


players_final <- players_final |>
  left_join(name_fixes, by = c("Player" = "fbref_name")) |>
  mutate(match_name = coalesce(tm_name, Player_clean))  # use fixed name if we have one, else the accent-stripped name


matched_final <- players_final |>
  inner_join(big5_clean, by = c("match_name" = "name_clean", "Born" = "birth_year"))

nrow(matched_final)


matched_final |> count(Player, Born) |> filter(n > 1)

nrow(matched_final)
nrow(players_final)
nrow(matched_final) / nrow(players_final)



matched_final <- matched_final |>
  filter(!(Player == "Vitinha" & Born == 2000 & club == "Paris Saint-Germain"))


matched_final |> count(Player, Born) |> filter(n > 1)
nrow(matched_final)




write.csv(matched_final, file.path(downloads_path, "matched_players_final.csv"), row.names = FALSE)
transfer_final <- matched_final
