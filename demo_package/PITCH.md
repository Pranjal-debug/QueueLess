# QueueLess — Product Pitch & Hackathon Brief

## 60-Second Elevator Pitch (Spoken Script)

> "Physical queues waste millions of productive hours every day. Whether it's a student advising office, a hospital intake desk, a barber shop, or a restaurant, customers hate being pinned to a crowded waiting room.
>
> Meet **QueueLess**: a zero-install, real-time virtual queueing system built on Flutter and Serverpod.
>
> Customers simply scan a room's QR code on their phone, enter their name, and immediately see their live ticket number, waiting position, and dynamic ETA. They are completely free to walk around, grab a coffee, or wait outside.
>
> For staff, QueueLess delivers a fast, multi-tenant workspace with instant room creation, one-click ticket calling, and live queue synchronization.
>
> Unlike naive mockups, QueueLess runs on a transactional PostgreSQL backend with database-level isolation between staff rooms, atomic ticket numbering, and customer self-service cancellation that instantly recalculates waiting positions for everyone behind them.
>
> QueueLess: Line up without standing in line."

---

## 1. Problem Statement

1. **The Physical Bottleneck:** Customers are forced to physically stand in line or hover near a reception desk for fear of losing their turn.
2. **Friction of Traditional Apps:** Forcing customers to download a 50MB mobile app and create an account just to order a sandwich or wait at the DMV creates high user abandonment.
3. **Ghost Tickets & Queue Bloat:** In paper-ticket or simple digital systems, customers who get tired and leave remain in the queue, forcing staff to repeatedly call non-existent numbers.
4. **Poor Multi-Tenancy:** Small businesses and department staff lack lightweight tools to create and manage their own isolated queues on demand.

---

## 2. Target Users & Practical Use Cases

- **University Campus Services:** Financial aid, course advising, registrar counters.
- **Healthcare & Clinics:** Walk-in clinics, urgent care triage, pharmacy pickup.
- **Retail & Hospitality:** Busy pop-ups, barber shops, DMV offices, restaurant walk-in waitlists.
- **Hackathon & Event Logistics:** Judging lines, mentor office hours, hardware checkout desks.

---

## 3. Product Workflows

### Customer Journey
1. **Access:** Scan physical QR code or click shared link (`http://localhost:8082/?roomId=1` or `/app/#/customer?roomId=1`).
2. **Join:** Enter name and click **Join Queue**. No sign-up or app download required.
3. **Track:** Receive unique ticket number, live queue position (e.g., `Position 2 of 5`), and estimated wait time.
4. **Notify:** Real-time WebSocket triggers a bold "It's your turn" banner when staff calls their ticket.
5. **Self-Service Exit:** Click "Stop Tracking" at any time if leaving early; this immediately cancels the ticket and frees up staff time.

### Staff Journey
1. **Authentication:** Sign in via secure email/password auth. Staff scope is validated at the API layer.
2. **Room Management:** Select existing rooms or spin up a new room in seconds.
3. **Live Counter:** See active waiting queue with customer names, ticket numbers, and waiting timers.
4. **Call Next:** One click advances the queue, locking the ticket and pushing live notifications to the customer's phone.
5. **Complete:** Mark tickets finished as service concludes.

---

## 4. Key Differentiators

- **Zero-Friction for Customers:** 100% web-based. Zero app downloads, zero account creation required for patrons.
- **Atomic Concurrency & Database Integrity:** Ticket numbering is strictly sequential per room and handled with PostgreSQL row locks (`skipLocked` and transaction locks).
- **Dynamic Position Recalculation:** When a ticket is called or cancelled via "Stop Tracking", all following customers immediately move up in line without page reloads.
- **Strict Multi-Tenant Isolation:** Staff members can only view, call, or modify tickets in rooms they own or are explicitly granted access to.

---

## 5. Technical Decisions & Security Boundaries

- **Full-Stack Dart:** Flutter Web frontend shares strongly-typed protocols and models with the Serverpod backend, eliminating API contract drift.
- **Scoped RBAC:** Strict separation between unauthenticated public endpoints (`joinQueue`, `getTicketStatus`), customer credentialed actions (`cancelTicket` protected by 6-char cryptographic access code), and authenticated staff operations (`getActiveQueue`, `callNext`, `completeTicket` requiring `'staff'` scope).
- **Proactive Token Refresh:** Automated client-side JWT refresh keeps long-running staff dashboards active without sudden session expirations.

---

## 6. Honest Limitations & Future Roadmap

- **Current Limitation:** SMS/Push notifications are not yet integrated; customers must keep the mobile browser tab active or backgrounded.
- **Current Limitation:** Single service agent per room; multiple staff members servicing the same room simultaneously is architected in database schema (`staff_room_access`), but currently optimized for single active agent workflow.
- **Future Roadmap:**
  - Web Push API integration for background notifications when mobile browser is closed.
  - SMS notification fallback via Twilio integration.
  - Multi-counter concurrent agent serving with ticket assignment tags.
  - Historic analytics dashboard with average wait and service duration reports.
