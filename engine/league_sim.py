"""Full round-robin league simulation (every club plays every other club
home and away) and Monte Carlo across many simulated seasons.

This is the "predict the season" mode, distinct from season_sim.py's
one-drafted-squad-vs-19-opponents mode used by the game's Core Loop.
"""

import random
import statistics

from . import match_engine


def simulate_round_robin(clubs, rng=random):
    """One full season (each pair of clubs meets twice, home and away).
    Returns {club_name: points}.
    """
    table = {c["name"]: 0 for c in clubs}
    for i, home in enumerate(clubs):
        for away in clubs[i + 1:]:
            r = match_engine.simulate_match(home, away, rng)
            table[home["name"]] += match_engine.points_from_result(r["home_goals"], r["away_goals"])
            table[away["name"]] += match_engine.points_from_result(r["away_goals"], r["home_goals"])

            r = match_engine.simulate_match(away, home, rng)
            table[away["name"]] += match_engine.points_from_result(r["home_goals"], r["away_goals"])
            table[home["name"]] += match_engine.points_from_result(r["away_goals"], r["home_goals"])
    return table


def monte_carlo_league(clubs, n, rng=random):
    names = [c["name"] for c in clubs]
    points_by_club = {name: [] for name in names}
    title_count = {name: 0 for name in names}
    top4_count = {name: 0 for name in names}
    relegation_count = {name: 0 for name in names}

    for _ in range(n):
        table = simulate_round_robin(clubs, rng)
        ranked = sorted(table.items(), key=lambda kv: kv[1], reverse=True)
        for name, pts in table.items():
            points_by_club[name].append(pts)
        title_count[ranked[0][0]] += 1
        for name, _ in ranked[:4]:
            top4_count[name] += 1
        for name, _ in ranked[-3:]:
            relegation_count[name] += 1

    summary = []
    for c in clubs:
        name = c["name"]
        pts = sorted(points_by_club[name])
        summary.append({
            "name": name,
            "mean": statistics.mean(pts),
            "median": statistics.median(pts),
            "min": pts[0],
            "max": pts[-1],
            "title_pct": title_count[name] / n * 100,
            "top4_pct": top4_count[name] / n * 100,
            "relegation_pct": relegation_count[name] / n * 100,
        })
    summary.sort(key=lambda s: s["mean"], reverse=True)
    return summary
