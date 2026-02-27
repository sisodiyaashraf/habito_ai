class HiveMember {
  final String id;
  final String displayName;
  final String avatarUrl;
  final double syncRate; // 0.0 to 1.0 (today's completion %)
  final bool isOnline;
  final int contributionXP;
  final String lastSyncedProtocol;

  HiveMember({
    required this.id,
    required this.displayName,
    this.avatarUrl = "",
    this.syncRate = 0.0,
    this.isOnline = false,
    this.contributionXP = 0,
    this.lastSyncedProtocol = "Waiting for Uplink...",
  });

  // FIX: Added getter to resolve 'name' not defined error in HiveScreen
  String get name => displayName;

  // Helper for UI to display formatted sync percentage
  String get syncPercentage => "${(syncRate * 100).toInt()}%";

  // Tactical status text for the Hive Terminal
  String get statusText => isOnline ? "UPLINKED" : "OFFLINE";
}
