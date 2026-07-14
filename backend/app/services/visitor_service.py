from datetime import datetime
from app.utils.qr_generator import QRGenerator

from fastapi import HTTPException

from app.models.visitor import Visitor
from app.core.logger import logger


class VisitorService:

    def __init__(self, repo):
        self.repo = repo

    def create(self, data):

        visitor = Visitor(
            resident_id=data.resident_id,
            visitor_name=data.visitor_name,
            phone=data.phone,
            visitor_type=data.visitor_type,
            purpose=data.purpose,
            vehicle_number=data.vehicle_number,
            expected_time=data.expected_time,
        )

        return self.repo.create(visitor)

    def get_all(self):
        return self.repo.get_all()

    def get_by_resident(self, resident_id):
        return self.repo.get_by_resident(resident_id)

    def approve(self, visitor_id):

        visitor = self.repo.get_by_id(visitor_id)

        if visitor is None:
         raise HTTPException(
            status_code=404,
            detail="Visitor not found",
        )

        if visitor.status != "PENDING":
            raise HTTPException(
            status_code=400,
            detail="Only pending visitors can be approved",
        )

        token, qr_path = QRGenerator.generate(visitor.id)

        visitor.status = "APPROVED"

        visitor.qr_token = token

        visitor.qr_code = qr_path

        visitor.approved_at = datetime.utcnow()

        logger.info(
            f"Visitor Approved: {visitor.visitor_name}"
        )

        return self.repo.save(visitor)

    def reject(self, visitor_id):

        visitor = self.repo.get_by_id(visitor_id)

        if visitor is None:
            raise HTTPException(404, "Visitor not found")

        visitor.status = "REJECTED"

        return self.repo.save(visitor)

    def check_in(self, visitor_id):

        visitor = self.repo.get_by_id(visitor_id)

        if visitor is None:
            raise HTTPException(404, "Visitor not found")

        if visitor.status != "APPROVED":
            raise HTTPException(
                400,
                "Visitor must be approved before check-in"
            )

        visitor.status = "CHECKED_IN"
        visitor.check_in_time = datetime.utcnow()

        return self.repo.save(visitor)

    def check_out(self, visitor_id):

        visitor = self.repo.get_by_id(visitor_id)

        if visitor is None:
            raise HTTPException(404, "Visitor not found")

        if visitor.status != "CHECKED_IN":
            raise HTTPException(
                400,
                "Visitor is not checked in"
            )

        visitor.status = "CHECKED_OUT"
        visitor.check_out_time = datetime.utcnow()

        return self.repo.save(visitor)
    
    def scan_qr(self, qr_token: str):

        visitor = self.repo.get_by_qr_token(qr_token)

        if visitor is None:
            raise HTTPException(
                status_code=404,
                detail="Invalid QR Code"
            )

        if visitor.status != "APPROVED":
            raise HTTPException(
                status_code=400,
                detail=f"Visitor status is {visitor.status}"
            )

        visitor.status = "CHECKED_IN"
        visitor.check_in_time = datetime.utcnow()

        self.repo.save(visitor)

        return visitor
        
    def scan_exit(self, qr_token: str):

        visitor = self.repo.get_by_qr_token(qr_token)

        if visitor is None:
            raise HTTPException(
                status_code=404,
                detail="Invalid QR Code"
            )

        if visitor.status != "CHECKED_IN":
            raise HTTPException(
                status_code=400,
                detail="Visitor is not checked in"
            )

        visitor.status = "CHECKED_OUT"
        visitor.check_out_time = datetime.utcnow()

        return self.repo.save(visitor)