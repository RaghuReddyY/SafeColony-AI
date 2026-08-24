
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.auth.dependencies import get_current_user
from app.database.dependency import get_db
from app.models.user import User
from app.schemas.super_app import *
from app.services.super_app_service import SuperAppService

router=APIRouter(prefix="/super-app",tags=["SafeColony Super App"])

def svc(db=Depends(get_db)): return SuperAppService(db)

@router.get("/overview",response_model=SuperAppOverviewResponse)
def overview(current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.overview(current_user)

@router.get("/service-providers", response_model=list[ServiceProviderResponse])
def service_providers(category: str | None = None, current_user: User = Depends(get_current_user), service: SuperAppService = Depends(svc)):
    return service.service_providers(current_user, category)

@router.post("/service-requests",response_model=ServiceRequestResponse)
def create_request(data:ServiceRequestCreate,current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.create_request(current_user,data)

@router.get("/service-requests",response_model=list[ServiceRequestResponse])
def requests(current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.list_requests(current_user)

@router.patch("/service-requests/{request_id}",response_model=ServiceRequestResponse)
def update_request(request_id:int,data:ServiceStatusUpdate,current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.update_request(current_user,request_id,data)

@router.get("/vendor/service-requests",response_model=list[ServiceRequestResponse])
def vendor_requests(current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.vendor_requests(current_user)

@router.patch("/vendor/service-requests/{request_id}",response_model=ServiceRequestResponse)
def vendor_update_request(request_id:int,data:ServiceStatusUpdate,current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.vendor_update_request(current_user,request_id,data)

@router.get("/offers",response_model=list[OfferResponse])
def offers(current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.offers(current_user)

@router.post("/offers",response_model=OfferResponse)
def create_offer(data:OfferCreate,current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.create_offer(current_user,data)

@router.post("/ratings",response_model=RatingResponse)
def rating(data:RatingCreate,current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.rate(current_user,data)

@router.get("/recurring-orders",response_model=list[RecurringOrderResponse])
def recurring(current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.list_recurring(current_user)

@router.post("/recurring-orders",response_model=RecurringOrderResponse)
def create_recurring(data:RecurringOrderCreate,current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.recurring(current_user,data)

@router.get("/delivery-hub",response_model=list[ParcelResponse])
def hub(current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.parcels(current_user)

@router.post("/delivery-hub/parcels",response_model=ParcelResponse)
def create_parcel(data:ParcelCreate,current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.create_parcel(current_user,data)

@router.post("/delivery-hub/{parcel_id}/pickup",response_model=ParcelResponse)
def pickup(parcel_id:int,current_user:User=Depends(get_current_user),service:SuperAppService=Depends(svc)): return service.pickup(current_user,parcel_id)


@router.get("/utility-providers", response_model=list[UtilityProviderResponse])
def utility_providers(current_user: User = Depends(get_current_user), service: SuperAppService = Depends(svc)):
    return service.utility_providers(current_user)

@router.post("/utility-providers", response_model=UtilityProviderResponse)
def create_utility_provider(data: UtilityProviderCreate, current_user: User = Depends(get_current_user), service: SuperAppService = Depends(svc)):
    return service.create_utility_provider(current_user, data)

@router.patch("/utility-providers/{provider_id}", response_model=UtilityProviderResponse)
def update_utility_provider(provider_id: int, data: UtilityProviderUpdate, current_user: User = Depends(get_current_user), service: SuperAppService = Depends(svc)):
    return service.update_utility_provider(current_user, provider_id, data)

@router.get("/map-points", response_model=list[MapPointResponse])
def map_points(current_user: User = Depends(get_current_user), service: SuperAppService = Depends(svc)):
    return service.map_points(current_user)

@router.post("/map-points", response_model=MapPointResponse)
def create_map_point(data: MapPointCreate, current_user: User = Depends(get_current_user), service: SuperAppService = Depends(svc)):
    return service.create_map_point(current_user, data)

@router.patch("/map-points/{point_id}", response_model=MapPointResponse)
def update_map_point(point_id: int, data: MapPointUpdate, current_user: User = Depends(get_current_user), service: SuperAppService = Depends(svc)):
    return service.update_map_point(current_user, point_id, data)
