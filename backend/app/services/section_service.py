from app.models.section import Section


class SectionService:

    def __init__(self, repo):
        self.repo = repo

    def create(self, data):
        section = Section(
            property_id=data.property_id,
            name=data.name,
            description=data.description,
        )

        return self.repo.create(section)

    def get_all(self):
        return self.repo.get_all()

    def get_by_property(self, property_id):
        return self.repo.get_by_property(property_id)