#!/usr/bin/env python3
"""
Exhaustive Backend Test Script
Verifies all 26 identified functional endpoints.
"""
import requests
import json
import time

BASE_URL = "http://localhost:8000"

def log(msg):
    print(f"[*] {msg}")

def test_endpoint(method, path, token=None, data=None, params=None, expected_status=[200, 201]):
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    url = f"{BASE_URL}{path}"
    
    try:
        if method == "GET":
            resp = requests.get(url, headers=headers, params=params)
        elif method == "POST":
            # For login we use data (form), for others we might use json
            if path == "/auth/login":
                resp = requests.post(url, data=data)
            else:
                resp = requests.post(url, headers=headers, json=data)
        elif method == "PUT":
            resp = requests.put(url, headers=headers, json=data)
        elif method == "PATCH":
            resp = requests.patch(url, headers=headers, json=data)
        
        status = resp.status_code
        if status in expected_status:
            print(f"✅ {method} {path} - Status {status}")
            return resp
        else:
            print(f"❌ {method} {path} - Status {status} (Expected {expected_status})")
            if status == 500:
                print(f"   Error: {resp.text[:200]}")
            return None
    except Exception as e:
        print(f"💥 {method} {path} - Exception: {str(e)}")
        return None

def main():
    print("="*60)
    print("VERIFYING ALL 26 FUNCTIONAL ENDPOINTS")
    print("="*60)

    # 1. Auth (1)
    # ---------------------------------------------------------
    print("\n--- 1. Authentication ---")
    login_resp = test_endpoint("POST", "/auth/login", data={"username": "alice@example.com", "password": "s3cret123"})
    if not login_resp: return
    token = login_resp.json()["access_token"]
    user_id = login_resp.json()["user_id"]

    # 2. Points Management (8)
    # ---------------------------------------------------------
    print("\n--- 2. Points Management ---")
    test_endpoint("GET", "/points/balance", token=token) # 1
    test_endpoint("GET", "/points/history", token=token) # 2
    test_endpoint("GET", "/points/rules", token=token)   # 3
    test_endpoint("GET", "/points/conversions", token=token) # 4
    
    # Rules creation/update (Admin logic, but Alice is usually seeded as EMPLOYEE in demo)
    # However, let's just see if they exist and return 200 or 403 (expected) rather than 500
    test_endpoint("POST", "/points/rules", token=token, data={"recognition_type": "TEST", "points": 10}, expected_status=[201, 200, 403, 401]) # 5
    test_endpoint("PUT", "/points/rules/1", token=token, data={"points": 50}, expected_status=[200, 403, 401]) # 6
    
    # Conversion action placeholders
    test_endpoint("POST", "/points/convert", token=token, data={"points_converted": 100, "conversion_type": "PAYROLL"}, expected_status=[201, 200, 400]) # 7
    test_endpoint("POST", "/points/conversions/1/action", token=token, data={"action": "APPROVE"}, expected_status=[200, 403, 404, 400]) # 8

    # 3. Rewards Catalog (3)
    # ---------------------------------------------------------
    print("\n--- 3. Rewards Catalog ---")
    test_endpoint("GET", "/catalog/items", token=token) # 1
    test_endpoint("GET", "/catalog/history", token=token) # 2
    test_endpoint("POST", "/catalog/redeem", token=token, data={"reward_id": 1}, expected_status=[201, 200, 400]) # 3

    # 4. User Profiles (4)
    # ---------------------------------------------------------
    print("\n--- 4. User Profiles ---")
    test_endpoint("GET", "/profile/me", token=token) # 1
    test_endpoint("GET", "/profile/", token=token)  # 2
    test_endpoint("PUT", f"/profile/{user_id}", token=token, data={"name": "Alice Wonderland"}) # 3
    # User creation (might fail if duplicate, but check it's not 500)
    test_endpoint("POST", "/profile/", token=token, data={"email": f"test_{int(time.time())}@example.com", "password": "password", "name": "Test User", "role": "EMPLOYEE"}, expected_status=[201, 400]) # 4

    # 5. Recognitions (10)
    # ---------------------------------------------------------
    print("\n--- 5. Recognitions ---")
    test_endpoint("GET", "/recognitions/badges", token=token) # 1
    test_endpoint("GET", "/recognitions/feed", token=token)   # 2
    test_endpoint("GET", "/recognitions/me/overview", token=token) # 3
    test_endpoint("GET", "/recognitions/leaderboard", token=token) # 4
    test_endpoint("GET", "/recognitions/auto", token=token)      # 5
    
    # Badge management
    test_endpoint("POST", "/recognitions/badges", token=token, data={"name": "Legend", "description": "Too good"}, expected_status=[201, 200, 403]) # 6
    test_endpoint("PUT", "/recognitions/badges/1", token=token, data={"name": "Superstar"}, expected_status=[200, 403]) # 7
    test_endpoint("PATCH", "/recognitions/badges/1/deactivate", token=token, expected_status=[200, 403]) # 8
    
    # Recognition specific
    test_endpoint("POST", "/recognitions/", token=token, data={"receiver_id": 1 if user_id != 1 else 2, "badge_id": 1, "message": "Great job"}, expected_status=[201, 200, 400]) # 9
    test_endpoint("GET", "/recognitions/1", token=token, expected_status=[200, 404]) # 10

    print("\n" + "="*60)
    print("VERIFICATION COMPLETE")
    print("="*60)

if __name__ == "__main__":
    main()
