import { NextResponse } from 'next/server';
const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash"});
export const runtime = 'edge';

export async function POST(req: Request) {
  try {
    // Add random seed and timestamp for more variety
    const timestamp = new Date().toISOString();
    const randomSeed = Math.floor(Math.random() * 10000);
    
    const prompt =
      `Create a list of three COMPLETELY DIFFERENT, original, open-ended and engaging questions. Format as a single string with questions separated by '||'. 
      
      These questions are for an anonymous social messaging platform and should be suitable for diverse audiences. Avoid personal or sensitive topics. 
      
      Focus on universal themes that encourage friendly interaction. DO NOT reuse questions you've generated before.
      
      Output format example: 'What's a hobby you've recently started?||If you could have dinner with any historical figure, who would it be?||What's a simple thing that makes you happy?'
      
      Make questions intriguing, curious, and positive. Random seed: ${randomSeed}. Current time: ${timestamp}`;
    
    const result = await model.generateContent({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 1.0,  // Maximum randomness
        topP: 0.98,
        topK: 50,
        seed: randomSeed
      }
    });
    
    const response = result.response;
    const text = response.text();
    
    // Add cache control headers to prevent caching
    return new NextResponse(text, {
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0'
      }
    });
  } catch (error) {
    console.error('An unexpected error occurred:', error);
    return new NextResponse(
      JSON.stringify({
        error: 'An unexpected error occurred',
        details: error instanceof Error ? error.message : 'Unknown error',
      }),
      { status: 500 }
    );
  }
}