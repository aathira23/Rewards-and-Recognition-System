"""
Enumerations for the application.
"""
from enum import Enum


class UserRole(str, Enum):
    """User roles in the system."""
    EMPLOYEE = "EMPLOYEE"
    MANAGER = "MANAGER"
    DEPT_HEAD = "DEPT_HEAD"
    HR = "HR"
    ADMIN = "ADMIN"


class Scope(str, Enum):
    """Analytics visibility scopes."""
    ORG = "ORG"
    DEPARTMENT = "DEPARTMENT"
    TEAM = "TEAM"


class WalletType(str, Enum):
    """Wallet types."""
    EMPLOYEE = "EMPLOYEE"
    MANAGER = "MANAGER"
    SYSTEM = "SYSTEM"


class TransactionType(str, Enum):
    """Transaction types for points ledger."""
    CREDIT = "CREDIT"
    DEBIT = "DEBIT"


class ReferenceType(str, Enum):
    """Reference types for transactions."""
    ECARD = "ECARD"
    AWARD = "AWARD"
    REDEMPTION = "REDEMPTION"
    CONVERSION = "CONVERSION"
    CELEBRATION = "CELEBRATION"
    MANAGER_REWARD = "MANAGER_REWARD"
    EXPIRY = "EXPIRY"
    BUDGET_ALLOCATION = "BUDGET_ALLOCATION"


class SourceType(str, Enum):
    ECARD = "ECARD"
    AWARD = "AWARD"
    CELEBRATION = "CELEBRATION"
    MANAGER_REWARD = "MANAGER_REWARD"
    CONVERSION = "CONVERSION"

class RecognitionType(str, Enum):
    """Recognition types for points policy."""
    ECARD = "ECARD"
    AWARD = "AWARD"
    CELEBRATION = "CELEBRATION"


class CelebrationType(str, Enum):
    """Celebration event types."""
    BIRTHDAY = "BIRTHDAY"
    ANNIVERSARY = "ANNIVERSARY"


class AwardStatus(str, Enum):
    """Award nomination status."""
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


class ApprovalLevel(str, Enum):
    """Approval levels for awards."""
    MANAGER = "MANAGER"
    DEPT_HEAD = "DEPT_HEAD"
    HR = "HR"


class ApprovalStatus(str, Enum):
    """Approval decision status."""
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


class RewardType(str, Enum):
    """Reward catalog item types."""
    MERCH = "MERCH"
    GIFT_CARD = "GIFT_CARD"
    CSR = "CSR"


class RedemptionStatus(str, Enum):
    """Redemption request status."""
    REQUESTED = "REQUESTED"
    FULFILLED = "FULFILLED"
    CANCELLED = "CANCELLED"


class ConversionType(str, Enum):
    """Points conversion types."""
    PAYROLL = "PAYROLL"
    CSR = "CSR"


class ConversionStatus(str, Enum):
    """Points conversion status."""
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    PAID = "PAID"


class AwardFrequency(str, Enum):
    """Award type frequency."""
    MONTHLY = "MONTHLY"
    QUARTERLY = "QUARTERLY"
    ADHOC = "ADHOC"


class EligibilityRule(str, Enum):
    """
    Award eligibility rules — defines who may nominate for an award.

    MANAGER_ONLY  : Only Managers / Dept Heads / HR can nominate.
                    Used for formal performance-based awards given top-down
                    (e.g. Star Performer, Best Team Player, Rising Star).

    PEER          : Any employee (including Managers / Dept Heads / HR) can
                    nominate a colleague.  Used for culture / value awards where
                    grassroots recognition matters (e.g. Above and Beyond,
                    Spot Award).

    SENIOR_MGMT   : Dept Heads and HR only.  Used for high-value org-wide or
                    cross-functional awards that require senior visibility
                    (e.g. Innovation Award, Leadership Excellence,
                    Special Achievement).
    """
    MANAGER_ONLY = "MANAGER_ONLY"
    PEER         = "PEER"
    SENIOR_MGMT  = "SENIOR_MGMT"


class EmailEventType(str, Enum):
    """Event types that can trigger an email notification."""
    WELCOME = "WELCOME"
    EMAIL_VERIFICATION = "EMAIL_VERIFICATION"
    PASSWORD_RESET = "PASSWORD_RESET"
    NOMINATION_SUBMITTED = "NOMINATION_SUBMITTED"
    AWARD_APPROVED = "AWARD_APPROVED"
    AWARD_REJECTED = "AWARD_REJECTED"
    REDEMPTION_CONFIRMED = "REDEMPTION_CONFIRMED"
    CONVERSION_SUBMITTED = "CONVERSION_SUBMITTED"
    CONVERSION_APPROVED = "CONVERSION_APPROVED"
    CONVERSION_REJECTED = "CONVERSION_REJECTED"
    POINTS_EXPIRY_REMINDER = "POINTS_EXPIRY_REMINDER"
    CELEBRATION_REMINDER = "CELEBRATION_REMINDER"
    PENDING_APPROVALS_REMINDER = "PENDING_APPROVALS_REMINDER"
    RECOGNITION_RECEIVED = "RECOGNITION_RECEIVED"
    HR_CRITICAL = "HR_CRITICAL"
