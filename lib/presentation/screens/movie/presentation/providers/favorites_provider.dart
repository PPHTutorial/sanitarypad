import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/movie.dart';

/// Favorites provider (simplified - no database for debugging)
final favoritesProviders = StateNotifierProvider<FavoritesNotifier, List<Movie>>((ref) {
  return FavoritesNotifier();
});

/// Check if movie is favorite provider
final isFavoriteProvider = Provider.family<bool, int>((ref, movieId) {
  final favorites = ref.watch(favoritesProviders);
  return favorites.any((movie) => movie.id == movieId);
});

/// Favorites notifier (simplified - in-memory only for debugging)
class FavoritesNotifier extends StateNotifier<List<Movie>> {
  FavoritesNotifier() : super([]);
  
  /// Add to favorites
  void addFavorite(Movie movie) {
    if (!state.any((m) => m.id == movie.id)) {
      state = [...state, movie];
      AppLogger.i('Added to favorites: ${movie.title}');
    }
  }
  
  /// Remove from favorites
  void removeFavorite(int movieId) {
    state = state.where((movie) => movie.id != movieId).toList();
    AppLogger.i('Removed from favorites: $movieId');
  }
  
  /// Toggle favorite
  void toggleFavorite(Movie movie) {
      final isFavorite = state.any((m) => m.id == movie.id);
    if (isFavorite) {
      removeFavorite(movie.id);
    } else {
      addFavorite(movie);
    }
  }
  
  /// Check if movie is favorite
  bool isFavorite(int movieId) {
    return state.any((movie) => movie.id == movieId);
  }
  
  /// Clear all favorites
  void clearAll() {
    state = [];
    AppLogger.i('Cleared all favorites');
  }
  
  /// Get favorites count
  int get count => state.length;
}

