from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.websocket("/api/log")
async def websocket_log(websocket: WebSocket):
    await websocket.accept()
    print("🔗 FluentD connected")
    try:
        while True:
            data = await websocket.receive_text()
            print(f"[LOG] {data}")
    except Exception:
        print("❌ FluentD disconnected")
    finally:
        await websocket.close()

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=4000)
