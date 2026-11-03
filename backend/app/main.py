from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .api.v1.endpoints import auth, translate, tts_ws, license

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="High-Security Orchestrator and Edge TTS Proxy for UzDub YouTube AI"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Connect API v1 Routers
app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["Security & Auth"])
app.include_router(translate.router, prefix=f"{settings.API_V1_STR}/translate", tags=["Translation"])
app.include_router(license.router, prefix=f"{settings.API_V1_STR}/license", tags=["Licensing & Telegram"])
app.include_router(tts_ws.router, prefix=f"{settings.API_V1_STR}", tags=["Real-time TTS WebSocket"])

@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
