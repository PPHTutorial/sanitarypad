import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:sanitarypad/core/constants/app_constants.dart';

/// User model
class UserModel extends Equatable {
  final String userId;
  final String email;
  final String? displayName;
  final String? fullName;
  final String? username;
  final String? photoUrl;
  final String? address;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String role; // 'user', 'admin', 'moderator'
  final UserSettings settings;
  final UserSubscription subscription;
  final UserPrivacy privacy;

  const UserModel({
    required this.userId,
    required this.email,
    this.displayName,
    this.fullName,
    this.username,
    this.photoUrl,
    this.address,
    this.gender,
    this.dateOfBirth,
    this.phoneNumber,
    required this.createdAt,
    this.lastLoginAt,
    this.role = 'user',
    required this.settings,
    required this.subscription,
    required this.privacy,
  });

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator' || role == 'admin';

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Prefer userId from data, fallback to document ID (for backward compatibility)
    final userId = data['userId'] as String? ?? doc.id;
    return UserModel(
      userId: userId,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      fullName: data['fullName'] as String?,
      username: data['username'] as String?,
      photoUrl: data['photoUrl'] as String?,
      address: data['address'] as String?,
      gender: data['gender'] as String?,
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      role: data['role'] as String? ?? 'user',
      settings: data['settings'] != null
          ? UserSettings.fromMap(data['settings'] as Map<String, dynamic>)
          : const UserSettings(units: UserUnits()),
      subscription: data['subscription'] != null
          ? UserSubscription.fromMap(
              data['subscription'] as Map<String, dynamic>,
            )
          : const UserSubscription(),
      privacy: data['privacy'] != null
          ? UserPrivacy.fromMap(data['privacy'] as Map<String, dynamic>)
          : const UserPrivacy(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId, // Include userId in document data for security rules
      'email': email,
      'displayName': displayName,
      'fullName': fullName,
      'username': username,
      'photoUrl': photoUrl,
      'address': address,
      'gender': gender,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'role': role,
      'settings': settings.toMap(),
      'subscription': subscription.toMap(),
      'privacy': privacy.toMap(),
    };
  }

  /// Create copy with updated fields
  UserModel copyWith({
    String? email,
    String? displayName,
    String? fullName,
    String? username,
    String? photoUrl,
    String? address,
    String? gender,
    DateTime? dateOfBirth,
    String? phoneNumber,
    DateTime? lastLoginAt,
    String? role,
    UserSettings? settings,
    UserSubscription? subscription,
    UserPrivacy? privacy,
  }) {
    return UserModel(
      userId: userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role,
      settings: settings ?? this.settings,
      subscription: subscription ?? this.subscription,
      privacy: privacy ?? this.privacy,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        email,
        displayName,
        fullName,
        username,
        photoUrl,
        address,
        gender,
        dateOfBirth,
        phoneNumber,
        createdAt,
        lastLoginAt,
        role,
        settings,
        subscription,
        privacy,
      ];
}

/// User settings
class UserSettings extends Equatable {
  final String theme;
  final String language;
  final bool notificationsEnabled;
  final bool anonymousMode;
  final bool biometricLock;
  final String? pinHash;
  final bool teenMode;
  final int cycleLength;
  final int periodLength;
  final bool predictPeriod;
  final bool predictOvulation;
  final bool dailyLogPrompt;
  final UserUnits units;

  const UserSettings({
    this.theme = 'system',
    this.language = 'en',
    this.notificationsEnabled = true,
    this.anonymousMode = false,
    this.biometricLock = false,
    this.pinHash,
    this.teenMode = false,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.predictPeriod = true,
    this.predictOvulation = true,
    this.dailyLogPrompt = true,
    required this.units,
  });

