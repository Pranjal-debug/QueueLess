# QueueLess — Stop Waiting. Know Your Place.

**A digital queue management system built with Flutter and Serverpod.**

QueueLess helps customers join a queue digitally, track their ticket status, and know when they're being served. Staff can view the active queue, call the next customer, and complete tickets through a dashboard.

## 🚀 Live Demo

**Web App:** https://queueless.serverpod.space/

**Backend API:** https://queueless.api.serverpod.space/

## ✨ Features

### Customer

* Join the queue and receive a ticket.
* View ticket status and queue position.
* Track the progress of your ticket.

### Staff

* View the active queue.
* Call the next waiting customer.
* Complete tickets and manage the queue.

### Backend

* Serverpod backend built with Dart.
* Database-backed queue and ticket management.
* Concurrent queue operations designed to prevent duplicate ticket numbers and duplicate calls.

## 🛠️ Tech Stack

* **Frontend:** Flutter
* **Backend:** Serverpod
* **Language:** Dart
* **Database:** Serverpod-managed database
* **Deployment:** Serverpod Cloud
* **Version Control:** Git and GitHub

## 🏗️ Project Structure

```text
QueueLess/
├── queueless_server/    # Serverpod backend
├── queueless_client/    # Generated Serverpod client
├── queueless_flutter/   # Flutter web application
└── README.md
```

## ⚙️ Run Locally

### Prerequisites

* Flutter SDK
* Dart SDK
* Serverpod CLI
* Git

### 1. Clone the repository

```bash
git clone -b pranjal-debug https://github.com/Pranjal-debug/QueueLess.git
cd QueueLess
```

### 2. Start the Serverpod services

From the project root:

```bash
serverpod start
```

This starts the local development services configured for the project.

### 3. Run the Flutter application

Open another terminal:

```bash
cd queueless_flutter
flutter pub get
flutter run -d chrome
```

Follow any project-specific configuration instructions if prompted.

## 🧪 Testing and Validation

The following checks have been reported as passing during development:

* `dart test` — backend tests, including queue concurrency scenarios.
* `dart analyze` — Dart static analysis.
* `flutter build web --wasm` — Flutter web production build.

Run the backend tests from the server directory:

```bash
cd queueless_server
dart test
```

Run static analysis from the project root:

```bash
dart analyze
```

Build the Flutter web application from the Flutter directory:

```bash
cd queueless_flutter
flutter build web --wasm
```

## 🎯 Project Goal

QueueLess aims to reduce uncertainty and unnecessary waiting by giving customers visibility into their place in a queue while enabling staff to manage service efficiently.

## 🔮 Future Improvements

Potential future enhancements include:

* Live ticket status updates.
* Notifications when a customer's turn approaches.
* Multiple queue locations and service categories.
* Authentication and role-based access.
* Queue analytics and wait-time improvements.

## 👨‍💻 Author

**Pranjal Gupta**

GitHub: https://github.com/Pranjal-debug

---

*QueueLess — Stop waiting. Know your place.*
