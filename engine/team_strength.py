"""Squad -> {attack, defence} aggregation.

Phase 1: squad-level ratings are supplied directly (dummy data), matching
the "Core Engine" step of Phase 1 in the build plan. Phase 2+ replaces this
with position-weighted aggregation from individual player performance
ratings, per README.md's "Team Strength -> Match Model" section (attackers
weight attack more, defenders weight defence more, plus the position-fit
penalty for out-of-position picks).
"""


def aggregate_squad(attack, defence):
    return {"attack": attack, "defence": defence}
