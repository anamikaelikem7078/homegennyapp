# Plan: Home Cook On‑Demand Booking + Live Staff Tracking (Google Maps)

## Context
HomeGenny today handles **long-term staff placement**: a client requests staff, the RM shortlists, and staff get placed. The client wants a **Snabbit-style on-demand "Home Cook" booking** too:
Home → Home Cook → Instant/Schedule → Date & Time → Duration → Dishes → Address → Summary/Price → Payment → Confirmed → Cook arrives (OTP check-in) → Cooking + cleanup → Complete.
The client also wants to **see live on Google Maps where the assigned cook is** while they are travelling, with an ETA.

**Decisions made:**
- Build both the Flutter app (`homegennyapp`) and the backend (`homegennyserver`, NestJS + Prisma).
- Payment reuses the **existing UPI screen**, not a payment SDK.

**What we can reuse:**
- Flutter: Riverpod, GoRouter, Dio and `BaseRemoteDataSource` ([lib/core/network/api_service.dart](lib/core/network/api_service.dart)), `RepositoryExecutor` with dummy-API fallback, `google_maps_flutter`, `geolocator`, `permission_handler` and `url_launcher`.
- Design system: `ds_date_time_picker.dart`, `ds_otp_field.dart` and `ds_timeline.dart`.
- Existing services: `LocationService` and `GoogleMapsService` (geocoding).
- Map example: the `GoogleMap` widget in `staff/.../attendance/check_out_screen.dart`.
- Backend: the Socket.IO gateway at `homegennyserver/src/modules/realtime/realtime.gateway.ts`, which already verifies JWTs and puts sockets into role rooms, plus the `maps` module.

---

## Part A: Backend (homegennyserver)

### A1. Prisma models (`prisma/schema.prisma` + migration)
- **`ServiceOffering`**: id, code (`HOME_COOK`), name, active.
- **`DurationPackage`**: id, serviceId, minutes (60/90/120/180), maxDishes, peopleHint ("1–2"), price.
- **`MenuItem`**: id, serviceId, name, category (Breakfast/Dal/Sabzi/Rice/Roti/Full meal), veg flag, active.
- **`ServiceBooking`**:
  - Who and what: id, bookingNo, clientId, staffId?, serviceId, `type` (INSTANT|SCHEDULED), slotStart, durationMin, dishes (Json), peopleCount.
  - Where: address text, lat, lng.
  - Money: amount, `paymentStatus` (PENDING|PAID|FAILED), upiRef.
  - Visit: `status` (see enum below), otpHash, checkInAt, checkOutAt, cancelReason.
  - Timestamps.
- **Status enum:** `PENDING_PAYMENT → CONFIRMED → ASSIGNED → EN_ROUTE → ARRIVED → IN_PROGRESS → COMPLETED` (plus `CANCELLED`).
- **`StaffLocationPing`**: id, bookingId, staffId, lat, lng, heading, speed, accuracy, recordedAt. It has an index on (bookingId, recordedAt) and old rows are purged after N days by cron.
- **`StaffAvailability`** (simple version): staffId, isOnline, lastLat, lastLng, skills includes COOK. It is used for instant matching.

### A2. New module `src/modules/service-booking/`
Same controller/service/module pattern as `placement`.

**Client endpoints:**
- `GET  /services/home-cook`: duration packages and menu.
- `GET  /services/home-cook/slots?date=`: available slots. Each day is split into 30-minute slots, minus the slots where cook capacity is already booked.
- `GET  /services/home-cook/instant-availability?lat&lng`: whether there is an online cook within X km, with an estimated arrival.
- `POST /bookings`: creates the booking (status PENDING_PAYMENT) and returns a server-computed price. The client's price is never trusted.
- `POST /bookings/:id/payment`: confirms the UPI reference, sets PAID/CONFIRMED and triggers assignment.
- `GET  /bookings`, `GET /bookings/:id`, `POST /bookings/:id/cancel`.
- `GET  /bookings/:id/tracking`: the latest staff location, the ETA, the route polyline and the status. This is the REST fallback when the socket is down.

**Staff endpoints:**
- `GET  /staff/bookings`: today's and upcoming jobs.
- `POST /staff/bookings/:id/accept`.
- `POST /staff/bookings/:id/start-trip`: sets EN_ROUTE.
- `POST /staff/bookings/:id/arrived`.
- `POST /staff/bookings/:id/verify-otp`: sets IN_PROGRESS. The 4-digit OTP is generated at confirmation, stored as a hash, and shown in the client app.
- `POST /staff/bookings/:id/complete`.

**Assignment:** a simple first version.
- INSTANT bookings go to the nearest online cook with no overlapping booking.
- SCHEDULED bookings are auto-assigned when confirmed, or the RM assigns them manually.

Every status change emits an event through EventEmitter, and the socket layer forwards it.

