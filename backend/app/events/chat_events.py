from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class ChatMessageSentEvent:
    """Published after a community chat message is created."""

    conversation_id: int
    organization_id: int
    sender_user_id: int
    message_id: int
    timestamp: datetime = field(default_factory=datetime.utcnow)
