import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from ....services.edge_tts_service import EdgeTTSService
from ....core.config import settings

router = APIRouter()

@router.websocket("/ws/tts")
async def websocket_tts_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            raw_data = await websocket.receive_text()
            try:
                request_data = json.loads(raw_data)
                text = request_data.get("text", "")
                voice = request_data.get("voice", settings.VOICE_MADINA)
                rate = float(request_data.get("rate", 1.0))

                if not text:
                    continue

                # Notify client that speech synthesis has begun
                await websocket.send_text(json.dumps({"event": "start", "voice": voice}))

                # Stream audio chunks directly as bytes
                async for chunk in EdgeTTSService.stream_audio(text=text, voice=voice, rate=rate):
                    await websocket.send_bytes(chunk)

                # Notify client that synthesis is complete
                await websocket.send_text(json.dumps({"event": "end", "charCount": len(text)}))

            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({"event": "error", "message": "Invalid JSON"}))
            except Exception as e:
                await websocket.send_text(json.dumps({"event": "error", "message": str(e)}))

    except WebSocketDisconnect:
        pass