### A3. Live tracking over Socket.IO (extend `realtime.gateway.ts`)
- Store `userId` and `role` on `client.data` in `handleConnection`.
- **`@SubscribeMessage('booking.join')`** `{bookingId}`:
  - Allowed only for the client who owns the booking, the assigned staff, or an RM/BM.
  - The socket joins room `booking:{id}`.
- **`@SubscribeMessage('staff.location')`** `{bookingId, lat, lng, heading, speed, accuracy, ts}`:
  - Only the assigned staff can send it, and only while status is ASSIGNED, EN_ROUTE or ARRIVED.
  - The server broadcasts `staff.location` to `booking:{id}` straight away.
  - It saves a ping to the database at most every 15 s or every 25 m.
- **ETA:** the server calls the Google Routes/Directions API from the existing `maps` module, at most every 30–60 s per booking. It emits `booking.eta` `{etaSec, distanceM, polyline}`. Throttling keeps Maps costs down.
- **`@OnEvent('booking.status')`**: emits `booking.status` to `booking:{id}` and pushes an FCM notification ("Cook is on the way", "Cook has arrived", "Share OTP").
- **Privacy:** after `IN_PROGRESS`, the server rejects location updates and the client stops tracking. Location is only shared during the trip to the client's home.

---

## Part B: Flutter app (homegennyapp)

### B1. Dependencies (`pubspec.yaml`)
- `socket_io_client`: live location.
- `google_polyline_algorithm`: decodes the route polyline.
- Payment needs no new dependency because it reuses the UPI screen.

### B2. Shared layer
- `lib/core/realtime/socket_service.dart`: a single Riverpod-provided Socket.IO client.
  - Connects to `{base host}/events` with `auth: {token}`, using the JWT from the existing auth storage.
  - Auto-reconnects and re-joins rooms after a reconnect.
  - Exposes `Stream`s per event.
- `lib/core/constants/api_constants.dart`: add the booking and tracking endpoints, and the socket URL.

### B3. New feature `lib/features/service_booking/`
Uses the same clean-architecture layout as the other features.

**Data and domain:**
- `data/datasources/booking_remote_datasource.dart`: extends `BaseRemoteDataSource`.
- `data/datasources/booking_dummy_api.dart` and `assets/json/client/home_cook_*.json`: dummy data for the `USE_DUMMY_API` flag.
- `domain/models/`: `ServicePackage`, `MenuItem`, `ServiceBooking`, `BookingStatus`, `StaffLocation`, `TrackingInfo`.
- `data/repositories/booking_repository_impl.dart`: built on `RepositoryExecutor.fetch`.

**Booking draft state:**
- `presentation/providers/booking_draft_provider.dart` is a `Notifier<BookingDraft>`.
- It holds type, date, slot, duration, dishes, people and address across the wizard steps, and validates that the dish count is within the duration's limit.

**Client screens** (`presentation/screens/client/`):

| # | Screen | Notes |
|---|---|---|
| 1 | Home Cook card on `ClientHomeScreen` | Entry point from home |
| 2 | `home_cook_landing_screen.dart` | Explains the service, then lets the client choose **Instant** or **Schedule**. Instant shows availability and estimated arrival. |
| 3 | `slot_picker_screen.dart` | Date chips for the next 7 days and a grid of time slots (Schedule only) |
| 4 | `duration_screen.dart` | 1 hr ≈ 3 dishes, 1–2 people; also 1.5, 2 and 3 hr, each with a price |
| 5 | `menu_screen.dart` | Category tabs and a multi-select of dishes, capped by the duration's dish limit |
| 6 | `address_screen.dart` | Saved addresses, or picking a pin on the map, reusing `LocationService`, `GoogleMapsService` and `location_address_widget` |
| 7 | `booking_summary_screen.dart` | Service, date, time, duration, dishes, address and the **total from the server**, plus a note that cleanup covers cooking utensils only |
| 8 | Payment | Reuses `ClientUpiPaymentScreen` (see below) |
| 9 | `booking_confirmed_screen.dart` | Shows the booking number, the OTP and a "Track cook" button |
| 10 | `my_bookings_screen.dart` and `booking_detail_screen.dart` | Upcoming and past tabs, a status timeline (`ds_timeline`), and cancel |
| 11 | **`live_tracking_screen.dart`** | See B4 |

**Making the UPI screen reusable:** today `ClientUpiPaymentScreen(invoiceId, amount)` only pays invoices. Change it to take a `PaymentTarget` (invoice or booking, id, amount) and an `onSuccess` route. After a successful payment for a booking it calls `POST /bookings/:id/payment`; for an invoice it keeps the current behaviour. The invoice flow must not break.

