import { GoogleGenAI } from "@google/genai";
import { NextResponse } from "next/server";

export const runtime = "edge";

export async function POST(req: Request) {
  try {
    // Validate API key
    if (!process.env.GEMINI_API_KEY) {
      return new NextResponse(
        JSON.stringify({ error: "Gemini API key not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Initialize the Gemini AI client with API key
    const ai = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
    });

    const { message, action } = await req.json();

    let prompt;

    if (action === "refine" && message) {
      // Refine existing message
      prompt = `Refine and improve this anonymous message while keeping its core intent:

Original message: "${message}"

Requirements:
- Keep the same meaning and intent
- Make it more thoughtful and well-structured
- Ensure it's respectful and appropriate
- Improve clarity and impact
- Keep it concise (1-3 sentences)
- Maintain anonymous tone

Refined message:`;
    } else {
      // Generate new message (fallback)
      prompt = `Generate a thoughtful, constructive anonymous message for someone.

Requirements:
- Keep it anonymous and respectful
- Be meaningful and engaging
- 1-2 sentences maximum
- Focus on positive communication
- Avoid generic compliments

Generate one personalized message:`;
    }

    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: prompt,
    });

    // Check if response is valid
    if (!response || !response.text) {
      throw new Error("No response generated from AI model");
    }

    const text = response.text.trim();

    return new NextResponse(JSON.stringify({ message: text }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error generating feedback:", error);

    // Provide fallback message if AI fails
    const fallbackMessage =
      "You're doing great! Keep being yourself and stay positive.";

    return new NextResponse(JSON.stringify({ message: fallbackMessage }), {
      headers: { "Content-Type": "application/json" },
    });
  }
}
