# ============================================================
# ATTACKING MIDFIELDER (CAM) RATING MODEL
# ============================================================
# Goal: produce a single 0-100 "mid_rating" for every Attacking
# Midfielder, judged mostly on creativity and goal threat, with
# defensive work weighted low (not expected of this role).
#
# DATA NOTE: this dataset has no true passing or chance-creation
# stats (no pass completion %, no progressive passes/carries, no
# key passes, no xA). So this model uses 3 measurable categories +
# market value:
#   - Defensive actions : TklW_90, Int_90
#   - Creativity         : Ast_90, Crs_90  (a WEAK proxy — really
#                           "assists + crossing volume", not true
#                           chance creation. Upgrade this the moment
#                           you have xA / key passes / SCA data.)
#   - Goal threat         : Gls_90, SoT_90
#   - Market value        : real-world scouting/reputation signal
#
# STEP 1 - SHRINKAGE (handling small sample sizes)
# Every raw per-90 stat is pulled ("shrunk") toward the CAM
# league-average for that stat, with the strength of the pull
# depending on minutes played (90-minute-equivalents, "nineties"):
#   - Low minutes  -> stats pulled heavily toward group average
#   - High minutes -> stats stay close to their real, raw numbers
# Controlled by "k" (10, same as other position models — ~10 full
# games before a player's own numbers are mostly trusted).
#
# STEP 2 - PERCENTILE RANKING
# Each shrunk raw stat is converted into a percentile (0-100)
# compared only against other CAMs.
#
# STEP 3 - CATEGORY SCORES
# Defensive = average of TklW_90 and Int_90 percentiles.
# Creativity = average of Ast_90 and Crs_90 percentiles.
# Goal threat = average of Gls_90 and SoT_90 percentiles.
#
# STEP 4 - WEIGHTED COMPOSITE SCORE
#   Defensive 12% | Creativity 40% | Goal threat 33% | Market value 15%
#
# STEP 5 - HARD CAP FOR UNPROVEN PLAYERS
# Any player with under 450 minutes played (roughly 5 full games)
# has mid_rating hard-capped at 65, so a small lucky sample can
# never outrate a proven starter.
#
# NOTE ON CROSS-POSITION COMPARISON: because this model averages
# several uncorrelated stat categories together (a player rarely
# excels at defense AND creativity AND scoring simultaneously),
# the resulting ratings compress toward the middle compared to,
# say, the forward model (where the underlying stats move together
# for elite players). This is fine for comparing CAMs to other
# CAMs, but NOT fine for comparing a CAM's rating directly to a
# forward's rating for team-strength purposes. A final rescale
# step (percent_rank on the finished rating, within each position
# group) should be applied across all position models before they
# feed into team simulation — see rescaling step (separate script).
# ============================================================

library(dplyr)

k <- 10  # confidence threshold, in 90-minute games (same as other position models)

build_mid_ratings <- function(data, sub_pos, w) {

  pos_data <- data |> filter(sub_position == sub_pos)

  league_avg <- pos_data |>
    summarise(
      Int_90  = mean(Int_90,  na.rm = TRUE),
      TklW_90 = mean(TklW_90, na.rm = TRUE),
      Ast_90  = mean(Ast_90,  na.rm = TRUE),
      Crs_90  = mean(Crs_90,  na.rm = TRUE),
      Gls_90  = mean(Gls_90,  na.rm = TRUE),
      SoT_90  = mean(SoT_90,  na.rm = TRUE)
    )

  pos_data |>
    mutate(
      shrink_weight = nineties / (nineties + k),

      Int_90_shrunk  = shrink_weight * Int_90  + (1 - shrink_weight) * league_avg$Int_90,
      TklW_90_shrunk = shrink_weight * TklW_90 + (1 - shrink_weight) * league_avg$TklW_90,
      Ast_90_shrunk  = shrink_weight * Ast_90  + (1 - shrink_weight) * league_avg$Ast_90,
      Crs_90_shrunk  = shrink_weight * Crs_90  + (1 - shrink_weight) * league_avg$Crs_90,
      Gls_90_shrunk  = shrink_weight * Gls_90  + (1 - shrink_weight) * league_avg$Gls_90,
      SoT_90_shrunk  = shrink_weight * SoT_90  + (1 - shrink_weight) * league_avg$SoT_90
    ) |>
    mutate(
      int_pct  = percent_rank(Int_90_shrunk)  * 100,
      tklw_pct = percent_rank(TklW_90_shrunk) * 100,
      ast_pct  = percent_rank(Ast_90_shrunk)  * 100,
      crs_pct  = percent_rank(Crs_90_shrunk)  * 100,
      gls_pct  = percent_rank(Gls_90_shrunk)  * 100,
      sot_pct  = percent_rank(SoT_90_shrunk)  * 100,
      mv_pct   = percent_rank(market_value_in_eur) * 100
    ) |>
    mutate(
      defensive_pct   = (int_pct + tklw_pct) / 2,
      creativity_pct  = (ast_pct + crs_pct) / 2,
      goal_threat_pct = (gls_pct + sot_pct) / 2
    ) |>
    mutate(
      mid_rating = round(
        w$defensive  * defensive_pct +
          w$creativity * creativity_pct +
          w$goal       * goal_threat_pct +
          w$mv         * mv_pct,
        1
      )
    ) |>
    mutate(
      mid_rating = if_else(Min < 450, pmin(mid_rating, 65), mid_rating)
    ) |>
    arrange(desc(mid_rating))
}

cam_weights <- list(defensive = 0.12, creativity = 0.40, goal = 0.33, mv = 0.15)

cam_ratings <- build_mid_ratings(matched_final, "Attacking Midfield", cam_weights)

dim(cam_ratings)
cam_ratings |> select(Player, Squad, Min, Ast_90, Gls_90, market_value_in_eur, mid_rating, low_sample) |> head(15)



# ============================================================
# FINAL RESCALING STEP (cross-position comparability)
# ============================================================
# See wing-mid script for full rationale. In short: mid_rating
# here is only comparable to other CAMs. Before this feeds into
# team attack/defence aggregation alongside other positions, it
# needs to be re-expressed as "how good relative to positional
# peers" on a consistent 0-100 scale.

cam_ratings <- rescale_position_rating(cam_ratings, "mid_rating")

cam_ratings |> select(Player, Squad, Min, mid_rating, final_rating, low_sample) |> head(15)