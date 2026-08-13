from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.chat import ChatConversation, ChatMessage, ChatParticipant


class ChatRepository:
    """Database-only operations for community chat."""

    def __init__(self, db: Session):
        self.db = db

    def get_conversation(self, organization_id: int, conversation_id: int):
        return (
            self.db.query(ChatConversation)
            .options(
                joinedload(ChatConversation.participants).joinedload(ChatParticipant.user),
            )
            .filter(
                ChatConversation.id == conversation_id,
                ChatConversation.organization_id == organization_id,
            )
            .first()
        )

    def participant(self, conversation_id: int, user_id: int):
        return (
            self.db.query(ChatParticipant)
            .filter(
                ChatParticipant.conversation_id == conversation_id,
                ChatParticipant.user_id == user_id,
            )
            .first()
        )

    def direct_conversation(self, organization_id: int, user_a: int, user_b: int):
        rows = (
            self.db.query(ChatConversation)
            .join(ChatParticipant)
            .filter(
                ChatConversation.organization_id == organization_id,
                ChatConversation.conversation_type == "DIRECT",
                ChatParticipant.user_id.in_([user_a, user_b]),
            )
            .all()
        )
        for conversation in rows:
            ids = {p.user_id for p in conversation.participants}
            if ids == {user_a, user_b}:
                return conversation
        return None

    def community_conversation(self, organization_id: int):
        return (
            self.db.query(ChatConversation)
            .filter(
                ChatConversation.organization_id == organization_id,
                ChatConversation.conversation_type == "COMMUNITY",
            )
            .first()
        )

    def conversations_for_user(self, organization_id: int, user_id: int):
        return (
            self.db.query(ChatConversation)
            .join(ChatParticipant)
            .options(
                joinedload(ChatConversation.participants).joinedload(ChatParticipant.user),
            )
            .filter(
                ChatConversation.organization_id == organization_id,
                ChatParticipant.user_id == user_id,
            )
            .order_by(ChatConversation.updated_at.desc())
            .all()
        )

    def latest_message(self, conversation_id: int):
        return (
            self.db.query(ChatMessage)
            .options(joinedload(ChatMessage.sender))
            .filter(ChatMessage.conversation_id == conversation_id)
            .order_by(ChatMessage.created_at.desc())
            .first()
        )

    def messages(self, conversation_id: int, limit: int = 100):
        return (
            self.db.query(ChatMessage)
            .options(joinedload(ChatMessage.sender))
            .filter(ChatMessage.conversation_id == conversation_id)
            .order_by(ChatMessage.created_at.asc())
            .limit(limit)
            .all()
        )

    def unread_count(self, conversation_id: int, last_read_at):
        q = self.db.query(func.count(ChatMessage.id)).filter(
            ChatMessage.conversation_id == conversation_id,
        )
        if last_read_at:
            q = q.filter(ChatMessage.created_at > last_read_at)
        return int(q.scalar() or 0)

    def commit(self):
        self.db.commit()

    def flush(self):
        self.db.flush()
