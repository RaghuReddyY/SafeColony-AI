# Money Management / Maintenance Module

Implemented end-to-end maintenance money tracking.

## Flow

1. Organization Admin creates a monthly maintenance period.
2. Previous period closing balance becomes the new period opening balance.
3. Admin generates one bill for every active resident.
4. Residents receive a `MAINTENANCE_DUE` notification when their bill is generated.
5. Admin records monthly expenses with category, description, amount and date.
6. Admin dashboard shows:
   - opening balance
   - total billed
   - total collected
   - total expenses
   - remaining/closing balance
   - paid resident count
   - unpaid resident count
   - resident payment tracking
   - expense list
7. Admin or resident can record a payment. The bill becomes `PARTIAL` or `PAID`.
8. Organization admins receive a collection notification when a payment is recorded.
9. An hourly scheduler checks overdue unpaid/partial bills and sends one reminder per resident per day.
10. Paid bills are excluded from reminders automatically.

## Database

- `maintenance_periods`
- `maintenance_bills`
- `maintenance_payments`
- `maintenance_expenses`

Run the new Alembic migration before starting the backend.

## APIs

- `GET /maintenance/dashboard`
- `POST /maintenance/periods`
- `POST /maintenance/periods/{period_id}/generate-bills`
- `POST /maintenance/periods/{period_id}/expenses`
- `GET /maintenance/me`
- `POST /maintenance/bills/{bill_id}/payments`

## Important behavior

There is intentionally no Razorpay/Stripe integration in this implementation. A payment is currently recorded as a manual collection/payment record. A real gateway can be added later without changing the bill/expense accounting model.
