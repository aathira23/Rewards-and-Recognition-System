# Rewards & Recognition System — User Service Integration Approach

**Prepared by:** R&R Backend Team
**Date:** 13 March 2026
**Status:** Pending Architect Review
**Reference Implementation:** Training Service (`training-service-dev`)

---

## 1. Objective

Integrate the R&R backend with the centralized **User Service** for all user identity, authentication, and profile data — while ensuring the R&R system operates with minimal dependency on User Service at runtime.

The goal is to call User Service as infrequently as possible, using an in-memory caching strategy that keeps the system fast, resilient, and independent of User Service availability during normal operation.

---

## 2. Core Architecture — Two-Cache Strategy

The entire integration is built on two in-memory caches. Together they eliminate almost all runtime calls to User Service.

---

### Cache 1 — TTL Authentication Cache

| Property | Detail |
|---|---|
| **Type** | `cachetools.TTLCache` (Python in-memory dictionary) |
| **Key** | Bearer token string |
| **Value** | Full `UserContext` object for the authenticated user |
| **TTL** | 24 hours |
| **Max size** | 20,000 entries |
| **Scope** | Per-user — each user has their own entry |
| **Purpose** | Identifies who is making the current request |

**How it works:**

```
Request arrives with Authorization: Bearer <token>
        │
        ▼
Is token in Cache 1?
        ├── YES (cache HIT)  → return UserContext instantly — NO User Service call
        └── NO  (cache MISS) → call User Service once → store in cache → return UserContext
```

**What UserContext contains:**
`user_id`, `email`, `first_name`, `last_name`, `role`, `org_id`, `department_id`, `department_name`, `emp_id`, `designation`, `img_path`, `dob`

After the first request of the day, every subsequent request from the same user is served entirely from memory. User Service sees at most one call per user per 24 hours.

---

### Cache 2 — Users Hash Map (Lazy-Loaded)

| Property | Detail |
|---|---|
| **Type** | Python `dict` (in-memory hash map) |
| **Key** | `user_id` (integer) |
| **Value** | User profile: `first_name`, `last_name`, `email`, `role`, `dept_id`, `dept_name`, `img_path`, `emp_id`, `dob`, `date_of_joining` |
| **Scope** | **Shared across all users and all requests** — one single map for the entire application |
| **Purpose** | Resolves any user's details by ID in O(1) without any external call |
| **Load strategy** | **Lazy — populated on first call to an endpoint that needs it, not at startup** |

**How it works:**

```
Specific endpoint is hit for the first time (e.g. recipient picker, leaderboard, reports)
        │
        ▼
Is users_map populated?
        ├── YES (already loaded) → serve from map instantly — NO User Service call
        └── NO  (first hit)      → call User Service once (paginated) → populate map → serve
                                          │
                                          ▼
                            users_map = {
                                1: { first_name: "John", role: "MANAGER",  dept_id: 3 },
                                2: { first_name: "Sara", role: "EMPLOYEE", dept_id: 5 },
                                ... (all org users, loaded once)
                            }
                                          │
                                          ▼
                            All subsequent requests from all users read from this map
                            Background task refreshes the map periodically
```

**Endpoints that trigger the lazy load (first hit only):**

| Endpoint / Feature | Why Cache 2 is needed |
|---|---|
| Recipient picker (send eCard) | Needs full user list to display |
| Nominee picker | Needs user list filtered by role/dept |
| Manager picker (HR wallet allocation) | Needs users filtered by `role = MANAGER` |
| Employee picker (manager reward) | Needs users filtered by dept |
| User listing / search | Needs full org user list |
| Leaderboard | Needs names to enrich top-N results |
| Celebrations (upcoming birthdays/anniversaries) | Needs `dob` / `date_of_joining` for all users |
| Reports (HR) | Needs names/emp_id to enrich report rows |
| Recognition feed / sent / received lists | Needs names to enrich records |

All of these call the same shared helper `get_users_map()`. Whichever endpoint is hit first triggers the single load. Every endpoint after that hits the already-populated map.

**Memory footprint:** ~200 bytes per user. 700 users ≈ 140 KB. Negligible.

**Lookup is O(1):**
```python
users_map[42]  →  { first_name: "John", role: "MANAGER", ... }  # instant
```

---

## 3. When User Service is Actually Called

With this two-cache strategy, User Service is called in exactly **four situations**:

| Trigger | User Service Call | Frequency |
|---|---|---|
| **User's first request** (Cache 1 MISS) | `POST /auth/token/get_user_details` | Once per user per 24 hours |
| **First hit of any Cache 2 endpoint** (lazy load) | `GET /users?comp_id=X` (paginated) | Once — whichever Cache 2 endpoint is hit first |
| **Background refresh** (Cache 2 refresh) | `GET /users?comp_id=X` (paginated) | Periodically, catches new joiners |
| **Fallback** (user_id missing in Cache 2) | `GET /users/{id}` | Rare edge case only |

**Everything else — zero User Service calls.** All runtime reads go through Cache 1 or Cache 2.

