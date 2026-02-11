#!/usr/bin/env python3
"""
Comprehensive Backend Test Script
Tests all critical endpoints and database functionality
"""
import requests
import json
from typing import Dict, Any

BASE_URL = "http://localhost:8000"

def print_test(name: str, passed: bool, details: str = ""):
    status = "✅ PASS" if passed else "❌ FAIL"
    print(f"{status} - {name}")
    if details:
        print(f"   {details}")
    print()

def test_database_connection():
    """Test database connectivity"""
    try:
        from app.core.database import engine
        from sqlalchemy import text
        conn = engine.connect()
        result = conn.execute(text('SELECT 1'))
        conn.close()
        print_test("Database Connection", True, "PostgreSQL connected successfully")
        return True
    except Exception as e:
        print_test("Database Connection", False, f"Error: {str(e)}")
        return False

def test_login_oauth():
    """Test OAuth2 login (form data)"""
    try:
        response = requests.post(
            f"{BASE_URL}/auth/login",
            data={"username": "alice@example.com", "password": "s3cret123"}
        )
        if response.status_code == 200:
            data = response.json()
            if "access_token" in data:
                print_test("Login (OAuth2 Form)", True, f"Token: {data['access_token'][:20]}...")
                return data["access_token"]
        print_test("Login (OAuth2 Form)", False, f"Status: {response.status_code}, Response: {response.text}")
        return None
    except Exception as e:
        print_test("Login (OAuth2 Form)", False, f"Error: {str(e)}")
        return None

def test_points_balance(token: str):
    """Test points balance endpoint"""
    try:
        response = requests.get(
            f"{BASE_URL}/points/balance",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            data = response.json()
            print_test("Points Balance", True, f"Data: {json.dumps(data, indent=2)}")
            return True
        print_test("Points Balance", False, f"Status: {response.status_code}, Response: {response.text}")
        return False
    except Exception as e:
        print_test("Points Balance", False, f"Error: {str(e)}")
        return False

def test_catalog_items(token: str):
    """Test catalog items endpoint"""
    try:
        response = requests.get(
            f"{BASE_URL}/catalog/items",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            data = response.json()
            print_test("Catalog Items", True, f"Found {len(data.get('data', []))} items")
            return True
        print_test("Catalog Items", False, f"Status: {response.status_code}, Response: {response.text}")
        return False
    except Exception as e:
        print_test("Catalog Items", False, f"Error: {str(e)}")
        return False

def test_recognition_feed(token: str):
    """Test recognition feed endpoint"""
    try:
        response = requests.get(
            f"{BASE_URL}/recognitions/feed",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            data = response.json()
            print_test("Recognition Feed", True, f"Status: {response.status_code}")
            return True
        print_test("Recognition Feed", False, f"Status: {response.status_code}, Response: {response.text}")
        return False
    except Exception as e:
        print_test("Recognition Feed", False, f"Error: {str(e)}")
        return False

def test_leaderboard(token: str):
    """Test leaderboard endpoint"""
    try:
        response = requests.get(
            f"{BASE_URL}/recognitions/leaderboard",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            print_test("Leaderboard", True, f"Status: {response.status_code}")
            return True
        print_test("Leaderboard", False, f"Status: {response.status_code}, Response: {response.text}")
        return False
    except Exception as e:
        print_test("Leaderboard", False, f"Error: {str(e)}")
        return False

def main():
    print("=" * 60)
    print("BACKEND COMPREHENSIVE TEST SUITE")
    print("=" * 60)
    print()
    
    # Test 1: Database
    if not test_database_connection():
        print("⚠️  Database connection failed. Stopping tests.")
        return
    
    # Test 2: Login
    token = test_login_oauth()
    if not token:
        print("⚠️  Login failed. Cannot proceed with authenticated tests.")
        return
    
    # Test 3: Points Balance
    test_points_balance(token)
    
    # Test 4: Catalog
    test_catalog_items(token)
    
    # Test 5: Recognition Feed
    test_recognition_feed(token)
    
    # Test 6: Leaderboard
    test_leaderboard(token)
    
    print("=" * 60)
    print("TEST SUITE COMPLETE")
    print("=" * 60)

if __name__ == "__main__":
    main()
