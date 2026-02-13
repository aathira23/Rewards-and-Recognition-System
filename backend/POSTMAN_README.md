Postman collection usage — Rewards & Recognition System

Purpose
- Explain how to use the provided Postman collection (`Rewards_Recognition_API.postman_collection.json`) to test role-scoped endpoints safely.

Location
- Collection: backend/Rewards_Recognition_API.postman_collection.json

Quick setup
1. Start the backend server (example):

```bash
cd backend
uvicorn app.main:app --reload --log-level debug
```

2. Open the collection in Postman.
3. Run the four login requests in `1. Authentication` (Login as HR, Manager, Dept Head, Employee). Each login test will store tokens in collection variables:
   - `hr_token`, `manager_token`, `dept_head_token`, `employee_token`.

Role switching (two options)
- Central switch (recommended):
  - The collection has a prerequest script that copies a chosen role token into `access_token`. Set the collection variable `role_selector` to one of: `hr`, `manager`, `dept_head`, `employee`.
  - Example: set `role_selector = hr` to use HR token automatically.
- Per-request override:
  - Use the request Authorization tab and choose `Bearer Token`, then set Token to `{{employee_token}}` or `{{hr_token}}` to test a specific role for that request only.

Important notes (common pitfalls)
- Remove any explicit `Authorization` header in the request `Headers` tab if you use the Authorization tab — duplicate headers can cause confusion.
- Some requests in the collection include a small prerequest script that sets `access_token` to a specific role (to ensure HR-only requests run correctly). If you want to test with a different role, remove or edit that prerequest script for that request or change `role_selector`.
- After sending a request, open Postman Console (View → Show Postman Console) and inspect the actual outgoing `Authorization` header to confirm which token was sent.

Server-side debugging
- I added debug logging in `get_current_user_id` to log the decoded token payload (redacted). To see these logs, start uvicorn with `--log-level debug` as shown above.

RBAC changes you should know
- `POST /points/conversions/{id}/action` is restricted to HR (403 Forbidden for non-HR).
- `POST /points/convert` remains a user-level endpoint (employees can submit requests for themselves).
- `GET /points/conversions` returns the current user's conversions (user-level). There is no dedicated `pending conversions` admin endpoint yet.

Quick curl example
- To test HR-only approve action with an employee token (expect 403):

```bash
curl -i -H "Authorization: Bearer <EMPLOYEE_TOKEN>" \
  -H "Content-Type: application/json" \
  -X POST http://127.0.0.1:8000/points/conversions/123/action \
  -d '{"action":"APPROVE"}'
```

If a request returns success when you expected 403:
- Check Postman Console for the actual `Authorization` header sent.
- Check the request/folder/collection prerequest scripts that may overwrite `access_token`.
- If the token sent is correct (employee) but server still responds success, tell me the endpoint and I will inspect server-side RBAC checks and patch them.

If you want, I can add a short `USAGE` snippet to the root `README.md` as well.
