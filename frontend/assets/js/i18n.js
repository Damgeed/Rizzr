/* ==========================================
   Rizzr — i18n + Random Titles
   Random tagline/description on page refresh
   ========================================== */

const RIZZR_TITLES = [
  "Got a voice note? Rizzr it.",
  "Don't think. Just Rizzr it.",
  "Voice note in. Perfect reply out.",
  "Stuck on a reply? Rizzr has you.",
  "Stuck on what to say back? Rizzr it.",
  "Voice note got you stuck? Rizzr it.",
  "Never be lost for words again.",
  "Your AI wingman for voice notes.",
  "Reply like you mean it.",
  "Voice notes decoded. Replies delivered.",
  "Got a voice note? We got you.",
  "Don't think. Just Rizzr it. periodt.",
  "Can't think of a reply? We got you.",
  "Voice notes? Rizzr handles those.",
  "Too stunned to reply? Not anymore.",
  "From voice note to perfect reply.",
];

const RIZZR_SUBTITLES = [
  "AI voice-note reply coach. Get 3 perfect replies in seconds.",
  "Paste any voice message. Get 3 perfect replies — in seconds.",
  "AI-powered replies that hit different.",
  "Whisper transcribes. AI crafts. You choose.",
  "Three styles. One tap. Zero awkward pauses.",
  "From voice note to perfect reply in 7 seconds.",
  "Flirty, witty, or chill — pick your vibe.",
  "The AI that turns voice notes into perfect replies.",
  "Voice notes in, smooth replies out.",
  "Your voice-note wingman. Always ready.",
  "Three replies. Zero effort. Pure rizz.",
];

const RIZZR_TRUST = [
  { icon: "🔒", label: "No signup" },
  { icon: "⚡", label: "~7s results" },
  { icon: "🌍", label: "Any language" },
  { icon: "🤫", label: "Auto-deleted" },
  { icon: "✨", label: "3 free daily" },
  { icon: "🚀", label: "No app install" },
];

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function applyRandomText() {
  const titleEl = document.querySelector('[data-hero-title]');
  const subEl = document.querySelector('[data-hero-subtitle]');
  const trustEl = document.querySelector('[data-trust]');

  if (titleEl) {
    const title = pick(RIZZR_TITLES);
    // Highlight the "Rizzr" word
    titleEl.innerHTML = title.replace(/Rizzr/g, '<span class="hero__title-highlight">Rizzr</span>');
  }

  if (subEl) {
    subEl.textContent = pick(RIZZR_SUBTITLES);
  }

  if (trustEl) {
    // Pick 3 random trust badges
    const shuffled = [...RIZZR_TRUST].sort(() => Math.random() - 0.5).slice(0, 3);
    trustEl.innerHTML = shuffled.map(t =>
      `<span class="trust__item">${t.icon} ${t.label}</span>`
    ).join('');
  }
}

// Run on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', applyRandomText);
} else {
  applyRandomText();
}
