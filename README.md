# 100: Centurion Challenge

A browser-based football (soccer) team-builder. Build a Premier League squad from a $1B budget, drafted from a spin-based system pulling real players across the world's top leagues, then simulate a 38-game season against the other 19 real PL clubs and see how close you get to Manchester City's 2017-18 Centurions record — **100 points**.

## Why 100 points?

Chosen over an unbeaten/"Invincibles" target because it's a clean, universally recognisable number that's achievable-but-hard, and it rewards win margin and frequency rather than punishing every single draw — a better fit for a probability-driven model than a binary perfect/imperfect outcome.

## How it works

1. **Lock a formation** (4-3-3, 4-4-2, 3-5-2, etc.) — sets your starting slots and bench slots.
2. **Draft a squad** under a $1B budget using the spin-and-shortlist system: spin a formation slot (e.g. "Left Winger"), and the wheel pulls from the pool of real players eligible for that exact sub-position.
3. **See your odds** — before kickoff, a Monte Carlo simulation runs thousands of simulated seasons and shows your probability of hitting 100+ points, alongside model-generated strength ratings for all 19 real PL opponents.
4. **Play the season** week by week, with results and a live table.
5. **End-of-season summary** — final points, how you stack up against the Centurions (and other historic marks), and the best XI you could have drafted with hindsight.

## Data

- **FBref** — 2025/26 season performance stats (goals, assists, shots, defensive actions, goalkeeping stats, etc.) for Big 5 league players, one row per player-club stint.
- **Transfermarkt** — market values, sourced from a bundled `.duckdb` export, joined in to price players and act as a real-world sanity check on the stats-only ratings.
- Both reflect the current 2025/26 season. No historical seasons, no live updates during play — data is compiled once into a static dataset shipped with the game (no live scraping from inside the browser).
- Player ratings are built entirely in-house from these two sources — no reliance on proprietary rating feeds — so the model stays self-consistent and explainable.

## Data pipeline (built in R)

Raw FBref and Transfermarkt exports go through several cleaning stages before they're usable:

1. **Mid-season transfer handling** — a player who changed clubs mid-season appears as multiple rows in the raw FBref data; these are merged into one season-total row per player, with their "current club" label taken from whichever stint they played the most minutes at.
2. **Identity resolution** — matching FBref players to their Transfermarkt market value by name isn't reliable on its own (shared names, accented characters, nicknames, shortened names). Matching is done on normalised name + birth year, with a manual lookup table correcting known mismatches (e.g. nicknames like "Nico Paz" → "Nicolás Paz", transliteration differences like "Djordje Petrovic" → "Đorđe Petrović").
3. **Per-90 normalisation** — raw season totals are converted to per-90-minute rates so players with different amounts of playing time can be fairly compared.
4. **Coverage** — roughly 85% of this season's Big 5 league players are successfully matched to a market value; the remainder are mostly fringe squad players or unresolved nickname cases.

Result: one clean master table, ~2,300 players, covering attacking, defensive, goalkeeping, and discipline stats plus market value, ready for rating and for the game's spin-draft to query by exact sub-position (Centre-Back, Left Winger, Defensive Midfield, etc.).

## Rating model

Position-specific rating models (not a single generic formula), since different positions are measured by completely different stats. Each model follows the same underlying structure:

- **Statistical shrinkage** — a player's raw stats are pulled toward the position's league-average, weighted by how many minutes they've played. This stops a player with a tiny, lucky sample (e.g. one clean sheet in one game) from rating as if they were the season's best.
- **Percentile ranking** — each relevant stat is converted to a percentile *within that position group only*, so wildly different stats (a save percentage, a per-90 rate) can be combined on the same scale.
- **Weighted composite score** — the percentiles are combined into one 0–100 rating, with weights reflecting what actually matters for that position.
- **Market value blend** — a modest weighting on market value acts as a real-world sanity check, correcting cases where raw stats alone over- or under-rate a player relative to team context the stats can't see (e.g. a player putting up huge shot volume because his team is otherwise weak, or a player whose defensive stats look "quiet" purely because his dominant team faces very little pressure).
- **Small-sample cap** — players under a minimum minutes threshold have their rating hard-capped, so an unproven backup can never outrank a proven starter purely on a small lucky sample.

**Completed so far:** Goalkeepers, Forwards, Centre-Backs, Full-Backs.
**In progress:** Midfielders (likely split into attacking-mid and defensive-mid formulas, given how different those roles are statistically).

Known limitation, kept deliberately rather than "fixed": the available stats can't fully capture some aspects of quality (e.g. progressive passing, positional intelligence) — market value helps but doesn't fully close this gap. Acceptable for a game; would need richer data (xG, xA, progressive actions) to close further.

## Match & season simulation (planned)

- Squad ratings aggregate into **attack** and **defence** scores, weighted by position, with a position-fit penalty for out-of-position players.
- Expected goals come from attack vs. opposing defence (plus a small home-advantage bump), with actual scorelines drawn from a **Poisson distribution** for realistic, varied results.
- The whole ratings-to-goals conversion is calibrated against real historical PL points totals.
- The 19 real PL opponents are rated with the *exact same model* as your own squad — so difficulty is self-generated, not hand-tuned.

## V1 scope

- Player pool: Big 5 leagues, current-season FBref + Transfermarkt data, matched and rated in R
- Spin-draft filtered by exact sub-position per formation slot
- $1B budget squad draft
- Position-fit penalty only (no style/chemistry system yet)
- Poisson-based match model, calibrated against real historical points totals
- 19 real PL clubs rated with the same model
- Monte Carlo probability readout + one week-by-week canon season
- Single HTML/JS artifact — no build step, runs standalone in-browser

## Stretch goals

- Style tags + synergy system (e.g. High Press, Target Man, Ball-Playing CB with compatibility bonuses/penalties)
- Bidding system for players instead of flat Transfermarkt pricing
- Injuries/suspensions/form dips affecting bench rotation over the season
- Full standalone site with leaderboard/save persistence
- Richer underlying stats (xG, xA, progressive passing) if a suitable data source is found, to reduce reliance on market value as a correction factor

## Tech approach

- **Data pipeline: R** — cleaning, matching, and rating model calculations (`dplyr`, `stringr`, `stringi`, `lubridate`).
- **Game: single-file HTML/JS artifact**, matching how the reference games (82-0, 38-0, 73-9) are built — no build step, trivially shareable and playable. The player/rating dataset is compiled once via the R pipeline into a static file shipped with the game, not fetched live at runtime. V1 keeps game state in-memory only.

## Repo structure

```
Sport-Project/
├── README.md
├── DATA/
│   ├── raw/
│   │   ├── transfermarkt-datasets.duckdb
│   │   └── players_data-2025_2026.csv
│   └── processed/
│       └── player_ratings_master.csv
├── pipeline/
│   └── build_player_ratings.R
├── game/
│   ├── index.html
│   ├── sim/
│   │   ├── match_engine.js
│   │   ├── team_strength.js
│   │   └── season_sim.js
│   ├── draft/
│   │   └── spin.js
│   └── ui/
├── schema/
│   └── types.md
└── .gitignore
```
