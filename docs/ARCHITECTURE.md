# FemCare+ System Architecture

## Overview
FemCare+ is a cross-platform women's health and wellness application built with Flutter for mobile and Next.js for web/backend services. The system prioritizes privacy, security, and user experience.

## Architecture Layers

### 1. Client Layer (Flutter Mobile App)
- **Platform**: Flutter (iOS, Android, Web)
- **State Management**: Riverpod (recommended) or Provider
- **Local Storage**: Hive (offline-first approach)
- **UI Framework**: Material Design 3 with custom feminine theme
- **Responsive Design**: flutter_screenutil for adaptive layouts

### 2. Backend Services Layer
- **Platform**: Next.js (TypeScript)
- **Hosting**: Vercel
- **API**: RESTful + GraphQL (optional)
- **State Management**: TanStack Query (React Query)
- **Styling**: Tailwind CSS

### 3. Authentication & Security Layer
- **Provider**: Firebase Authentication
- **Methods**: Email/Password, Google Sign-In, Anonymous mode
- **Security**: 
  - End-to-end encryption for health data
  - PIN/Biometric lock
  - Zero-knowledge architecture
  - Data export/delete capabilities

### 4. Database Layer
- **Primary**: Firebase Firestore
- **Structure**: 
  - Users collection
  - Cycles collection
  - Symptoms collection
  - Pads collection
  - Wellness entries collection
  - Subscriptions collection
- **Offline Support**: Hive local database with sync

### 5. Notification Layer
- **Service**: Firebase Cloud Messaging (FCM)
- **Types**:
  - Period prediction alerts
  - Pad change reminders
  - Wellness check-ins
  - Subscription updates

### 6. Payment & Subscription Layer
- **International**: Stripe
- **Local (Africa)**: Flutterwave
- **Mobile**: In-App Purchases (iOS/Android)
- **Subscription Tiers**: Monthly, Quarterly, Yearly

### 7. AI/ML Layer (Premium)
- **Cycle Prediction**: Machine learning models
- **Symptom Analysis**: AI-powered insights
- **Personalized Recommendations**: ML-based suggestions

## Data Flow

```
User Action → Flutter App → Local Storage (Hive)
                              ↓
                         Sync Service
                              ↓
                    Firebase Firestore
                              ↓
                    Next.js Backend (if needed)
                              ↓
                    AI/ML Processing (Premium)
                              ↓
                    Push Notifications (FCM)
```

## Security Architecture

1. **Data Encryption**
   - Health data encrypted at rest
   - End-to-end encryption for sensitive data
   - Secure key management

2. **Authentication Flow**
   - Firebase Auth handles authentication
   - JWT tokens for API access
   - Biometric/PIN for app access

3. **Privacy Features**
   - Anonymous mode (no personal data)
   - Data export in JSON format
   - Complete data deletion option

## Offline-First Architecture

- **Local Database**: Hive for offline storage
- **Sync Strategy**: Background sync when online
- **Conflict Resolution**: Last-write-wins with user confirmation
- **Data Priority**: Critical data (cycles, symptoms) prioritized

## Scalability Considerations

- **Firestore**: Automatic scaling
- **CDN**: Vercel edge network
- **Caching**: Aggressive caching for static content
- **Database Indexing**: Optimized Firestore indexes

## Technology Stack Summary

### Mobile (Flutter)
- Flutter SDK 3.0+
- Riverpod (State Management)
- Hive (Local Storage)
- Firebase (Auth, Firestore, FCM, Storage)
- flutter_screenutil (Responsive)
- google_fonts (Red Hat Display)
- in_app_purchase (Subscriptions)

### Backend/Web (Next.js)
- Next.js 14+
- TypeScript
- TanStack Query
- Tailwind CSS
- Firebase Admin SDK
- Stripe/Flutterwave SDKs

## Deployment Strategy

- **Mobile**: App Store (iOS), Play Store (Android)
- **Web**: Vercel (Next.js)
- **Database**: Firebase (Firestore)
- **CDN**: Vercel Edge Network

## Monitoring & Analytics

- Firebase Analytics
- Crashlytics for error tracking
- Performance monitoring
- User behavior analytics (privacy-compliant)

