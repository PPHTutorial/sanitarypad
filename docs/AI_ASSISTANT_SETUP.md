# AI Assistant Setup Guide

The FemCare+ app includes an AI assistant powered by OpenAI's GPT models. This guide explains how to set up and use the feature.

## Features

- **Category-Specific Assistance**: Different AI assistants for Pregnancy, Fertility, and Skincare
- **Context-Aware**: The AI receives relevant context (e.g., pregnancy week, cycle day) for personalized responses
- **Chat History**: All conversations are saved and can be cleared
- **Centralized API Key**: One API key for all users, stored securely in environment variables (similar to .env in Node.js/Next.js)

## Developer Setup Instructions

### 1. Get an OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in to your account
3. Navigate to [API Keys](https://platform.openai.com/api-keys)
4. Click "Create new secret key"
5. Copy the API key (starts with `sk-`)

### 2. Configure Environment Variables

1. Copy `.env.example` to `.env` in the project root:
   ```bash
   cp .env.example .env
   ```

2. Open `.env` and replace `sk-your-api-key-here` with your actual OpenAI API key:
   ```
   OPENAI_API_KEY=sk-your-actual-api-key-here
   ```

3. **Important**: The `.env` file is already in `.gitignore` and will NOT be committed to version control.

4. Optional: Configure additional settings:
   ```
   OPENAI_API_BASE_URL=https://api.openai.com/v1  # Default if not set
   OPENAI_MODEL=gpt-3.5-turbo                     # Default if not set (can use gpt-4)
   ```

### 3. Run the App

The app will automatically load the `.env` file on startup. The API key will be available to all users without them needing to configure anything.

## User Usage

### Accessing the AI Assistant

- **Pregnancy**: Go to Pregnancy Tracking → Insights tab → "Open AI assistant"
- **Fertility**: Go to Fertility Tracking → Overview tab → "AI Fertility Assistant" (coming soon)
- **Skincare**: Go to Skincare Tracking → Insights tab → "AI Dermatologist Assistant" (coming soon)

### Chat Features

- **Send Messages**: Type your question and tap the send button
- **View History**: All previous messages are displayed in chronological order
- **Clear History**: Tap the delete icon (🗑️) in the app bar to clear all messages

**Note**: Users do NOT need to configure API keys. The key is managed by developers and stored securely in the app.

## Technical Details

### Models Used

- Default: `gpt-3.5-turbo` (cost-effective, fast)
- Can be upgraded to `gpt-4` for better responses (modify in `ai_service.dart`)

### Context System

The AI receives:
- **System Prompt**: Category-specific instructions (pregnancy, fertility, skincare)
- **User Context**: Relevant data like pregnancy week, cycle day, etc.
- **Conversation History**: Last 10 messages for context

### Data Storage

- **Messages**: Stored in Firestore collection `aiChatMessages`
- **API Key**: Stored in `.env` file (not committed to git, loaded at runtime)
- **Privacy**: All messages are user-specific and isolated by `userId`

## Cost Considerations

OpenAI API usage is charged per token:
- **Input tokens**: ~$0.0015 per 1K tokens (gpt-3.5-turbo)
- **Output tokens**: ~$0.002 per 1K tokens (gpt-3.5-turbo)
- Average conversation: ~500-1000 tokens per exchange

**Recommendation**: Monitor your usage on the OpenAI dashboard to avoid unexpected charges.

## Security Best Practices

1. **Never commit API keys** to version control
2. **Use environment variables** for production deployments
3. **Rotate keys regularly** if exposed
4. **Set usage limits** on your OpenAI account
5. **Monitor API usage** through OpenAI dashboard

## Troubleshooting

### "AI Assistant is not configured"
- **For Developers**: Check that `.env` file exists in the project root
- Verify `OPENAI_API_KEY` is set in `.env` file
- Ensure the key is not the placeholder value `sk-your-api-key-here`
- Restart the app after adding/updating `.env` file

### "Invalid API key" or API Errors
- Verify the key is correct in `.env` (no extra spaces, quotes, etc.)
- Check if the key is active on OpenAI platform
- Ensure you have credits in your OpenAI account
- Check the console logs for detailed error messages

### "Network error"
- Check your internet connection
- Verify OpenAI API is accessible
- Check if your API key has rate limits

### "Failed to get AI response"
- Check your OpenAI account balance
- Verify API key permissions
- Check OpenAI status page for outages

## Future Enhancements

- [ ] Support for other AI providers (Anthropic Claude, Google Gemini)
- [ ] Voice input/output
- [ ] Image analysis for skincare
- [ ] Conversation export
- [ ] Predefined prompts/templates
- [ ] Multi-language support

