# Quick Fix: .env Not Loading

If your `.env` file is not loading, follow these steps:

## Step 1: Create .env File

Create a file named `.env` in the project root (same directory as `pubspec.yaml`):

**Windows (PowerShell):**
```powershell
New-Item -Path .env -ItemType File
```

**Mac/Linux:**
```bash
touch .env
```

## Step 2: Add Your API Key

Open `.env` and add:
```
OPENAI_API_KEY=sk-your-actual-api-key-here
```

Replace `sk-your-actual-api-key-here` with your real OpenAI API key.

## Step 3: Verify pubspec.yaml

Ensure `.env` is listed in the assets section of `pubspec.yaml`:
```yaml
assets:
  - .env
```

## Step 4: Run Flutter Commands

```bash
flutter pub get
flutter clean
flutter pub get
```

## Step 5: Restart the App

Completely stop and restart your Flutter app.

## Verification

When the app starts, you should see in the console:
```
✓ Environment variables loaded successfully
```

If you see warnings, check:
1. `.env` file exists in project root
2. File contains `OPENAI_API_KEY=sk-...` (not placeholder)
3. No extra spaces or quotes around the key
4. `.env` is in `pubspec.yaml` assets
5. You ran `flutter pub get` after creating `.env`

## Still Not Working?

1. Check console logs for specific error messages
2. Verify the `.env` file is exactly named `.env` (not `.env.txt`)
3. Ensure the file is in the project root, not in a subdirectory
4. Try deleting `.env` and recreating it
5. Check that `flutter_dotenv` package is installed: `flutter pub get`

