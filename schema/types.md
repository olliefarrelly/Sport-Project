# Data Schema (Phase 2 draft)

Target shape of `players.json` (draftable pool) and `pl_clubs.json` (19
opponents) — see DOCS/100-centurion-challenge-build-plan.md, Phase 2. Nothing
here is populated with real data yet; `pipeline/` will produce it once built
out, and `engine/` (later `game/sim/`) consumes it.

## Player

| field | type | notes |
|---|---|---|
| id | string | stable slug, e.g. `erling-haaland` |
| name | string | |
| league | enum | `PL` \| `LaLiga` \| `SerieA` \| `Bundesliga` \| `Ligue1` \| `RestOfWorld` |
| club | string | current real-world club |
| position | enum | e.g. `GK` \| `CB` \| `FB` \| `DM` \| `CM` \| `AM` \| `W` \| `ST` — exact buckets TBD, must map onto the formation slots (4-3-3, 4-4-2, 3-5-2, etc.) |
| age_band | enum | `16-19` \| `20-23` \| `24-27` \| `28-31` \| `32-35+` |
| performance_rating | number | 0-100, derived from the position-relevant stats below; drives `engine/team_strength.py` aggregation |
| stats | object | raw per-90 FBref inputs behind the rating (position-dependent, see below) |
| market_value | number | Transfermarkt value, source figure |
| volatility_multiplier | number | 0.8-2.0, revealed at spin time |
| price | number | `market_value * volatility_multiplier` — in-game draft cost |

### Position-relevant stat fields (feed `performance_rating`)
- **Forwards/wingers:** goals/90, xG/90, xA/90, shots/90
- **Midfielders:** xA/90, progressive passes/90, key passes/90
- **Defenders:** tackles/90, interceptions/90, aerial win%
- **Keepers:** save%, goals prevented

## Club (19 real PL opponents)

| field | type | notes |
|---|---|---|
| id | string | |
| name | string | |
| squad | Player[] | current real squad, rated via the same pipeline as the draftable pool |
| attack_rating | number | position-weighted aggregate — same function `engine/team_strength.py` will use once it moves off dummy data |
| defence_rating | number | position-weighted aggregate |
| coach_factor | number | manager win%/reputation multiplier applied to attack + defence |

## Open questions for Phase 2 build-out
- Exact position bucket granularity, and how it maps onto formation slots.
- How `performance_rating` combines the per-position stat fields into one
  0-100 number — weights are TBD, calibrated in Phase 3 against real squads
  (e.g. does a real Man City XI land near their actual 2017-18 output).
- Whether `engine/config.py`'s `RATING_POWER`/`BASELINE_GOALS` need retuning
  once real ratings (rather than hand-picked dummy 30-90 values) are plugged
  in — flagged explicitly as a Phase 3 step in the build plan.
