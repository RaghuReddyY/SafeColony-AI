# AI, Chat and Notification Fixes

## Notification workflow

- Resident complaint creation notifies organization admins, property managers, security managers and guards.
- Complaint assignment notifies the resident and assigned user.
- Complaint resolution notifies the resident and assignee.
- Complaint escalation notifies the resident and management team.
- Incident creation notifies management/security roles except the reporter.
- Incident assignment/status/investigation updates notify the reporter and assignee.
- Incident resolution notifies the reporter/assignee and the management/security team.
- Chat messages create an in-app notification for every other conversation participant.

All notification inboxes are user-scoped through `/notifications/me`.

## AI live-data accuracy

The AI context now distinguishes: 

- current user's unread notifications
- unresolved security alerts
- open incidents
- open complaints
- current maintenance collection/expense/outstanding totals
- latest maintenance monthly amount for management roles
- bounded incident and alert detail lists
- current user's recent notification details

The assistant is instructed to treat these values as authoritative live database data and not invent values.

## Dashboard chat shortcut

Resident, guard/security manager and administrator dashboards now have a reusable bottom-right quick-access control containing:

- Community Chat
- AI Assistant

The chat shortcut shows the unread chat-message count and refreshes periodically.

## Testing

Backend Python compilation and the existing AI/pending-module tests pass. Flutter SDK was not available in the build environment, so run `flutter analyze` and `flutter test` on the Windows development machine.
