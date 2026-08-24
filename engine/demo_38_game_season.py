"""Demo: run the model over a standard 38-game, 20-team season (matches the
real PL calendar shape) using hypothetical clubs spanning the strength
spectrum, not real teams.

A round-robin of 20 clubs gives each club 2*(20-1) = 38 games.

Run: python3 -m engine.demo_38_game_season
"""

import random

from . import league_sim

SEASONS = 5000
SEED = 380127

CLUBS_38_GAME = [
    {"name": "Titan",      "attack": 92, "defence": 90},
    {"name": "Vanguard",   "attack": 90, "defence": 84},
    {"name": "Sentinel",   "attack": 82, "defence": 86},
    {"name": "Comet",      "attack": 84, "defence": 78},
    {"name": "Falcon",     "attack": 78, "defence": 76},
    {"name": "Meridian",   "attack": 74, "defence": 72},
    {"name": "Harbor",     "attack": 70, "defence": 74},
    {"name": "Ironclad",   "attack": 66, "defence": 70},
    {"name": "Crest",      "attack": 68, "defence": 64},
    {"name": "Anchor",     "attack": 62, "defence": 66},
    {"name": "Union",      "attack": 60, "defence": 60},
    {"name": "Fenwick",    "attack": 58, "defence": 56},
    {"name": "Redline",    "attack": 60, "defence": 52},
    {"name": "Solace",     "attack": 52, "defence": 58},
    {"name": "Driftwood",  "attack": 54, "defence": 50},
    {"name": "Northgate",  "attack": 48, "defence": 52},
    {"name": "Emberline",  "attack": 50, "defence": 44},
    {"name": "Lowtide",    "attack": 40, "defence": 42},
    {"name": "Thistle",    "attack": 34, "defence": 36},
    {"name": "Basecamp",   "attack": 26, "defence": 28},
]


def main():
    rng = random.Random(SEED)
    games_per_team = 2 * (len(CLUBS_38_GAME) - 1)
    assert games_per_team == 38, games_per_team

    summary = league_sim.monte_carlo_league(CLUBS_38_GAME, SEASONS, rng)

    print(f"Monte Carlo 38-game season, {len(CLUBS_38_GAME)} hypothetical teams of varying strength ({SEASONS} simulated seasons)")
    header = (
        f"{'#':<3}{'Team':<12}{'Rating':>8}{'Mean':>7}{'Median':>8}{'Min':>6}{'Max':>6}"
        f"{'Title%':>8}{'Top4%':>8}{'Bot3%':>8}"
    )
    print(header)
    print("-" * len(header))
    ratings = {c["name"]: (c["attack"] + c["defence"]) / 2 for c in CLUBS_38_GAME}
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
