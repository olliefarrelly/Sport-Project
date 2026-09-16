const testXI = [
  { name: "GK Test",       finalRating: 78, trueSubPosition: "Goalkeeper",        slotSubPosition: "Goalkeeper" },
  { name: "CB Test 1",     finalRating: 82, trueSubPosition: "Centre-Back",       slotSubPosition: "Centre-Back" },
  { name: "CB Test 2",     finalRating: 75, trueSubPosition: "Centre-Back",       slotSubPosition: "Centre-Back" },
  { name: "LB Test",       finalRating: 70, trueSubPosition: "Left-Back",         slotSubPosition: "Left-Back" },
  { name: "RB Test",       finalRating: 73, trueSubPosition: "Right-Back",        slotSubPosition: "Right-Back" },
  { name: "CDM Test",      finalRating: 80, trueSubPosition: "Defensive Midfield",slotSubPosition: "Defensive Midfield" },
  { name: "CM Test",       finalRating: 76, trueSubPosition: "Central Midfield",  slotSubPosition: "Central Midfield" },
  { name: "CAM Test",      finalRating: 88, trueSubPosition: "Attacking Midfield",slotSubPosition: "Attacking Midfield" },
  { name: "Misfit Test",   finalRating: 85, trueSubPosition: "Centre-Back",       slotSubPosition: "Left Winger" },
  { name: "Star Forward",  finalRating: 96, trueSubPosition: "Centre-Forward",    slotSubPosition: "Centre-Forward" },
  { name: "RW Test",       finalRating: 72, trueSubPosition: "Right Winger",      slotSubPosition: "Right Winger" }
];

console.log(computeTeamStrength(testXI));