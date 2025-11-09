# Firestore Security Rules Documentation

## Overview

This document describes the comprehensive Firestore security rules implemented for the FemCare+ application. These rules ensure that:

1. **Only authenticated users** can access the database
2. **Users can only access their own data** (user isolation)
3. **Data integrity** is maintained through validation
4. **Attack prevention** through strict access controls

## Security Principles

### 1. Authentication Required
- All operations require a valid Firebase Authentication token
- No anonymous or unauthenticated access is allowed

### 2. User Isolation
- Users can only read/write data where `userId` matches their `request.auth.uid`
- Prevents cross-user data access

### 3. Data Validation
- Validates required fields on create/update
- Ensures timestamp fields are properly formatted
- Prevents data tampering (e.g., userId cannot be changed)

### 4. Attack Prevention
- **Injection Attacks**: Field type validation prevents malicious data
- **Data Tampering**: userId cannot be modified after creation
- **Unauthorized Access**: Strict user ownership checks
- **Mass Assignment**: Only allows specific fields to be written

## Collection Rules

### Users Collection (`/users/{userId}`)
- **Read**: Users can only read their own profile
- **Create**: Users can create their own profile with validation
- **Update**: Users can update their own profile (email cannot be changed)
- **Delete**: Users can delete their own profile

**Security Checks:**
- Email must match authenticated user's email
- userId cannot be tampered with
- Timestamps must be valid

### Cycles Collection (`/cycles/{cycleId}`)
- **Read**: Users can only read their own cycles
- **Create**: Users can create cycles with required fields
- **Update**: Users can update their own cycles
- **Delete**: Users can delete their own cycles

**Required Fields:**
- `userId`, `startDate`, `cycleLength`, `periodLength`, `flowIntensity`

### Wellness Entries Collection (`/wellnessEntries/{entryId}`)
- **Read**: Users can only read their own entries
- **Create**: Users can create entries with date validation
- **Update**: Users can update their own entries
- **Delete**: Users can delete their own entries

### Pads Collection (`/pads/{padId}`)
- **Read**: Users can only read their own pad changes
- **Create**: Users can create pad changes with timestamp validation
- **Update**: Users can update their own pad changes
- **Delete**: Users can delete their own pad changes

### Wellness Content Collection (`/wellnessContent/{contentId}`)
- **Read**: All authenticated users can read (public content)
- **Write**: Disabled for client-side (admin-only via Admin SDK)

### Subscriptions Collection (`/subscriptions/{subscriptionId}`)
- **Read**: Users can only read their own subscriptions
- **Create**: Users can create subscriptions with validation
- **Update**: Users can update their own subscriptions
- **Delete**: Disabled (for audit trail)

### Other Collections
All other collections (pregnancies, fertilityEntries, skincareEntries, etc.) follow the same pattern:
- User isolation (userId must match)
- Timestamp validation
- Required field validation
- Full CRUD for own data only

## Helper Functions

### `isAuthenticated()`
Checks if the request has a valid authentication token.

### `isOwner(userId)`
Verifies that the authenticated user owns the resource.

### `isValidUserId()`
Ensures the userId in request data matches the authenticated user.

### `isCreatingOwnDocument(userId)`
Validates that a user is creating a document for themselves.

### `hasValidTimestamps()`
Ensures timestamp fields are properly formatted.

## Deployment

### Deploy Rules
```bash
firebase deploy --only firestore:rules
```

### Deploy Indexes
```bash
firebase deploy --only firestore:indexes
```

### Test Rules
Use the Firebase Console Rules Playground to test your rules before deploying.

## Security Best Practices

1. **Never disable authentication** for any collection
2. **Always validate userId** matches `request.auth.uid`
3. **Validate data types** to prevent injection attacks
4. **Use helper functions** for consistency
5. **Test rules thoroughly** before deployment
6. **Monitor access patterns** in Firebase Console
7. **Review rules regularly** for security updates

## Common Attack Vectors Prevented

### 1. User ID Spoofing
- Rules check `request.auth.uid` against `resource.data.userId`
- Prevents users from accessing other users' data

### 2. Data Injection
- Type validation ensures fields are correct types
- Prevents malicious data from being stored

### 3. Mass Assignment
- Only specific fields can be written
- Prevents unauthorized field modifications

### 4. Unauthorized Reads
- All reads require authentication
- All reads require user ownership

### 5. Data Tampering
- userId cannot be changed after creation
- Email cannot be modified
- Timestamps are validated

## Testing

### Test Cases to Verify

1. ✅ Authenticated user can read their own data
2. ✅ Authenticated user cannot read other users' data
3. ✅ Unauthenticated user cannot access any data
4. ✅ User can create data with valid userId
5. ✅ User cannot create data with different userId
6. ✅ User can update their own data
7. ✅ User cannot update other users' data
8. ✅ User can delete their own data
9. ✅ User cannot delete other users' data
10. ✅ Invalid data types are rejected

## Monitoring

Monitor the following in Firebase Console:
- **Firestore Usage**: Track read/write operations
- **Security Rules**: Monitor rule evaluation failures
- **Authentication**: Track login patterns
- **Alerts**: Set up alerts for unusual access patterns

## Updates

When adding new collections:
1. Add rules following the same pattern
2. Include userId validation
3. Add timestamp validation
4. Test thoroughly
5. Update this documentation

