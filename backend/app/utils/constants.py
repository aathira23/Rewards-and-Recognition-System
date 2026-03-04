"""
Application constants.
"""

# Points and rewards
DEFAULT_POINTS_EXPIRY_DAYS = 365
MIN_CONVERSION_POINTS = 100

# Pagination
DEFAULT_PAGE_SIZE = 6
MAX_PAGE_SIZE = 100

# Notifications
NOTIFICATION_RETENTION_DAYS = 90

# Celebrations
CELEBRATION_RETRY_MAX_ATTEMPTS = 3

# Messages
# Success Messages
SUCCESS_USER_FETCHED = "Fetched current user"
SUCCESS_USERS_LIST_FETCHED = "User list fetched"
SUCCESS_USER_CREATED = "User created"
SUCCESS_USER_UPDATED = "User updated"

SUCCESS_CATALOG_RETRIEVED = "Catalog retrieved successfully"
SUCCESS_STORE_ITEM_CREATED = "Store item created successfully"
SUCCESS_STORE_ITEM_UPDATED = "Store item updated successfully"
SUCCESS_REDEMPTION_SUCCESSFUL = "Redemption successful"
SUCCESS_HISTORY_RETRIEVED = "History retrieved successfully"

SUCCESS_WALLET_RETRIEVED = "Manager wallet retrieved"
SUCCESS_ALLOCATED_POINTS_TO_MANAGER = "Allocated {} points to manager"
SUCCESS_REWARD_SUCCESSFUL = "Successfully rewarded employee with {} points"
SUCCESS_BULK_ALLOCATE_SUCCESSFUL = "Successfully allocated points to {} wallets"

SUCCESS_NOMINATION_SUCCESSFUL = "Nomination successful"
SUCCESS_NOMINATIONS_FETCHED = "Nominations fetched"
SUCCESS_AWARD_TYPES_FETCHED = "Award types fetched"
SUCCESS_AWARD_TYPE_CREATED = "Award type created"
SUCCESS_AWARD_TYPE_UPDATED = "Award type updated"
SUCCESS_NO_APPROVAL_HISTORY = "No approval history for employees"
SUCCESS_APPROVAL_HISTORY_FETCHED = "Approval history fetched"
SUCCESS_NOMINATION_DETAILS_FETCHED = "Nomination details fetched"
SUCCESS_NOMINATION_APPROVED = "Nomination approved"
SUCCESS_NOMINATION_REJECTED = "Nomination rejected"
SUCCESS_APPROVAL_STATUS_RETRIEVED = "Approval status retrieved"

SUCCESS_CELEBRATIONS_FETCHED = "Upcoming celebrations fetched"
SUCCESS_CELEBRATION_HISTORY_FETCHED = "Celebration history fetched"
SUCCESS_CELEBRATIONS_PROCESSED = "Processed {} birthdays and {} anniversaries"

SUCCESS_CONFIGS_RETRIEVED = "Configurations retrieved"
SUCCESS_CONFIG_UPDATED = "Config '{}' updated"

SUCCESS_DEPARTMENTS_RETRIEVED = "Departments retrieved"
SUCCESS_DEPARTMENT_CREATED = "Department created successfully"
SUCCESS_DEPARTMENT_UPDATED = "Department updated successfully"
SUCCESS_DEPARTMENT_DELETED = "Department deleted successfully"

SUCCESS_NOTIFICATIONS_RETRIEVED = "Notifications retrieved"
SUCCESS_UNREAD_COUNT_RETRIEVED = "Unread count retrieved"
SUCCESS_ALL_NOTIFICATIONS_MARKED_READ = "All notifications marked as read"
SUCCESS_NOTIFICATION_MARKED_READ = "Notification marked as read"
SUCCESS_EXPIRY_REMINDERS_SENT = "Successfully sent {} expiry reminders."

SUCCESS_POINTS_BALANCE_FETCHED = "Balance fetched"
SUCCESS_POINTS_HISTORY_FETCHED = "Points history fetched"
SUCCESS_CONVERSION_REQUESTED = "Conversion request submitted"
SUCCESS_CONVERSION_APPROVED = "Request approved and points deducted"
SUCCESS_CONVERSION_REJECTED = "Request rejected"
SUCCESS_POLICIES_RETRIEVED = "Policies retrieved"
SUCCESS_POINT_RULE_CREATED = "Rule created successfully"
SUCCESS_POINT_RULE_UPDATED = "Rule updated successfully"

SUCCESS_RECOGNITION_SENT = "Recognition sent successfully"
SUCCESS_FEED_RETRIEVED = "Feed retrieved"
SUCCESS_OVERVIEW_RETRIEVED = "Overview retrieved"
SUCCESS_LEADERBOARD_RETRIEVED = "Leaderboard retrieved"
SUCCESS_BADGE_CREATED = "Badge created"
SUCCESS_BADGE_UPDATED = "Badge updated"
SUCCESS_BADGES_RETRIEVED = "Badges retrieved"
SUCCESS_RECOGNITION_FOUND = "Recognition found"

SUCCESS_RECOGNITION_REPORT_GENERATED = "Recognition report generated"
SUCCESS_REDEMPTION_REPORT_GENERATED = "Redemption report generated"
SUCCESS_WALLET_REPORT_GENERATED = "Wallet utilization report generated"
SUCCESS_EXPIRY_FORECAST_GENERATED = "Points expiry forecast for next {} days generated"
SUCCESS_PAYROLL_REPORT_GENERATED = "Payroll report for {} generated"

