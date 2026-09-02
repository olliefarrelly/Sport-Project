"""Calibration constants for the rating -> xG conversion.

Tuned against the Phase 1 sanity check in sanity_check.py:
elite (City-strength) squads should average ~85-100 points across many
simulated seasons, relegation-strength squads should land in the 20s-30s.
Retune these, not the engine logic, if a future data pass shifts the
distribution.
"""

BASELINE_GOALS = 1.35   # roughly PL average goals/team/game
HOME_ADV = 1.10
AWAY_PEN = 0.92
RATING_POWER = 1.35     # exponent on the attack/defence ratio; amplifies rating gaps
XG_FLOOR = 0.15
XG_CEIL = 5.0
