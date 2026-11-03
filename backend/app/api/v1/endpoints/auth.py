from fastapi import APIRouter, Depends, Header, HTTPException
from ....core.security import SecurityMiddleware, require_signed_request

router = APIRouter()

@router.post("/injection-contract")
async def get_injection_contract(
    x_uzdub_deviceid: str = Header(..., alias="X-UzDub-DeviceID"),
    _ = Depends(require_signed_request)
):
    """
    Issues a short-lived cryptographic contract that authorizes the JavaScript
    injection script inside InAppWebView.
    """
    contract = SecurityMiddleware.create_injection_contract(device_id=x_uzdub_deviceid)
    return {
        "status": "success",
        "contract": contract
    }
