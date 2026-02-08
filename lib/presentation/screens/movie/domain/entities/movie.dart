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
    this.episodes,
  });

  final List<Map<String, dynamic>>? episodes;

  Movie copyWith({
    int? id,
    String? title,
    String? originalTitle,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    int? voteCount,
    String? releaseDate,
    List<int>? genreIds,
    double? popularity,
    bool? adult,
    String? originalLanguage,
    String? mediaType,
    List<Map<String, dynamic>>? episodes,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      releaseDate: releaseDate ?? this.releaseDate,
      genreIds: genreIds ?? this.genreIds,
      popularity: popularity ?? this.popularity,
      adult: adult ?? this.adult,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      mediaType: mediaType ?? this.mediaType,
      episodes: episodes ?? this.episodes,
    );
  }

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
        episodes,
      ];
}
