"""
100pts — Phase 1: Match Engine Prototype (Python port)

Goal: confirm the rating -> xG -> Poisson pipeline produces believable
points totals before any real data is added. Dummy ratings only.
"""

import random
import numpy as np

# ---------- CONFIG ----------
SEASONS_PER_TIER = 2000
BASELINE_GOALS = 1.35   # roughly PL avg goals/team/game
HOME_ADV = 1.10
AWAY_PEN = 0.92
AVG_RATING = 60          # league-average attack/defence rating (unused directly yet,
                          # kept for when we normalise against real data later)

random.seed(24014423)    # reproducible runs — change/remove once you're happy with tuning


# ---------- OPPONENT POOL ----------
def tier_block(label, count, lo, hi):
    return [
        {
            "name": f"{label}-{i+1}",
            "attack": random.randint(lo, hi),
            "defence": random.randint(lo, hi),
        }
        for i in range(count)
    ]


def build_opponents():
    # 19 dummy opponents, roughly mirroring PL table shape
    return (
        tier_block("Strong", 5, 78, 88)
        + tier_block("Mid", 9, 50, 65)
        + tier_block("Weak", 5, 30, 42)
    )


# ---------- CORE ENGINE ----------
def aggregate_squad(attack, defence):
    """
    Placeholder for Phase 1: squad-level attack/defence passed in directly.
    Phase 2+ will replace this with position-weighted aggregation from
    individual player ratings.
    """
    return {"attack": attack, "defence": defence}


def expected_goals(attack, opp_defence, venue_multiplier):
    xg = BASELINE_GOALS * (attack / opp_defence) * venue_multiplier
    return max(0.15, min(xg, 5.0))  # clamp to sane bounds


def simulate_match(home, away):
    home_xg = expected_goals(home["attack"], away["defence"], HOME_ADV)
    away_xg = expected_goals(away["attack"], home["defence"], AWAY_PEN)
    return {
        "home_goals": np.random.poisson(home_xg),
        "away_goals": np.random.poisson(away_xg),
    }


def points_from_result(goals_for, goals_against):
    if goals_for > goals_against:
        return 3
    if goals_for == goals_against:
        return 1
    return 0


def simulate_season(squad, opponents):
    points = 0
    for opp in opponents:
        # home leg
        r = simulate_match(squad, opp)
        points += points_from_result(r["home_goals"], r["away_goals"])
        # away leg (squad plays away this time)
        r = simulate_match(opp, squad)
        points += points_from_result(r["away_goals"], r["home_goals"])
    return points


def monte_carlo(squad, opponents, n):
    results = np.array([simulate_season(squad, opponents) for _ in range(n)])
    return {
        "mean": results.mean(),
        "median": np.median(results),
        "min": results.min(),
        "max": results.max(),
        "p90": np.percentile(results, 90),
        "p95": np.percentile(results, 95),
        "p99": np.percentile(results, 99),
        "pct_100plus": (results >= 100).mean() * 100,
        "raw": results,  # keep raw array around in case you want to plot/inspect further
    }


# ---------- TEST SQUADS ----------
TEST_SQUADS = [
    ("City-strength (elite)", aggregate_squad(90, 88)),
    ("Mid-table strength", aggregate_squad(58, 58)),
    ("Relegation-strength", aggregate_squad(34, 36)),
]


# ---------- RUN ----------
def main():
    opponents = build_opponents()

    print("Opponent pool (19 dummy PL clubs)")
    print(f"{'Name':<12}{'Attack':>8}{'Defence':>9}")
    for o in opponents:
        print(f"{o['name']:<12}{o['attack']:>8}{o['defence']:>9}")

    print(f"\nMonte Carlo results ({SEASONS_PER_TIER} simulated seasons each)")
    header = f"{'Squad':<24}{'Mean':>7}{'Median':>8}{'Min':>6}{'Max':>6}{'P90':>6}{'P95':>6}{'P99':>6}{'%>=100':>9}"
    print(header)
    print("-" * len(header))
    for label, squad in TEST_SQUADS:
        stats = monte_carlo(squad, opponents, SEASONS_PER_TIER)
        print(
            f"{label:<24}"
            f"{stats['mean']:>7.1f}"
            f"{stats['median']:>8.0f}"
            f"{stats['min']:>6.0f}"
            f"{stats['max']:>6.0f}"
            f"{stats['p90']:>6.0f}"
            f"{stats['p95']:>6.0f}"
            f"{stats['p99']:>6.0f}"
            f"{stats['pct_100plus']:>8.2f}%"
        )


if __name__ == "__main__":
    main()