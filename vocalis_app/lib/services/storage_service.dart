import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_stats.dart';

class StorageService {
  static const _kStatsKey = 'vocalis_stats_v1';
  static const _kCustomPhrasesKey = 'vocalis_custom_phrases_v1';
  static const _kLastPracticeDateKey = 'vocalis_last_practice_date';
  static const _kAttemptsKey = 'vocalis_attempts_v1';
  static const int _maxAttempts = 100;

  Future<UserStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kStatsKey);
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UserStats.fromJson(map);
      } catch (_) {}
    }
    return UserStats();
  }

  Future<void> saveStats(UserStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStatsKey, jsonEncode(stats.toJson()));
  }

  Future<List<String>> loadCustomPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kCustomPhrasesKey) ?? [];
  }

  Future<void> saveCustomPhrase(String phrase) async {
    final phrases = await loadCustomPhrases();
    if (!phrases.contains(phrase)) {
      phrases.insert(0, phrase);
      if (phrases.length > 20) {
        phrases.removeLast();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kCustomPhrasesKey, phrases);
    }
  }

  Future<void> removeCustomPhrase(String phrase) async {
    final phrases = await loadCustomPhrases();
    phrases.remove(phrase);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kCustomPhrasesKey, phrases);
  }

  Future<List<AttemptRecord>> loadAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kAttemptsKey);
    if (list == null) return [];

    final attempts = <AttemptRecord>[];
    for (final item in list) {
      try {
        attempts.add(AttemptRecord.fromJson(jsonDecode(item)));
      } catch (_) {}
    }
    return attempts;
  }

  Future<void> recordPracticeSession(
    double score, {
    String exerciseId = '',
    List<String> weakWords = const [],
    List<String> weakPhonemes = const [],
  }) async {
    final stats = await loadStats();
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_kLastPracticeDateKey);

    if (lastDate != today) {
      stats.sentencesToday = 1;
      stats.streakDays += 1;
      await prefs.setString(_kLastPracticeDateKey, today);
    } else {
      stats.sentencesToday += 1;
    }

    if (stats.accuracyAvg == 0) {
      stats.accuracyAvg = score;
    } else {
      stats.accuracyAvg = ((stats.accuracyAvg * 4) + score) / 5;
    }
    stats.practiceMinutes += 2;

    // Save attempt record
    final attempts = await loadAttempts();
    final newAttempt = AttemptRecord(
      exerciseId: exerciseId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      overallScore: score,
      weakWords: weakWords,
      weakPhonemes: weakPhonemes,
    );

    attempts.insert(0, newAttempt);
    if (attempts.length > _maxAttempts) {
      attempts.removeRange(_maxAttempts, attempts.length);
    }

    final rawJsonList =
        attempts.map((a) => jsonEncode(a.toJson())).toList(growable: false);
    await prefs.setStringList(_kAttemptsKey, rawJsonList);

    await saveStats(stats);
  }

  Future<ReviewRecommendation> getReviewRecommendation() async {
    final attempts = await loadAttempts();
    if (attempts.isEmpty) {
      return const ReviewRecommendation(hasData: false);
    }

    final wordFrequency = <String, int>{};
    final wordExerciseMap = <String, String>{};
    final phonemeFrequency = <String, int>{};

    for (final attempt in attempts) {
      for (final rawWord in attempt.weakWords) {
        final clean = rawWord.toLowerCase().replaceAll(RegExp(r"[^a-z0-9']"), '');
        if (clean.isNotEmpty) {
          wordFrequency[clean] = (wordFrequency[clean] ?? 0) + 1;
          if (attempt.exerciseId.isNotEmpty) {
            wordExerciseMap[clean] = attempt.exerciseId;
          }
        }
      }

      for (final ph in attempt.weakPhonemes) {
        if (ph.isNotEmpty) {
          phonemeFrequency[ph] = (phonemeFrequency[ph] ?? 0) + 1;
        }
      }
    }

    if (wordFrequency.isEmpty && phonemeFrequency.isEmpty) {
      return const ReviewRecommendation(hasData: true);
    }

    String? topWord;
    int topWordCount = 0;
    for (final entry in wordFrequency.entries) {
      if (entry.value > topWordCount) {
        topWordCount = entry.value;
        topWord = entry.key;
      }
    }

    String? topPhoneme;
    int topPhonemeCount = 0;
    for (final entry in phonemeFrequency.entries) {
      if (entry.value > topPhonemeCount) {
        topPhonemeCount = entry.value;
        topPhoneme = entry.key;
      }
    }

    return ReviewRecommendation(
      hasData: true,
      reviewWord: topWord,
      count: topWordCount,
      reviewPhoneme: topPhoneme,
      targetExerciseId: topWord != null ? wordExerciseMap[topWord] : null,
    );
  }
}
