/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'FemCare+';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.codeink.stsl.sanitarypad';

  // Design Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonHeight = 48.0;

  // Cycle Constants
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int minCycleLength = 21;
  static const int maxCycleLength = 35;
  static const int minPeriodLength = 3;
  static const int maxPeriodLength = 7;

  // Pad Constants
  static const int defaultLowStockThreshold = 10;
  static const int defaultPadChangeReminderHours = 4;

  // Storage Keys
  static const String hiveBoxName = 'femcare_box';
  static const String prefsKeyOnboardingComplete = 'onboarding_complete';
  static const String prefsKeyUserId = 'user_id';
  static const String prefsKeyPinHash = 'pin_hash';
  static const String prefsKeyBiometricEnabled = 'biometric_enabled';
  static const String prefsKeyAnonymousMode = 'anonymous_mode';
  static const String prefsKeyNotificationCheckInterval =
      'notification_check_interval_minutes';

  // Notification Check Intervals (in minutes)
  static const int defaultNotificationCheckInterval = 5; // Default: 5 minutes
  static const int minNotificationCheckInterval = 1; // Minimum: 1 minute
  static const int maxNotificationCheckInterval = 30; // Maximum: 30 minutes

  // Collection Names (Firestore)
  static const String collectionUsers = 'users';
  static const String collectionCycles = 'cycles';
  static const String collectionCyclePredictions = 'cyclePredictions';
  static const String collectionSymptoms = 'symptoms';
  static const String collectionWellnessEntries = 'wellnessEntries';
  static const String collectionPads = 'pads';
  static const String collectionPadInventory = 'padInventory';
  static const String collectionReminders = 'reminders';
  static const String collectionWellnessContent = 'wellnessContent';
  static const String collectionAnalytics = 'analytics';
  static const String collectionSubscriptions = 'subscriptions';
  static const String collectionSupportContacts = 'supportContacts';
  static const String collectionRedFlagAlerts = 'redFlagAlerts';
  static const String collectionPregnancies = 'pregnancies';
  static const String collectionFertilityEntries = 'fertilityEntries';
  static const String collectionSkincareEntries = 'skincareEntries';
  static const String collectionSkincareProducts = 'skincareProducts';
  static const String collectionKickEntries = 'kickEntries';
  static const String collectionContractionEntries = 'contractionEntries';
  static const String collectionPregnancyAppointments = 'pregnancyAppointments';
  static const String collectionPregnancyMedications = 'pregnancyMedications';
  static const String collectionPregnancyJournalEntries =
      'pregnancyJournalEntries';
  static const String collectionPregnancyWeightEntries =
      'pregnancyWeightEntries';
  static const String collectionHospitalChecklistItems =
      'hospitalChecklistItems';
  static const String collectionSkinTypes = 'skinTypes';
  static const String collectionSkinJournalEntries = 'skinJournalEntries';
  static const String collectionRoutineTemplates = 'routineTemplates';
  static const String collectionIngredients = 'ingredients';
  static const String collectionAcneEntries = 'acneEntries';
  static const String collectionUVIndexEntries = 'uvIndexEntries';
  static const String collectionSkinGoals = 'skinGoals';
  static const String collectionHormoneCycles = 'hormoneCycles';
  static const String collectionFertilitySymptoms = 'fertilitySymptoms';
  static const String collectionMoodEnergyEntries = 'moodEnergyEntries';
  static const String collectionFertilityMedications = 'fertilityMedications';
  static const String collectionIntercourseEntries = 'intercourseEntries';
  static const String collectionPregnancyTestEntries = 'pregnancyTestEntries';
  static const String collectionHealthRecommendations = 'healthRecommendations';
  static const String collectionOvulationTestReminders =
      'ovulationTestReminders';
  static const String collectionGroups = 'groups';
  static const String collectionGroupMembers = 'groupMembers';
  static const String collectionGroupMessages = 'groupMessages';
  static const String collectionEvents = 'events';
  static const String collectionEventAttendees = 'eventAttendees';
  static const String collectionAIChatMessages = 'aiChatMessages';
  static const String collectionAIConversations = 'aiConversations';

  // Subscription Tiers
  static const String tierEconomy = 'economy';
  static const String tierPremiumPro = 'premium_pro';
  static const String tierPremiumAdvance = 'premium_advance';
  static const String tierPremiumPlus = 'premium_plus';

  // Subscription Plans
  static const String planForever = 'forever';
  static const String planMonthly = 'monthly';
  static const String planQuarterly = 'quarterly';
  static const String planSemiAnnual = 'semi_annual';
  static const String planYearly = 'yearly';

  // Flow Intensity
  static const String flowLight = 'light';
  static const String flowMedium = 'medium';
  static const String flowHeavy = 'heavy';

  // Pad Types
  static const String padTypeLight = 'light';
  static const String padTypeRegular = 'regular';
  static const String padTypeSuper = 'super';
  static const String padTypeOvernight = 'overnight';

  // Cycle Phases
  static const String phaseMenstrual = 'menstrual';
  static const String phaseFollicular = 'follicular';
  static const String phaseOvulation = 'ovulation';
  static const String phaseLuteal = 'luteal';

  // Symptom Types
  static const List<String> symptomTypes = [
    'cramps',
    'headache',
    'fatigue',
    'bloating',
    'mood_swings',
    'acne',
    'nausea',
    'backache',
    'breast_tenderness',
    'other',
  ];

  // Reminder Types
  static const String reminderPadChange = 'pad_change';
  static const String reminderPeriodPrediction = 'period_prediction';
  static const String reminderWellnessCheck = 'wellness_check';
  static const String reminderMedication = 'medication';
  static const String reminderCustom = 'custom';

  // Content Types
  static const String contentTypeTip = 'tip';
  static const String contentTypeArticle = 'article';
  static const String contentTypeMeditation = 'meditation';
  static const String contentTypeAffirmation = 'affirmation';
  static const String contentTypeMythFact = 'myth_fact';

  // Privacy
  static const int pinLength = 4;
  static const int maxFailedPinAttempts = 5;

  // Credit Costs (ActionType costs)
  static const double costPregnancy = 2.0;
  static const double costFertility = 2.0;
  static const double costSkincare = 3.0;
  static const double costWellness = 2.0;
  static const double costLogPeriod = 2.0;
  static const double costPadChange = 2.0;
  static const double costNotification = 2.0;
  static const double costAIChat = 5.0;
  static const double costMovie = 2;
  static const double costCreateGroup = 5.0;
  static const double costCreateEvent = 5.0;
  static const double costDermatologist = 5.0;
  static const double costExport = 2.0;
  static const double costEmergencyNumber = 1.0;

  // Daily Credit Limits (per tier)
  static const double creditsEco = 108.0;
  static const double creditsPro = 360.0;
  static const double creditsAdv = 720.0;
  static const double creditsPlus = 1440.0;
  static const double creditsYearly = 999990.0;
  static const double creditsDefault = 108.0;

  // Subscription Pricing (Monthly)
  static const double priceEco = 0.0;
  static const double pricePro = 19.99;
  static const double priceAdv = 29.99;
  static const double pricePlus = 59.99;

  // Ad Rewards
  static const int adsNeededForReward = 3;
  static const double creditsPerAdReward = 2.0;

  // Download Links
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';
  static const String appStoreUrl =
      'https://apps.apple.com/app/femcare/id123456789'; // Placeholder ID
}
