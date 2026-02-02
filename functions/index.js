const functions = require("firebase-functions");
const admin = require("firebase-admin");
const OpenAI = require("openai");

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
      return `${basePrompt} Focus on skincare routines, ingredient analysis, skin health evaluation, and personalized skincare advice. Provide clear explanations of skincare ingredients, their functions, compatibility, and potential interactions. Consider common dermatological conditions and how ingredients or routines may affect them. Account for medication use (topical or oral) such as retinoids, antibiotics, hormonal treatments, and acne therapies, and provide safe, evidence-based guidance without giving medical prescriptions. Prioritize safety, sensitivity awareness, patch-test recommendations, and ingredient contraindications for pregnant or breastfeeding users. Then return an object with keys; name, scientificName, category, description, benefits, concerns, comedogenicRating, irritationRating, goodFor, avoidWith`;


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
