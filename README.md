# Founders Scout (Scoutify)

[![Flutter](https://img.shields.io/badge/Flutter-3.9+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Go](https://img.shields.io/badge/Go-1.22+-00ADD8?logo=go&logoColor=white)](https://go.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**Founders Scout** (branded in-app as **Scoutify**) is a premium, multi-vertical lead generation engine purpose-built for freelancers, consultants, and boutique agencies. It transforms raw Google Maps business data into a curated, actionable feed of sales opportunities by identifying **digital gaps** — specific service deficiencies that signal a business needs your help.

> **Stop chasing cold leads. Founders Scout shows you exactly which nearby businesses need your service, why they need it, and how to reach them — all from your phone.**

---

## Table of Contents

- [Core Concept](#core-concept)
- [Who It's For](#who-its-for)
- [How It Works](#how-it-works)
- [Niche Intelligence System](#niche-intelligence-system)
- [Key Features](#key-features)
  - [Onboarding & Setup Wizard](#-onboarding--setup-wizard)
  - [Radar Map View](#-radar-map-view)
  - [Live Analysis Engine](#-live-analysis-engine)
  - [Curated Lead Feed](#-curated-lead-feed)
  - [AI Pitch Generator](#-ai-pitch-generator)
  - [Lead Detail & Outreach](#-lead-detail--outreach)
  - [Stats Dashboard](#-stats-dashboard)
  - [Profile & Preferences](#-profile--preferences)
- [Tech Stack](#tech-stack)
  - [Frontend (Flutter)](#frontend-flutter)
  - [Backend (Go)](#backend-go)
  - [Infrastructure](#infrastructure)
- [Architecture](#architecture)
  - [App Architecture (Flutter)](#app-architecture-flutter)
  - [Backend Scan Pipeline](#backend-scan-pipeline)
- [Design System](#design-system)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Roadmap](#roadmap)
- [License](#license)

---

## Core Concept

Most lead generation tools return massive, noisy datasets that still require heavy manual filtering. Founders Scout flips this model: **instead of showing you every business, it shows you only the businesses with a specific, visible, serviceable problem.**

The core thesis:

1. You define **what service you sell** (e.g., web design, photography, SEO, social media management)
2. The system maps your service to a **digital gap rule set** (e.g., "no website" for web developers, "fewer than 2 photos" for photographers)
3. The backend scans Google Maps and business metadata, applying niche-aware filters
4. The app surfaces only the businesses that match your gap criteria, scored by opportunity strength
5. You contact them directly through one-tap outreach — WhatsApp, phone call, or Google Maps handoff

---

## Who It's For

- **Freelance web developers & designers** — find businesses without a website or with an outdated web presence
- **Photographers & videographers** — discover businesses with weak or missing visual content
- **SEO specialists** — target businesses with enough reviews to matter but low ratings that signal poor digital reputation
- **Social media managers** — identify businesses with no visible social media presence
- **Interior designers** — find businesses whose presentation, pricing position, or category suggest a design upgrade opportunity
- **Small digital agencies** — equip sales teams with a mobile-first prospecting tool
- **Growth freelancers** — looking for location-based business prospecting in any niche

---

## How It Works

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Choose    │     │    Set      │     │   Scan &    │     │  Outreach   │
│  Your Service│ ──► │  Location   │ ──► │   Analyze   │ ──► │   & Close   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
  Web Dev, SEO,        City/Area        Google Maps +       WhatsApp, Call,
  Photography, etc.                     Gap Detection       Maps Handoff
```

### Step-by-Step Flow

1. **Launch** — Open the app (branded as **Scoutify**)
2. **Onboard** — Select your service niche and configure what gaps to look for
3. **Set Location** — Choose your target city or area
4. **Scan** — The app connects to the backend (or uses Google Places directly) to discover nearby businesses
5. **Analyze** — Each business is checked against your niche gap rules
6. **Review Leads** — Browse a curated feed of matched opportunities
7. **Inspect** — Tap any lead for detailed gap analysis, business metadata, and photos
8. **Engage** — One-tap outreach via WhatsApp, phone call, or Google Maps

---

## Niche Intelligence System

Founders Scout is a **multi-vertical shell product**. Its behavior changes dynamically based on the selected niche, without requiring code changes.

| User Service | Niche ID | Gap Filter Logic |
|---|---|---|
| Web Developer | `web_dev` | `place.website == null` |
| Web Designer | `web_design` | `place.website == null` OR weak site quality signal |
| Photographer | `photography` | `place.photos.length < 2` OR low-res image signal |
| Social Media Manager | `social_media` | `place.social_links == null` |
| SEO Expert | `seo` | `place.rating < 3.5` AND `place.user_ratings_total > 20` |
| SEO Specialist (Local) | `seo_local` | `place.rating < 3.8` AND `place.user_ratings_total > 15` |
| Interior Designer | `interior_design` | Category-aware presentation/opportunity rule |

The rule system is **configurable and extensible** — new niches can be added through configuration and rule registration without modifying core application logic.

---

## Key Features

### 📋 Onboarding & Setup Wizard

The initial setup guides users through configuring their prospecting preferences:

- **Service Selection** — Choose from multiple service verticals (Web Development, Photography, SEO, Social Media, Interior Design, etc.)
- **Gap Customization** — Select which specific digital gaps to prioritize (e.g., "No Website", "Weak Reviews", "No Social Presence", "Poor Photography")
- **Category Targeting** — Choose business categories to focus on (Restaurants, Nightclubs, Gyms, Salons, Retail, etc.)
- **Location Setup** — Enter a target city or neighborhood for localized prospecting
- **Country Selection** — Support for location-based targeting across countries

### 🗺️ Radar Map View

A visually striking map-based lead discovery interface:

- **Google Maps Integration** — Powered by `google_maps_flutter` with custom dark map styling
- **Interactive Markers** — Businesses are displayed as map markers at their real locations
- **Bottom Lead Sheet** — A draggable sheet lists nearby leads below the map for quick browsing
- **Pulse Animation** — Circular scan pulse animation creates a live streaming feel during discovery
- **Tap-to-Inspect** — Tap a marker or list item to open detailed lead information
- **Geofence Support** — Location-aware filtering based on user-defined geofences

### 🔬 Live Analysis Engine

The scanning and analysis experience is designed to feel like a premium, real-time instrument:

- **Real-Time Progress** — Live status updates as the system checks businesses
- **Neural Connection Visualizer** — An animated neural network-inspired widget that makes scanning feel intelligent and dynamic
- **Helper Message Rotation** — Contextual messages that update every few seconds to keep users informed
- **Scan Caching** — Results are cached locally to avoid redundant API calls (with configurable cache invalidation)
- **Google Places API Integration** — Direct integration for fetching and analyzing business data

### 📊 Curated Lead Feed

A fast, triage-focused list of discovered opportunities:

- **Glassmorphic Cards** — Premium frosted-glass card design for each lead
- **Gap Badges** — Color-coded badges showing which digital gaps were detected
- **Quick Actions** — WhatsApp, call, and maps buttons directly on each card
- **Sorting & Filtering** — Organize leads by gap type, rating, distance, or opportunity score
- **Pull-to-Refresh** — Trigger a new scan from the feed

### 🤖 AI Pitch Generator

An intelligent outreach companion powered by Mistral AI:

- **Conversational Interface** — Chat-style UI for interacting with "Scout AI"
- **Lead Analysis** — Ask the AI to analyze a lead and explain why it's a good fit
- **Pitch Generation** — Generate personalized outreach messages tailored to the lead and your service
- **Tone Customization** — Choose from multiple pitch templates (Professional, Friendly, Direct, etc.)
- **Template Library** — Save and reuse successful pitch templates
- **One-Tap Copy** — Copy generated pitches to clipboard for use in WhatsApp or email
- **Conversation History** — Browse past pitch threads and regenerate as needed
- **Pricing Guidance** — Ask the AI for pricing recommendations based on the opportunity

### 📍 Lead Detail & Outreach

Deep dive into individual business opportunities:

- **Hero Image** — Full-width business photo when available
- **Gap Summary** — Clear, visual breakdown of detected digital gaps with niche-specific reasoning
- **Business Metadata** — Rating, review count, address, phone, website status, hours, and more
- **Action Bar** — Persistent floating bar with:
  - 📞 **Call** — One-tap phone call
  - 📋 **Copy Number** — Copy phone to clipboard
  - 💬 **WhatsApp Pitch** — Open WhatsApp with a pre-filled pitch message
  - 🗺️ **Open in Maps** — Navigate to the business in Google Maps
- **Outreach Tracking** — Log when you've contacted a lead and track follow-up status

### 📈 Stats Dashboard

Performance tracking for your prospecting activity:

- **Scan History** — View past scans and their results
- **Lead Statistics** — Total leads found, contacted, converted
- **Gap Distribution** — See which digital gaps are most common in your area
- **Activity Timeline** — Track your outreach activity over time

### 👤 Profile & Preferences

User account management:

- **Firebase Authentication** — Secure sign-up and login
- **Profile Management** — Update name, niche preferences, and saved locations
- **Notification Settings** — Configure daily reminders and scan-complete notifications
- **Morning Reminder** — Scheduled 8 AM notification to start your daily prospecting

---

## Tech Stack

### Frontend (Flutter)

| Technology | Purpose |
|---|---|
| **Flutter 3.x** (Dart 3.x) | Cross-platform mobile UI framework |
| **google_maps_flutter** | Interactive map rendering and place markers |
| **Firebase Core / Auth / Firestore** | Authentication, user data, and cloud persistence |
| **cloud_firestore** | Firestore client with offline persistence |
| **url_launcher** | Deep links for phone, WhatsApp, and Maps |
| **Lottie** | Rich vector animations for scan states |
| **Mistral AI API** | AI-powered pitch generation and lead analysis |
| **flutter_local_notifications** | Local push notifications and reminders |
| **timezone** | Timezone-aware scheduling |
| **Google Fonts** | Custom typography |
| **cached_network_image** | Efficient image loading and caching |
| **http** | HTTP client for API communication |

### Backend (Go)

| Technology | Purpose |
|---|---|
| **Go 1.22+** | High-performance backend runtime |
| **Google Places API** | Business data fetching (nearby search, text search, place details) |
| **gRPC (planned)** | Real-time lead streaming to clients |
| **PostgreSQL (planned)** | Persistent lead and user data storage |
| **Redis (planned)** | In-memory caching for scan results and rate limiting |
| **Worker Pool** | Bounded goroutine worker pool for concurrent Places API queries |
| **Token Bucket** | Rate limiter for API quota management |

### Infrastructure

| Service | Purpose |
|---|---|
| **Firebase** | Authentication, Firestore DB, Cloud Functions |
| **Google Maps Platform** | Places API, Maps SDK, Geocoding |
| **Mistral AI** | AI pitch generation |
| **GitHub** | Source control and project management |

---

## Architecture

### App Architecture (Flutter)

```
lib/
├── main.dart                     # App entry point, Firebase init, notifications
├── firebase_options.dart         # Firebase platform config
├── app/
│   └── app.dart                  # App shell with bottom nav + screen routing
├── core/
│   ├── constants/
│   │   └── api_keys.dart         # API key management
│   ├── services/
│   │   ├── app_config_service.dart      # App configuration
│   │   └── notification_service.dart    # Push notification handling
│   ├── theme/
│   │   └── app_theme.dart              # Design system (colors, typography, components)
│   └── models/                          # Shared domain models
├── features/
│   ├── auth/            # Login, signup, auth gate, user profiles
│   ├── onboarding/      # First-launch experience
│   ├── setup/           # Niche selection wizard (service, location, categories)
│   ├── analysis/        # Live scanning engine + progress visualization
│   ├── radar/           # Map view + lead markers + geofence
│   ├── leads/           # Curated feed, detail screen, outreach actions
│   ├── pitch/           # AI chat, pitch generation, template management
│   ├── stats/           # Dashboard and analytics
│   └── profile/         # User settings and preferences
```

### Backend Scan Pipeline

```
┌──────────┐    ┌────────────┐    ┌─────────────┐    ┌───────────┐    ┌──────────┐
│  Client  │    │   API      │    │   Niche     │    │  Google   │    │  Stream  │
│ Request  │───►│  Gateway   │───►│   Resolver  │───►│  Places   │───►│   Leads  │
└──────────┘    └────────────┘    └─────────────┘    │   Query   │    │  to App  │
                                                      └───────────┘    └──────────┘
                                                           │
                                                           ▼
                                                     ┌───────────┐
                                                     │  Enrich   │
                                                     │  Details  │
                                                     └───────────┘
                                                           │
                                                           ▼
                                                     ┌───────────┐
                                                     │   Score   │
                                                     │  & Filter │
                                                     └───────────┘
```

1. **Receive Request** — Client sends scan request with location, niche_id, and filters
2. **Load Niche Rules** — Resolve niche filter definition by `niche_id`
3. **Query Google Places** — `nearby_search` or `text_search` based on location
4. **Normalize Results** — Convert raw API responses into internal business models
5. **Apply First-Pass Gap Filter** — Quick elimination of non-matching businesses
6. **Fetch Details** — `place_details` for strong candidates (phone, photos, hours, ratings)
7. **Compute Score** — Lead score based on gap severity, rating, review count, and distance
8. **Cache Results** — Store enriched data with configurable TTL
9. **Stream to Client** — Real-time lead delivery over gRPC stream

---

## Design System

The UI follows an **Industrial Tech** design language — tactical, premium, dark, and high-performance.

### Color Palette

| Token | Value | Usage |
|---|---|---|
| Background | `#0D0D0D` | Primary background |
| Accent | `#00E5FF` | Active states, scan pulses, highlights |
| Borders | `#FFFFFF1A` | Subtle card and container borders |
| Primary Text | `#F5F7FA` | Headlines and primary copy |
| Secondary Text | `#A7B0BE` | Labels, hints, supporting text |

### Visual Language

- **Glassmorphism** — Frosted-glass effect for lead cards and bottom sheets
- **Blur** — ~15px backdrop blur for depth and layering
- **Glow Effects** — Cyan neon glow for active scan states and markers
- **Dark Maps** — High-contrast map styling for readability
- **Motion Design** — Circular scan pulses, smooth transitions, animated markers

---

## Getting Started

### Prerequisites

- **Flutter SDK** 3.9+ ([install guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK** 3.9+
- **Go** 1.22+ (for backend development)
- **Firebase Project** with Authentication and Firestore enabled
- **Google Maps API Key** with Places API, Maps SDK enabled
- **Mistral AI API Key** (for AI pitch generation, optional)

### Installation

```bash
# Clone the repository
git clone https://github.com/Adebayodamilola20/founders_scout.git
cd founders_scout

# Install Flutter dependencies
flutter pub get

# Run on device/emulator
flutter run
```

### Configuration

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Add your Google Maps API key to `.env`:**
   ```
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
   ```

3. **Firebase Setup:**
   - The project already includes `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - If setting up from scratch, generate these from the Firebase Console
   - Enable **Email/Password** and **Google Sign-In** in Firebase Authentication

4. **Mistral AI (Optional):**
   - Add your Mistral API key in the app configuration or environment
   - Required for AI-powered pitch generation

5. **Platform-Specific Setup:**

   **Android:**
   - The Gradle configuration reads the Maps API key from `.env` automatically
   - Update `android/app/build.gradle.kts` if you need custom build variants

   **iOS:**
   - The Maps API key is read from `.env` through xcconfig configuration
   - Ensure `Info.plist` resolves `GMSApiKey` correctly

---

## Project Structure

```
founders_scout/
├── android/                  # Android platform files
├── ios/                      # iOS platform files
├── lib/                      # Flutter/Dart source code
│   ├── main.dart             # Entry point
│   ├── firebase_options.dart
│   ├── app/
│   │   └── app.dart          # App shell with navigation
│   ├── core/
│   │   ├── constants/
│   │   ├── services/
│   │   └── theme/
│   └── features/
│       ├── auth/
│       ├── onboarding/
│       ├── setup/
│       ├── analysis/
│       ├── radar/
│       ├── leads/
│       ├── pitch/
│       ├── stats/
│       └── profile/
├── backend/                  # Go backend source
│   ├── cmd/api/main.go       # API entry point
│   ├── go.mod
│   └── internal/
│       ├── cache/            # Redis caching layer
│       ├── config/           # Backend configuration
│       ├── googleplaces/     # Google Places API client
│       ├── niches/           # Niche rule definitions
│       ├── pitch/            # Server-side pitch logic
│       ├── scanner/          # Scan orchestration
│       ├── scoring/          # Lead scoring engine
│       ├── security/         # Auth and rate limiting
│       └── stream/           # gRPC streaming
├── assets/
│   ├── branding/             # App logos and brand assets
│   ├── images/               # Screenshots and marketing images
│   └── lottie/               # Lottie animation files
├── docs/
│   └── PRD.md                # Full product requirements document
├── test/                     # Unit and widget tests
├── web/                      # Web platform files
├── macos/                    # macOS platform files
├── linux/                    # Linux platform files
├── windows/                  # Windows platform files
├── pubspec.yaml              # Flutter dependencies
└── .env.example              # Environment variable template
```

---

## Roadmap

### ✅ Complete
- [x] Niche onboarding & setup wizard
- [x] Radar map view with Google Maps
- [x] Google Places API scanning engine
- [x] Curated lead feed with gap badges
- [x] Lead detail screen with action bar
- [x] AI pitch generator (Mistral integration)
- [x] Firebase authentication
- [x] Firestore user profile persistence
- [x] Stats dashboard
- [x] Local notifications & reminders
- [x] Cross-platform (Android, iOS, Web, macOS, Linux, Windows)
- [x] Lottie scan animations
- [x] Geofence support

### 🚧 In Progress
- [ ] Go backend deployment with gRPC streaming
- [ ] Real-time lead streaming to Flutter
- [ ] Advanced lead scoring with machine learning
- [ ] Lead outreach tracking & CRM integration
- [ ] Saved lead lists / collections
- [ ] Pitch history management
- [ ] Email outreach support (via Resend)

### 📋 Planned
- [ ] Google Sign-In
- [ ] Subscription & upgrade flow
- [ ] Email reports & Excel export
- [ ] Team/agency account support
- [ ] Multiple scan profiles
- [ ] Advanced filter presets
- [ ] Lead alerts & push notifications for new opportunities
- [ ] API marketplace for third-party integrations

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Links

- **GitHub Repository**: [github.com/Adebayodamilola20/founders_scout](https://github.com/Adebayodamilola20/founders_scout)
- **Product Requirements Document**: [docs/PRD.md](docs/PRD.md)
- **Author**: Adebayo Stephen Oluwadamilola

---

*Founders Scout — Turn every map into a sales opportunity.*
