"""add synthese triggers

Revision ID: ab2c1be6dd0d
Revises: 130601cd46c9
Create Date: 2022-09-08 09:46:53.756199

"""
import importlib

from alembic import op
from sqlalchemy.sql import text

from gn_module_monitoring_flora_territory import MODULE_CODE


# revision identifiers, used by Alembic.
revision = 'ab2c1be6dd0d'
down_revision = '130601cd46c9'
branch_labels = None
depends_on = None

def upgrade():
    operations = text(
        importlib.resources.read_text(
            "gn_module_monitoring_flora.territory.data", "synthese.sql"
        )
    )

    op.get_bind().execute(operations, { "moduleCode": MODULE_CODE })


def downgrade():
    pass