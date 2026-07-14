from app.models.property import Property


class PropertyService:

    def __init__(self, repo):

        self.repo = repo

    def create(self, data):

        property = Property(
            name=data.name,
            property_type=data.property_type,
            address=data.address,
            city=data.city,
            state=data.state,
            country=data.country,
            pincode=data.pincode,
        )

        return self.repo.create(property)

    def get_all(self):

        return self.repo.get_all()

    def get(self, property_id):

        return self.repo.get(property_id)