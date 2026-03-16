# []{#anchor}Rewards & Recognition System --- User Service Integration Design[]{#anchor-1}

## 1. Integration Principles

The R&R Service follows a microservices pattern where all user identity
and profile data are owned exclusively by the centralized **User
Service**.

## []{#anchor-1}2. Caching Strategy

### []{#anchor-1}Cache 1 --- Authentication Cache (Token → Identity)

Used to identify **who is making the current request**.

  --------- -------------------------------------------------------------------------------
  Key       Bearer token string
  Value     Authenticated user's identity and role (user_id, role, org_id, dept_id, etc.)
  TTL       3 hours
  Scope     Per active user session
  Trigger   Every inbound API request --- checked before anything else
  --------- -------------------------------------------------------------------------------

Flow:

Inbound request with Bearer token\
│\
▼\
Token in cache?\
├── HIT → return identity instantly\
└── MISS → validate with User Service → cache result → return identity

After the first request of the day, every subsequent request from the
same user is resolved instantly from memory.

### []{#anchor-2}Cache 2 --- User Profile Cache (user_id → Profile)

Used to enrich R&R data with human-readable names, departments, and
profile info when serving responses.

+---------+-----------------------------------------------------------+
| Key     | user_id (integer)                                         |
+---------+-----------------------------------------------------------+
| Value   | { first_name,last_name,email,role,\                       |
|         | designati                                                 |
|         | on,dept_id,dept_name,emp_id,img_path,dob,date_of_joining, |
|         |                                                           |
|         | is_active}                                                |
+---------+-----------------------------------------------------------+
| TTL     | 24 hour (default) --- role changes and updates propagate  |
|         | within the hour                                           |
+---------+-----------------------------------------------------------+
| Scope   | Per user, shared across all requests                      |
+---------+-----------------------------------------------------------+
| Trigger | Cache miss on any lookup for a specific user_id           |
+---------+-----------------------------------------------------------+

Flow:

Response needs to display \"Alice Johnson\" for user_id 42\
│\
▼\
user_id 42 in Cache 2?\
├── HIT (not expired) → use cached profile instantly\
└── MISS (new or expired) → fetch from User Service → cache with TTL →
return

**Key design choice --- store IDs, enrich on read:** R&R records store
only user_id at write time. Display names are resolved at read time by
looking up Cache 2. This keeps writes simple and ensures names always
reflect the User Service's current data (within TTL)

### []{#anchor-3}Cache TTL Guidelines by Feature

  ------------------------------------- --------------------------- -------------------------------------
  Auth / current user identity          \_\_\_\_\_\_\_              Token lifespan
  Individual user profile enrichment    1 hour                      User details change rarely
  Manager list (HR wallet allocation)   4 hours                     Role changes are infrequent
  Picker / search results               5 minutes                   Improve search performance
  Leaderboard                           15 minutes                  Keep rankings updated recalculation
  Celebrations (daily job)              24 hours                    Generated once daily
  ------------------------------------- --------------------------- -------------------------------------

## []{#anchor-3}3. Retrieval Patterns

### []{#anchor-3}Pattern A --- Single User Lookup

Used when enriching a known user_id with display details.

Step 1: Check Cache 2 for user_id\
Step 2: On miss → fetch from User Service by ID\
Step 3: Store in Cache 2 with TTL\
Step 4: Return profile

*Used by:* points history, recognition sent/received, approval chain
display, nomination details.

### []{#anchor-3}Pattern B --- Batch Lookup

Used when a list of records contains multiple user_id values that need
enrichment.

Step 1: Collect all user_ids from the result set\
Step 2: Check Cache 2 for each → split into HIT list and MISS list\
Step 3: For MISS list → fetch all at once from User Service (batch/list
call)\
Step 4: Store each fetched profile in Cache 2\
Step 5: Merge cached + fetched profiles into result set

*Used by:* recognition feed, leaderboard, nominations list, reports, HR
pending conversions.

**Benefit:** One User Service call for N missing users instead of N
separate calls.

### []{#anchor-3}Pattern C --- Paginated List (Pickers)

Used when the UI needs a searchable list of people to select from.

Step 1: Check response-level cache for this picker query\
Step 2: On miss → call User Service with pagination (skip, limit) and
optional filters\
Step 3: Cache the entire response with a short TTL\
Step 4: Return the list to the client

*Used by:* recipient picker (send eCard), nominee picker, manager picker
(HR wallet), employee picker (manager reward).

**Filter examples:** role = MANAGER, dept_id = X, org_id = Y, excluding
self.

### []{#anchor-3}Pattern D --- My Profile

The current user's own profile is always served from **Cache 1** (the
auth cache). The identity object returned during token validation
already contains all profile fields needed for the "My Profile" screen.
No additional User Service call is made.

## []{#anchor-3}4. Feature-by-Feature Integration

### 4.1 Recognition / eCards

  ---------------------- ---------------------- -------------------- -----------------------------------------------------
  Recipient picker       C --- Paginated list   Short TTL (5 min)    Filterable by name, excludes self
  Send eCard             ---                    Cache 1 only         Sender from auth cache, receiver_id in request body
  Recognition feed       B --- Batch lookup     TTL (1h)             Enrich all sender_id + receiver_id in feed
  Sent / received list   A --- Single lookup    TTL (1h)             Resolve one name per record on read
  Leaderboard            B --- Batch lookup     Short TTL (15 min)   Aggregate by user_id in DB first, then enrich top-N
  Personal overview      ---                    Cache 1 only         Own stats from R&R DB
  ---------------------- ---------------------- -------------------- -----------------------------------------------------

