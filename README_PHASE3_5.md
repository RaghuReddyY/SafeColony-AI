# SafeColony Phase 3-5 implementation

Based on the uploaded `lib(7).zip` and `backend(6).zip`.

## Implemented

### Phase 3 - Vendor accounts
- Organization admin can create a vendor account directly from Marketplace Admin.
- Creates `users` row with `role=VENDOR` and links `marketplace_vendors.user_id` atomically.
- Vendor login uses the normal `/auth/login` flow.
- Admin UI displays vendor login email and whether the vendor account is linked.
- Existing standalone organization user management now also permits the VENDOR role.

### Phase 4 - Marketplace end-to-end
- Vendor portal already supports community days, consolidated demand, resident orders and order lifecycle:
  `PLACED -> ACCEPTED -> PREPARING -> READY -> DELIVERED`.
- Vendor receives an in-app notification when a resident places a marketplace order.
- Vendor portal now includes service requests assigned to the vendor.
- Service requests gain a `vendor_id` linkage and can move through:
  `REQUESTED -> ASSIGNED -> QUOTED -> APPROVED -> IN_PROGRESS -> COMPLETED`.
- Resident SafeColony Hub displays vendor and quote information and can approve a quote.
- If a service request does not explicitly specify a vendor, backend attempts to match an active marketplace vendor by category.

### Phase 5 - AI action layer
- Added `/ai/action`.
- AI requests are previewed first and require confirmation before database mutation.
- Marketplace order actions can create a real marketplace order after confirmation.
- Service-request actions can create a real service request after confirmation.
- Existing Gemini chat remains available for general questions.
- Flutter AI screen now checks for an executable action, asks for confirmation, then executes it.

## Database migration
A new Alembic migration was added:

`20260821_vendor_service_requests.py`

It adds `service_requests.vendor_id` and the foreign key/index.

Run in backend:

```powershell
alembic upgrade head
```

Verify:

```powershell
alembic heads
alembic current
```

Expected head:

```text
20260821_vendor_service_requests
```

## Cloud Run deployment
After applying the migration against the same Cloud SQL database used by Cloud Run, build/deploy the backend normally.

Example:

```powershell
gcloud builds submit --tag asia-south1-docker.pkg.dev/safecolony-production/safecolony/backend:latest .
gcloud run deploy safecolony-backend --image asia-south1-docker.pkg.dev/safecolony-production/safecolony/backend:latest --region asia-south1 --platform managed
```

## Android APK
Use the cloud backend URL at build time:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://safecolony-backend-2ut27gpyba-el.a.run.app
```

Do not include `/docs` in `API_BASE_URL`.

The existing `AppConfig` already reads `API_BASE_URL` from `--dart-define`.

## E2E test order

1. Organization Admin logs in.
2. Marketplace -> Create Vendor Account.
3. Create a vendor login such as `freshmart@test.com`.
4. Logout.
5. Login using the vendor credentials.
6. Verify Vendor Portal opens automatically.
7. Logout/login as Organization Admin.
8. Create Community Day and select the vendor.
9. Login as Resident A/B/C and place orders.
10. Login as Vendor and verify Orders + Consolidated Demand.
11. Move an order through ACCEPTED, PREPARING, READY and DELIVERED.
12. As resident, create a service request matching the vendor category.
13. Login as Vendor and verify Services tab.
14. Vendor accepts and sends quote.
15. Resident approves quote.
16. Vendor moves request to IN_PROGRESS and COMPLETED.
17. Resident opens AI Assistant and try: `Order 2 litres of milk for the grocery day`.
18. Verify confirmation dialog appears.
19. Confirm and verify the real marketplace order appears in My Orders and Vendor Orders.
