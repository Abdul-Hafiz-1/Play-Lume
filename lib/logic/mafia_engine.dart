class MafiaSession {
  final List<String> allPlayers;
  final Map<String, String> roles;
  Set<String> deceased = {};
  
  // Round-specific actions
  String? lastMafiaTarget;
  String? lastDoctorTarget;
  String? lastDetectiveTarget;
  bool doctorHasSelfSaved = false;

  MafiaSession({required this.allPlayers, required this.roles});

  // Dynamically filter survivors so dead players don't show up in lists
  List<String> get survivors => allPlayers.where((p) => !deceased.contains(p)).toList();

  // 🏆 Game Over Check: Mafia wins if they equal/outnumber town. Town wins if Mafia are gone.
  String? checkWinner() {
    int mafiaCount = survivors.where((p) => roles[p] == "MAFIA").length;
    int townCount = survivors.length - mafiaCount;
    if (mafiaCount == 0) return "TOWN";
    if (mafiaCount >= townCount) return "MAFIA";
    return null;
  }
}