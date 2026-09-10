# ============================================================
# MIDFIELDER RATING MODEL (CDM / CM / CAM)
# ============================================================
# Goal: produce a single 0-100 "mid_rating" for every midfielder,
# usable by the wheel/game to represent overall quality — with a
# separate weighting profile for defensive mids, central/box-to-box
# mids, and attacking mids, since "midfielder" covers very
# different jobs on the pitch.
#
# DATA NOTE: unlike the GK model, this dataset has no true passing
# or chance-creation stats (no pass completion %, no progressive
# passes/carries, no key passes, no xA). So instead of 4 categories
# this model uses 3 measurable categories + market value:
#   - Defensive actions : TklW_90, Int_90
#   - Creativity         : Ast_90, Crs_90  (a WEAK proxy — really
#                           "assists + crossing volume", not true
#                           chance creation. Upgrade this the moment
#                           you have xA / key passes / SCA data.)
#   - Goal threat         : Gls_90, SoT_90
#   - Market value        : real-world scouting/reputation signal,
#                           same role as in the GK model (15%)
#
# STEP 1 - SHRINKAGE (handling small sample sizes)
# Same idea as the GK model: every raw per-90 stat is pulled
# ("shrunk") toward the league-average for that stat *within the
# same sub-position group* (e.g. a CDM's Int_90 is shrunk toward
# the average Int_90 for other CDMs, not all midfielders lumped
# together), with the strength of the pull depending on minutes
# played (90-minute-equivalents, "nineties"):
#   - Low minutes  -> stats pulled heavily toward group average
#   - High minutes -> stats stay close to their real, raw numbers
# Controlled by "k" (10, same as the GK model — ~10 full games
# before a player's own numbers are mostly trusted).
#
# STEP 2 - PERCENTILE RANKING
# Each shrunk raw stat is converted into a percentile (0-100)
# compared only against other players in the SAME sub-position
# group (CDMs vs CDMs, CMs vs CMs, CAMs vs CAMs) — mirrors how the
# GK model only ever compared keepers to keepers.
#
# STEP 3 - CATEGORY SCORES
# Where a category is built from two raw stats (e.g. Defensive =
# TklW_90 + Int_90), the category score is the average of the two
# stats' percentiles. This avoids arbitrarily picking just one stat
# to represent a category.
#
# STEP 4 - WEIGHTED COMPOSITE SCORE (profile-specific)
# The 3 category percentiles + market value percentile are combined
# using a different weight profile per role, reflecting what that
# role is actually judged on:
#
#              Defensive  Creativity  Goal threat  Market value
#   CDM           50%         20%         15%          15%
#   CM            28%         30%         27%          15%
#   CAM           12%         40%         33%          15%
#
# (CDM = destroyer/deep mid, judged mostly on defensive work.
#  CM   = box-to-box/all-round mid, fairly even across the board.
#  CAM  = attacking mid, judged mostly on creativity + goal threat.)
#
# STEP 5 - HARD CAP FOR UNPROVEN PLAYERS
# Same safeguard as the GK model: any player with under 450 minutes
# played (roughly 5 full games) has mid_rating hard-capped at 65,
# so a small lucky sample can never outrate a proven starter.
#
# ASSUMPTION TO VERIFY: this script filters on sub_position values
# "Defensive Midfield", "Central Midfield", "Attacking Midfield"
# (Transfermarkt-style labels, matching how the GK model used
# sub_position == "Goalkeeper"). Run:
#   unique(matched_final$sub_position)
# and adjust the three filter strings below if your labels differ
# (e.g. if wide mids like "Left Midfield"/"Right Midfield" should
# be folded into one of these three groups instead of excluded).
# ============================================================

library(dplyr)

k <- 10  # confidence threshold, in 90-minute games (same as GK model)

# ------------------------------------------------------------
# Reusable builder: same shrink -> percentile -> weight -> cap
# pipeline as the GK model, parameterized by sub-position and
# weight profile so CDM/CM/CAM share one implementation.
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# Weight profiles (Defensive / Creativity / Goal threat / Market value)
# ------------------------------------------------------------
cdm_weights <- list(defensive = 0.50, creativity = 0.20, goal = 0.15, mv = 0.15)
cm_weights  <- list(defensive = 0.28, creativity = 0.30, goal = 0.27, mv = 0.15)
cam_weights <- list(defensive = 0.12, creativity = 0.40, goal = 0.33, mv = 0.15)

# ------------------------------------------------------------
# Build ratings for each profile
# ------------------------------------------------------------
cdm_ratings <- build_mid_ratings(matched_final, "Defensive Midfield", cdm_weights)
cm_ratings  <- build_mid_ratings(matched_final, "Central Midfield",   cm_weights)
cam_ratings <- build_mid_ratings(matched_final, "Attacking Midfield", cam_weights)

dim(cdm_ratings); dim(cm_ratings); dim(cam_ratings)

cdm_ratings |> select(Player, Squad, Min, TklW_90, Int_90, market_value_in_eur, mid_rating, low_sample) |> head(15)
cm_ratings  |> select(Player, Squad, Min, Ast_90, Gls_90, market_value_in_eur, mid_rating, low_sample) |> head(15)
cam_ratings |> select(Player, Squad, Min, Ast_90, Gls_90, market_value_in_eur, mid_rating, low_sample) |> head(15)