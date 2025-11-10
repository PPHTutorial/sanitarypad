# Quick Start: Adding Wellness Content

## Method 1: Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **sanitarypad**
3. Navigate to **Firestore Database**
4. Click **Start collection** (if `wellnessContent` doesn't exist) or click on `wellnessContent`
5. Click **Add document** (or **Add document** with auto-ID)

### Required Fields:

| Field | Type | Value | Example |
|-------|------|-------|---------|
| `title` | string | Required | "Stay Hydrated During Your Period" |
| `content` | string | Required | "Drinking plenty of water..." |
| `type` | string | Required | `"tip"`, `"article"`, or `"meditation"` |
| `createdAt` | timestamp | Required | Current date/time |
| `isPremium` | boolean | Optional (default: false) | `false` |
| `category` | string | Optional | `"menstrual_health"` |
| `tags` | array | Optional | `["hydration", "period"]` |
| `readTime` | number | Optional | `1` (minutes) |
| `imageUrl` | string | Optional | `"https://..."` |
| `updatedAt` | timestamp | Optional | Current date/time |

### Quick Examples:

#### Tip Example:
```
title: "Stay Hydrated"
content: "Drink 8-10 glasses of water daily during your period."
type: "tip"
category: "menstrual_health"
tags: ["hydration", "period"]
isPremium: false
readTime: 1
createdAt: [Now]
```

#### Article Example:
```
title: "Understanding Your Cycle"
content: "Your menstrual cycle typically lasts 28 days..."
type: "article"
category: "menstrual_health"
tags: ["cycle", "health"]
isPremium: false
readTime: 5
createdAt: [Now]
```

#### Meditation Example:
```
title: "5-Minute Pain Relief"
content: "Find a comfortable position. Close your eyes..."
type: "meditation"
category: "wellness"
tags: ["meditation", "relaxation"]
isPremium: false
readTime: 5
createdAt: [Now]
```

## Method 2: Using the Sample Script

1. Open `scripts/add_wellness_content.dart`
2. Review the sample content structure
3. Copy the data structure
4. Paste into Firebase Console as shown in Method 1

## Content Types

- **`tip`**: Short, actionable advice (1-2 min read)
- **`article`**: Longer-form educational content (3-10 min read)
- **`meditation`**: Guided meditation or breathing exercises (3-10 min)

## Categories (Optional but Recommended)

- `menstrual_health`
- `pregnancy`
- `fertility`
- `skincare`
- `wellness`
- `mental_health`
- `nutrition`
- `exercise`
- `hygiene`

## Testing

After adding content:
1. Run the app
2. Go to **Wellness** screen
3. Check tabs: **All**, **Tips**, **Articles**, **Meditation**
4. Content should appear in the correct tab based on `type` field

## Premium Content

Set `isPremium: true` to restrict content to premium subscribers only.

## Need More Examples?

See `docs/WELLNESS_CONTENT_SETUP.md` for detailed examples and best practices.

