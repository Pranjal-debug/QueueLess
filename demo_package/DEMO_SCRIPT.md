# QueueLess — Hackathon Live Demo Script (3–5 Minutes)

**Target Presentation Window:** 3 to 5 minutes
**Presenter Roles:** 1 Presenter (switching between Staff view and Customer mobile view) or 2 Co-presenters (1 Staff, 1 Customer on phone/laptop).
**Live Application URL:** `http://localhost:8082/app/`
**API Endpoint:** `http://localhost:8080/`

---

## Pre-Demo Setup Checklist (T-Minus 2 Minutes)

1. **Verify Services Running:**
   - Serverpod API server listening on `http://localhost:8080`
   - Serverpod Web server listening on `http://localhost:8082`
   - PostgreSQL running on port `8090`
2. **Browser Windows Preparation:**
   - **Window 1 (Staff View):** Open `http://localhost:8082/app/#/staff`. (Sign in with authorized staff credentials).
   - **Window 2 (Customer View):** Open `http://localhost:8082/app/#/customer` (or emulate mobile viewport 390×844 in DevTools).
   - **Window 3 (Customer 2 / Mobile View):** Open second customer tab or scan the room QR code.

---

## Timed Script & Action Guide

### [0:00 - 0:45] Act 1: The Problem & The Solution Setup

- **Spoken:**
  > "Waiting in lines is broken. Customers hate being trapped physically in a crowded waiting area, and staff hate the stress of manual crowd control. QueueLess solves this by turning any physical or virtual line into a live, transparent queue without forcing customers to download any native app."
- **Presenter Action:**
  - Show the Staff Workspace at `http://localhost:8082/app/#/staff`.
  - Point to the room title (e.g. *General room queue*), the live queue flow bar, and the **Share Room** button.
  - Click **Share room** to bring up the high-contrast QR code modal and canonical join URL: `http://localhost:8082/?roomId=1` (or `http://localhost:8082/app/#/customer?roomId=1`).
- **What Judges Observe:**
  - Modern, responsive staff dashboard with clear statistics (Waiting, Serving, Wait Time).
  - Instant QR code and one-click share link ready for customer scanning.

---

### [0:45 - 1:45] Act 2: Seamless Customer Onboarding & Multi-Ticket Queueing

- **Spoken:**
  > "A customer walks in, scans the QR code or clicks the join link. No account creation is needed for customers. They simply type their name and join."
- **Presenter Action:**
  - In Customer Window, enter name: `Alex`. Click **Join the queue**.
  - Open a second customer tab, enter name: `Sam`. Click **Join the queue**.
  - Open a third customer tab, enter name: `Taylor`. Click **Join the queue**.
- **What Judges Observe:**
  - Each customer gets a unique ticket number (`#70`, `#71`, `#72`).
  - Position counter updates dynamically:
    - Alex sees: `Position 1 of 3` (~0 mins wait).
    - Sam sees: `Position 2 of 3` (~5 mins wait).
    - Taylor sees: `Position 3 of 3` (~10 mins wait).
  - Meanwhile, on the Staff Dashboard Window:
    - The queue count immediately increases to 3.
    - Customer cards appear in real time without refreshing the page.

---

### [1:45 - 2:30] Act 3: Live Queue Progression & Real-Time Turn Call

- **Spoken:**
  > "Now the staff member is ready to call the next customer. Watch how the customer's device reacts instantly via WebSockets."
- **Presenter Action:**
  - On the Staff Dashboard, click **Call next customer**.
- **What Judges Observe:**
  - On Staff View: Ticket #70 (Alex) shifts into the **Currently serving** section with an active green timer and glowing indicator.
  - On Customer Alex's screen: Card status instantly transforms to **"It’s your turn — Please proceed to the service counter!"** with active notification styling.
  - On Customer Sam's screen: Position dynamically recalculates from `Position 2 of 3` to `Position 1 of 2`.
  - On Customer Taylor's screen: Position recalculates from `Position 3 of 3` to `Position 2 of 2`.

---

### [2:30 - 3:15] Act 4: Completing Service & Self-Service Cancellation ("Stop Tracking")

- **Spoken:**
  > "Once Alex is served, staff marks the ticket complete. But what if a waiting customer has to leave early? Rather than clogging the queue with ghost tickets, QueueLess gives customers a self-service 'Stop Tracking' button."
- **Presenter Action:**
  - On Staff View: Click **Complete** on Alex's ticket.
  - On Customer Sam's screen: Click **Stop tracking**, confirm the dialog.
- **What Judges Observe:**
  - Alex's ticket moves to completed and disappears from the active queue.
  - Sam's screen updates immediately: *"Cancelled: You’ve left this queue. Tracking has stopped."*
  - On Customer Taylor's screen: Position immediately advances to `Position 1 of 1`!
  - Staff Dashboard immediately drops waiting count and reflects the cancellation without stale ghost entries.

---

### [3:15 - 4:00] Act 5: Security, Room Isolation & Edge Cases

- **Spoken:**
  > "Under the hood, QueueLess isn't just a toy client. It runs on Serverpod 4.0.4 with PostgreSQL. Multi-tenancy is enforced through cryptographic authentication and database-level room isolation. Account A cannot manage, view, or call tickets for Account B's rooms. If a user refreshes the page or reloads their browser, state persists cleanly."
- **Presenter Action:**
  - Reload both Staff and Customer windows to demonstrate persistent session and ticket state.
  - Highlight that unauthenticated access to `#/staff` is strictly barred by the Serverpod auth boundary.

---

## Graceful Fallback Strategies (If Hiccups Occur)

1. **Delayed WebSocket Broadcast:**
   - *Explanation:* "Because Serverpod maintains transactional database state, the client features automatic background polling and retry mechanisms."
   - *Action:* Click the subtle refresh icon on the staff header or customer screen; the latest persisted state will render immediately.
2. **Accidental Tab Closure:**
   - *Explanation:* "Customer tickets are persisted in client state. Navigating back to the join link restores the active ticket tracking instantly."
3. **Staff Session Timeout:**
   - *Explanation:* "The staff client incorporates proactive JWT token refreshing (`refreshAuthKey`) and role bootstrap, automatically recovering authorization before requests fail."
