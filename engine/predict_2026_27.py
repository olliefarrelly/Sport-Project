"""Run the prediction engine on the current (2026-27) Premier League season.

Ratings are the hand-estimated placeholders in estimates_2026_27.py, not
real FBref/Transfermarkt pipeline output - see that file's docstring for
methodology and caveats.

Run: python3 -m engine.predict_2026_27
"""

import random

from . import league_sim
from .estimates_2026_27 import CLUBS_2026_27

SEASONS = 5000
SEED = 100100


def main():
    rng = random.Random(SEED)
    summary = league_sim.monte_carlo_league(CLUBS_2026_27, SEASONS, rng)

    print(f"Monte Carlo 2026-27 Premier League prediction ({SEASONS} simulated seasons)")
    header = (
        f"{'#':<3}{'Club':<20}{'Mean':>7}{'Median':>8}{'Min':>6}{'Max':>6}"
        f"{'Title%':>8}{'Top4%':>8}{'Releg%':>8}"
    )
    print(header)
    print("-" * len(header))
    for i, row in enumerate(summary, start=1):
        print(
            f"{i:<3}{row['name']:<20}"
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
