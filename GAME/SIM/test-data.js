function convertToTeamStrengthFormat(realPlayer, slotSubPosition) {
  return {
    name: realPlayer.Player,
    finalRating: realPlayer.final_rating,
    trueSubPosition: realPlayer.sub_position,
    slotSubPosition: slotSubPosition
  };
}



const salah = playerRatingsMaster.find(p => p.Player.includes("Salah"));

const realXI = [
  convertToTeamStrengthFormat(salah, "Right Winger")
];

console.log(realXI);