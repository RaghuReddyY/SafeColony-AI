SafeColony AI - Money Management / Maintenance implementation

Copy these files into the same relative paths in the existing project.
Then run:
  cd backend
  alembic upgrade head
  start the FastAPI backend

Flutter:
  cd frontend/safecolony_app
  flutter pub get
  flutter run -d chrome

Organization Admin:
  Dashboard -> Money Management

Resident:
  Dashboard sidebar -> Maintenance

The module supports monthly bills, expenses, opening/closing balance, paid/unpaid tracking,
manual payment recording, payment notifications, and daily overdue reminders.
