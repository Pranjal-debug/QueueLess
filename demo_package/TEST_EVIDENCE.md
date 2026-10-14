# QueueLess — Test Evidence & Verification Log

**Generated On:** 2026-10-14
**Target Environment:** Local Development (`http://localhost:8082/app/` / `http://localhost:8080/`)
**Backend:** Serverpod 4.0.4 on Dart 3.13.5
**Database:** PostgreSQL 8090

---

## 1. Automated Test Suites Executed

All automated test suites and static analyzers were executed locally against the codebase with 100% pass rates and zero analyzer errors.

| Test Suite / Command | Execution Directory | Passed | Failed | Status |
| :--- | :--- | :--- | :--- | :--- |
| `dart analyze lib test` | `queueless_server` | 0 issues | 0 issues | **PASS** |
| `flutter analyze lib test` | `queueless_flutter` | 0 issues | 0 issues | **PASS** |
| `dart test` (Integration & Serverpod tests) | `queueless_server` | **89** | **0** | **PASS** |
| `flutter test` (Widget & Link Safety tests) | `queueless_flutter` | **21** | **0** | **PASS** |
| `flutter test` (E2E flow tests) | `queueless_flutter` | **2** | **0** | **PASS** |
| **Total Automated Tests** | | **112** | **0** | **100% PASS** |

### Breakdown of Verified Coverage in Server Suite (89 tests):
- Customer queue joining, sequential numbering, and position incrementation.
- ETA calculation algorithm based on average service time and position.
- Access code security and ticket ownership validation.
- Staff role bootstrap, authentication scopes, and provisioning validation.
- Room creation and atomic creator access mapping in `staff_room_access`.
- Cross-tenant room isolation (preventing Staff B from managing Staff A's rooms).
- Calling next customer (`callNext`) with transactional row lock (`skipLocked`).
- Ticket completion (`completeTicket`) with audit timestamp tracking.
- Stop tracking / self-service cancellation flow (`cancelTicket`) and dynamic position shifts.
- Real-time WebSocket event dispatch for `joined`, `called`, `completed`, `cancelled`, and room lifecycle.
- Sanitization of `accessCode` on public queue listings.
- Daily session rollover: automatic midnight Kolkata rollover, ticket resets to #1, closing of old sessions, and preservation of history.
- Manual queue restart: staff-authorized queue reset with transactional active ticket cancellation.
- Safe room deletion: soft-deletion of rooms with preserved historical sessions/tickets and real-time room removal.

---

## 2. Browser Scenarios Actually Observed

All browser tests were executed autonomously via browser automation against the live running server:

### Scenario 1: Customer Queue Flow & Dynamic Multi-Ticket Progression
- **Observed:**
  - Navigated to `http://localhost:8082/app/#/customer`.
  - Joined `Customer_Demo_1` -> Ticket `#67` issued (`Position 1 of 1`).
  - Joined `Customer_Demo_2` -> Ticket `#68` issued (`Position 2 of 2`).
  - Joined `Customer_Demo_3` -> Ticket `#69` issued (`Position 3 of 3`).
  - All cards rendered with live status indicators, wait time estimates, and active action controls.
- **Artifact:** Recording saved to `scenario_a_customer_journey_1791815059294.webp`.
- **Verdict:** **PASS**

### Scenario 2: Self-Service Ticket Cancellation ("Stop Tracking")
- **Observed:**
  - Clicked "Stop tracking" on `Customer_Demo_2` (Ticket `#68`).
  - Confirmation dialog accepted.
  - Ticket `#68` transitioned instantly to `Cancelled: You’ve left this queue. Tracking has stopped.`
  - Stream cleanly closed (`queue.subscribeToRoomCustomer` closed in server logs).
  - Subsequent customer (`Customer_Demo_3`) immediately advanced from `Position 3 of 3` to `Position 2 of 2` without page reload.
- **Verdict:** **PASS**

### Scenario 3: Page Reload & State Persistence
- **Observed:**
  - Hard reloaded `http://localhost:8082/app/`.
  - Verified active tickets remained in waiting state.
  - Cancelled ticket `#68` remained permanently excluded from active queue.
- **Verdict:** **PASS**

### Scenario 4: Responsive Mobile & Desktop Layout (Task D)
- **Observed:**
  - Mobile viewport (390×844): Join card, text inputs, status badges, and action buttons stacked cleanly without layout overflow or clipped text.
  - Desktop viewport (1280×800): Proper container centering, max width constraints (1040px), and clear typography.
- **Artifact:** Recording saved to `responsive_layout_test_1791815769131.webp`.
- **Verdict:** **PASS**

### Scenario 5: Staff Workspace Authentication Boundary
- **Observed:**
  - Navigating to `http://localhost:8082/app/#/staff` in unauthenticated session presents the protected Staff Access screen with Serverpod `SignInWidget`.
  - Unauthorized direct requests to staff endpoints return `QueueException: Unauthorized: Staff login required.`
- **Verdict:** **PASS**

---

## 3. Idle-Session Verification (Task B)

- **Elapsed Time:** Real-time continuous 12–15 minute wait was not performed in this session.
- **Status:** **NOT VERIFIED**
- **Note:** Rather than simulating or fabricating an elapsed-time test, this scenario is strictly recorded as NOT VERIFIED.
- **Code Safeguards In Place:** The Flutter staff client implements proactive 5-minute periodic token refresh (`client.auth.refreshAuthKey(force: true)`) and automatic retry with refresh on 401/unauthorized errors (`_executeWithAuthRetry`), preventing idle timeouts during typical presentations.

---

## 4. Remaining Risks & Demo Considerations

1. **Host URL Port Accuracy:**
   - Always access the web app via port 8082: `http://localhost:8082/app/`.
   - Accessing `http://localhost:8080/app/` will fail with an HTTP 404 Endpoint Not Found because Serverpod binds static web assets to port 8082.
2. **First-Time Staff Login:**
   - Presenter should log in prior to going on stage to have the active room queue preloaded and avoid typing credentials during the pitch.
