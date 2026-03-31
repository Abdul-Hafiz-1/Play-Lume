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
  // 1. Jester Win (Lynched during the day)
  if (jesterExiled) return "JESTER";

  int mafiaCount = survivors.where((p) => roles[p] == "MAFIA").length;
  int townCount = survivors.length - mafiaCount;

  // 2. Mafia Win (Mafia equals or outnumbers Town)
  if (mafiaCount >= townCount && townCount > 0) return "MAFIA"; 
  
  // 3. Town Win (All Mafia eliminated)
  if (mafiaCount == 0) return "TOWN";

  return null; // Game continues
}
}