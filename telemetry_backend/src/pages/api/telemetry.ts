// src/pages/api/telemetry.ts
import type { APIRoute } from 'astro';

// Store an array of history per UUID
const telemetryStore = new Map<string, any[]>();
const MAX_HISTORY = 100; // Cap history to prevent memory issues

export const POST: APIRoute = async ({ request }) => {
  try {
    const data = await request.json();
    const { unique_UUID_id, s1_distance, s2_distance, s3_distance } = data;

    if (!unique_UUID_id) {
      return new Response(JSON.stringify({ error: 'UUID required' }), { status: 400 });
    }

    if (typeof s1_distance !== 'number' || typeof s2_distance !== 'number' || typeof s3_distance !== 'number') {
      return new Response(JSON.stringify({ error: 'Invalid distance values' }), { status: 400 });
    }

    const telemetryData = {
      timestamp: Date.now(),
      s1_distance,
      s2_distance,
      s3_distance
    };

    // Retrieve existing history or start a new array
    const history = telemetryStore.get(unique_UUID_id) || [];
    history.push(telemetryData);

    // Keep only the latest MAX_HISTORY records
    if (history.length > MAX_HISTORY) {
      history.shift();
    }

    telemetryStore.set(unique_UUID_id, history);

    return new Response(JSON.stringify({ success: true, data: telemetryData }), { 
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Invalid payload' }), { 
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const GET: APIRoute = async ({ request }) => {
  const url = new URL(request.url);
  const uuid = url.searchParams.get('uuid');

  if (!uuid) {
    return new Response(JSON.stringify({ error: 'UUID required' }), { status: 400 });
  }

  // Return the entire history array
  const history = telemetryStore.get(uuid);
  
  if (!history || history.length === 0) {
    return new Response(JSON.stringify({ error: 'No data found' }), { status: 404 });
  }

  return new Response(JSON.stringify(history), { 
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
};
