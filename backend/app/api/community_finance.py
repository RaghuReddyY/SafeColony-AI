from decimal import Decimal

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.schemas.community_finance import (
    CommunityFinanceDashboardResponse,
    CommunityFundCreate,
    CommunityFundUpdate,
    CommunityFundContributionCreate,
    CommunityFundResidentPaymentCreate,
    CommunityFundExpenseCreate,
    CommunityFundPaymentLinkResponse,
    CommunityFundResponse,
)
from app.security.permissions import Permissions
from app.repositories.community_finance_repository import CommunityFinanceRepository
from app.services.community_finance_service import CommunityFinanceService

router = APIRouter(prefix="/community-finance", tags=["Community Finance"])


def get_service(db: Session = Depends(get_db)):
    return CommunityFinanceService(CommunityFinanceRepository(db))


@router.get("/dashboard", response_model=CommunityFinanceDashboardResponse, dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_VIEW))])
def dashboard(current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.dashboard(current_user)


@router.post("/funds", response_model=CommunityFundResponse, dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_MANAGE))])
def create_fund(data: CommunityFundCreate, current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.create_fund(current_user, data)


@router.put("/funds/{fund_id}", response_model=CommunityFundResponse, dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_MANAGE))])
def update_fund(fund_id: int, data: CommunityFundUpdate, current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.update_fund(current_user, fund_id, data)


@router.delete("/funds/{fund_id}", dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_MANAGE))])
def delete_fund(fund_id: int, current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.delete_fund(current_user, fund_id)


@router.post("/funds/{fund_id}/publish", response_model=CommunityFundResponse, dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_MANAGE))])
def publish_fund(fund_id: int, current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.publish_fund(current_user, fund_id)


@router.post("/funds/{fund_id}/close", response_model=CommunityFundResponse, dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_MANAGE))])
def close_fund(fund_id: int, current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.close_fund(current_user, fund_id)


@router.post("/funds/{fund_id}/contributions", response_model=CommunityFundResponse, dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_MANAGE))])
def add_contribution(fund_id: int, data: CommunityFundContributionCreate, current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.add_contribution(current_user, fund_id, data)


@router.post("/funds/{fund_id}/pay", response_model=CommunityFundPaymentLinkResponse, dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_PAYMENT))])
def create_payment(fund_id: int, amount: Decimal, current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.create_payment(current_user, fund_id, amount)


@router.post("/funds/{fund_id}/payments", response_model=CommunityFundResponse, dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_PAYMENT))])
def submit_payment(fund_id: int, data: CommunityFundResidentPaymentCreate, current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.submit_payment(current_user, fund_id, data)


@router.post("/contributions/{contribution_id}/verify", dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_MANAGE))])
def verify_contribution(contribution_id: int, approve: bool, current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.verify_contribution(current_user, contribution_id, approve)


@router.post("/funds/{fund_id}/expenses", response_model=CommunityFundResponse, dependencies=[Depends(require_permission(Permissions.COMMUNITY_FINANCE_MANAGE))])
def add_expense(fund_id: int, data: CommunityFundExpenseCreate, current_user: User = Depends(get_current_user), service: CommunityFinanceService = Depends(get_service)):
    return service.add_expense(current_user, fund_id, data)
