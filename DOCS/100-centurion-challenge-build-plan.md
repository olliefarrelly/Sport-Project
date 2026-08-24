# 100: Centurion Challenge — Build Plan

Goal: get from the scope doc to a playable v1 with the least risk of wasted work. The order below is deliberate — data and math come before UI, because if the sim doesn't feel right, no amount of polish fixes it.

---

## Phase 1 — Prove the Match Model (no real data yet)
Build the Poisson match engine first, with fake/placeholder ratings. This is the riskiest part of the whole project mathematically, so it gets de-risked before we spend time on data collection.

- Build attack/defence rating aggregation from a squad of dummy players
- Build the expected-goals formula (attack vs opposing defence + home advantage)
- Build the Poisson scoreline sampler
- Run a fake 38-game season against 19 dummy opponents with hand-set strength tiers (weak/mid/strong)
- Sanity check: does a "City-strength" dummy squad land around 85-100 points across many simulated seasons? Does a "relegation-strength" dummy squad land in the 20s-30s?
- Tune the rating→goals conversion until the output ranges feel realistic, **before** touching real data

**Output:** a working simulation engine, tested against invented numbers, that produces plausible league tables.

---

## Phase 2 — Build the Real Dataset
Now that we know what shape of input the engine needs, build the actual player pool.

- Define the exact stat fields needed per position (from FBref) — e.g. forwards: goals/90, xG/90, shots/90; midfielders: xA/90, progressive passes; defenders: tackles/90, interceptions/90, aerial win%; keepers: save%, goals prevented
- Research and compile players across the 6 league buckets × 5 age bands, enough per bucket that every spin combination has a real shortlist
- Pull Transfermarkt values for the same player set
- Compute the performance rating and price (value × volatility multiplier) for each player
- Compile the 19 real PL clubs' current squads the same way, run them through the same rating pipeline to get their team strength + apply the coach factor
- Output everything as a single structured JSON dataset

**Output:** `players.json` (draftable pool) and `pl_clubs.json` (19 opponents), both using the exact schema Phase 1's engine expects.

---

## Phase 3 — Recalibrate with Real Data
Swap the dummy data in Phase 1's engine for the real dataset from Phase 2.

- Re-run the sanity checks: does the real Man City squad (if you "drafted" them) land near their actual 2017-18 form? Does a real bottom-table club land where you'd expect?
- Adjust the calibration constants if real player ratings compress or spread out differently than the dummy data did
- This is the point where the "Monte Carlo, thousands of simulated seasons" probability output gets validated for real

**Output:** a calibrated engine running on real players and real opponents.

---

## Phase 4 — Draft System
With good data and a trustworthy engine, build the part the player actually interacts with first.

- Formation lock-in screen
- Spin logic: league + age band + position → filter the dataset → return a shortlist of 4-6 players
- Budget tracking, price display, re-spin cost/logic
- Squad builder UI: 11 starters + bench, formation slots, running budget total
- Position-fit penalty wired into the engine for anyone drafted out of natural position

**Output:** a playable draft flow that ends in a valid, priced 15-16 man squad.

---

## Phase 5 — Season Experience
Connect the finished squad to the engine and build the actual play-through.

- Pre-season screen: run the Monte Carlo simulation, show probability of 100+ points, average points, distribution
- Week-by-week results screen with live table (played 38 fixtures against the 19 real clubs, home and away)
- End-of-season summary: final points/position vs. the Centurions (and optionally Invincibles/Chelsea's record as bonus comparisons)
- "Best XI you could've drafted" hindsight view

**Output:** the full core loop, start to finish, playable end to end.

---

## Phase 6 — Polish Pass
- Visual identity (Roman/centurion theming — colours, icons, typography)
- Mobile-friendly layout check
- Edge case handling (budget running out mid-draft, unfilled slots, etc.)
- Playtest a handful of full runs yourself and adjust calibration/pricing based on how it *feels*, not just the numbers

---

## Stretch Phase (post-v1, from the scope doc)
- Style tags + synergy system
- AI bidding competition
- Injuries/suspensions/form dips
- Standalone site + save/leaderboard persistence

---

## Why this order
- **Engine before data** avoids building a big dataset around a model that might need reworking once real numbers hit it.
- **Data before draft UI** avoids building spin/shortlist logic against a schema that changes later.
- **Full loop before polish** means you have something genuinely playable to test and enjoy as early as possible, and polish time doesn't get spent on a system that later gets rebalanced.

Each phase produces something testable on its own, so we can check in and adjust before moving to the next.
