const functions = require("firebase-functions");
const admin = require("firebase-admin");
const OpenAI = require("openai");
const axios = require("axios");

admin.initializeApp();

const defaultModel = "gpt-3.5-turbo";

/**
 * Validates request authentication
 */
const validateAuth = (context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }
  return context.auth.uid;
};

/**
 * Builds the system prompt based on category and context
 */
const buildSystemPrompt = (category, context) => {
  const basePrompt =
    "You are FemCare+, a compassionate and knowledgeable AI assistant specialized in women's health, wellness, and self-care. You provide evidence-based, supportive, and empathetic guidance. Always remind users to consult healthcare professionals for medical concerns. No extra text or comments should be returned except the required response only.";

  switch (category) {
    case "pregnancy":
      const week = context && context.pregnancyWeek ? context.pregnancyWeek : null;
      const weekInfo = week
        ? ` The user is currently at week ${week} of pregnancy.`
        : "";
      return `${basePrompt}${weekInfo} Focus on pregnancy-related questions, prenatal care, fetal development, nutrition, and emotional support during pregnancy.`;

    case "fertility":
      return `${basePrompt} Focus on fertility tracking, ovulation, cycle health, conception tips, and reproductive wellness.`;

    case "skincare":
      return `${basePrompt} Focus on skincare routines, ingredient analysis, skin health, and personalized skincare advice.`;

    case 'dermatologist':
      return `${basePrompt} Focus on dermatologist-level skincare routines, ingredient analysis, skin health evaluation, and personalized recommendations. Provide clear, evidence-based explanations of skincare ingredients, their functions, benefits, safety profiles, and potential interactions. Always consider dermatological conditions such as acne, hyperpigmentation, eczema, rosacea, sensitivity, and barrier impairment. Account for topical and oral medications (e.g., retinoids, benzoyl peroxide, antibiotics, azelaic acid, hormonal treatments)and provide safe compatibility guidance without giving medical prescriptions. Highlight contraindications, ingredient conflicts, over-exfoliation risks, and pregnancy/breastfeeding considerations. Prioritize user safety, patch testing, gentle options, barrier support, and conservative recommendations. Do not diagnose but offer supportive dermatologist-informed insights based on provided information.`;

    case 'ingredient':
      return `${basePrompt} Focus on skincare routines, ingredient analysis, skin health evaluation, and personalized skincare advice. Provide clear explanations of skincare ingredients, their functions, compatibility, and potential interactions. Consider common dermatological conditions and how ingredients or routines may affect them. Account for medication use (topical or oral) such as retinoids, antibiotics, hormonal treatments, and acne therapies, and provide safe, evidence-based guidance without giving medical prescriptions. Prioritize safety, sensitivity awareness, patch-test recommendations, and ingredient contraindications for pregnant or breastfeeding users. 
      IMPORTANT: You must return the analysis as a raw JSON object string (no markdown blocks) containing exactly these keys: "name", "scientificName", "category", "description", "benefits", "concerns", "comedogenicRating", "irritationRating", "goodFor" (array), "avoidWith" (array). If information is unknown, use an empty string or empty array.`;


    case "wellness":
      return `${basePrompt} You are an expert wellness content creator for the FemCare+ application. Your goal is to write highly relevant, compassionate, and evidence-based content specifically for women's health, menstrual wellness, pregnancy, and self-care. Do NOT create general content; instead, tailor every response to the unique context of female physiology and emotional health. Focus on the user's specific request while maintaining a supportive and professional tone. Always include a disclaimer to consult a healthcare professional.`;

    default:
      return `${basePrompt} Provide general wellness, pregnancy, skincare, fertility and health guidance.`;
  }
};

/**
 * Cloud Function to generate AI response
 */
exports.generateAIResponse = functions.https.onCall(async (data, context) => {
  const userId = validateAuth(context);

  // Get OpenAI API key from environment variables
  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "OpenAI API key not configured."
    );
  }

  const openai = new OpenAI({ apiKey: apiKey });

  const { category, message, conversationHistory, userContext } = data;

  if (!message) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a 'message' argument."
    );
  }

  try {
    // Build messages list
    const messages = [];

    // System prompt
    const systemPrompt = buildSystemPrompt(category, userContext);
    messages.push({ role: "system", content: systemPrompt });

    // History (limit to last 10)
    if (conversationHistory && Array.isArray(conversationHistory)) {
      const recentHistory = conversationHistory.slice(-10);
      for (const msg of recentHistory) {
        if (msg.role && msg.content) {
          messages.push({ role: msg.role, content: msg.content });
        }
      }
    }

    // User message
    messages.push({ role: "user", content: message });

    // Call OpenAI
    const completion = await openai.chat.completions.create({
      messages: messages,
      model: defaultModel,
      temperature: 0.7,
      max_tokens: 500,
    });

    return {
      response: completion.choices[0].message.content.trim(),
    };
  } catch (error) {
    console.error("OpenAI Error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to process AI request.",
      error.message
    );
  }
});

