# Project Aether

A production-grade Flutter MMO world event system demonstrating senior-level architecture, concurrency safety, and Firebase scalability patterns.

---

## Project Overview

Project Aether simulates a live MMORPG world event system with three real-time subsystems:

- **Global Pulse** — A high-frequency world boss countdown (100ms ticks) with optimized rebuild isolation
- **Geo-Raid** — A concurrency-safe 15-slot raid signup using Firestore atomic transactions
- **Engagement Chat** — A paginated, cost-optimized real-time chat stream

The app is architected for production scale, not tutorial simplicity. Every architectural decision is justified by distributed systems constraints.

---

## Features

| Feature | Implementation |
|---|---|
| 100ms countdown timer | Ticker stream → BLoC → BlocSelector isolation |
| 15-slot atomic raid join | Firestore transactions with retry |
| Thundering herd protection | Transaction read-before-write ordering |
| Live chat stream | Query-limited descending listener |
| Chat pagination | startAfterDocument cursor pattern |
| Memory-safe streams | Explicit subscription cancellation |
| Zero rebuild waste | BlocSelector + buildWhen filtering |
| Full test coverage | bloc_test + mocktail + fake_cloud_firestore |

---

## Architecture Decisions

### Clean Architecture + BLoC

```
Presentation (BLoC/Cubit + Widgets)
    ↓ uses
Domain (Entities + Repository Interfaces + Use Cases)
    ↓ implemented by
Data (Firebase Data Sources + Repository Implementations + DTOs)
```

**Why**: Each layer has a single responsibility. The domain layer has zero dependencies on Flutter or Firebase — it is pure Dart. This means domain logic can be tested without mocking the UI framework or Firebase SDK. Repository interfaces allow data sources to be swapped (e.g., replacing Firestore with a REST API) without touching a single BLoC.

**Why BLoC over Provider/Riverpod**: BLoC enforces unidirectional data flow and makes state transitions explicit via events. For a concurrency-heavy system where race conditions are a real concern, explicit event ordering is a feature, not ceremony.

---

## Folder Structure

```
lib/
├── core/
│   ├── constants/        # AppConstants, FirestoreFields
│   ├── errors/           # Failures (domain) + Exceptions (data)
│   ├── extensions/       # DurationFormatting
│   ├── theme/            # AppTheme (Material 3 dark)
│   └── widgets/          # AetherCard, SectionHeader, StatusDot
│
├── features/
│   ├── world_boss/
│   │   ├── domain/entities/   # WorldBoss, WorldBossStatus
│   │   └── presentation/
│   │       ├── bloc/          # WorldBossBloc, Event, State
│   │       └── widgets/       # WorldBossCard
│   │
│   ├── raid/
│   │   ├── data/
│   │   │   ├── datasources/   # RaidService (transactions)
│   │   │   └── repositories/  # RaidRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/      # Raid
│   │   │   └── repositories/  # RaidRepository (interface)
│   │   └── presentation/
│   │       ├── bloc/          # RaidBloc, Event, State
│   │       ├── pages/         # MainDashboard
│   │       └── widgets/       # RaidCard
│   │
│   └── chat/
│       ├── data/
│       │   ├── datasources/   # ChatRemoteDataSource
│       │   ├── models/        # ChatMessageModel (DTO)
│       │   └── repositories/  # ChatRepositoryImpl
│       ├── domain/
│       │   ├── entities/      # ChatMessage
│       │   └── repositories/  # ChatRepository (interface)
│       └── presentation/
│           ├── bloc/          # ChatCubit, ChatState
│           └── widgets/       # ChatCard
│
├── injection_container.dart   # get_it service locator
├── app.dart                   # MaterialApp root
└── main.dart                  # Bootstrap + Firebase init
```

---

## State Management

### BLoC vs Cubit Choice

| Feature | Type | Reason |
|---|---|---|
| WorldBoss | Bloc | Complex event sequencing (start → tick → spawn → restart) |
| Raid | Bloc | Multiple event sources (stream updates + user actions) |
| Chat | Cubit | Simple: watch → messages arrive → send |

### Rebuild Optimization

The 100ms timer is the hardest constraint. With a naive `BlocBuilder`, the entire page would rebuild at 10Hz. Instead:

