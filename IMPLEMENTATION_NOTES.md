# SafeColony latest implementation

Updated from the uploaded latest backend and Flutter lib sources on 2026-08-21.

## Fixed
- Organization Admin sidebar: Maintenance and Money Details now open different screens.
- Resident sidebar includes Maintenance and Community Finance.
- Marketplace is limited in the sidebar to roles that can actually operate it (resident, organization admin, vendor).
- Marketplace resident order UI now supports service slot and delivery notes and does not require a real price.
- Marketplace cutoff is enforced server-side.
- Marketplace event lifecycle supports OPEN/CLOSED/COMPLETED/CANCELLED.
- Admin can view resident orders and aggregated demand.
- Marketplace orders store service slot and payment reference.
- Existing notification bell remains wired into the Admin and scoped-admin dashboard AppBars.

## Marketplace architecture
Resident -> Community Day -> individual request/order -> SafeColony aggregation -> vendor -> one community delivery/service visit.

Supported event types:
- PRODUCT: groceries, vegetables, food, community pharmacy, etc.
- SERVICE: car service, bike service, AC/plumber/electrician/cleaning camps, etc.

## Database
Run:
    cd backend
    alembic upgrade head

New migration:
    backend/alembic/versions/marketplace_20260821_enhancements.py

## Important
The current upload contained the Flutter `lib/` source but did not contain the Flutter platform/build files (`android/`, `ios/`, etc.) or pubspec.yaml. Therefore this package contains the exact updated Flutter `lib/` plus the complete backend, without fabricating missing platform files. Keep your latest full Flutter project and replace its `lib/` with this package's `frontend/safecolony_app/lib/`.

Backend `.env` and generated caches are intentionally excluded.
