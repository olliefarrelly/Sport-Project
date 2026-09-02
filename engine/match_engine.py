"""Expected-goals formula and Poisson scoreline sampling.

Stdlib-only (no numpy) so the engine has zero setup friction while it's
still running on dummy data.
"""

import math
import random

from . import config


def expected_goals(attack, opp_defence, venue_multiplier):
    ratio = (attack / opp_defence) ** config.RATING_POWER
    xg = config.BASELINE_GOALS * ratio * venue_multiplier
    return max(config.XG_FLOOR, min(xg, config.XG_CEIL))


def sample_poisson(lam, rng):
    """Knuth's algorithm: draw one sample from Poisson(lam)."""
    limit = math.exp(-lam)
    k = 0
    p = 1.0
    while True:
        k += 1
        p *= rng.random()
        if p <= limit:
            return k - 1


def simulate_match(home, away, rng=random):
    home_xg = expected_goals(home["attack"], away["defence"], config.HOME_ADV)
    away_xg = expected_goals(away["attack"], home["defence"], config.AWAY_PEN)
    return {
        "home_goals": sample_poisson(home_xg, rng),
        "away_goals": sample_poisson(away_xg, rng),
    }


def points_from_result(goals_for, goals_against):
    if goals_for > goals_against:
        return 3
    if goals_for == goals_against:
        return 1
    return 0