  UserSettings copyWith({
    String? theme,
    String? language,
    bool? notificationsEnabled,
    bool? anonymousMode,
    bool? biometricLock,
    String? pinHash,
    bool? teenMode,
    int? cycleLength,
    int? periodLength,
    bool? predictPeriod,
    bool? predictOvulation,
    bool? dailyLogPrompt,
    UserUnits? units,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      anonymousMode: anonymousMode ?? this.anonymousMode,
      biometricLock: biometricLock ?? this.biometricLock,
      pinHash: pinHash ?? this.pinHash,
      teenMode: teenMode ?? this.teenMode,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      predictPeriod: predictPeriod ?? this.predictPeriod,
      predictOvulation: predictOvulation ?? this.predictOvulation,
      dailyLogPrompt: dailyLogPrompt ?? this.dailyLogPrompt,
      units: units ?? this.units,
    );
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      theme: map['theme'] as String? ?? 'system',
      language: map['language'] as String? ?? 'en',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      anonymousMode: map['anonymousMode'] as bool? ?? false,
      biometricLock: map['biometricLock'] as bool? ?? false,
      pinHash: map['pinHash'] as String?,
      teenMode: map['teenMode'] as bool? ?? false,
      cycleLength: map['cycleLength'] as int? ?? 28,
      periodLength: map['periodLength'] as int? ?? 5,
      predictPeriod: map['predictPeriod'] as bool? ?? true,
      predictOvulation: map['predictOvulation'] as bool? ?? true,
      dailyLogPrompt: map['dailyLogPrompt'] as bool? ?? true,
      units: UserUnits.fromMap(
        map['units'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'anonymousMode': anonymousMode,
      'biometricLock': biometricLock,
      'pinHash': pinHash,
      'teenMode': teenMode,
      'cycleLength': cycleLength,
      'periodLength': periodLength,
      'predictPeriod': predictPeriod,
      'predictOvulation': predictOvulation,
      'dailyLogPrompt': dailyLogPrompt,
      'units': units.toMap(),
    };
  }

  @override
  List<Object?> get props => [
        theme,
        language,
        notificationsEnabled,
        anonymousMode,
        biometricLock,
        pinHash,
        teenMode,
        cycleLength,
        periodLength,
        predictPeriod,
        predictOvulation,
        dailyLogPrompt,
        units,
      ];
}

/// User units
class UserUnits extends Equatable {
  final String temperature;
  final String weight;

  const UserUnits({
    this.temperature = 'celsius',
    this.weight = 'kg',
  });

  factory UserUnits.fromMap(Map<String, dynamic> map) {
    return UserUnits(
      temperature: map['temperature'] as String? ?? 'celsius',
      weight: map['weight'] as String? ?? 'kg',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'weight': weight,
    };
  }

  @override
  List<Object?> get props => [temperature, weight];
}

/// User subscription
class UserSubscription extends Equatable {
  final String tier;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? plan; // 'monthly', 'yearly', 'forever'
  final String? paymentMethod;
  final String? transactionId;
  final double dailyCreditsRemaining;
  final double adCreditsEarnedToday;
  final int totalActionsToday;
  final DateTime? lastResetDate;

  const UserSubscription({
    this.tier = 'economy',
    this.status = 'expired',
    this.plan,
    this.startDate,
    this.endDate,
    this.paymentMethod,
    this.transactionId,
    this.dailyCreditsRemaining = AppConstants.creditsDefault,
    this.adCreditsEarnedToday = 0.0,
    this.totalActionsToday = 0,
    this.lastResetDate,
  });

  /// Getter to handle null lastResetDate (defaults to epoch)
  DateTime get effectiveLastResetDate =>
      lastResetDate ?? DateTime.fromMillisecondsSinceEpoch(0);

