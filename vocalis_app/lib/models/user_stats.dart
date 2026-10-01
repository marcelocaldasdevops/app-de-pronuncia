class UserStats {
  int streakDays;
  int sentencesToday;
  double accuracyAvg;
  int practiceMinutes;
  String reviewWord;
  String reviewPhoneme;

  UserStats({
    this.streakDays = 0,
    this.sentencesToday = 0,
    this.accuracyAvg = 0.0,
    this.practiceMinutes = 0,
    this.reviewWord = '',
    this.reviewPhoneme = '',
  });

  Map<String, dynamic> toJson() => {
        'streakDays': streakDays,
        'sentencesToday': sentencesToday,
        'accuracyAvg': accuracyAvg,
        'practiceMinutes': practiceMinutes,
        'reviewWord': reviewWord,
        'reviewPhoneme': reviewPhoneme,
      };

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      streakDays: json['streakDays'] as int? ?? 0,
      sentencesToday: json['sentencesToday'] as int? ?? 0,
      accuracyAvg: (json['accuracyAvg'] as num?)?.toDouble() ?? 0.0,
      practiceMinutes: json['practiceMinutes'] as int? ?? 0,
      reviewWord: json['reviewWord'] as String? ?? '',
      reviewPhoneme: json['reviewPhoneme'] as String? ?? '',
    );
  }
}

class AttemptRecord {
  final String exerciseId;
  final int timestamp;
  final double overallScore;
  final List<String> weakWords;
  final List<String> weakPhonemes;

  const AttemptRecord({
    required this.exerciseId,
    required this.timestamp,
    required this.overallScore,
    this.weakWords = const [],
    this.weakPhonemes = const [],
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'timestamp': timestamp,
        'overallScore': overallScore,
        'weakWords': weakWords,
        'weakPhonemes': weakPhonemes,
      };

  factory AttemptRecord.fromJson(Map<String, dynamic> json) => AttemptRecord(
        exerciseId: json['exerciseId'] as String? ?? '',
        timestamp: json['timestamp'] as int? ?? 0,
        overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
        weakWords: (json['weakWords'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        weakPhonemes: (json['weakPhonemes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

class ReviewRecommendation {
  final bool hasData;
  final String? reviewWord;
  final String? reviewPhoneme;
  final int count;
  final String? targetExerciseId;

  const ReviewRecommendation({
    required this.hasData,
    this.reviewWord,
    this.reviewPhoneme,
    this.count = 0,
    this.targetExerciseId,
  });
}
