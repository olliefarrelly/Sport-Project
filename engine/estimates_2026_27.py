"""Hand-estimated club strength ratings for the 2026-27 Premier League season.

NOT the output of the FBref/Transfermarkt pipeline (that's Phase 2/3 work,
see schema/types.md) - these are placeholder attack/defence ratings on the
same 0-100ish scale as engine/sanity_check.py's dummy tiers, built from:

  - final 2025-26 Premier League points as a proxy for underlying squad
    quality entering the new season (source: statsmagazine.co.uk final
    table, cross-checked against Yahoo Sports / NBC Sports coverage)
  - the three promoted sides (Coventry City, Ipswich Town, Hull City)
    placed below the weakest surviving 2025-26 side, per typical
    newly-promoted PL form
  - a small attack/defence split around each club's base rating from
    general team style/reputation, since goals-for/against splits weren't
    available for most mid-table clubs in the source table

Caveat: this does NOT account for 2026 summer transfer window business
(the window closes after this file's knowledge cutoff) - treat these as a
rough prior for exercising the engine, not a researched rating. Real
ratings arrive once the Phase 2 pipeline is built.
"""

CLUBS_2026_27 = [
    # name, attack, defence           # 2025-26 finish (pts) or promoted
    {"name": "Arsenal",           "attack": 88, "defence": 92},  # 1st, 85 pts
    {"name": "Manchester City",   "attack": 88, "defence": 80},  # 2nd, 78 pts
    {"name": "Manchester United", "attack": 78, "defence": 76},  # 3rd, 71 pts
    {"name": "Aston Villa",       "attack": 70, "defence": 74},  # 4th, 65 pts
    {"name": "Liverpool",         "attack": 72, "defence": 62},  # 5th, 60 pts
    {"name": "Bournemouth",       "attack": 60, "defence": 68},  # 6th, 57 pts
    {"name": "Sunderland",        "attack": 60, "defence": 62},  # 7th, 54 pts
    {"name": "Brighton",          "attack": 64, "defence": 56},  # 8th, 53 pts
    {"name": "Brentford",         "attack": 60, "defence": 60},  # 9th, 53 pts
    {"name": "Chelsea",           "attack": 64, "defence": 54},  # 10th, 52 pts
    {"name": "Fulham",            "attack": 58, "defence": 60},  # 11th, 52 pts
    {"name": "Newcastle United",  "attack": 58, "defence": 56},  # 12th, 49 pts
    {"name": "Everton",           "attack": 50, "defence": 64},  # 13th, 49 pts
    {"name": "Leeds United",      "attack": 54, "defence": 56},  # 14th, 47 pts
    {"name": "Crystal Palace",    "attack": 48, "defence": 58},  # 15th, 45 pts
    {"name": "Nottingham Forest", "attack": 52, "defence": 52},  # 16th, 44 pts
    {"name": "Tottenham Hotspur", "attack": 56, "defence": 42},  # 17th, 41 pts
    {"name": "Ipswich Town",      "attack": 38, "defence": 42},  # promoted
    {"name": "Coventry City",     "attack": 36, "defence": 38},  # promoted
    {"name": "Hull City",         "attack": 34, "defence": 36},  # promoted
]
