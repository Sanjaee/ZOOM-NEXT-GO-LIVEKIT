import type { NextApiRequest, NextApiResponse } from "next";
import { request } from "undici";

const KOLOSAL_API_URL = "https://api.kolosal.ai/v1/chat/completions";

function getKolosalApiKey(): string {
  // In Next.js standalone mode, process.env is available at runtime
  const apiKey = "kol_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZDE0OWZkY2MtMTRhOS00MzYwLWI3YWQtY2IxMzhmODk5MGYwIiwia2V5X2lkIjoiZGFhY2I3MGYtY2FjOS00ZDg1LTgyYjYtMzVlOTEwN2I1ZmRhIiwia2V5X25hbWUiOiJ0ZXN0IiwiZW1haWwiOiJhZnJpemFhaG1hZDE4QGdtYWlsLmNvbSIsInJhdGVfbGltaXRfcnBzIjpudWxsLCJtYXhfY3JlZGl0X3VzZSI6MTAsImNyZWF0ZWRfYXQiOjE3NjQ1MTU3NDksImV4cGlyZXNfYXQiOjE3OTYwNTE3NDksImlhdCI6MTc2NDUxNTc0OX0.FJohjYxWBeeKm2XSl3zrZHA3_PyOQFbTD9iQSsZiW_M";
  
  if (!apiKey) {
    // Log available env vars for debugging
    const envKeys = Object.keys(process.env || {}).filter(key => 
      key.includes('KOLOSAL') || key.includes('API')
    );
    console.error("Chat: NEXT_PUBLIC_KOLOSAL_API_KEY not found. Available env keys:", envKeys);
    throw new Error("NEXT_PUBLIC_KOLOSAL_API_KEY environment variable is not set");
  }
  
  return `Bearer ${apiKey}`;
}

type ChatMessage = {
  role: "user" | "assistant" | "system";
  content: string;
};

type ChatRequest = {
  messages: ChatMessage[];
  model?: string;
  max_tokens?: number;
};

type ChatResponse = {
  choices: Array<{
    message: {
      role: string;
      content: string;
    };
    finish_reason: string;
  }>;
  usage?: {
    total_tokens: number;
  };
};

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  let apiKey: string;
  try {
    apiKey = getKolosalApiKey();
  } catch (error) {
    return res.status(500).json({
      error: error instanceof Error ? error.message : "NEXT_PUBLIC_KOLOSAL_API_KEY environment variable is not set",
    });
  }

  try {
    const { messages, model = "meta-llama/llama-4-maverick-17b-128e-instruct", max_tokens = 1000 }: ChatRequest = req.body;

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: "Messages are required" });
    }

    const { statusCode, body } = await request(KOLOSAL_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: apiKey,
      },
      body: JSON.stringify({
        messages,
        model,
        max_tokens,
      }),
    });

    const responseData = (await body.json()) as ChatResponse;

    if (statusCode !== 200) {
      return res.status(statusCode).json({
        error: "Failed to get chat completion",
        details: responseData,
      });
    }

    return res.status(200).json(responseData);
  } catch (error) {
    console.error("Chat API error:", error);
    return res.status(500).json({
      error: "Internal server error",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

