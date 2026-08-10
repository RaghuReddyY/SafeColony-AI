from app.repositories.property_repository import PropertyRepository
from app.repositories.section_repository import SectionRepository
from app.repositories.unit_repository import UnitRepository
from app.repositories.resident_repository import ResidentRepository


class GuardLookupService:

    def __init__(
        self,
        property_repo: PropertyRepository,
        section_repo: SectionRepository,
        unit_repo: UnitRepository,
        resident_repo: ResidentRepository,
    ):
        self.property_repo = property_repo
        self.section_repo = section_repo
        self.unit_repo = unit_repo
        self.resident_repo = resident_repo

    # -------------------------------------------------------
    # Properties
    # -------------------------------------------------------

    def properties(self):

        properties = self.property_repo.get_all()

        return [
            {
                "id": p.id,
                "name": p.name,
            }
            for p in properties
        ]

    # -------------------------------------------------------
    # Sections
    # -------------------------------------------------------

    def sections(self, property_id: int):

        sections = self.section_repo.get_by_property(
            property_id
        )

        return [
            {
                "id": s.id,
                "name": s.name,
            }
            for s in sections
        ]

    # -------------------------------------------------------
    # Units
    # -------------------------------------------------------

    def units(self, section_id: int):

        units = self.unit_repo.get_by_section(
            section_id
        )

        return [
            {
                "id": u.id,
                "unit_number": u.unit_number,
            }
            for u in units
        ]

    # -------------------------------------------------------
    # Residents
    # -------------------------------------------------------

    def residents(self, unit_id: int):

        residents = self.resident_repo.get_by_unit(
            unit_id
        )

        return [
            {
                "id": r.id,
                "full_name": r.full_name,
            }
            for r in residents
        ]