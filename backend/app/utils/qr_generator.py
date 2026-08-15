import uuid

import qrcode

from app.services.storage_service import StorageService


class QRGenerator:

    @staticmethod
    def generate(visitor_id: int):
        token = str(uuid.uuid4())

        qr = qrcode.QRCode(
            version=1,
            box_size=10,
            border=4,
        )

        qr.add_data(token)
        qr.make(fit=True)

        image = qr.make_image(
            fill_color="black",
            back_color="white",
        )

        from io import BytesIO

        buffer = BytesIO()
        image.save(buffer, format="PNG")

        object_name = f"qr/visitor_{visitor_id}.png"
        StorageService().upload_bytes(
            object_name,
            buffer.getvalue(),
            content_type="image/png",
        )

        # Stable API route. The token protects access to the image without
        # exposing the storage bucket directly.
        return token, f"visitors/{visitor_id}/qr?token={token}"
