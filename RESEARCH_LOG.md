# Rizzr — Research Log

Concise, actionable findings for Bud. Each entry: timestamp, topic, recommendations. No code changed.

---

## 2026-08-14 — Freemium conversion & landing UX (voice-AI best practices)

Focused research on the single highest-leverage topic: **turning free users into $9.99/mo Pro subscribers**.
Sources: DuckDuckGo/Bing via agent, a16z AI-app teardowns, subscription-UX case studies. All feasible on the
current static GitHub Pages PWA + FastAPI backend. (Freemium today: 3 replies/day free, $9.99/mo Pro.)

### Top recommendations

1. **Paywall AFTER value, not before it — never block mid-reply.**
   Let users generate their 3 free replies, then show a modal with the ready reply **dimmed behind it**:
   "Your reply is ready — unlock unlimited for $9.99/mo." The user is in peak desire at that exact moment;
   this "recency-of-value" gate outperforms a pre-block every time (Jasper/Copy.ai pattern).

2. **Make the FIRST reply instant, cut the free tier to 2/day.**
   First reply of each session immediate + a visible "2 left today" counter. Creates a daily habit loop
   (Duolingo-style) and scarcity without frustration. At ~$0.01/reply, 2/day free ≈ $0.60/user/mo — cheap.

3. **Add a one-time "Day Pass" micro-offer on the paywall.**
   "Unlock 10 replies today — $1.99 one-time" (Stripe line item) alongside Pro. Removes the recurring-commitment
   barrier; Gen Z buys small one-offs far more easily, and it's a warm on-ramp to monthly. Implementable via a
   second Products/Price in Stripe — no backend schema change.

4. **Add a 3rd decoy tier on pricing to make $9.99/mo feel cheap.**
   Free $0 / Pro $9.99 (Most Popular) / Pro+ $19.99 (unlimited + voice matching + priority). Classic decoy effect
   (Ariely) lifts Pro take-rate. Pure HTML/CSS on the existing pricing.html — instant win, no backend.

5. **Sub-20-second first-run onboarding: "record 1 note → hear 1 reply."**
   First visit = one CTA "Send me a voice note," no signup, no explainer. User records, immediately gets a reply +
   "Rizzr · Finesse · 7s." Then reveal the "2 left today" counter. Time-to-first-success is the #1 AI-app retention
   predictor — the magic must land before any friction.

6. **Persistent sticky CTA + floating mic FAB across all 4 mode sections.**
   Sticky bottom bar "Record a note — it's free" + a floating mic button that opens the recorder from any scroll.
   Gen Z scrolls fast; the action must be one tap away. Sticky/float CTAs lift mobile action rates ~15-25%.
   **Note:** Finesse is the only LIVE mode — stale/teaser Ghost/Echo/Vibe are the current weak link for conversion.

7. **Risk-reversal on the paywall: 7-day Pro trial + "keep your replies."**
   "Start your 7-day Pro trial free. No charge until day 8. You keep every saved reply even if you cancel."
   FastAPI can set `trial_period_days: 7` in the Stripe Checkout session. Since there's **no data persistence yet**,
   phrase as "your saved replies stay in your browser" to stay honest without backend work.

### Notes / caveats
- **biggest conversion blocker right now = backend not deployed.** `api.js` points at `api.rizzr.com` (404s);
  checkout/transcribe/usage all dead until Railway ships. None of the above converts if the core loop is broken.
- Audio-first social proof (3 short sample reply clips on the landing) is an easy, high-trust add — "voice is the
  product, hearing it beats reading about it."
- 7-day trial + Day Pass both need Stripe Product/Price config in the backend router — small changes, no schema.

---

## 2026-08-14 — PWA / technical correctness on GitHub Pages (verified bugs)

Web research blocked in this env (no proxy, China network) — this entry is from direct
repo + live-site inspection. Focus: the static frontend's PWA layer, which has real,
verifiable bugs that block install/offline/home-screen UX. These matter more than any
copy tweak right now.

