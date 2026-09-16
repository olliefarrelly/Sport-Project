# ============================================================
# GOALKEEPER RATING MODEL
# ============================================================
# Goal: produce a single 0-100 "gk_rating" for every goalkeeper,
# usable by the wheel/game to represent overall quality.
#
# Stats used: Save% (shot-stopping), GA_90 (goals conceded per 90,
# lower = better), CS_90 (clean sheets per 90).
#
# STEP 1 - SHRINKAGE (handling small sample sizes)
# A keeper with only 90 minutes played can post a fluke 100% save
# rate that looks "perfect" but tells us almost nothing reliable.
# To fix this, every keeper's raw stats are pulled ("shrunk") toward
# the league-average goalkeeper stat, with the strength of the pull
# depending on how many minutes they've played:
#   - Low minutes  -> stats pulled heavily toward league average
#   - High minutes -> stats stay close to their real, raw numbers
# This is controlled by "k" (currently 10, meaning ~10 full games
# worth of minutes before a keeper's own numbers are mostly trusted).
#
# STEP 2 - PERCENTILE RANKING
# Once shrunk, each stat is converted into a percentile rank
# (0-100) compared only against other goalkeepers. This puts very
# different stats (a percentage, a per-90 rate, etc.) onto the same
# comparable scale before combining them.
#
# STEP 3 - WEIGHTED COMPOSITE SCORE
# Four percentiles are combined into one gk_rating:
#   34% Save% (core shot-stopping skill)
#   34% GA_90, inverted (fewer goals conceded = higher score)
#   17% Clean sheets per 90 (team outcome, so weighted lower since
#       it's influenced by the defense in front of the keeper too)
#   15% Market value (real-world scouting/reputation signal, helps
#       correct cases where raw stats over/under-rate a keeper due
#       to factors the stats can't see, e.g. quality of defense in
#       front of them, big-game reputation, consistency over time)
#
# STEP 4 - HARD CAP FOR UNPROVEN KEEPERS
# Shrinkage alone can't fully stop a lucky small sample from still
# scoring highly (it only pulls toward average, not below it). So
# as a final safeguard, any keeper with under 450 minutes played
# (roughly 5 full games) has their rating hard-capped at 65 - this
# guarantees no unproven backup can ever rate near a proven starter,
# no matter how good their tiny sample looks.
# ============================================================





league_avg_save_pct <- mean(matched_final$Save_pct[matched_final$sub_position == "Goalkeeper"], na.rm = TRUE)
league_avg_ga90 <- mean(matched_final$GA_90[matched_final$sub_position == "Goalkeeper"], na.rm = TRUE)

k <- 10  # confidence threshold, in 90-minute games

gk_ratings <- matched_final |>
  filter(sub_position == "Goalkeeper") |>
  mutate(
    CS_90 = if_else(nineties > 0, round(CS / nineties, 2), NA_real_)
  ) |>
  mutate(
    league_avg_cs90 = mean(CS_90, na.rm = TRUE)
  ) |>
  mutate(
    shrink_weight = nineties / (nineties + k),
    Save_pct_shrunk = shrink_weight * Save_pct + (1 - shrink_weight) * league_avg_save_pct,
    GA_90_shrunk = shrink_weight * GA_90 + (1 - shrink_weight) * league_avg_ga90,
    CS_90_shrunk = shrink_weight * CS_90 + (1 - shrink_weight) * league_avg_cs90
  ) |>
  mutate(
    save_pct_percentile = percent_rank(Save_pct_shrunk) * 100,
    ga90_percentile = percent_rank(-GA_90_shrunk) * 100,
    cs90_percentile = percent_rank(CS_90_shrunk) * 100,
    mv_percentile = percent_rank(market_value_in_eur) * 100
  ) |>
  mutate(
    gk_rating = round(
      0.34 * save_pct_percentile +
        0.34 * ga90_percentile +
        0.17 * cs90_percentile +
        0.15 * mv_percentile,
      1
    )
  ) |>
  mutate(
    gk_rating = if_else(Min < 450, pmin(gk_rating, 65), gk_rating)
  ) |>
  arrange(desc(gk_rating))

dim(gk_ratings)
gk_ratings |> select(Player, Squad, Min, Save_pct, GA_90, market_value_in_eur, gk_rating, low_sample) |> head(15)


# ============================================================
# FINAL RESCALING STEP (cross-position comparability)
# ============================================================
# See wing-mid script for full rationale. gk_rating here is only
# comparable to other goalkeepers — needs rescaling before feeding
# into team attack/defence aggregation alongside other positions.

gk_ratings <- rescale_position_rating(gk_ratings, "gk_rating")

gk_ratings |> select(Player, Squad, Min, gk_rating, final_rating, low_sample) |> head(15)