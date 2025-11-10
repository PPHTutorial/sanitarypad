# Wellness Content Setup Guide

This guide explains how to populate wellness content (tips, articles, and meditation) in the FemCare+ app.

## Overview

Wellness content is stored in Firestore under the `wellnessContent` collection. The app displays this content in the Wellness Screen under three tabs:
- **All**: Shows all content types
- **Tips**: Shows content with `type: 'tip'`
- **Articles**: Shows content with `type: 'article'`
- **Meditation**: Shows content with `type: 'meditation'`

## Data Structure

Each wellness content document should have the following structure:

```json
{
  "title": "String (required)",
  "content": "String (required) - Can be HTML or plain text",
  "type": "String (required) - Must be one of: 'tip', 'article', 'meditation'",
  "category": "String (optional) - e.g., 'menstrual_health', 'pregnancy', 'skincare'",
  "imageUrl": "String (optional) - URL to an image",
  "tags": ["Array of strings (optional)"],
  "isPremium": "Boolean (default: false) - If true, only premium users can access",
  "readTime": "Number (optional) - Reading time in minutes",
  "createdAt": "Timestamp (required)",
  "updatedAt": "Timestamp (optional)"
}
```

## Content Types

Based on `AppConstants`, the valid content types are:
- `tip` - Quick wellness tips
- `article` - Longer-form articles
- `meditation` - Meditation guides or content
- `affirmation` - Positive affirmations (optional)
- `myth_fact` - Myth vs fact content (optional)

## Adding Content via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **sanitarypad**
3. Navigate to **Firestore Database**
4. Click on the `wellnessContent` collection (or create it if it doesn't exist)
5. Click **Add document**
6. Add the following fields:

### Example: Tip
```
title: "Stay Hydrated During Your Period"
content: "Drinking plenty of water can help reduce bloating and ease menstrual cramps. Aim for 8-10 glasses per day."
type: "tip"
category: "menstrual_health"
tags: ["hydration", "period", "health"]
isPremium: false
readTime: 1
createdAt: [Current Timestamp]
```

### Example: Article
```
title: "Understanding Your Menstrual Cycle"
content: "Your menstrual cycle is a complex process that prepares your body for pregnancy each month. It typically lasts 28 days, but can range from 21 to 35 days. The cycle consists of four main phases: menstrual, follicular, ovulation, and luteal. Understanding these phases can help you track your fertility, manage symptoms, and maintain better overall health."
type: "article"
category: "menstrual_health"
tags: ["cycle", "menstruation", "health"]
isPremium: false
readTime: 5
createdAt: [Current Timestamp]
```

### Example: Meditation
```
title: "5-Minute Period Pain Relief Meditation"
content: "Find a comfortable position. Close your eyes and take three deep breaths. Focus on your breath, inhaling slowly through your nose and exhaling through your mouth. As you breathe, visualize tension leaving your body with each exhale. If you experience pain, acknowledge it without judgment, then gently redirect your attention to your breath. Continue for 5 minutes."
type: "meditation"
category: "wellness"
tags: ["meditation", "pain_relief", "relaxation"]
isPremium: false
readTime: 5
createdAt: [Current Timestamp]
```

## Adding Content via Script

You can also use the provided Dart script to add content programmatically. See `scripts/add_wellness_content.dart` for details.

## Firestore Security Rules

The current Firestore rules allow:
- **Read**: All authenticated users can read wellness content
- **Create/Update/Delete**: Only admins (via Firebase Admin SDK or Console)

This ensures content integrity while allowing all users to access the content.

## Categories Suggestions

- `menstrual_health`
- `pregnancy`
- `fertility`
- `skincare`
- `wellness`
- `mental_health`
- `nutrition`
- `exercise`
- `hygiene`

## Tags Suggestions

- `period`, `menstruation`, `cycle`
- `pregnancy`, `fertility`
- `skincare`, `beauty`
- `health`, `wellness`
- `mental_health`, `self_care`
- `nutrition`, `diet`
- `exercise`, `fitness`
- `hygiene`, `cleanliness`

## Premium Content

Set `isPremium: true` for exclusive content that requires a premium subscription. The app will show a premium badge and restrict access for free users.

## Best Practices

1. **Title**: Keep titles concise and descriptive (50-100 characters)
2. **Content**: Use clear, easy-to-read language. HTML formatting is supported.
3. **Read Time**: Calculate based on average reading speed (200-250 words per minute)
4. **Images**: Use high-quality images with appropriate aspect ratios
5. **Tags**: Use 3-5 relevant tags for better discoverability
6. **Categories**: Use consistent category names across all content

## Testing

After adding content:
1. Run the app
2. Navigate to the Wellness Screen
3. Check that content appears in the correct tabs
4. Verify premium content restrictions work correctly
5. Test content detail screen navigation

