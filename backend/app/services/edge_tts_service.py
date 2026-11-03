import asyncio
from typing import AsyncGenerator
import edge_tts
from ..core.config import settings

class EdgeTTSService:
    @staticmethod
    def get_supported_voices():
        return [
            {"id": settings.VOICE_MADINA, "name": "Madina Neural (HD)", "gender": "Female", "lang": "uz-UZ"},
            {"id": settings.VOICE_SARDOR, "name": "Sardor Neural (HD)", "gender": "Male", "lang": "uz-UZ"},
        ]

    @staticmethod
    async def stream_audio(
        text: str,
        voice: str = settings.VOICE_MADINA,
        rate: float = 1.0
    ) -> AsyncGenerator[bytes, None]:
        """
        Streams MP3 audio chunks generated via Microsoft Edge TTS WebSocket.
        """
        if not text or not text.strip():
            return

        # Format rate string: "+0%", "+25%", "-10%"
        rate_percent = int((rate - 1.0) * 100)
        rate_str = f"+{rate_percent}%" if rate_percent >= 0 else f"{rate_percent}%"

        # Validate voice parameter
        chosen_voice = voice if "Neural" in voice else settings.VOICE_MADINA

        communicate = edge_tts.Communicate(
            text=text.strip(),
            voice=chosen_voice,
            rate=rate_str,
            pitch="+0Hz"
        )

        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                yield chunk["data"]
