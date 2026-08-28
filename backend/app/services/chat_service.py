from datetime import datetime
from pathlib import Path
from uuid import uuid4

from app.core.event_bus import event_bus
from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException
from app.core.logger import logger
from app.events.chat_events import ChatMessageSentEvent
from app.models.chat import ChatConversation, ChatMessage, ChatParticipant
from app.models.notification import Notification
from app.models.user import User
from app.repositories.chat_repository import ChatRepository
from app.services.storage_service import StorageService
from app.models.chat_attachment import ChatAttachment


class ChatService:
    """Business rules for safe organization-scoped community chat."""

    CHAT_ROLES = {
        "SYSTEM_ADMIN",
        "ORGANIZATION_ADMIN",
        "PROPERTY_MANAGER",
        "SECURITY_MANAGER",
        "SECURITY_GUARD",
        "RESIDENT",
        "COMMUNITY_FINANCE_ADMIN",
        "BLOCK_ADMIN",
    }

    def __init__(self, repo: ChatRepository):
        self.repo = repo
        self.db = repo.db

    def _check_user(self, current_user: User):
        if current_user.role not in self.CHAT_ROLES:
            raise ForbiddenException("Your role cannot use community chat.")
        if not current_user.organization_id:
            raise ForbiddenException("Your account is not associated with an organization.")

    def _target_user(self, current_user: User, target_user_id: int):
        user = (
            self.db.query(User)
            .filter(
                User.id == target_user_id,
                User.organization_id == current_user.organization_id,
                User.is_active.is_(True),
            )
            .first()
        )
        if not user:
            raise NotFoundException("Chat user")
        if user.id == current_user.id:
            raise BadRequestException("You cannot start a direct chat with yourself.")
        if user.role == "SYSTEM_ADMIN" and current_user.role != "SYSTEM_ADMIN":
            raise ForbiddenException("System administrators are not available for direct community chat.")
        return user

    @staticmethod
    def _message_response(message: ChatMessage):
        return {
            "id": message.id,
            "conversation_id": message.conversation_id,
            "sender_user_id": message.sender_user_id,
            "sender_name": message.sender.full_name if message.sender else "User",
            "sender_role": message.sender.role if message.sender else "USER",
            "content": "This message was deleted" if message.is_deleted else message.content,
            "created_at": message.created_at,
            "updated_at": message.updated_at,
            "is_edited": bool(message.is_edited and not message.is_deleted),
            "is_deleted": message.is_deleted,
            "attachments": [
                {
                    "id": a.id,
                    "file_name": a.file_name,
                    "content_type": a.content_type,
                    "file_size": a.file_size,
                    "file_url": StorageService().url_for(a.file_path),
                    "created_at": a.created_at,
                }
                for a in (message.attachments or [])
            ],
        }

    def _conversation_response(self, conversation: ChatConversation, user_id: int):
        participant = self.repo.participant(conversation.id, user_id)
        participants = [
            {
                "id": p.user.id,
                "full_name": p.user.full_name,
                "role": p.user.role,
            }
            for p in conversation.participants
            if p.user is not None and p.user.is_active
        ]
        latest = self.repo.latest_message(conversation.id)
        last_message = self._message_response(latest) if latest else None
        unread = self.repo.unread_count(
            conversation.id,
            participant.last_read_at if participant else None,
        )
        name = conversation.name
        if conversation.conversation_type == "DIRECT" and not name:
            other = next((p for p in participants if p["id"] != user_id), None)
            name = other["full_name"] if other else "Direct Chat"
        return {
            "id": conversation.id,
            "conversation_type": conversation.conversation_type,
            "name": name,
            "participants": participants,
            "last_message": last_message,
            "unread_count": unread,
            "updated_at": conversation.updated_at,
        }

    def users(self, current_user: User, search: str | None = None):
        self._check_user(current_user)
        q = self.db.query(User).filter(
            User.organization_id == current_user.organization_id,
            User.is_active.is_(True),
            User.id != current_user.id,
            User.role != "SYSTEM_ADMIN",
        )
        if search and search.strip():
            value = f"%{search.strip()}%"
            q = q.filter(User.full_name.ilike(value) | User.email.ilike(value))
        return [
            {"id": u.id, "full_name": u.full_name, "role": u.role}
            for u in q.order_by(User.full_name.asc()).limit(50).all()
        ]

    def _create_conversation(self, current_user, target_user=None, community=False):
        if community:
            conversation = self.repo.community_conversation(current_user.organization_id)
            if conversation:
                return conversation
            conversation = ChatConversation(
                organization_id=current_user.organization_id,
                conversation_type="COMMUNITY",
                name="Community Chat",
                created_by_user_id=current_user.id,
            )
            self.db.add(conversation)
            self.repo.flush()
            users = (
                self.db.query(User)
                .filter(
                    User.organization_id == current_user.organization_id,
                    User.is_active.is_(True),
                    User.role != "SYSTEM_ADMIN",
                )
                .all()
            )
            for user in users:
                self.db.add(ChatParticipant(conversation_id=conversation.id, user_id=user.id))
            self.repo.commit()
            return conversation

        conversation = self.repo.direct_conversation(
            current_user.organization_id, current_user.id, target_user.id
        )
        if conversation:
            return conversation
        conversation = ChatConversation(
            organization_id=current_user.organization_id,
            conversation_type="DIRECT",
            created_by_user_id=current_user.id,
        )
        self.db.add(conversation)
        self.repo.flush()
        self.db.add_all([
            ChatParticipant(conversation_id=conversation.id, user_id=current_user.id),
            ChatParticipant(conversation_id=conversation.id, user_id=target_user.id),
        ])
        self.repo.commit()
        return conversation

    def community(self, current_user: User):
        self._check_user(current_user)
        conversation = self._create_conversation(current_user, community=True)
        # New members added after first creation join automatically on first access.
        if not self.repo.participant(conversation.id, current_user.id):
            self.db.add(ChatParticipant(conversation_id=conversation.id, user_id=current_user.id))
            self.repo.commit()
        return self._conversation_response(conversation, current_user.id)

    def start_direct(self, current_user: User, target_user_id: int):
        self._check_user(current_user)
        target = self._target_user(current_user, target_user_id)
        conversation = self._create_conversation(current_user, target_user=target)
        return self._conversation_response(conversation, current_user.id)

    def list_conversations(self, current_user: User):
        self._check_user(current_user)
        return [
            self._conversation_response(c, current_user.id)
            for c in self.repo.conversations_for_user(
                current_user.organization_id, current_user.id
            )
        ]

    def _conversation_for_user(self, current_user, conversation_id):
        self._check_user(current_user)
        conversation = self.repo.get_conversation(
            current_user.organization_id, conversation_id
        )
        if not conversation:
            raise NotFoundException("Conversation")
        if not self.repo.participant(conversation.id, current_user.id):
            # Community conversations allow organization members to join on demand.
            if conversation.conversation_type == "COMMUNITY":
                self.db.add(ChatParticipant(conversation_id=conversation.id, user_id=current_user.id))
                self.repo.commit()
            else:
                raise ForbiddenException("You are not a participant in this conversation.")
        return conversation

    def messages(self, current_user: User, conversation_id: int):
        conversation = self._conversation_for_user(current_user, conversation_id)
        return [self._message_response(m) for m in self.repo.messages(conversation.id)]

    def send(self, current_user: User, conversation_id: int, content: str):
        conversation = self._conversation_for_user(current_user, conversation_id)
        text = content.strip()
        if not text:
            raise BadRequestException("Message cannot be empty.")
        if len(text) > 4000:
            raise BadRequestException("Message is too long.")
        message = ChatMessage(
            conversation_id=conversation.id,
            sender_user_id=current_user.id,
            content=text,
        )
        self.db.add(message)
        conversation.updated_at = datetime.utcnow()
        self.repo.flush()

        # Create an in-app notification for every other participant. This is
        # intentionally stored in the normal notification inbox so the same
        # notification bell works for residents, guards and administrators.
        sender_name = current_user.full_name or current_user.email
        for participant in conversation.participants:
            if participant.user_id == current_user.id:
                continue
            if participant.user is None or not participant.user.is_active:
                continue
            self.db.add(Notification(
                user_id=participant.user_id,
                title=f"New message from {sender_name}",
                message=text[:500],
                notification_type="CHAT",
                entity_type="COMMUNITY_CHAT",
                entity_id=conversation.id,
                action="OPEN_CHAT",
            ))

        event_bus.publish(
            ChatMessageSentEvent(
                conversation_id=conversation.id,
                organization_id=conversation.organization_id,
                sender_user_id=current_user.id,
                message_id=message.id,
            )
        )
        self.repo.commit()
        logger.info(
            "Chat message sent conversation=%s sender=%s",
            conversation.id,
            current_user.id,
        )
        return self._message_response(message)


    async def send_attachment(self, current_user: User, conversation_id: int, content: str, upload):
        conversation = self._conversation_for_user(current_user, conversation_id)
        text = content.strip()
        if len(text) > 4000:
            raise BadRequestException("Message is too long.")
        content_type = (upload.content_type or "").lower()
        allowed = {
            "image/jpeg", "image/png", "image/webp", "image/gif",
            "application/pdf",
        }
        if content_type not in allowed:
            raise BadRequestException("Unsupported attachment type. Use JPG, PNG, WEBP, GIF or PDF.")
        filename = (upload.filename or "attachment").strip()
        extension = Path(filename).suffix.lower()
        if extension not in {".jpg", ".jpeg", ".png", ".webp", ".gif", ".pdf"}:
            raise BadRequestException("Unsupported attachment extension.")
        content_bytes = await upload.read()
        if not content_bytes:
            raise BadRequestException("Attachment is empty.")
        if len(content_bytes) > 10 * 1024 * 1024:
            raise BadRequestException("Chat attachment must be 10 MB or smaller.")
        if not text:
            text = "Attachment"

        message = ChatMessage(
            conversation_id=conversation.id,
            sender_user_id=current_user.id,
            content=text,
        )
        self.db.add(message)
        self.repo.flush()
        stored = StorageService().upload_bytes(
            f"chat/{conversation.id}/{message.id}/{uuid4().hex}{extension}",
            content_bytes,
            content_type=content_type,
        )
        self.db.add(ChatAttachment(
            message_id=message.id,
            uploaded_by_user_id=current_user.id,
            file_name=filename[:255],
            content_type=content_type,
            file_size=len(content_bytes),
            file_path=stored,
        ))
        conversation.updated_at = datetime.utcnow()
        sender_name = current_user.full_name or current_user.email
        for participant in conversation.participants:
            if participant.user_id == current_user.id or participant.user is None or not participant.user.is_active:
                continue
            self.db.add(Notification(
                user_id=participant.user_id,
                title=f"New message from {sender_name}",
                message=text[:500],
                notification_type="CHAT",
                entity_type="COMMUNITY_CHAT",
                entity_id=conversation.id,
                action="OPEN_CHAT",
            ))
        event_bus.publish(ChatMessageSentEvent(
            conversation_id=conversation.id,
            organization_id=conversation.organization_id,
            sender_user_id=current_user.id,
            message_id=message.id,
        ))
        self.repo.commit()
        self.db.refresh(message)
        return self._message_response(message)

    def _message_for_participant(self, current_user: User, conversation_id: int, message_id: int):
        conversation = self._conversation_for_user(current_user, conversation_id)
        message = (
            self.db.query(ChatMessage)
            .filter(
                ChatMessage.id == message_id,
                ChatMessage.conversation_id == conversation.id,
            )
            .first()
        )
        if not message:
            raise NotFoundException("Chat message")
        if message.sender_user_id != current_user.id:
            raise ForbiddenException("You can only modify your own messages.")
        return conversation, message

    def edit(self, current_user: User, conversation_id: int, message_id: int, content: str):
        conversation, message = self._message_for_participant(current_user, conversation_id, message_id)
        if message.is_deleted:
            raise BadRequestException("Deleted messages cannot be edited.")
        text = content.strip()
        if not text:
            raise BadRequestException("Message cannot be empty.")
        if len(text) > 4000:
            raise BadRequestException("Message is too long.")
        message.content = text
        message.is_edited = True
        message.updated_at = datetime.utcnow()
        conversation.updated_at = message.updated_at
        self.repo.commit()
        logger.info("Chat message edited conversation=%s message=%s user=%s", conversation.id, message.id, current_user.id)
        return self._message_response(message)

    def delete(self, current_user: User, conversation_id: int, message_id: int):
        conversation, message = self._message_for_participant(current_user, conversation_id, message_id)
        if message.is_deleted:
            return self._message_response(message)
        now = datetime.utcnow()
        message.is_deleted = True
        message.deleted_at = now
        message.updated_at = now
        message.content = "This message was deleted"
        conversation.updated_at = now
        self.repo.commit()
        logger.info("Chat message deleted conversation=%s message=%s user=%s", conversation.id, message.id, current_user.id)
        return self._message_response(message)

    def mark_read(self, current_user: User, conversation_id: int):
        conversation = self._conversation_for_user(current_user, conversation_id)
        participant = self.repo.participant(conversation.id, current_user.id)
        participant.last_read_at = datetime.utcnow()
        self.repo.commit()
        return {"success": True}
