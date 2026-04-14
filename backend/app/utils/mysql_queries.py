"""
MySQL raw-SQL query constants for the R&R backend.

Organised as one class per table — same pattern used across Styria services
(award-service, feed-service, entity-service).

Usage (inside a repository):
    from app.utils.query_loader import QueryLoader
    from app.models.wallets import Wallet

    loader  = QueryLoader()
    queries = loader.get_queries(Wallet)
    result  = session.execute(queries.GET_BY_ID, {"id": wallet_id}).mappings().fetchone()

Notes
-----
- No RETURNING / OUTPUT INSERTED — MySQL doesn't support it.
  After every INSERT the repository calls SELECT WHERE id = LAST_INSERT_ID().
- Pagination uses LIMIT :limit OFFSET :skip.
- Booleans stored as TINYINT(1): TRUE = 1, FALSE = 0.
- Timestamps use NOW(); dates use CURDATE().
"""
from sqlalchemy import text


# ──────────────────────────────────────────────────────────────────────────────
# wallets
# ──────────────────────────────────────────────────────────────────────────────
class WalletQueries:
    GET_BY_ID = text("""
        SELECT * FROM wallets WHERE id = :id
    """)

    GET_BY_USER_AND_TYPE = text("""
        SELECT * FROM wallets
        WHERE user_id = :user_id AND wallet_type = :wallet_type
        LIMIT 1
    """)

    CREATE = text("""
        INSERT INTO wallets (user_id, wallet_type, balance, created_at)
        VALUES (:user_id, :wallet_type, :balance, NOW())
    """)

    UPDATE_BALANCE = text("""
        UPDATE wallets SET balance = :balance WHERE id = :id
    """)

    INCREMENT_BALANCE = text("""
        UPDATE wallets SET balance = balance + :delta WHERE id = :id
    """)

    DECREMENT_BALANCE = text("""
        UPDATE wallets SET balance = balance - :delta WHERE id = :id
    """)


# ──────────────────────────────────────────────────────────────────────────────
# wallet_funding
# ──────────────────────────────────────────────────────────────────────────────
class WalletFundingQueries:
    GET_BY_ID = text("""
        SELECT * FROM wallet_funding WHERE id = :id
    """)

    GET_BY_WALLET = text("""
        SELECT * FROM wallet_funding WHERE manager_wallet_id = :wallet_id
        ORDER BY created_at DESC
    """)

    CREATE = text("""
        INSERT INTO wallet_funding (manager_wallet_id, funded_by, points, created_at)
        VALUES (:manager_wallet_id, :funded_by, :points, NOW())
    """)

    SUM_FUNDING = text("""
        SELECT COALESCE(SUM(points), 0) AS total
        FROM wallet_funding
        WHERE manager_wallet_id = :wallet_id
    """)


# ──────────────────────────────────────────────────────────────────────────────
# points_ledger
# ──────────────────────────────────────────────────────────────────────────────
class PointsLedgerQueries:
    GET_BY_ID = text("""
        SELECT * FROM points_ledger WHERE id = :id
    """)

    GET_BY_WALLET = text("""
        SELECT * FROM points_ledger
        WHERE source_wallet_id = :wallet_id OR target_wallet_id = :wallet_id
        ORDER BY created_at DESC
    """)

    GET_BY_WALLET_PAGINATED_COUNT = text("""
        SELECT COUNT(*) AS total FROM points_ledger
        WHERE source_wallet_id = :wallet_id OR target_wallet_id = :wallet_id
    """)

    GET_BY_WALLET_PAGINATED = text("""
        SELECT * FROM points_ledger
        WHERE source_wallet_id = :wallet_id OR target_wallet_id = :wallet_id
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :skip
    """)

    CREATE = text("""
        INSERT INTO points_ledger
            (source_wallet_id, target_wallet_id, points, transaction_type,
             reference_type, reference_id, created_at)
        VALUES
            (:source_wallet_id, :target_wallet_id, :points, :transaction_type,
             :reference_type, :reference_id, NOW())
    """)

    SUM_CREDITS_FOR_WALLET = text("""
        SELECT COALESCE(SUM(points), 0) AS total
        FROM points_ledger
        WHERE transaction_type = 'CREDIT' AND target_wallet_id = :wallet_id
    """)

    SUM_CREDITS_SINCE = text("""
        SELECT COALESCE(SUM(points), 0) AS total
        FROM points_ledger
        WHERE transaction_type = 'CREDIT' AND created_at >= :since
    """)

    SUM_MONTHLY_EARNED = text("""
        SELECT COALESCE(SUM(points), 0) AS total
        FROM points_ledger
        WHERE transaction_type = 'CREDIT'
          AND target_wallet_id = :wallet_id
          AND created_at >= :since
    """)


