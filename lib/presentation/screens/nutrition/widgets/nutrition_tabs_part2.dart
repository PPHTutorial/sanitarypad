// Nutrition Tabs Part 2: Meals, Recipes, Goals, Insights tabs

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sanitarypad/core/theme/app_theme.dart';
import 'package:sanitarypad/models/nutrition_models.dart';
import 'package:sanitarypad/services/nutrition_service.dart';
import 'package:sanitarypad/services/video_feed_service.dart';
import 'package:sanitarypad/services/credit_manager.dart';
import 'package:sanitarypad/services/video_overlay_service.dart';

// ============================================================================
// MEALS TAB
// ============================================================================
class MealsTab extends ConsumerWidget {
  final String userId;
  final DateTime selectedDate;
  final VoidCallback onAddMeal;

  const MealsTab(
      {super.key, required this.userId,
      required this.selectedDate,
      required this.onAddMeal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(todayMealsProvider(userId));

    return mealsAsync.when(
      data: (meals) {
        if (meals.isEmpty) {
          return _EmptyMealsState(onAddMeal: onAddMeal);
        }

        final groupedMeals = <MealType, List<MealEntry>>{};
        for (final meal in meals) {
          groupedMeals.putIfAbsent(meal.type, () => []).add(meal);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...MealType.values.map((type) {
              final typeMeals = groupedMeals[type] ?? [];
              if (typeMeals.isEmpty) {
                return _EmptyMealSection(type: type, onAdd: onAddMeal);
              }
              return _MealSection(type: type, meals: typeMeals, userId: userId);
            }),
            const SizedBox(height: 80),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _EmptyMealsState extends StatelessWidget {
  final VoidCallback onAddMeal;
  const _EmptyMealsState({required this.onAddMeal});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FontAwesomeIcons.bowlFood, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No meals logged today',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: onAddMeal,
              icon: const Icon(Icons.add),
              label: const Text('Log Your First Meal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMealSection extends StatelessWidget {
  final MealType type;
  final VoidCallback onAdd;
  const _EmptyMealSection({required this.type, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.grey.withOpacity(0.2), style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Icon(type.icon, size: 24, color: AppTheme.primaryPink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(type.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _MealSection extends ConsumerWidget {
  final MealType type;
  final List<MealEntry> meals;
  final String userId;
  const _MealSection(
      {required this.type, required this.meals, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCals = meals.fold(0, (sum, m) => sum + m.calories);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(type.icon, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${meals.length} items',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$totalCals cal',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...meals.map((meal) => _MealItem(meal: meal, userId: userId)),
        ],
      ),
    );
  }
}

class _MealItem extends ConsumerWidget {
  final MealEntry meal;
  final String userId;
  const _MealItem({required this.meal, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final mealToDelete = meal;
        await ref.read(nutritionServiceProvider).deleteMeal(userId, meal.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${mealToDelete.name} deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await ref
                      .read(nutritionServiceProvider)
                      .restoreMeal(userId, mealToDelete);
                },
              ),
            ),
          );
        }
      },
      child: ListTile(
        title: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          'P: ${meal.protein.toInt()}g  C: ${meal.carbs.toInt()}g  F: ${meal.fat.toInt()}g',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text('${meal.calories} cal',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ============================================================================
// RECIPES TAB
// ============================================================================
class RecipesTab extends ConsumerStatefulWidget {
  final String userId;
  const RecipesTab({super.key, required this.userId});

  @override
  ConsumerState<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends ConsumerState<RecipesTab> {
  VideoCategory _selectedCategory = VideoCategory.recipe;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final creditManager = ref.read(creditManagerProvider);
      final hasCredits = await creditManager.requestCredit(
        context,
        ActionType.nutritionSearch,
      );

      if (hasCredits) {
        await creditManager.consumeCredits(ActionType.nutritionSearch);
        setState(() {
          _isSearching = true;
        });
      }
    } else {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedRecipesAsync = ref.watch(savedRecipesProvider(widget.userId));
    final videosAsync = _isSearching
        ? ref.watch(recipeVideoSearchProvider(_searchController.text))
        : ref.watch(nutritionVideosByCategoryProvider(_selectedCategory));

    return CustomScrollView(
      slivers: [
        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search recipes (e.g. Keto, Vegan, Smoothies)',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPink),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => _onSearch(),
              onChanged: (val) {
                if (val.isEmpty && _isSearching) {
                  setState(() => _isSearching = false);
                }
              },
            ),
          ),
        ),

        // Category Chips
        SliverToBoxAdapter(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                VideoCategory.recipe,
                VideoCategory.healthyEating,
                VideoCategory.mealPrep,
                VideoCategory.nutrition,
                VideoCategory.weightLoss,
              ]
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat.displayName),
                          selected: !_isSearching && _selectedCategory == cat,
                          onSelected: (_) {
                            _searchController.clear();
                            setState(() {
                              _selectedCategory = cat;
                              _isSearching = false;
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),

        // Saved Recipes Section
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Saved Recipes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        savedRecipesAsync.when(
          data: (recipes) {
            if (recipes.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(FontAwesomeIcons.bookmark,
                            color: Colors.grey, size: 32),
                        SizedBox(height: 8),
                        Text('No saved recipes yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recipes.length,
                  itemBuilder: (context, i) => _SavedRecipeCard(
                      recipe: recipes[i], userId: widget.userId),
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
        ),

        // Video Feed Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
                _isSearching
                    ? 'Search Results'
                    : '${_selectedCategory.displayName} Videos',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        videosAsync.when(
          data: (videos) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) =>
                  _RecipeVideoCard(video: videos[i], userId: widget.userId),
              childCount: videos.length,
            ),
          ),
          loading: () => const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator()))),
          error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading videos: $e'))),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _SavedRecipeCard extends ConsumerWidget {
  final Recipe recipe;
  final String userId;
  const _SavedRecipeCard({required this.recipe, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(recipe.thumbnailUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
            if (recipe.estimatedCalories != null)
              Text('${recipe.estimatedCalories} cal',
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _RecipeVideoCard extends ConsumerStatefulWidget {
  final VideoMetadata video;
  final String userId;
  const _RecipeVideoCard({required this.video, required this.userId});

  @override
  ConsumerState<_RecipeVideoCard> createState() => _RecipeVideoCardState();
}

class _RecipeVideoCardState extends ConsumerState<_RecipeVideoCard> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final saved = await ref
        .read(nutritionServiceProvider)
        .isRecipeSaved(widget.userId, widget.video.videoId);
    if (mounted) setState(() => _isSaved = saved);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _playVideo(context),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: widget.video.thumbnailUrl,
                width: 120,
                height: 100,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 120,
                  height: 80,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    if (widget.video.channelName != null)
                      Text(widget.video.channelName!,
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(_formatDuration(widget.video.duration),
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color:
                      _isSaved ? Theme.of(context).colorScheme.primary : null),
              onPressed: _toggleSave,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _playVideo(BuildContext context) async {
    final creditManager = ref.read(creditManagerProvider);
    final hasCredits = await creditManager.requestCredit(
      context,
      ActionType.videoWatch,
    );

    if (hasCredits) {
      await creditManager.consumeCredits(ActionType.videoWatch);
      if (context.mounted) {
        ref.read(videoOverlayProvider.notifier).playVideo(widget.video.videoId);
      }
    }
  }

  Future<void> _toggleSave() async {
    final service = ref.read(nutritionServiceProvider);
    if (_isSaved) {
      // Find and delete
      final recipes = await service.watchSavedRecipes(widget.userId).first;
      final saved = recipes
          .where((r) => r.youtubeVideoId == widget.video.videoId)
          .firstOrNull;
      if (saved != null) {
        await service.deleteRecipe(widget.userId, saved.id);
      }
    } else {
      await service.saveRecipe(
          widget.userId,
          Recipe(
            id: '',
            youtubeVideoId: widget.video.videoId,
            title: widget.video.title,
            description: widget.video.description,
            thumbnailUrl: widget.video.thumbnailUrl,
            duration: widget.video.duration,
            ingredients: const [],
            tags: const [],
            channelName: widget.video.channelName,
            savedAt: DateTime.now(),
          ));
    }
    setState(() => _isSaved = !_isSaved);
  }
}
