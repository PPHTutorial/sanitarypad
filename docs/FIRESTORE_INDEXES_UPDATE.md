# Firestore Indexes - Complete Update

## ✅ All Required Indexes Added

All composite indexes required for Firestore queries have been added to `firestore.indexes.json`.

## 📋 Indexes by Collection

### AI Chat Collections
- ✅ `aiChatMessages`: userId + category + timestamp (ASC)
- ✅ `aiConversations`: userId + category + updatedAt (DESC)

### Pregnancy Enhanced Collections
- ✅ `kickEntries`: userId + pregnancyId + loggedAt (DESC)
- ✅ `contractionEntries`: userId + pregnancyId + startTime (DESC)
- ✅ `pregnancyAppointments`: userId + pregnancyId + scheduledDate (ASC)
- ✅ `pregnancyMedications`: userId + pregnancyId + startDate (DESC)
- ✅ `pregnancyJournalEntries`: userId + pregnancyId + date (DESC)
- ✅ `pregnancyWeightEntries`: userId + pregnancyId + date (DESC)
- ✅ `hospitalChecklistItems`: userId + pregnancyId + category (ASC)

### Fertility Enhanced Collections
- ✅ `fertilityMedications`: userId + isActive + startDate (DESC)
- ✅ `intercourseEntries`: userId + date (DESC)
- ✅ `pregnancyTestEntries`: userId + date (DESC)
- ✅ `healthRecommendations`: userId + createdAt (DESC)

### Skincare Enhanced Collections
- ✅ `skinJournalEntries`: userId + date (DESC)

### Community Collections
- ✅ `groups`: category + isPublic + createdAt (DESC)
- ✅ `groups`: isPublic + createdAt (DESC)
- ✅ `groupMembers`: groupId + userId
- ✅ `groupMembers`: userId
- ✅ `events`: category + startDate (ASC)
- ✅ `events`: startDate (ASC)
- ✅ `eventAttendees`: eventId + userId
- ✅ `eventAttendees`: userId + status
- ✅ `eventAttendees`: eventId + userId + status

### Existing Collections (Verified)
- ✅ `cycles`: userId + startDate (DESC)
- ✅ `symptoms`: userId + date (DESC)
- ✅ `wellnessEntries`: userId + date (DESC)
- ✅ `pads`: userId + changeTime (DESC)
- ✅ `reminders`: userId + enabled
- ✅ `fertilityEntries`: userId + date (DESC/ASC)
- ✅ `redFlagAlerts`: userId + detectedAt (DESC)
- ✅ `wellnessContent`: Multiple indexes for filtering
- ✅ `skincareEntries`: userId + date (DESC)
- ✅ `skincareProducts`: isActive + userId + createdAt (DESC)
- ✅ `pregnancies`: userId + createdAt (DESC)
- ✅ `supportContacts`: userId + isPrimary (DESC) + name (ASC)

## 🚀 Deployment

To deploy the indexes:

```bash
firebase deploy --only firestore:indexes
```

Or use the Firebase Console:
1. Go to Firebase Console → Firestore Database → Indexes
2. The indexes will be automatically created when queries are made
3. Or manually create them using the error links provided by Firestore

## ⏱️ Index Creation Time

- **Simple indexes**: Usually ready within minutes
- **Complex indexes**: May take 10-30 minutes depending on data volume
- **Status**: Check Firebase Console → Firestore → Indexes tab

## 📝 Notes

- Indexes are created automatically when queries are made (if auto-indexing is enabled)
- For production, it's better to deploy indexes before queries are made
- Some queries with range filters (>=, <=) require special index configurations
- All indexes use `COLLECTION` scope (not collection group)

## ✅ Verification

After deployment, all queries should work without "index required" errors. The indexes ensure:
- Fast query performance
- Support for complex filtering and sorting
- Efficient data retrieval across all collections

