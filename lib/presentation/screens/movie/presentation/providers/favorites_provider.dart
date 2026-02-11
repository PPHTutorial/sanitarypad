import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/movie.dart';
import '../../data/models/movie_model.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/constants/app_constants.dart';

/// Favorites provider (using Firestore for persistence)
final favoritesProviders =
    StateNotifierProvider<FavoritesNotifier, List<Movie>>((ref) {
  final user = ref.watch(currentUserProvider);
  return FavoritesNotifier(ref, user?.userId);
});

/// Check if movie is favorite provider
final isFavoriteProvider = Provider.family<bool, int>((ref, movieId) {
  final favorites = ref.watch(favoritesProviders);
  return favorites.any((movie) => movie.id == movieId);
});

/// Favorites notifier with Firestore integration
class FavoritesNotifier extends StateNotifier<List<Movie>> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FavoritesNotifier(Ref ref, this._userId) : super([]) {
    _loadFavorites();
  }

  CollectionReference get _favoritesCollection => _firestore
      .collection(AppConstants.collectionUsers)
      .doc(_userId)
      .collection(AppConstants.collectionMovieFavorites);

  Future<void> _loadFavorites() async {
    if (_userId == null) return;

    try {
      final snapshot = await _favoritesCollection.get();
      final movies = snapshot.docs.map((doc) {
        final model = MovieModel.fromJson(doc.data() as Map<String, dynamic>);
        return model.toEntity();
      }).toList();
      state = movies;
    } catch (e) {
      AppLogger.e('Error loading favorites: $e');
    }
  }

  /// Add to favorites
  Future<void> addFavorite(Movie movie) async {
    if (_userId == null) return;

    if (!state.any((m) => m.id == movie.id)) {
      state = [...state, movie];
      try {
        final model = MovieModel.fromEntity(movie);
        await _favoritesCollection.doc(movie.id.toString()).set(model.toJson());
        AppLogger.i('Added to favorites: ${movie.title}');
      } catch (e) {
        AppLogger.e('Error adding favorite: $e');
      }
    }
  }

  /// Remove from favorites
  Future<void> removeFavorite(int movieId) async {
    if (_userId == null) return;

    state = state.where((movie) => movie.id != movieId).toList();
    try {
      await _favoritesCollection.doc(movieId.toString()).delete();
      AppLogger.i('Removed from favorites: $movieId');
    } catch (e) {
      AppLogger.e('Error removing favorite: $e');
    }
  }

  /// Toggle favorite
  Future<void> toggleFavorite(Movie movie) async {
    final isFavorite = state.any((m) => m.id == movie.id);
    if (isFavorite) {
      await removeFavorite(movie.id);
    } else {
      await addFavorite(movie);
    }
  }

  /// Clear all favorites (local and remote)
  Future<void> clearAll() async {
    if (_userId == null) return;

    state = [];
    try {
      final snapshot = await _favoritesCollection.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      AppLogger.i('Cleared all favorites');
    } catch (e) {
      AppLogger.e('Error clearing favorites: $e');
    }
  }
}