# ──────────────────────────────────────────────────────────────────────────────
# points_batches
# ──────────────────────────────────────────────────────────────────────────────
class PointsBatchQueries:
    GET_BY_ID = text("""
        SELECT * FROM points_batches WHERE id = :id
    """)

    GET_AVAILABLE_BALANCE = text("""
        SELECT COALESCE(SUM(remaining_points), 0) AS total
        FROM points_batches
        WHERE user_id = :user_id
          AND expiry_date >= CURDATE()
          AND remaining_points > 0
    """)

    GET_FIFO_BATCHES = text("""
        SELECT * FROM points_batches
        WHERE user_id = :user_id
          AND expiry_date >= CURDATE()
          AND remaining_points > 0
        ORDER BY expiry_date ASC
    """)

    GET_EXPIRED_BATCHES = text("""
        SELECT * FROM points_batches
        WHERE user_id = :user_id
          AND expiry_date < CURDATE()
          AND remaining_points > 0
    """)

    GET_EXPIRED_BATCHES_COUNT = text("""
        SELECT COUNT(*) AS total FROM points_batches
        WHERE user_id = :user_id
          AND expiry_date < CURDATE()
          AND remaining_points > 0
    """)

    GET_EXPIRED_BATCHES_PAGINATED = text("""
        SELECT * FROM points_batches
        WHERE user_id = :user_id
          AND expiry_date < CURDATE()
          AND remaining_points > 0
        ORDER BY expiry_date DESC
        LIMIT :limit OFFSET :skip
    """)

    GET_UPCOMING_EXPIRY = text("""
        SELECT * FROM points_batches
        WHERE expiry_date > CURDATE()
          AND expiry_date <= :cutoff
          AND remaining_points > 0
    """)

    GET_ALL_EXPIRED_UNPROCESSED = text("""
        SELECT * FROM points_batches
        WHERE expiry_date < CURDATE()
          AND remaining_points > 0
    """)

    GET_GROUPED_EXPIRING_ON = text("""
        SELECT user_id, SUM(remaining_points) AS total_expiring
        FROM points_batches
        WHERE expiry_date = :expiry_date
          AND remaining_points > :min_points
        GROUP BY user_id
    """)

    GET_EXPIRY_FORECAST = text("""
        SELECT expiry_date,
               SUM(remaining_points)          AS total_points,
               COUNT(DISTINCT user_id)        AS user_count
        FROM points_batches
        WHERE remaining_points > 0
          AND expiry_date <= :target_date
          AND expiry_date >= CURDATE()
        GROUP BY expiry_date
        ORDER BY expiry_date
    """)

    GET_EXPIRING_POINTS_ON_DATE = text("""
        SELECT COALESCE(SUM(remaining_points), 0) AS total
        FROM points_batches
        WHERE user_id = :user_id
          AND remaining_points > 0
          AND expiry_date = :on_date
    """)

    GET_EXPIRING_POINTS_IN_RANGE = text("""
        SELECT COALESCE(SUM(remaining_points), 0) AS total
        FROM points_batches
        WHERE user_id = :user_id
          AND remaining_points > 0
          AND expiry_date > :after
          AND expiry_date <= :until
    """)

    CREATE = text("""
        INSERT INTO points_batches
            (user_id, points, remaining_points, source_type, source_id, expiry_date, created_at)
        VALUES
            (:user_id, :points, :remaining_points, :source_type, :source_id, :expiry_date, NOW())
    """)

    UPDATE_REMAINING = text("""
        UPDATE points_batches SET remaining_points = :remaining_points WHERE id = :id
    """)


