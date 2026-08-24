# 100: Centurion Challenge — Scope & Plan

## Concept
A browser-based football (soccer) team-builder. Build a Premier League squad from a $1B budget, drafted from a spin-based system pulling real players across the world's top leagues. Simulate a 38-game season against the other 19 real PL clubs and see how close you get to Manchester City's 2017-18 Centurions record — 100 points.

**Name:** 100: Centurion Challenge (short form: 100pts)

**Target record:** 100 points (City, 2017-18: 32W-4D-2L). Chosen over an unbeaten/Invincibles target because it's a clean, universally recognisable number, achievable-but-hard, and rewards win *margin and frequency* rather than punishing every single draw — better fit for a probability-driven model than a binary perfect/imperfect outcome.

---

## Core Loop
1. Lock a formation (4-3-3, 4-4-2, 3-5-2, etc.) — sets starting slots + bench slots.
2. Draft a 16 player squad (11 starters + 5 bench) under a $1B budget using the spin-and-shortlist system.
3. Before the season starts, run a Monte Carlo simulation (thousands of simulated seasons) and show your probability of hitting 100+ points, plus average points, alongside the 19 real PL opponents' own model-generated strength ratings.
4. Play through one "canon" season, week by week, with results and a live table.
5. End-of-season summary: final points, comparison to the Centurions/Invincibles/other historic marks, best XI you could have drafted with hindsight (nice touch borrowed from 73-9).

---

## Data Sources
- **FBref (Football Reference)** — primary source for performance stats: goals/90, xG, xA, progressive passes, tackles, interceptions, save%, etc., segmented by position. Drives the *performance rating* layer.
- **Transfermarkt** — market values, drives the *price* layer. Note: live scraping isn't possible from inside the game itself (no cross-origin access from a browser artifact), so this will be built as a static dataset compiled once during development and shipped with the game. Refreshing the dataset is a manual/periodic task, not a live feature.
- Both sources reflect the **current 2025/26 season** — no historical seasons, no live updates during play.
- No reliance on Opta or other proprietary rating feeds — all team/player ratings are built in-house from the above two sources so the model is self-consistent and explainable.

---

## Player Pool
- **6 league buckets:** Premier League, La Liga, Serie A, Bundesliga, Ligue 1, and **Rest of World** (everyone else — Eredivisie, Liga Portugal, Brazil, MLS, Saudi Pro League, etc.) — ensures no spin filter ever comes up empty and opens the door to fun wildcard picks without needing deep data on every minor league.
- **4-year age bands:** roughly 16-19 / 20-23 / 24-27 / 28-31 / 32-35+ — mirrors real scouting brackets (prospect / rising / prime / experienced / veteran) and feeds into price volatility (younger bands skew toward hype premiums, veteran bands skew toward value/stability).
- Target pool size: curated to squad-quality players only (not every professional footballer) — likely 150-300 players per league bucket, enough for every league × age × position combination to return a non-empty shortlist.

---

## Player Rating Model
Two layers, kept deliberately separate so price and quality aren't the same thing:

1. **Performance rating** (drives sim strength): built from position-relevant FBref stats — attacking output for forwards/wingers, creation stats for midfielders, defensive actions for defenders, shot-stopping/distribution for keepers.
2. **Market price** (drives budget cost): Transfermarkt value × a **volatility multiplier** (roughly 0.8x–2x) reflecting hype, release clauses, and "wanted man" premiums. Young/high-potential players skew toward the higher end; squad/depth players skew closer to 1x. Multiplier is revealed at spin time, adding a "gamble or re-spin" decision point.

Keeping these separate is what creates real drafting tension — a properly-priced value pick vs. an overhyped name at the same output level.

---

