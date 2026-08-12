/* ==========================================
   Rizzr — API Client
   All backend communication goes through here
   ========================================== */

const API_BASE = window.location.hostname === 'localhost'
  ? 'http://localhost:8000'
  : 'https://api.rizzr.com';

class RizzrAPI {
  constructor() {
    this.base = API_BASE;
  }

  async transcribe(audioBlob) {
    const formData = new FormData();
    formData.append('audio', audioBlob, 'voice.webm');

    const res = await fetch(`${this.base}/api/transcribe`, {
      method: 'POST',
      body: formData,
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.detail || `Transcribe failed: ${res.status}`);
    }

    return res.json(); // { transcript, language, duration }
  }

  async generateReply(transcript, sessionId) {
    // SSE streaming — returns a ReadableStream
    const res = await fetch(`${this.base}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ transcript, session_id: sessionId }),
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.detail || `Generate failed: ${res.status}`);
    }

    return res.body; // ReadableStream for SSE parsing
  }

  async generateTTS(text, voiceId) {
    const res = await fetch(`${this.base}/api/tts`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text, voice_id: voiceId || 'default' }),
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.detail || `TTS failed: ${res.status}`);
    }

    const blob = await res.blob();
    return URL.createObjectURL(blob);
  }

  async getUsage() {
    const res = await fetch(`${this.base}/api/usage`);
    if (!res.ok) return { remaining: 0, total: 3 };
    return res.json(); // { remaining, total }
  }

  async createCheckout() {
    const res = await fetch(`${this.base}/api/checkout`, {
      method: 'POST',
    });
    if (!res.ok) throw new Error('Checkout failed');
    const data = await res.json();
    return data.url; // Stripe redirect URL
  }

  // Parse SSE stream from generate endpoint
  async *parseSSE(stream) {
    const reader = stream.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6).trim();
          if (data === '[DONE]') return;
          try {
            yield JSON.parse(data);
          } catch {
            // skip invalid JSON
          }
        }
      }
    }
  }
}

window.rizzrAPI = new RizzrAPI();