# ──────────────────────────────────────────────────────────────────────────────
# points_policy
# ──────────────────────────────────────────────────────────────────────────────
class PointsPolicyQueries:
    GET_BY_ID = text("""
        SELECT * FROM points_policy WHERE id = :id
    """)

    GET_ALL = text("""
        SELECT * FROM points_policy
    """)

    GET_ACTIVE = text("""
        SELECT * FROM points_policy WHERE is_active = TRUE
    """)

    GET_ECARD_POLICY = text("""
        SELECT * FROM points_policy
        WHERE recognition_type = 'ECARD'
          AND event_key IS NULL
          AND is_active = TRUE
        LIMIT 1
    """)

    GET_CELEBRATION_POLICY = text("""
        SELECT * FROM points_policy
        WHERE recognition_type = 'CELEBRATION'
          AND event_key = :event_key
          AND is_active = TRUE
        LIMIT 1
    """)

    FIND_DUPLICATES_CONVERSION = text("""
        SELECT * FROM points_policy
        WHERE recognition_type = 'CONVERSION'
          AND conversion_reward_type = :conversion_reward_type
    """)

    FIND_DUPLICATES_WITH_EVENT_KEY = text("""
        SELECT * FROM points_policy
        WHERE recognition_type = :recognition_type
          AND event_key = :event_key
    """)

    FIND_DUPLICATES_NO_EVENT_KEY = text("""
        SELECT * FROM points_policy
        WHERE recognition_type = :recognition_type
          AND event_key IS NULL
    """)

    CREATE = text("""
        INSERT INTO points_policy
            (recognition_type, event_key, points, monthly_limit, cooldown_days,
             cooldown_hours, consecutive_limit, conversion_rate, conversion_reward_type,
             is_active, created_at)
        VALUES
            (:recognition_type, :event_key, :points, :monthly_limit, :cooldown_days,
             :cooldown_hours, :consecutive_limit, :conversion_rate, :conversion_reward_type,
             :is_active, NOW())
    """)

    UPDATE = text("""
        UPDATE points_policy SET
            points                 = COALESCE(:points, points),
            monthly_limit          = COALESCE(:monthly_limit, monthly_limit),
            cooldown_days          = COALESCE(:cooldown_days, cooldown_days),
            cooldown_hours         = COALESCE(:cooldown_hours, cooldown_hours),
            consecutive_limit      = COALESCE(:consecutive_limit, consecutive_limit),
            conversion_rate        = COALESCE(:conversion_rate, conversion_rate),
            conversion_reward_type = COALESCE(:conversion_reward_type, conversion_reward_type),
            is_active              = COALESCE(:is_active, is_active)
        WHERE id = :id
    """)


# ──────────────────────────────────────────────────────────────────────────────
# points_conversion
# ──────────────────────────────────────────────────────────────────────────────
class PointsConversionQueries:
    GET_BY_ID = text("""
        SELECT * FROM points_conversion WHERE id = :id
    """)

    GET_BY_USER = text("""
        SELECT * FROM points_conversion WHERE user_id = :user_id
        ORDER BY requested_at DESC
    """)

    GET_ALL = text("""
        SELECT * FROM points_conversion ORDER BY requested_at DESC
    """)

    GET_PENDING = text("""
        SELECT * FROM points_conversion WHERE status = 'PENDING'
    """)

    GET_PENDING_BY_USER = text("""
        SELECT * FROM points_conversion
        WHERE user_id = :user_id AND status = 'PENDING'
        ORDER BY requested_at DESC
    """)

    GET_PENDING_BY_USER_PAGINATED_COUNT = text("""
        SELECT COUNT(*) AS total FROM points_conversion
        WHERE user_id = :user_id AND status = 'PENDING'
    """)

    GET_PENDING_BY_USER_PAGINATED = text("""
        SELECT * FROM points_conversion
        WHERE user_id = :user_id AND status = 'PENDING'
        ORDER BY requested_at DESC
        LIMIT :limit OFFSET :skip
    """)

    HAS_PENDING = text("""
        SELECT COUNT(*) AS cnt FROM points_conversion
        WHERE user_id = :user_id AND status = 'PENDING'
    """)

    COUNT_PENDING = text("""
        SELECT COUNT(*) AS total FROM points_conversion
        WHERE user_id = :user_id AND status = 'PENDING'
    """)

    SUM_PENDING_POINTS = text("""
        SELECT COALESCE(SUM(points_converted), 0) AS total
        FROM points_conversion
        WHERE user_id = :user_id AND status = 'PENDING'
    """)

    SUM_APPROVED_CONVERTED = text("""
        SELECT COALESCE(SUM(points_converted), 0) AS total
        FROM points_conversion
        WHERE user_id = :user_id AND status IN ('APPROVED', 'PAID')
    """)

    GET_APPROVED_FOR_PAYROLL = text("""
        SELECT * FROM points_conversion
        WHERE status = 'APPROVED'
          AND YEAR(approved_at) = :year
          AND MONTH(approved_at) = :month
    """)

    CREATE = text("""
        INSERT INTO points_conversion
            (user_id, points_converted, cash_amount, conversion_type, status, requested_at)
        VALUES
            (:user_id, :points_converted, :cash_amount, :conversion_type, :status, NOW())
    """)

    UPDATE_STATUS = text("""
        UPDATE points_conversion SET
            status      = :status,
            approved_by = :approved_by,
            approved_at = :approved_at
        WHERE id = :id
    """)


