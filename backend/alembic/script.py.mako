"""
Alembic migration template (minimal).
This template is used by Alembic when generating revision files via autogenerate.
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '${up_revision}'
down_revision = ${repr(down_revision)}
branch_labels = ${repr(branch_labels)}
depends_on = ${repr(depends_on)}


def upgrade():
    """Apply upgrade migrations."""
${upgrades if upgrades else "    pass"}


def downgrade():
    """Revert upgrade migrations."""
${downgrades if downgrades else "    pass"}