> **Why lazy loading over startup loading?**
> Startup loading creates a hard dependency on User Service being available when the R&R server starts. With lazy loading, the R&R server starts independently. The user map is built on the first real request that needs it — no startup delay, no startup failure risk.

---

## 4. User Service Endpoints Used

### 4.1 Token Validation (Cache 1)

| | |
|---|---|
| **Endpoint** | `POST /python/api/v1/auth/token/get_user_details` |
| **When** | Cache 1 MISS only (first request per user per 24h) |
| **Request** | `{ "token": "<bearer_token>" }` with `Authorization: Bearer <token>` header |
| **Response** | `{ "status_code": 200, "response_data": { id, email, first_name, last_name, role_name, comp_id, bu_id, bu_name, emp_id, desig_name, img_path, dob, ... } }` |

### 4.2 All Users List (Cache 2)

| | |
|---|---|
| **Endpoint** | `GET /python/api/v1/users?comp_id=X&skip=0&limit=200` |
| **When** | Server startup + background refresh only |
| **Purpose** | Populate the shared users hash map |

### 4.3 Fallback Single User

| | |
|---|---|
| **Endpoint** | `GET /python/api/v1/users/{id}` |
| **When** | user_id not found in Cache 2 (new joiner not yet refreshed) |
| **Action** | Fetch, return response, and insert into Cache 2 |

---

## 5. Feature-by-Feature Cache Usage

### 5.1 Recognition Page

| Scenario | Cache 1 | Cache 2 | Notes |
|---|---|---|---|
| Recipient picker (who to send eCard to) | — | ✅ | `users_map.values()` filtered by `org_id`, excludes self |
| Send eCard (action) | ✅ | — | Sender from Cache 1, `receiver_id` in request body |
| Sent recognitions list | — | ✅ | `users_map[receiver_id]` for receiver name + pic on read |
| Received recognitions list | — | ✅ | `users_map[sender_id]` for sender name + pic on read |
| Recognition feed (all org) | ✅ | ✅ | Cache 1 for current user scope, Cache 2 for all sender/receiver names |
| Personal overview (my stats) | ✅ | — | Own aggregated data from R&R DB |
| Leaderboard | ✅ | ✅ | Cache 1 for org scoping, Cache 2 to enrich top-N user names |

### 5.2 Points Page

| Scenario | Cache 1 | Cache 2 | Notes |
|---|---|---|---|
| Points summary card | ✅ | — | Own wallet from R&R DB |
| Points history | ✅ | — | Own ledger from R&R DB |
| Request points conversion | ✅ | — | Own wallet, action stored in R&R DB |
| View my conversion requests | ✅ | — | Own data from R&R DB |
| HR: view pending conversions | ✅ | ✅ | Cache 2 for requester names in the list |
| HR: approve/reject conversion | ✅ | — | HR role from Cache 1, record in R&R DB |

### 5.3 Awards / Nominations Page

| Scenario | Cache 1 | Cache 2 | Notes |
|---|---|---|---|
| Nominee picker | ✅ | ✅ | Cache 1 for nominator role/dept, Cache 2 for eligible nominee list |
| Submit nomination (action) | ✅ | — | Nominator from Cache 1, `nominee_id` in request body |
| View nominations list | ✅ | ✅ | Cache 2 for nominator + nominee names in the list |
| Approve / reject nomination | ✅ | — | Approver role from Cache 1, record in R&R DB |
| Approval chain status | — | ✅ | `users_map[approver_id]` for each approval level |
| My approvals history | ✅ | — | Own records from R&R DB |

### 5.4 Manager Wallet Page

| Scenario | Cache 1 | Cache 2 | Notes |
|---|---|---|---|
| View wallet balance | ✅ | — | Own wallet from R&R DB |
| Pick a manager to allocate to (HR) | — | ✅ | Filter `users_map` where `role = MANAGER` |
| Allocate budget (action) | ✅ | — | HR from Cache 1, `manager_id` in request body |
| Bulk allocate by department | — | ✅ | Filter `users_map` where `role = MANAGER AND dept_id = X` |
| Pick employee to reward | ✅ | ✅ | Cache 1 for manager's dept, Cache 2 for employee list in that dept |
| Reward employee (action) | ✅ | — | Manager from Cache 1, `employee_id` in request body |

### 5.5 Rewards Store / Catalog Page

| Scenario | Cache 1 | Cache 2 | Notes |
|---|---|---|---|
| Browse catalog items | — | — | Public endpoint, no auth. R&R DB only |
| Add / update catalog item (HR) | ✅ | — | HR role check from Cache 1, config stored in R&R DB |
| Redeem a reward | ✅ | — | User from Cache 1, `item_id` in request body |
| Redemption history | ✅ | — | Own records from R&R DB |

### 5.6 Points Conversion Page

*(Already covered in 5.2 — Points Page)*

### 5.7 Celebrations Page

| Scenario | Cache 1 | Cache 2 | Notes |
|---|---|---|---|
| Upcoming birthdays / anniversaries | — | ✅ | Filter `users_map` by `dob` / `date_of_joining` matching today ± N days |
| Celebration history | ✅ | ✅ | Own records in R&R DB, Cache 2 for display names |
| Process today's celebrations (job) | ✅ | ✅ | Cache 2 to find today's matches, award points in R&R DB |

