class GlobalRank {
  final int position;
  final String username;
  final int level;
  final double disciplineIndex; // Score from 0-1000
  final bool isUser;

  GlobalRank({
    required this.position,
    required this.username,
    required this.level,
    required this.disciplineIndex,
    this.isUser = false,
  });
}
