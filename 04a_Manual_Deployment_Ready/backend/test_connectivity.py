import os
import requests
import socket

print("Testing connectivity from Cloud Run...")

# Test DNS resolution
try:
    ip = socket.gethostbyname("generativelanguage.googleapis.com")
    print(f"✅ DNS resolution works: generativelanguage.googleapis.com -> {ip}")
except Exception as e:
    print(f"❌ DNS resolution failed: {e}")

# Test HTTPS connection
try:
    response = requests.get("https://www.google.com", timeout=5)
    print(f"✅ HTTPS to google.com works: {response.status_code}")
except Exception as e:
    print(f"❌ HTTPS to google.com failed: {e}")

# Test Google AI API endpoint
api_key = os.getenv("GOOGLE_API_KEY", "")
if api_key:
    try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
        response = requests.get(url, timeout=10)
        print(f"✅ Google AI API reachable: {response.status_code}")
        if response.status_code == 200:
            print(f"   Models available: {len(response.json().get('models', []))}")
    except Exception as e:
        print(f"❌ Google AI API failed: {e}")
else:
    print("⚠️ No API key available to test Google AI API")
