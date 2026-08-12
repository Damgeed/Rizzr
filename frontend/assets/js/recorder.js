/* ==========================================
   Rizzr — Audio Recorder
   MediaRecorder API for voice capture
   ========================================== */

class AudioRecorder {
  constructor() {
    this.mediaRecorder = null;
    this.chunks = [];
    this.stream = null;
    this.isRecording = false;
    this.startTime = 0;
  }

  async requestPermission() {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          channelCount: 1,
          sampleRate: 16000,
          echoCancellation: true,
          noiseSuppression: true,
        }
      });
      return true;
    } catch (err) {
      console.error('Mic permission denied:', err);
      return false;
    }
  }

  start() {
    if (!this.stream) {
      console.error('No stream — call requestPermission first');
      return;
    }

    this.chunks = [];
    this.startTime = Date.now();

    // Pick best supported format
    const mimeType = this._getMimeType();

    this.mediaRecorder = new MediaRecorder(this.stream, {
      mimeType,
      audioBitsPerSecond: 64000,
    });

    this.mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) this.chunks.push(e.data);
    };

    this.mediaRecorder.start(100); // collect in 100ms chunks
    this.isRecording = true;
  }

  stop() {
    return new Promise((resolve) => {
      if (!this.mediaRecorder || !this.isRecording) {
        resolve(null);
        return;
      }

      this.mediaRecorder.onstop = () => {
        const duration = (Date.now() - this.startTime) / 1000;
        const blob = new Blob(this.chunks, { type: this.mediaRecorder.mimeType });
        this.isRecording = false;
        resolve({ blob, duration });
      };

      this.mediaRecorder.stop();
    });
  }

  cancel() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop();
      this.isRecording = false;
      this.chunks = [];
    }
  }

  getDuration() {
    if (!this.startTime) return 0;
    return (Date.now() - this.startTime) / 1000;
  }

  _getMimeType() {
    const types = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/ogg;codecs=opus',
      'audio/mp4',
      'audio/mpeg',
    ];
    for (const type of types) {
      if (MediaRecorder.isTypeSupported(type)) return type;
    }
    return '';
  }

  // Handle file upload
  static validateFile(file) {
    const MAX_SIZE = 25 * 1024 * 1024; // 25MB
    const MAX_DURATION = 300; // 5 min
    const VALID_TYPES = [
      'audio/webm', 'audio/wav', 'audio/m4a',
      'audio/mp3', 'audio/mpeg', 'audio/ogg',
      'audio/mp4', 'audio/aac',
    ];

    if (!VALID_TYPES.includes(file.type) && !file.name.match(/\.(webm|wav|m4a|mp3|ogg|aac)$/i)) {
      return { valid: false, error: 'Unsupported audio format' };
    }

    if (file.size > MAX_SIZE) {
      return { valid: false, error: 'File too large (max 25MB)' };
    }

    return { valid: true };
  }
}

window.AudioRecorder = AudioRecorder;
