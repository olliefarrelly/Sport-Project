"""Phase 1 sanity check (DOCS/100-centurion-challenge-build-plan.md).

Confirms the rating -> xG -> Poisson pipeline produces believable points
totals on dummy data, before any real data is added:
  - a City-strength (elite) squad should land ~85-100 points
  - a relegation-strength squad should land in the 20s-30s

Run: python3 -m engine.sanity_check
"""

import random

from . import season_sim, team_strength

SEASONS_PER_TIER = 2000
SEED = 24014423

TEST_SQUADS = [
    ("City-strength (elite)", team_strength.aggregate_squad(90, 88), (85, 100)),
    ("Mid-table strength", team_strength.aggregate_squad(58, 58), None),
    ("Relegation-strength", team_strength.aggregate_squad(34, 36), (20, 39)),
]


def main():
    rng = random.Random(SEED)
    opponents = season_sim.build_dummy_opponents(rng)

    print("Opponent pool (19 dummy PL clubs)")
    print(f"{'Name':<12}{'Attack':>8}{'Defence':>9}")
    for o in opponents:
        print(f"{o['name']:<12}{o['attack']:>8}{o['defence']:>9}")

    print(f"\nMonte Carlo results ({SEASONS_PER_TIER} simulated seasons each)")
    header = (
        f"{'Squad':<24}{'Mean':>7}{'Median':>8}{'Min':>6}{'Max':>6}"
        f"{'P90':>6}{'P95':>6}{'P99':>6}{'%>=100':>9}  Target check"
    )
    print(header)
    print("-" * len(header))

    all_pass = True
    for label, squad, target in TEST_SQUADS:
        stats = season_sim.monte_carlo(squad, opponents, SEASONS_PER_TIER, rng)
        if target:
            lo, hi = target
            ok = lo <= stats["mean"] <= hi
            all_pass = all_pass and ok
            check = f"PASS ({lo}-{hi})" if ok else f"FAIL (target {lo}-{hi})"
        else:
            check = "-"
        print(
            f"{label:<24}"
            f"{stats['mean']:>7.1f}"
            f"{stats['median']:>8.0f}"
            f"{stats['min']:>6.0f}"
            f"{stats['max']:>6.0f}"
            f"{stats['p90']:>6.0f}"
            f"{stats['p95']:>6.0f}"
            f"{stats['p99']:>6.0f}"
            f"{stats['pct_100plus']:>8.2f}%  {check}"
        )

    print("\nPhase 1 sanity check:", "PASS" if all_pass else "FAIL - tune engine/config.py")


if __name__ == "__main__":
    main()