> **Open Question:** Does `GET /users` from User Service return `dob` and `date_of_joining`? These fields are required in Cache 2 for the celebrations feature to work without any external calls. Needs confirmation before implementation.

### 5.8 Reports Page (HR)

All reports follow the same pattern: **R&R DB owns all numbers, Cache 2 enriches display names**.

| Scenario | Cache 1 | Cache 2 | Notes |
|---|---|---|---|
| Awards given report | ✅ | ✅ | R&R DB for data, Cache 2 for sender/receiver names |
| Payroll report | ✅ | ✅ | R&R DB for conversion amounts, Cache 2 for `emp_id` + name |
| Redemptions report | ✅ | ✅ | R&R DB for redemption data, Cache 2 for employee names |
| Wallet utilization report | ✅ | ✅ | R&R DB for wallet data, Cache 2 for manager names |
| Budget allocation report | ✅ | ✅ | R&R DB for allocation data, Cache 2 for manager names |
| Analytics dashboard | ✅ | — | R&R aggregated data, Cache 1 for role-based scoping |

### 5.9 Profile Page

| Scenario | Cache 1 | Cache 2 | Notes |
|---|---|---|---|
| My profile | ✅ | — | `UserContext` from Cache 1 **is** the profile — no DB lookup needed |
| User listing / search | — | ✅ | Search `users_map.values()` by name, filtered by org |

### 5.10 Inbox / Notifications

| Scenario | Cache 1 | Cache 2 | Notes |
|---|---|---|---|
| View notifications | ✅ | — | Own data from R&R DB |
| Unread count | ✅ | — | Own data from R&R DB |
| Mark as read | ✅ | — | Own data from R&R DB |
| Send expiry reminders (HR job) | ✅ | ✅ | Cache 2 for user emails to send reminders to |

### 5.11 Admin / Config Pages

All admin pages follow the same simple pattern — role check from Cache 1, configuration data from R&R DB. No user lookups needed.

| Pages | Cache 1 | Cache 2 |
|---|---|---|
| System config, badges, award types, points rules, departments, email logs, feature flags | ✅ | — |

---

## 6. What Gets Removed After Integration

| Current | After Integration |
|---|---|
| Local login endpoint (`POST /api/v1/auth/login`) | Removed — login handled entirely by User Service + Azure AD |
| Local JWT creation and signing (HS256) | Removed — tokens issued by User Service (RS256) |
| bcrypt password hashing | Removed — passwords managed by Azure AD |
| `password` column in `users` table | Removed (migration required) |
| `SECRET_KEY` config | Removed |

---

## 7. What Changes in the Backend Code

| File | Change |
|---|---|
| `app/core/dependencies.py` | Replace `get_current_user()` — instead of decoding local JWT, validate token via User Service (Cache 1) |
| `app/core/config.py` | Add `USER_SERVICE_BASE_URL`, `GET_USER_DETAILS_URL`, `GET_USERS_URL` |
| `app/core/security.py` | Remove local JWT logic |
| `app/services/user_service_client.py` | **New file** — HTTP client for User Service calls |
| `app/services/users_cache.py` | **New file** — Cache 2 (users hash map): lazy load on first call to `get_users_map()`, background refresh, lookup helper, fallback handler |
| `app/schemas/user_context.py` | **New file** — `UserContext` Pydantic schema |
| `app/main.py` | Add background refresh task only (no startup load — lazy) |
| All routers | **No change** — they already use `Depends(get_current_user)` |

---

## 8. Migration Phases

| Phase | Work | Risk |
|---|---|---|
| **Phase 1** | Add `user_service_client.py`, `users_cache.py`, `user_context.py`. Add new config. Add dependencies. Feature-flag both old and new auth paths. | Zero — old auth still works |
| **Phase 2** | Switch all routers to new `get_current_user()`. Validate with testing. | Low — routers unchanged, only dependency swapped |
| **Phase 3** | Remove old login endpoint, password hashing, local JWT logic. Run DB migration to drop `password` column. | Low — only after Phase 2 is validated |
| **Phase 4** | Add R&R to KrakenD gateway config for rate limiting, CORS, and header passthrough. | Infra — separate task |

---

## 9. Open Questions for Architect Review

| # | Question | Impact |
|---|---|---|
| 1 | Does `GET /python/api/v1/users` return `dob` and `date_of_joining`? | Required for celebrations feature to work off Cache 2 |
| 2 | What are the exact `role_name` values returned by User Service? | Required for role mapping in `get_current_user()` |
| 3 | Does User Service provide a manager hierarchy (`manager_id`)? | Required for manager-scoped approval workflows |
| 4 | Will R&R be added to the existing KrakenD gateway? | Affects routing, rate limiting, and CORS config |
| 5 | Should R&R keep a local auth fallback for development/testing environments? | Affects Phase 3 timeline |
| 6 | Are `bu_id`/`bu_name` from User Service the same as R&R's departments, or do they need mapping? | Affects department management feature |

---

*This document is pending architect review and approval. Implementation begins after Phase 1 approval.*
