import os
import uuid

import qrcode


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

        image = qr.make_image(fill_color="black", back_color="white")

        folder = "uploads/qr"

        os.makedirs(folder, exist_ok=True)

        filename = f"visitor_{visitor_id}.png"

        filepath = os.path.join(folder, filename)

        image.save(filepath)

        return token, filepath