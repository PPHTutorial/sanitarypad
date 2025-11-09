import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// User model
class UserModel extends Equatable {
  final String userId;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserSettings settings;
  final UserSubscription subscription;
  final UserPrivacy privacy;

  const UserModel({
    required this.userId,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.lastLoginAt,
    required this.settings,
    required this.subscription,
    required this.privacy,
  });

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      settings: UserSettings.fromMap(data['settings'] as Map<String, dynamic>),
      subscription: UserSubscription.fromMap(
        data['subscription'] as Map<String, dynamic>,
      ),
      privacy: UserPrivacy.fromMap(data['privacy'] as Map<String, dynamic>),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'settings': settings.toMap(),
      'subscription': subscription.toMap(),
      'privacy': privacy.toMap(),
    };
  }

  /// Create copy with updated fields
  UserModel copyWith({
    String? email,
    String? displayName,
    DateTime? lastLoginAt,
    UserSettings? settings,
    UserSubscription? subscription,
    UserPrivacy? privacy,
  }) {
    return UserModel(
      userId: userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
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
        createdAt,
        lastLoginAt,
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
  final UserUnits units;

  const UserSettings({
    this.theme = 'system',
    this.language = 'en',
    this.notificationsEnabled = true,
    this.anonymousMode = false,
    this.biometricLock = false,
    this.pinHash,
    this.teenMode = false,
    required this.units,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      theme: map['theme'] as String? ?? 'system',
      language: map['language'] as String? ?? 'en',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      anonymousMode: map['anonymousMode'] as bool? ?? false,
      biometricLock: map['biometricLock'] as bool? ?? false,
      pinHash: map['pinHash'] as String?,
      teenMode: map['teenMode'] as bool? ?? false,
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
  final String? paymentMethod;
  final String? transactionId;

  const UserSubscription({
    this.tier = 'free',
    this.status = 'expired',
    this.startDate,
    this.endDate,
    this.paymentMethod,
    this.transactionId,
  });

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      tier: map['tier'] as String? ?? 'free',
      status: map['status'] as String? ?? 'expired',
      startDate: map['startDate'] != null
          ? (map['startDate'] as Timestamp).toDate()
          : null,
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      paymentMethod: map['paymentMethod'] as String?,
      transactionId: map['transactionId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tier': tier,
      'status': status,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
    };
  }

  bool get isActive {
    if (status != 'active') return false;
    if (endDate == null) return false;
    return endDate!.isAfter(DateTime.now());
  }

  @override
  List<Object?> get props => [
        tier,
        status,
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

  const UserPrivacy({
    this.dataEncrypted = true,
    this.lastExportDate,
    this.deletionRequested = false,
  });

  factory UserPrivacy.fromMap(Map<String, dynamic> map) {
    return UserPrivacy(
      dataEncrypted: map['dataEncrypted'] as bool? ?? true,
      lastExportDate: map['lastExportDate'] != null
          ? (map['lastExportDate'] as Timestamp).toDate()
          : null,
      deletionRequested: map['deletionRequested'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dataEncrypted': dataEncrypted,
      'lastExportDate':
          lastExportDate != null ? Timestamp.fromDate(lastExportDate!) : null,
      'deletionRequested': deletionRequested ?? false,
    };
  }

  @override
  List<Object?> get props => [dataEncrypted, lastExportDate, deletionRequested];
}