## Team Strength → Match Model
- Aggregate a squad's XI into **attack** and **defence** ratings, weighted by position (attackers/creators weight attack more; defenders/keeper weight defence more).
- **Position-fit penalty (v1):** playing a player out of their natural position reduces their effective rating in the match model.
- Expected goals for each side calculated from attack rating vs. opposing defence rating, with a small home-advantage adjustment.
- Actual scorelines drawn from a **Poisson distribution** around those expected goals — gives realistic, varied results (0-0s, 4-2s, etc.) instead of deterministic outcomes.
- **Calibration:** the whole rating→goals conversion is anchored against real historical PL points totals (top-6 strength squad ≈ historical top-6 points range, mid-table ≈ mid-table range, etc.) so results feel plausible rather than arbitrary.
- **Coach factor:** a lightweight multiplier per manager (based on career win% / reputation) applied to the 19 AI opponents, so e.g. a Guardiola side gets a small bump over an equivalent-rated squad with a less proven manager. Simple, explainable, no deep tactical modelling.

---

## The 19 Opponents
All real, current Premier League clubs, rated using the *exact same model* as the player's own squad (their real current players run through the same performance-rating and team-strength pipeline). This means difficulty is self-generated rather than hand-tuned — City should naturally come out near the top, a newly-promoted side near the bottom, with no manual balancing needed.

---

## Draft Mechanics
- **Formation lock-in** happens first, defining the slots to fill.
- For each slot, spin **league + age band + position** (e.g. "Serie A, CB, 20-23") to reveal a shortlist of 4-6 real matching players with stats and price shown.
- Pick one from the shortlist — a shortlist (not a single forced player) keeps every spin meaningful even with a constrained real-player pool.
- **Re-spin costs money** (à la 73-9's paid re-spin) — burns budget for another shot at a better filter, a genuine risk/reward lever.
- Repeat until all 11 starters + bench slots are filled or budget runs out.
- **No bidding system in v1** (flagged as a stretch goal — full AI-bidding competition is its own substantial feature).

---

## Season Simulation
- **Week-by-week results** with a live, updating league table — not an instant full-season result, and not full match-by-match commentary (good middle ground for build effort vs. immersion).
- **Pre-season probability readout:** before playing, show Monte Carlo results across thousands of simulated seasons — e.g. *"Simulated 10,000 seasons: 100+ points in 14% of them, average 87 points"* — this is the explicit "data-driven" hook.
- Then one **canon playthrough** of the season is played out week by week for the narrative experience.
- End of season: final points/table position, comparison to the Centurions (and optionally the Invincibles and Chelsea's fewest-conceded record as secondary bragging-rights stats), and a "best XI you could've drafted" hindsight view.

---

## V1 Scope vs. Stretch Goals

**V1 (build this first):**
- Player pool: 6 league buckets × 4-year age bands, current-season FBref + Transfermarkt data
- Spin + shortlist draft, formation lock-in, re-spin cost
- $1B budget, 11 starters + 4-5 bench
- Position-fit penalty only (no style/chemistry system)
- Poisson-based match model, calibrated against real historical points totals
- 19 real PL clubs rated with the same model + lightweight coach factor
- Monte Carlo probability readout + one week-by-week canon season
- Single HTML/JS artifact — no build step, runs standalone in-browser

**Stretch goals (layer in later):**
- Style tags + synergy system (Option B from earlier: 4-5 broad tags like High Press, Target Man, Ball-Playing CB, with simple compatibility bonuses/penalties)
- Bidding system for players (have to bid instead of paying transfermarkt value - more for young players, less for older)
- Injuries/suspensions/form dips affecting bench rotation over the season
- Full standalone site + leaderboard/save persistence (vs. playing purely within a chat artifact)

---

## Tech Approach
- Single-file HTML/JS artifact — matches how the reference games (82-0, 38-0, 73-9) are built, avoids a build step, and is trivially shareable/playable.
- Player/team dataset compiled once (via research) into a static JSON file shipped with the game — not live-fetched at runtime.
- In-memory game state only for v1 (no persistent storage needed unless we build toward a real standalone site later).

## Repo Structure

```
100pts/
├── README.md
├── docs/
│   └── scope.md
├── data/
│   ├── raw/
│   └── processed/
├── pipeline/
│   ├── scrape_fbref.py
│   ├── scrape_transfermarkt.py
│   ├── rating_model.py
│   ├── price_model.py
│   └── build_player_pool.py
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
