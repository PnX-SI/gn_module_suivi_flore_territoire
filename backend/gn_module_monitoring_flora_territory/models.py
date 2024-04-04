from flask import g
from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql.expression import func
from sqlalchemy.ext.associationproxy import association_proxy


from apptax.taxonomie.models import Taxref
from geonature.core.gn_monitoring.models import (
    TBaseSites,
    TBaseVisits,
    corVisitObserver,
)
from ref_geo.models import LAreas
from geonature.utils.env import db
from utils_flask_sqla_geo.serializers import shapeserializable
from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable


class MonitoringFloraTerritory(db.Model):
    """
    Module db master parent abstract class.
    Debug is more easy.
    """

    __abstract__ = True

    def __repr__(self):
        return str(self.__class__) + ": " + str(self.__dict__)

    def __str__(self):
        return str(self.__class__) + ": " + str(self.__dict__)


class VisitAuthMixin(object):
    def user_is_observer_or_digitizer(self, user):
        return self.id_digitizer == user.id_role or user in self.observers

    def user_is_in_organism_of_observers(self, user):
        for obs in self.observers:
            if obs.id_organisme == user.id_organism:
                return True
        return False

    def has_instance_permission(self, scope):
        """
        Fonction permettant de dire si un utilisateur
        peu ou non agir sur une donnée
        """
        # Si l'utilisateur n'a pas de droit d'accès aux données
        if scope == 0 or scope not in (1, 2, 3):
            return False

        # Si l'utilisateur à le droit d'accéder à toutes les données
        if scope == 3:
            return True

        # Si l'utilisateur est propriétaire de la données
        if self.user_is_observer_or_digitizer(g.current_user):
            return True

        # Si l'utilisateur appartient à un organisme
        # qui a un droit sur la données et
        # que son niveau d'accès est 2 ou 3
        if scope in (2, 3) and self.user_is_in_organism_of_observers(g.current_user) :
            return True
        return False

    def get_instance_perms(self, scopes):
        """
        Return the user's perms for a model instance for each action.
        Use in the map-list interface to allow or not an action
        params:
            - scopes:  the scope of the user for each action
        """
        return {
            action: self.has_instance_permission(scope)
            for action, scope in scopes.items()
        }

@serializable
@geoserializable
class SiteInfos(MonitoringFloraTerritory):
    __tablename__ = "t_infos_site"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}
    id_infos_site = db.Column(db.Integer, primary_key=True)
    id_base_site = db.Column(db.Integer, ForeignKey(TBaseSites.id_base_site))
    cd_nom = db.Column(db.Integer, ForeignKey(Taxref.cd_nom))

    base_site = db.relationship(TBaseSites)
    sciname = db.relationship(Taxref)

    geom = association_proxy("base_site", "geom")

    def get_geofeature(self):
        return self.as_geofeature("geom", "id_infos_site")

@serializable
class VisitPerturbation(MonitoringFloraTerritory):
    __tablename__ = "cor_visit_perturbation"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}
    id_base_visit = db.Column(
        "id_base_visit",
        db.Integer,
        ForeignKey(TBaseVisits.id_base_visit),
        primary_key=True,
    )
    id_nomenclature_perturbation = db.Column(
        "id_nomenclature_perturbation",
        db.Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    )

    nomenclature = db.relationship(
        TNomenclatures,
        primaryjoin=(id_nomenclature_perturbation == TNomenclatures.id_nomenclature),
        foreign_keys=[id_nomenclature_perturbation],
        lazy="joined",
    )


@serializable
class VisitGrid(MonitoringFloraTerritory):
    __tablename__ = "cor_visit_grid"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}
    id_area = db.Column(db.Integer, ForeignKey(LAreas.id_area), primary_key=True)
    id_base_visit = db.Column(db.Integer, ForeignKey(TBaseVisits.id_base_visit), primary_key=True)
    presence = db.Column(db.Boolean)
    uuid_base_visit = db.Column(UUID(as_uuid=True))


@serializable
@shapeserializable
class Visit(TBaseVisits, VisitAuthMixin):
    __tablename__ = "t_base_visits"
    __table_args__ = {"schema": "gn_monitoring", "extend_existing": True}


    def __repr__(self):
        return str(self.__class__) + ": " + str(self.__dict__)

    def __str__(self):
        return str(self.__class__) + ": " + str(self.__dict__)

    cor_visit_grid = db.relationship(
        VisitGrid,
        primaryjoin=(VisitGrid.id_base_visit == TBaseVisits.id_base_visit),
        foreign_keys=[VisitGrid.id_base_visit],
    )
    cor_visit_perturbation = db.relationship(VisitPerturbation, lazy="joined")
    observers = db.relationship(
        "User",
        secondary=corVisitObserver,
        primaryjoin=(corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit),
        secondaryjoin=(corVisitObserver.c.id_role == User.id_role),
        foreign_keys=[corVisitObserver.c.id_base_visit, corVisitObserver.c.id_role],
    )

    def has_visit_for_this_year(self, year):
        visit = db.session.query(Visit.id_base_site).filter_by(id_base_site=self.id_base_site).filter(func.date_part("year", TBaseVisits.visit_date_min) == year).one_or_none()
        if visit :
            return True
        return False



@serializable
@geoserializable
@shapeserializable
class VisitsExport(MonitoringFloraTerritory):
    __tablename__ = "export_visits"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}
    id_area = db.Column(db.Integer, primary_key=True)
    id_base_visit = db.Column(db.Integer, primary_key=True)
    id_base_site = db.Column(db.Integer)
    uuid_base_visit = db.Column(UUID(as_uuid=True))
    visit_date_min = db.Column(db.DateTime)
    comments = db.Column(db.Unicode)
    geom = db.Column(Geometry("GEOMETRY", 2154))
    presence = db.Column(db.Boolean)
    label_perturbation = db.Column(db.Unicode)
    observateurs = db.Column(db.Unicode)
    organisme = db.Column(db.Unicode)
    base_site_name = db.Column(db.Unicode)
    nom_valide = db.Column(db.Unicode)
    cd_nom = db.Column(db.Integer)
    area_name = db.Column(db.Unicode)
    id_type = db.Column(db.Integer)
