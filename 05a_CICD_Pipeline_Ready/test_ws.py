import asyncio
import websockets
import json
import ssl

ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

async def test_story():
    uri = "wss://genai-backend-453527276826.us-central1.run.app/ws/test999"
    async with websockets.connect(uri, ssl=ssl_context) as websocket:
        print("Connected!")
        
        # Receive connection message
        msg = await websocket.recv()
        print(f"Server: {msg}")
        
        # Send story request immediately
        request = {"type": "generate_story", "data": "robot"}
        await websocket.send(json.dumps(request))
        print(f"Sent: {request}")
        
        # Keep connection alive and wait for responses
        try:
            while True:
                msg = await asyncio.wait_for(websocket.recv(), timeout=30)
                print(f"Server: {msg}")
        except asyncio.TimeoutError:
            print("Timeout - no response received")
        except websockets.exceptions.ConnectionClosed:
            print("Connection closed by server")

asyncio.run(test_story())
