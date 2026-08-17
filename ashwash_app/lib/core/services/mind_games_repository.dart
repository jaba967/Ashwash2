import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MindGamesRepository {
  static const String _keyBestScore = 'mind_games_best_score_';
  static const String _keyLastScore = 'mind_games_last_score_';
  static const String _keyPlayCount = 'mind_games_play_count_';
  static const String _keyTotalTime = 'mind_games_total_time_';
  static const String _keyLastPlayed = 'mind_games_last_played_';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save Game Score locally & sync to Firebase Firestore
  Future<void> saveGameScore({
    required String gameId,
    required int score,
    required int durationSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Update Best Score
    int currentBest = prefs.getInt('$_keyBestScore$gameId') ?? 0;
    if (score > currentBest) {
      await prefs.setInt('$_keyBestScore$gameId', score);
    }

    // Save Last Score
    await prefs.setInt('$_keyLastScore$gameId', score);

    // Update Play Count
    int currentPlayCount = prefs.getInt('$_keyPlayCount$gameId') ?? 0;
    await prefs.setInt('$_keyPlayCount$gameId', currentPlayCount + 1);

    // Update Total Time Played
    int currentTotalTime = prefs.getInt('$_keyTotalTime$gameId') ?? 0;
    await prefs.setInt('$_keyTotalTime$gameId', currentTotalTime + durationSeconds);

    // Save Last Played Date
    await prefs.setString('$_keyLastPlayed$gameId', DateTime.now().toIso8601String());

    // Live Firebase Firestore Sync
    await _syncScoreToFirestore(
      gameId: gameId,
      score: score,
      durationSeconds: durationSeconds,
      bestScore: score > currentBest ? score : currentBest,
    );
  }

  // Get Best Score
  Future<int> getBestScore(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyBestScore$gameId') ?? 0;
  }

  // Get Game Stats
  Future<Map<String, dynamic>> getGameStats(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'bestScore': prefs.getInt('$_keyBestScore$gameId') ?? 0,
      'lastScore': prefs.getInt('$_keyLastScore$gameId') ?? 0,
      'playCount': prefs.getInt('$_keyPlayCount$gameId') ?? 0,
      'totalTimePlayed': prefs.getInt('$_keyTotalTime$gameId') ?? 0,
      'lastPlayedDate': prefs.getString('$_keyLastPlayed$gameId') ?? '',
    };
  }

  // Live Firebase Firestore Sync
  Future<void> _syncScoreToFirestore({
    required String gameId,
    required int score,
    required int durationSeconds,
    required int bestScore,
  }) async {
    try {
      final user = _auth.currentUser;
      final userId = user?.uid ?? 'guest_user';

      await _firestore.collection('game_scores').add({
        'userId': userId,
        'gameId': gameId,
        'score': score,
        'bestScore': bestScore,
        'durationSeconds': durationSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update User Aggregate Stats
      await _firestore.collection('users').doc(userId).set({
        'lastPlayedDate': DateTime.now().toIso8601String(),
        'totalGamePoints': FieldValue.increment(score),
      }, SetOptions(merge: true));
    } catch (e) {
      // Offline fallback handling gracefully
    }
  }
}
