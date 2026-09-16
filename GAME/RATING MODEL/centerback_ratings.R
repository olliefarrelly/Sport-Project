# ============================================================
# CENTRE-BACK RATING MODEL
# ============================================================
# Stats used: interceptions per 90, tackles won per 90, fouls per 90
# (inverted - fewer fouls is better), market value.
# Same shrinkage -> percentile -> weighted composite -> cap structure
# as the other position models.
# ============================================================
library(tidyverse)
k <- 10

cb_pool <- matched_final |>
  filter(sub_position == "Centre-Back") |>
  mutate(Fls_90 = if_else(nineties > 0, round(Fls / nineties, 2), NA_real_))

league_avg_int90 <- mean(cb_pool$Int_90, na.rm = TRUE)
league_avg_tklw90 <- mean(cb_pool$TklW_90, na.rm = TRUE)
league_avg_fls90 <- mean(cb_pool$Fls_90, na.rm = TRUE)

cb_ratings <- cb_pool |>
  mutate(
    shrink_weight = nineties / (nineties + k),
    Int_90_shrunk  = shrink_weight * Int_90  + (1 - shrink_weight) * league_avg_int90,
    TklW_90_shrunk = shrink_weight * TklW_90 + (1 - shrink_weight) * league_avg_tklw90,
    Fls_90_shrunk  = shrink_weight * Fls_90  + (1 - shrink_weight) * league_avg_fls90
  ) |>
  mutate(
    int90_percentile  = percent_rank(Int_90_shrunk) * 100,
    tklw90_percentile = percent_rank(TklW_90_shrunk) * 100,
    fls90_percentile  = percent_rank(-Fls_90_shrunk) * 100,   # inverted: fewer fouls = higher percentile
    mv_percentile     = percent_rank(market_value_in_eur) * 100
  ) |>
  mutate(
    cb_rating = round(
      0.40 * int90_percentile +
        0.35 * tklw90_percentile +
        0.10 * fls90_percentile +
        0.15 * mv_percentile,
      1
    )
  ) |>
  mutate(
    cb_rating = if_else(Min < 450, pmin(cb_rating, 65), cb_rating)
  ) |>
  arrange(desc(cb_rating))

dim(cb_ratings)
cb_ratings |> select(Player, Squad, Min, Int_90, TklW_90, Fls_90, market_value_in_eur, cb_rating, low_sample) |> head(15)




matched_final |> filter(str_detect(Player, "Saliba|Dijk|Marquinhos")) |> 
  select(Player, Squad, sub_position, Min, Int_90, TklW_90, market_value_in_eur)


# ============================================================
# FINAL RESCALING STEP (cross-position comparability)
# ============================================================
# See wing-mid script for full rationale. cb_rating here is only
# comparable to other Centre-Backs — needs rescaling before
# feeding into team attack/defence aggregation alongside other
# positions.

cb_ratings <- rescale_position_rating(cb_ratings, "cb_rating")

cb_ratings |> select(Player, Squad, Min, cb_rating, final_rating, low_sample) |> head(15)