class RankingUser {
  const RankingUser({
    required this.id,
    required this.nickname,
    required this.ecoPoint,
    required this.grade,
    required this.rank,
  });

  final String id;
  final String nickname;
  final int ecoPoint;
  final String grade;
  final int rank;

  factory RankingUser.fromJson(Map<String, dynamic> json) {
    return RankingUser(
      id: json['userId'] as String? ?? '',
      nickname: json['nickname'] as String? ?? 'ECO 유저',
      ecoPoint: _readInt(json['ecoPoint']),
      grade: json['grade'] as String? ?? 'Seed',
      rank: _readInt(json['rank']),
    );
  }
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}