# ──────────────────────────────────────────────────────────────────────────────
# rewards
# ──────────────────────────────────────────────────────────────────────────────
class RewardQueries:
    GET_BY_ID = text("""
        SELECT * FROM rewards WHERE id = :id
    """)

    GET_CATALOG_COUNT = text("""
        SELECT COUNT(*) AS total FROM rewards
        WHERE is_active = TRUE
          AND (stock_quantity IS NULL OR stock_quantity > 0)
    """)

    GET_CATALOG_COUNT_ALL = text("""
        SELECT COUNT(*) AS total FROM rewards
    """)

    GET_CATALOG = text("""
        SELECT * FROM rewards
        WHERE is_active = TRUE
          AND (stock_quantity IS NULL OR stock_quantity > 0)
        LIMIT :limit OFFSET :skip
    """)

    GET_CATALOG_ALL = text("""
        SELECT * FROM rewards LIMIT :limit OFFSET :skip
    """)

    CREATE = text("""
        INSERT INTO rewards
            (name, reward_type, points_required, stock_quantity, image_url, is_active, created_at)
        VALUES
            (:name, :reward_type, :points_required, :stock_quantity, :image_url, :is_active, NOW())
    """)

    UPDATE = text("""
        UPDATE rewards SET
            name            = COALESCE(:name, name),
            reward_type     = COALESCE(:reward_type, reward_type),
            points_required = COALESCE(:points_required, points_required),
            stock_quantity  = COALESCE(:stock_quantity, stock_quantity),
            image_url       = COALESCE(:image_url, image_url),
            is_active       = COALESCE(:is_active, is_active),
            updated_at      = NOW()
        WHERE id = :id
    """)

    DECREMENT_STOCK = text("""
        UPDATE rewards SET stock_quantity = stock_quantity - 1 WHERE id = :id AND stock_quantity > 0
    """)


# ──────────────────────────────────────────────────────────────────────────────
# redemptions
# ──────────────────────────────────────────────────────────────────────────────
class RedemptionQueries:
    GET_BY_ID = text("""
        SELECT r.*, rw.name AS reward_name, rw.reward_type, rw.image_url
        FROM redemptions r
        JOIN rewards rw ON rw.id = r.reward_id
        WHERE r.id = :id
    """)

    GET_BY_USER = text("""
        SELECT r.*, rw.name AS reward_name, rw.reward_type, rw.image_url
        FROM redemptions r
        JOIN rewards rw ON rw.id = r.reward_id
        WHERE r.user_id = :user_id
        ORDER BY r.created_at DESC
    """)

    GET_ALL = text("""
        SELECT r.*, rw.name AS reward_name, rw.reward_type
        FROM redemptions r
        JOIN rewards rw ON rw.id = r.reward_id
        ORDER BY r.created_at DESC
    """)

    SUM_REDEEMED_BY_USER = text("""
        SELECT COALESCE(SUM(points_used), 0) AS total
        FROM redemptions WHERE user_id = :user_id
    """)

    CREATE = text("""
        INSERT INTO redemptions (user_id, reward_id, points_used, status, created_at)
        VALUES (:user_id, :reward_id, :points_used, :status, NOW())
    """)

    UPDATE_STATUS = text("""
        UPDATE redemptions SET status = :status WHERE id = :id
    """)


# ──────────────────────────────────────────────────────────────────────────────
# badges
# ──────────────────────────────────────────────────────────────────────────────
class BadgeQueries:
    GET_BY_ID = text("""
        SELECT * FROM badges WHERE id = :id
    """)

    GET_ALL_ACTIVE = text("""
        SELECT * FROM badges WHERE is_active = TRUE
    """)

    GET_ALL = text("""
        SELECT * FROM badges
    """)

    GET_BY_NAME = text("""
        SELECT * FROM badges WHERE LOWER(name) = LOWER(:name) LIMIT 1
    """)

    CREATE = text("""
        INSERT INTO badges (name, description, icon_url, points, is_active, created_at)
        VALUES (:name, :description, :icon_url, :points, :is_active, NOW())
    """)

    UPDATE = text("""
        UPDATE badges SET
            name        = COALESCE(:name, name),
            description = COALESCE(:description, description),
            icon_url    = COALESCE(:icon_url, icon_url),
            points      = COALESCE(:points, points),
            is_active   = COALESCE(:is_active, is_active)
        WHERE id = :id
    """)


