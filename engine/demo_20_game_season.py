"""Demo: run the model over a 20-game season (not the real 38-game PL
calendar) across dummy teams spanning the full strength spectrum.

A round-robin of N clubs gives each club 2*(N-1) games (home + away vs.
everyone else) - 11 clubs is the smallest pool that lands exactly on 20.

Run: python3 -m engine.demo_20_game_season
"""

import random

from . import league_sim

SEASONS = 5000
SEED = 200127

CLUBS_20_GAME = [
    {"name": "Elite A",     "attack": 90, "defence": 88},
    {"name": "Elite B",     "attack": 85, "defence": 85},
    {"name": "Strong",      "attack": 78, "defence": 76},
    {"name": "Upper-mid",   "attack": 70, "defence": 68},
    {"name": "Mid A",       "attack": 60, "defence": 60},
    {"name": "Mid B",       "attack": 55, "defence": 58},
    {"name": "Lower-mid",   "attack": 50, "defence": 52},
    {"name": "Weak A",      "attack": 42, "defence": 44},
    {"name": "Weak B",      "attack": 36, "defence": 38},
    {"name": "Very Weak",   "attack": 30, "defence": 32},
    {"name": "Bottom",      "attack": 24, "defence": 26},
]


def main():
    rng = random.Random(SEED)
    games_per_team = 2 * (len(CLUBS_20_GAME) - 1)
    assert games_per_team == 20, games_per_team

    summary = league_sim.monte_carlo_league(CLUBS_20_GAME, SEASONS, rng)

    print(f"Monte Carlo 20-game season, {len(CLUBS_20_GAME)} teams of varying strength ({SEASONS} simulated seasons)")
    header = (
        f"{'#':<3}{'Team':<12}{'Rating':>8}{'Mean':>7}{'Median':>8}{'Min':>6}{'Max':>6}"
        f"{'Title%':>8}{'Top4%':>8}{'Bot3%':>8}"
    )
    print(header)
    print("-" * len(header))
    ratings = {c["name"]: (c["attack"] + c["defence"]) / 2 for c in CLUBS_20_GAME}
    for i, row in enumerate(summary, start=1):
        print(
            f"{i:<3}{row['name']:<12}{ratings[row['name']]:>8.0f}"
            f"{row['mean']:>7.1f}"
            f"{row['median']:>8.0f}"
            f"{row['min']:>6.0f}"
            f"{row['max']:>6.0f}"
            f"{row['title_pct']:>7.1f}%"
            f"{row['top4_pct']:>7.1f}%"
            f"{row['relegation_pct']:>7.1f}%"
        )


if __name__ == "__main__":
    main()
