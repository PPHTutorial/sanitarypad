# FemCare+ Firebase Firestore Database Schema

## Collections Overview

### 1. users
User profile and settings data.

```typescript
{
  userId: string (document ID),
  email: string,
  displayName?: string,
  createdAt: timestamp,
  lastLoginAt: timestamp,
  settings: {
    theme: 'light' | 'dark' | 'system',
    language: string,
    notificationsEnabled: boolean,
    anonymousMode: boolean,
    biometricLock: boolean,
    pinHash?: string,
    teenMode: boolean,
    units: {
      temperature: 'celsius' | 'fahrenheit',
      weight: 'kg' | 'lbs'
    }
  },
  subscription: {
    tier: 'free' | 'premium',
    status: 'active' | 'expired' | 'cancelled',
    startDate?: timestamp,
    endDate?: timestamp,
    paymentMethod?: 'stripe' | 'flutterwave' | 'iap',
    transactionId?: string
  },
  privacy: {
    dataEncrypted: boolean,
    lastExportDate?: timestamp,
    deletionRequested?: boolean
  }
}
```

### 2. cycles
Menstrual cycle tracking data.

```typescript
{
  cycleId: string (document ID),
  userId: string,
  startDate: timestamp,
  endDate?: timestamp,
  cycleLength: number, // days
  periodLength: number, // days
  flowIntensity: 'light' | 'medium' | 'heavy',
  symptoms: string[], // ['cramps', 'headache', etc.]
  mood: string, // emoji or text
  notes?: string,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 3. cyclePredictions
AI-generated cycle predictions.

```typescript
{
  predictionId: string (document ID),
  userId: string,
  predictedStartDate: timestamp,
  predictedEndDate: timestamp,
  confidence: number, // 0-1
  ovulationDate?: timestamp,
  fertileWindow?: {
    start: timestamp,
    end: timestamp
  },
  pmsStartDate?: timestamp,
  createdAt: timestamp
}
```

### 4. symptoms
Detailed symptom logging.

```typescript
{
  symptomId: string (document ID),
  userId: string,
  date: timestamp,
  cycleId?: string,
  type: 'cramps' | 'headache' | 'fatigue' | 'bloating' | 'mood_swings' | 'acne' | 'other',
  severity: 1 | 2 | 3 | 4 | 5, // 1=mild, 5=severe
  location?: string, // for cramps
  duration?: number, // minutes
  notes?: string,
  createdAt: timestamp
}
```

### 5. wellnessEntries
Daily wellness check-ins.

```typescript
{
  entryId: string (document ID),
  userId: string,
  date: timestamp,
  hydration: {
    waterGlasses: number,
    goal: number
  },
  sleep: {
    hours: number,
    quality: 1 | 2 | 3 | 4 | 5,
    bedtime?: timestamp,
    wakeTime?: timestamp
  },
  appetite: {
    level: 'low' | 'normal' | 'high',
    notes?: string
  },
  mood: {
    emoji: string,
    description?: string,
    energyLevel: 1 | 2 | 3 | 4 | 5
  },
  exercise?: {
    type: string,
    duration: number, // minutes
    intensity: 'light' | 'moderate' | 'vigorous'
  },
  journal?: string,
  createdAt: timestamp
}
```

### 6. pads
Sanitary pad management.

```typescript
{
  padId: string (document ID),
  userId: string,
  changeTime: timestamp,
  cycleId?: string,
  padType: 'light' | 'regular' | 'super' | 'overnight',
  flowIntensity: 'light' | 'medium' | 'heavy',
  duration: number, // hours since last change
  notes?: string,
  createdAt: timestamp
}
```

### 7. padInventory
Pad stock tracking.

```typescript
{
  inventoryId: string (document ID),
  userId: string,
  padType: 'light' | 'regular' | 'super' | 'overnight',
  quantity: number,
  brand?: string,
  lastRefillDate?: timestamp,
  lowStockThreshold: number, // default: 10
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 8. reminders
User-configured reminders.

```typescript
{
  reminderId: string (document ID),
  userId: string,
  type: 'pad_change' | 'period_prediction' | 'wellness_check' | 'medication' | 'custom',
  title: string,
  message: string,
  enabled: boolean,
  time?: string, // HH:mm format
  daysOfWeek?: number[], // 0=Sunday, 6=Saturday
  flowBased?: boolean,
  flowThreshold?: 'light' | 'medium' | 'heavy',
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 9. wellnessContent
Educational and wellness content.

```typescript
{
  contentId: string (document ID),
  type: 'tip' | 'article' | 'meditation' | 'affirmation' | 'myth_fact',
  category: 'menstrual' | 'hygiene' | 'nutrition' | 'fitness' | 'mental_health' | 'teen' | 'menopause',
  title: string,
  content: string,
  imageUrl?: string,
  audioUrl?: string, // for meditations
  cyclePhase?: 'menstrual' | 'follicular' | 'ovulation' | 'luteal',
  isPremium: boolean,
  tags: string[],
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 10. analytics
User analytics and insights (aggregated).

```typescript
{
  analyticsId: string (document ID),
  userId: string,
  period: 'week' | 'month' | 'year',
  startDate: timestamp,
  endDate: timestamp,
  averageCycleLength: number,
  averagePeriodLength: number,
  mostCommonSymptoms: string[],
  moodTrends: object,
  wellnessScore: number, // 0-100
  createdAt: timestamp
}
```

### 11. subscriptions
Subscription and payment records.

```typescript
{
  subscriptionId: string (document ID),
  userId: string,
  tier: 'premium',
  plan: 'monthly' | 'quarterly' | 'yearly',
  status: 'active' | 'expired' | 'cancelled' | 'pending',
  startDate: timestamp,
  endDate: timestamp,
  paymentMethod: 'stripe' | 'flutterwave' | 'iap_ios' | 'iap_android',
  transactionId: string,
  amount: number,
  currency: string,
  isStudentDiscount: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 12. supportContacts
Emergency and support contacts.

```typescript
{
  contactId: string (document ID),
  userId: string,
  name: string,
  phoneNumber: string,
  relationship: string,
  isEmergency: boolean,
  isSOS: boolean,
  createdAt: timestamp
}
```

### 13. redFlagAlerts
Health alerts and warnings.

```typescript
{
  alertId: string (document ID),
  userId: string,
  type: 'pcos_indicator' | 'anemia_indicator' | 'infection_indicator' | 'irregular_cycle',
  severity: 'low' | 'medium' | 'high',
  message: string,
  symptoms: string[],
  recommendation: string,
  acknowledged: boolean,
  createdAt: timestamp
}
```

## Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /cycles/{cycleId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    match /symptoms/{symptomId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Similar rules for all user-specific collections
    // Wellness content is readable by all authenticated users
    match /wellnessContent/{contentId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins can write
    }
  }
}
```

## Indexes Required

1. `cycles`: userId + startDate (descending)
2. `symptoms`: userId + date (descending)
3. `wellnessEntries`: userId + date (descending)
4. `pads`: userId + changeTime (descending)
5. `reminders`: userId + enabled

## Data Encryption

- Sensitive fields encrypted before storage
- Encryption keys stored securely
- Zero-knowledge architecture for health data

