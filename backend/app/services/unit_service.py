from app.models.unit import Unit


class UnitService:

    def __init__(self, repo):
        self.repo = repo

    def create(self, data):
        unit = Unit(
            property_id=data.property_id,
            section_id=data.section_id,
            unit_number=data.unit_number,
            unit_type=data.unit_type,
            floor=data.floor,
            owner_name=data.owner_name,
            intercom_number=data.intercom_number,
        )

        return self.repo.create(unit)

    def get_all(self):
        return self.repo.get_all()

    def get_by_section(self, section_id):
        return self.repo.get_by_section(section_id)