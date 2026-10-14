# QueueLess

> Smart, real-time queue management built with Flutter and Serverpod.

QueueLess eliminates physical waiting rooms and crowded lines by turning any service line into a live, transparent virtual queue. Designed for clinics, academic advising centers, and service counters, QueueLess provides a zero-install customer experience alongside a protected, multi-tenant staff workspace.

---

## Overview

Physical queues create anxiety for customers and operational strain for staff. Paper ticketing systems trap patrons near service counters, while native mobile applications demand storage, updates, and account registration for a single interaction.

QueueLess solves this with a web-first architecture:

- **Customers** scan an on-screen or printed QR code (or tap a shared link) to join in seconds using only their name. They receive an immediate digital ticket, monitor their position and estimated wait time in real time, and can step away until their device notifies them that it is their turn.
- **Staff** manage their assigned rooms from an authenticated dashboard, call waiting customers with atomic concurrency locks, monitor live flow metrics, and complete tickets cleanly.
- **System** operates on a transactional PostgreSQL backend with WebSocket event streams, ensuring data consistency, sequential ticket numbers, and strict multi-tenant room isolation.

---

## Key Features

### Zero-Install Customer Experience
- **Instant Browser Check-in:** Customers join by entering their name—no app download, registration, or password required.
- **Sequential Ticketing:** Monotonic, sequential ticket numbers (`#1`, `#2`, ...) generated atomically per room.
- **Live Dynamic Tracking:** Live position updates (e.g., *Position 2 of 5*) and status badges (*Waiting*, *Serving now*, *Completed*).
- **Turn Notifications:** Prominent, high-contrast visual alert (*"It's your turn — Please head to the service desk"*) pushed via WebSockets when called.
- **Self-Service Cancellation:** Customers who leave early can tap "Stop tracking" to cancel their ticket, instantly recalculating the queue positions of all customers behind them.
- **Real-Time Room Discovery:** The customer room list updates automatically when staff create or delete rooms without requiring manual page refreshes.

### Staff Queue Operations
- **Room Management:** Create dedicated rooms (e.g., *Neurology Clinic 302*, *Advising Desk 1*), restart active lines, or remove completed queues.
- **Instant QR & Link Sharing:** Generates high-contrast QR codes and sanitized canonical room URLs (`http://<host>:8082/?roomId=<id>`) with fallback text copy.
- **Atomic Next-Customer Calling:** One-click ticket progression shifts the next waiting patron into the *Serving* state, backed by database row-level locking.
- **Multi-Tenant Isolation:** Access control enforced via database records (`StaffRoomAccess`) and Serverpod scopes—staff can only view and manage rooms assigned to their profile.

---

## Live Demo

