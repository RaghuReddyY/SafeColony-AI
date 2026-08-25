import json
import smtplib
import urllib.parse
import urllib.request
from email.message import EmailMessage

from app.config import settings


def send_email(destination: str, subject: str, message: str) -> str:
    """Send an email through the configured SMTP provider.

    Cloud Run does not use the developer machine's .env file. The values must
    be supplied as runtime environment variables/secrets. This function fails
    loudly so callers never report a successful email when SMTP delivery
    actually failed.
    """
    missing = []
    if not settings.SMTP_HOST:
        missing.append("SMTP_HOST")
    if not settings.SMTP_USERNAME:
        missing.append("SMTP_USERNAME")
    if not settings.SMTP_PASSWORD:
        missing.append("SMTP_PASSWORD")
    if not settings.SMTP_FROM_EMAIL:
        missing.append("SMTP_FROM_EMAIL")

    if missing:
        raise RuntimeError(
            "SMTP provider is not configured; missing: " + ", ".join(missing)
        )

    destination = destination.strip().lower()
    if not destination:
        raise ValueError("Email destination is empty.")

    mail = EmailMessage()
    mail["From"] = settings.SMTP_FROM_EMAIL
    mail["To"] = destination
    mail["Subject"] = subject
    mail.set_content(message)

    # Gmail SMTP on port 587 uses STARTTLS. Failures are intentionally allowed
    # to propagate to AuthService so the API can return HTTP 503 instead of a
    # false success response.
    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=20) as smtp:
        smtp.ehlo()
        smtp.starttls()
        smtp.ehlo()
        smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
        smtp.send_message(mail)

    return destination


def _twilio_send(destination: str, body: str, from_number: str) -> str:
    if not all([settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN, from_number]):
        raise RuntimeError("Twilio provider is not configured.")
    url = (
        f"https://api.twilio.com/2010-04-01/Accounts/"
        f"{settings.TWILIO_ACCOUNT_SID}/Messages.json"
    )
    data = urllib.parse.urlencode({
        "To": destination,
        "From": from_number,
        "Body": body,
    }).encode()
    request = urllib.request.Request(url, data=data, method="POST")
    import base64
    token = base64.b64encode(
        f"{settings.TWILIO_ACCOUNT_SID}:{settings.TWILIO_AUTH_TOKEN}".encode()
    ).decode()
    request.add_header("Authorization", f"Basic {token}")
    request.add_header("Content-Type", "application/x-www-form-urlencoded")
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = json.loads(response.read().decode())
    return payload.get("sid", "")


def send_sms(destination: str, message: str) -> str:
    return _twilio_send(destination, message, settings.TWILIO_FROM_NUMBER)


def send_whatsapp(destination: str, message: str) -> str:
    if not settings.TWILIO_WHATSAPP_FROM:
        raise RuntimeError("Twilio WhatsApp provider is not configured.")
    to = destination if destination.startswith("whatsapp:") else f"whatsapp:{destination}"
    return _twilio_send(to, message, settings.TWILIO_WHATSAPP_FROM)


def send_push(destination: str, title: str, message: str) -> str:
    if not settings.FCM_SERVER_KEY:
        raise RuntimeError("FCM provider is not configured.")
    payload = json.dumps({
        "to": destination,
        "notification": {"title": title, "body": message},
    }).encode()
    request = urllib.request.Request(
        "https://fcm.googleapis.com/fcm/send",
        data=payload,
        headers={
            "Authorization": f"key={settings.FCM_SERVER_KEY}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        result = json.loads(response.read().decode())
    if result.get("failure", 0):
        raise RuntimeError(str(result))
    return str(result.get("message_id", "FCM"))