### B4. Live tracking screen (client)
- **Map:**
  - `GoogleMap` with a home marker (the booking's lat/lng) and a cook marker using a custom icon rotated by `heading`.
  - The route polyline comes from `booking.eta`.
  - Calls `animateCamera` with `LatLngBounds` so both markers fit on screen.
- **Smooth movement:** interpolate the cook marker between pings with a ~1 s tween so it doesn't jump.
- **Bottom sheet:**
  - The cook's photo, name and rating, a **Call** button (`url_launcher` `tel:`) and a chat button that reuses the existing `chat_screen`.
  - Live ETA ("Arriving in 8 min · 2.3 km"), the status steps (Assigned → On the way → Arrived → Cooking → Done), and the **OTP shown large**.
- **Data:** `trackingProvider(bookingId)` is a `StreamNotifier`.
  - On open, it seeds itself from `GET /bookings/:id/tracking`, then emits `booking.join` and listens for `staff.location`, `booking.eta` and `booking.status`.
  - If the socket is disconnected for more than 10 s, it falls back to polling the REST endpoint every 10 s.
- **Ending tracking:** at `ARRIVED` the screen shows "Cook has arrived – share OTP". At `IN_PROGRESS` it closes the map and shows "Cooking in progress" with a timer for the remaining duration.

### B5. Staff side (`lib/features/staff/`, new `presentation/screens/jobs/`)
- `staff_jobs_screen.dart`: today's on-demand jobs, with an Accept button.
- `staff_job_detail_screen.dart`:
  - Shows the client address, dishes and duration, and a **Navigate** button that opens the Google Maps app via `google.navigation:q=lat,lng`.
  - The **Start Trip** button starts location sharing. **Arrived** stops it.
  - **Enter OTP** uses `ds_otp_field` and calls verify-otp, which sets IN_PROGRESS. **Complete** ends the job.
- `lib/features/staff/.../location_sharing_service.dart`:
  - `Geolocator.getPositionStream` with `distanceFilter: 20` and high accuracy.
  - On Android it uses `AndroidSettings(foregroundNotificationConfig: ...)` so updates keep coming when the screen is off. The notification reads "Sharing location with customer".
  - Each position is emitted to the socket as `staff.location`. It stops automatically on ARRIVED, IN_PROGRESS or CANCELLED.

### B6. Routing
- Add the new paths to `client_routes.dart` and `client_router.dart`: `/client/home-cook`, `/slots`, `/duration`, `/menu`, `/address`, `/summary`, `/bookings`, `/bookings/:id`, `/bookings/:id/track`.
- Add `/staff/jobs` and `/staff/jobs/:id` to the staff router.
- Add an FCM deep link so tapping "Cook is on the way" opens `/client/bookings/:id/track`.

### B7. Platform config
- **Android `AndroidManifest.xml`:** `ACCESS_FINE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION` (needed on Android 14+), and `POST_NOTIFICATIONS`.
- **iOS `Info.plist`:** `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, and `UIBackgroundModes: location`.
- **Google Cloud:** enable the Maps SDK (Android/iOS), the Routes/Directions API and the Geocoding API.
  - The Maps keys are hardcoded in `AndroidManifest.xml` and `AppDelegate.swift`, and the Geocoding key in `AppConfig`.
  - **Restrict** these keys by package name or bundle ID, and move the Directions calls to the server.

---

## Phases (build order)
1. **Backend core:** models, migration and seed (packages and menu), booking CRUD, pricing, slots.
2. **Flutter booking flow:** screens 1–10 against dummy data first, then the real API, then the UPI payment change.
3. **Staff job flow:** accept, start trip, arrived, OTP, complete (REST only).
4. **Realtime tracking:** gateway rooms and events, Flutter `SocketService`, staff `LocationSharingService`, client `LiveTrackingScreen`, ETA and polyline, FCM deep links.
5. **Hardening:**
   - Polling fallback.
   - Permission-denied states.
   - Cancellation rules: free before ASSIGNED, a fee after EN_ROUTE.
   - Purging old pings.
   - RM view of active trips on `rm_locations_screen.dart`.

## Verification
- **Backend:**
  - Unit tests for pricing, slot capacity and status transitions (invalid transitions rejected).
  - An e2e test of the booking lifecycle.
  - A socket test: a client joins someone else's booking and is rejected; staff location updates are rejected after IN_PROGRESS.
- **Flutter:** `flutter analyze`, plus unit tests for the `booking_draft_provider` validation (dish cap per duration) and the tracking provider's fallback logic.
- **End to end, on two devices or emulators** (client and staff logged in), run against the local server:
  1. The client books Home Cook (Schedule), pays by UPI and sees the confirmation with an OTP.
  2. The staff member accepts and taps Start Trip.
     - On an emulator, use **Extended controls → Location → Routes** to simulate driving.
     - On the client device, the marker should move smoothly, and the ETA and polyline should update.
  3. With the staff screen locked, updates should keep arriving (because of the foreground service).
  4. Staff taps Arrived and then enters the OTP. On the client device, tracking should close and "Cooking in progress" should appear.
  5. Staff taps Complete. The booking should appear under Past.
  6. Kill the socket (turn the server's WS off). Tracking should switch to REST polling.
