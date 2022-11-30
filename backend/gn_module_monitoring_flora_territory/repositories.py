from sqlalchemy.sql.expression import func

from werkzeug.exceptions import Forbidden

from geonature.core.gn_monitoring.models import TBaseVisits
from geonature.utils.env import db


def check_user_cruved_visit(user, visit, cruved_level):
    """
    Check if user have right on a visit object, related to his cruved.
    If not, raise 403 error.
    If allowed return void.
    """
    is_allowed = False
    # cruved level '1' => My data
    if cruved_level == "1":
        for role in visit.observers:
            if role.id_role == user.id_role:
                is_allowed = True
                break
            elif visit.id_digitiser == user.id_role:
                is_allowed = True
                break
        if not is_allowed:
            raise Forbidden(
                f"User {user.id_role} cannot update visit number {visit.id_base_visit}"
            )

    # cruved level '2' => My organism data
    elif cruved_level == "2":
        for role in visit.observers:
            if role.id_role == user.id_role:
                is_allowed = True
                break
            elif visit.id_digitiser == user.id_role:
                is_allowed = True
                break
            elif role.id_organisme == user.id_organisme:
                is_allowed = True
                break
        if not is_allowed:
            raise Forbidden(
                f"User {user.id_role} cannot update visit number {visit.id_base_visit}"
            )


def check_year_visit(id_base_site, new_visit_date, id_base_visit=None):
    """
    Check if there is already a visit of the same year.
    If yes, observer is not allowed to post the new visit.

    Raise a FORBIDDEN 403 HTTP ERROR if a visit already exist this year.
    """
    query = db.session.query(func.date_part("year", TBaseVisits.visit_date_min)).filter(
        TBaseVisits.id_base_site == id_base_site
    )
    if id_base_visit is not None:
        query = query.filter(TBaseVisits.id_base_visit != id_base_visit)
    old_visits_dates = query.all()

    year_new_visit = new_visit_date[0:4]
    for date in old_visits_dates:
        year_old_visit = str(int(date[0]))
        if year_old_visit == year_new_visit:
            db.session.rollback()
            raise Forbidden(
                f"PostYearError - Site {id_base_site} has already been visited in {year_old_visit}!"
            )
