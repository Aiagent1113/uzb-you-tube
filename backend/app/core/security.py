import hmac
import hashlib
import time
from typing import Optional, Set
from fastapi import Request, HTTPException, status
from .config import settings

# In-memory nonce cache to prevent replay attacks
_seen_nonces: Set[str] = set()
_MAX_TIMESTAMP_DRIFT_MS = 60000  # 60 seconds tolerance

class SecurityMiddleware:
    @staticmethod
    def verify_request_signature(
        timestamp: str,
        nonce: str,
        signature: str,
        device_id: str,
        endpoint: str,
        body_bytes: bytes = b""
    ) -> bool:
        """
        Validates HMAC-SHA256 signature:
        Message = "{timestamp}.{nonce}.{endpoint}.{body_sha256}.{device_id}"
        """
        try:
            ts_int = int(timestamp)
            current_ms = int(time.time() * 1000)
            if abs(current_ms - ts_int) > _MAX_TIMESTAMP_DRIFT_MS:
                return False  # Expired request or replay attack

            if nonce in _seen_nonces:
                return False  # Replayed nonce!

            # Add nonce to cache (in production, use Redis with TTL)
            _seen_nonces.add(nonce)
            if len(_seen_nonces) > 50000:
                _seen_nonces.clear()

            body_hash = hashlib.sha256(body_bytes).hexdigest()
            message_to_sign = f"{timestamp}.{nonce}.{endpoint}.{body_hash}.{device_id}"

            expected_sig = hmac.new(
                settings.HMAC_SECRET_KEY.encode("utf-8"),
                message_to_sign.encode("utf-8"),
                hashlib.sha256
            ).hexdigest()

            return hmac.compare_digest(expected_sig, signature)
        except Exception:
            return False

    @staticmethod
    def create_injection_contract(device_id: str) -> dict:
        """
        Generates a signed short-lived contract that authorizes the JavaScript injection
        in the InAppWebView.
        """
        ts = int(time.time() * 1000)
        raw = f"{ts}.{device_id}.{hash(settings.HMAC_SECRET_KEY)}"
        sig = hashlib.sha256(raw.encode("utf-8")).hexdigest()
        return {
            "ts": ts,
            "dev": device_id,
            "sig": sig,
            "v": settings.VERSION
        }

async def require_signed_request(request: Request):
    """
    FastAPI Dependency to verify security headers on protected endpoints
    """
    ts = request.headers.get("X-UzDub-Timestamp")
    nonce = request.headers.get("X-UzDub-Nonce")
    signature = request.headers.get("X-UzDub-Signature")
    device_id = request.headers.get("X-UzDub-DeviceID")

    if not all([ts, nonce, signature, device_id]):
        # Allow internal health checks / docs in development
        if request.url.path in ["/docs", "/openapi.json", "/health", "/api/v1/"]:
            return True
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing security signature headers"
        )

    body = await request.body()
    is_valid = SecurityMiddleware.verify_request_signature(
        timestamp=ts,
        nonce=nonce,
        signature=signature,
        device_id=device_id,
        endpoint=request.url.path,
        body_bytes=body
    )

    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid cryptographic signature or tampered payload"
        )
    return True