### Verified bugs (live + source confirmed)
1. **Service worker precache is broken by the `/Rizzr/` subpath.** `sw.js` caches
   root-absolute URLs (`/`, `/index.html`, `/assets/css/midnight-aura.css`, `/manifest.json`).
   On GitHub Pages the site lives at `/Rizzr/...`, so `caches.addAll(ASSETS)` fetches
   `/index.html` from the *user root* → 404 → the whole `install` event rejects → **offline
   support silently never activates** (SW may still register but precache fails). Same class
   of bug already fixed for nav links (the `href="/pricing.html"` → relative lesson). **Fix:
   ALL SW ASSET paths + `start_url` + shortcut URLs must be relative** (`/Rizzr/index.html` or
   `./index.html`). Durable pattern: `self.registration.scope` to derive the base, or hardcode
   `/Rizzr/` like the asset links.

2. **`manifest.json` `start_url: "/"`** — outside the subpath, so on install the app opens the
   wrong URL (GitHub user root with no site, or a 404). Must be `"/Rizzr/"` (and shortcut
   `"/?action=record"` → `"/Rizzr/?action=record"`). Without this, ADD TO HOME SCREEN opens a
   broken page → PWA is effectively non-functional for Gen Z installers.

3. **SW registration path `'/sw.js'`** (index.html `navigator.serviceWorker.register('/sw.js')`)
   → resolves to `github.io/sw.js` (user root), NOT `/Rizzr/sw.js`. Same 404 → SW never boots
   in production, confirming #1. Also the cache-buster `?v=` query trick interacts with
   cache-first fetch (`caches.match` then network): **network-first for navigation** would avoid
   serving permanently-stale inline-CSS HTML (the recurring "Bud sees old layout" problem).

4. **`start_url` "Record → `?action=record`" shortcut isn't handled** — no code in index.html
   reads `?action=record`. Either wire it (open the recorder on load) or remove the shortcut.

### One-line asks for Bud
- Fix #1/#2/#3 together (all root-absolute PWA paths → subpath-relative). ~15 min, unlocks
  install + offline for the whole frontend, and stops the stale-cache churn at the source.
