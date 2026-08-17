import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';

class GameScoreData {
  final int bestScore;
  final int lastScore;
  final int playCount;
  final int totalTimeSeconds;
  final String lastPlayedDate;

  GameScoreData({
    required this.bestScore,
    required this.lastScore,
    required this.playCount,
    required this.totalTimeSeconds,
    required this.lastPlayedDate,
  });

  Map<String, dynamic> toJson() => {
        'best_score': bestScore,
        'last_score': lastScore,
        'play_count': playCount,
        'total_time_seconds': totalTimeSeconds,
        'last_played_date': lastPlayedDate,
      };

  factory GameScoreData.fromJson(Map<String, dynamic> json) => GameScoreData(
        bestScore: json['best_score'] ?? 0,
        lastScore: json['last_score'] ?? 0,
        playCount: json['play_count'] ?? 0,
        totalTimeSeconds: json['total_time_seconds'] ?? 0,
        lastPlayedDate: json['last_played_date'] ?? 'Never',
      );
}

class GameScoreService {
  static const String _storagePrefix = 'ashwash_mind_game_';
  static int _lastSubmissionTimestamp = 0;

  /// Save game score locally and attempt async sync with Django backend repository
  static Future<GameScoreData> saveScore({
    required String gameId,
    required int score,
    required int durationSeconds,
  }) async {
    // 1. Validation to prevent invalid scores or rapid duplicate submission
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSubmissionTimestamp < 1500) {
      throw Exception('Duplicate score submission blocked.');
    }
    if (score < 0 || durationSeconds < 0 || durationSeconds > 7200) {
      throw Exception('Invalid game score or timing values.');
    }
    _lastSubmissionTimestamp = now;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_storagePrefix$gameId';
    final existingRaw = prefs.getString(key);

    GameScoreData currentData = existingRaw != null
        ? GameScoreData.fromJson(jsonDecode(existingRaw))
        : GameScoreData(bestScore: 0, lastScore: 0, playCount: 0, totalTimeSeconds: 0, lastPlayedDate: 'Never');

    final int newBest = score > currentData.bestScore ? score : currentData.bestScore;
    final int newPlayCount = currentData.playCount + 1;
    final int newTotalTime = currentData.totalTimeSeconds + durationSeconds;
    final String nowFormatted = _formatCurrentDate();

    final updatedData = GameScoreData(
      bestScore: newBest,
      lastScore: score,
      playCount: newPlayCount,
      totalTimeSeconds: newTotalTime,
      lastPlayedDate: nowFormatted,
    );

    // Save locally to SharedPreferences
    await prefs.setString(key, jsonEncode(updatedData.toJson()));

    // 2. Prepared Repository Service Layer for Django REST API Integration
    _syncScoreWithBackend(gameId, score, durationSeconds, newBest);

    return updatedData;
  }

  /// Retrieve local scores for a specific game
  static Future<GameScoreData> getGameData(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_storagePrefix$gameId';
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        return GameScoreData.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return GameScoreData(
      bestScore: 0,
      lastScore: 0,
      playCount: 0,
      totalTimeSeconds: 0,
      lastPlayedDate: 'Never',
    );
  }

  /// Async background method to sync scores with Django Backend API when available
  static Future<void> _syncScoreWithBackend(String gameId, int score, int durationSeconds, int bestScore) async {
    try {
      await ApiService.post(
        ApiEndpoints.gameScore,
        {
          'game_id': gameId,
          'score': score,
          'duration_seconds': durationSeconds,
          'best_score': bestScore,
        },
        requireAuth: true,
      );
    } catch (_) {
      // Backend not yet connected or offline: fails silently, local storage preserves all data safely
    }
  }

  static String _formatCurrentDate() {
    final dt = DateTime.now();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