### 4.2 Awards & Nominations

  ------------------------ ---------------------- ------------------- --------------------------------------------
  Nominee picker           C --- Paginated list   Short TTL (5 min)   Filtered by eligibility rules (role, dept)
  Submit nomination        ---                    Cache 1 only        nominee_id in request body
  Nominations list         B --- Batch lookup     TTL (1h)            Enrich nominator + nominee names
  Approval chain display   A --- Single lookup    TTL (1h)            One lookup per approver level
  Approve / reject         ---                    Cache 1 only        Approver identity from auth cache
  My approvals             ---                    Cache 1 only        Own records from R&R DB
  ------------------------ ---------------------- ------------------- --------------------------------------------

### 4.3 Manager Wallet & Budget Allocation

  ---------------------------------- ---------------------- ------------------- --------------------------------------------------
  Pick manager to allocate to (HR)   C --- Paginated list   Long TTL (4h)       Filtered by role = MANAGER
  Allocate budget                    ---                    Cache 1 only        manager_id in request body
  Bulk allocate by department        C --- Paginated list   Long TTL (4h)       Filtered by role = MANAGER AND dept_id = X
  Pick employee to reward            C --- Paginated list   Short TTL (5 min)   Manager's dept_id from auth cache used as filter
  Reward employee                    ---                    Cache 1 only        employee_id in request body
  View wallet balance                ---                    Cache 1 only        Own wallet from R&R DB
  ---------------------------------- ---------------------- ------------------- --------------------------------------------------

### 4.4 Points & Conversions

  ------------------------------ -------------------- -------------- ----------------------------------------
  Points balance / history       ---                  Cache 1 only   Own ledger from R&R DB
  Request conversion             ---                  Cache 1 only   Own wallet data
  HR: pending conversions list   B --- Batch lookup   TTL (1h)       Enrich requester names from Cache 2
  HR: approve / reject           ---                  Cache 1 only   Role from auth cache, record in R&R DB
  ------------------------------ -------------------- -------------- ----------------------------------------

### 4.5 Celebrations

  ---------------------------------------------- ----------------------------------------- -------------------------------------------------------------------
  Upcoming birthdays / anniversaries             C --- Paginated list (filtered by date)   Fetched by daily scheduled job, cached for the day
  Process today's celebrations (scheduled job)   C --- Paginated list                      Filter by dob / date_of_joining matching today, then award points
  Celebration history                            B --- Batch lookup                        R&R DB records enriched with names from Cache 2
  ---------------------------------------------- ----------------------------------------- -------------------------------------------------------------------

### 4.6 Analytics & Reports (HR)

All reports follow the pattern: **R&R DB owns all numbers, Cache 2
enriches display names.**

  ----------------------------- -------------------- ----------------------------------------------------
  Awards given                  B --- Batch lookup   R&R DB aggregated, Cache 2 for names
  Payroll / conversion report   B --- Batch lookup   Cache 2 for name + employee ID enrichment
  Redemptions report            B --- Batch lookup   Cache 2 for employee names
  Wallet / budget utilization   B --- Batch lookup   Cache 2 for manager names
  Analytics dashboard           ---                  Cache 1 for role scoping, R&R aggregated data only
  ----------------------------- -------------------- ----------------------------------------------------

### 4.7 Profile & User Search

  ----------------------- ---------------------- -----------------------------------------------------------
  My profile              D --- Auth cache       UserContext from Cache 1 is the profile --- no extra call
  User listing / search   C --- Paginated list   users_map search by name, filtered by org
  ----------------------- ---------------------- -----------------------------------------------------------

### 4.8 Features with No User Service Dependency

These features operate entirely on R&R's own data:

  ------------------------------ ------------------------------
  Rewards catalog / redemption   Product data lives in R&R DB
  Points policy management       Configuration in R&R DB
  Feature flags                  Configuration in R&R DB
  Inbox / notifications          Own records in R&R DB
  Admin / system config          Configuration in R&R DB
  ------------------------------ ------------------------------

## []{#anchor-3}5. Service Interaction Flows

### []{#anchor-3}Flow A --- Dashboard Load (Points Balance + Recognition Feed)

1\. Client sends: GET /points/balance AND GET /recognitions/feed\
\
2. R&R queries its own DB:\
 - wallets table → balance\
 - recognitions table → recent feed items (returns sender_id,
receiver_id)\
\
3. Collect all unique user_ids from feed items\
\
4. Batch lookup (Pattern B):\
 - Check Cache 2 for each user_id\
 - Fetch any misses from User Service in one call\
 - Store results in Cache 2\
\
5. Merge names + profile pictures into feed items\
\
6. Return enriched response to client

### []{#anchor-4}Flow B --- Send eCard (Recipient Search + Submit)

Search phase:\
1. Client types name in \"To:\" field\
2. Check response-level cache for this search query\
3. On miss: call User Service with pagination, cache response (5 min
TTL)\
4. Return name + dept + photo suggestions to client\
\
Submit phase:\
1. Client submits: { receiver_id: 42, badge_id: 3, message: \"\...\" }\
2. Sender identity from Cache 1 (no User Service call)\
3. Save recognition to R&R DB with sender_id + receiver_id (no names
stored)\
4. Return success

### []{#anchor-5}Flow C --- Leaderboard

1\. Client sends: GET /analytics/leaderboard\
\
2. R&R runs aggregation query:\
SELECT user_id, SUM(points) FROM ledger\
GROUP BY user_id ORDER BY SUM(points) DESC LIMIT 10\
\
3. Take the top-10 user_ids\
\
4. Batch lookup (Pattern B):\
 - Check Cache 2 for each user_id\
 - Fetch misses from User Service in one batch call\
\
5. Merge names + departments into leaderboard rows\
\
6. Return enriched leaderboard (cached at response level, 15 min TTL)

## 
