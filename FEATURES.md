# Muse — Complete Feature Guide

**Version 1.0.0** | Developed by Ephesian28 LLC  
**Website:** [museapp.us](https://museapp.us)

---

## 🏠 Home Feed (FeedView)

The main screen users see after onboarding. A **full-screen, vertical-swipeable feed** (TikTok-style paging) displaying curated content.

### Content Types
- **Affirmations** — Positive, identity-shifting statements organized by category (Confidence, Self-Worth, Self-Love, Peace, Growth, Gratitude, Strength, Self-Care, Anxiety, etc.)
- **Quotes** — Inspirational quotes from thinkers like Carl Jung, Eckhart Tolle, Rumi, Alan Watts, Seneca, Marcus Aurelius, and Buddha, organized by category (Self-Discovery, Purpose, Presence, Mental Health, Healing, Wisdom, Inner Peace, etc.)
- Content is loaded from bundled JSON files (`quotes.json`, `affirmations.json`) with hardcoded fallback defaults

### Feed Interactions
- **Swipe vertically** to browse content (native iOS paging)
- **Category tabs** at the top to switch between Affirmations and Quotes
- **Heart button** to save/unsave the current item to Favorites
- **Share button** to share the current item via iOS share sheet
- **Long-press on category tag** to open the **Category Picker** for filtering by specific categories
- **Adaptive font sizing** — adjusts based on word count (shorter = larger text)
- **Landscape support** — UI adapts, hides certain controls in landscape

### Hamburger Menu (LiquidMenu)
A floating liquid-style menu in the top-right providing access to:
- **Explore** — Opens the content library (MixPopupView)
- **Background** — Opens the background picker to customize visuals

---

## 📚 Explore Library (MixPopupView)

A browsable content library with two tabs:

### Affirmations Tab
- **Favorites** — All saved affirmations with count
- **My Own Affirmations** — User-created/saved affirmations
- **Category Grid** — Browse all affirmation categories (Self-Love, Confidence, Peace, Gratitude, Strength, Love, Growth, Mental Health, Abundance, Courage, etc.)

### Quotes Tab
- **Favorites** — All saved quotes with count
- **Category Grid** — Browse all quote categories

Each category opens a dedicated list view where users can browse, save, and interact with individual items.

---

## 🧘 Practice Hub (StartAffirmationsView)

The core practice launcher — accessed via the **"Start" button** on the home feed. This is a comprehensive hub with multiple wellness modalities:

### 1. Immersive Affirmation Sessions
- **Duration options:** 1 minute, 3 minutes, 5 minutes, 10 minutes
- **Two generation modes:**
  - **Curated affirmations** — Uses the user's saved/favorited affirmations or category-specific content
  - **AI-Generated affirmations** — Through the guided AI chat (AIAffirmationsChatView)
- **Immersive experience** includes:
  - Full-screen display with customizable background
  - **AI text-to-speech narration** via OpenAI TTS API (natural-sounding "alloy" voice)
  - Audio caching for instant replay of previously generated speech
  - iOS native speech fallback if API is unavailable
  - Background music continues during sessions
  - 3-2-1 countdown with bell sound before session starts
  - Auto-advances through affirmations with speech timing
  - Volume controls for voice and background music
  - Screen stays awake during sessions (idle timer disabled)
  - **Save prompt** after AI-generated sessions — users can save generated affirmations to their library

### 2. AI Affirmation Generator (AIAffirmationsChatView)
- **Guided 4-question chat flow:**
  1. "What would you like to accomplish?" (goals)
  2. "What's been holding you back?" (challenges)
  3. "What strengths do you have?" (assets)
  4. "What kind of person do you want to become?" (vision)
- AI generates personalized affirmations using **OpenRouter / Google Gemini**
- Affirmation count scales with session duration (5 for 1min → 40 for 10min)
- Generated affirmations feed directly into an immersive session
- **Daily limit:** 5 AI generations per day

### 3. Breathwork Sessions (ImmersiveBreathworkView)
**Four breathing patterns:**
- **Box Breathing** — 4s inhale, 4s hold, 4s exhale, 4s hold (stress relief)
- **4-7-8 Relaxation** — 4s inhale, 7s hold, 8s exhale (deep relaxation)
- **4-6 Calming** — 4s inhale, 6s exhale (anxiety relief)
- **Energizing Breath** — 2s inhale, 1s hold, 4s exhale, 1s hold (energy boost)

**Breathwork features:**
- Visual breathing circle animation (expands/contracts with phases)
- Phase indicators (inhale/hold/exhale) with progress tracking
- Audio cues for each phase transition (different sounds per phase)
- Customizable session duration
- Volume controls
- Real-time elapsed time display
- Sessions logged to progress tracking

### 4. Healing Frequencies (ImmersiveFrequenciesView)
**Nine Solfeggio/healing frequencies:**
| Frequency | Purpose |
|-----------|---------|
| 174 Hz | Pain relief & safety |
| 285 Hz | Tissue repair & regeneration |
| 396 Hz | Releasing fear & guilt |
| 417 Hz | Facilitating change |
| 432 Hz | Natural relaxation & meditation |
| 528 Hz | Love & transformation |
| 639 Hz | Relationships & connection |
| 741 Hz | Intuition & mental clarity |
| 852 Hz | Spiritual awareness |

**Frequency features:**
- Animated pulsing circle visualization with glow effects
- Audio playback of the selected frequency tone
- Independent volume controls for frequency and background music
- Elapsed time display
- Tap to show/hide controls
- Sessions logged to progress tracking

### 5. Manifestation Session (ImmersiveManifestView)
- **5-minute guided manifestation** with scripted narration
- **Teleprompter-style scrolling text** that follows audio progress
- Pre-recorded audio narration with timeline scrubber
- Play/pause controls
- Independent volume controls for voice and background music
- Auto-scrolling to the active segment
- Sessions logged to progress tracking

---

## 💬 Muse AI Chat (ChatBoxView)

An AI-powered personal growth companion accessible from the home feed.

### Chat Features
- **Conversational AI** powered by **OpenRouter / Google Gemini**
- Real-time streaming responses (or fallback to non-streaming)
- **Voice input** via on-device speech recognition (Apple Speech framework)
- Text input with auto-resizing text field
- Message history with user/AI bubbles
- Loading animations while AI responds
- **Daily limit:** 25 chat messages per day

### AI Intelligence (MuseAgentService)
- **Personalized system prompts** incorporating:
  - User profile (goals, life domains, spiritual orientation, challenge level)
  - Current streak and progress data
  - Communication style preference (concise/detailed/balanced)
  - Time of day awareness
- **Crisis detection** — Identifies keywords related to self-harm, suicidal thoughts, etc.
  - Auto-prepends crisis resource information (988 Suicide Hotline, Crisis Text Line)
  - Emphasizes professional help over AI assistance
- **Feature intent detection** — Recognizes when users ask about breathwork, affirmations, frequencies, manifestation, or progress and can suggest relevant app features
- **Knowledge domains:** Neuroscience, psychology, mindfulness, breathwork, manifestation, cognitive behavioral techniques, positive psychology, habit formation

### Chat History (ChatHistoryView)
- **Multiple chat sessions** — Start new conversations, switch between past ones
- Persistent storage via `ChatStorageService`
- Auto-generated titles based on first user message
- Delete individual sessions
- **Context memory** — AI receives summaries of recent past conversations for continuity
- Insight extraction from conversations (topics discussed)

---

## 📓 Journal (JournalView)

A structured daily journaling experience accessible from the Muse Chat screen.

### Daily Check-In Flow
1. **Mood Selection** — Choose current mood with emoji (😔 → 😁 scale)
2. **Grounding Prompt** — Randomized reflective question with free-text response
3. **Gratitude Section** — Three things to be grateful for
4. **What Would Make Today Great** — Three intentions/goals
5. **Daily Affirmation** — Personal affirmation for the day
6. **Evening Reflection** — Three amazing things that happened
7. **How Could I Have Made Today Better** — Growth reflection
8. **Dynamic Quote & Affirmation** — Includes rotating quote and affirmation

### Journal Features
- One entry per day (edit existing or create new)
- **AI Insights** — AI-powered analysis of journal entries (daily limit: 3)
- View past entries in a scrollable list
- Dark theme with glassmorphic design
- Persistent storage via UserDefaults

---

## 📊 Progress Dashboard (MuseProgressView)

Comprehensive stats and tracking, accessible via the streak/fire button on the home feed.

### Metrics Tracked
- **Current Streak** — Consecutive days with at least one session
- **Longest Streak** — All-time best streak
- **Total Sessions** — All-time affirmation session count
- **Today's Sessions** — Sessions completed today
- **Breathwork Stats** — Total sessions and cumulative time
- **Frequency Stats** — Total sessions and cumulative time
- **Journal Entries** — Total entries count

### Visualizations
- **Weekly Progress Chart** — Bar chart showing daily session counts (Mon-Sun)
- **Contribution Calendar** (ContributionCalendarView) — GitHub-style heatmap showing activity over time
- **Activity metric cards** with icons and color coding
- **Time breakdown** — Formatted hours/minutes for breathwork and frequency time

### Additional
- **Notification Settings** — Configure reminders
- **Legal Section** — Links to Privacy Policy and Terms of Service (in-app views)
- Daily progress auto-refreshes on appear

---

## 🔔 Onboarding (OnboardingContainerView)

A 9-screen guided onboarding flow for new users:

1. **Splash Screen** — App branding/intro
2. **Science Hook** — Why affirmations work (neuroscience angle)
3. **Blockage Selection** — User selects their primary challenge:
   - Anxiety Loop
   - Scarcity Mindset
   - Imposter Syndrome
   - Relationship Patterns
   - Lack of Direction
   - Self-Sabotage
   - Other (free-form flow)
4. **Specificity Input** — User describes their challenge in detail
5. **Spiritual Orientation** — Choose secular, spiritual, or blended
6. **Challenge Level** — Choose gentle, moderate, or bold affirmation style
7. **AI Calibration** — Animated "neural analysis" while generating affirmations
   - Pre-built affirmations for standard blockages (instant, no AI call)
   - AI-generated affirmations for "Other" flow (via OpenRouter)
8. **Immersive Preview** — Users experience their first affirmation session right in onboarding
9. **Welcome Screen** — Highlights all app features before entering the main app

### User Profile Collection
Onboarding captures and stores:
- Primary goal / blockage
- Spiritual orientation (secular / spiritual / blended)
- Challenge level (gentle / moderate / bold)
- Communication style (concise / detailed / balanced)
- Life domains of focus

---

## 🎨 Customization

### Background Themes (BackgroundPickerView)
- Multiple visual backgrounds users can choose from for sessions and the home feed
- Selected via hamburger menu → Background
- Persisted across app launches via `@AppStorage`

### Background Music
**Three ambient soundscapes + silent option:**
| Track | Description |
|-------|-------------|
| Forest Birds | Peaceful forest sounds |
| River | Flowing river water |
| Rain | Gentle rain ambiance |
| None | Silent |

- **Volume control** with persistence
- **Background audio** support — continues playing when app is backgrounded (during immersive sessions)
- Auto-resumes on returning to foreground
- Preview tracks before selecting

---

## 📱 Widgets (MuseWidgetsExtension)

### Quote Widget
- Displays a random saved quote (or default if none saved)
- Supports Small, Medium, and Large widget sizes
- Refreshes on a timeline (updates hourly with 5 entries)
- Dark theme with rainbow angular gradient border
- Shows quote text and author attribution

### Affirmation Widget
- Displays a random saved affirmation (or default if none saved)
- Supports Small, Medium, and Large widget sizes
- Same refresh/design pattern as quote widget
- Shows affirmation text and category

### Widget Data Sync
- Widgets read from App Group shared UserDefaults (`group.Ephesian28LLC.Muse`)
- Main app syncs saved quotes/affirmations to App Group on every save
- Widget timelines auto-reload when content changes

---

## 🔐 Rate Limiting (EntitlementManager)

Daily usage limits for AI-powered features to manage API costs:

| Feature | Daily Limit |
|---------|-------------|
| Muse Chat Messages | 25/day |
| AI Affirmation Generations | 5/day |
| Journal AI Insights | 3/day |

- Limits reset at midnight local time
- User-friendly alerts when limits are reached
- **All non-AI features are unlimited** (sessions, breathwork, frequencies, manifest, journal entries, saving favorites, etc.)

---

## 🛠 Technical Architecture

### APIs
- **OpenRouter / Google Gemini** — AI chat, affirmation generation, journal insights
- **OpenAI TTS API** — Text-to-speech for affirmation narration (voice: "alloy", model: "tts-1")
- **Apple Speech Framework** — On-device voice-to-text for chat input

### Data Persistence
- **SwiftData** — Session history (`AffirmationSession` model) for progress tracking
- **UserDefaults** — Quotes, affirmations, AI-generated content, user profile, preferences, daily usage counts, journal entries, chat sessions
- **App Group UserDefaults** — Shared data for widget access
- **File Cache** — TTS audio files cached in app's cache directory

### Key Services
| Service | Purpose |
|---------|---------|
| `MuseAgentService` | AI system prompts, crisis detection, feature intent detection |
| `SpeechService` | OpenAI TTS with caching and iOS fallback |
| `SpeechRecognizer` | On-device voice input |
| `ChatStorageService` | Chat session persistence and context retrieval |
| `StorageService` | Quotes, affirmations, music preferences |
| `ProgressService` | Streaks, session logging, stats |
| `ContentLoader` | JSON content loading with fallbacks |
| `EntitlementManager` | Daily rate limiting |
| `MuseUserProfileService` | User preferences and personalization |
| `ManifestGenerationService` | Manifestation session audio/script |
| `BackgroundMusicManager` | Ambient music playback with background support |

### Design System (Theme.swift)

#### 🎨 Color Profile

**Primary Colors:**
| Token | Hex | Role |
|-------|-----|------|
| `museDeepNavy` | `#1A1A1D` | Main backgrounds (all screens, sheets, modals) |
| `museSoftWhite` | `#F5F5F7` | Primary text color throughout the app |
| `museAccentBlue` | `#007AFF` | Call-to-action buttons, tab selection indicators, interactive elements |

**Gradient Colors (Premium Accent):**
| Token | Hex | Role |
|-------|-----|------|
| `museGradientStart` | `#6B4CE6` | Purple — start of premium gradient (CTA buttons, AI avatar, onboarding accents) |
| `museGradientEnd` | `#4A90E2` | Blue — end of premium gradient |

**Secondary Colors:**
| Token | Hex | Role |
|-------|-----|------|
| `museDarkGray` | `#2C2C2E` | Card backgrounds, glassmorphism base layer |
| `museMediumGray` | `#48484A` | Borders, dividers, subtle separators |
| `museLightGray` | `#8E8E93` | Secondary/placeholder text, unselected tab labels |
| `museSuccessGreen` | `#34C759` | Confirmations, completed states, journal check-in |
| `musePremiumGold` | `#FFD700` | Premium badges, streak fire icon |
| `museTeal` | `#5AC8FA` | AI-generated content indicators, quote tag color |
| `musePurple` | `#AF52DE` | Accent highlights, affirmation tag color |
| `musePink` | `#FF2D55` | Energetic accents, frequency time metric cards |
| `museOrange` | `#FF9500` | Alerts, warm accent, breathing pattern icons |

**Convenience Aliases:**
| Alias | Maps To | Usage |
|-------|---------|-------|
| `themeBackground` | `museDeepNavy` | Default background reference |
| `themeText` | `museSoftWhite` | Default text reference |
| `themeAccent` | `museAccentBlue` | Default accent reference |
| `themeSecondaryAccent` | `museTeal` | Secondary accent reference |

**Rainbow Border Gradient** (used on category selectors, widgets, pulsing animations):
`#FF3B30` → `#FF9500` → `#FFCC00` → `#34C759` → `#00C7BE` → `#007AFF` → `#AF52DE` → `#FF2D55`
(Red → Orange → Yellow → Green → Teal → Blue → Purple → Pink)

**Glassmorphism Effect:**
- `museDarkGray` at 60% opacity over `.ultraThinMaterial` blur
- Applied to chat headers, card overlays, and floating UI elements

**Dark Mode Only** — `preferredColorScheme(.dark)` enforced globally; no light mode variant exists.

---

#### 🔤 Typography

**Primary Font: SF Pro Rounded** (Apple system font, `design: .rounded`)
Used for all UI chrome — headers, body text, buttons, labels, captions.

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `museDisplayLarge()` | 34pt | Bold | Main screen titles |
| `museDisplayMedium()` | 28pt | Bold | Section headers, progress dashboard |
| `museDisplaySmall()` | 22pt | Semibold | Sub-section headers, journal empty state |
| `museHeadline()` | 17pt | Semibold | Card titles, emphasized labels |
| `museSubheadline()` | 15pt | Medium | Supporting labels, metadata |
| `museBodyLarge()` | 17pt | Regular | Primary reading text |
| `museBodyMedium()` | 15pt | Regular | Secondary body text |
| `museBodySmall()` | 13pt | Regular | Small descriptions |
| `museCaption()` | 12pt | Regular | Timestamps, fine print |
| `museButtonLarge()` | 17pt | Semibold | Primary action buttons |
| `museButtonMedium()` | 15pt | Semibold | Secondary action buttons |
| `museAffirmation()` | 18pt | Medium | Affirmation text in lists/cards |
| `museQuote()` | 20pt | Light Italic | Quote text in lists/cards |

**Secondary Font: New York (Serif)** (Apple system font, `design: .serif`) + **Palatino Bold**
Used for literary/editorial content — the feed, journal entries, manifestation scripts, and feature titles. Gives content an elegant, book-like feel.

| Context | Font | Size | Weight |
|---------|------|------|--------|
| Feed card — affirmation/quote text | System Serif | 20–32pt (adaptive) | Medium |
| Feed card — author attribution | System Serif | 13–21pt (adaptive) | Regular |
| Journal page — section headers | `Palatino-Bold` | 24–28pt | Bold |
| Journal page — grounding prompt | System Serif | 22pt | Medium |
| Journal page — entry text | System Serif | 16–18pt | Regular |
| Journal page — category labels | System Serif | 10pt | Bold |
| Muse Chat — header title | `Palatino-Bold` | 28pt | Bold |
| Chat History — title | `Palatino-Bold` | 24pt | Bold |
| Manifestation — teleprompter script | System Serif | 24pt | Regular |
| Category detail — affirmation text | System Serif | 16–18pt | Medium |
| AI Chat — empty state prompt | System Serif | 32pt | Regular |
| Immersive affirmation — display text | System Serif | 36pt | Medium |

**Font Size Scaling (Feed):**
Affirmation and quote text on the home feed uses adaptive sizing based on word count:
| Word Count | Font Size |
|------------|-----------|
| 0–5 words | 32pt |
| 6–10 words | 28pt |
| 11–15 words | 24pt |
| 16–20 words | 22pt |
| 21+ words | 20pt |

---

#### ✨ Animations & Effects
- **Pulsing rainbow border** — Rotating angular gradient with subtle scale pulse (10s rotation, 4s pulse)
- **Static rainbow border** — Linear gradient stroke on cards and category pickers
- **Liquid menu** — Floating radial menu with spring animations
- **Glassmorphism** — Frosted glass card effects with ultra-thin material blur
- **Spring transitions** — `spring(response: 0.3)` for tab switching and content transitions
- **Breathing circle** — Scale animation synced to breathwork phase durations
- **Frequency glow** — Pulsing circle with glow shadow effects

### Platform
- **iOS 17+** with SwiftUI
- **iPhone** (portrait-optimized, landscape-supported)
- **iPad** supported with adaptive layouts
- **Background audio** enabled via `UIBackgroundModes`
