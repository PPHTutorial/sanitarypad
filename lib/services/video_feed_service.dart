import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/nutrition_models.dart';
import '../models/workout_models.dart';

/// Provider for VideoFeedService
final videoFeedServiceProvider = Provider<VideoFeedService>((ref) {
  return VideoFeedService();
});

/// Video categories for workout content
enum VideoCategory {
  workout,
  yoga,
  cardio,
  strength,
  hiit,
  pilates,
  nutrition,
  recipe,
  healthyEating,
  mealPrep,
  meditation,
  stretching,
  mobility,
  weightLoss,
  muscleBuilding,
  wellness,
  skincare,
}

extension VideoCategoryExtension on VideoCategory {
  String get searchQuery {
    switch (this) {
      case VideoCategory.workout:
        return 'home workout for women';
      case VideoCategory.yoga:
        return 'yoga for beginners women';
      case VideoCategory.cardio:
        return 'cardio workout at home';
      case VideoCategory.strength:
        return 'strength training for women';
      case VideoCategory.hiit:
        return 'hiit workout for women';
      case VideoCategory.pilates:
        return 'pilates workout';
      case VideoCategory.nutrition:
        return 'women nutrition health tips';
      case VideoCategory.recipe:
        return 'healthy recipes weight loss';
      case VideoCategory.healthyEating:
        return 'healthy eating habits';
      case VideoCategory.mealPrep:
        return 'meal prep for weight loss';
      case VideoCategory.meditation:
        return 'meditation for stress relief';
      case VideoCategory.stretching:
        return 'stretching exercises';
      case VideoCategory.mobility:
        return 'mobility exercises';
      case VideoCategory.weightLoss:
        return 'weight loss exercises';
      case VideoCategory.muscleBuilding:
        return 'muscle building exercises';
      case VideoCategory.wellness:
        return 'wellness exercises';
      case VideoCategory.skincare:
        return 'dermatologist skincare routine tips';
    }
  }

  String get displayName {
    switch (this) {
      case VideoCategory.workout:
        return 'Workouts';
      case VideoCategory.yoga:
        return 'Yoga';
      case VideoCategory.cardio:
        return 'Cardio';
      case VideoCategory.strength:
        return 'Strength';
      case VideoCategory.hiit:
        return 'HIIT';
      case VideoCategory.pilates:
        return 'Pilates';
      case VideoCategory.nutrition:
        return 'Nutrition';
      case VideoCategory.recipe:
        return 'Recipes';
      case VideoCategory.healthyEating:
        return 'Healthy Eating';
      case VideoCategory.mealPrep:
        return 'Meal Prep';
      case VideoCategory.meditation:
        return 'Meditation';
      case VideoCategory.stretching:
        return 'Stretching';
      case VideoCategory.mobility:
        return 'Mobility';
      case VideoCategory.weightLoss:
        return 'Weight Loss';
      case VideoCategory.muscleBuilding:
        return 'Muscle Building';
      case VideoCategory.wellness:
        return 'Wellness';
      case VideoCategory.skincare:
        return 'Skincare';
    }
  }
}

/// Video Feed Service - Uses serious_python with yt-dlp for YouTube metadata extraction
class VideoFeedService {
  bool _isInitialized = false;
  final _initCompleter = Completer<void>();

