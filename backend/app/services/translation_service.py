import httpx
from typing import Optional

class TranslationService:
    _cache = {}

    @classmethod
    async def translate_to_uzbek(cls, text: str, source_lang: str = "auto") -> Optional[str]:
        cleaned = text.strip()
        if not cleaned:
            return ""

        if cleaned in cls._cache:
            return cls._cache[cleaned]

        # Use Google GTX client proxy
        url = "https://translate.googleapis.com/translate_a/single"
        params = {
            "client": "gtx",
            "sl": source_lang,
            "tl": "uz",
            "dt": "t",
            "q": cleaned
        }

        async with httpx.AsyncClient(timeout=4.0) as client:
            try:
                response = await client.get(url, params=params)
                if response.status_code == 200:
                    data = response.json()
                    translated = "".join([segment[0] for segment in data[0] if segment[0]])
                    cls._cache[cleaned] = translated
                    return translated
            except Exception as e:
                # Log error and return original
                pass

        return cleaned
