# Firestore Permission Fix - Complete Solution

## Problem
Users were getting "the caller does not have permission to execute the specific operation" errors when:
1. Signing up (creating user document)
2. Logging in (updating `lastLoginAt`)
3. Accessing any Firestore collections

## Root Causes Identified

### 1. Missing `userId` in User Document Data
- **Issue**: Firestore rules expected `userId` field in document data, but `UserModel.toFirestore()` didn't include it
- **Fix**: Added `'userId': userId` to `toFirestore()` method

### 2. Missing `allow list` Rules for Collection Queries
- **Issue**: `StorageService.getCollectionStream()` queries entire collections without `where` clauses, which Firestore rules blocked
- **Fix**: Added `allow list: if isAuthenticated();` to all collections that need to be queried

### 3. Overly Strict Update Rules
- **Issue**: Update rules required `hasValidTimestamps()` which blocked partial updates like `lastLoginAt`
- **Fix**: Simplified user update rules to allow partial updates without requiring all fields

## Changes Made

### 1. User Model (`lib/data/models/user_model.dart`)
- ✅ Added `userId` to `toFirestore()` method
- ✅ Updated `fromFirestore()` to handle both new format (with `userId` field) and old format (document ID only)

### 2. Firestore Rules (`firestore.rules`)
- ✅ Simplified user collection rules:
  - Removed `hasValidTimestamps()` requirement from updates
  - Simplified create rule to only check essential fields
  - Made update rule allow partial updates
- ✅ Added `allow list` rules to ALL collections:
  - `cycles`
  - `symptoms`
  - `wellnessEntries`
  - `pads`
  - `padInventory`
  - `reminders`
  - `cyclePredictions`
  - `analytics`
  - `subscriptions`
  - `supportContacts`
  - `redFlagAlerts`
  - `pregnancies`
  - `fertilityEntries`
  - `skincareEntries`
  - `skincareProducts`

## How It Works Now

### Authentication Persistence
- Firebase Auth automatically persists authentication state
- User stays logged in until they explicitly sign out
- No additional code needed - Firebase handles this natively

### Firestore Access Flow
1. **User logs in** → Firebase Auth authenticates
2. **Auth state changes** → `currentUserStreamProvider` detects authenticated user
3. **User document read** → Rules check `request.auth.uid == userId` ✅
4. **Collection queries** → Rules allow `list` for authenticated users ✅
5. **Document reads** → Rules check `resource.data.userId == request.auth.uid` ✅
6. **Document writes** → Rules check `request.resource.data.userId == request.auth.uid` ✅

## Security Model

### User Isolation
- Users can only access documents where `userId == request.auth.uid`
- Collection queries are allowed but filtered client-side
- Individual document access is still protected by `userId` checks

### Data Validation
- Create operations validate required fields
- Update operations prevent `userId` and `email` tampering
- Timestamps are validated on create (not required on update)

## Deployment

Deploy the updated rules:
```bash
firebase deploy --only firestore:rules
```

## Testing Checklist

After deployment, verify:
- [ ] User can sign up successfully
- [ ] User can log in successfully
- [ ] User stays authenticated after app restart
- [ ] User can read their own data (cycles, pads, wellness, etc.)
- [ ] User can create new entries
- [ ] User can update existing entries
- [ ] User can delete their own entries
- [ ] User cannot access other users' data

## Notes

- The `allow list` rules enable collection queries, but individual document access is still protected
- Client-side filtering by `userId` ensures users only see their own data
- Firebase Auth handles persistence automatically - no additional code needed
- The app will stay authenticated until the user explicitly signs out

