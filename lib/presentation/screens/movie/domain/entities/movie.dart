import 'package:equatable/equatable.dart';

/// Movie domain entity
class Movie extends Equatable {
  final int id;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final List<int>? genreIds;
  final double popularity;
  final bool adult;
  final String? originalLanguage;
  final String mediaType;
  
  const Movie({
    required this.id,
    required this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    this.releaseDate,
    this.genreIds,
    required this.popularity,
    this.adult = false,
    this.originalLanguage,
    this.mediaType = 'movie',
  });
  
  /// Get release year
  int? get releaseYear {
    if (releaseDate == null) return null;
    try {
      return int.parse(releaseDate!.substring(0, 4));
    } catch (e) {
      return null;
    }
  }
  
  /// Get formatted rating (e.g., "8.5")
  String get formattedRating => voteAverage.toStringAsFixed(1);
  
  /// Check if has poster
  bool get hasPoster => posterPath != null && posterPath!.isNotEmpty;
  
  /// Check if has backdrop
  bool get hasBackdrop => backdropPath != null && backdropPath!.isNotEmpty;
  
  /// Check if has overview
  bool get hasOverview => overview != null && overview!.isNotEmpty;
  
  @override
  List<Object?> get props => [
        id,
        title,
        originalTitle,
        overview,
        posterPath,
        backdropPath,
        voteAverage,
        voteCount,
        releaseDate,
        genreIds,
        popularity,
        adult,
        originalLanguage,
        mediaType,
      ];
}

