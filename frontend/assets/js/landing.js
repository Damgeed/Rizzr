(function () {
  'use strict';

  var prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ------------------------------------------------------------------ */
  /* Sticky header shadow on scroll                                      */
  /* ------------------------------------------------------------------ */
  var header = document.getElementById('site-header');
  function onScroll() {
    header.classList.toggle('is-scrolled', window.scrollY > 8);
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  /* ------------------------------------------------------------------ */
  /* Mobile menu                                                         */
  /* ------------------------------------------------------------------ */
  var menuToggle = document.getElementById('menu-toggle');
  var mobileMenu = document.getElementById('mobile-menu');

  function closeMenu() {
    menuToggle.setAttribute('aria-expanded', 'false');
    mobileMenu.hidden = true;
    document.body.style.overflow = '';
  }
  function openMenu() {
    menuToggle.setAttribute('aria-expanded', 'true');
    mobileMenu.hidden = false;
    document.body.style.overflow = 'hidden';
    var firstLink = mobileMenu.querySelector('a');
    if (firstLink) firstLink.focus();
  }
  menuToggle.addEventListener('click', function () {
    var isOpen = menuToggle.getAttribute('aria-expanded') === 'true';
    isOpen ? closeMenu() : openMenu();
  });
  mobileMenu.addEventListener('click', function (e) {
    if (e.target.tagName === 'A') closeMenu();
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && menuToggle.getAttribute('aria-expanded') === 'true') closeMenu();
  });

  /* ------------------------------------------------------------------ */
  /* Scroll-reveal (IntersectionObserver)                                 */
  /* ------------------------------------------------------------------ */
  var revealEls = document.querySelectorAll('[data-reveal]');
  if ('IntersectionObserver' in window && !prefersReducedMotion) {
    var io = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15 }
    );
    revealEls.forEach(function (el) { io.observe(el); });
  } else {
    revealEls.forEach(function (el) { el.classList.add('is-visible'); });
  }

  /* ------------------------------------------------------------------ */
  /* Phone demo — state machine: idle -> recording -> processing -> results */
  /* ------------------------------------------------------------------ */
  var views = {
    idle: document.getElementById('view-idle'),
    recording: document.getElementById('view-recording'),
    processing: document.getElementById('view-processing'),
    results: document.getElementById('view-results')
  };
  var tabs = document.querySelectorAll('.state-tabs button');
  var announcer = document.getElementById('state-announcer');

  var announceText = {
    idle: 'Ready to record.',
    recording: 'Recording your voice note.',
    processing: 'Generating replies.',
    results: '3 replies ready: flirty, witty, sweet.'
  };

  function setState(state) {
    Object.keys(views).forEach(function (key) {
      views[key].classList.toggle('active', key === state);
    });
    tabs.forEach(function (btn) {
      var match = btn.getAttribute('data-state') === state || (state === 'processing' && btn.getAttribute('data-state') === 'recording');
      btn.classList.toggle('active', match);
      btn.setAttribute('aria-selected', match ? 'true' : 'false');
    });
    if (announcer && announceText[state]) announcer.textContent = announceText[state];
  }

  tabs.forEach(function (btn) {
    btn.addEventListener('click', function () {
      stopMic();
      setState(btn.getAttribute('data-state'));
    });
  });

  /* ---- hold-to-record interaction, with real mic visualization ---- */
  var recordBtn = document.getElementById('record-btn');
  var stopBtn = document.getElementById('stop-btn');
  var backBtn = document.getElementById('back-btn');
  var waveformEl = document.getElementById('waveform');
  var waveformBars = waveformEl.querySelectorAll('span');
  var timerEl = document.getElementById('rec-timer');

  var audioCtx, analyser, micStream, rafId;
  var timerInterval, elapsedSeconds;
  var isHolding = false;

  function formatTime(s) {
    var m = Math.floor(s / 60);
    var sec = s % 60;
    return m + ':' + (sec < 10 ? '0' : '') + sec;
  }

  function startTimer() {
    elapsedSeconds = 0;
    timerEl.textContent = formatTime(0);
    timerInterval = setInterval(function () {
      elapsedSeconds++;
      timerEl.textContent = formatTime(elapsedSeconds);
    }, 1000);
  }
  function stopTimer() {
    clearInterval(timerInterval);
  }

  function drawSimulatedWave() {
    waveformEl.classList.add('is-simulated');
  }

  function drawLiveWave() {
    waveformEl.classList.remove('is-simulated');
    var data = new Uint8Array(analyser.frequencyBinCount);
    (function loop() {
      analyser.getByteFrequencyData(data);
      var step = Math.floor(data.length / waveformBars.length);
      waveformBars.forEach(function (bar, i) {
        var v = data[i * step] || 0;
        var height = Math.max(6, Math.min(60, (v / 255) * 60));
        bar.style.height = height + 'px';
      });
      rafId = requestAnimationFrame(loop);
    })();
  }

  function startMic() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      drawSimulatedWave();
      return;
    }
    navigator.mediaDevices.getUserMedia({ audio: true })
      .then(function (stream) {
        micStream = stream;
        audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        analyser = audioCtx.createAnalyser();
        analyser.fftSize = 64;
        var source = audioCtx.createMediaStreamSource(stream);
        source.connect(analyser);
        drawLiveWave();
      })
      .catch(function () {
        // permission denied / unavailable — fall back to a simulated waveform
        drawSimulatedWave();
      });
  }

  function stopMic() {
    if (rafId) cancelAnimationFrame(rafId);
    if (micStream) {
      micStream.getTracks().forEach(function (t) { t.stop(); });
      micStream = null;
    }
    if (audioCtx) {
      audioCtx.close().catch(function () {});
      audioCtx = null;
    }
    waveformEl.classList.remove('is-simulated');
    waveformBars.forEach(function (bar) { bar.style.height = ''; });
  }

  function beginRecording() {
    if (isHolding) return;
    isHolding = true;
    recordBtn.classList.add('is-active');
    setState('recording');
    startTimer();
    startMic();
  }

  function endRecording() {
    if (!isHolding) return;
    isHolding = false;
    recordBtn.classList.remove('is-active');
    stopTimer();
    stopMic();
    setState('processing');
    window.setTimeout(function () {
      setState('results');
    }, prefersReducedMotion ? 200 : 1100);
  }

  // pointer events cover mouse + touch + pen in one API
  recordBtn.addEventListener('pointerdown', function (e) {
    e.preventDefault();
    beginRecording();
  });
  window.addEventListener('pointerup', endRecording);
  window.addEventListener('pointercancel', endRecording);

  // keyboard support: Enter/Space toggles instead of requiring a hold
  recordBtn.addEventListener('keydown', function (e) {
    if ((e.key === 'Enter' || e.key === ' ') && !isHolding) {
      e.preventDefault();
      beginRecording();
    }
  });
  recordBtn.addEventListener('keyup', function (e) {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      endRecording();
    }
  });

  stopBtn.addEventListener('click', endRecording);

  backBtn.addEventListener('click', function () {
    setState('idle');
  });

  /* ------------------------------------------------------------------ */
  /* Reply cards — play (simulated) + copy (real clipboard)              */
  /* ------------------------------------------------------------------ */
  var activePlayBtn = null;

  document.querySelectorAll('.play-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var wave = btn.nextElementSibling;
      var isPlaying = btn.classList.contains('is-playing');

      if (activePlayBtn && activePlayBtn !== btn) {
        resetPlayButton(activePlayBtn);
      }

      if (isPlaying) {
        resetPlayButton(btn);
        activePlayBtn = null;
        return;
      }

      btn.classList.add('is-playing');
      btn.innerHTML = '<svg viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="5" width="4" height="14" rx="1"></rect><rect x="14" y="5" width="4" height="14" rx="1"></rect></svg>';
      if (wave) wave.classList.add('is-playing');
      activePlayBtn = btn;

      window.setTimeout(function () {
        if (activePlayBtn === btn) {
          resetPlayButton(btn);
          activePlayBtn = null;
        }
      }, 2600);
    });
  });

  function resetPlayButton(btn) {
    btn.classList.remove('is-playing');
    btn.innerHTML = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"></path></svg>';
    var wave = btn.nextElementSibling;
    if (wave) wave.classList.remove('is-playing');
  }

  document.querySelectorAll('.copy-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var card = btn.closest('.reply-card');
      var text = card ? card.getAttribute('data-reply') : '';
      copyText(text, btn);
    });
  });

  function copyText(text, btn) {
    var done = function () {
      btn.classList.add('is-copied');
      var original = btn.innerHTML;
      btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"></path></svg>';
      if (announcer) announcer.textContent = 'Reply copied to clipboard.';
      window.setTimeout(function () {
        btn.innerHTML = original;
        btn.classList.remove('is-copied');
      }, 1400);
    };

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(done).catch(function () { fallbackCopy(text, done); });
    } else {
      fallbackCopy(text, done);
    }
  }

  function fallbackCopy(text, done) {
    var ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand('copy'); } catch (err) { /* no-op */ }
    document.body.removeChild(ta);
    done();
  }

  /* ------------------------------------------------------------------ */
  /* CTA pill buttons (Upload / Paste link) — jump to the live demo      */
  /* ------------------------------------------------------------------ */
  document.querySelectorAll('[data-action]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      setState('idle');
      var demo = document.querySelector('.phone');
      if (demo) demo.scrollIntoView({ behavior: prefersReducedMotion ? 'auto' : 'smooth', block: 'center' });
    });
  });

  /* ------------------------------------------------------------------ */
  /* FAQ accordion                                                        */
  /* ------------------------------------------------------------------ */
  document.querySelectorAll('.accordion-trigger').forEach(function (trigger) {
    trigger.addEventListener('click', function () {
      var item = trigger.closest('.accordion-item');
      var isOpen = item.classList.contains('is-open');
      item.classList.toggle('is-open', !isOpen);
      trigger.setAttribute('aria-expanded', !isOpen ? 'true' : 'false');
    });
  });

})();
