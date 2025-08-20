import asyncio
import websockets
import json
import ssl

ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

async def test_story():
    uri = "wss://genai-backend-clean-453527276826.us-central1.run.app/ws/testclean"
    async with websockets.connect(uri, ssl=ssl_context) as websocket:
        print("Connected to clean backend!")
        
        # Receive connection message
        msg = await websocket.recv()
        print(f"Server: {msg}")
        
        # Send story request
        request = {"type": "generate_story", "data": "a friendly dragon"}
        await websocket.send(json.dumps(request))
        print(f"Sent: {request}")
        
        # Wait for responses
        try:
            while True:
                msg = await asyncio.wait_for(websocket.recv(), timeout=60)
                print(f"Server: {msg[:100]}...")
                data = json.loads(msg)
                if data.get("type") == "complete":
                    print("Story generation complete!")
                    break
        except asyncio.TimeoutError:
            print("Timeout - no response received")
        except websockets.exceptions.ConnectionClosed:
            print("Connection closed by server")

asyncio.run(test_story())
