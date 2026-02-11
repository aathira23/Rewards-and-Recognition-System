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
    VOUCHER = "VOUCHER"


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
    """Award eligibility rules."""
    MANAGER_ONLY = "MANAGER_ONLY"
    PEER = "PEER"
    CROSS_DEPT = "CROSS_DEPT"
