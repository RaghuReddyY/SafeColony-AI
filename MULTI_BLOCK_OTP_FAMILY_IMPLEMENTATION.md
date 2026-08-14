# SafeColony — Mobile OTP, Block Administration and Family Membership

## Design used in this implementation

### 1. Blocks
SafeColony already has the hierarchy:

`Organization -> Property -> Section -> Unit -> Resident`

The existing **Section is treated as the community Block**. This avoids creating a duplicate `Block` table and keeps existing property/unit data compatible.

Example:

- Organization: Green Valley
- Block A = Section A
- Block B = Section B
- Unit A-101 belongs to Section A
- Unit B-101 belongs to Section B

### 2. Block administrators
Two new roles are available:

- `BLOCK_ADMIN`: can operate only on assigned blocks.
- `COMMUNITY_FINANCE_ADMIN`: community-wide finance collector. One person can collect maintenance/festival/CCTV/community funds across all blocks.

The existing `ORGANIZATION_ADMIN` remains the full community administrator.

Block assignments are stored in `user_block_scopes`.

Organization admins can create scoped admins from **Block & Finance Administration** on the admin dashboard.

### 3. Finance model
Maintenance periods now support an optional `section_id`.

- `section_id = NULL`: community-wide collection, suitable for a common festival fund, CCTV project, common amenity, etc.
- `section_id = Block A`: Block A maintenance/collection.
- `section_id = Block B`: Block B maintenance/collection.

This lets Block A and Block B have separate collection while still allowing a single community finance collector to manage a common fund.

### 4. Mobile + OTP login
New APIs:

- `POST /auth/otp/request`
- `POST /auth/otp/verify`

OTP records are stored hashed and expire after the configured period.

Local development defaults to `OTP_DEV_MODE=true`, so the generated OTP is returned to the Flutter app for testing.

For production, configure Twilio:

- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_FROM_NUMBER`
- `OTP_DEV_MODE=false`

### 5. Family members
Multiple residents can already belong to the same unit. This implementation makes the flow explicit.

The primary resident can open **Invite family members** on the resident dashboard and generate a family join code.

A family member enters:

- Organization Code
- Family Join Code
- Their own name, phone, email and password

The backend associates the new resident with the **same unit** as the primary resident. No duplicate unit is created. The new family member remains pending until approved.

The family member gets their own login, notifications, vehicles/visitors and profile, while the unit remains shared.

## Migration order

The new migrations are chained after the existing chat migration head:

1. `b2d3e4f5a6c7_add_block_scopes_and_roles.py`
2. `c3d4e5f6a7b8_add_section_to_incidents.py`
3. `d4e5f6a7b8c9_add_maintenance_block_scope.py`
4. `e5f6a7b8c9d0_add_login_otps.py`
5. `f6a7b8c9d0e1_add_family_join_code.py`

Run:

```bash
cd backend
alembic upgrade head
```

## Important deployment note

Do not keep `OTP_DEV_MODE=true` in production. It intentionally exposes the OTP for local testing only.

## Existing data compatibility

- Existing organization admins continue to work as before.
- Existing sections remain sections in the database but are presented conceptually as Blocks for block administration.
- Existing community-wide maintenance periods keep `section_id = NULL`.
- Existing resident/unit relationships are preserved.