```dart
// Only the countdown text rebuilds at 10Hz — nothing else.
BlocSelector<WorldBossBloc, WorldBossState, _CountdownData>(
  selector: (state) => _CountdownData(
    remaining: state.remaining,
    isAlive: state.isAlive,
    bossName: state.bossName,
  ),
  builder: (context, data) => Text(data.remaining.toCountdownString()),
)

// The progress bar rebuilds at 10Hz — isolated from the text.
BlocSelector<WorldBossBloc, WorldBossState, double>(
  selector: (state) => state.progress,
  builder: (context, progress) => LinearProgressIndicator(value: progress),
)

// The status label rebuilds only when the boss spawns — effectively never.
BlocSelector<WorldBossBloc, WorldBossState, bool>(
  selector: (state) => state.isAlive,
  builder: (context, isAlive) => Text(isAlive ? 'ALIVE' : 'SPAWNING'),
)
```

`_CountdownData` implements `Equatable` so `BlocSelector` skips rebuilds when `remaining` hasn't changed between emissions (which never happens at 100ms, but this is the defensive pattern).

---

## Firebase Strategy

### Firestore Data Model

```
/events/dragon_raid
  slots_filled: int   ← atomic counter
  max_slots: int

/events/dragon_raid/participants/{userId}
  userId: string
  joined_at: Timestamp

/events/dragon_raid/messages/{messageId}
  userId: string
  displayName: string
  message: string
  timestamp: Timestamp
```

**Why scoped to events**: Event-scoped subcollections allow security rules and TTL Cloud Functions to be event-aware. When the raid ends, a single Cloud Function can delete `/events/dragon_raid` and all subcollections atomically.

### Concurrency Protection

The raid join uses a Firestore transaction with this critical property:

```
READ all documents first → VALIDATE → WRITE atomically
```

Firestore transactions guarantee that if the documents read change between the read and commit, the transaction retries automatically (up to 5 times). This means:

- 50 users fire `joinRaid()` simultaneously
- Firestore serializes the transactions at the server
- The first 15 that successfully commit increment `slots_filled`
- The remaining 35 read `slots_filled >= max_slots` and return `false`
- **Exactly 15 succeed. No exceptions. No data corruption.**

The test `raid_concurrency_test.dart` verifies this with `FakeFirebaseFirestore` which simulates the same transaction semantics.

**What we explicitly avoided**:
```dart
// ❌ WRONG — classic read-then-write race condition
final snap = await raidDoc.get();
final count = snap['slots_filled'];
if (count < 15) {
  await raidDoc.update({'slots_filled': count + 1}); // RACE HERE
}
```

---

## Performance Optimizations

### Timer Architecture

```
Ticker Stream (every 100ms)
  → add(WorldBossTimerTicked) to BLoC
    → BLoC emits new state
      → BlocSelector diffs against previous selection
        → Only changed selectors trigger rebuild
```

The stream is a Dart `async*` generator that yields `Duration` values. It completes naturally when remaining hits zero, triggering the `onDone` callback which fires `WorldBossSpawned`. No `Timer.periodic` is used because periodic timers don't self-cancel and are harder to test.

### Stream Disposal

Every `StreamSubscription` is captured and cancelled:

```dart
StreamSubscription<Duration>? _tickerSubscription;

@override
Future<void> close() async {
  await _tickerSubscription?.cancel();
  return super.close();
}
```

The `?` nullable type forces handling of the null case (subscription not yet started). BLoC's `close()` is the guaranteed cleanup hook — it fires even if the widget tree is torn down unexpectedly.

---

## Testing Strategy

### Test Coverage

| Test File | What It Tests |
|---|---|
| `raid_concurrency_test.dart` | 50 simultaneous joins → exactly 15 succeed |
| `raid_service_test.dart` | Transaction semantics, idempotency, full-raid rejection |
| `raid_bloc_test.dart` | BLoC state transitions with mocked repository |
| `world_boss_bloc_test.dart` | Timer events, spawn, stop |
| `chat_cubit_test.dart` | Message streaming, send flow, empty message guard |
| `duration_extensions_test.dart` | Formatting correctness |

### Why `fake_cloud_firestore`

Real Firestore transactions require a network connection and Firebase project. `fake_cloud_firestore` implements the Firestore SDK interface in memory, including transaction retry semantics. This allows the concurrency test to run in CI with no external dependencies.

### Mock Strategy

The repository layer is mocked with `mocktail` in BLoC tests. This isolates the BLoC from Firestore entirely — BLoC tests verify event-to-state transitions, not Firebase behavior. Firebase behavior is tested separately in service-layer tests using `fake_cloud_firestore`.

