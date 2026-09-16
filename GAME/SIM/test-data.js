function convertToTeamStrengthFormat(realPlayer, slotSubPosition) {
  return {
    name: realPlayer.Player,
    finalRating: realPlayer.final_rating,
    trueSubPosition: realPlayer.sub_position,
    slotSubPosition: slotSubPosition
  };
}