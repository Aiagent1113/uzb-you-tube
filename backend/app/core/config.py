from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "UzDub YouTube AI - Security Proxy & Orchestrator"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Secret HMAC Key for Request Signing & Dynamic Contracts
    HMAC_SECRET_KEY: str = "UzDub_Secure_Key2026!@#$"
    
    # Allowed CORS Origins
    CORS_ORIGINS: List[str] = [
        "https://m.youtube.com",
        "https://www.youtube.com",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ]
    
    # Supported Neural Voices (Microsoft Edge TTS)
    VOICE_MADINA: str = "uz-UZ-MadinaNeural"
    VOICE_SARDOR: str = "uz-UZ-SardorNeural"
    
    # Telegram Bot
    TELEGRAM_BOT_TOKEN: str = "YOUR_TELEGRAM_BOT_TOKEN"
    TELEGRAM_BOT_USERNAME: str = "UzDubAI_bot"

    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