- **Production application:** [https://queueless.serverpod.space/app/](https://queueless.serverpod.space/app/)
  QueueLess is deployed on Serverpod Cloud. Open the live application to explore queue discovery and the customer/staff interface.
- **Demo video:** [https://drive.google.com/file/d/11qa9hb0m0OWRDerSwINfzELVeZn0r6KR/view?usp=sharing](https://drive.google.com/file/d/11qa9hb0m0OWRDerSwINfzELVeZn0r6KR/view?usp=sharing)
  *(A submission demo video `queueless_demo_final.mp4` [69 seconds, 1080p-grade framing, synchronized voiceover] is prepared locally for hackathon presentation).*
- **Source code:** [https://github.com/Pranjal-debug/QueueLess](https://github.com/Pranjal-debug/QueueLess)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter Web Client                          │
│        (Customer View / Protected Staff Dashboard)              │
└────────────────┬───────────────────────────────▲────────────────┘
                 │ HTTP API Calls                │ WebSocket Pub/Sub
                 │ (joinQueue, callNext, ...)    │ (Room & Ticket Events)
┌────────────────▼───────────────────────────────┴────────────────┐
│                   Serverpod Backend Server                      │
│            Endpoints, Auth Boundaries, Pub/Sub Engine           │
└────────────────┬───────────────────────────────┬────────────────┘
                 │ Relational Queries            │ Streaming State
┌────────────────▼────────────────┐  ┌───────────▼────────────────┐
│      PostgreSQL 16 (Port 8090)  │  │      Redis 6.2 (Port 8091) │
│  ACID transactions & row locks  │  │   Distributed event broker │
└─────────────────────────────────┘  └────────────────────────────┘
```

- **`queueless_flutter`:** Flutter 3.44+ web client built with responsive design for both desktop staff consoles and mobile customer viewports.
- **`queueless_client`:** Generated Dart client protocol library defining strongly-typed models, exceptions, and endpoints.
- **`queueless_server`:** Serverpod 4.0.4 backend providing streaming endpoints, transactional database operations, and cryptographic session validation.
- **PostgreSQL & Redis:** Persistent storage backed by PostgreSQL 16 (port 8090) and Redis 6.2 (port 8091) running in isolated local containers.

---

## Project Structure

```text
queueless/
├── queueless_server/       # Serverpod backend application, endpoints, models & migrations
│   ├── config/             # Environment configurations and password templates
│   ├── lib/src/            # Business logic, endpoints, and generated protocol code
│   ├── migrations/         # Serverpod transactional schema migrations
│   └── test/               # Server integration and concurrency test suites
├── queueless_client/       # Generated Dart client library consumed by Flutter
│   └── lib/src/protocol/   # Strongly-typed protocol data models
├── queueless_flutter/      # Flutter frontend application (Customer & Staff UI)
│   ├── lib/screens/        # Customer screen, staff dashboard, sign-in screen
│   ├── lib/design_system/  # Design system widgets and live AppQueueFlow visualizer
│   └── test/               # Widget tests, layout audits, and link safety tests
├── .gitignore              # Repository exclusions (secrets, build caches, raw media)
└── README.md               # Project documentation and developer setup
```

---

## Prerequisites

- **Dart SDK:** `^3.12.2` (Verified on Dart 3.13.5)
- **Flutter SDK:** `^3.44.4` (Verified on Flutter 3.47.7 stable)
- **Serverpod CLI:** `4.0.4` (`dart pub global activate serverpod_cli 4.0.4`)
- **Docker & Docker Compose:** For running PostgreSQL and Redis containers
- **Git:** Standard Git distribution

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Pranjal-debug/QueueLess.git
cd QueueLess
```

### 2. Configure credentials

Create your local `passwords.yaml` from the provided example template:

```bash
# On Linux/macOS
cp queueless_server/config/passwords.yaml.example queueless_server/config/passwords.yaml

# On Windows PowerShell
Copy-Item queueless_server\config\passwords.yaml.example queueless_server\config\passwords.yaml
```

*Note: The passwords in `passwords.yaml.example` match the default credentials defined in `docker-compose.yaml` for local development.*

### 3. Launch database and cache services

From the `queueless_server` directory, start PostgreSQL and Redis:

```bash
cd queueless_server
docker compose up -d
```

Verify services are listening:
- PostgreSQL on `localhost:8090`
- Redis on `localhost:8091`

### 4. Apply database migrations

Apply Serverpod database migrations to set up required tables and indices:

```bash
dart run bin/main.dart --apply-migrations
```

### 5. Start the Serverpod server

```bash
dart run bin/main.dart
```

The Serverpod API server starts on `http://localhost:8080`, and the companion web server listens on `http://localhost:8082`.

### 6. Launch the Flutter Web client

In a separate terminal:

```bash
cd queueless_flutter
flutter pub get
flutter run -d chrome
```

---

## Configuration

Configuration files are located in `queueless_server/config/`:

| File | Purpose |
| :--- | :--- |
| `development.yaml` | Local development port definitions, database hosts, and log settings. |
| `passwords.yaml.example` | Safe template detailing required database, redis, and service secrets. |
| `docker-compose.yaml` | Container declarations for local development and test databases. |

*Security Warning: `passwords.yaml` contains local credentials and is excluded by `.gitignore`. Never commit real credentials to source control.*

---

## Testing & Verification

The project includes unit, widget, and integration test suites:

### 1. Flutter Widget & Safety Tests (Isolated)
Run isolated widget tests, responsive layout audits, and link safety validations (no running server required):

```bash
cd queueless_flutter
flutter test test/widget_test.dart test/room_join_link_test.dart
```
*Result: 21 of 21 tests pass.*

### 2. Static Analysis
Verify code health and conformance:

```bash
dart analyze queueless_server/lib queueless_server/test queueless_client/lib queueless_flutter/lib
```
*Result: 0 issues found across all production packages.*

### 3. Backend Integration Tests
Run Serverpod transactional database and concurrency integration tests:

```bash
cd queueless_server
dart test
```
*Result: 88 integration tests pass, verifying concurrency locks, customer registration, queue ordering, access isolation, token refresh recovery, and stream delivery.*

---

## Security Notes

- **Authentication Boundary:** Administrative and room operations require cryptographic session validation and Serverpod `staff` scopes. Unauthenticated requests are rejected with `QueueException`.
- **Cross-Room Isolation:** Every staff action verifies explicit ownership via `StaffRoomAccess` records. Staff members cannot observe or operate on rooms belonging to other staff accounts.
- **Input & URL Sanitization:** Customer room join links are parsed and validated through a strict sanitizer that strips userinfo, credentials, non-numeric room IDs, and path traversal tokens.
- **Transactional Row Locking:** Ticket progression operations execute inside PostgreSQL database transactions using row locks to eliminate race conditions and prevent duplicate ticket numbering.

---

## Future Improvements

- **SMS & Push Alerts:** WebPush and Twilio/FCM SMS dispatch when a customer's turn is 1–2 positions away.
- **Analytics & Throughput Dashboard:** Historical reporting on average consultation times, peak wait windows, and room efficiency.
- **Multi-Counter Support:** Support multiple staff members serving concurrently from a single pooled queue.
- **Localized Multilingual Interface:** Accessibility translations for healthcare and public agency lobbies.

---

## License

No license has been specified for this repository. All rights reserved by the author.
