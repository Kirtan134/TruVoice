import { GoogleGenAI } from "@google/genai";

// Initialize Google AI client
export const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || "", });

// Function to generate content using AI
export async function generateContent(prompt: string) {
  try {
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: prompt,
    });

    if (!response || !response.text) {
      throw new Error("No response generated from AI model");
    }

    return response.text.trim();
  } catch (error) {
    console.error("Error generating content:", error);
    throw error;
  }
}

// Fallback responses when AI fails
export const FALLBACK_RESPONSES = {
  QUESTIONS: [
    "What's something you're passionate about?",
    "If you could time travel, which era would you visit?",
    "What's a random act of kindness you've witnessed?",
  ].join("||"),

  FEEDBACK: "You're doing great! Keep being yourself and stay positive.",
};
