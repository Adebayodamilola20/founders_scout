# Founders Scout

The formal product requirements document lives at [docs/PRD.md](/Users/adebayostephenoluwadamilola/Desktop/founders_scout/docs/PRD.md:1).

Founders Scout is a multi-vertical lead generation app that turns Google Maps business data into a curated feed of opportunities for freelancers, consultants, and boutique agencies. Instead of only looking for businesses without websites, the product adapts to the user's niche and identifies the specific "digital gap" that signals a sales opportunity.

This repository is the Flutter client shell for the product. The intended production system pairs this mobile app with a Go backend that scans Google Places data, applies niche-aware filters, enriches promising leads, and streams them back to the app in real time.

## Google Maps Setup

The radar home screen uses `google_maps_flutter`.

- Put `GOOGLE_MAPS_API_KEY=...` in the root `.env` file.
- Android reads the key from `.env` during Gradle configuration.
- iOS includes the same `.env` through xcconfig so `Info.plist` can resolve `GMSApiKey`.
- Use `.env.example` as the template if you need to recreate the local env file.

## Product Vision

Founders Scout should feel like a premium scouting instrument for modern service providers. A web designer, photographer, SEO consultant, social media manager, interior designer, or any other niche operator should be able to open the app, choose what service they offer, and immediately see nearby businesses that visibly need that service.

The product is not website-only.

The core idea is:

1. The user defines what they sell.
2. The system maps that choice to a "digital gap" rule set.
3. The backend scans Google Maps and business metadata.
4. The app surfaces only the businesses with the strongest fit.
5. The user contacts those businesses through direct outreach flows such as WhatsApp, phone, or map handoff.

## Core Product Thesis

Most lead tools show massive, noisy lists. Founders Scout should do the opposite. It should narrow the market to a tactical feed of businesses that are visibly under-optimized in a way the user can fix.

Examples:

- A web developer sees businesses with no website.
- A photographer sees businesses with weak or missing photography.
- An SEO specialist sees businesses with enough review volume to matter but weak ratings that suggest poor digital reputation.
- A social media manager sees businesses with weak or missing social presence.
- An interior designer can be routed to businesses whose presentation, pricing position, or category suggest a design uplift opportunity.

## Multi-Vertical Orchestration

Founders Scout is a shell product. Its behavior changes based on the selected niche.

Each niche has:

- A `niche_id`
- A display label
- A gap detection rule
- A lead scoring profile
- A pitch generation style
- A recommended CTA priority

### Example Niche Mapping

| Niche | Example `niche_id` | Digital Gap Logic |
| --- | --- | --- |
| Web Developer | `web_dev` | `place.website == null` |
| Web Designer | `web_design` | `place.website == null` or outdated/mobile-poor site from metadata audit |
| Photographer | `photography` | `place.photos.length < 2` or low-quality/low-resolution photo signal |
| Social Media Manager | `social_media` | `place.social_links == null` or no detectable social presence |
| SEO Expert | `seo` | `place.rating < 3.5 && place.user_ratings_total > 20` |
| SEO Specialist | `seo_local` | `place.rating < 3.8 && place.user_ratings_total > 15` |
| Interior Designer | `interior_design` | category-specific rule, for example `restaurant` or `retail` venues with low presentation signals |

The final implementation should support arbitrary future niches through config rather than hardcoded branches.

## User Flow

### 1. Onboarding

The user selects the kind of service they provide:

- Web Developer
- Photographer
- SEO Expert
- Social Media Manager
- Interior Designer
- Additional niches added later

This choice should be persisted locally using `SharedPreferences`, then mirrored to backend session context so scans and pitches remain niche-aware.

### 2. Scan

The user lands on the radar screen and starts a scan around a selected city, map area, or current location.

The backend:

- queries Google Places nearby search or text search
- paginates and throttles requests
- applies niche-aware gap rules
- enriches promising businesses with place details
- streams partial lead results back to the app