---

## If 10,000 Players Are Chatting Simultaneously

This is the most important scalability question for the chat subsystem.

### Problem

A naive listener on `/events/dragon_raid/messages` with 10,000 connected clients:

- Each new message triggers a snapshot update for **all 10,000 clients**
- Each snapshot includes the full document — not just the delta
- At 1 message/second × 10,000 clients = **10,000 reads/second = 864M reads/day**
- At Firestore pricing (~$0.06/100k reads): **~$518/day just for chat reads**

### Solution Architecture

#### 1. Sharded Chat Rooms

Instead of one `/messages` collection, shard by a hash of the userId:

```
/events/dragon_raid/chat/room_0/messages/{id}
/events/dragon_raid/chat/room_1/messages/{id}
...
/events/dragon_raid/chat/room_15/messages/{id}
```

Each user is assigned to `room_{userId.hashCode % 16}`. This caps any single listener at ~625 users instead of 10,000. A "global chat" view shows a merged feed from all rooms (sampled, not full).

#### 2. Query Limits

```dart
.orderBy('timestamp', descending: true)
.limit(50)  // Hard cap — only 50 documents in the live window
```

New clients only receive the 50 most recent messages. Older messages are fetched on demand via `startAfterDocument` cursor pagination.

#### 3. Message Windows + TTL

Messages older than 24 hours are deleted by a Cloud Function on a schedule:

```javascript
// Cloud Function (Node.js)
exports.cleanupOldMessages = onSchedule('every 1 hours', async () => {
  const cutoff = Timestamp.fromDate(new Date(Date.now() - 24 * 60 * 60 * 1000));
  const batch = db.batch();
  const old = await db.collectionGroup('messages')
    .where('timestamp', '<', cutoff)
    .limit(500)
    .get();
  old.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
});
```

This prevents unbounded collection growth and keeps read costs stable.

#### 4. Fan-out via Cloud Functions

For system announcements ("Boss spawned!") reaching all users, avoid writing to each user's chat room individually from the client. Use a Cloud Function fan-out:

```javascript
exports.broadcastSystemMessage = onDocumentCreated(
  '/events/{eventId}/system_broadcasts/{id}',
  async (event) => {
    const batch = db.batch();
    for (let room = 0; room < 16; room++) {
      const ref = db.collection(`/events/${event.params.eventId}/chat/room_${room}/messages`).doc();
      batch.set(ref, { ...event.data.data(), type: 'system' });
    }
    await batch.commit();
  }
);
```

#### 5. Caching Layer

For historical messages (beyond the live window), use a CDN-cached REST endpoint instead of Firestore listeners. Cloud Firestore REST API + Cloud CDN means thousands of users can read the same paginated history without triggering individual Firestore reads.

#### 6. Client-Side Lazy Loading

The Flutter client only subscribes to the live window. Scrolling up triggers `fetchPageBefore(cursor: oldestMessage)` which is a one-time read, not a persistent listener. Listeners are expensive; paginated reads are cheap.

#### Cost Comparison at Scale

| Strategy | Reads/Day (10k users, 1 msg/sec) |
|---|---|
| Naive listener | 864,000,000 |
| Sharded (16 rooms) | 54,000,000 |
| Sharded + limit(50) | ~27,000,000 |
| Sharded + limit + TTL + CDN cache | ~5,000,000 |

A 170× reduction in read costs from architecture alone — without sacrificing real-time UX.

---

## Setup Instructions — Firebase Emulator

This project is designed to run against the **Firebase Local Emulator Suite** with no real Firebase project required. The emulator gives you a fully local Firestore instance with transaction support, security rules evaluation, and an admin UI.

### Prerequisites

