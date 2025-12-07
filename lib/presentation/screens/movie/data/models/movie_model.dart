import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/movie.dart';

part 'movie_model.g.dart';

@HiveType(typeId: 0)
class MovieModel extends Equatable {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String? originalTitle;
  
  @HiveField(3)
  final String? overview;
  
  @HiveField(4)
  final String? posterPath;
  
  @HiveField(5)
  final String? backdropPath;
  
  @HiveField(6)
  final double voteAverage;
  
  @HiveField(7)
  final int voteCount;
  
  @HiveField(8)
  final String? releaseDate;
  
  @HiveField(9)
  final List<int>? genreIds;
  
  @HiveField(10)
  final double popularity;
  
  @HiveField(11)
  final bool adult;
  
  @HiveField(12)
  final String? originalLanguage;
  
  @HiveField(13)
  final String mediaType; // 'movie' or 'tv'
  
  const MovieModel({
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
  
  /// From JSON (TMDB API response)
  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      originalTitle: json['original_title'] as String? ?? json['original_name'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      releaseDate: json['release_date'] as String? ?? json['first_air_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      adult: json['adult'] as bool? ?? false,
      originalLanguage: json['original_language'] as String?,
      mediaType: json['media_type'] as String? ?? 'movie',
    );
  }
  
  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'original_title': originalTitle,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'release_date': releaseDate,
      'genre_ids': genreIds,
      'popularity': popularity,
      'adult': adult,
      'original_language': originalLanguage,
      'media_type': mediaType,
    };
  }
  
  /// Convert to domain entity
  Movie toEntity() {
    return Movie(
      id: id,
      title: title,
      originalTitle: originalTitle,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      voteCount: voteCount,
      releaseDate: releaseDate,
      genreIds: genreIds,
      popularity: popularity,
      adult: adult,
      originalLanguage: originalLanguage,
      mediaType: mediaType,
    );
  }
  
  /// From domain entity
  factory MovieModel.fromEntity(Movie movie) {
    return MovieModel(
      id: movie.id,
      title: movie.title,
      originalTitle: movie.originalTitle,
      overview: movie.overview,
      posterPath: movie.posterPath,
      backdropPath: movie.backdropPath,
      voteAverage: movie.voteAverage,
      voteCount: movie.voteCount,
      releaseDate: movie.releaseDate,
      genreIds: movie.genreIds,
      popularity: movie.popularity,
      adult: movie.adult,
      originalLanguage: movie.originalLanguage,
      mediaType: movie.mediaType,
    );
  }
  
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