  final _yt = YoutubeExplode();

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      _initCompleter.complete();
      debugPrint('🐍 VideoFeedService: Native extraction initialized');
    } catch (e) {
      debugPrint('🐍 VideoFeedService initialization error: $e');
      _initCompleter.complete();
    }
  }

  /// Wait for initialization to complete
  Future<void> waitForInit() async {
    if (!_isInitialized) {
      await initialize();
    }
    await _initCompleter.future;
  }

  /// Search for workout videos
  Future<List<WorkoutVideo>> searchWorkoutVideos(
    String query, {
    int limit = 100,
    ExerciseCategory? category,
  }) async {
    try {
      await waitForInit();

      var searchResults = await _yt.search.search(query);
      final videos = <WorkoutVideo>[];

      while (videos.length < limit) {
        for (final video in searchResults) {
          if (videos.length >= limit) break;
          videos.add(WorkoutVideo(
            videoId: video.id.value,
            title: video.title,
            description: video.description,
            thumbnailUrl: video.thumbnails.highResUrl,
            duration: video.duration ?? Duration.zero,
            category: category ?? ExerciseCategory.other,
            difficulty: WorkoutDifficulty.beginner,
            channelName: video.author,
            viewCount: video.engagement.viewCount,
            isSaved: false,
            likes: video.engagement.likeCount,
          ));
        }

        if (videos.length >= limit) break;

        final nextPage = await searchResults.nextPage();
        if (nextPage == null || nextPage.isEmpty) break;
        searchResults = nextPage;
      }

      if (videos.isEmpty) {
        return _getFallbackWorkoutVideos(query, category);
      }

      return videos;
    } catch (e) {
      debugPrint('🐍 Search error: $e');
      return _getFallbackWorkoutVideos(query, category);
    }
  }

  /// Search for recipe videos
  Future<List<VideoMetadata>> searchRecipeVideos(String query,
      {int limit = 100}) async {
    try {
      await waitForInit();

      var searchResults = await _yt.search.search(query);
      final videos = <VideoMetadata>[];

      while (videos.length < limit) {
        for (final video in searchResults) {
          if (videos.length >= limit) break;
          videos.add(VideoMetadata(
            videoId: video.id.value,
            title: video.title,
            description: video.description,
            thumbnailUrl: video.thumbnails.highResUrl,
            duration: video.duration ?? Duration.zero,
            channelName: video.author,
            viewCount: video.engagement.viewCount,
            likes: video.engagement.likeCount,
          ));
        }

        if (videos.length >= limit) break;

        final nextPage = await searchResults.nextPage();
        if (nextPage == null || nextPage.isEmpty) break;
        searchResults = nextPage;
      }

      if (videos.isEmpty) {
        return _getFallbackRecipeVideos(query);
      }

      return videos;
    } catch (e) {
      debugPrint('🐍 Recipe search error: $e');
      return _getFallbackRecipeVideos(query);
    }
  }

  /// Get videos by category
  Future<List<WorkoutVideo>> getVideosByCategory(VideoCategory category,
      {int limit = 100}) async {
    final exerciseCategory = _mapToExerciseCategory(category);
    return searchWorkoutVideos(category.searchQuery,
        limit: limit, category: exerciseCategory);
  }

  /// Get nutrition videos by category
  Future<List<VideoMetadata>> getNutritionVideos(VideoCategory category,
      {int limit = 100}) async {
    return searchRecipeVideos(category.searchQuery, limit: limit);
  }

  /// Map video category to exercise category
  ExerciseCategory? _mapToExerciseCategory(VideoCategory category) {
    switch (category) {
      case VideoCategory.workout:
        return ExerciseCategory.other;
      case VideoCategory.yoga:
        return ExerciseCategory.yoga;
      case VideoCategory.cardio:
        return ExerciseCategory.cardio;
      case VideoCategory.strength:
        return ExerciseCategory.strength;
      case VideoCategory.hiit:
        return ExerciseCategory.hiit;
      case VideoCategory.pilates:
        return ExerciseCategory.pilates;
      case VideoCategory.skincare:
        return ExerciseCategory.skincare;
      case VideoCategory.wellness:
        return ExerciseCategory.other;
      default:
        return null;
    }
  }

  /// Fallback workout videos (curated list when yt-dlp fails)
  List<WorkoutVideo> _getFallbackWorkoutVideos(
      String query, ExerciseCategory? category) {
    // Return curated popular workout videos as fallback
    return [
      WorkoutVideo(
        videoId: 'gC_L9qAHVJ8',
        title: '30 Minute Full Body Workout - No Equipment',
        description: 'Complete home workout for all fitness levels',
        thumbnailUrl: 'https://img.youtube.com/vi/gC_L9qAHVJ8/hqdefault.jpg',
        duration: const Duration(minutes: 30),
        category: category ?? ExerciseCategory.cardio,
        difficulty: WorkoutDifficulty.beginner,
        channelName: 'MadFit',
        viewCount: 15000000,
        isSaved: false,
      ),
      WorkoutVideo(
        videoId: 'UItWltVZZmE',
        title: '20 Minute HIIT Workout - Fat Burning',
        description: 'High intensity interval training for maximum results',
        thumbnailUrl: 'https://img.youtube.com/vi/UItWltVZZmE/hqdefault.jpg',
        duration: const Duration(minutes: 20),
        category: category ?? ExerciseCategory.hiit,
        difficulty: WorkoutDifficulty.intermediate,
        channelName: 'Sydney Cummings',
        viewCount: 8000000,
        isSaved: false,
      ),
      WorkoutVideo(
        videoId: 'v7AYKMP6rOE',
        title: '10 Minute Morning Yoga for Beginners',
        description: 'Start your day with gentle yoga stretches',
        thumbnailUrl: 'https://img.youtube.com/vi/v7AYKMP6rOE/hqdefault.jpg',
        duration: const Duration(minutes: 10),
        category: category ?? ExerciseCategory.yoga,
        difficulty: WorkoutDifficulty.beginner,
        channelName: 'Yoga With Adriene',
        viewCount: 25000000,
        isSaved: false,
      ),
      WorkoutVideo(
        videoId: 'IT94xC35u6k',
        title: '15 Minute Ab Workout - Core Strengthening',
        description: 'Targeted ab exercises for a strong core',
        thumbnailUrl: 'https://img.youtube.com/vi/IT94xC35u6k/hqdefault.jpg',
        duration: const Duration(minutes: 15),
        category: category ?? ExerciseCategory.strength,
        difficulty: WorkoutDifficulty.intermediate,
        channelName: 'Blogilates',
        viewCount: 12000000,
        isSaved: false,
      ),
      WorkoutVideo(
        videoId: '2pLT-olgUJs',
        title: '30 Minute Pilates for Beginners',
        description: 'Full body pilates workout for flexibility and strength',
        thumbnailUrl: 'https://img.youtube.com/vi/2pLT-olgUJs/hqdefault.jpg',
        duration: const Duration(minutes: 30),
        category: category ?? ExerciseCategory.pilates,
        difficulty: WorkoutDifficulty.beginner,
        channelName: 'Move With Nicole',
        viewCount: 6000000,
        isSaved: false,
      ),
    ];
  }

  /// Fallback recipe videos
  List<VideoMetadata> _getFallbackRecipeVideos(String query) {
    return [
      const VideoMetadata(
        videoId: 'DnG9S9I0nBg',
        title: 'Easy Healthy Meal Prep for the Week',
        description: 'Simple and nutritious meals you can prep in advance',
        thumbnailUrl: 'https://img.youtube.com/vi/DnG9S9I0nBg/hqdefault.jpg',
        duration: Duration(minutes: 15),
        channelName: 'Pick Up Limes',
        viewCount: 5000000,
      ),
      const VideoMetadata(
        videoId: '7-LxNu6h76w',
        title: 'High Protein Breakfast Ideas',
        description:
            'Start your day with these protein-packed breakfast recipes',
        thumbnailUrl: 'https://img.youtube.com/vi/7-LxNu6h76w/hqdefault.jpg',
        duration: Duration(minutes: 12),
        channelName: 'The Domestic Geek',
        viewCount: 3000000,
      ),
      const VideoMetadata(
        videoId: 'XeqCP-gVGnM',
        title: 'Healthy Smoothie Recipes for Weight Loss',
        description: 'Delicious smoothies that help you stay on track',
        thumbnailUrl: 'https://img.youtube.com/vi/XeqCP-gVGnM/hqdefault.jpg',
        duration: Duration(minutes: 8),
        channelName: 'Downshiftology',
        viewCount: 4000000,
      ),
      const VideoMetadata(
        videoId: 'Pn0VY31JKkU',
        title: 'Quick Healthy Dinner Recipes',
        description: 'Healthy dinners you can make in 30 minutes or less',
        thumbnailUrl: 'https://img.youtube.com/vi/Pn0VY31JKkU/hqdefault.jpg',
        duration: Duration(minutes: 18),
        channelName: 'Fit Men Cook',
        viewCount: 2500000,
      ),
      const VideoMetadata(
        videoId: 'o-c2gVrRwY0',
        title: 'Low Carb Meal Ideas',
        description: 'Satisfying low carb meals for your health goals',
        thumbnailUrl: 'https://img.youtube.com/vi/o-c2gVrRwY0/hqdefault.jpg',
        duration: Duration(minutes: 14),
        channelName: 'Diet Doctor',
        viewCount: 1800000,
      ),
    ];
  }

  /// Dispose resources
  void dispose() {
    _yt.close();
    _isInitialized = false;
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider for workout videos by category
final workoutVideosByCategoryProvider =
    FutureProvider.family<List<WorkoutVideo>, VideoCategory>(
        (ref, category) async {
  final service = ref.watch(videoFeedServiceProvider);
  return service.getVideosByCategory(category);
});

/// Provider for nutrition videos by category
final nutritionVideosByCategoryProvider =
    FutureProvider.family<List<VideoMetadata>, VideoCategory>(
        (ref, category) async {
  final service = ref.watch(videoFeedServiceProvider);
  return service.getNutritionVideos(category);
});

/// Provider for searching workout videos
final workoutVideoSearchProvider =
    FutureProvider.family<List<WorkoutVideo>, String>((ref, query) async {
  final service = ref.watch(videoFeedServiceProvider);
  return service.searchWorkoutVideos(query);
});

/// Provider for searching recipe videos
final recipeVideoSearchProvider =
    FutureProvider.family<List<VideoMetadata>, String>((ref, query) async {
  final service = ref.watch(videoFeedServiceProvider);
  return service.searchRecipeVideos(query);
});