SUCCESS_METRICS_RETRIEVED = "Analytics metrics retrieved successfully"
SUCCESS_LOGIN = "Login successful"
SUCCESS_FEATURE_FLAGS_RETRIEVED = "Feature flags retrieved"
INFO_CONVERSION_FEATURE_DISABLED = "Conversion feature is disabled"

# Email notification messages
SUCCESS_EMAIL_TEMPLATES_RETRIEVED = "Email templates retrieved"
SUCCESS_EMAIL_TEMPLATE_RETRIEVED = "Template retrieved"
SUCCESS_EMAIL_TEMPLATE_CREATED = "Email template created"
SUCCESS_EMAIL_TEMPLATE_UPDATED = "Template updated"
SUCCESS_EMAIL_LOGS_RETRIEVED = "Email logs retrieved"
SUCCESS_TEST_EMAIL_DISPATCHED = "Test email dispatched ({})"
ERROR_EMAIL_TEMPLATE_NOT_FOUND = "Template not found"
ERROR_EMAIL_TEMPLATE_EXISTS = "Template with this key already exists"
ERROR_EMAIL_TEMPLATE_INACTIVE = "Template not found or inactive"

# Error Messages
ERROR_ONLY_HR_ADMIN_CREATE_USER = "Only HR/Admin users can create new users"
ERROR_UNAUTHORIZED_USER_UPDATE = "You do not have permission to update this user"

ERROR_ONLY_HR_CREATE_STORE_ITEM = "Only HR can create store items"
ERROR_ONLY_HR_UPDATE_STORE_ITEM = "Only HR can update store items"

ERROR_UNAUTHORIZED_WALLET_VIEW = "Only managers, dept heads, or HR/Admin may view manager wallets"
ERROR_ONLY_HR_ADMIN_ALLOCATE_BUDGET = "Only HR/Admin can allocate budget"
ERROR_UNAUTHORIZED_REWARD = "You do not have permission to reward employees from a budget"
ERROR_ONLY_HR_ADMIN_BULK_ALLOCATE = "Only HR/Admin can bulk allocate budget"

ERROR_ONLY_HR_ADMIN_CREATE_AWARD_TYPE = "Only HR/Admin can create award types"
ERROR_ONLY_HR_ADMIN_UPDATE_AWARD_TYPE = "Only HR/Admin can update award types"
ERROR_AWARD_TYPE_NOT_FOUND = "Award type not found"
ERROR_NOMINATION_NOT_FOUND = "Nomination not found"
ERROR_UNAUTHORIZED_NOMINATION_VIEW = "Not authorized to view this nomination"
ERROR_EMPLOYEES_CANNOT_APPROVE = "Employees cannot approve nominations"
ERROR_INVALID_NOMINATION_ACTION = "Invalid action. Must be 'APPROVE' or 'REJECT'."

ERROR_ONLY_HR_ADMIN_PROCESS_CELEBRATIONS = "Only HR/Admin can trigger celebration processing"

ERROR_ACCESS_DENIED = "Access denied"
ERROR_CONFIG_RETRIEVAL_FAILED = "Config retrieval failed: {}"

ERROR_ONLY_HR_ADMIN_CREATE_DEPT = "Access denied. Only HR/Admin can create departments."
ERROR_ONLY_HR_ADMIN_UPDATE_DEPT = "Access denied. Only HR/Admin can update departments."
ERROR_ONLY_HR_ADMIN_DELETE_DEPT = "Access denied. Only HR/Admin can delete departments."
ERROR_DEPARTMENT_NOT_FOUND = "Department not found"

ERROR_NOTIFICATION_NOT_FOUND = "Notification not found or access denied"
ERROR_INVALID_MARK_READ_PARAMS = "Provide either notification_id or mark_all=true"
ERROR_ONLY_HR_TRIGGER_REMINDERS = "Access denied. Only HR can trigger reminders."

ERROR_ONLY_HR_ADMIN_VIEW_PENDING_CONVERSIONS = "Only HR/Admin can view pending conversion requests"
ERROR_ONLY_HR_ADMIN_ACTION_CONVERSION = "Only HR/Admin users can approve or reject conversion requests"
ERROR_INVALID_CONVERSION_ACTION = "Invalid action. Must be 'APPROVE' or 'REJECT'."
ERROR_ONLY_HR_ADMIN_CREATE_RULE = "Access denied. Only HR/Admin can create points rules."
ERROR_ONLY_HR_ADMIN_UPDATE_RULE = "Access denied. Only HR/Admin can update points rules."

ERROR_ONLY_HR_ADMIN_CREATE_BADGE = "Only HR/Admin can create badges"
ERROR_FAILED_CREATE_BADGE = "Failed to create badge"
ERROR_ONLY_HR_ADMIN_UPDATE_BADGE = "Only HR/Admin can update badges"
ERROR_ECARD_NOT_FOUND = "ECard not found"

ERROR_INVALID_REPORT_TYPE = "Invalid report type: {}"
ERROR_INCORRECT_LOGIN = "Incorrect email or password"


def clamp_pagination(page: int = 1, per_page: int = DEFAULT_PAGE_SIZE) -> tuple:
    """Validate and clamp pagination parameters. Returns (page, per_page, skip)."""
    page = max(1, page)
    per_page = max(1, min(per_page, MAX_PAGE_SIZE))
    skip = (page - 1) * per_page
    return page, per_page, skip
