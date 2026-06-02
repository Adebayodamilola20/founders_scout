# Founders Scout PRD

Status: Draft  
Version: 1.0  
Owner: Adebayo Stephen Oluwadamilola

## 1. Product Vision

Founders Scout is a high-end, niche-agnostic lead generation engine. It transforms Google Maps business data into a curated stream of business opportunities by identifying digital gaps that match the user's service niche.

The product is not limited to website discovery. It is a multi-vertical shell that adapts its scanning, scoring, and outreach logic based on what the user sells.

Examples:

- A web developer sees businesses with no website.
- A photographer sees businesses with weak or missing photos.
- An SEO specialist sees businesses with weak ratings but meaningful review volume.
- A social media manager sees businesses with no visible social presence.
- An interior designer sees businesses where presentation and positioning suggest a design upgrade opportunity.

## 2. Problem Statement

Most lead generation tools return broad, noisy datasets that still require heavy manual filtering. Freelancers and small agencies do not need more raw leads. They need businesses with obvious, service-specific deficiencies they can fix.

Founders Scout should reduce that noise by:

- mapping the user's niche to a digital-gap rule set
- scanning Google Maps and business metadata
- filtering businesses by service-specific need
- scoring opportunity quality
- enabling immediate outreach from mobile

## 3. Product Goals

### Primary Goals

- help users discover nearby businesses that are strong service-fit prospects
- reduce the time between discovery and first contact
- make digital gaps visible and easy to act on
- support multiple freelance and agency verticals from one product shell

### Secondary Goals

- provide premium visual differentiation through an industrial-tech design system
- support real-time scanning with low-latency lead streaming
- build a reusable platform for new niches, scoring models, and outreach flows

## 4. Core Product Concept

Founders Scout adapts to the user's selected niche. The user chooses their service during onboarding, and that selection configures the system's:

- scan filters
- lead scoring logic
- gap labels
- recommended contact actions
- AI-generated pitch style

This makes the app feel specialized to each user even though the platform is shared.

## 5. Target Users

- freelance web developers
- web designers
- photographers
- SEO specialists
- social media managers
- interior designers
- small digital agencies
- growth freelancers looking for location-based business prospecting

## 6. Multi-Vertical Orchestration

Each niche should resolve to a `niche_id` and a set of rules.

### Example Niche Mappings

| User Choice | `niche_id` | Logic Filter |
| --- | --- | --- |
| Web Developer | `web_dev` | `place.website == null` |
| Web Designer | `web_design` | `place.website == null` or weak site quality signal |
| Photographer | `photography` | `place.photos.length < 2` or low-res image signal |
| Social Media Manager | `social_media` | `place.social_links == null` |
| SEO Expert | `seo` | `place.rating < 3.5 && place.user_ratings_total > 20` |
| SEO Specialist | `seo_local` | `place.rating < 3.8 && place.user_ratings_total > 15` |
| Interior Designer | `interior_design` | category-aware presentation/opportunity rule |

The architecture should support new niches through config and rule registration rather than hardcoded UI-only logic.

## 7. User Flow

### 7.1 Launch

The user opens the app.

### 7.2 Onboarding

The user selects the service they provide. This determines which digital gaps Founders Scout should search for.

### 7.3 Scan

The backend fetches businesses from Google Maps based on location, radius, and optional category constraints.

### 7.4 Filter

Only businesses that match the active niche rule are surfaced to the user.

### 7.5 Inspect

The user taps a business to review lead details, imagery, gap summary, and available actions.

### 7.6 Engage

The user calls, copies the number, opens Google Maps, or sends a prefilled WhatsApp pitch.

## 8. Screens

The visual reference file at `/Users/adebayostephenoluwadamilola/Desktop/founders_scout_human_screens.html` shows a more complete UI direction than the base three-screen concept. It includes onboarding, radar, lead, pitch, and account flows.

### 8.1 MVP Screens

1. Niche Onboarding
2. Radar Map
3. Live Scanning State
4. Lead Feed
5. Lead Detail
6. Gap Report
7. Pitch Composer
8. Contact Action Layer

### 8.2 Expanded Screens

- sign up
- login
- saved lists
- search
- pitch history
- dashboard
- alerts
- settings
- upgrade flow

## 9. Screen Specifications

### Screen 1: Niche Onboarding

Goal: configure the scanner.

Requirements:

- tappable niche cards
- short explanation of what Founders Scout will look for
- persistence via `SharedPreferences`
- restore previous niche on app relaunch

### Screen 2: Radar

Goal: visual lead discovery.

Requirements:

- dark map styling
- live scan pulse animation
- neon cyan markers
- bottom lead feed
- progress state during active scan

### Screen 3: Lead Feed

Goal: fast triage of opportunities.

Requirements:

- glassmorphic cards
- business name, category, location
- gap badge
- score or priority indicator
- quick preview actions

### Screen 4: Lead Detail

Goal: conversion.

Requirements:

- hero business image
- gap alert summary
- business metadata
- floating action bar with `Copy Number`, `Call`, `WhatsApp Pitch`, and `Open in Maps`

### Screen 5: Gap Report

Goal: explain why this lead matters.

Requirements:

- clear gap diagnosis
- niche-specific reasoning
- visual and textual evidence where possible
- suggested service angle

### Screen 6: Pitch Composer

Goal: generate personalized outreach.

Requirements:

- niche-aware prompt system
- editable message
- WhatsApp-first flow
- future support for alternate channels

## 10. Design System: Industrial Tech

