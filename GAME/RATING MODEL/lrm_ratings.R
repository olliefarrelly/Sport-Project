# ============================================================
# LEFT/RIGHT MIDFIELDER RATING MODEL
# ============================================================
# Goal: produce a single 0-100 "mid_rating" for every Left/Right
# Midfielder — a hybrid role between a winger and a central
# midfielder, expected to contribute defensively down the flank,
# create chances (crossing especially), and chip in goals.
# Left and right sides are combined into one pool (mirror-image
# roles, same as how the full-back model combined LB/RB).
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
# Every raw per-90 stat is pulled ("shrunk") toward the Left/Right
# Midfield league-average for that stat, with the strength of the
# pull depending on minutes played (90-minute-equivalents,
# "nineties"):
#   - Low minutes  -> stats pulled heavily toward group average
#   - High minutes -> stats stay close to their real, raw numbers
# Controlled by "k" (10, same as other position models — ~10 full
# games before a player's own numbers are mostly trusted).
#
# STEP 2 - PERCENTILE RANKING
# Each shrunk raw stat is converted into a percentile (0-100)
# compared only against other Left/Right Midfielders.
#
# STEP 3 - CATEGORY SCORES
# Defensive = average of TklW_90 and Int_90 percentiles.
# Creativity = average of Ast_90 and Crs_90 percentiles.
# Goal threat = average of Gls_90 and SoT_90 percentiles.
#
# STEP 4 - WEIGHTED COMPOSITE SCORE
#   Defensive 20% | Creativity 40% | Goal threat 25% | Market value 15%
# (Creativity weighted highest, since crossing/chance creation from
#  the flank is this role's main job; some defensive expectation,
#  since they still track back more than a winger typically would.)
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
# for elite players). This is fine for comparing this group to each
# other, but NOT fine for comparing against a different position's
# rating for team-strength purposes — see the rescaling step at the
# bottom of this file, which fixes this across ALL position models.
# ============================================================

library(dplyr)

k <- 10  # confidence threshold, in 90-minute games (same as other position models)

build_mid_ratings <- function(data, sub_pos, w) {
  
  pos_data <- data |> filter(sub_position %in% sub_pos)
  
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

lrm_weights <- list(defensive = 0.20, creativity = 0.40, goal = 0.25, mv = 0.15)

lrm_ratings <- build_mid_ratings(matched_final, c("Left Midfield", "Right Midfield"), lrm_weights)

dim(lrm_ratings)
lrm_ratings |> select(Player, Squad, sub_position, Min, Crs_90, Ast_90, market_value_in_eur, mid_rating, low_sample) |> head(15)


# ============================================================
# FINAL RESCALING STEP
# ============================================================
# WHY THIS EXISTS:
# Different position models produce ratings on very different
# ranges. The forward model's underlying stats (goals, shots,
# assists) tend to move TOGETHER for elite players, so top
# forwards land near 95-100. Midfielder models average several
# UNCORRELATED categories (defense vs. creativity vs. scoring) —
# few players are elite at all three at once, so even the very
# best midfielders' composite scores land in the 70s-80s instead
# of near 100.
#
# This is fine when comparing players WITHIN one position (e.g.
# ranking CDMs against other CDMs for the wheel), but it's a real
# problem the moment ratings get compared ACROSS positions — like
# when the game combines individual ratings into an overall team
# attack/defence score for the match simulation. Left uncorrected,
# a team stacked with great midfielders but average forwards would
# look weaker than it should, purely because of how the two
# formulas compress differently — not because of real quality.
#
# THE FIX:
# Take the FINAL rating column from each position model (after
# shrinkage, weighting, and the low-minutes cap have already been
# applied) and run it through percent_rank() one more time, within
# that position group. This stretches whatever range the raw
# composite happened to land in (e.g. 60-90 for CDMs, 95-100 for
# forwards) into a full, consistent 0-100 spread for every
# position. The single best CDM in the dataset ends up near 100 —
# the same as the single best forward — because both are being
# expressed as "how good is this player relative to their own
# positional peers", which is the fairest basis for team-strength
# comparison across different roles.
#
# This does throw away magnitude information (how much better the
# best player is than the 50th-best in that position becomes pure
# rank order instead of a raw gap) — an acceptable trade-off here,
# since what the wheel/team-simulation actually needs is relative
# quality within a role, not the raw statistical gap.
# ============================================================

rescale_position_rating <- function(df, rating_col) {
  df |>
    mutate(
      final_rating = round(percent_rank(.data[[rating_col]]) * 100, 1)
    ) |>
    arrange(desc(final_rating))
}

lrm_ratings <- rescale_position_rating(lrm_ratings, "mid_rating")

lrm_ratings |> select(Player, Squad, Min, mid_rating, final_rating, low_sample) |> head(15)