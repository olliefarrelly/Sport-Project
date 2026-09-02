## ============================================================
## 100pts — Phase 2: Build the final player pool
## Cleans the Kaggle/FBref stats dataset, cleans the Transfermarkt
## price+position dataset, and joins them into one table ready
## for rating_model.py / price_model.py.
## ============================================================
library(tidyverse)
library(dplyr)
library(stringr)
library(stringi)   # for accent stripping (stri_trans_general)
library(tidyr)

# --------------------------------------------------------------
# 0. LOAD
# --------------------------------------------------------------
stats_raw <- read.csv("players_data-2025_2026", stringsAsFactors = FALSE)
tm_raw    <- read.csv("big5_market_values.csv", stringsAsFactors = FALSE)

# --------------------------------------------------------------
# 1. NAME NORMALIZATION HELPER
#    Used on BOTH datasets so the join key matches regardless of
#    accents, case, or stray whitespace.
#    e.g. "João Neves" -> "joao neves"
# --------------------------------------------------------------
normalize_name <- function(x) {
  x %>%
    stri_trans_general("Latin-ASCII") %>%   # strip accents/diacritics
    str_to_lower() %>%
    str_squish()                             # trim + collapse internal whitespace
}

# --------------------------------------------------------------
# 2. CLEAN THE KAGGLE/FBREF STATS DATASET
#    2a. Merge mid-season transfer rows (same player, multiple clubs)
#    2b. Recompute rate stats from SUMMED raw components (not averaged!)
# --------------------------------------------------------------

stats <- stats_raw %>%
  mutate(
    name_key = normalize_name(Player),
    birth_year = Born  # already just a year in this dataset
  )

# Raw counting stats that are safe to SUM across a player's rows.
# Add/remove columns here to match your actual file's exact names.
raw_sum_cols <- c(
  "MP", "Starts", "Min", "X90s",   # R auto-renames "90s" column to "X90s" on read.csv — verify this!
  "Gls", "Ast", "Sh", "SoT",
  "TklW", "Int", "Crs", "Fld", "Fls", "Off", "CrdY", "CrdR",
  "CS", "SoTA", "Saves", "PKA", "PKsv"
)
# Keep only the ones that actually exist in the loaded file (avoids errors
# if a column name differs slightly from what we expect).
raw_sum_cols <- intersect(raw_sum_cols, names(stats))

stats_grouped <- stats %>%
  group_by(name_key, birth_year) %>%
  mutate(n_rows = n()) %>%
  ungroup()

# Rows for players who appear once — no merge needed
stats_single <- stats_grouped %>% filter(n_rows == 1)

# Rows for players who transferred mid-season — need merging
stats_multi <- stats_grouped %>% filter(n_rows > 1)

