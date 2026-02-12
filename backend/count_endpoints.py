from app.main import app
from fastapi.routing import APIRoute

count = 0
print(f"{'METHOD':<8} {'PATH':<50} {'NAME':<30}")
print("-" * 90)

for route in app.routes:
    if isinstance(route, APIRoute):
        # Filter out built-in docs endpoints if desired, but let's see everything first
        if route.path in ["/openapi.json", "/docs", "/redoc"]:
            continue
        print(f"{list(route.methods)[0]:<8} {route.path:<50} {route.name:<30}")
        count += 1

print("-" * 90)
print(f"Total Operational Endpoints: {count}")
