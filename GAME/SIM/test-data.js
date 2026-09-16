function findPlayer(name, squad) {
  const matches = playerRatingsMaster.filter(p => p.Player.includes(name));
  const player = squad ? matches.find(p => p.Squad === squad) : matches[0];
  if (!player) console.warn(`Could not find player: ${name}`);
  return player;
}

function convertToTeamStrengthFormat(realPlayer, slotSubPosition) {
  return {
    name: realPlayer.Player,
    finalRating: realPlayer.final_rating,
    trueSubPosition: realPlayer.sub_position,
    slotSubPosition: slotSubPosition
  };
}

const realXI = [
  convertToTeamStrengthFormat(findPlayer("Alisson"), "Goalkeeper"),
  convertToTeamStrengthFormat(findPlayer("van Dijk"), "Centre-Back"),
  convertToTeamStrengthFormat(findPlayer("Saliba"), "Centre-Back"),
  convertToTeamStrengthFormat(findPlayer("Alexander-Arnold"), "Right-Back"),
  convertToTeamStrengthFormat(findPlayer("Robertson"), "Left-Back"),
  convertToTeamStrengthFormat(findPlayer("Rodri", "Manchester City"), "Defensive Midfield"),
  convertToTeamStrengthFormat(findPlayer("Bellingham"), "Central Midfield"),
  convertToTeamStrengthFormat(findPlayer("degaard"), "Attacking Midfield"),
  convertToTeamStrengthFormat(findPlayer("Salah"), "Right Winger"),
  convertToTeamStrengthFormat(findPlayer("Haaland"), "Centre-Forward"),
  convertToTeamStrengthFormat(findPlayer("Vinicius"), "Left Winger")
];

console.log(realXI);
console.log(computeTeamStrength(realXI));