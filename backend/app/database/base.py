from app.database.base_class import Base

# Import every model so Alembic can discover them

from app.models.user import User
from app.models.organization import Organization
from app.models.property import Property
from app.models.section import Section
from app.models.unit import Unit
from app.models.resident import Resident
from app.models.vehicle import Vehicle
from app.models.visitor import Visitor
from app.models.notification import Notification
from app.models.vacation_mode import VacationMode
from app.models.security_alert import SecurityAlert
from app.models.delivery import Delivery
from app.models.maintenance_period import MaintenancePeriod
from app.models.maintenance_bill import MaintenanceBill
from app.models.maintenance_payment import MaintenancePayment
from app.models.maintenance_expense import MaintenanceExpense
from app.models.community_fund import CommunityFund, CommunityFundContribution, CommunityFundExpense

from app.models.notification_template import NotificationTemplate, NotificationDelivery
from app.models.incident import Incident, IncidentEvidence
from app.models.complaint import Complaint
from app.models.amenity import Amenity, AmenityBooking

from app.models.notification_device import NotificationDevice

from app.models.chat import ChatConversation, ChatParticipant, ChatMessage

from app.models.user_block_scope import UserBlockScope

from app.models.login_otp import LoginOTP
