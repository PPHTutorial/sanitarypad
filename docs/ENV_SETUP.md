# Environment Variables Setup

This project uses environment variables (similar to `.env` files in Node.js/Next.js) to store sensitive configuration like API keys.

## Quick Start

1. **Create `.env` file** in the project root (same directory as `pubspec.yaml`)

2. **Copy the template** from `.env.example` (if it exists):
   ```bash
   # On Windows (PowerShell)
   Copy-Item .env.example .env
   
   # On Mac/Linux
   cp .env.example .env
   ```
   
   Or create a new `.env` file manually.

3. **Edit `.env`** and add your actual API key:
   ```
   OPENAI_API_KEY=sk-your-actual-api-key-here
   ```

4. **Important Steps**:
   - The `.env` file is in `.gitignore` and will NOT be committed to git
   - The `.env` file must be listed in `pubspec.yaml` under `assets:` section (already done)
   - After creating/updating `.env`, run: `flutter pub get`
   - Restart your app for changes to take effect

## Available Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_API_KEY` | Yes | - | Your OpenAI API key (starts with `sk-`) |
| `OPENAI_API_BASE_URL` | No | `https://api.openai.com/v1` | OpenAI API base URL |
| `OPENAI_MODEL` | No | `gpt-3.5-turbo` | OpenAI model to use (can be `gpt-4` for better responses) |

## Example `.env` File

```env
# OpenAI API Configuration
OPENAI_API_KEY=sk-proj-abc123def456ghi789jkl012mno345pqr678stu901vwx234yz

# Optional: Custom API base URL
# OPENAI_API_BASE_URL=https://api.openai.com/v1

# Optional: Use GPT-4 for better responses (more expensive)
# OPENAI_MODEL=gpt-4
```

## Security Notes

1. **Never commit `.env` to version control** - it's already in `.gitignore`
2. **Never share your API key** publicly or in screenshots
3. **Use different keys** for development and production
4. **Set usage limits** on your OpenAI account to prevent unexpected charges
5. **Rotate keys** if they're accidentally exposed

## Troubleshooting

### App says "AI Assistant is not configured"

- Check that `.env` file exists in the project root
- Verify `OPENAI_API_KEY` is set (not empty, not the placeholder)
- Ensure there are no extra spaces or quotes around the key
- Restart the app after creating/updating `.env`

### API Key Not Loading

- Check console logs for errors when loading `.env`
- Verify the file is named exactly `.env` (not `.env.txt` or `.env.local`)
- Ensure the file is in the project root (same directory as `pubspec.yaml`)

## Production Deployment

For production builds, you may want to:

1. **Use CI/CD secrets** instead of `.env` files
2. **Inject environment variables** at build time
3. **Use a backend proxy** to hide the API key from the client entirely (most secure)

The current implementation loads `.env` at runtime, which works for development but consider a backend proxy for production to keep the key completely hidden from the client.

