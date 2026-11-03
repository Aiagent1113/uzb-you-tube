from fastapi import APIRouter, Depends
from pydantic import BaseModel
from ....services.translation_service import TranslationService
from ....core.security import require_signed_request

router = APIRouter()

class TranslationRequest(BaseModel):
    text: str
    source_lang: str = "auto"

class TranslationResponse(BaseModel):
    original: str
    translated: str

@router.post("/translate", response_model=TranslationResponse)
async def translate_subtitle_text(
    payload: TranslationRequest,
    _ = Depends(require_signed_request)
):
    """
    Translates raw YouTube subtitle segment to Uzbek
    """
    translated = await TranslationService.translate_to_uzbek(
        text=payload.text,
        source_lang=payload.source_lang
    )
    return TranslationResponse(original=payload.text, translated=translated)
