"""create schema

Revision ID: 130601cd46c9
Revises: 661986d31dc6
Create Date: 2022-08-09 16:23:32.161405

"""
import importlib

from alembic import op
from sqlalchemy.sql import text


# revision identifiers, used by Alembic.
revision = "130601cd46c9"
down_revision = "661986d31dc6"
branch_labels = None
depends_on = None


def upgrade():
    operations = text(
        importlib.resources.read_text(
            "gn_module_monitoring_flora_territory.migrations.data", "schema.sql"
        )
    )
    op.get_bind().execute(operations)


def downgrade():
    op.execute("DROP SCHEMA pr_monitoring_flora_territory CASCADE")
