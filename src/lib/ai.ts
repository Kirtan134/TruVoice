import { GoogleGenAI } from "@google/genai";

// Validate API key
if (!process.env.GEMINI_API_KEY) {
  throw new Error("GEMINI_API_KEY environment variable is required");
}

// Initialize the Gemini AI client with API key
export const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

// Helper function to generate content with the new API
export async function generateContent(prompt: string) {
  return await ai.models.generateContent({
    model: "gemini-2.5-flash",
    contents: prompt,
  });
}

// Common prompts
export const AI_PROMPTS = {
  SUGGEST_MESSAGES: `Generate exactly 3 engaging, thoughtful questions for an anonymous messaging platform.

Requirements:
- Questions should be open-ended and spark meaningful conversations
- Suitable for all ages and backgrounds
- Avoid personal, sensitive, or controversial topics
- Focus on positive, creative, and fun themes
- Format: separate each question with '||' (no spaces around separator)

Examples of good questions:
- What's a skill you'd love to learn and why?
- If you could visit any place in the world, where would it be?
- What's something that always makes you smile?

Generate 3 new unique questions now:`,

  GENERATE_FEEDBACK: (
    context: string,
    tone: string
  ) => `Generate a thoughtful, constructive anonymous message for someone.

Context: ${context || "general feedback"}
Tone: ${tone || "encouraging"}

Requirements:
- Keep it anonymous and respectful
- Be specific and helpful
- Use a ${tone || "encouraging"} tone
- 1-2 sentences maximum
- Avoid generic compliments
- Focus on actionable or meaningful feedback

Generate one personalized message:`,
};

// Fallback responses when AI fails
export const FALLBACK_RESPONSES = {
  QUESTIONS: [
    "What's something you're passionate about?",
    "If you could time travel, which era would you visit?",
    "What's a random act of kindness you've witnessed?",
  ].join("||"),

  FEEDBACK: "You're doing great! Keep being yourself and stay positive.",
};