if (nrow(stats_multi) > 0) {
  # Identity/context fields taken from whichever row has the most minutes
  # (most representative of their season) — Squad, Comp, Pos, Nation, Age.
  primary_rows <- stats_multi %>%
    group_by(name_key, birth_year) %>%
    slice_max(order_by = Min, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(name_key, birth_year, Player, Nation, Pos, Squad, Comp, Age)
  
  # Sum the raw counting stats across all of that player's rows
  summed_stats <- stats_multi %>%
    group_by(name_key, birth_year) %>%
    summarise(across(all_of(raw_sum_cols), \(x) sum(x, na.rm = TRUE)), .groups = "drop")
  
  merged_multi <- primary_rows %>%
    left_join(summed_stats, by = c("name_key", "birth_year"))
  
  # Recompute rate stats from the SUMMED raw numbers — never average percentages directly.
  # Only recompute the ones whose raw components we actually kept.
  merged_multi <- merged_multi %>%
    mutate(
      `SoT%`    = if (all(c("SoT", "Sh") %in% names(.)))    round(SoT / Sh * 100, 1)    else NA,
      `G/Sh`    = if (all(c("Gls", "Sh") %in% names(.)))    round(Gls / Sh, 3)          else NA,
      `G/SoT`   = if (all(c("Gls", "SoT") %in% names(.)))   round(Gls / SoT, 3)         else NA,
      `Save%`   = if (all(c("Saves", "SoTA") %in% names(.))) round(Saves / SoTA * 100, 1) else NA,
      `CS%`     = if (all(c("CS", "MP") %in% names(.)))      round(CS / MP * 100, 1)      else NA,
      `PK_Save%`= if (all(c("PKsv", "PKA") %in% names(.)))   round(PKsv / PKA * 100, 1)   else NA
    )
} else {
  merged_multi <- stats_multi[0, ]  # empty, keeps rbind below safe
}

stats_clean <- bind_rows(
  stats_single %>% select(-n_rows),
  merged_multi
)

cat("Players before merge:", nrow(stats), "\n")
cat("Players after merging mid-season transfers:", nrow(stats_clean), "\n")

# --------------------------------------------------------------
# 3. CLEAN THE TRANSFERMARKT PRICE + POSITION DATASET
#    3a. Drop rows with missing sub_position (19 rows, per earlier check)
#    3b. Map Transfermarkt sub_position -> our 7 model positions
#    3c. Extract birth year from full date_of_birth for the join key
# --------------------------------------------------------------

position_map <- c(
  "Goalkeeper"          = "GK",
  "Centre-Back"         = "CB",
  "Right-Back"          = "FB",
  "Left-Back"           = "FB",
  "Defensive Midfield"  = "CM",
  "Central Midfield"    = "CM",
  "Right Midfield"      = "W",   # judgment call — see note in chat, adjust if you disagree
  "Left Midfield"       = "W",
  "Attacking Midfield"  = "CAM",
  "Right Winger"        = "W",
  "Left Winger"         = "W",
  "Second Striker"      = "CAM",
  "Centre-Forward"      = "ST"
)

tm_clean <- tm_raw %>%
  filter(!is.na(sub_position)) %>%
  mutate(
    name_key = normalize_name(name),
    birth_year = as.integer(format(as.Date(date_of_birth), "%Y")),
    model_position = position_map[sub_position]
  )

# Sanity check: flag any sub_position value that didn't map (should be none,
# but worth checking in case Transfermarkt data has a label we haven't seen).
unmapped <- tm_clean %>% filter(is.na(model_position)) %>% distinct(sub_position)
if (nrow(unmapped) > 0) {
  cat("WARNING — unmapped sub_position values found:\n")
  print(unmapped)
}

cat("Transfermarkt players after cleaning:", nrow(tm_clean), "\n")

# --------------------------------------------------------------
# 4. JOIN
#    Match on normalized name + birth year.
# --------------------------------------------------------------

player_pool <- stats_clean %>%
  inner_join(
    tm_clean %>% select(name_key, birth_year, club, league, model_position,
                        nationality, market_value_in_eur),
    by = c("name_key", "birth_year")
  )

cat("\n--- MATCH RATE ---\n")
cat("Stats dataset players:", nrow(stats_clean), "\n")
cat("Successfully matched to Transfermarkt:", nrow(player_pool), "\n")
cat("Match rate:", round(nrow(player_pool) / nrow(stats_clean) * 100, 1), "%\n")

# --------------------------------------------------------------
# 5. INSPECT UNMATCHED ROWS (for manual review)
#    These are players in the stats dataset with no Transfermarkt match —
#    likely name formatting differences. Check a sample before deciding
#    whether to hand-fix or just drop them from the draftable pool.
# --------------------------------------------------------------

unmatched <- stats_clean %>%
  anti_join(tm_clean, by = c("name_key", "birth_year"))

cat("\nUnmatched players (sample of 20):\n")
print(head(unmatched %>% select(Player, Squad, Comp, birth_year), 20))

# Save unmatched list to a CSV so you can review/fix names by hand if needed
write.csv(unmatched %>% select(Player, Squad, Comp, birth_year),
          "unmatched_players_review.csv", row.names = FALSE)

# --------------------------------------------------------------
# 6. FINAL OUTPUT
#    Rename columns to match your schema, drop helper columns.
# --------------------------------------------------------------

player_pool_final <- player_pool %>%
  transmute(
    name = Player,
    nation = nationality,
    position = model_position,     # granular position from Transfermarkt — use this, not Pos
    squad = club,
    league = league,
    age = Age,
    born = birth_year,
    market_value_eur = market_value_in_eur,
    # attacking
    goals = Gls, assists = Ast, shots = Sh, shots_on_target = SoT,
    `sot_pct` = `SoT%`, `g_per_sh` = `G/Sh`, `g_per_sot` = `G/SoT`,
    # defensive
    tackles_won = TklW, interceptions = Int,
    # creative/misc
    crosses = Crs, fouls_drawn = Fld,
    # goalkeeping
    `save_pct` = `Save%`, `cs_pct` = `CS%`, `pk_save_pct` = `PK_Save%`,
    # playing time
    minutes = Min, nineties = X90s
  )

write.csv(player_pool_final, "players_pool_clean.csv", row.names = FALSE)
cat("\nFinal player pool saved:", nrow(player_pool_final), "players -> players_pool_clean.csv\n")