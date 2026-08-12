SafeColony maintenance/payment update

Changes:
- Fixed missing Razorpay Settings attributes.
- Added organization payment mode: RAZORPAY or DIRECT_UPI.
- Added Admin Payment Settings UI.
- Added Direct UPI flow for communities using a secretary/maintenance person's PhonePe/Google Pay UPI.
- Direct UPI payments require UTR/reference submission and administrator verification before PAID.
- Added pending Direct UPI verification UI for admins.
- Added Community Finance navigation for residents.
- Community Finance remains visible to residents through /maintenance/community-finance.
- Razorpay webhook amount parsing now accepts order amount_paid or payment amount.

Database:
Run from backend:
    alembic upgrade head

Environment:
Copy backend/.env.example to backend/.env and add your real secrets.
Do not commit backend/.env.

Razorpay mode:
Configure Test Mode keys for development and configure:
POST /maintenance/payments/razorpay/webhook
Use the same webhook secret in Razorpay and SafeColony.

Direct UPI mode:
Admin -> Money Management -> Payment Settings -> Direct UPI.
Enter the public UPI ID and receiver name. Residents can open a UPI app or copy the UPI ID. They then submit the UTR/reference. Admin verifies it before the bill becomes PAID.

After backend changes restart FastAPI.
After Flutter changes run:
    flutter pub get
    flutter analyze
    flutter run