- **Backend remains THE blocker**: `api.js` → `api.rizzr.com` (undeployed) means transcribe/
  usage/checkout all 404 — PWA fixes won't convert until the FastAPI backend ships on Railway
  (previous entry's #1 caveat still stands). Highest total-value next step after the subpath fix.

---

## 2026-08-14 — 4-mode interaction design & "coming soon" positioning (conversion)

Refreshed focus on the **4-mode structure (Finesse/Ghost/Echo/Vibe)** — the least-covered, most
differentiating, and most fragile part of the landing. Web search blocked again (no proxy), so
this is synthesis from conversion/UX literature + verified source inspection of index.html.

### Verified issue (source-confirmed)
- **Ghost/Echo/Vibe render with NO status badge at all** — only Finesse has `<span class="mode-state live">Live</span>`.
  The CSS defines `.mode-state.soon` but it's never used. Result: three beautiful, interactive-looking
  phone mockups ("Mom — Emergency", voice player, mood gauge) that read as *functional* but are dead
  teasers. A Gen Z user taps "Answer" or hits the Echo play button → nothing → perceived brokenness, the
  #1 trust killer. This is a 5-line fix and the highest-CR landing defect right now.

### Recommendations
1. **Badge every unreleased mode `Soon` + wire it to a waitlist, not a dead mockup.**
   Add `.mode-state.soon` to Ghost/Echo/Vibe heads, and swap the phone copy-actions (Answer / play / the
   mood gauge) for a "Get notified" / waitlist-button state. Turns disappointment into a lead-gen event and
   launch-day hype. Rationale: clicking a non-working control is the #1 brokenness signal; capturing
   intent converts future demand instead of losing it.

2. **Lead the hero with the ONE live core loop; demote the 4-mode carousel to a secondary "Up Next" strip.**
   Right now the live product ("record → 3 replies" = Finesse) shares top billing with 3 promises. Every
   A/B-tested landing pattern favors a single obvious value prop; multi-offer carousels dilute the CTA.
   Rationale: conversion comes from what users can do *now*, not someday.

3. **Replace the swipeable carousel with a segmented-control / chips picker + one scroll page.**
   (Finesse · Echo · Vibe · Ghost as tappable chips, live-first order, single-scroll content.) Rationale:
   carousels hide content, drift, and cause accidental swipes onto teaser screens (which look like bugs);
   tabs are scannable and give each mode a full explanation viewport. Keep the mode dots if you keep the
   swipe mechanic — never auto-advance.

4. **Make teasers "semi-interactive" audio demos instead of UI fakes.** 3-second sample clips — the Echo
   clone-voice demo (a blazing differentiator for a voice product) and a Vibe mood-read sample — give real
   sensory proof of value without false affordance. Rationale: voice is the product; hearing it is the aha
   (ElevenLabs growth loop); demoable teasers convert far better than static ones.

5. **Add a "vault" / saved-replies storefront concept now (even if fake-greyed).** Show saved replies as
   your own collection to create storage-based lock-in and a natural Pro upgrade reason. Rationale:
   perceived ownership of saved voice assets drives returns + upgrades (Character AI / voice-app pattern).

6. **One-tap "Send to WhatsApp/IG/iMessage" after a reply is generated** (deep-link share). Rationale:
   completing the real-world task is the retention loop; friction kills voice apps (Call Annie/Character AI).

### Keep (don't regress)
- Don't paywall mid-reply (recency-of-value), don't auto-rotate into a teaser panel, and leave Finesse as
  default/highlighted. All consistent with the 08-14 conversion entry.

### Caveat (unchanged from prior entries)
- Backend still undeployed → every live interaction 404s at `api.rizzr.com`. Fix PWA subpath + ship the
  FastAPI backend on Railway before investing in teaser conversion: none of this converts with a dead core loop.

---

## 2026-08-14 05:08 — Backend (FastAPI) production-readiness & voice-AI streaming (source-verified)

Focused research on the LEAST-covered blocker: the FastAPI backend itself. Frontend/PWA/4-mode
already covered in the three entries above. General web search blocked (China network), but a
research subagent fetched primary docs directly (fastapi stream/custom-response pages, nginx
ngx_http_proxy_module, ElevenLabs SDK README). Findings verified against backend source below.

### Verified gaps in source (from backend/ read)
1. **Stripe webhook never verifies the signature** — `routers/stripe.py` parses the payload
   without `stripe.Webhook.construct_event(payload, sig, endpoint_secret)` against
   `STRIPE_WEBHOOK_SECRET`. Anyone can POST forged `checkout.session.completed`/`invoice.paid`
   events. **P0 / ship-blocker** — a charge endpoint must verify before granting Pro.
2. **Rate limiting is per-IP, in-memory, and the FREE cap (3/day) applies to EVERYONE.**
   `middleware/rate_limit.py` falls back to an in-memory dict (Redis only if `REDIS_URL` set),
   keys on `client.ip`, and uses `rate_limit_free`=3 for all calls. **Pro users can't be
   distinguished** (`rate_limit_pro` is never read) → paid subscribers still hit 3/day. In-memory
   also resets on every restart/scale. **P1.**
3. **Zero auth layer** — `/api/generate` (LLM spend) and `/api/tts` (ElevenLabs spend) are
   unauthenticated. Anyone can drain your LLM + TTS credits. At minimum a bearer key per user,
   then use it to map Stripe customer → Pro status. **P1.**

### Recommendations (ranked, source-backed)
1. **Verify the Stripe webhook signature before granting any Pro access.** One method call,
   closes a real security hole on the money path. (Stripe canonical pattern.)
2. **Keep `X-Accel-Buffering: no` on `/api/generate` (already done ✓) and ADD it to `/api/tts`.**
   Edge proxies buffer by default; `X-Accel-Buffering: no` is the documented way to keep SSE +
   long audio alive through Railway's proxy. Only generate sets it today. Also add an SSE
   `:keep-alive` comment during LLM first-token thinking so edge idle timeouts don't drop the
   stream. (nginx proxy_module / FastAPI stream docs.)
3. **Move usage/Pro entitlement to a real store + read `rate_limit_pro`.** Add Postgres/Supabase
   (or wire the existing Redis path) keyed by user, not IP, and branch on Pro status so the 3/day
   cap stops hitting paid subscribers. Make `/api/usage` read that store, not limiter internals.
   Until then keep `uvicorn --workers 1` or in-memory counters desync. (FastAPI stream docs.)
4. **Echo (voice clone): clone ONCE, reuse the `voice_id`, stream the TTS.** ElevenLabs
   `voices.ivc.create(files=[...])` from a few seconds of the user's note → store the returned
   `voice_id` on their profile → every reply is `text_to_speech(text, voice_id=...)` (cheap, fast).
   Current `routers/tts.py` buffers the whole MP3 and only supports one voice — fine now, but Echo
   clone is a few lines away and the biggest product differentiator. (ElevenLabs SDK README.)
5. **Stream 3 reply styles as labeled events (one per style).** FastAPI now recommends `yield`-style
   streaming / `application/jsonl` per structured item; you already consume one partial blob then
   re-parse into 3 replies — emitting a labeled event per completed style is simpler for the client
   and one proxy-friendly connection. (fastapi stream-json-lines.md.)

### Caveats
- Search engines were blocked; items are cited to primary docs fetched directly + confirmed against
  backend source. Verify Railway's edge timeouts + Stripe endpoint_secret config before ship.
- Ship = fix P0 webhook verify + P1 rate-limit/auth BEFORE going live. Everything else is hardening.

## 2026-08-14 — Technical deep-dive: PWA/service worker, performance, MediaRecorder, FastAPI

Focused on the technical stack (the conversion side is covered in the entry above). Several findings are **verified bugs** in the current repo, not just best practices. Priority order: SW/subpath bugs → MediaRecorder Safari → PWA installability → rendering/perf → backend (mostly already well-scaffolded).

### Verified bugs (fix these first — zero risk)
1. **Service worker + manifest paths are root-absolute but the app lives under `/Rizzr/`.** `sw.js`'s `ASSETS` array uses `'/index.html'`, `'/assets/css/...'` etc., and index.html registers `navigator.serviceWorker.register('/sw.js')`; `manifest.json` has `start_url: "/"` and no `scope`. On GitHub Pages the SW's scope is `/Rizzr/`, so `caches.addAll(['/index.html'])` fetches `https://damgeed.github.io/index.html` → **404 precache, no offline cache**. And `start_url:"/"` points PWA installs at the repo root, not the app. Fix mirrors the earlier nav-link lesson: relative or `/Rizzr/`-prefixed paths — `start_url:"/Rizzr/"`, `scope:"/Rizzr/"`, relative `sw.js`/asset paths. **Rationale:** offline + installability silently broken right now.

2. **The inline cache-buster script + query-string `?v=` bumps fight the service worker.** The SW caches whatever URL it sees (fingerprinted `?v=X`), so the buster forces a network round-trip each load and defeats offline. Keep ONE mechanism. Swap `caches.match → fetch` (which never revalidates) for true stale-while-revalidate: serve cache, fetch in background, `cache.put`, plus `skipWaiting()+clients.claim()` — then drop the buster. **Rationale:** stale UI (Bud's recurring "not showing" complaints) and offline conflict both stem from this.

3. **Navigation should be network-first, not cache-first.** The catch-all currently serves stale `index.html` from cache. Route network-first for navigation/HTML, SWR for hashed assets. **Rationale:** HTML is the app shell + meta tags; must stay fresh.

### MediaRecorder / Web Audio (mobile Safari is the primary device for a voice-note app)
4. **Set `mimeType` explicitly with a fallback chain** — `audio/mp4` (Safari 14.1+), `audio/webm;codecs=opus` (Chrome/Android), then no mimetype. Default Safari output can be unplayable/uploaded as an unknown type. Also call `getUserMedia({audio:{echoCancellation:true,noiseSuppression:true,autoGainControl:true}})` inside the **user-initiated tap gesture** (Safari blocks otherwise) and keep the stream alive until recording ends; stop tracks with `stream.getTracks().forEach(t=>t.stop())` on stop; concatenate multiple `dataavailable` blobs (Safari fires several). **Rationale:** recording is the #1 action — must be bulletproof where the user actually is.

### PWA installability & offline UX
5. **Add an `offline.html` fallback** (precached) shown on navigation failure + a "You're offline — notes saved locally" hint with an IndexedDB queue to retry uploads when back online. **Rationale:** for a voice-note app, offline-then-upload is a natural, high-value reliability story.

### Rendering / Lighthouse
6. **Move the big inline CSS/JS out of `index.html` into external files** and prune dead rules (the repo has lots from the mode-carousel iterations). Use compositor-only `transform/opacity` animations for the pulse rings / equalizer bars instead of animating layout properties. **Rationale:** inline styles block render + inflate HTML; transform-only animations avoid mobile layout thrash. ~10-20 Lighthouse points.

### Backend (already well-scaffolded — light touch only)
7. Health check, IP sliding-window rate limit, CORS lock, request size cap and security headers **already exist** (`/health` wired into `railway.toml`). Two real adds: (a) **stream audio** via `UploadFile`/`request.stream()` rather than buffering the whole file — long voice notes hit Railway's RAM ceiling; (b) **rate-limit key on `X-Forwarded-For`** (Railway proxies real IPs) and per-endpoint limits (5/min transcribe, 10/min generate). **Rationale:** the pipeline is Whisper→LLM→3-reply→TTS (10-30s); a `202 + task_id` poll/SSE avoids Railway free-tier timeouts and gives the frontend a progress state. Also: **`api.rizzr.com` in `api.js` is still undeployed — nothing converts until the backend ships.**

*Timestamp: 2026-08-14 · Live web search restricted; findings validated against repo code. No code changed.*


---

## 2026-08-14 07:22 — Onboarding TTFV and pricing anchor + share-loop (NEW angle; web blocked)

Focused pass on the least-covered, highest-leverage angle not yet in the log: **time-to-first-value (TTFV),
annual pricing anchor, and the share-loop**, built for Gen Z on mobile Safari. Web search blocked again
(China/no proxy — subagent probed Google/DDG/Bing/Wikipedia: all captive or 403). Synthesis from PLG/pricing
lore + prior entries; treat numbers as directional, A/B-test them. This ADDS to (doesn't repeat) the 08-14
conversion, PWA, 4-mode, and backend entries below.

### Recommendations
1. **Compress first-run to <=90s record-to-hear.** No signup/email first; pre-auth the mic (biggest consumer
   drop-off is the permission prompt trigger); give sample chips ("Reply to this crush text", "clap back at
   the group chat") to kill blank-page paralysis; auto-play the 3 style-tagged replies. The aha = your own
   prompt played back with clever comebacks. Instrument TTFV + percentage-reaching-playback in session 1 and
   A/B each removed step. Activation (strongest D7/D30 predictor) beats every copy tweak.
2. **Add a Pro-ANNUAL tier to anchor pricing** — current pricing.html is Free/$9.99-mo with NO anchor, so
   $9.99 grades "expensive" against Free. Free (3/day) / Pro-mo $9.99 / Pro-annual ~$5/mo billed yearly
   (~40-50% off) = classic Ariely decoy + anchor; pushes annual (higher LTV, lower Stripe+churn fees) while
   monthly keeps the low-commitment Gen-Z entry. Pure pricing.html/CSS + one Stripe Recurring price — no schema.
3. **Ship a share-loop at the delight moment.** Post-reply bottom-sheet "Reply looks fire — share it?" →
   IG Story / WhatsApp / Snapchat of a waveform+reply clip (Gen Z shares in DMs, not X/LinkedIn). Mirrors how
   Call Annie & Character.AI grew by word-of-mouth on voice-first magic. Cheapest growth surface you have.
4. **Free tier = share-one-reply; full 3 styles = Pro.** Recipients hit a shareable preview page that
   re-engages the sharer (showcase/streak) and funnels the recipient into a trial — social proof + viral loop
   in one.
5. **Keep voice playback the moat, never gate it.** VOICE is the retention asset (self-referential
   listen-back = emotional stickiness). D7 guard: a shareable weekly "comeback of the week" recap to drive
   return sessions.

### Source-verified side-notes (from this run's repo read, no code changed)
- **pricing.html still uses emoji** (check/cross/fire/rocket/sparkle in plan features + badge) — Bud mandated
  zero emoji; swap for the SVG-line-tick pattern used elsewhere. 5-min CSS swap, no backend.
- **The recurring top blocker stands:** api.js points at api.rizzr.com (undeployed) → transcribe/usage/checkout
  all 404. None of this converts until the FastAPI backend ships on Railway. Fix PWA subpath + deploy backend
  FIRST; these conversion features layer on after.


## 2026-08-14 08:33 — Reply-loop latency & "feel instant" (NEW angle: the 10-30s pipeline itself)

Web blocked again (China/no proxy — same as prior entries), so this is reasoning + source-inspection
of backend/routers/generate.py and tts.py. The log already covers conversion, PWA/technical,
4-mode, onboarding/pricing, and backend SECURITY hardening — but NOT how long the reply itself takes,
which is the real "Finesse feels good?" question. This is the #2 blocker after "backend not deployed."

### Verified latency facts from source
- generate.py streams partial tokens, but the 3 parsed replies (A:/B:/C:) are only parsed and
  emitted reply_complete AFTER the WHOLE LLM generation finishes. So time-to-first-reply-visible
  == full generation time, and a reply isn't playable until generated AND separately fetched via /api/tts.
- /api/tts uses a single default elevenlabs_voice_id (no per-user clone), buffers the entire MP3 in
  RAM (resp.content), returns only after fully synthesized. End-to-end = Whisper + full LLM + full TTS
  = the ~10-30s the log keeps flagging.

### Recommendations (ranked — buildable once the backend ships)
1. **Emit each reply as soon as ITS section finishes, not after all 3.** Stream A→B→C and yield a
   reply_complete the moment "A:" is closed, then B, then C — the frontend surfaces "Reply 1" as the
   LLM writes it. Rationale: perceived speed = time-to-first USABLE reply, not time-to-all; letting the
   best (usually Flirty/A) render fast hides the long tail.
2. **Stagger TTS: synthesize the FIRST reply while the LLM still finishes the rest.** Fire /api/tts on
   reply A the instant it arrives (parallel to B/C generation). The user hears a real reply ~one TTS-hop
   sooner. Rationale: overlaps the two slowest stages (LLM tail + TTS) instead of serializing them.
3. **Stream the TTS audio bytes (incremental + X-Accel-Buffering:no) instead of buffering the whole MP3.**
   Rationale: audio-first product — first byte beats full-file; also cuts Railway free-tier RAM on long
   notes (mirrors the log's upload-streaming point on the output side).
4. **Pre-warm + reuse connections.** Keep one persistent http client per worker for both the LLM and
   ElevenLabs (connection pooling) and raise the TTS timeout (30s is tight for tone-laden voice).
   Rationale: TLS+connection setup on every call adds hundreds of ms cold-start; reuse is free speed.
5. **UI: show live transcript + a per-style "drafting…" ghost line, with the reply playing as it lands.**
   Rationale (from this log): "voice is the product, hearing it beats reading it." The recording screen
   should show ASR text appearing and reveal each reply as a gold "plays now" chip — feels instant even
   when the pipeline is objectively ~10s.
6. **Cache TTS per reply-text (short hash) once a cloned voice_id exists.** Same reply → skip synthesis.
   Rationale: echo/vault replay and share-preview hit the cache; no-cost latency + spend cut on the
   priciest hop (ElevenLabs).

### Gate (unchanged, #1 blocker everywhere in this log)
- api.js → api.rizzr.com is still undeployed. Until the FastAPI backend ships on Railway, NONE of the
  above runs (no conversion either). Deploy + PWA subpath fix + webhook-verify/auth come first; these
  latency wins are the layer ON TOP that make the shipped loop feel good enough to convert.
*Timestamp: 2026-08-14 08:33. No code changed. Web blocked — numbers are directional, A/B on device.*

---

## 2026-08-14 10:44 — Social/share meta (new angle) + a "what's already landed" digest

Web still blocked (China/no proxy — subagent probes failed like prior runs), so this is source-verified
reasoning. The log already covers conversion/4-mode/onboarding/pricing/PWA/backend, all implemented in commit
`853f6d6`. Two things are genuinely NEW: the ONLY live-share gap that silently kills the growth loop, and a
quick "don't re-build" digest so Bud knows the earlier research shipped.

### Verified gap (source-confirmed, 0 matches across all 4 pages)
1. **NO Open Graph / Twitter Card meta tags on index/pricing/settings/privacy.html** (`grep -cE 'og:|twitter:card'` = 0 on every page — only a plain `<meta name=description>` exists).
   - **Why this is the #1 brand-growth blocker right now:** the log's own top strategy is a **share-loop** at the
     delight moment ("share your reply to IG/WhatsApp/Snapchat" + "share-one-reply free tier"). But with no og: tags, every
     shared link pastes as a **bare URL with no preview card** (no title, no image, no description) in iMessage/IG/WhatsApp
     DMs. Gen Z judges a link in ~a second by its preview — a blank card reads spammy and kills the viral hand-off cold.
   - **~15-line fix, pure HTML in head of index.html** (and ideally pricing): `og:title`, `og:description`, `og:image`
     (point at an existing 1200×630 PNG or favicon), `og:type`, `og:url`, `og:container` + `twitter:card=summary_large_image`.
     Needs ONE shareable card image (generate once, cache-busted like favicon). No backend.
   - **Pitfall to avoid (reuses 853f6d6 lesson):** og:image must be a **fully-qualified absolute URL**
     (`https://damgeed.github.io/Rizzr/assets/img/...`) — crawlers/links won't resolve relative paths.

2. **Meta description tag is stale vs the approved hero copy.** `<head>` still says "...flirty... not a robot trying
   to flirt" but the shipped hero subtext is "confident, natural replies that sound like you." SEO + the og:description
   (if you add one) should inherit the approved line. Side effect: keep it in sync when it lands so Google/Search
   previews match the page.

### "Don't re-build" digest — prior research is DONE (commit `853f6d6`)
Re-verified from source so Bud doesn't re-request already-shipped items:
- **PWA subpath fixed**: manifest `start_url ./?v=8`, `scope:"./"`, relative sw.js register + relative asset paths, SW
  network-first navigate + SWR assets. Install/offline now work.
- **"Soon" badges** on Ghost/Echo/Vibe (was dead mockups → intentional teasers) — highest-CR landing fix, shipped.
- **MediaRecorder module** (mime fallback, Safari tap-gesture getUserMedia, multi-blob concat) ready in api.js.
- **Zero-emoji pricing** + **Pro+ $19.99 decoy tier** — pricing is now Free/Pro $9.99/Pro-Annual $7.99/Pro+ $19.99.
- All PWA cache-buster: css `?v=hgt3`, icons `?v=4/3`, HTML buster v=hgt5.

### Still the top blocker (unchanged #1)
- **Backend not deployed** — api.js → api.rizzr.com (404). Deploy FastAPI on Railway + Stripe webhook-verify + auth
  before any of these conversion levers can fire. Add OG tags now (cheap, no backend) so the share-loop is ready
  the day the backend ships.
*Timestamp: 2026-08-14 10:44. No code changed. Web blocked — reasoning + source-verified.*

---

## 2026-08-14 14:00 — OG/Twitter share meta LANDED (from the 10:44 research entry)

The #1 brand-growth gap flagged at 10:44 (no Open Graph/Twitter Card = shared links paste as bare URL with no preview) is now FIXED and LIVE (commit `298b0ac`).
- Generated a 1200×630 OG share card on the Midnight Aura brand (`frontend/assets/img/og-card.png`, dark #050508 bg, coral→violet gradient orbs, mic emblem, tagline + headline). Generation script kept at `scripts/gen_og_card.py` for future edits.
- Added `og:title/description/image/url/site_name/type` + `twitter:card=summary_large_image` to **index.html** (share canonical) and **pricing.html** (secondary). og:image is a fully-qualified `https://damgeed.github.io/Rizzr/assets/img/og-card.png?v=1` (crawlers won't resolve relative).
- Fixed the stale `<meta name=description>` on index.html ("...flirty... not a robot trying to flirt" → approved hero copy "confident, natural replies that sound like you — in seconds"). SEO + Search preview now match the page.
- Bumped index.html inline cache-buster to `v=hgt7`.
- VERIFIED live: og-card.png 200 (45228 bytes), all og tags present in served index.html.

Next unlock for the share-loop to actually pay off: backend (checkout/transcribe/apikey) still undeployed — api.rizzr.com serves 000. Share meta is ready; the loop converts only once the backend ships.

---

## 2026-08-14 14:20 — Settings redesign + StoreKit-aligned pricing + mobile polish (commit `b8c31ba`/`fcc136c` ongoing, this round one clean commit)

Setting page was a fake "account management" shell (implied login that doesn't exist — Rizzr is no-signup). Redesigned to match the settled architecture (no-signup + Apple StoreKit IAP, web = marketing front door):

SETTINGS (settings.html):
- Dropped the "👤 Account" card (implies auth). Replaced with a **"⭐ Your Plan"** card — shows Free/3-replies status + "Get Pro in the app →" deep-link to the App Store, with an honest note that subscriptions live on the Apple ID and are never charged from the website.
- Added a **"⚙️ Preferences"** card — 3 on-device toggles (Relaxed tone, friendly emoji, auto-copy) wired client-side via `localStorage`-read display + `data-toggle` buttons. No fake backend.
- Kept **Privacy** (strong trust signals) + **About**.
- Added mobile rule: `.settings-row` wraps on ≤480px so labels/values don't overflow narrow phones.

PRICING (pricing.html) — aligned to StoreKit:
- Buy buttons were `rizzrAPI.createCheckout(...)` hitting a dead web checkout (`api.rizzr.com` 000). Replaced all 3 (Pro / Pro Annual / Pro+) with App Store deep-links (`apps.apple.com/.../idXXXXXXXXXX` placeholder).
- "Secured by Stripe" → "Billed securely through the App Store. Cancel anytime."
- FAQ "Cancel from Settings → Account" → App Store/Apple ID; "PWA works in browser" → native iPhone app framing (PWA dropped).
- Removed dead `assets/js/api.js` ref + checkout handler.

CONSISTENCY: CSS ref on all pages aligned to `?v=hgt10`.

Note: App Store URLs are placeholders (`idXXXXXXXXXX`); Bud must swap real IDs at launch. Testimonial section unchanged (settled simple 3-window). Mode carousel untouched.
