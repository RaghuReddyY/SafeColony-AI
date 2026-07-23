from fastapi import HTTPException, status

from app.models.property import Property


class PropertyService:

    def __init__(
        self,
        property_repo,
        organization_repo,
    ):
        self.property_repo = property_repo
        self.organization_repo = organization_repo

    def create(
        self,
        current_user,
        data,
    ):

        organization = organization = self.organization_repo.get_by_id(
            current_user.organization_id
        )

        if not organization:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found.",
            )

        if self.property_repo.exists_by_name(
            current_user.organization_id,
            data.name,
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Property with this name already exists.",
            )

        property = Property(
            organization_id=current_user.organization_id,
            name=data.name,
            property_type=data.property_type,
            address=data.address,
            city=data.city,
            state=data.state,
            country=data.country,
            pincode=data.pincode,
        )

        return self.property_repo.create(property)

    def get_all(
        self,
        current_user,
    ):
        return self.property_repo.get_by_organization(
            current_user.organization_id
        )

    def get(
        self,
        current_user,
        property_id,
    ):

        property = self.property_repo.get(property_id)

        if (
            not property
            or property.organization_id != current_user.organization_id
        ):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Property not found.",
            )

        return property

    def update(
        self,
        current_user,
        property_id,
        data,
    ):

        property = self.property_repo.get(property_id)

        if (
            not property
            or property.organization_id != current_user.organization_id
        ):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Property not found.",
            )

        if (
            property.name.lower() != data.name.lower()
            and self.property_repo.exists_by_name(
                current_user.organization_id,
                data.name,
            )
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Property with this name already exists.",
            )

        property.name = data.name
        property.property_type = data.property_type
        property.address = data.address
        property.city = data.city
        property.state = data.state
        property.country = data.country
        property.pincode = data.pincode

        return self.property_repo.update(property)

    def delete(
        self,
        current_user,
        property_id,
    ):

        property = self.property_repo.get(property_id)

        if (
            not property
            or property.organization_id != current_user.organization_id
        ):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Property not found.",
            )

        self.property_repo.delete(property)