import json
import smtplib
import urllib.parse
import urllib.request
from email.message import EmailMessage

from app.config import settings


def send_email(destination: str, subject: str, message: str) -> str:
    if not all([settings.SMTP_HOST, settings.SMTP_USERNAME, settings.SMTP_PASSWORD, settings.SMTP_FROM_EMAIL]):
        raise RuntimeError("SMTP provider is not configured.")
    mail = EmailMessage()
    mail["From"] = settings.SMTP_FROM_EMAIL
    mail["To"] = destination
    mail["Subject"] = subject
    mail.set_content(message)
    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=20) as smtp:
        smtp.starttls()
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
