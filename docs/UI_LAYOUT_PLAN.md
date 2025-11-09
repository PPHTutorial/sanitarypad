# FemCare+ UI Layout Plan & Wireframes

## Design Principles
- Feminine, calming soft palette (lavender, nude pinks, neutrals)
- Smooth animations and friendly icons
- Emoji-based mood logging
- Motivational & supportive tone
- Inclusive for teens & adults
- Accessible design (WCAG 2.1 AA)

## Screen Structure

### 1. Onboarding Flow
**Screens:**
1. Welcome Screen
   - App logo/icon
   - Tagline: "Your trusted wellness companion"
   - "Get Started" button

2. Privacy & Security
   - Privacy explanation
   - Data encryption info
   - "I understand" checkbox + Continue

3. Account Setup
   - Optional: Create account or Continue anonymously
   - Email/Password or Google Sign-In
   - Skip option for anonymous mode

4. Initial Setup
   - Age range selection (for content filtering)
   - First period date (optional)
   - Cycle length (optional, can skip)
   - Notification preferences

### 2. Main Navigation (Bottom Navigation Bar)
**Tabs:**
- 🏠 Home
- 📅 Calendar
- 📊 Insights
- 💝 Wellness
- 👤 Profile

### 3. Home Screen
**Layout:**
```
┌─────────────────────────────┐
│  [App Bar: FemCare+]        │
│  [Notifications] [Settings] │
├─────────────────────────────┤
│  [Cycle Status Card]        │
│  - Current phase            │
│  - Days until period        │
│  - Quick stats              │
├─────────────────────────────┤
│  [Quick Actions]            │
│  [Log Period] [Log Symptom] │
│  [Pad Change] [Wellness]    │
├─────────────────────────────┤
│  [Today's Wellness]         │
│  - Mood tracker             │
│  - Hydration check          │
│  - Sleep log                │
├─────────────────────────────┤
│  [Upcoming Reminders]       │
│  - Pad change in 2h         │
│  - Period starts in 3 days  │
├─────────────────────────────┤
│  [Quick Tips]               │
│  - Cycle phase tip card     │
└─────────────────────────────┘
```

### 4. Calendar Screen
**Layout:**
```
┌─────────────────────────────┐
│  [Month/Year Selector]      │
│  [←] January 2024 [→]       │
├─────────────────────────────┤
│  [Calendar Grid]            │
│  S  M  T  W  T  F  S        │
│  1  2  3  4  5  6  7        │
│  8  9 10 11 12 13 14        │
│  [Period days highlighted]  │
│  [Ovulation marked]         │
│  [Symptoms icons]           │
├─────────────────────────────┤
│  [Selected Date Details]    │
│  - Period day 3             │
│  - Symptoms logged          │
│  - Pad changes              │
│  [Edit] [Add Entry]         │
└─────────────────────────────┘
```

### 5. Insights Screen
**Layout:**
```
┌─────────────────────────────┐
│  [Insights Header]          │
│  "Your Health Insights"      │
├─────────────────────────────┤
│  [Cycle Statistics]         │
│  - Avg cycle length         │
│  - Avg period length        │
│  - Regularity indicator     │
├─────────────────────────────┤
│  [Trend Charts]             │
│  [Cycle Length Chart]       │
│  [Symptom Frequency]        │
│  [Mood Trends]              │
├─────────────────────────────┤
│  [Pattern Recognition]      │
│  - "You often experience    │
│     cramps on day 2"        │
│  - "Your cycle is regular"  │
├─────────────────────────────┤
│  [Health Score]             │
│  [Progress Circle]          │
│  "Your wellness score: 85"  │
└─────────────────────────────┘
```

