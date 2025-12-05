import type { NextApiRequest, NextApiResponse } from "next";
import { request } from "undici";

const KOLOSAL_API_URL = "https://api.kolosal.ai/v1/models";

function getKolosalApiKey(): string {
  // In Next.js standalone mode, process.env is available at runtime
  const apiKey = "kol_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZDE0OWZkY2MtMTRhOS00MzYwLWI3YWQtY2IxMzhmODk5MGYwIiwia2V5X2lkIjoiZGFhY2I3MGYtY2FjOS00ZDg1LTgyYjYtMzVlOTEwN2I1ZmRhIiwia2V5X25hbWUiOiJ0ZXN0IiwiZW1haWwiOiJhZnJpemFhaG1hZDE4QGdtYWlsLmNvbSIsInJhdGVfbGltaXRfcnBzIjpudWxsLCJtYXhfY3JlZGl0X3VzZSI6MTAsImNyZWF0ZWRfYXQiOjE3NjQ1MTU3NDksImV4cGlyZXNfYXQiOjE3OTYwNTE3NDksImlhdCI6MTc2NDUxNTc0OX0.FJohjYxWBeeKm2XSl3zrZHA3_PyOQFbTD9iQSsZiW_M";
  
  if (!apiKey) {
    // Log available env vars for debugging
    const envKeys = Object.keys(process.env || {}).filter(key => 
      key.includes('KOLOSAL') || key.includes('API')
    );
    console.error("Model: NEXT_PUBLIC_KOLOSAL_API_KEY not found. Available env keys:", envKeys);
    throw new Error("NEXT_PUBLIC_KOLOSAL_API_KEY environment variable is not set");
  }
  
  return `Bearer ${apiKey}`;
}

type Model = {
  id: string;
  name: string;
  pricing: {
    input: number;
    output: number;
    currency: string;
    unit: string;
  };
  contextSize: number;
  lastUpdated: string;
};

type ModelsResponse = {
  models: Model[];
  count: number;
};

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== "GET") {
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
    const { statusCode, body } = await request(KOLOSAL_API_URL, {
      method: "GET",
      headers: {
        Authorization: apiKey,
      },
    });

    const responseData = (await body.json()) as ModelsResponse;

    if (statusCode !== 200) {
      return res.status(statusCode).json({
        error: "Failed to get models",
        details: responseData,
      });
    }

    return res.status(200).json(responseData);
  } catch (error) {
    console.error("Models API error:", error);
    return res.status(500).json({
      error: "Internal server error",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