# ──────────────────────────────────────────────────────────────────────────────
# ecards
# ──────────────────────────────────────────────────────────────────────────────
class ECardQueries:
    GET_BY_ID = text("""
        SELECT e.*, b.name AS badge_name, b.icon_url AS badge_icon_url
        FROM ecards e
        JOIN badges b ON b.id = e.badge_id
        WHERE e.id = :id
    """)

    COUNT_SINCE = text("""
        SELECT COUNT(*) AS cnt
        FROM ecards
        WHERE sender_id = :sender_id AND created_at >= :since
    """)

    GET_LAST_BY_SENDER = text("""
        SELECT * FROM ecards WHERE sender_id = :sender_id ORDER BY created_at DESC LIMIT 1
    """)

    GET_LAST_BY_SENDER_SINCE = text("""
        SELECT * FROM ecards
        WHERE sender_id = :sender_id AND created_at >= :since
        ORDER BY created_at DESC LIMIT 1
    """)

    CREATE = text("""
        INSERT INTO ecards
            (sender_id, receiver_id, badge_id, points_awarded, message,
             persona_type, persona_label, created_at)
        VALUES
            (:sender_id, :receiver_id, :badge_id, :points_awarded, :message,
             :persona_type, :persona_label, NOW())
    """)

    GET_RECEIVED = text("""
        SELECT e.*, b.name AS badge_name, b.icon_url AS badge_icon_url
        FROM ecards e
        JOIN badges b ON b.id = e.badge_id
        WHERE e.receiver_id = :receiver_id
        ORDER BY e.created_at DESC
    """)

    GET_SENT = text("""
        SELECT e.*, b.name AS badge_name, b.icon_url AS badge_icon_url
        FROM ecards e
        JOIN badges b ON b.id = e.badge_id
        WHERE e.sender_id = :sender_id
        ORDER BY e.created_at DESC
    """)


# ──────────────────────────────────────────────────────────────────────────────
# award_types
# ──────────────────────────────────────────────────────────────────────────────
class AwardTypeQueries:
    GET_BY_ID = text("""
        SELECT * FROM award_types WHERE id = :id
    """)

    GET_BY_ID_ACTIVE = text("""
        SELECT * FROM award_types WHERE id = :id AND is_active = TRUE
    """)

    GET_ALL_ACTIVE = text("""
        SELECT * FROM award_types WHERE is_active = TRUE
    """)

    GET_ALL = text("""
        SELECT * FROM award_types
    """)

    GET_ACTIVE_WITH_ELIGIBILITY = text("""
        SELECT * FROM award_types
        WHERE is_active = TRUE AND eligibility_rule IN :eligibility_rules
    """)

    GET_BY_KEY = text("""
        SELECT * FROM award_types WHERE award_key = :award_key LIMIT 1
    """)

    GET_BY_NAME = text("""
        SELECT * FROM award_types WHERE LOWER(name) = LOWER(:name) LIMIT 1
    """)

    CREATE = text("""
        INSERT INTO award_types
            (award_key, name, description, points, frequency, eligibility_rule,
             approval_workflow, is_active, created_at)
        VALUES
            (:award_key, :name, :description, :points, :frequency, :eligibility_rule,
             :approval_workflow, :is_active, NOW())
    """)

    UPDATE = text("""
        UPDATE award_types SET
            name               = COALESCE(:name, name),
            description        = COALESCE(:description, description),
            points             = COALESCE(:points, points),
            frequency          = COALESCE(:frequency, frequency),
            eligibility_rule   = COALESCE(:eligibility_rule, eligibility_rule),
            approval_workflow  = COALESCE(:approval_workflow, approval_workflow),
            is_active          = COALESCE(:is_active, is_active)
        WHERE id = :id
    """)


