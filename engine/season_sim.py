"""38-game season simulation (home + away vs. 19 opponents) and Monte Carlo
across many simulated seasons.
"""

import random
import statistics

from . import match_engine


def tier_block(label, count, lo, hi, rng):
    return [
        {
            "name": f"{label}-{i + 1}",
            "attack": rng.randint(lo, hi),
            "defence": rng.randint(lo, hi),
        }
        for i in range(count)
    ]


def build_dummy_opponents(rng=random):
    """19 dummy PL-shaped opponents, roughly mirroring the real table shape:
    5 strong / 9 mid / 5 weak. Phase 3 swaps this for the real 19 clubs.
    """
    return (
        tier_block("Strong", 5, 78, 88, rng)
        + tier_block("Mid", 9, 50, 65, rng)
        + tier_block("Weak", 5, 30, 42, rng)
    )


def simulate_season(squad, opponents, rng=random):
    points = 0
    for opp in opponents:
        r = match_engine.simulate_match(squad, opp, rng)
        points += match_engine.points_from_result(r["home_goals"], r["away_goals"])
        r = match_engine.simulate_match(opp, squad, rng)
        points += match_engine.points_from_result(r["away_goals"], r["home_goals"])
    return points


def monte_carlo(squad, opponents, n, rng=random):
    results = sorted(simulate_season(squad, opponents, rng) for _ in range(n))

    def percentile(p):
        idx = min(len(results) - 1, int(len(results) * p))
        return results[idx]

    return {
        "mean": statistics.mean(results),
        "median": statistics.median(results),
        "min": results[0],
        "max": results[-1],
        "p90": percentile(0.90),
        "p95": percentile(0.95),
        "p99": percentile(0.99),
        "pct_100plus": sum(1 for r in results if r >= 100) / len(results) * 100,
    }
