# Firestore Security Rules - Complete Update

## ✅ All Collections Now Have Permissions

All collections defined in `app_constants.dart` now have proper Firestore security rules configured.

## 📋 Collections Added/Updated

### AI Chat Collections (NEW)
- ✅ `aiChatMessages` - User-specific chat messages
- ✅ `aiConversations` - User-specific conversation threads

### Pregnancy Enhanced Collections (NEW)
- ✅ `kickEntries` - Baby kick tracking
- ✅ `contractionEntries` - Contraction tracking
- ✅ `pregnancyAppointments` - Appointment scheduling
- ✅ `pregnancyMedications` - Medication tracking
- ✅ `pregnancyJournalEntries` - Journal entries
- ✅ `pregnancyWeightEntries` - Weight tracking
- ✅ `hospitalChecklistItems` - Hospital preparation checklist

### Fertility Enhanced Collections (NEW)
- ✅ `hormoneCycles` - Hormone cycle tracking
- ✅ `fertilitySymptoms` - Symptom logging
- ✅ `moodEnergyEntries` - Mood and energy tracking
- ✅ `fertilityMedications` - Medication tracking
- ✅ `intercourseEntries` - Intercourse logging
- ✅ `pregnancyTestEntries` - Pregnancy test results
- ✅ `healthRecommendations` - Health recommendations
- ✅ `ovulationTestReminders` - Ovulation test reminders

### Skincare Enhanced Collections (NEW)
- ✅ `skinTypes` - Skin type analysis
- ✅ `skinJournalEntries` - Daily skin journal
- ✅ `routineTemplates` - Skincare routine templates
- ✅ `ingredients` - Ingredient dictionary (shared read access)
- ✅ `acneEntries` - Acne tracking
- ✅ `uvIndexEntries` - UV index monitoring
- ✅ `skinGoals` - Skin goal tracking

### Community Collections (NEW)
- ✅ `groups` - Community groups (public read, admin-only edit)
- ✅ `groupMembers` - Group membership
- ✅ `events` - Community events (public read, organizer-only edit)
- ✅ `eventAttendees` - Event attendance

### Existing Collections (Verified)
- ✅ `users` - User profiles
- ✅ `cycles` - Menstrual cycles
- ✅ `cyclePredictions` - Cycle predictions
- ✅ `symptoms` - Symptom tracking
- ✅ `wellnessEntries` - Wellness journal
- ✅ `pads` - Pad usage tracking
- ✅ `padInventory` - Pad inventory
- ✅ `reminders` - Reminders
- ✅ `wellnessContent` - Wellness content (public read)
- ✅ `analytics` - Analytics data
- ✅ `subscriptions` - Subscription records
- ✅ `supportContacts` - Emergency contacts
- ✅ `redFlagAlerts` - Red flag alerts
- ✅ `pregnancies` - Pregnancy records
- ✅ `fertilityEntries` - Fertility entries
- ✅ `skincareEntries` - Skincare entries
- ✅ `skincareProducts` - Skincare products

## 🔒 Security Model

### User-Specific Collections
Most collections follow this pattern:
- **Read**: User must be authenticated and own the document (`resource.data.userId == request.auth.uid`)
- **Create**: User must be authenticated and set themselves as owner (`request.resource.data.userId == request.auth.uid`)
- **Update**: User must be authenticated and own the document
- **Delete**: User must be authenticated and own the document (except where audit trail is needed)

### Public Collections
- **wellnessContent**: All authenticated users can read/write
- **ingredients**: All authenticated users can read/write (shared ingredient dictionary)
- **groups**: All authenticated users can read, only admins can edit
- **events**: All authenticated users can read, only organizers can edit

### Special Rules
- **subscriptions**: Delete disabled (keep audit trail)
- **redFlagAlerts**: Delete disabled (keep records for safety)

## 🚀 Deployment

To deploy the updated rules:

```bash
firebase deploy --only firestore:rules
```

Or use the Firebase Console:
1. Go to Firebase Console → Firestore Database → Rules
2. Copy the contents of `firestore.rules`
3. Paste and click "Publish"

## ✅ Verification

After deployment, all collections should now work without permission errors. The rules ensure:
- Users can only access their own data
- All authenticated users can access public/shared collections
- Admins/organizers have special permissions for groups/events
- Audit trails are preserved where needed

## 📝 Notes

- All rules require authentication (`request.auth != null`)
- User ownership is verified via `userId` field in documents
- Helper functions (`isOwner`, `isResourceOwner`, `isNewResourceOwner`) make rules more maintainable
- Default deny rule at the end ensures no unauthorized access