  UserSubscription copyWith({
    String? tier,
    String? status,
    String? plan,
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    String? transactionId,
    double? dailyCreditsRemaining,
    double? adCreditsEarnedToday,
    int? totalActionsToday,
    DateTime? lastResetDate,
  }) {
    return UserSubscription(
      tier: tier ?? this.tier,
      status: status ?? this.status,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      dailyCreditsRemaining:
          dailyCreditsRemaining ?? this.dailyCreditsRemaining,
      adCreditsEarnedToday: adCreditsEarnedToday ?? this.adCreditsEarnedToday,
      totalActionsToday: totalActionsToday ?? this.totalActionsToday,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      tier: map['tier'] as String? ?? 'economy',
      status: map['status'] as String? ?? 'expired',
      plan: map['plan'] as String?,
      startDate: map['startDate'] != null
          ? (map['startDate'] as Timestamp).toDate()
          : null,
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      paymentMethod: map['paymentMethod'] as String?,
      transactionId: map['transactionId'] as String?,
      dailyCreditsRemaining:
          (map['dailyCreditsRemaining'] as num? ?? 3).toDouble(),
      adCreditsEarnedToday:
          (map['adCreditsEarnedToday'] as num? ?? 0).toDouble(),
      totalActionsToday: (map['totalActionsToday'] as num? ?? 0).toInt(),
      lastResetDate: map['lastResetDate'] != null
          ? (map['lastResetDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tier': tier,
      'status': status,
      'plan': plan,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'dailyCreditsRemaining': dailyCreditsRemaining,
      'adCreditsEarnedToday': adCreditsEarnedToday,
      'totalActionsToday': totalActionsToday,
      'lastResetDate':
          lastResetDate != null ? Timestamp.fromDate(lastResetDate!) : null,
    };
  }

  bool get isActive {
    if (status != 'active') return false;
    if (tier == 'economy') return true; // Eco is forever
    if (endDate == null) return false;
    return endDate!.isAfter(DateTime.now());
  }

  /// Check if plan is yearly
  bool get isYearly {
    // Economy tier is basic/free and never qualifies for "Yearly Unlimited" credits
    // regardless of duration or plan name.
    if (tier == 'economy') return false;

    if (plan != null && plan!.toLowerCase().contains('yearly')) return true;
    if (startDate != null && endDate != null) {
      // Logic: If duration is > 300 days (approx 10 months), treat as yearly
      return endDate!.difference(startDate!).inDays > 300;
    }
    return false;
  }

  /// Check if credits should be reset (new day)
  bool get shouldResetDaily {
    final now = DateTime.now();
    final resetDate = effectiveLastResetDate;
    return now.year != resetDate.year ||
        now.month != resetDate.month ||
        now.day != resetDate.day;
  }

  @override
  List<Object?> get props => [
        tier,
        status,
        plan,
        startDate,
        endDate,
        paymentMethod,
        transactionId,
      ];
}

/// User privacy
class UserPrivacy extends Equatable {
  final bool dataEncrypted;
  final DateTime? lastExportDate;
  final bool? deletionRequested;
  final String profileVisibility; // 'public', 'private', 'protected'

  // Visibility Flags
  final bool showFullName;
  final bool showUsername;
  final bool showPhoto;
  final bool showAddress;
  final bool showGender;
  final bool showAge;
  final bool showHealthStats;

  const UserPrivacy({
    this.dataEncrypted = true,
    this.lastExportDate,
    this.deletionRequested = false,
    this.profileVisibility = 'private',
    this.showFullName = false,
    this.showUsername = true,
    this.showPhoto = true,
    this.showAddress = false,
    this.showGender = false,
    this.showAge = false,
    this.showHealthStats = false,
  });

  UserPrivacy copyWith({
    bool? dataEncrypted,
    DateTime? lastExportDate,
    bool? deletionRequested,
    String? profileVisibility,
    bool? showFullName,
    bool? showUsername,
    bool? showPhoto,
    bool? showAddress,
    bool? showGender,
    bool? showAge,
    bool? showHealthStats,
  }) {
    return UserPrivacy(
      dataEncrypted: dataEncrypted ?? this.dataEncrypted,
      lastExportDate: lastExportDate ?? this.lastExportDate,
      deletionRequested: deletionRequested ?? this.deletionRequested,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showFullName: showFullName ?? this.showFullName,
      showUsername: showUsername ?? this.showUsername,
      showPhoto: showPhoto ?? this.showPhoto,
      showAddress: showAddress ?? this.showAddress,
      showGender: showGender ?? this.showGender,
      showAge: showAge ?? this.showAge,
      showHealthStats: showHealthStats ?? this.showHealthStats,
    );
  }

  factory UserPrivacy.fromMap(Map<String, dynamic> map) {
    return UserPrivacy(
      dataEncrypted: map['dataEncrypted'] as bool? ?? true,
      lastExportDate: map['lastExportDate'] != null
          ? (map['lastExportDate'] as Timestamp).toDate()
          : null,
      deletionRequested: map['deletionRequested'] as bool? ?? false,
      profileVisibility: map['profileVisibility'] as String? ?? 'private',
      showFullName: map['showFullName'] as bool? ?? false,
      showUsername: map['showUsername'] as bool? ?? true,
      showPhoto: map['showPhoto'] as bool? ?? true,
      showAddress: map['showAddress'] as bool? ?? false,
      showGender: map['showGender'] as bool? ?? false,
      showAge: map['showAge'] as bool? ?? false,
      showHealthStats: map['showHealthStats'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dataEncrypted': dataEncrypted,
      'lastExportDate':
          lastExportDate != null ? Timestamp.fromDate(lastExportDate!) : null,
      'deletionRequested': deletionRequested ?? false,
      'profileVisibility': profileVisibility,
      'showFullName': showFullName,
      'showUsername': showUsername,
      'showPhoto': showPhoto,
      'showAddress': showAddress,
      'showGender': showGender,
      'showAge': showAge,
      'showHealthStats': showHealthStats,
    };
  }

  @override
  List<Object?> get props => [
        dataEncrypted,
        lastExportDate,
        deletionRequested,
        profileVisibility,
        showFullName,
        showUsername,
        showPhoto,
        showAddress,
        showGender,
        showAge,
        showHealthStats,
      ];
}
