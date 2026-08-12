/* ==========================================
   Rizzr — Main App Logic
   Orchestrates: record → transcribe → generate → TTS → render
   ========================================== */

(function() {
  const recorder = new AudioRecorder();
  const api = window.rizzrAPI;

  // State
  let isProcessing = false;
  let currentSession = null;

  // DOM refs
  const recordBtn = document.querySelector('[data-record-btn]');
  const recordRing = document.querySelector('[data-record-ring]');
  const uploadBtn = document.querySelector('[data-upload-btn]');
  const fileInput = document.querySelector('[data-file-input]');
  const heroSection = document.querySelector('[data-hero]');
  const processSection = document.querySelector('[data-process]');
  const resultsSection = document.querySelector('[data-results]');
  const transcriptEl = document.querySelector('[data-transcript]');
  const repliesEl = document.querySelector('[data-replies]');
  const freeCountEl = document.querySelector('[data-free-count]');
  const hamburger = document.querySelector('[data-hamburger]');
  const mobileMenu = document.querySelector('[data-mobile-menu]');
  const mobileMenuClose = document.querySelector('[data-mobile-menu-close]');

  // ==========================================
  // RECORDING (press & hold)
  // ==========================================
  if (recordBtn) {
    let holdTimer = null;
    let isHolding = false;

    // Touch events for mobile
    recordBtn.addEventListener('touchstart', async (e) => {
      e.preventDefault();
      if (isProcessing) return;

      const hasPermission = await recorder.requestPermission();
      if (!hasPermission) {
        showToast('🎤 Microphone permission needed');
        return;
      }

      isHolding = true;
      recordBtn.classList.add('recording');
      recordRing?.classList.add('recording');
      recorder.start();
    }, { passive: false });

    recordBtn.addEventListener('touchend', async (e) => {
      e.preventDefault();
      if (!isHolding) return;
      isHolding = false;
      recordBtn.classList.remove('recording');
      recordRing?.classList.remove('recording');

      const result = await recorder.stop();
      if (result && result.blob && result.blob.size > 0) {
        await processAudio(result.blob);
      }
    }, { passive: false });

    // Mouse events for desktop
    recordBtn.addEventListener('mousedown', async (e) => {
      if (isProcessing) return;
      const hasPermission = await recorder.requestPermission();
      if (!hasPermission) return;
      isHolding = true;
      recordBtn.classList.add('recording');
      recordRing?.classList.add('recording');
      recorder.start();
    });

    recordBtn.addEventListener('mouseup', async () => {
      if (!isHolding) return;
      isHolding = false;
      recordBtn.classList.remove('recording');
      recordRing?.classList.remove('recording');
      const result = await recorder.stop();
      if (result && result.blob && result.blob.size > 0) {
        await processAudio(result.blob);
      }
    });

    recordBtn.addEventListener('mouseleave', async () => {
      if (isHolding) {
        isHolding = false;
        recordBtn.classList.remove('recording');
        recordRing?.classList.remove('recording');
        recorder.cancel();
      }
    });
  }

  // ==========================================
  // FILE UPLOAD
  // ==========================================
  if (uploadBtn && fileInput) {
    uploadBtn.addEventListener('click', () => fileInput.click());

    fileInput.addEventListener('change', async (e) => {
      const file = e.target.files[0];
      if (!file) return;

      const validation = AudioRecorder.validateFile(file);
      if (!validation.valid) {
        showToast(`❌ ${validation.error}`);
        return;
      }

      const blob = new Blob([file], { type: file.type });
      await processAudio(blob);
      fileInput.value = ''; // reset
    });
  }

  // ==========================================
  // PROCESS AUDIO (main pipeline)
  // ==========================================
  async function processAudio(audioBlob) {
    if (isProcessing) return;
    isProcessing = true;
    currentSession = crypto.randomUUID();

    // Show processing screen
    showScreen('process');
    processSection?.classList.remove('hidden');
    processSection?.classList.add('slide-up');
    updateProcessStep('upload', 'done');
    updateProcessStep('transcribe', 'active');

    try {
      // Step 1: Transcribe
      const { transcript, language, duration } = await api.transcribe(audioBlob);
      updateProcessStep('transcribe', 'done');
      updateProcessStep('generate', 'active');

      // Show transcript + results container
      transcriptEl.textContent = transcript;
      showScreen('results');

      // Step 2: Generate replies (SSE streaming)
      const stream = await api.generateReply(transcript, currentSession);
      let replies = [];

      for await (const chunk of api.parseSSE(stream)) {
        if (chunk.type === 'reply_partial') {
          // Update reply card as it streams in
          updateReplyCard(chunk.index, chunk.text, chunk.style, false);
        } else if (chunk.type === 'reply_complete') {
          // Mark reply as complete, show play button
          updateReplyCard(chunk.index, chunk.text, chunk.style, true);
          replies.push({ text: chunk.text, style: chunk.style, index: chunk.index });

          // Step 3: Generate TTS for this reply (parallel)
          generateTTSForReply(chunk.index, chunk.text);
        } else if (chunk.type === 'done') {
          updateProcessStep('generate', 'done');
          updateProcessStep('tts', 'done');
        }
      }

      // Update free count
      const usage = await api.getUsage();
      if (freeCountEl) {
        freeCountEl.textContent = usage.remaining;
        if (usage.remaining === 0) {
          showPaywall();
        }
      }

    } catch (err) {
      console.error('Processing error:', err);
      showToast(`❌ ${err.message}`);
      showScreen('hero');
    } finally {
      isProcessing = false;
    }
  }

  // ==========================================
  // TTS GENERATION (per reply, parallel)
  // ==========================================
  async function generateTTSForReply(index, text) {
    const playBtn = document.querySelector(`[data-play-btn="${index}"]`);
    if (!playBtn) return;

    playBtn.textContent = '⏳';
    playBtn.disabled = true;

    try {
      const audioUrl = await api.generateTTS(text);
      playBtn.dataset.audioUrl = audioUrl;
      playBtn.textContent = '▶';
      playBtn.disabled = false;

      // Click to play/pause
      playBtn.onclick = () => togglePlayback(audioUrl, playBtn);
    } catch (err) {
      playBtn.textContent = '▶';
      playBtn.disabled = false;
      // TTS failed but text is still usable
    }
  }

  let currentAudio = null;
  function togglePlayback(url, btn) {
    if (currentAudio && !currentAudio.paused) {
      currentAudio.pause();
      btn.textContent = '▶';
    }

    if (currentAudio?.src === url && currentAudio.paused) {
      currentAudio.play();
      btn.textContent = '⏸';
      return;
    }

    currentAudio = new Audio(url);
    currentAudio.play();
    btn.textContent = '⏸';

    currentAudio.onended = () => {
      btn.textContent = '▶';
    };
  }

  // ==========================================
  // REPLY CARD RENDERING
  // ==========================================
  function updateReplyCard(index, text, style, isComplete) {
    let card = document.querySelector(`[data-reply-card="${index}"]`);

    if (!card) {
      // Create new card
      card = document.createElement('div');
      card.className = `reply reply--${style} fade-in`;
      card.dataset.replyCard = index;
      card.innerHTML = `
        <div class="reply__header">
          <span class="reply__badge reply__badge--${style}">${style}</span>
        </div>
        <div class="reply__text" data-reply-text="${index}"></div>
        <div class="reply__actions${isComplete ? '' : ' hidden'}">
          <button class="reply__play" data-play-btn="${index}" disabled title="Play">⏳</button>
          <button class="reply__copy" data-copy="${index}" title="Copy">📋</button>
          <button class="reply__download" data-download="${index}" title="Download voice">📥</button>
          <button class="reply__regen" data-remix="${index}">Remix</button>
        </div>
      `;
      repliesEl.appendChild(card);

      // Wire up actions
      card.querySelector(`[data-copy="${index}"]`)?.addEventListener('click', () => {
        navigator.clipboard.writeText(text);
        showToast('📋 Copied!');
      });

      card.querySelector(`[data-download="${index}"]`)?.addEventListener('click', async () => {
        const playBtn = card.querySelector(`[data-play-btn="${index}"]`);
        const audioUrl = playBtn?.dataset.audioUrl;
        if (!audioUrl) {
          showToast('⏳ Voice still generating...');
          return;
        }
        const a = document.createElement('a');
        a.href = audioUrl;
        a.download = `rizzr-reply-${style}.mp3`;
        a.click();
        showToast('📥 Downloaded!');
      });

      card.querySelector(`[data-remix="${index}"]`)?.addEventListener('click', async () => {
        showToast('🔄 Remixing...');
        // TODO: call API to regenerate this reply with higher temperature
      });
    }

    // Update text
    const textEl = card.querySelector(`[data-reply-text="${index}"]`);
    if (textEl) textEl.textContent = text;

    if (isComplete) {
      const actions = card.querySelector('.reply__actions');
      if (actions) actions.classList.remove('hidden');
    }
  }

  // ==========================================
  // UI HELPERS
  // ==========================================
  function showScreen(screen) {
    heroSection?.classList.toggle('hidden', screen !== 'hero');
    processSection?.classList.toggle('hidden', screen !== 'process');
    resultsSection?.classList.toggle('hidden', screen !== 'results');
  }

  function updateProcessStep(step, state) {
    const el = document.querySelector(`[data-process-step="${step}"]`);
    if (!el) return;
    el.className = `process__step process__step--${state}`;
    const icon = el.querySelector('.process__step-icon');
    if (icon) {
      icon.textContent = state === 'done' ? '✓' : state === 'active' ? '✦' : '○';
    }
  }

  function showPaywall() {
    window.location.href = 'pricing.html';
  }

  function showToast(msg) {
    const toast = document.querySelector('[data-toast]');
    if (!toast) return;
    toast.textContent = msg;
    toast.classList.add('toast--show');
    setTimeout(() => toast.classList.remove('toast--show'), 3000);
  }

  // ==========================================
  // MOBILE MENU
  // ==========================================
  hamburger?.addEventListener('click', () => {
    mobileMenu?.classList.add('mobile-menu--open');
  });

  mobileMenuClose?.addEventListener('click', () => {
    mobileMenu?.classList.remove('mobile-menu--open');
  });

  // Close menu on link click
  document.querySelectorAll('.mobile-menu__link').forEach(link => {
    link.addEventListener('click', () => {
      mobileMenu?.classList.remove('mobile-menu--open');
    });
  });

  // Start over button
  document.querySelector('[data-start-over]')?.addEventListener('click', () => {
    // Clear replies
    if (repliesEl) repliesEl.innerHTML = '';
    // Reset process steps
    ['upload', 'transcribe', 'generate', 'tts'].forEach(step => {
      updateProcessStep(step, 'pending');
    });
    // Show hero
    showScreen('hero');
  });

})();
