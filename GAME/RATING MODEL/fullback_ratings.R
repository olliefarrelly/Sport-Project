# ============================================================
# FULL-BACK RATING MODEL
# ============================================================
# Added variables onG, onGA and plusminus
# Applies to: Left-Back, Right-Back (combined into one pool)
# Stats used: tackles won per 90, interceptions per 90, crosses per 90
# (attacking output), fouls per 90 (inverted), market value.
# Same shrinkage -> percentile -> weighted composite -> cap structure
# as the other position models.
# ============================================================
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
    onG = sum(onG, na.rm = TRUE),
    onGA = sum(onGA, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    G_PK = Gls - PK,
    Save_pct = if_else(SoTA > 0, round(Saves / SoTA * 100, 1), NA_real_)
  )

dim(season_totals)


current_club <- players_data |>
  group_by(Player, Born) |>
  slice_max(Min, n = 1, with_ties = FALSE) |>
  ungroup()

players_final <- current_club |>
  select(Player, Born, Nation, Pos, Squad, Comp, Age) |>
  left_join(season_totals, by = c("Player", "Born")) |>
  mutate(Player_clean = stri_trans_general(Player, "Latin-ASCII")) |>
  left_join(name_fixes, by = c("Player" = "fbref_name")) |>
  mutate(match_name = coalesce(tm_name, Player_clean))

matched_final <- players_final |>
  inner_join(big5_clean, by = c("match_name" = "name_clean", "Born" = "birth_year")) |>
  filter(!(Player == "Vitinha" & Born == 2000 & club == "Paris Saint-Germain")) |>
  mutate(
    nineties = Min / 90,
    Gls_90 = if_else(nineties > 0, round(Gls / nineties, 2), NA_real_),
    Ast_90 = if_else(nineties > 0, round(Ast / nineties, 2), NA_real_),
    Sh_90 = if_else(nineties > 0, round(Sh / nineties, 2), NA_real_),
    SoT_90 = if_else(nineties > 0, round(SoT / nineties, 2), NA_real_),
    Int_90 = if_else(nineties > 0, round(Int / nineties, 2), NA_real_),
    TklW_90 = if_else(nineties > 0, round(TklW / nineties, 2), NA_real_),
    Crs_90 = if_else(nineties > 0, round(Crs / nineties, 2), NA_real_),
    GA_90 = if_else(nineties > 0, round(GA / nineties, 2), NA_real_),
    onG_90 = if_else(nineties > 0, round(onG / nineties, 2), NA_real_),
    onGA_90 = if_else(nineties > 0, round(onGA / nineties, 2), NA_real_),
    plusminus_90 = onG_90 - onGA_90,
    low_sample = Min < 450
  )

dim(matched_final)











k <- 10

fb_pool <- matched_final |>
  filter(sub_position %in% c("Left-Back", "Right-Back")) |>
  mutate(Fls_90 = if_else(nineties > 0, round(Fls / nineties, 2), NA_real_))

league_avg_int90_fb  <- mean(fb_pool$Int_90, na.rm = TRUE)
league_avg_tklw90_fb <- mean(fb_pool$TklW_90, na.rm = TRUE)
league_avg_crs90_fb  <- mean(fb_pool$Crs_90, na.rm = TRUE)
league_avg_fls90_fb  <- mean(fb_pool$Fls_90, na.rm = TRUE)

fb_ratings <- fb_pool |>
  mutate(
    shrink_weight = nineties / (nineties + k),
    Int_90_shrunk  = shrink_weight * Int_90  + (1 - shrink_weight) * league_avg_int90_fb,
    TklW_90_shrunk = shrink_weight * TklW_90 + (1 - shrink_weight) * league_avg_tklw90_fb,
    Crs_90_shrunk  = shrink_weight * Crs_90  + (1 - shrink_weight) * league_avg_crs90_fb,
    Fls_90_shrunk  = shrink_weight * Fls_90  + (1 - shrink_weight) * league_avg_fls90_fb
  ) |>
  mutate(
    int90_percentile  = percent_rank(Int_90_shrunk) * 100,
    tklw90_percentile = percent_rank(TklW_90_shrunk) * 100,
    crs90_percentile  = percent_rank(Crs_90_shrunk) * 100,
    fls90_percentile  = percent_rank(-Fls_90_shrunk) * 100,
    mv_percentile     = percent_rank(market_value_in_eur) * 100
  ) |>
  mutate(
    fb_rating = round(
      0.20 * tklw90_percentile +
        0.15 * int90_percentile +
        0.15 * crs90_percentile +
        0.05 * fls90_percentile +
        0.25 * mv_percentile +
        0.10 * plusminus_90 +
        0.05 * onGA_90 +
        0.05 * onG_90,
      1
    )
  ) |>
  mutate(
    fb_rating = if_else(Min < 450, pmin(fb_rating, 65), fb_rating)
  ) |>
  arrange(desc(fb_rating))

dim(fb_ratings)
fb_ratings |> select(Player, Squad, sub_position, Min, Int_90, TklW_90, Crs_90, market_value_in_eur, fb_rating, low_sample) |> head(15)




matched_final |> filter(str_detect(Player, "Davies|Hakimi|Alexander-Arnold|Cucurella")) |> 
  select(Player, Squad, sub_position, Min, Int_90, TklW_90, Crs_90, market_value_in_eur)

fb_ratings |> filter(str_detect(Player, "Hakimi|Davies|Cucurella|Alexander-Arnold")) |> 
  select(Player, Squad, Min, Int_90, TklW_90, Crs_90, market_value_in_eur, fb_rating, low_sample)