### 6. Wellness Screen
**Layout:**
```
┌─────────────────────────────┐
│  [Wellness Header]          │
│  [Search] [Filter]          │
├─────────────────────────────┤
│  [Categories Tabs]          │
│  [All] [Tips] [Meditation]  │
│  [Affirmations] [Articles]   │
├─────────────────────────────┤
│  [Content Cards]            │
│  ┌─────────────────────┐   │
│  │ [Image]               │   │
│  │ Title: "Self-care..." │   │
│  │ Category: Tips        │   │
│  │ [Premium Badge]       │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ [Audio Icon]         │   │
│  │ "Guided Meditation"  │   │
│  │ Duration: 10 min    │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

### 7. Profile Screen
**Layout:**
```
┌─────────────────────────────┐
│  [Profile Header]           │
│  [Avatar]                    │
│  User Name                   │
│  user@email.com              │
├─────────────────────────────┤
│  [Subscription Card]        │
│  [Premium Badge] or         │
│  [Upgrade to Premium]       │
├─────────────────────────────┤
│  [Settings Sections]       │
│  📊 Cycle Settings           │
│  🔔 Notifications            │
│  🔒 Privacy & Security       │
│  💾 Data Management          │
│  🆘 Emergency Contacts       │
│  📚 Help & Support           │
│  ℹ️ About                    │
├─────────────────────────────┤
│  [Account Actions]          │
│  [Sign Out]                  │
│  [Delete Account]            │
└─────────────────────────────┘
```

### 8. Log Period Screen
**Layout:**
```
┌─────────────────────────────┐
│  [Back] Log Period          │
├─────────────────────────────┤
│  [Date Picker]              │
│  Start Date: [Select]       │
│  End Date: [Select]         │
├─────────────────────────────┤
│  Flow Intensity             │
│  [Light] [Medium] [Heavy]   │
├─────────────────────────────┤
│  Symptoms                   │
│  [Cramps] [Headache]        │
│  [Fatigue] [Bloating]       │
│  [+ Add More]                │
├─────────────────────────────┤
│  Mood                       │
│  [Emoji Picker] 😊 😢 😡   │
├─────────────────────────────┤
│  Notes (Optional)           │
│  [Text Input]               │
├─────────────────────────────┤
│  [Save Entry]               │
└─────────────────────────────┘
```

### 9. Pad Management Screen
**Layout:**
```
┌─────────────────────────────┐
│  [Back] Pad Management       │
├─────────────────────────────┤
│  [Current Stock]            │
│  Light: 15 pads             │
│  Regular: 8 pads [Low!]     │
│  Super: 20 pads             │
│  [Add Stock]                 │
├─────────────────────────────┤
│  [Log Pad Change]           │
│  Time: [Now]                 │
│  Type: [Select]             │
│  Flow: [Light/Med/Heavy]    │
│  [Save]                      │
├─────────────────────────────┤
│  [Recent Changes]           │
│  Today 2:30 PM - Regular    │
│  Today 8:00 AM - Super      │
│  Yesterday 10:00 PM - Light │
├─────────────────────────────┤
│  [Reminders]                │
│  [Configure Reminders]      │
└─────────────────────────────┘
```

### 10. Wellness Journal Screen
**Layout:**
```
┌─────────────────────────────┐
│  [Back] Wellness Journal    │
├─────────────────────────────┤
│  [Date Selector]            │
├─────────────────────────────┤
│  [Mood Tracker]             │
│  How are you feeling?        │
│  [Emoji Grid]                │
├─────────────────────────────┤
│  [Hydration]                │
│  [Water Drop Icons]         │
│  6/8 glasses                 │
├─────────────────────────────┤
│  [Sleep]                    │
│  Hours: [Slider]             │
│  Quality: [Stars]            │
├─────────────────────────────┤
│  [Appetite]                 │
│  [Low] [Normal] [High]      │
├─────────────────────────────┤
│  [Journal Entry]            │
│  [Text Area]                │
├─────────────────────────────┤
│  [Save Entry]               │
└─────────────────────────────┘
```

## Component Library

### Buttons
- Primary: Pink filled, rounded corners
- Secondary: Outlined pink
- Text: Pink text button
- Icon: Circular with icon

### Cards
- Elevated cards with rounded corners (16px)
- Soft shadows
- Pink accent borders for important cards

### Input Fields
- Rounded text fields
- Pink focus border
- Helper text below
- Error states in red

### Icons
- Material Icons with custom pink theme
- Emoji support for mood tracking
- Custom illustrations for cycle phases

### Typography
- Font: Red Hat Display
- Headings: Bold, various sizes
- Body: Regular weight
- Labels: Medium weight

## Color Palette
- Primary Pink: #E91E63
- Light Pink: #F8BBD0
- Lavender: #E1BEE7
- Background: Warm white / Dark gray
- Text: Dark gray / White
- Accents: Coral, Rose

## Animations
- Page transitions: Slide and fade
- Button presses: Scale animation
- Card interactions: Subtle lift
- Loading states: Skeleton screens

## Responsive Breakpoints
- Mobile: < 600px (primary)
- Tablet: 600px - 1024px
- Desktop: > 1024px (web version)

