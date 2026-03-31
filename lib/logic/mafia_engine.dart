class MafiaSession {
  final List<String> allPlayers;
  final Map<String, String> roles;
  Set<String> deceased = {};
  
  // 📂 Persistent Detective Case Files
  Map<String, bool> detectiveIntel = {}; 
  
  // Round Actions
  Set<String> lastMafiaTargets = {}; // 🔫 Support for multiple killers
  String? lastDoctorTarget;
  String? lastDetectiveTarget;
  bool doctorHasSelfSaved = false;
  bool jesterExiled = false; 

  MafiaSession({required this.allPlayers, required this.roles});

  List<String> get survivors => allPlayers.where((p) => !deceased.contains(p)).toList();

  String? checkWinner() {
    if (jesterExiled) return "JESTER";
    int mafiaCount = survivors.where((p) => roles[p] == "MAFIA").length;
    int townCount = survivors.length - mafiaCount;
    if (mafiaCount == 0) return "TOWN";
    if (mafiaCount >= townCount) return "MAFIA";
    return null;
  }
}