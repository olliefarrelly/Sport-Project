# ============================================================
# FORWARD RATING MODEL
# ============================================================
# Applies to: Centre-Forward, Second Striker, Left Winger, Right Winger
# Stats used: non-penalty goals per 90, shots on target per 90,
# assists per 90, total shots per 90.
# Same shrinkage -> percentile -> weighted composite -> cap structure
# as the goalkeeper model, adjusted for attacking output.
# added market value as a parameter in order to filter down average players on bad teams
# ============================================================

forward_positions <- c("Centre-Forward", "Second Striker", "Left Winger", "Right Winger")

k <- 10  # same confidence threshold as goalkeepers (~10 full games)

# league averages calculated ONLY among forwards, for fair shrinkage baseline
fwd_pool <- matched_final |>
  filter(sub_position %in% forward_positions) |>
  mutate(G_PK_90 = if_else(nineties > 0, round(G_PK / nineties, 2), NA_real_))

league_avg_gpk90 <- mean(fwd_pool$G_PK_90, na.rm = TRUE)
league_avg_sot90 <- mean(fwd_pool$SoT_90, na.rm = TRUE)
league_avg_ast90 <- mean(fwd_pool$Ast_90, na.rm = TRUE)
league_avg_sh90  <- mean(fwd_pool$Sh_90, na.rm = TRUE)

forward_ratings <- fwd_pool |>
  mutate(
    shrink_weight = nineties / (nineties + k),
    G_PK_90_shrunk = shrink_weight * G_PK_90 + (1 - shrink_weight) * league_avg_gpk90,
    SoT_90_shrunk  = shrink_weight * SoT_90  + (1 - shrink_weight) * league_avg_sot90,
    Ast_90_shrunk  = shrink_weight * Ast_90  + (1 - shrink_weight) * league_avg_ast90,
    Sh_90_shrunk   = shrink_weight * Sh_90   + (1 - shrink_weight) * league_avg_sh90
  ) |>
  mutate(
    gpk90_percentile = percent_rank(G_PK_90_shrunk) * 100,
    sot90_percentile = percent_rank(SoT_90_shrunk) * 100,
    ast90_percentile = percent_rank(Ast_90_shrunk) * 100,
    sh90_percentile  = percent_rank(Sh_90_shrunk) * 100,
    mv_percentile    = percent_rank(market_value_in_eur) * 100
  ) |>
  mutate(
    fwd_rating = round(
      0.45 * gpk90_percentile +
        0.17 * sot90_percentile +
        0.15 * ast90_percentile +
        0.08 * sh90_percentile +
        0.15 * mv_percentile,
      1
    )
  ) |>
  mutate(
    fwd_rating = if_else(Min < 450, pmin(fwd_rating, 65), fwd_rating)
  ) |>
  arrange(desc(fwd_rating))

dim(forward_ratings)
forward_ratings |> select(Player, Squad, Min, Gls, market_value_in_eur, fwd_rating, low_sample) |> head(15)


# ============================================================
# FINAL RESCALING STEP (cross-position comparability)
# ============================================================
# See wing-mid script for full rationale. fwd_rating here is only
# comparable to other forwards (Centre-Forward, Second Striker,
# Left/Right Winger, treated as one combined pool) — needs
# rescaling before feeding into team attack/defence aggregation
# alongside other positions.

forward_ratings <- rescale_position_rating(forward_ratings, "fwd_rating")

forward_ratings |> select(Player, Squad, Min, fwd_rating, final_rating, low_sample) |> head(15)