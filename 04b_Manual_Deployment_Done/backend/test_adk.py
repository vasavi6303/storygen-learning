import os
from google.adk.agents import LlmAgent
from google.adk.runners import InMemoryRunner
from google.adk.sessions.in_memory_session_service import InMemorySessionService
from google.genai.types import Content, Part

# Check environment
api_key = os.getenv("GOOGLE_API_KEY")
use_vertexai = os.getenv("GOOGLE_GENAI_USE_VERTEXAI", "FALSE")
print(f"API Key available: {'Yes' if api_key else 'No'}")
print(f"API Key length: {len(api_key) if api_key else 0}")
print(f"Using Vertex AI: {use_vertexai}")

# Create a simple agent
try:
    print("\nCreating LlmAgent...")
    agent = LlmAgent(
        model="gemini-1.5-flash",
        name="test_agent",
        description="Test agent"
    )
    print("✅ Agent created successfully")
    
    # Create runner and session
    print("\nCreating runner and session...")
    runner = InMemoryRunner(app_name="test", agent=agent)
    
    # Test the agent
    import asyncio
    
    async def run_test():
        session = await runner.session_service.create_session(app_name="test", user_id="test_user")
        print(f"✅ Session created: {session.id}")
        
        print("\nTesting agent...")
        content = Content(role="user", parts=[Part(text="Say hello")])
        
        print("Starting agent execution...")
        response = ""
        async for event in runner.run_async(user_id="test_user", session_id=session.id, new_message=content):
            if event.content and event.content.parts:
                for part in event.content.parts:
                    if part.text:
                        response += part.text
                        print(f"Received: {part.text[:50]}...")
        return response
    
    result = asyncio.run(run_test())
    print(f"\n✅ Test successful! Response length: {len(result)}")
    
except Exception as e:
    print(f"\n❌ Error: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