### 3. Filter

Only leads that match the user's gap criteria should appear in the feed. The app should prioritize signal quality over volume.

### 4. Inspect

The user taps a marker or lead card to open a detailed profile with business imagery, contact options, map context, and a clear "Gap Alert" explanation.

### 5. Engage

The user can:

- copy the business number
- call directly
- open the location in Google Maps
- generate and send a niche-specific WhatsApp pitch

## Screen System

The HTML mockup at `/Users/adebayostephenoluwadamilola/Desktop/founders_scout_human_screens.html` shows a broader, app-store-grade product vision than the initial three-screen PRD. It includes onboarding, radar, lead feed, pitch studio, and profile/admin flows.

That mockup currently suggests these major screen groups:

- Onboarding
- Radar
- Leads
- Pitch AI
- Profile

### Priority MVP Screens

These are the screens that should be treated as the first shippable flow:

1. Niche Onboarding
2. Radar Map
3. Live Scanning State
4. Lead Feed
5. Lead Detail
6. Gap Report
7. Pitch Generator
8. WhatsApp / Call / Maps action layer

### Expanded Product Screens

The mockup also points toward a more complete premium app with:

- sign up and login
- saved lead collections
- search
- pitch history
- analytics dashboard
- notification/alert center
- settings
- upgrade/paywall flow

## Design System: Industrial Tech

The visual direction should feel tactical, premium, dark, and performance-oriented rather than playful or generic.

### Core Palette

- Background: `#0D0D0D`
- Accent: `#00E5FF`
- Border: `#FFFFFF1A`
- Text primary: `#F5F7FA`
- Text secondary: `#A7B0BE`
- Success/support accent: restrained green when needed for live scan or positive status
- Warning/gap accent: amber or red for high-value missing assets

### UI Principles

- Dark map with a custom Google Maps JSON style
- Neon cyan for active states, scan rings, markers, highlights, and CTA emphasis
- Glassmorphic cards with blur around `15px`
- Thin luminous borders, low-opacity whites, and subtle depth layers
- Dense information layout that still feels premium and fast
- Motion should suggest scanning, acquisition, and live intelligence

### Component Direction

- Lead cards should use blurred translucent surfaces
- Gap badges should be bold, compact, and immediately legible
- Map markers should glow in cyan, with urgency states in amber/red
- Bottom sheets should feel like control panels rather than consumer app drawers

## Backend Architecture

The backend should be implemented in Go as a concurrent lead scanning engine.

### Responsibilities

- accept scan requests from Flutter
- resolve the active `niche_id`
- query Google Places APIs
- enforce rate limiting and quotas
- enrich businesses with detailed metadata
- score and filter leads
- cache scan results and photo references
- stream leads back to the mobile client

### Service Layout

A practical layout could look like:

```text
backend/
  cmd/api/
  internal/config/
  internal/googleplaces/
  internal/scanner/
  internal/niches/
  internal/scoring/
  internal/cache/
  internal/pitch/
  internal/stream/
  internal/security/
```

### Scan Pipeline

1. Receive a scan request containing:
   - `niche_id`
   - coordinates or map bounds
   - radius
   - business categories
   - pagination settings
2. Resolve the niche rule set.
3. Run `nearby_search` or `text_search` against Google Places.
4. Normalize the response into internal place models.
5. Apply a first-pass niche filter to discard weak candidates quickly.
6. Fetch `place_details` only for candidates with enough potential.
7. Compute gap flags and a lead score.
8. Cache enriched lead data.
9. Stream qualifying leads to Flutter over gRPC.

### Worker Pool

The scanner should use a worker pool with bounded concurrency so the system can scan aggressively without uncontrolled API spend.

Recommended controls:

- goroutine workers for enrichment
- context cancellation per scan session
- token bucket rate limiter for Google calls
- retry policy with backoff
- deduplication by `place_id`
- per-user scan budget enforcement

## Niche Rule Engine

