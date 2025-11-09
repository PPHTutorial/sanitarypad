# Firestore Rules Permission Fix

## Issue
Users were getting "the caller does not have permission to execute the specific operation" error when trying to login or signup.

## Root Cause
The Firestore security rules expected a `userId` field in the document data, but the `UserModel.toFirestore()` method was not including it. The rules were checking:
- `request.resource.data.userId == request.auth.uid` for creates
- `request.resource.data.userId == resource.data.userId` for updates

But since `userId` wasn't in the document data, these checks were failing.

## Solution

### 1. Added `userId` to User Document Data
Updated `UserModel.toFirestore()` to include `userId` in the document data:
```dart
Map<String, dynamic> toFirestore() {
  return {
    'userId': userId, // Now included for security rules
    'email': email,
    // ... other fields
  };
}
```

### 2. Updated Firestore Rules for Users Collection
Made the rules more flexible to handle:
- Document creation with `userId` field
- Partial updates (like `lastLoginAt`) without requiring all fields
- Backward compatibility with existing documents

### 3. Updated `fromFirestore` Method
Made it handle both cases:
- Documents with `userId` field (new format)
- Documents without `userId` field (backward compatibility, uses document ID)

## Testing

After deploying the updated rules:
1. **Signup**: Should create user document successfully
2. **Login**: Should update `lastLoginAt` successfully
3. **Read Profile**: Should read user document successfully

## Deployment

Deploy the updated rules:
```bash
firebase deploy --only firestore:rules
```

## Notes

- The `userId` field is now stored in the document data for consistency with other collections
- The document ID still matches the `userId` for easy lookups
- Rules allow partial updates (e.g., just updating `lastLoginAt`) without requiring all fields

