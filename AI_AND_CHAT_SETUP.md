# SafeColony AI + Community Chat

This update adds a role-aware AI operations center and organization-scoped community chat.

## AI capabilities implemented

- AI Security Summary
- AI Chat Assistant backed by Gemini
- AI Resident Assistant
- AI Guard Assistant
- AI Incident Summary
- AI Visitor Insights
- AI Visitor Risk Prediction (decision-support rules)
- AI Parking Prediction (current-data demand estimate)
- AI Suspicious Activity Detection (rule-based security signals)
- AI Reports / live operational report
- AI Daily Digest
- AI Incident Investigation guidance
- AI Smart Notifications prioritization
- AI Community Analytics
- AI Report Generator prompts
- AI Security Copilot

The AI overview uses the same live dashboard data that the user can see, including security alerts, incidents, complaints, visitors, deliveries, vehicles, vacations, notifications, amenities and maintenance. Resident AI additionally receives the resident's own dashboard values. It does not expose other residents' private records.

## Future AI capabilities

- CCTV integration
- Face recognition
- Voice assistant

These remain explicitly marked as FUTURE in the UI. No camera, biometric or voice processing is claimed to be implemented by this update.

## Community Chat

The new Community Chat supports:

- Community-wide chat
- Direct 1:1 chat
- Resident-to-resident chat
- Resident-to-admin/property-manager chat
- Resident-to-guard/security-manager chat
- Guard/admin/resident conversations within the same organization
- Searchable community user directory
- Unread counters and read state
- Four-second polling while a conversation is open for local development

The chat is organization-scoped and does not allow a user to open a direct conversation with another organization's user.

## Database migration

From `backend`:

```powershell
alembic upgrade head
```

This creates:

- `chat_conversations`
- `chat_participants`
- `chat_messages`

## Gemini

The existing AI chat still requires:

```env
GEMINI_API_KEY=your_key
GEMINI_MODEL=gemini-2.5-flash
```

Restart the FastAPI server after changing `.env`.

## API endpoints

AI:

- `GET /ai/overview`
- `POST /ai/chat`

Chat:

- `GET /chat/users`
- `GET /chat/conversations`
- `GET /chat/community`
- `POST /chat/direct/{target_user_id}`
- `GET /chat/conversations/{conversation_id}/messages`
- `POST /chat/conversations/{conversation_id}/messages`
- `POST /chat/conversations/{conversation_id}/read`

## Frontend

Open **AI Assistant**. It now has three tabs:

1. AI Insights
2. AI Chat
3. Community

Community Chat is also available directly from the resident/guard/admin dashboard navigation.