The rule engine should not be tightly coupled to UI labels. It should load gap definitions from structured config or a registry.

### Rule Inputs

- place category/type
- website presence
- rating
- ratings count
- photo count
- photo quality signal
- social links or social metadata presence
- opening hours completeness
- price level
- description completeness where available

### Example Rule Shape

```json
{
  "niche_id": "photography",
  "title": "Photographer",
  "filters": [
    { "field": "photos.length", "op": "<", "value": 2 },
    { "field": "photo_quality.low_res", "op": "==", "value": true }
  ],
  "pitch_style": "visual-upgrade",
  "priority_actions": ["whatsapp", "call", "maps"]
}
```

## Lead Scoring

A lead should not only pass the gap filter. It should also be ranked.

Possible score inputs:

- gap severity
- category fit for the chosen niche
- presence of phone number
- existence of WhatsApp-friendly contact route
- ratings count
- proximity
- business activity signals
- number of missing digital assets

Example high-level formula:

```text
lead_score =
  gap_weight +
  contactability_weight +
  niche_relevance_weight +
  proximity_weight +
  opportunity_weight
```

## Google Places and Image Handling

Photography and visual-led niches depend heavily on image quality, so image handling should be explicit in the backend design.

### Photo Reference Strategy

The Go service should:

- store `photo_reference` IDs returned by Google Places
- map those references to `place_id`
- generate signed or proxied thumbnail URLs where appropriate
- cache thumbnail metadata for repeated UI loads

### Image Pipeline

1. Fetch `photo_reference` values from place details.
2. Cache the references with TTL in Redis or PostgreSQL.
3. Build thumbnail requests for the Flutter app.
4. Return a lead payload containing hero image and gallery metadata.
5. Let Flutter display images using cached network loading.

### Thumbnail Policy

- first photo becomes hero image
- additional photos populate gallery strips and lead cards
- failed images should degrade gracefully to branded placeholders
- image fetches should be aggressively cached to keep scrolling smooth

### Flutter Image Layer

The client should use cached image widgets so:

- radar feed scrolling remains smooth
- detail screens load quickly
- repeated viewing of the same lead does not refetch everything

## Frontend Architecture

The client is a Flutter mobile app focused on field-ready prospecting.

### Primary Responsibilities

- capture niche and scan preferences
- render the radar map
- display live scan progress
- consume streamed leads
- present lead details and gap summaries
- launch contact actions
- cache local state for session continuity

### Suggested Flutter Structure

```text
lib/
  app/
  core/
    theme/
    models/
    services/
  features/
    onboarding/
    radar/
    leads/
    pitch/
    profile/
```

### State and Persistence

- `SharedPreferences` for onboarding selections and lightweight settings
- SQLite for local lead cache, recent scans, and saved pitches
- in-memory state for live scan sessions
- optional repository pattern for swapping remote/local data sources cleanly

## Real-Time Communication

The preferred real-time bridge is gRPC streaming.

### Why gRPC

- structured contracts between Go and Flutter
- low-latency incremental lead delivery
- easier long-term support for scan events, partial updates, and typed errors

### Stream Events

The backend should be able to emit:

- `scan_started`
- `scan_progress`
- `lead_found`
- `lead_updated`
- `scan_completed`
- `scan_failed`

### Fallback

WebSockets can be used during prototyping, but the target production path should remain gRPC.

## Contact Actions

The lead detail view should be optimized for conversion.

### Core Actions

- Copy Number
- Call
- WhatsApp Pitch
- Open in Google Maps

### Mobile Integrations

- `url_launcher` for `tel:` deep links
- `url_launcher` for `https://wa.me/<number>?text=<encoded_message>`
- map handoff to Google Maps app or browser

## Dynamic Pitching

The outreach layer should not use one static template. The message should change based on:

- business name
- niche chosen
- detected gap
- city/category context
- tone preference

### Prompt Inputs

