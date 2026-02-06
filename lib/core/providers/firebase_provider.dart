import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track if Firebase has been initialized
final firebaseReadyProvider = StateProvider<bool>((ref) => false);
