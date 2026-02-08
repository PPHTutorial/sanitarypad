import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanitarypad/models/workout_models.dart';
import 'package:sanitarypad/services/workout_service.dart';
import 'package:sanitarypad/core/theme/app_theme.dart';

class WorkoutChallengesScreen extends ConsumerWidget {
  final String userId;

  const WorkoutChallengesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(workoutChallengesProvider);
    final joinedIdsAsync = ref.watch(joinedChallengeIdsProvider(userId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Workout Challenges',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: challengesAsync.when(
        data: (challenges) => joinedIdsAsync.when(
          data: (joinedIds) =>
              _buildChallengesList(context, ref, challenges, joinedIds),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildChallengesList(BuildContext context, WidgetRef ref,
      List<WorkoutChallenge> challenges, List<String> joinedIds) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No active challenges',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final isJoined = joinedIds.contains(challenge.id);

        return _ChallengeCard(
            challenge: challenge, isJoined: isJoined, userId: userId);
      },
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  final WorkoutChallenge challenge;
  final bool isJoined;
  final String userId;

  const _ChallengeCard({
    required this.challenge,
    required this.isJoined,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    challenge.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        challenge.description,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (challenge.deadline != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Ends in: ${_getTimeRemaining(challenge.deadline!)}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.creditReward} Credits',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: isJoined
                      ? null
                      : () => ref
                          .read(workoutServiceProvider)
                          .joinChallenge(userId, challenge.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isJoined
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primary,
                    foregroundColor: isJoined
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(isJoined ? 'Joined' : 'Join Challenge'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getTimeRemaining(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays} days';
    if (diff.inHours > 0) return '${diff.inHours} hours';
    return 'Ending soon';
  }
}