- `business_name`
- `niche_id`
- `gap_summary`
- `business_type`
- `city`
- `tone`
- optional CTA style

### Example Prompt Contract

```text
Generate a short WhatsApp outreach message for a business owner.

Business name: Mama Titi Kitchen
Business type: restaurant
City: Lagos
User niche: web developer
Detected gap: no website found

Write a concise, friendly message that points out the opportunity without sounding robotic or spammy. End with a simple soft CTA.
```

### Output Requirements

- short enough for WhatsApp
- personalized
- niche-specific
- avoids exaggerated claims
- makes the gap obvious
- closes with a low-friction CTA

## Data and Caching Strategy

The product requirement calls for PostgreSQL and Redis, and that is a sensible split.

### PostgreSQL

Use PostgreSQL for:

- durable scan history
- niche definitions
- saved leads
- pitch logs
- user settings
- analytics aggregates

### Redis

Use Redis for:

- hot lead cache
- scan session state
- rate limiting counters
- cached Google Places payloads
- photo reference TTL caching

### Local Device Cache

Use SQLite in the Flutter app for:

- recently viewed leads
- saved prospects
- offline-friendly lead reopening
- pending pitch drafts

## Security and Cost Controls

### Google Maps API Key

- restrict keys by package name and SHA-1 on Android
- use platform-specific restrictions for iOS
- never hardcode unrestricted production keys in the client

### Rate Limiting

The Go backend should use a token bucket limiter to:

- protect costs
- avoid runaway scans
- throttle concurrent workers
- smooth request bursts

### Data Privacy

- avoid storing unnecessary user data on the server
- process leads in-memory where possible during live scan
- store only what is necessary for product continuity and caching
- keep sensitive contact workflows auditable

## Suggested MVP Scope

The current repo is still an early Flutter scaffold, so the first meaningful milestone should stay narrow.

### MVP Deliverables

1. Niche onboarding with persistence
2. Radar screen with industrial-tech theme
3. gRPC scan session start and progress stream
4. Lead feed with gap badges
5. Lead detail with hero image and CTA actions
6. WhatsApp pitch generation
7. Local cache for recent leads

### Phase 2

- auth
- saved lists
- dashboard and analytics
- smarter scoring
- richer social presence audits
- subscription/paywall

### Phase 3

- collaborative team workspaces
- AI-assisted follow-up flows
- automated scheduled scans
- CRM export
- multi-channel outreach orchestration

## Current Repo State

This repository currently contains the default Flutter project scaffold and should be treated as the starting shell, not the finished product architecture.

Right now:

- the Flutter app exists
- the product README is now defined
- the Go backend is still to be built
- the niche engine, gRPC contracts, caching layers, and production UI still need implementation

## Build Direction

The intended stack is:

- Flutter for the mobile client
- Go for the scanning and enrichment backend
- gRPC for real-time lead streaming
- PostgreSQL and Redis for server-side persistence and caching
- SQLite for local mobile caching
- Google Places / Maps APIs for business discovery and map rendering

## Next Implementation Steps

1. Replace the demo Flutter counter app with app routing and theme setup.
2. Implement the industrial-tech design system in Flutter.
3. Create onboarding with niche selection and `SharedPreferences`.
4. Define protobuf contracts for scan requests, progress events, and lead payloads.
5. Build the Go scan engine with rate-limited Google Places access.
6. Add lead scoring and niche registry support.
7. Implement radar map, live scan UI, and lead feed.
8. Add lead detail actions for call, WhatsApp, copy, and maps.
9. Add AI pitch generation endpoint and client flow.
10. Add PostgreSQL, Redis, and SQLite caching layers where each is appropriate.

## Summary

Founders Scout should become a niche-adaptive lead intelligence system for freelancers and small agencies. The product should not be limited to finding businesses without websites. Its strength is the ability to transform one scanning engine into many specialized opportunity detectors, each matched to the service the user actually sells.

That is the foundation this repository should now build toward.
