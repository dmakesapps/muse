---
description: Battle plan for App Store preparation - Muse App
---

# 🚀 Muse App Store Preparation Battle Plan

## Executive Summary
This plan covers everything needed to prepare Muse for the App Store, including:
- Secure API key management (production-ready)
- Rate limiting to prevent API abuse
- Beautiful onboarding experience
- Code cleanup and optimization

---

## Phase 1: API Key Security (🔴 CRITICAL)

### Current State
- API keys stored in `APIKeys.swift` (gitignored ✅)
- Direct API calls from client (OpenAI TTS, OpenRouter for AI chat)
- No rate limiting on API usage

### Problem with Current Approach
⚠️ **Shipping API keys in the app binary is DANGEROUS**
- Keys can be extracted from the IPA using reverse engineering
- Anyone with the key can run up your API bill
- OpenAI and OpenRouter explicitly forbid this

### Solution Options

#### Option A: Backend Proxy Server (RECOMMENDED ✅)
Set up a simple backend that:
1. Receives requests from your app
2. Adds API keys server-side
3. Forwards to OpenAI/OpenRouter
4. Returns response to app

**Pros:** Most secure, full control, can add analytics
**Cons:** Need to host a server (Vercel/Railway/Fly.io - free tiers available)

#### Option B: iOS Keychain + Server-Fetched Keys
1. On first launch, app fetches encrypted keys from your server
2. Store in iOS Keychain (secure enclave)
3. Keys never in binary

**Pros:** No ongoing server costs for proxying
**Cons:** Keys still on device (less secure than Option A)

#### Option C: RevenueCat + Server Functions (If Premium)
If you plan to monetize:
1. Use RevenueCat for subscriptions
2. Store API keys in RevenueCat's backend
3. Fetch keys only for paying users

### Recommended: Option A with Vercel Edge Functions
```
📁 muse-backend/
├── api/
│   ├── tts.ts        # Proxy for OpenAI TTS
│   └── chat.ts       # Proxy for OpenRouter chat
└── vercel.json
```

---

## Phase 2: Rate Limiting (🟡 IMPORTANT)

### Why Rate Limiting?
- Prevent API abuse (cost protection)
- Ensure fair usage across users
- Required by most API providers

### Implementation Strategy

#### Client-Side Rate Limiting
```swift
class RateLimiter {
    // TTS: Max 30 requests per minute
    // Chat: Max 20 messages per hour (AI chat)
    // Store last request times in UserDefaults
}
```

#### Server-Side Rate Limiting (if using backend)
- Track by device ID or user ID
- Return 429 (Too Many Requests) when exceeded
- Show friendly message to user

### Suggested Limits for Free Tier
| Feature | Limit | Time Window |
|---------|-------|-------------|
| AI Affirmations | 10 generations | per day |
| Muse Chat | 20 messages | per day |
| TTS (Speech) | 50 affirmations | per session |

---

## Phase 3: Onboarding Experience (🟢 HIGH IMPACT)

### Onboarding Flow Design
```
Screen 1: Welcome
├── App logo with beautiful animation
├── "Welcome to Muse"
└── "Your daily sanctuary for mindfulness"

Screen 2: Personalization
├── "What brings you to Muse?"
├── [Reduce Stress] [Build Confidence] [Better Sleep]
├── [Self-Love] [Gratitude] [Motivation]
└── (Multi-select, saves to determine initial content)

Screen 3: Notifications
├── "Stay on track with gentle reminders"
├── Time picker for preferred reminder time
└── [Enable Notifications] / [Maybe Later]

Screen 4: Your First Affirmation
├── Beautiful full-screen affirmation card
├── "Let's begin your journey"
└── [Start My First Session]
```

### Technical Implementation
1. Create `OnboardingView.swift` with PageTabViewStyle
2. Store completion state in `@AppStorage("hasCompletedOnboarding")`
3. Store preferences in `UserDefaults` (categories, notification time)
4. Skip onboarding for returning users

---

## Phase 4: Code Cleanup & Optimization

### Remove Debug Code
- [ ] Remove all `print()` statements (or wrap in `#if DEBUG`)
- [ ] Remove any hardcoded test data
- [ ] Ensure no API keys in code (double-check)

### App Icon & Launch Screen
- [ ] Ensure App Icon is set for all sizes
- [ ] Create beautiful Launch Screen storyboard
- [ ] Match launch screen to initial app state

### Performance
- [ ] Profile with Instruments for memory leaks
- [ ] Optimize image assets (use Asset Catalog properly)
- [ ] Test on oldest supported device

### Privacy & Compliance
- [ ] Create Privacy Policy (required)
- [ ] Create Terms of Service
- [ ] Add `NSMicrophoneUsageDescription` if using mic
- [ ] Add `NSUserNotificationsUsageDescription`

---

## Phase 5: App Store Assets

### Required Materials
- [ ] App Name: "Muse - Daily Affirmations" (or similar)
- [ ] Subtitle: "Mindfulness & Positive Thinking"
- [ ] App Description (4000 chars max)
- [ ] Keywords (100 chars max)
- [ ] Screenshots (6.7", 6.5", 5.5" iPhones + iPad)
- [ ] App Preview Video (optional but recommended)

### Categories
- Primary: Health & Fitness
- Secondary: Lifestyle

---

## Implementation Priority Order

### Week 1: Must-Have Before Launch
1. ✅ Set up backend proxy for API keys
2. ✅ Implement client-side rate limiting
3. ✅ Build onboarding flow
4. ✅ Remove debug code

### Week 2: Polish
5. ✅ Create Privacy Policy & Terms
6. ✅ Finalize App Store assets
7. ✅ Test on multiple devices
8. ✅ Submit for review

---

## Quick Start Commands

### Create Backend (Vercel)
```bash
npx create-next-app@latest muse-backend --typescript
cd muse-backend
# Add API routes for proxying
vercel deploy
```

### Build for Release
```bash
xcodebuild -scheme Muse -configuration Release archive
```

---

## Files to Create

1. `Views/Onboarding/OnboardingView.swift` - Main onboarding container
2. `Views/Onboarding/WelcomeView.swift` - Welcome screen
3. `Views/Onboarding/PersonalizationView.swift` - Category selection
4. `Views/Onboarding/NotificationsView.swift` - Notification setup
5. `Services/RateLimitService.swift` - Rate limiting logic
6. `Services/APIProxyService.swift` - Backend communication (if using proxy)

---

## Questions to Answer

1. **Monetization Strategy?**
   - Free with limits + Premium subscription?
   - One-time purchase?
   - Completely free?

2. **Target Audience?**
   - Age range affects content and design
   - Helps with App Store marketing

3. **Backend Hosting Preference?**
   - Vercel (easiest, free tier)
   - Railway (simple, affordable)
   - Your own server?

---

*This plan will be updated as we implement each phase.*