# ──────────────────────────────────────────────────────────────────────────────
# awards
# ──────────────────────────────────────────────────────────────────────────────
class AwardQueries:
    GET_BY_ID = text("""
        SELECT a.*, at.name AS award_type_name, at.award_key, at.points AS type_points,
               at.frequency, at.eligibility_rule, at.approval_workflow
        FROM awards a
        JOIN award_types at ON at.id = a.award_type_id
        WHERE a.id = :id
    """)

    GET_BY_ID_SIMPLE = text("""
        SELECT * FROM awards WHERE id = :id
    """)

    CREATE = text("""
        INSERT INTO awards
            (nominee_id, nominator_id, award_type_id, status, points_awarded,
             citation, persona_type, persona_label, created_at)
        VALUES
            (:nominee_id, :nominator_id, :award_type_id, :status, :points_awarded,
             :citation, :persona_type, :persona_label, NOW())
    """)

    FIND_PENDING_NOMINATION = text("""
        SELECT * FROM awards
        WHERE nominee_id = :nominee_id
          AND award_type_id = :award_type_id
          AND status = 'PENDING'
        LIMIT 1
    """)

    UPDATE_STATUS = text("""
        UPDATE awards SET status = :status WHERE id = :id
    """)

    GET_INVOLVED_IDS = text("""
        SELECT DISTINCT a.id
        FROM awards a
        LEFT JOIN award_approvals aa ON aa.award_id = a.id
        WHERE a.nominator_id = :user_id
           OR a.nominee_id   = :user_id
           OR aa.approver_id = :user_id
    """)

    GET_PENDING_EXCLUDING = text("""
        SELECT a.*, at.name AS award_type_name, at.award_key
        FROM awards a
        JOIN award_types at ON at.id = a.award_type_id
        WHERE a.status = 'PENDING'
          AND a.id NOT IN :exclude_ids
    """)

    GET_PENDING_NO_EXCLUSION = text("""
        SELECT a.*, at.name AS award_type_name, at.award_key
        FROM awards a
        JOIN award_types at ON at.id = a.award_type_id
        WHERE a.status = 'PENDING'
    """)

    GET_FILTERED_COUNT = text("""
        SELECT COUNT(*) AS total FROM awards
        WHERE id IN :award_ids
          AND (:status IS NULL OR status = :status)
    """)

    GET_FILTERED = text("""
        SELECT a.*, at.name AS award_type_name, at.award_key
        FROM awards a
        JOIN award_types at ON at.id = a.award_type_id
        WHERE a.id IN :award_ids
          AND (:status IS NULL OR a.status = :status)
        ORDER BY a.created_at DESC
        LIMIT :limit OFFSET :skip
    """)


# ──────────────────────────────────────────────────────────────────────────────
# award_approvals
# ──────────────────────────────────────────────────────────────────────────────
class AwardApprovalQueries:
    GET_BY_ID = text("""
        SELECT * FROM award_approvals WHERE id = :id
    """)

    CREATE = text("""
        INSERT INTO award_approvals
            (award_id, approver_id, approval_level, status, comments, created_at)
        VALUES
            (:award_id, :approver_id, :approval_level, :status, :comments, NOW())
    """)

    GET_APPROVED_LEVELS = text("""
        SELECT approval_level FROM award_approvals
        WHERE award_id = :award_id AND status = 'APPROVED'
    """)

    GET_BY_AWARD_ID = text("""
        SELECT * FROM award_approvals WHERE award_id = :award_id
        ORDER BY created_at DESC
    """)

    GET_BY_APPROVER = text("""
        SELECT * FROM award_approvals WHERE approver_id = :approver_id
        ORDER BY created_at DESC
    """)

    GET_BY_AWARD_IDS = text("""
        SELECT * FROM award_approvals WHERE award_id IN :award_ids
        ORDER BY created_at DESC
    """)

    UPDATE_STATUS = text("""
        UPDATE award_approvals SET status = :status, comments = :comments WHERE id = :id
    """)


# ──────────────────────────────────────────────────────────────────────────────
# notifications
# ──────────────────────────────────────────────────────────────────────────────
class NotificationQueries:
    GET_BY_ID = text("""
        SELECT * FROM notifications WHERE id = :id
    """)

    COUNT_BY_USER = text("""
        SELECT COUNT(*) AS total FROM notifications WHERE user_id = :user_id
    """)

    COUNT_BY_USER_UNREAD = text("""
        SELECT COUNT(*) AS total FROM notifications
        WHERE user_id = :user_id AND is_read = FALSE
    """)

    GET_BY_USER_PAGINATED = text("""
        SELECT * FROM notifications WHERE user_id = :user_id
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :skip
    """)

    GET_BY_USER_UNREAD_PAGINATED = text("""
        SELECT * FROM notifications
        WHERE user_id = :user_id AND is_read = FALSE
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :skip
    """)

    CREATE = text("""
        INSERT INTO notifications
            (user_id, message, source_type, source_id, is_read, created_at)
        VALUES
            (:user_id, :message, :source_type, :source_id, FALSE, NOW())
    """)

    MARK_READ = text("""
        UPDATE notifications SET is_read = TRUE
        WHERE id = :id AND user_id = :user_id
    """)

    MARK_ALL_READ = text("""
        UPDATE notifications SET is_read = TRUE
        WHERE user_id = :user_id AND is_read = FALSE
    """)

    FIND_BY_SOURCE = text("""
        SELECT * FROM notifications
        WHERE source_type = :source_type AND source_id = :source_id
        LIMIT 1
    """)

    FIND_BY_USER_SOURCE_LIKE = text("""
        SELECT * FROM notifications
        WHERE user_id = :user_id
          AND source_type = :source_type
          AND message LIKE :pattern
        LIMIT 1
    """)


