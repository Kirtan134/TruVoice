import requests

API_KEY = "AIzaSyAKJOGioPTm12v0fmF_3LRk5f4-lgDy1TA"  # Replace with your actual API key
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={API_KEY}"

headers = {
    "Content-Type": "application/json"
}

data = {
    "contents": [{
        "parts": [{
            "text": "Hello, how are you?"
        }]
    }]
}

response = requests.post(url, json=data, headers=headers)

print("Status Code:", response.status_code)
print("Response:", response.json())