| Tool | Install |
|---|---|
| Flutter 3.10+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Node.js 18+ | [nodejs.org](https://nodejs.org) |
| Firebase CLI | `npm install -g firebase-tools` |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` |
| Java 11+ | Required by the Firestore emulator |

Verify Java is available:
```bash
java -version
# Should print: openjdk 11 or higher
```

---

### Step 1 — Install dependencies

```bash
cd aether_project
flutter pub get
```

---

### Step 2 — Start the emulator (no Firebase account needed)

Do **not** run `firebase init` — it tries to contact Firebase servers and will fail without a real project.

Instead, start the emulator directly using the `demo-` prefix, which tells the Firebase CLI to run fully offline with no server validation:

```bash
firebase emulators:start --only firestore --project=demo-aether
```

> The `demo-` prefix is the official Firebase pattern for local-only development. No login, no account, no internet required.

---

You should see:

```
┌─────────────────────────────────────────────────────────────┐
│ ✔  All emulators ready! It is now safe to connect your app. │
│ i  View Emulator UI at http://127.0.0.1:4000/               │
└─────────────────────────────────────────────────────────────┘

┌───────────┬──────────────────────────────────┬─────────────────────────────────┐
│ Emulator  │ Host:Port                        │ View in Emulator UI             │
├───────────┼──────────────────────────────────┼─────────────────────────────────┤
│ Functions │ Failed to initialize (see above) │                                 │
├───────────┼──────────────────────────────────┼─────────────────────────────────┤
│ Firestore │ 127.0.0.1:8080                   │ http://127.0.0.1:4000/firestore │
└───────────┴──────────────────────────────────┴─────────────────────────────────┘
```

Open `http://127.0.0.1:4000` in a browser — this is the **Emulator UI** where you can inspect Firestore documents in real time as the app runs.

---

### Step 3 — Seed the raid document

The app needs the `dragon_raid` document to exist before it can function. The Cloud Function `seedRaidDocument` (see below) handles this automatically when the emulator starts. Alternatively, seed it manually via the Emulator UI:

**Option A — Emulator UI (manual)**

1. Go to `http://127.0.0.1:4000` → **Firestore**
2. Click **Start collection** → Collection ID: `events`
3. Document ID: `dragon_raid`
4. Add fields:
    - `slots_filled` → number → `0`
    - `max_slots` → number → `15`
5. Click **Save**

> Requires `firebase-admin` installed globally: `npm install -g firebase-admin`

---

### Step 4 — Run the app

```bash
flutter run
```

The app connects to your local emulator. Every Firestore read and write is visible in the Emulator UI at `http://127.0.0.1:4000`.

---

### Step 5 — Run all tests

Tests use `fake_cloud_firestore` and require **no running emulator**:

```bash
flutter test
```

To run only the concurrency test:
```bash
flutter test test/raid_concurrency_test.dart
```

---

### Emulator Persistence (optional)

By default the emulator resets all data when stopped. To persist data between sessions:

```bash
firebase emulators:start --only firestore --project=demo-aether \
  --export-on-exit=./emulator-data \
  --import=./emulator-data
```

The first run creates `./emulator-data/`. Subsequent runs reload it, so your seeded raid document survives restarts.

---

## Tradeoffs

| Decision | Tradeoff |
|---|---|
| Firestore transactions for raid | Slightly higher latency (~200ms) vs. eventual consistency approach, but guarantees are worth it |
| Stream-per-BLoC subscription | One Firestore listener per BLoC instance. With get_it factories, multiple screens wouldn't share a listener — use singletons for shared listeners in larger apps |
| 100ms timer in async* stream | Clean and testable, but adds slight drift over long sessions vs. a clock-anchored ticker. In production, sync against a server timestamp every minute |
| FakeFirebaseFirestore in tests | Simulates, but doesn't perfectly replicate, Firestore's transaction conflict detection. Production validation requires emulator-based integration tests |
| Single chat room (demo) | The demo uses a single room. The sharding strategy is documented and the code structure supports it — adding sharding is a one-file change in `ChatRemoteDataSource` |

---

## Scaling Discussion

### Beyond Firebase

At true MMO scale (1M+ concurrent users), Firestore alone is insufficient for the high-frequency world boss timer. The pattern would shift to:

1. **Boss Timer**: Cloud Firestore single document updated by a Cloud Function (not clients). Clients watch that one document. Cost: 1 write/second × N reads = cheap.

2. **Raid Signups**: Firestore transactions hold for ~10k concurrent tries. Beyond that, use a Cloud Function with a distributed counter or a dedicated backend (Redis atomic INCR).

3. **Chat**: Migrate to a purpose-built system (Firebase Realtime Database for pure message throughput, or a dedicated WebSocket service) if volume exceeds 50k concurrent chatters per shard.

4. **Presence**: Use Firebase Realtime Database (not Firestore) for online presence — it's designed for high-frequency small-value updates.

The architecture of this project is designed so each subsystem can be replaced independently without touching the others, because the domain layer owns the contracts and data sources are injected dependencies.

---

## Acknowledgment

This repository includes testing and validation utilities originally provided by lwar780 under the MIT License.