# ──────────────────────────────────────────────────────────────────────────────
# celebrations
# ──────────────────────────────────────────────────────────────────────────────
class CelebrationQueries:
    GET_BY_ID = text("""
        SELECT * FROM celebrations WHERE id = :id
    """)

    GET_BY_USER_TYPE_YEAR = text("""
        SELECT * FROM celebrations
        WHERE user_id = :user_id
          AND celebration_type = :celebration_type
          AND year = :year
        LIMIT 1
    """)

    GET_HISTORY_COUNT = text("""
        SELECT COUNT(*) AS total FROM celebrations
    """)

    GET_HISTORY = text("""
        SELECT * FROM celebrations ORDER BY created_at DESC
        LIMIT :limit OFFSET :skip
    """)

    CREATE = text("""
        INSERT INTO celebrations
            (user_id, celebration_type, year, points_awarded, created_at)
        VALUES
            (:user_id, :celebration_type, :year, :points_awarded, NOW())
    """)


# ──────────────────────────────────────────────────────────────────────────────
# recognition_feed
# ──────────────────────────────────────────────────────────────────────────────
class RecognitionFeedQueries:
    GET_BY_ID = text("""
        SELECT * FROM recognition_feed WHERE id = :id
    """)

    GET_ALL = text("""
        SELECT * FROM recognition_feed ORDER BY created_at DESC
    """)

    GET_BY_ACTOR = text("""
        SELECT * FROM recognition_feed WHERE actor_id = :actor_id
        ORDER BY created_at DESC
    """)

    GET_BY_RECEIVER = text("""
        SELECT * FROM recognition_feed WHERE receiver_id = :receiver_id
        ORDER BY created_at DESC
    """)

    GET_FILTERED_COUNT = text("""
        SELECT COUNT(*) AS total FROM recognition_feed
        WHERE (:actor_id IS NULL OR actor_id = :actor_id)
          AND (:receiver_id IS NULL OR receiver_id = :receiver_id)
          AND (:from_date IS NULL OR created_at >= :from_date)
          AND (:to_date IS NULL OR created_at <= :to_date)
    """)

    GET_FILTERED = text("""
        SELECT * FROM recognition_feed
        WHERE (:actor_id IS NULL OR actor_id = :actor_id)
          AND (:receiver_id IS NULL OR receiver_id = :receiver_id)
          AND (:from_date IS NULL OR created_at >= :from_date)
          AND (:to_date IS NULL OR created_at <= :to_date)
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :skip
    """)

    CREATE = text("""
        INSERT INTO recognition_feed
            (actor_id, receiver_id, source_type, source_id, message, actor_label, created_at)
        VALUES
            (:actor_id, :receiver_id, :source_type, :source_id, :message, :actor_label, NOW())
    """)

    # Analytics queries -------------------------------------------------------
    COUNT_RECOGNITIONS = text("""
        SELECT COUNT(*) AS cnt FROM recognition_feed
        WHERE (:from_date IS NULL OR created_at >= :from_date)
          AND (:to_date IS NULL OR created_at <= :to_date)
    """)

    COUNT_RECOGNITIONS_FOR_USERS = text("""
        SELECT COUNT(*) AS cnt FROM recognition_feed
        WHERE receiver_id IN :user_ids
          AND (:from_date IS NULL OR created_at >= :from_date)
          AND (:to_date IS NULL OR created_at <= :to_date)
    """)

    GET_RECOGNITION_TRENDS = text("""
        SELECT DATE(created_at) AS `date`, COUNT(*) AS `count`
        FROM recognition_feed
        WHERE (:from_date IS NULL OR created_at >= :from_date)
          AND (:to_date IS NULL OR created_at <= :to_date)
        GROUP BY DATE(created_at)
        ORDER BY DATE(created_at)
    """)

    GET_RECOGNITION_TRENDS_FOR_USERS = text("""
        SELECT DATE(created_at) AS `date`, COUNT(*) AS `count`
        FROM recognition_feed
        WHERE receiver_id IN :user_ids
          AND (:from_date IS NULL OR created_at >= :from_date)
          AND (:to_date IS NULL OR created_at <= :to_date)
        GROUP BY DATE(created_at)
        ORDER BY DATE(created_at)
    """)

    GET_TOP_RECOGNIZERS = text("""
        SELECT actor_id, COUNT(*) AS `count`
        FROM recognition_feed
        GROUP BY actor_id
        ORDER BY `count` DESC
        LIMIT :limit
    """)

    GET_TOP_RECOGNIZERS_FOR_USERS = text("""
        SELECT actor_id, COUNT(*) AS `count`
        FROM recognition_feed
        WHERE actor_id IN :user_ids
        GROUP BY actor_id
        ORDER BY `count` DESC
        LIMIT :limit
    """)

    GET_TOP_RECOGNIZED = text("""
        SELECT receiver_id, COUNT(*) AS `count`
        FROM recognition_feed
        GROUP BY receiver_id
        ORDER BY `count` DESC
        LIMIT :limit
    """)

    GET_TOP_RECOGNIZED_FOR_USERS = text("""
        SELECT receiver_id, COUNT(*) AS `count`
        FROM recognition_feed
        WHERE receiver_id IN :user_ids
        GROUP BY receiver_id
        ORDER BY `count` DESC
        LIMIT :limit
    """)

    GET_ACTIVE_USER_COUNT = text("""
        SELECT COUNT(DISTINCT uid) AS cnt FROM (
            SELECT receiver_id AS uid FROM recognition_feed
            UNION
            SELECT actor_id AS uid FROM recognition_feed
        ) AS combined
    """)

    GET_ACTIVE_USER_COUNT_FOR_USERS = text("""
        SELECT COUNT(DISTINCT uid) AS cnt FROM (
            SELECT receiver_id AS uid FROM recognition_feed WHERE receiver_id IN :user_ids
            UNION
            SELECT actor_id AS uid FROM recognition_feed WHERE actor_id IN :user_ids
        ) AS combined
    """)

    SUM_POINTS_FOR_USERS = text("""
        SELECT COALESCE(SUM(pl.points), 0) AS total
        FROM points_ledger pl
        JOIN wallets w ON w.id = pl.target_wallet_id
        WHERE w.user_id IN :user_ids
          AND w.wallet_type = 'EMPLOYEE'
          AND pl.transaction_type = 'CREDIT'
          AND (:from_date IS NULL OR pl.created_at >= :from_date)
          AND (:to_date IS NULL OR pl.created_at <= :to_date)
    """)


