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

  async createCheckout(tier = 'pro_monthly') {
    const res = await fetch(`${this.base}/api/checkout`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tier }),
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

// ---- Robust microphone capture (mobile-Safari safe) ----
// mimeType fallback chain, getUserMedia MUST be called inside the user tap
// gesture (Safari blocks async), and Safari fires several `dataavailable`
// blobs that must be concatenated into one file.
RizzrAPI.pickAudioMime = function () {
  if (typeof MediaRecorder === 'undefined') return null;
  const types = [
    'audio/mp4',
    'audio/webm;codecs=opus',
    'audio/webm',
    'audio/ogg;codecs=opus',
    '',
  ];
  for (const t of types) {
    try {
      if (MediaRecorder.isTypeSupported(t)) return t;
    } catch (e) { /* ignore */ }
  }
  return '';
};

// Returns { stop(), stream, blobPromise } — call start() then stop() later.
RizzrAPI.startRecording = function () {
  return navigator.mediaDevices.getUserMedia({
    audio: {
      echoCancellation: true,
      noiseSuppression: true,
      autoGainControl: true,
    },
  }).then(function (stream) {
    const mime = RizzrAPI.pickAudioMime();
    let recorder;
    try {
      recorder = mime
        ? new MediaRecorder(stream, mime === '' ? undefined : { mimeType: mime })
        : new MediaRecorder(stream);
    } catch (e) {
      // Last resort: no options
      recorder = new MediaRecorder(stream);
    }
    const chunks = [];
    recorder.ondataavailable = function (e) {
      if (e.data && e.data.size > 0) chunks.push(e.data);
    };
    const blobPromise = new Promise(function (resolve, reject) {
      recorder.onstop = function () {
        stream.getTracks().forEach(function (t) { t.stop(); });
        const type = mime && mime !== '' ? mime : chunks[0] && chunks[0].type;
        resolve(new Blob(chunks, { type: type || 'audio/webm' }));
      };
      recorder.onerror = function (e) { reject(e); };
    });
    recorder.start();
    return {
      stop: function () {
        if (recorder.state === 'recording') recorder.stop();
      },
      stream: stream,
      blob: blobPromise,
    };
  });
};

window.rizzrAPI = new RizzrAPI();
