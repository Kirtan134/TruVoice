import { GoogleGenAI } from "@google/genai";
import { NextResponse } from "next/server";

export const runtime = "edge";

export async function POST(req: Request) {
  try {
    // Check if API key exists
    if (!process.env.GEMINI_API_KEY) {
      return NextResponse.json(
        { error: "Gemini API key not configured" },
        { status: 500 }
      );
    }

    // Get the message from request
    const { message } = await req.json();

    if (!message) {
      return NextResponse.json(
        { error: "Message is required" },
        { status: 400 }
      );
    }

    // Initialize AI client
    const ai = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
    });

    // Create prompt for refining the message
    const prompt = `Refine and improve this anonymous message while keeping its core intent:

Original message: "${message}"

Requirements:
- Keep the same meaning and intent
- Make it more thoughtful and well-structured
- Ensure it's respectful and appropriate
- Improve clarity and impact
- Keep it concise (1-3 sentences)
- Maintain anonymous tone

Refined message:`;

    // Generate refined message
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: prompt,
    });

    if (!response || !response.text) {
      throw new Error("No response generated from AI model");
    }

    const refinedMessage = response.text.trim();

    return NextResponse.json({
      success: true,
      message: refinedMessage,
    });
  } catch (error) {
    console.error("Error refining message:", error);
    return NextResponse.json(
      {
        success: false,
        error: "Failed to refine message. Please try again.",
      },
      { status: 500 }
    );
  }
}