# ──────────────────────────────────────────────────────────────────────────────
# system_config
# ──────────────────────────────────────────────────────────────────────────────
class SystemConfigQueries:
    GET_BY_KEY = text("""
        SELECT * FROM system_config WHERE `key` = :key
    """)

    GET_ALL = text("""
        SELECT * FROM system_config
    """)

    UPSERT = text("""
        INSERT INTO system_config (`key`, value, description, updated_at)
        VALUES (:key, :value, :description, NOW())
        ON DUPLICATE KEY UPDATE
            value       = VALUES(value),
            description = COALESCE(VALUES(description), description),
            updated_at  = NOW()
    """)


# ──────────────────────────────────────────────────────────────────────────────
# email_logs
# ──────────────────────────────────────────────────────────────────────────────
class EmailLogQueries:
    GET_BY_ID = text("""
        SELECT * FROM email_logs WHERE id = :id
    """)

    GET_RECENT = text("""
        SELECT * FROM email_logs ORDER BY created_at DESC LIMIT :limit OFFSET :offset
    """)

    GET_FEATURE_FLAG = text("""
        SELECT value FROM system_config
        WHERE `key` = 'feature.email_notifications_enabled'
        LIMIT 1
    """)

    CREATE = text("""
        INSERT INTO email_logs
            (recipient_email, user_id, template_key, subject, body_html,
             status, error_message, created_at, sent_at)
        VALUES
            (:recipient_email, :user_id, :template_key, :subject, :body_html,
             :status, :error_message, NOW(), :sent_at)
    """)

    UPDATE_STATUS = text("""
        UPDATE email_logs SET status = :status, error_message = :error_message, sent_at = :sent_at
        WHERE id = :id
    """)
