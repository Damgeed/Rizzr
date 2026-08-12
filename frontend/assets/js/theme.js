/* ==========================================
   Rizzr — Theme Switcher
   3 themes: sunset (default), purple-dream, neon-nights
   Stored in localStorage, applied via CSS file swap
   ========================================== */

const THEMES = [
  { id: 'sunset', name: 'Sunset', css: 'theme-sunset.css', previewClass: 'theme-sunset-preview' },
  { id: 'purple-dream', name: 'Purple Dream', css: 'theme-purple-dream.css', previewClass: 'theme-purple-dream-preview' },
  { id: 'neon-nights', name: 'Neon Nights', css: 'theme-neon-nights.css', previewClass: 'theme-neon-nights-preview' },
];

const STORAGE_KEY = 'rizzr-theme';
const DEFAULT_THEME = 'sunset';

function getCurrentTheme() {
  return localStorage.getItem(STORAGE_KEY) || DEFAULT_THEME;
}

function setTheme(themeId) {
  const theme = THEMES.find(t => t.id === themeId);
  if (!theme) return;

  // Remove existing theme CSS
  const existing = document.querySelector('link[data-theme-css]');
  if (existing) existing.remove();

  // Add new theme CSS
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = `assets/css/${theme.css}`;
  link.setAttribute('data-theme-css', '');
  document.head.appendChild(link);

  // Save to localStorage
  localStorage.setItem(STORAGE_KEY, themeId);

  // Update theme dots in navbar
  document.querySelectorAll('[data-theme-dot]').forEach(dot => {
    dot.classList.toggle('navbar__theme-dot--active', dot.dataset.themeDot === themeId);
  });

  // Update theme cards in settings
  document.querySelectorAll('[data-theme-card]').forEach(card => {
    card.classList.toggle('active', card.dataset.themeCard === themeId);
  });

  // Dispatch event for other scripts
  window.dispatchEvent(new CustomEvent('themechange', { detail: { theme: themeId } }));
}

function initTheme() {
  const saved = getCurrentTheme();
  setTheme(saved);

  // Theme dots in navbar
  document.querySelectorAll('[data-theme-dot]').forEach(dot => {
    dot.addEventListener('click', () => setTheme(dot.dataset.themeDot));
  });

  // Theme cards in settings
  document.querySelectorAll('[data-theme-card]').forEach(card => {
    card.addEventListener('click', () => setTheme(card.dataset.themeCard));
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initTheme);
} else {
  initTheme();
}
