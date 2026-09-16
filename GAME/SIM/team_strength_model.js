// team_strength.js
// ============================================================
// TEAM STRENGTH AGGREGATION
// ============================================================
// Takes an 11-player starting lineup (each player already has a
// cross-position-comparable final_rating from the R pipeline) and
// produces three squad-level numbers: attackScore, defenceScore,
// and overallScore. This same function runs for the user's drafted
// XI AND all 19 real PL opponents, so difficulty stays self-generated.
// ============================================================

// ------------------------------------------------------------
// 1. POSITION WEIGHT TABLE (attackPct + defencePct always = 100)
// ------------------------------------------------------------
// Single source of truth for "how attacking is this position" —
// everything downstream, including the fit penalty, derives from
// this table rather than any separately hand-authored data.
const POSITION_WEIGHTS = {
  GK:       { attackPct: 0,  defencePct: 100 },
  CB:       { attackPct: 5,  defencePct: 95 },
  FB:       { attackPct: 25, defencePct: 75 },
  CDM:      { attackPct: 20, defencePct: 80 },
  CM:       { attackPct: 50, defencePct: 50 },
  CAM:      { attackPct: 75, defencePct: 25 },
  WIDE_MID: { attackPct: 65, defencePct: 35 }, // Left/Right Midfield
  FWD:      { attackPct: 90, defencePct: 10 }, // Centre-Fwd, 2nd Striker, Wingers
};

// ------------------------------------------------------------
// 2. MAP YOUR DATA'S sub_position STRINGS TO A CATEGORY ABOVE
// ------------------------------------------------------------
// Same 13-label vocabulary as your R pipeline, used for BOTH a
// player's true position and whatever slot they're assigned to.
const SUB_POSITION_TO_CATEGORY = {
  "Goalkeeper": "GK",
  "Centre-Back": "CB",
  "Left-Back": "FB",
  "Right-Back": "FB",
  "Defensive Midfield": "CDM",
  "Central Midfield": "CM",
  "Attacking Midfield": "CAM",
  "Left Midfield": "WIDE_MID",
  "Right Midfield": "WIDE_MID",
  "Centre-Forward": "FWD",
  "Second Striker": "FWD",
  "Left Winger": "FWD",
  "Right Winger": "FWD",
};

function getCategory(subPosition) {
  const category = SUB_POSITION_TO_CATEGORY[subPosition];
  if (!category) throw new Error(`Unknown sub_position: "${subPosition}"`);
  return category;
}

// ------------------------------------------------------------
// 3. POSITION-FIT PENALTY (derived from the weight table, not a
//    manually-authored "similarity" map)
// ------------------------------------------------------------
// distance ranges 0 (exact match) to ~0.9 (GK played at FWD, the
// widest possible gap in the table). v1 uses a LINEAR penalty:
//   CM (50) at CDM (20): distance 0.30 -> multiplier 0.70 (mild)
//   CB (5) at FWD (90):  distance 0.85 -> multiplier 0.15 (brutal)
//
// TUNING NOTE: if linear ever feels too harsh/lenient, swap for:
//   const fitMultiplier = Math.pow(1 - distance, 1.5);
// which keeps close mismatches closer to full value while punishing
// big ones even more than linear does.
function getFitMultiplier(trueSubPosition, slotSubPosition) {
  const trueAttackPct = POSITION_WEIGHTS[getCategory(trueSubPosition)].attackPct;
  const slotAttackPct = POSITION_WEIGHTS[getCategory(slotSubPosition)].attackPct;
  const distance = Math.abs(trueAttackPct - slotAttackPct) / 100;
  return 1 - distance;
}

// ------------------------------------------------------------
// 4. STAR PLAYER LINE BOOST
// ------------------------------------------------------------
const STAR_THRESHOLD = 85;   // effective rating above this = "world class"
const STAR_MULTIPLIER = 0.3; // how much of the excess becomes bonus points

function getStarBonus(effectiveRating) {
  if (effectiveRating <= STAR_THRESHOLD) return 0;
  return (effectiveRating - STAR_THRESHOLD) * STAR_MULTIPLIER;
}

// ------------------------------------------------------------
// 5. MAIN AGGREGATION FUNCTION
// ------------------------------------------------------------
// starters: exactly 11 objects, one per player in the starting XI:
//   {
//     name: "Declan Rice",
//     finalRating: 91.4,                       // from the R pipeline
//     trueSubPosition: "Defensive Midfield",   // player's real position
//     slotSubPosition: "Central Midfield",     // where they're SLOTTED here
//   }
// Returns: { attackScore, defenceScore, overallScore }
function computeTeamStrength(starters) {
  if (starters.length !== 11) {
    throw new Error(`Expected exactly 11 starters, got ${starters.length}`);
  }

  let attackTotal = 0;
  let defenceTotal = 0;
  let bestAttack = { contribution: 0, effectiveRating: 0 };
  let bestDefence = { contribution: 0, effectiveRating: 0 };

  starters.forEach((player) => {
    const fitMultiplier = getFitMultiplier(player.trueSubPosition, player.slotSubPosition);
    const effectiveRating = player.finalRating * fitMultiplier;

    const { attackPct, defencePct } = POSITION_WEIGHTS[getCategory(player.slotSubPosition)];
    const attackContribution = effectiveRating * (attackPct / 100);
    const defenceContribution = effectiveRating * (defencePct / 100);

    attackTotal += attackContribution;
    defenceTotal += defenceContribution;

    if (attackContribution > bestAttack.contribution) {
      bestAttack = { contribution: attackContribution, effectiveRating };
    }
    if (defenceContribution > bestDefence.contribution) {
      bestDefence = { contribution: defenceContribution, effectiveRating };
    }
  });

  // Dividing by 11 (not by "how many attackers/defenders") is what
  // makes a back-3 formation lower defenceScore and raise attackScore
  // automatically — no formation-specific branching needed anywhere.
  let attackScore = attackTotal / 11;
  let defenceScore = defenceTotal / 11;

  attackScore += getStarBonus(bestAttack.effectiveRating);
  defenceScore += getStarBonus(bestDefence.effectiveRating);

  attackScore = Math.min(100, Math.round(attackScore * 10) / 10);
  defenceScore = Math.min(100, Math.round(defenceScore * 10) / 10);

  const overallScore = Math.round(((attackScore + defenceScore) / 2) * 10) / 10;

  return { attackScore, defenceScore, overallScore };
}