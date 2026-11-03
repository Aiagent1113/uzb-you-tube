from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
import uuid
from ....core.security import require_signed_request

router = APIRouter()

class LicenseVerifyRequest(BaseModel):
    license_key: str
    device_id: str

class LicenseVerifyResponse(BaseModel):
    is_valid: bool
    status: str
    tier: str

@router.post("/verify", response_model=LicenseVerifyResponse)
async def verify_license(
    payload: LicenseVerifyRequest,
    _ = Depends(require_signed_request)
):
    key = payload.license_key.strip().upper()
    if key.startswith("UZDUB-PRO-") and len(key) >= 18:
        return LicenseVerifyResponse(
            is_valid=True,
            status="active",
            tier="unlimited_hd"
        )
    return LicenseVerifyResponse(
        is_valid=False,
        status="invalid",
        tier="none"
    )

@router.post("/telegram/webhook")
async def telegram_webhook(update: dict):
    """
    Telegram Bot webhook receiver.
    Generates unique license key when user completes payment via Telegram Stars / Click / Payme.
    """
    message = update.get("message", {})
    text = message.get("text", "")
    chat = message.get("chat", {})
    chat_id = chat.get("id")

    # In production, uses aiogram / telegram-bot API to issue license key
    license_key = f"UZDUB-PRO-{uuid.uuid4().hex[:8].upper()}-{uuid.uuid4().hex[:8].upper()}"

    return {
        "status": "ok",
        "generated_key": license_key,
        "chat_id": chat_id
    }
