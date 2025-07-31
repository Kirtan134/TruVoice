import { GoogleGenAI } from "@google/genai";
import { NextResponse } from "next/server";

export const runtime = "edge";

export async function POST(req: Request) {
  try {
    const ai = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
    });

    const prompt = `Generate exactly 3 engaging, thoughtful questions for an anonymous messaging platform.

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

Generate 3 new unique questions now:`;

    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: prompt,
    });

    // Check if response is valid
    if (!response || !response.text) {
      throw new Error("No response generated from AI model");
    }

    const text = response.text.trim();

    // Validate that we got questions in the right format
    const questions = text.split("||");
    if (questions.length < 2) {
      // Fallback to default questions if AI response is malformed
      const fallbackQuestions = [
        "What's a book or movie that changed your perspective?",
        "If you could have any superpower for a day, what would it be?",
        "What's the best advice you've ever received?",
      ].join("||");

      return new NextResponse(fallbackQuestions);
    }

    return new NextResponse(text);
  } catch (error) {
    console.error("Error generating suggested messages:", error);

    // Provide fallback questions if AI fails
    const fallbackQuestions = [
      "What's something you're passionate about?",
      "If you could time travel, which era would you visit?",
      "What's a random act of kindness you've witnessed?",
    ].join("||");

    return new NextResponse(fallbackQuestions);
  }
}