/**
 * Syncs subscription data to the user document to ensure consistency across the app.
 * This is critical for usage tracking (credits) and tier status.
 */
exports.syncSubscriptionToUser = functions.firestore
  .document("subscriptions/{userId}")
  .onWrite(async (change, context) => {
    const userId = context.params.userId;
    const db = admin.firestore();

    // If the document was deleted
    if (!change.after.exists) {
      console.log(`Subscription for user ${userId} was deleted. Resetting to free/expired.`);
      try {
        await db.collection("users").doc(userId).set(
          {
            subscription: {
              tier: "free",
              status: "expired",
              dailyCreditsRemaining: 3.0, // Default free credits
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
          },
          { merge: true }
        );
      } catch (error) {
        console.error(`Error resetting subscription for user ${userId}:`, error);
      }
      return;
    }

    // If the document was created or updated
    const newSubscriptionData = change.after.data();
    console.log(`Syncing subscription for user ${userId}. Tier: ${newSubscriptionData.tier}`);

    try {
      await db.collection("users").doc(userId).set(
        {
          subscription: newSubscriptionData,
        },
        { merge: true }
      );
    } catch (error) {
      console.error(`Error syncing subscription for user ${userId}:`, error);
    }
  });

/**
 * Cloud Function to generate specialized wellness content
 */
exports.generateWellnessContent = functions.https.onCall(async (data, context) => {
  const userId = validateAuth(context);
  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey) {
    throw new functions.https.HttpsError("failed-precondition", "OpenAI API key not configured.");
  }

  const openai = new OpenAI({ apiKey: apiKey });
  const { title, type, category, tags } = data;

  if (!title || !type) {
    throw new functions.https.HttpsError("invalid-argument", "The function must be called with 'title' and 'type' arguments.");
  }

  try {
    const systemPrompt = buildSystemPrompt("wellness", { category });

    // User message tailoring the request
    const userMessage = `Generate a high-quality ${type} titled "${title}"${category ? ` in the category of ${category}` : ""}.${tags ? ` Include themes related to: ${tags.join(", ")}.` : ""} 
    Focus on being compassionate, evidence-based, and specifically for women's health. 
    Format the response as a JSON object with two keys: "content" (the full article/tip text) and "suggestedTags" (an array of strings). 
    Do not return any other text, only the JSON object.`;

    const completion = await openai.chat.completions.create({
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userMessage }
      ],
      model: defaultModel,
      temperature: 0.7,
      max_tokens: 1500,
      response_format: { type: "json_object" }
    });

    const result = JSON.parse(completion.choices[0].message.content);

    return {
      content: result.content,
      suggestedTags: result.suggestedTags,
    };
  } catch (error) {
    console.error("OpenAI Error:", error);
    throw new functions.https.HttpsError("internal", "Failed to generate wellness content.", error.message);
  }
});

/**
 * Cloud Function to analyze skin image using GPT-4o
 */
exports.analyzeSkinImage = functions.https.onCall(async (data, context) => {
  const userId = validateAuth(context);
  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey) {
    throw new functions.https.HttpsError("failed-precondition", "OpenAI API key not configured.");
  }

  const { imageUrl } = data;
  if (!imageUrl) {
    throw new functions.https.HttpsError("invalid-argument", "The function must be called with an 'imageUrl' argument.");
  }

  const openai = new OpenAI({ apiKey: apiKey });

  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "system",
          content: "You are a professional Dermatologist AI. Analyze the provided image and return a detailed report in JSON format."
        },
        {
          role: "user",
          content: [
            {
              type: "text",
              text: `Analyze this facial skin image for 12 key criteria. For each criteria, provide a score (0-100, where 100 is perfect/no concern) and a normalized bounding box [x1, y1, x2, y2] (0-1.0) of the most affected region.
              
              Criteria: Wrinkles, Acne/Blemishes, Oiliness, Texture, Redness, Dark Spots, Dark Circles, Hydration, Elasticity, Pore Size, Sensitivity, Sun Damage.
              
              Return a JSON object with:
              - "overallScore": A string describing general health (e.g., "Good", "Needs Care")
              - "criteriaScores": { "Wrinkles": 85, ... }
              - "regionData": { "Wrinkles": [0.2, 0.3, 0.4, 0.5], ... }
              - "identifiedConcerns": ["Concern 1", ...]
              - "recommendedRemedies": ["Remedy 1", ...]
              - "recommendedProducts": ["Product Category 1", ...]
              - "precautions": ["Precaution 1", ...]
              - "routineRecommendations": ["Morning Step 1", ...]
              - "notes": "General overview of the analysis."`
            },
            {
              type: "image_url",
              image_url: { url: imageUrl }
            }
          ]
        }
      ],
      max_tokens: 1500,
      response_format: { type: "json_object" }
    });

    const analysisResult = JSON.parse(response.choices[0].message.content);
    return analysisResult;
  } catch (error) {
    console.error("GPT-4o Skin Analysis Error:", error);
    throw new functions.https.HttpsError("internal", "Failed to analyze skin image.", error.message);
  }
});


