# Scale Master Guitar - CLAUDE.md

## Project Overview
Scale Master Guitar (smguitar) is a Flutter app for learning guitar scales and fingering patterns. It features an interactive fretboard, scale visualization, and a cloud-based fingerings library for saving and sharing custom patterns.

## Tech Stack

### Core Framework
- **Flutter** (Dart)
- **State Management**: flutter_riverpod

### Backend & Database
- **Supabase** - Backend as a Service
  - PostgreSQL database with Row Level Security
  - Anonymous authentication for user identification
  - Shared project with Guitar Progression Generator

### Monetization
- **RevenueCat** - Subscription management
  - Premium subscription (full features)
  - Lifetime purchase (one-time)
  - Fingerings Library subscription (separate)

## Supabase Database Schema

### IMPORTANT: Shared Supabase Project

This app shares a Supabase project with **Guitar Progression Generator**. All Scale Master Guitar tables use the `smg_` prefix to avoid conflicts.

#### Scale Master Guitar Tables (smg_ prefix)

| Table | Description |
|-------|-------------|
| `smg_saved_fingerings` | User-saved fingering patterns |
| `smg_fingering_likes` | Like tracking for public fingerings |

#### Scale Master Guitar Functions (smg_ prefix)

| Function | Description |
|----------|-------------|
| `smg_increment_fingering_likes` | Increment like count |
| `smg_decrement_fingering_likes` | Decrement like count |
| `smg_increment_fingering_loads` | Increment load/download count |

#### Scale Master Guitar Views (smg_ prefix)

| View | Description |
|------|-------------|
| `smg_popular_fingerings` | Public fingerings sorted by popularity |

### DO NOT MODIFY These Tables (Guitar Progression Generator)

The following tables belong to Guitar Progression Generator and should NOT be modified by smguitar:

- `user_credits`
- `generated_songs`
- `saved_progressions`
- `default_progressions`
- `progression_likes`
- `progression_categories`

### SQL Schema Location

The complete SQL schema for Scale Master Guitar is in:
- `supabase_schema.sql` - Run this in the SQL Editor to create smg_ tables

## RevenueCat Entitlements

### 3-Tier Model

| Code Enum | RevenueCat Entitlement | Type | Features |
|-----------|----------------------|------|----------|
| `free` | (none) | — | Major scales only, with ads |
| `premiumOneTime` | `premium_lifetime` | One-time | All scales, audio, fretboard download, local saves |
| `premiumSub` | `fingerings_library` or `all_access` | Monthly | Everything: scales, audio, download, **multi-instrument**, **cloud library** |

### Feature Gating

- **Scales, audio, fretboard download**: Any premium user (`isPremium`)
- **Multi-instrument/tuning**: Subscribers only (`isSubscriber`)
- **Cloud fingerings library**: Subscribers only (`isSubscriber`)
- **Local progression saves**: Any premium user (`isPremium`)
- **Cloud progression saves**: Subscribers only (`hasFingeringsLibraryAccess`)

### RevenueCat → Code Mapping

- `all_access` (riffroutine.com cross-app subscription) → `Entitlement.premiumSub`
- `fingerings_library` (in-app monthly subscription) → `Entitlement.premiumSub`
- `premium_lifetime` (in-app one-time purchase) → `Entitlement.premiumOneTime`

### Important: Lifetime vs Subscriber Differentiation

Lifetime purchasers (`premiumOneTime`) do NOT get access to multi-instrument/tuning or the cloud Fingerings Library. These features require an active subscription to drive recurring revenue. When a lifetime user tries to access these features, show a message encouraging them to subscribe.

## Project Structure

```
lib/
├── UI/
│   ├── fretboard_page/          # Main fretboard interface
│   │   ├── save_to_library_button.dart
│   │   ├── library_access_button.dart
│   │   └── provider/
│   └── fingerings_library/       # Library feature
│       ├── fingerings_library_page.dart
│       ├── fingering_card.dart
│       ├── fingering_preview.dart
│       └── fingerings_paywall.dart
├── models/
│   └── saved_fingering.dart
├── services/
│   ├── supabase_service.dart
│   └── feature_restriction_service.dart
├── revenue_cat_purchase_flutter/
│   ├── entitlement.dart
│   ├── purchase_api.dart
│   └── provider/
└── providers/
```

## Environment Configuration

The `.env` file should contain:
```
SUPABASE_URL=https://your-shared-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

**Note**: Use the same Supabase project URL as Guitar Progression Generator.

## Development Notes

### Adding New Supabase Tables

When adding new tables to this project:
1. **Always use the `smg_` prefix** for table names
2. **Always use the `smg_` prefix** for function names
3. Update the schema in `supabase_schema.sql`
4. Document new tables in this file
5. Update the Guitar Progression Generator CLAUDE.md to mention the new tables

### Anonymous Authentication

This app uses Supabase anonymous authentication. Users are identified by a UUID that persists across sessions. This allows saving fingerings without requiring email/password sign-up.

---

**Last Updated**: January 2026 - Added Fingerings Library feature with Supabase integration
