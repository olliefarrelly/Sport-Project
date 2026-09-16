library(tidyverse)


gk_final  <- gk_ratings      |> select(Player, Squad, sub_position, Min, market_value_in_eur, final_rating)
fwd_final <- forward_ratings |> select(Player, Squad, sub_position, Min, market_value_in_eur, final_rating)
cb_final  <- cb_ratings      |> select(Player, Squad, sub_position, Min, market_value_in_eur, final_rating)
fb_final  <- fb_ratings      |> select(Player, Squad, sub_position, Min, market_value_in_eur, final_rating)
cdm_final <- cdm_ratings     |> select(Player, Squad, sub_position, Min, market_value_in_eur, final_rating)
cm_final  <- cm_ratings      |> select(Player, Squad, sub_position, Min, market_value_in_eur, final_rating)
cam_final <- cam_ratings     |> select(Player, Squad, sub_position, Min, market_value_in_eur, final_rating)
lrm_final <- lrm_ratings     |> select(Player, Squad, sub_position, Min, market_value_in_eur, final_rating)

player_ratings_master <- bind_rows(
  gk_final, fwd_final, cb_final, fb_final, cdm_final, cm_final, cam_final, lrm_final
)

dim(player_ratings_master)


library(jsonlite)

json_data <- toJSON(player_ratings_master, pretty = TRUE, auto_unbox = TRUE)
writeLines(paste0("const playerRatingsMaster = ", json_data, ";"), "player_ratings_master.js")

getwd()
