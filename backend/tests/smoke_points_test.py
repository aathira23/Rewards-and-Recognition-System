from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

paths = [
    "/api/points/balance",
    "/api/points/history",
]

for p in paths:
    resp = client.get(p)
    print(f"{p} -> {resp.status_code}")
    # print body truncated
    text = resp.text
    print(text[:2000])
    print("---\n")