The UI should feel tactical, premium, dark, and high-performance.

### Palette

- Background: `#0D0D0D`
- Accent: `#00E5FF`
- Borders: `#FFFFFF1A`
- Primary text: `#F5F7FA`
- Secondary text: `#A7B0BE`

### Visual Language

- glassmorphism for lead cards and sheets
- blur around `15px`
- glowing cyan highlights for active scan states
- strong map contrast
- controlled warning colors for opportunity severity

### Motion

- circular scan pulses
- live streaming feel during discovery
- smooth bottom sheet transitions
- subtle marker emphasis animations

## 11. Technical Architecture

## 11.1 Frontend

Stack:

- Flutter
- `google_maps_flutter`
- `url_launcher`
- cached network image strategy
- local persistence with `SharedPreferences` and SQLite

Responsibilities:

- onboarding and niche selection
- radar visualization
- streamed lead rendering
- lead details and action handling
- local caching

## 11.2 Backend

Stack:

- Go
- Google Places API
- gRPC streaming
- PostgreSQL
- Redis

Responsibilities:

- accept scan requests
- resolve `niche_id`
- query and enrich Google Places data
- apply filters and scoring
- cache results
- stream leads in real time

## 12. Backend Scan Pipeline

1. Receive scan request from client.
2. Load niche filter definition by `niche_id`.
3. Query Google Places `nearby_search` or `text_search`.
4. Normalize results into internal models.
5. Apply a first-pass gap filter.
6. Fetch `place_details` for strong candidates.
7. Resolve phone, photos, hours, ratings, and other metadata.
8. Compute lead score and gap labels.
9. Cache enriched lead data.
10. Stream lead events back to Flutter over gRPC.

## 13. Worker Pool and Rate Control

The Go backend should use concurrent workers with guardrails.

Requirements:

- bounded goroutine worker pool
- token bucket rate limiter
- per-request context cancellation
- retries with backoff
- `place_id` deduplication
- API cost protection

## 14. Image Management

Photo handling is especially important for visual-service niches.

### Backend Responsibilities

- fetch `photo_reference` IDs from Google Places
- cache photo references by `place_id`
- build high-resolution thumbnail or preview URLs
- return image metadata in lead payloads

### Flutter Responsibilities

- render cached network images
- use first image as hero
- use fallback placeholder if no image is available
- keep scrolling smooth in feed and detail views

## 15. Real-Time Communication

The preferred bridge is gRPC streaming.

### Event Types

- `scan_started`
- `scan_progress`
- `lead_found`
- `lead_updated`
- `scan_completed`
- `scan_failed`

### Why gRPC

- typed contracts
- low-latency updates
- easier scan/session modeling than ad hoc payloads

WebSockets can be used temporarily during prototyping, but gRPC should remain the target production path.

## 16. Contact Actions

The lead detail screen should support:

- copy number
- direct phone call
- WhatsApp deep link
- open in Google Maps

Example WhatsApp route:

```text
wa.me/<number>?text=<url_encoded_pitch>
```

## 17. Dynamic Pitching

Pitch generation must depend on both the business and the user's niche.

### Prompt Inputs

- `business_name`
- `business_type`
- `city`
- `niche_id`
- `gap_summary`
- `tone`

### Output Rules

- short
- personalized
- natural
- niche-specific
- soft CTA
- suitable for WhatsApp

## 18. Data Architecture

### PostgreSQL

Use PostgreSQL for:

- saved leads
- pitch records
- niche definitions
- scan history
- analytics-friendly persistence

### Redis

Use Redis for:

- hot lead cache
- photo reference cache
- scan session state
- rate limiting counters
- repeated Google payload avoidance

### Local SQLite

Use local SQLite on device for:

- recent leads
- saved prospects
- offline reopen
- pitch drafts

## 19. Security Requirements

### API Key Security

- restrict Google Maps keys by app signing identity
- do not ship unrestricted production keys
- split client and server concerns where appropriate

### Privacy

- avoid storing unnecessary personal user data
- process live scan data in-memory where feasible
- cache only what supports UX and reliability

### Cost Controls

- enforce rate limits
- budget scan concurrency
- cap enrichment depth when necessary

## 20. MVP Requirements

### Must Have

1. Niche onboarding with persistence
2. Radar map with industrial-tech styling
3. Real-time scan progress
4. Niche-aware lead filtering
5. Lead feed and detail flow
6. WhatsApp pitch generation
7. Call and maps integration
8. Local lead caching

### Nice to Have

- saved collections
- analytics dashboard
- follow-up reminders
- richer social auditing
- subscription tiering

## 21. Current Repository Status

This repo is currently an early-stage Flutter shell and not a completed product implementation.

Current state:

- Flutter project scaffold exists
- product direction is now documented
- backend structure exists but must be implemented further
- UI, streaming, and niche engine still need product code

## 22. Next Steps

1. Replace the demo Flutter app with app routing and themed foundations.
2. Implement onboarding and niche persistence.
3. Define protobuf contracts for scans and lead events.
4. Build the Go scanner service.
5. Add Google Places integration and rate limiting.
6. Implement radar and lead feed UI.
7. Implement lead detail and outreach actions.
8. Add pitch generation service.
9. Add PostgreSQL, Redis, and SQLite caching layers.

## 23. Success Criteria

Founders Scout succeeds when a user can:

- choose a niche in under a minute
- launch a scan and see relevant leads in real time
- understand why each lead is a fit
- contact a business in one or two taps
- repeatedly use the app as a daily prospecting workflow
